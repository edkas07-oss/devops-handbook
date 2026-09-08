# TM-ADR-0020

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0020 |
| **Title** | Enforce Bounded Incident Notification Delivery Lifecycle and Exponential Backoff Retries |
| **Project** | Tomcat Monitoring |
| **Section** | Incident Notification and Delivery Architecture |
| **Status** | Accepted |
| **Date** | 2026-09-01 |

---

## 🔍 Overview

Menetapkan standarisasi mesin status pengiriman notifikasi (*notification state machine*) dan mekanisme percobaan ulang terbatas (*bounded exponential backoff retries*) di dalam Diagnostic Service guna menjamin keandalan pengiriman email laporan insiden tanpa menimbulkan badai notifikasi (*alert storm*), duplikasi, maupun ketergantungan pada antrean pesan eksternal.

## 🌍 Context

Pada saat insiden `TomcatDown` terjadi, sistem pemantauan (Alertmanager) dapat mengirimkan webhook evaluasi berulang kali (*alert evaluation interval*). Jika Diagnostic Service mengirimkan email pada setiap webhook yang masuk, tim SRE akan mengalami kelelahan notifikasi (*notification fatigue*).

Di sisi lain, kegagalan sementara (*transient error*) pada server SMTP (seperti koneksi terputus atau timeout sesaat) dapat menyebabkan laporan diagnosis krusial gagal terkirim jika tidak ada mekanisme percobaan ulang (*retry*). Namun, *retry* yang tidak dibatasi (*unbounded retries*) atau penumpukan antrean tanpa batas waktu berisiko mengirimkan email kedaluwarsa yang sudah tidak relevan (*zombie alerts*). Menggunakan sistem message broker eksternal (seperti RabbitMQ atau Kafka) juga melanggar prinsip desain *single-host lightweight bounded service* ([TM-ADR-0010](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)).

## ⚖️ Decision

Ditetapkan arsitektur pengiriman notifikasi insiden yang terikat pada aturan deterministik:

1. **Siklus Hidup Status Notifikasi Deterministik:**
   - **`INITIAL_FIRING`**: Dikirim tepat satu kali saat insiden baru terdeteksi pertama kali.
   - **`SUPPRESSED_DUPLICATE`**: Webhook pemicu berikutnya dengan *fingerprint* dan hash hasil diagnosis (SHA-256) yang identik akan disupresi secara otomatis tanpa mengirimkan email ulang.
   - **`MATERIAL_UPDATE`**: Jika evaluasi lanjutan menemukan bukti baru yang secara substansial mengubah kesimpulan asesmen (misal dari `UNDETERMINED` menjadi `OOM_CRASH`), sistem mengirimkan maksimum **1 kali** notifikasi pembaruan per insiden.
   - **`RESOLVED`**: Tepat **1 kali** notifikasi pemulihan dikirimkan saat Alertmanager mengirimkan status `resolved`.

2. **Mekanisme Percobaan Ulang Terbatas (*Bounded Retries*):**
   - Maksimum percobaan pengiriman dibatasi hingga **3 kali** (*max attempts = 3*).
   - Interval jeda menerapkan *exponential backoff*: percobaan ke-2 setelah **1 detik**, percobaan ke-3 setelah **5 detik**.
   - Batas kedaluwarsa pengiriman maksimum (*maximum delivery age ceiling*) ditetapkan **60 detik**. Percobaan di luar batas waktu ini otomatis ditandai sebagai `EXPIRED_FAILED` dan dihentikan.

3. **Pelacakan Status Transaksional di SQLite Lokal:**
   - Seluruh riwayat pengiriman dicatat dalam tabel SQLite `notification_deliveries` (Migration `004`), mencakup `delivery_id`, `incident_id`, `notification_type`, `attempt_count`, `delivery_status`, dan `error_message`.
   - Tidak menggunakan *message queue* sekunder eksternal; seluruh status delivery dikelola secara transaksional dan terisolasi di dalam memori dan database SQLite lokal.

## 🏛️ Architecture

```text
Incoming Webhook (Alertmanager)
               |
               v
 [ State Transition Evaluator ]
  ├── Fingerprint & Hash Check ──> Identik? ──> [ SUPPRESSED (No Email) ]
  ├── Status FIRING Pertama Kali? ────────────> [ INITIAL_FIRING ]
  ├── Diagnosis Berubah Signifikan? ──────────> [ MATERIAL_UPDATE (Max 1x) ]
  └── Status RESOLVED? ───────────────────────> [ EXACTLY-ONE RESOLVED ]
               |
               v (Memerlukan Pengiriman)
 [ Bounded Delivery Engine ]
  ├── Attempt 1 (Immediate) ──> [ OK ] ──> Status: DELIVERED
  │         │ (Transient Error)
  │         v
  ├── Attempt 2 (Backoff 1s) ──> [ OK ] ──> Status: DELIVERED
  │         │ (Transient Error)
  │         v
  ├── Attempt 3 (Backoff 5s) ──> [ OK ] ──> Status: DELIVERED
  │         │ (Failed / Age > 60s)
  │         v
  └── Terminal Status: FAILED / EXPIRED_FAILED (Logged in SQLite)
```

## 💡 Rationale

- **Eliminasi Kelelahan Notifikasi SRE:** Operator hanya menerima informasi penting: deteksi awal, pembaruan kritis (jika ada bukti baru), dan konfirmasi pemulihan.
- **Ketahanan Terhadap Gangguan Jaringan:** *Retry* singkat 1s/5s mampu mengatasi gangguan koneksi SMTP sementara tanpa menunda pelaporan insiden.
- **Zero External Infrastructure Overhead:** Menghindari beban operasional pemeliharaan cluster broker pesan tambahan, sejalan dengan prinsip *self-contained bounded runtime*.

## ⚠️ Consequences

- **Kelebihan:**
  - Auditabilitas penuh terhadap setiap upaya pengiriman email dan alasan kegagalannya langsung di database lokal.
  - Perilaku pengiriman yang sepenuhnya deterministik dan mudah diuji dengan *unit test* dan *mock SMTP*.
- **Keterbatasan:**
  - Jika server SMTP mati lebih dari 60 detik, notifikasi tidak akan tertunda selamanya di antrean, melainkan gagal secara definitif (operator harus memeriksa dasbor web / log lokal).

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-09-01**

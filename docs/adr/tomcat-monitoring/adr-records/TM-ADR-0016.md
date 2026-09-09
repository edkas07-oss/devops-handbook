# TM-ADR-0016

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0016 |
| **Title** | Designate Diagnostic Service as the Canonical Incident Notification Authority |
| **Project** | Tomcat Monitoring |
| **Section** | Incident Notification and Alerting Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-31 |

---

## 🔍 Overview

Diagnostic Service ditetapkan sebagai satu-satunya sumber pengirim notifikasi resmi (*Single Source of Truth & Canonical Incident Notification Authority*) untuk **seluruh siklus alert pemantauan Tomcat** (termasuk insiden `TomcatDown`, degradasi memori & GC `TomcatGCPauseHigh`/`TomcatOldGenMemoryPressure`, kejenuhan thread `TomcatThreadPoolSaturated`, hingga kegagalan aplikasi `TomcatApplicationHealthFailed`). 

Pengiriman email insiden langsung dari Alertmanager ke tim operasional dinonaktifkan secara universal; Alertmanager murni bertindak sebagai agregator dan dispatcher webhook menuju Diagnostic Service. Satu-satunya pengecualian jalur email langsung dari Alertmanager adalah kondisi darurat ketika Diagnostic Service sendiri tidak dapat dihubungi (*Emergency Bypass: `DiagnosticServiceDown`*).

## 🌍 Context

Dalam arsitektur pemantauan konvensional, Alertmanager langsung mengirimkan email ke tim operasional segera setelah menerima sinyal *firing* atau *resolved* dari Prometheus.

Namun, pengiriman langsung dari Alertmanager menimbulkan fragmentasi operasional yang serius:

1. **Inkonsistensi Format & Ketiadaan Konteks Bukti (*Unverified Raw Alerting*):** Email bawaan Alertmanager hanya memuat ekspresi metrik mentah tanpa bukti log aplikasi (`catalina.out`), status container cgroup/exit code, maupun korelasi data forensik. Hal ini memaksa operator melakukan investigasi manual dari nol.
2. **Notifikasi Ganda yang Membingungkan (*Split Alerting*):** Jika sebagian alert dikirim oleh Alertmanager dan sebagian lainnya dikirim oleh Diagnostic Service, tim operasional menerima format email yang berbeda-beda tanpa standardisasi SOP mitigasi.
3. **Pentingnya Format Standar 7-Seksi Enterprise SRE:** Seluruh insiden degradasi maupun kegagalan sistem wajib disajikan dalam struktur terpadu 7-seksi (Ringkasan, Asesmen Diagnostik, Snapshot Metrik, Bukti Log, Bukti yang Hilang/Bertentangan, Rekomendasi SOP Mitigasi Bahasa Indonesia, dan Keterlacakan Aturan).

## ⚖️ Decision

Ditetapkan kebijakan **Pemberi Notifikasi Tunggal Universal (*Universal Canonical Notification Authority*)**:

1. **Universal Webhook Routing di Alertmanager:**
   Alertmanager dikonfigurasi dengan *default root route* yang mengarahkan **seluruh alert monitoring** secara eksklusif ke webhook HTTPS Diagnostic Service (`lab-diagnostic-service`). Pengiriman email langsung dari Alertmanager untuk seluruh alert insiden dinonaktifkan sepenuhnya.
2. **Wewenang Notifikasi Penuh Diagnostic Service:**
   Diagnostic Service menjadi satu-satunya entitas yang berwenang mengirimkan email laporan insiden ke Mailpit / kanal operasional on-call:
    - Melakukan evaluasi terhadap basis aturan deklaratif (*Rulepack Engine*) atau asesmen diagnostik umum jika rule belum dipetakan.
    - Menyajikan data forensik runtime (log, metrik, cgroup, dan spool) secara lengkap.
    - Menerbitkan laporan awal (*Initial Firing*), pembaruan materiil (*Material Update* maks 1x), dan konfirmasi pemulihan (*Resolved*).
3. **Format Standar Wajib 7-Seksi SRE:**
   Semua notifikasi email wajib disusun menggunakan format standar 7-seksi Enterprise SRE multipart (HTML responsif dan Plain Text fallback).
4. **Emergency Direct SMTP Bypass (Khusus `DiagnosticServiceDown`):**
   Satu-satunya jalur pengiriman email langsung dari Alertmanager yang diizinkan adalah sub-rute darurat `DiagnosticServiceDown` guna mencegah kegagalan tanpa pemberitahuan (*zero silent failure*).

## 🏛️ Architecture

```text
                                 Prometheus
                         (Seluruh Aturan Alert Tomcat)
                                     |
                                     v
                                Alertmanager
                                     |
                  +------------------+------------------+
                  | (Seluruh Alert Normal)              | (Khusus Emergency)
                  | (TomcatDown, GC, Threads, Health)   | (DiagnosticServiceDown)
                  v                                     v
       [Webhook HTTPS Internal :8443]         [Direct SMTP Emergency Bypass]
                  |                                     |
                  v                                     |
          Diagnostic Service                            |
        (Evidence Engine & 7-Section)                   |
                  |                                     |
                  v                                     |
       [Pengirim Tunggal SMTP Laporan]                  |
                  |                                     |
                  +------------------+------------------+
                                     |
                                     v
                                  Mailpit
                          (Inbox Tunggal Operator)
```

## 💡 Rationale

- **Standarisasi Menyeluruh (*Universal Single Source of Truth*):** Operator on-call menerima format laporan yang konsisten dan kaya konteks forensik untuk semua jenis insiden.
- **Pemberian Rekomendasi SOP Otomatis:** Setiap email insiden selalu dilengkapi langkah mitigasi manual terstruktur sesuai prinsip *Zero Automatic Remediation* (TM-ADR-0014).
- **Mengeliminasi Email Mentah Alertmanager:** Menghindarkan tim SRE dari kelelahan alert (*alert fatigue*) akibat email teks mentah yang tidak terverifikasi.

## ⚠️ Consequences

- **Kelebihan:**
  - Seluruh notifikasi pemantauan Tomcat tersaji seragam, profesional, dan dapat langsung dieksekusi oleh tim SRE.
  - Semua bukti insiden (metrik, log, container lifecycle) terekam secara otomatis ke database SQLite lokal `diagnostic.db` untuk audit dan AI enrichment.
- **Keterbatasan dan Mitigasi (Addendum 2026-09-08):**
  - **Risiko Ketergantungan:** Alur notifikasi bergantung pada kesehatan container Diagnostic Service.
  - **Mitigasi Terverifikasi (*Zero Silent Failure Safeguard*):**
    1. **Health Scrape Mandiri:** Prometheus mengikis endpoint `/health` Diagnostic Service setiap 15 detik.
    2. **Alert Rule `DiagnosticServiceDown`:** Evaluasi `up{job="tomcat-diagnostic-service"} == 0` (for: 1m, severity: critical).
    3. **Emergency Bypass Route:** Alertmanager meneruskan alert `DiagnosticServiceDown` secara langsung via Direct SMTP ke Mailpit, melewati webhook yang mati.

## 📌 Status

**Accepted — Policy expanded to Universal Diagnostic Ingestion.**

## 📅 Date

**2026-08-31** *(Universal Ingestion Addendum: 2026-09-08)*


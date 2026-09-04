# TM-ADR-0017

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0017 |
| **Title** | Adopt Vertical Slice Minimum Viable Product (MVP) Scoping for Diagnostic Pilot |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Architecture Strategy |
| **Status** | Accepted |
| **Date** | 2026-08-31 |

---

## 🔍 Overview

Pengembangan sistem diagnosis otomatis menerapkan strategi **Minimum Viable Product (MVP)** dengan pendekatan irisan vertikal (*vertical slice*). Ruang lingkup pilot dibatasi secara terfokus pada satu alert utama (`TomcatDown`) guna membuktikan keandalan dan nilai nyata arsitektur (*Proof of Value*) di lingkungan lab sebelum memperluas sistem ke skala yang lebih besar.

## 🌍 Context

Membangun sistem diagnosis insiden yang langsung mencakup seluruh spektrum kegagalan sistem enterprise sejak awal—seperti kehabisan memori JVM (*High-Heap*), kebuntuan thread (*deadlock*), query database timeout, error aplikasi HTTP 5xx, integrasi platform pihak ketiga (TrueSight), dan tindakan perbaikan otomatis—mengandung risiko proyek yang sangat besar:

1. **Jebakan Proyek Terlalu Besar (*The Big-Bang Delivery Trap*):** Mencoba mengotomatiskan puluhan jenis kegagalan sekaligus sejak awal menyebabkan proses pengerjaan berlarut-larut tanpa hasil konkret yang dapat diuji di server sesungguhnya.
2. **Format Data Belum Teruji:** Skema database, struktur laporan insiden, dan format pengumpulan bukti belum pernah divalidasi dalam operasional nyata.
3. **Ketergantungan Eksternal:** Akses dan kredensial sistem enterprise eksternal (seperti TrueSight) belum siap di lingkungan lab, sehingga dapat menghambat penyelesaian komponen inti.

## ⚖️ Decision

Ditetapkan strategi arsitektur **Vertical Slice MVP Scoping** yang berlandaskan tiga pilar utama:

1. **Minimum (Fokus pada Masalah Paling Esensial):**
    - Sistem hanya memproses satu alert ketersediaan utama: `TomcatDown`.
    - Metrik kesehatan aplikasi (*application health*) hanya digunakan sebagai bukti pendukung, bukan pemicu diagnosis mandiri.
    - Aturan diagnostik lanjutan (seperti *High-Heap*), integrasi TrueSight, Integration Bridge, serta remediasi otomatis sengaja ditunda (*deferred*) atau dinonaktifkan.
2. **Viable (Sistem Mandiri dan Tangguh di Runtime):**
    - Solusi yang dibangun bukan sekadar rancangan coba-coba atau purwarupa buangan (*throwaway prototype*), melainkan layanan utuh yang siap operasional.
    - Sistem dilengkapi persistensi database lokal (SQLite), batasan keamanan proses tanpa root (*least-privilege rootless*), pengumpul bukti host yang terisolasi, format laporan kanonikal standar, dan pengiriman notifikasi email terstruktur.
3. **Iteratif (Fondasi Bersih untuk Fase Berikutnya):**
    - Menetapkan kontrak antarmuka dan skema data yang stabil sejak awal.
    - Kapabilitas tambahan (seperti aturan domain baru, integrasi enterprise, atau pengayaan AI) dapat ditambahkan di kemudian hari secara bertahap tanpa perlu merombak arsitektur dasar.

## 🏛️ Architecture

```text
Cakupan Penuh Enterprise (Masa Depan)
[ High-Heap ] [ DB Timeouts ] [ TrueSight ] [ Auto-Remediation ] [ Multi-Host ]
--------------------------------------------------------------------------------
Irisan Vertikal MVP (Diagnostic Pilot):
Prometheus (`up == 0`)
   --> Alertmanager
   --> Diagnostic Service
   --> Bukti Multi-Sumber (Metrik, Log :ro, Spool :ro)
   --> Evaluasi Aturan Deterministik
   --> SQLite Persisten
   --> Laporan Mailpit (Operator SRE)
```

Arsitektur MVP memotong sistem secara vertikal (*vertical slice*): mengalirkan data dari lapisan telemetri terbawah hingga penyajian notifikasi teratas secara tuntas dan berfungsi penuh, namun dengan batas fungsional horizontal yang dikontrol secara ketat.

## 💡 Rationale

- **Pembuktian Nilai yang Cepat dan Terukur (*Proof of Value*):** Tim dapat segera membuktikan secara objektif apakah korelasi bukti multi-sumber benar-benar efektif mendiagnosis insiden ketersediaan sebelum sistem diperluas.
- **Isolasi Risiko Operasional:** Membatasi fitur pada lingkungan lab menjamin eksperimen diagnostik tidak membebani atau mengganggu kestabilan proses bisnis Tomcat yang sedang berjalan.
- **Penyusunan Kontrak yang Matang:** Memberikan kesempatan bagi tim untuk mematangkan kontrak data (skema SQLite, format hasil kanonikal, protokol spool collector) berdasarkan pembelajaran nyata di lapangan sebelum diterapkan ke sistem produksi.

## ⚠️ Consequences

- **Kelebihan:**
  - Sasaran pengerjaan sangat tajam, terarah, dan menghasilkan arsitektur yang siap pakai (*production-ready pattern*) tanpa meninggalkan hutang teknis (*zero architectural debt*).
  - Menghindari pembuatan kode coba-coba yang harus dibongkar ulang saat fase pilot berakhir.
- **Keterbatasan:**
  - Jenis insiden di luar `TomcatDown` (seperti degradasi performa bertahap tanpa proses mati) belum ditangani secara otomatis pada fase ini.
  - Aktivasi integrasi platform eksternal dan aturan tambahan memerlukan tahapan perencanaan teknis tersendiri pada fase berikutnya.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-31**

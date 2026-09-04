# TM-ADR-0015

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0015 |
| **Title** | Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Ingestion Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-31 |

---

## 🔍 Overview

Diagnostic Service menggunakan pola *asynchronous store-and-forward* untuk memproses webhook dari Alertmanager. Status HTTP `202 Accepted` hanya dikirimkan setelah data alert berhasil disimpan secara aman ke database SQLite lokal (*durable acceptance*).

## 🌍 Context

Ketika Alertmanager meneruskan alert insiden `TomcatDown` (baik saat kondisi *firing* maupun saat *resolved*), proses analisis diagnostik membutuhkan waktu beberapa detik (antara 5 hingga 30 detik). Hal ini dikarenakan sistem harus:

1. Mengambil metrik terkini dan historis dari Prometheus via HTTP API.
2. Membaca file log Tomcat dan crash dump di filesystem host.
3. Membaca spool event ternormalisasi dari Restricted Event Collector.
4. Menjalankan evaluasi aturan deterministik dan menyiapkan laporan email ke Mailpit.

Jika seluruh tahapan tersebut dieksekusi secara langsung (*synchronous*) di dalam siklus penanganan request HTTP webhook:

- Alertmanager akan mengalami *timeout* (karena batas toleransi default Alertmanager hanya beberapa detik), sehingga memicu pengiriman ulang alert secara bertubi-tubi (*retry storm*).
- Jika container Diagnostic Service mendadak crash atau restart di tengah proses analisis, alert yang hanya tersimpan di memori (*in-memory queue*) akan hilang secara permanen.

## ⚖️ Decision

Ditetapkan pola integrasi **Asynchronous Ingestion dengan Durable Acceptance**:

1. **Pemisahan Penerimaan dan Eksekusi:**
   Handler HTTP webhook hanya bertugas memvalidasi Bearer Token, memeriksa format JSON payload dari Alertmanager, dan menyimpan data alert ke tabel `alert_events` di SQLite.
2. **Simpan ke Disk Sebelum Merespons HTTP 202:**
   Handler dilarang membalas `202 Accepted` sebelum transaksi penulisan SQLite selesai di-commit ke disk. Jika database gagal menulis, kembalikan HTTP `500 Internal Server Error` agar Alertmanager tahu bahwa pengiriman gagal dan dapat mencoba mengirim ulang secara teratur.
3. **Pemrosesan Asinkron oleh Worker:**
   Satu background worker mandiri akan mengambil alert berstatus `pending` dari SQLite, menjalankan pengumpulan bukti, mengevaluasi aturan diagnostik, menyimpan hasil *canonical result*, dan mengirimkan email notifikasi.
4. **Pemulihan Otomatis Saat Restart:**
   Jika container restart atau mati mendadak, worker akan memeriksa kembali database SQLite untuk melanjutkan alert yang belum tuntas diproses.

## 🏛️ Architecture

```text
Alertmanager
     |
     | 1. POST /api/v1/alerts (HTTPS + Bearer Token)
     v
[HTTP Webhook Handler]
     |
     | 2. Validasi Auth & Skema JSON
     | 3. Simpan ke SQLite (Durable Transaction)
     v
[(Disk) Database SQLite (WAL Mode)]
     |
     | 4. Data berhasil tersimpan di disk
     v
[HTTP Webhook Handler] ---> 5. Balas HTTP 202 Accepted ---> Alertmanager (Selesai)
     |
     ~ (Asinkron / Terpisah dari Siklus HTTP) ~
     |
     v
[Diagnostic Background Worker]
     |
     +---> 6. Ambil event pending dari SQLite
     +---> 7. Kumpulkan bukti multi-sumber (Prometheus, Log, Spool)
     +---> 8. Evaluasi aturan diagnosis
     +---> 9. Simpan Canonical Result ke SQLite
     +---> 10. Kirim Notifikasi Email ke Mailpit
```

## 💡 Rationale

- **Mencegah Alert Hilang (*Zero Alert Loss*):** Data insiden langsung diamankan di disk persisten sebelum respons HTTP dikirim, sehingga data tidak akan hilang meski proses container mati mendadak.
- **Respons Webhook Sangat Cepat:** Siklus HTTP selesai dalam hitungan milidetik (< 20 ms), sehingga sepenuhnya kebal terhadap lamanya waktu pengumpulan bukti log atau jaringan Prometheus yang lambat.
- **Audit Trail yang Jelas:** Setiap alert langsung memiliki catatan persisten sejak pertama kali diterima, memudahkan pelacakan status penanganan insiden (*pending*, *processing*, *completed*, *failed*).

## ⚠️ Consequences

- **Kelebihan:**
  - Data insiden terlindungi dengan baik dan tahan terhadap restart container (*crash-resilient*).
  - Alur komunikasi webhook dengan Alertmanager tetap stabil tanpa risiko request timeout atau pengiriman ulang yang tidak terkontrol.
- **Keterbatasan & Tuntutan Desain Teknis:**
  - Database SQLite menjadi komponen kritis pada jalur penerimaan; jika kapasitas penyimpanan habis atau terjadi gangguan I/O disk, webhook akan langsung mengembalikan status error HTTP 500.
  - Pengembang wajib mengimplementasikan mesin status (*state machine* `pending` $\to$ `processing` $\to$ `completed`) serta mekanisme pemulihan antrean macet (*stale lock recovery*) agar tidak terjadi duplikasi eksekusi saat container hidup kembali pasca-crash.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-31**

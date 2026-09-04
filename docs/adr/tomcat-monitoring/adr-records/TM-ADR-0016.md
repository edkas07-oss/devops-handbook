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

Diagnostic Service ditetapkan sebagai satu-satunya sumber pengirim notifikasi (*Single Source of Truth*) untuk seluruh siklus insiden `TomcatDown` (mulai dari kondisi *firing*, pembaruan bukti, hingga *resolved*). Pengiriman email langsung dari Alertmanager untuk alert `TomcatDown` dinonaktifkan guna menghindari duplikasi notifikasi ke tim operasional.

## 🌍 Context

Dalam arsitektur pemantauan pada umumnya, Alertmanager langsung mengirimkan email ke tim operasional segera setelah menerima sinyal *firing* atau *resolved* dari Prometheus.

Namun, pada alur diagnostik otomatis, pola pengiriman langsung ini menimbulkan sejumlah masalah operasional:

1. **Notifikasi Ganda yang Membingungkan (*Split Alerting*):** Jika Alertmanager mengirim email pemicu awal, lalu beberapa detik kemudian Diagnostic Service mengirimkan email hasil analisis lengkap, operator on-call menerima rentetan email terpisah dengan informasi berbeda yang menimbulkan kebingungan mengenai status mana yang harus dipercaya.
2. **Ketiadaan Konteks Penyebab (*Unverified Trigger Alert*):** Sinyal awal `up{job="tomcat-jmx-exporter"} == 0` dari Alertmanager hanyalah gejala kegagalan *scrape*, bukan bukti mutlak bahwa proses Tomcat mati. Mengirimkan email kepanikan sebelum bukti diperiksa meningkatkan risiko alarm palsu (*false alarm*) dan kelelahan alert (*alert fatigue*).
3. **Status Pemulihan Tidak Terintegrasi (*Resolved Inconsistency*):** Saat sinyal metrik kembali pulih, aplikasi belum tentu langsung siap melayani trafik secara sehat. Notifikasi pemulihan (*resolved*) perlu mengonfirmasi data diagnostik secara akurat serta mencatat durasi total insiden dari awal hingga tuntas.

## ⚖️ Decision

Ditetapkan kebijakan **Pemberi Notifikasi Tunggal (*Canonical Incident Notification Authority*)**:

1. **Routing Khusus di Alertmanager:**
   Alertmanager dikonfigurasi untuk meneruskan alert `alertname="TomcatDown"` secara eksklusif ke webhook Diagnostic Service. Jalur email langsung dari Alertmanager ke operator untuk jenis alert ini dinonaktifkan sepenuhnya.
2. **Wewenang Penuh Diagnostic Service:**
   Diagnostic Service menjadi satu-satunya pihak yang berwenang mengirimkan email insiden `TomcatDown` ke Mailpit, yang mencakup:
    - Laporan awal insiden (*Initial Incident Report*) segera setelah pengumpulan dan evaluasi bukti selesai.
    - Laporan pembaruan jika ditemukan temuan baru atau eskalasi status.
    - Laporan pemulihan (*Incident Resolved*) saat status pulih telah terverifikasi.
3. **Format Laporan Standar:**
   Semua notifikasi email wajib disusun dari satu data terpadu (*canonical result version 1*) menggunakan template standar Enterprise SRE (memuat ringkasan insiden, domain kegagalan, tingkat keyakinan, bukti pendukung, dan rekomendasi tindakan).
4. **Alert Lain Tetap Standar:**
   Alert monitoring di luar cakupan diagnostik (seperti alert *Telegraf Health Scrape*) tetap dikirimkan langsung oleh Alertmanager melalui jalur email standar.

## 🏛️ Architecture

```text
                                 Prometheus
                                     |
                                     v
                                Alertmanager
                                     |
                  +------------------+------------------+
                  |                                     |
            (TomcatDown)                        (Alert Lainnya)
                  |                                     |
                  v                                     v
       [Webhook HTTPS Internal]               [Direct SMTP Delivery]
                  |                                     |
                  v                                     |
          Diagnostic Service                            |
                  |                                     |
        (Evaluasi & Laporan)                            |
                  |                                     |
                  v                                     |
         [Pengirim Tunggal SMTP]                        |
                  |                                     |
                  +------------------+------------------+
                                     |
                                     v
                                  Mailpit
                          (Inbox Tunggal Operator)
```

## 💡 Rationale

- **Informasi yang Jelas dan Konsisten (*Single Source of Truth*):** Operator hanya menerima satu jenis email per insiden yang sudah terverifikasi dan memuat analisis mendalam, sehingga memudahkan proses penanganan insiden.
- **Mengurangi Beban Operator (*Alert Fatigue*):** Menghindarkan tim dari banjir email mentah saat terjadi gangguan metrik sesaat (*transient scrape blip*).
- **Laporan Siklus Hidup yang Lengkap:** Diagnostic Service dapat menyajikan laporan *resolved* yang menampilkan perbandingan kondisi saat insiden terjadi versus saat pulih beserta durasi total gangguan dari database SQLite.

## ⚠️ Consequences

- **Kelebihan:**
  - Notifikasi insiden tersaji rapi, akurat, profesional, dan langsung dapat ditindaklanjuti oleh tim SRE.
  - Beban kognitif operator berkurang drastis karena tidak ada email duplikat atau status yang saling bertolak belakang.
- **Keterbatasan:**
  - Ketersediaan notifikasi insiden `TomcatDown` kini bergantung pada keaktifan Diagnostic Service. Jika container Diagnostic Service mati, notifikasi insiden ini tidak terkirim via jalur utama.
  - Untuk mengantisipasi risiko tersebut, platform monitoring harus memiliki pemantauan kesehatan mandiri (*health scrape*) terhadap Diagnostic Service.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-31**

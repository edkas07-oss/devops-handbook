# TM-ADR-0009

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0009 |
| **Title** | Use SQLite for Local Diagnostic State |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Data Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Setiap instans Diagnostic Service lokal pada host menggunakan database SQLite untuk menyimpan state event, insiden, hasil kanonikal (*canonical result*), deduplikasi, dan riwayat pengiriman notifikasi secara persisten (*durable*).

## 🌍 Context

Penerimaan webhook dari Alertmanager harus mampu bertahan saat container mengalami restart, dapat memasangkan event *firing* dengan *resolved*, serta mencegah pemrosesan ganda (*duplicate work*). Lingkup pilot hanya memiliki satu proses worker dan tidak memerlukan sistem database eksternal yang dikelola terpisah.

## ⚖️ Decision

SQLite berjalan dalam mode WAL (*Write-Ahead Logging*) pada named volume persisten `diagnostic_data`. Proses inisialisasi, migrasi skema, *checkpoint*, retensi data, dan *incremental vacuum* berjalan secara otomatis.

Target kapasitas data adalah 100 MiB dan dibatasi tidak boleh melampaui batas toleransi 250 MiB. Data state insiden yang masih berstatus aktif dilarang dihapus secara otomatis hanya untuk tujuan pemulihan kapasitas disk.

## 🏛️ Architecture

Layanan melakukan commit transaksi event unik yang telah dinormalisasi ke SQLite sebelum merespons HTTP `202 Accepted`, kemudian memprosesnya secara asinkron melalui satu worker antrean.

## 💡 Rationale

SQLite menyediakan penyimpanan state lokal transaksional yang tahan terhadap restart (*restart-persistent*) dengan kebutuhan sumber daya dan beban operasional yang sangat rendah. Penyimpanan berbasis memori (*in-memory*) tidak dapat bertahan saat restart, sementara database eksternal tidak proporsional untuk kebutuhan pilot.

## ⚠️ Consequences

- Model deployment *active-active* pada volume yang sama tidak didukung (*single-writer*).
- Prosedur migrasi skema, penanganan kerusakan data (*corruption*), batas kapasitas, dan pemulihan volume memerlukan pengujian eksplisit.

## 📌 Status

**Accepted — skema fisik dan implementasi ditunda (physical schema and implementation pending).**

## 📅 Date

**2026-08-30**

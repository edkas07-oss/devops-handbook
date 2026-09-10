# SQLite Lifecycle Contract

## 🔍 Overview

SQLite berfungsi sebagai penyimpanan status lokal yang tahan-uji (*local durable state store*) untuk satu instans Diagnostic Service per host Tomcat. Database ini menyimpan identitas event, siklus hidup insiden, canonical result terbatas, aturan kustom deklaratif, dan status pengiriman notifikasi; bukan sebagai arsip log mentah atau database metrik monitoring.

---

## 💾 Kontrak Penyimpanan

| Parameter | Nilai Pilot |
| :--- | :--- |
| Named Volume | `diagnostic_data` |
| Path Database | `/var/lib/tomcat-diagnostic/diagnostic.db` |
| Mode Journal | `WAL` (*Write-Ahead Logging*) |
| Model Writer | Satu service, satu worker, single logical writer |
| Target Kapasitas | 100 MiB |
| Batas Keras (*Hard Limit*) | 250 MiB |

Inisialisasi skema dan migrasi maju (*forward migration*) berjalan otomatis saat startup sebelum status service menjadi *ready*. Kegagalan migrasi mencegah penerimaan webhook. Transaksi event yang diterima wajib di-commit sebelum HTTP `202 Accepted` dikembalikan, dan kunci event (*event keys*) memiliki *uniqueness constraint* yang bertahan melewati restart container.

---

## 🔄 Retensi dan Pemeliharaan (*Housekeeping*)

- Insiden aktif dipertahankan sampai event pemulihan (*resolved event*) tercatat.
- Event ternormalisasi yang telah resolved, canonical result, ringkasan bukti, dan riwayat pengiriman disimpan selama 30 hari.
- Body webhook mentah dibuang setelah normalisasi tervalidasi.
- Pemeliharaan berkala (setiap jam dan saat startup) menjalankan penghapusan data kedaluwarsa, *checkpoint* WAL, pemeriksaan integritas & kapasitas, serta *incremental vacuum* jika diperlukan.
- Pada batas target 100 MiB, rekaman resolved terlama akan dihapus terlebih dahulu.
- Data insiden aktif tidak pernah dihapus secara otomatis demi pemulihan kapasitas.
- Pada batas keras 250 MiB, jika pemeliharaan aman tidak dapat memulihkan kapasitas, probe readiness akan gagal dan webhook baru akan menerima respons `503 Service Unavailable` sampai kapasitas dipulihkan dengan aman.

Penghapusan named volume, penghapusan database, perbaikan manual, ekspor, atau recovery merupakan tindakan operasional destruktif yang memerlukan otorisasi terpisah. Prosedur backup dan disaster recovery tingkat produksi berada di luar lingkup pilot.

---

## 💡 Arsitektur Self-Managed SQLite Engine (Manajemen Mandiri)

Diagnostic Service didesain menggunakan **Embedded SQLite** ([TM-ADR-0013](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md)) yang berjalan langsung di dalam kontainer tanpa bantuan server database eksternal (seperti PostgreSQL atau MySQL) dan tanpa peran administrator database (DBA) khusus.

Konsekuensinya, Diagnostic Service wajib memiliki kemampuan mengelola dan memelihara database SQLite-nya sendiri (*self-managed / autonomous engine*), yang mencakup **3 pilar utama**:

```text
+-----------------------------------------------------------------------------+
|               Self-Managed SQLite Lifecycle in Diagnostic Service           |
+-----------------------------------------------------------------------------+
| 1. Self-Healing State Recovery (TASK-TM-004):                                |
|    Mendeteksi & memulihkan antrean macet (stale processing lock) pasca-crash|
|    secara otomatis tanpa intervensi manual operator / DBA.                  |
+-----------------------------------------------------------------------------+
| 2. Automated Storage Housekeeping & Pruning (TASK-TM-005):                  |
|    Memangkas event/log lama (> 30 hari) secara teratur & menjalankan        |
|    PRAGMA incremental_vacuum untuk mencegah kebocoran disk (bounded storage).|
+-----------------------------------------------------------------------------+
| 3. Autonomous Storage Telemetry & Quota Guard:                              |
|    Memantau ukuran file fisik database (diagnostic_db_size_bytes) dan       |
|    mengeksposnya ke Prometheus untuk pemantauan kapasitas host.             |
+-----------------------------------------------------------------------------+
```

### 1. Self-Healing State & Crash Resilience ([TASK-TM-004](../follow-up-tasks.md#task-tm-004-implementasi-stale-lock-recovery-pada-worker-ingestion))

- Jika kontainer mati mendadak saat worker sedang menganalisis insiden, event tidak akan menjadi *"zombie"* yang tertinggal selamanya di status `processing`.
- Saat aplikasi hidup kembali, metode [`sqlite-repository.js:166-194`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/adapters/sqlite-repository.js#L166-L194) secara mandiri mengembalikan tugas ke status `queued` dengan counter `retry_count`, sehingga analisis otomatis dilanjutkan tanpa intervensi manusia.
- Jika suatu tugas berulang kali memicu crash hingga melampaui batas maksimum (`maxRetries = 3`), statusnya diubah menjadi `failed` untuk mencegah *infinite crash loop*.

### 2. Automated Data Lifecycle & Disk Guard ([TASK-TM-005](../follow-up-tasks.md#task-tm-005-penjadwalan-housekeeping--pruning-database-sqlite))

- Tanpa cron job eksternal, aplikasi menjalankan metode [`sqlite-repository.js:196-235`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/adapters/sqlite-repository.js#L196-L235) pada startup dan secara berkala di worker loop.
- Record lama yang melewati batas retensi (> 30 hari) dihapus secara terurut (*Foreign-Key Safe*: `evidence_summaries` $\rightarrow$ `notification_attempts` $\rightarrow$ `canonical_results` $\rightarrow$ `work_queue` $\rightarrow$ `events` $\rightarrow$ `requests` $\rightarrow$ resolved `incidents`).
- Ruang disk kosong dikembalikan ke OS melalui `PRAGMA incremental_vacuum;` agar ukuran file database tetap berbatas (*bounded storage*).

### 3. Self-Monitoring Metrics & Storage Telemetry

- Aplikasi secara mandiri mengukur ukuran aktual berkas database pada disk (`page_count * page_size`) via [`sqlite-repository.js:237-244`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/adapters/sqlite-repository.js#L237-L244).
- Metrik `diagnostic_db_size_bytes` dan `diagnostic_housekeeping_runs_total` diekspos langsung ke Prometheus, memastikan tim SRE memiliki visibilitas penuh terhadap kesehatan storage lokal tanpa perlu login manual ke server.

---

## 📋 Skema & Migrasi Database Terpadu (001 s/d 007)

Skema fisik dikelola melalui migrasi *forward-only* terurut numerik:
- **`001-initial.sql`:** Skema dasar tabel `schema_migrations`, `requests`, `incidents`, `events`, dan `work_queue`.
- **`002-canonical-results.sql`:** Tabel `canonical_results`, `evidence_summaries`, dan kolom `material_update_count`.
- **`003-delivery-attempts.sql`:** Tabel `notification_attempts` untuk riwayat pengiriman SMTP berbatas.
- **`004-notification-lifecycle.sql`:** Kolom `resolved_notification_count` pada tabel `incidents`.
- **`005-custom-rules.sql`:** Tabel `custom_rules` dengan proteksi unik anti-collision `branch`.
- **`006-rule-category.sql`:** Kolom `category` dan indeks domain query pada `custom_rules`.
- **`007-stale-lock-recovery-and-retention.sql`:** Kolom `retry_count`, `lease_expires_at`, dan indeks optimasi retensi.

---

## ✅ Skenario Penerimaan dan Pengujian

Pengujian mencakup: inisialisasi volume kosong, penanganan kegagalan migrasi, commit database sebelum respons `202`, deduplikasi event setelah restart service, korelasi firing/resolved, pemulihan mode WAL, penegakan retensi 30 hari, ambang batas kapasitas 100 MiB & 250 MiB, pemulihan antrean macet pasca-crash, batasan retry exhaustion, dan perlindungan data insiden aktif.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.6 / `devops-lab`).**
Persistensi database SQLite pada volume bernama `diagnostic_data`, mode WAL, migrasi otomatis skema (`001` s/d `007`), proteksi deduplikasi, retensi 30 hari, pemulihan kuncian macet otomatis (*stale lock recovery*), penegakan batas retry crash loop, serta telemetri metrik kapasitas database telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-005](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md), [TN-007](../engineering-journal/diagnostic-mvp-pilot/TN-007-implement-worker-canonical-result-and-renderers.md), [TN-018](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md), [TN-006](../engineering-journal/monitoring-platform-integration/TN-006-implement-multi-domain-diagnostic-dispatcher-and-decision-engines.md), dan [TN-007](../engineering-journal/monitoring-platform-integration/TN-007-implement-stale-lock-recovery-and-sqlite-state-resilience.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [Runtime Configuration and Verification Contract](runtime-configuration-and-verification-contract.md)
- [TN-005 — Implement Durable Diagnostic Ingestion and Queue](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md)
- [TN-015 — Deploy Persistent Monitoring Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md)
- [TM-ADR-0008 — SQLite Embedded Persistence Lifecycle](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md)

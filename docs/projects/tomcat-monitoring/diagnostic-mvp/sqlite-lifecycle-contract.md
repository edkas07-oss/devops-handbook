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

## 📋 Data Logis Minimum

Skema fisik merepresentasikan:
- Migrasi skema (`schema_migrations`);
- Permintaan dan event alert (`diagnostic_events`);
- Riwayat insiden dan status siklus hidup;
- Identitas target kanonikal;
- Hasil kanonikal terstruktur (`canonical_results`);
- Ringkasan bukti terbatas (`evidence_summaries`);
- Aturan kustom deklaratif (`custom_rules` dengan branch unik);
- Riwayat percobaan notifikasi (`delivery_attempts`);
- Kunci deduplikasi dan status pemeliharaan.

---

## ✅ Skenario Penerimaan dan Pengujian

Pengujian mencakup: inisialisasi volume kosong, penanganan kegagalan migrasi, commit database sebelum respons `202`, deduplikasi event setelah restart service, korelasi firing/resolved, pemulihan mode WAL, penegakan retensi 30 hari, ambang batas kapasitas 100 MiB & 250 MiB, serta perlindungan data insiden aktif.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Persistensi database SQLite pada volume bernama `diagnostic_data`, mode WAL, migrasi otomatis skema (termasuk `004-custom-rules.sql`), proteksi deduplikasi, retensi, dan ketahanan data saat container direstart telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-005](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md), [TN-007](../engineering-journal/diagnostic-mvp-pilot/TN-007-implement-worker-canonical-result-and-renderers.md), [TN-013](../engineering-journal/diagnostic-mvp-pilot/TN-013-rebuild-and-verify-diagnostic-service-mailpit-runtime.md), [TN-015](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md), [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md), dan [TN-018](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [Runtime Configuration and Verification Contract](runtime-configuration-and-verification-contract.md)
- [TN-005 — Implement Durable Diagnostic Ingestion and Queue](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md)
- [TN-015 — Deploy Persistent Monitoring Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md)
- [TM-ADR-0008 — SQLite Embedded Persistence Lifecycle](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md)

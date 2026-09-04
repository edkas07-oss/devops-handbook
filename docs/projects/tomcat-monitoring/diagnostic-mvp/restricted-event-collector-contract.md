# Restricted Event Collector Contract

## 🔍 Overview

Restricted Event Collector menyediakan bukti telemetri container dan host tanpa memberikan Diagnostic Service akses langsung ke Podman socket atau host-control API. Desain sistem menggunakan host-side *rootless service* dan partisi spool ternormalisasi satu arah (*one-way normalized spool*).

---

## 🏛️ Batas Kepemilikan dan Bentuk Layanan

Source code, packaging, siklus hidup, dan component test collector dikelola oleh repositori `tomcat-diagnostic-event-collector`. Repositori `tomcat-monitoring` mengelola allowlist target, konfigurasi deployment, integrasi spool *read-only*, dan verifikasi *end-to-end*.

Collector berjalan sebagai layanan *rootless* di level host. Layanan ini menuliskan rekaman JSON berversi melalui berkas sementara (*temporary file*) dan melakukan *atomic rename* ke direktori partisi target. Direktori spool di-mount secara hanya-baca (*read-only*) ke dalam container Diagnostic Service. Tidak ada jalur request API dari webhook ke collector.

---

## 🔐 Batasan Allowlist

Collector hanya diizinkan membaca:

- Siklus hidup dan status container yang cocok dengan identitas target yang terkonfigurasi;
- Exit code, waktu start/finish, event restart, dan indikator OOM;
- Event kernel cgroup memory yang disetujui (`memory.events` / `oom_kill`);
- Status layanan user-systemd dan log insiden kernel OOM terbatas; serta
- Metadata kapasitas untuk path diagnostik yang disetujui.

Collector menolak pembacaan identitas container arbitrary, eksekusi command, path filesystem di luar allowlist, mutasi runtime, perintah `exec`, `start`, `stop`, `restart`, `remove`, maupun `create`. Bukti yang memerlukan hak akses istimewa (*privilege*) yang belum disetujui dilaporkan sebagai `unavailable`; collector tidak pernah menaikkan hak akses (*privilege escalation*) secara otomatis.

---

## 📦 Kontrak Rekaman Spool (*Record Contract*)

Setiap rekaman memuat versi skema, identitas target kanonikal, generasi runtime, jenis event ternormalisasi, waktu event UTC, sumber bukti (*source*), nilai typed terbatas (*bounded typed value*), status redaksi, dan status pengumpulan. Satu rekaman dibatasi maksimum **16 KiB**. Retensi spool, jumlah berkas, total ukuran spool, dan jendela waktu pembacaan dibatasi dan divalidasi secara ketat.

---

## ✅ Skenario Penerimaan dan Pengujian

Verifikasi wajib membuktikan isolasi identitas, perilaku pembacaan atomik (*atomic rename & read*), retensi terbatas, penolakan rekaman rusak (*malformed record*), penolakan *symlink/path-escape*, penanganan sumber bukti tidak tersedia, serta ketiadaan celah kontrol container (*zero control surface*).

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-event-collector` / `devops-lab`).**
Repositori tata kelola, logika penulisan atomik spool JSON, component test, mount direktori spool hanya-baca (`/run/tomcat-diagnostic/spool`), dan verifikasi korelasi insiden live telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-016](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md) dan [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Target and Evidence Contract](target-and-evidence-contract.md)
- [TomcatDown Rule Specification](tomcat-down-rule-specification.md)
- [Knowledge Base and AI Enrichment Architecture](knowledge-base-and-ai-enrichment-architecture.md)
- [TN-016 — Implement Restricted Collector and Tomcat Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md)
- [TN-017 — Verify End-to-End Incident Diagnostic Flow](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)
- [TM-ADR-0012 — Restricted Event Collector and Spool Delivery Boundary](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0012.md)

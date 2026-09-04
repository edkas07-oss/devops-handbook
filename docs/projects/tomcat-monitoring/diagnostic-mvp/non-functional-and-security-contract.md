# Non-Functional and Security Contract

## 🔍 Overview

Kelengkapan diagnostik tunduk pada prioritas ketersediaan (*availability*) runtime Tomcat. Seluruh pekerjaan dibatasi (*strictly bounded*) dan Diagnostic Service melakukan degradasi terkontrol (*graceful degradation*) ketika sumber bukti atau kapasitas host tidak memadai.

---

## 📏 Batasan Non-Fungsional (*Pilot Limits*)

| Kontrol Parameter | Nilai Batas Pilot |
| :--- | ---: |
| Diagnostic Workers | `1` (*single worker*) |
| Kapasitas Antrean Pekerjaan | `50` item |
| Timeout Global Diagnostik | `60` detik |
| Batas Memori Container (*Limit*) | `256` MiB |
| Batas CPU Container (*Limit*) | `500` millicores |
| Target Memori Kondisi Idle | `64` MiB |
| Target CPU Kondisi Idle | `10` millicores |
| Batas Payload Request Webhook | `256` KiB |
| Batas Payload Ingest Rules API | `64` KiB |
| Input Log per Insiden | `500` baris / `512` KiB |
| Ringkasan Bukti per Insiden | `256` KiB |
| Target / Batas Keras Database SQLite | `100` MiB / `250` MiB |

Ketika CPU host melebihi 90%, memori yang tersedia kurang dari 512 MiB, atau sisa ruang filesystem di bawah 5%, pengambilan metrik dan log opsional dilewati (*skipped*). Service akan mengeluarkan hasil diagnosis parsial berbasis bukti yang ada (*partial evidence-only result*). Ambang batas menerapkan mekanisme jeda (*cooldown/hysteresis*) sebelum pekerjaan opsional dapat dilanjutkan kembali.

---

## 🔐 Batasan Keamanan (*Security Boundary*)

- Webhook menggunakan enkripsi TLS ketat, autentikasi bearer token, jaringan internal khusus container, tanpa port host yang terbuka, batas ukuran 256 KiB, dan validasi skema Ajv.
- Rules API (`/api/v1/rules`) bersifat *strictly append-only* yang ditegakkan oleh **5-Layer Ingestion Guard**: autentikasi bearer *timing-safe*, validasi skema Ajv (`rulepack-v1`), deteksi tabrakan aturan (proteksi TD-01 s/d TD-08 & keunikan branch), batas payload 64 KiB, dan pemeriksaan keamanan Regex.
- Metode mutasi (`PUT`, `DELETE`, `PATCH`) pada Rules API dilarang keras dan menghasilkan respons `405 Method Not Allowed`.
- Berkas secret dan sertifikat TLS disimpan di luar Git (*non-Git storage*) dan di-mount secara hanya-baca (*read-only*).
- Diagnostic Service tidak memiliki akses ke Podman socket host, host namespace, eksekusi command arbitrary, kontrol siklus hidup container lain, maupun pembacaan direktori di luar allowlist.
- Path bukti dan pemetaan target hanya bersumber dari konfigurasi allowlist lokal (`targets.json`).
- Mount direktori spool event collector dan log Tomcat berstatus hanya-baca (*read-only*).
- Seluruh label, anotasi, log, dan artefak yang tidak tepercaya disanitasi sebelum disimpan ke database, dicatat di log, atau dimasukkan ke notifikasi email.
- Lingkungan operasional tidak memuat runtime LLM lokal, database vektor, pengindeks log kontinu, message broker berat, maupun database yang dikelola terpisah.

---

## 🩺 Health Check dan Metrik Operasional

- **Liveness:** Mengindikasikan bahwa proses Node.js masih berjalan dan responsif.
- **Readiness:** Mewajibkan konfigurasi valid, migrasi skema database berhasil, SQLite dapat ditulisi di bawah batas keras 250 MiB, serta kemampuan menerima pekerjaan baru secara tahan-uji. Ketiadaan sumber bukti opsional tidak menggagalkan status readiness.
- **Metrik Prometheus:** Mengekspos metrik event diterima/ditolak/duplikat, kedalaman antrean, durasi pengumpulan bukti, status hasil, sumber bukti yang tidak tersedia, status pengiriman notifikasi, ukuran database SQLite, siklus housekeeping, dan penolakan isolasi. Metrik tidak pernah mengekspos label sensitif atau konten rahasia.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Seluruh batasan non-fungsional, alokasi resource (256 MiB RAM, 0.5 CPU), batas payload, isolasi rootless, 5-layer ingestion guard pada Rules API, penolakan mutasi 405, sanitasi bukti, serta probe liveness/readiness/metrics telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-008](../engineering-journal/diagnostic-mvp-pilot/TN-008-implement-secure-service-and-smtp-delivery-boundaries.md), [TN-009](../engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md), [TN-010](../engineering-journal/diagnostic-mvp-pilot/TN-010-build-and-verify-diagnostic-service-image.md), [TN-011](../engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md), [TN-015](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md), [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md), dan [TN-018](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Target and Evidence Contract](target-and-evidence-contract.md)
- [Knowledge Base and AI Enrichment Architecture](knowledge-base-and-ai-enrichment-architecture.md)
- [Runtime Configuration and Verification Contract](runtime-configuration-and-verification-contract.md)
- [TN-008 — Implement Secure Service and SMTP Delivery Boundaries](../engineering-journal/diagnostic-mvp-pilot/TN-008-implement-secure-service-and-smtp-delivery-boundaries.md)
- [TN-018 — Implement Strict Declarative Rulepack Engine](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)
- [TM-ADR-0010 — Non-Functional Boundaries and Capacity Shedding](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)

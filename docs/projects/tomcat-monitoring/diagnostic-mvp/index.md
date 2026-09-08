# Diagnostic MVP

## 🔍 Overview

Diagnostic MVP menambahkan diagnosis deterministik berbasis bukti (*evidence-based deterministic diagnosis*) pada alur alert Tomcat Monitoring. Seluruh komponen Diagnostic Service, Restricted Event Collector, Declarative Rulepack Engine, integrasi Alertmanager, persistensi SQLite, dan notifikasi Mailpit telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan persisten `devops-lab` ([TN-001](../engineering-journal/diagnostic-mvp-pilot/TN-001-define-diagnostic-mvp-architecture-and-contract.md) s/d [TN-020](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md)).

Arsitektur sistem mengadopsi **5-Layer Knowledge Base and AI Enrichment Architecture**: evaluasi pohon keputusan deterministik `TD-01` s/d `TD-08`, evaluasi dynamic rulepack (`rulepack-v1.schema.json`) untuk aturan kustom seperti `TD-09` (*DatabaseConnectionPoolExhausted*), serta ingestion API `POST /api/v1/rules` dengan 5 lapis pengamanan (*Strict 5-Layer Ingestion Guard*) yang memungkinkan penambahan aturan baru secara instan (*hot-loaded*) tanpa restart container.

---

## 🎯 Pilot Objective

Target utama pilot adalah membuktikan keandalan alur deterministik berikut tanpa remediasi otomatis (*automatic remediation*):

```text
Prometheus
    -> Alertmanager
    -> Diagnostic Service
    -> SQLite and bounded evidence correlation
    -> Mailpit (Laporan SRE 7-Seksi)
    -> Notifikasi Pemulihan (Resolved Notification)
```

Diagnostic Service memberikan bantuan analisis akar masalah (*Root Cause Analysis / RCA*) yang objektif bagi operator SRE. Service ini tidak menjalankan restart container, force kill, perubahan konfigurasi, kontrol container, maupun eksekusi remediasi otomatis.

---

## 📚 Scope

| Kapabilitas (*Capability*) | Status Fase Pilot |
| :--- | :--- |
| Diagnosis `TomcatDown` | Engine, loader rulepack, dan alur end-to-end terverifikasi live di `devops-lab` |
| Health check aplikasi sebagai bukti pendukung `TomcatDown` | Diizinkan dan terverifikasi saat dipetakan ke target yang sama |
| Diagnosis `ApplicationHealthCheckFailed` | Ditunda (*deferred*) dan dinonaktifkan (*disabled*) |
| Diagnosis `TomcatHighHeapUsage` | Ditunda (*deferred*) dan dinonaktifkan (*disabled*) |
| Pengiriman Notifikasi Mailpit | Terverifikasi live untuk siklus firing, laporan 7-seksi, dan resolved |
| Declarative Rulepack Engine & Rules API | Terimplementasi dan terverifikasi live (5-Layer Ingestion Guard, hot-reloading) |
| Alur Kerja Pengayaan AI (*AI Enrichment Workflow*) | Terverifikasi live (ekstraksi forensik -> sintesis aturan AI -> pemetaan ulang instan) |
| Integration Bridge | Dinonaktifkan; tidak ada koneksi jaringan, retry, atau antrean |
| TrueSight Integration | Dinonaktifkan dan bukan merupakan dependensi fase pilot |
| Remediasi Otomatis (*Automatic Remediation*) | Dikecualikan (*strictly excluded*) |

Alert pemantauan *application health* existing tetap berfungsi sebagai notifikasi monitoring standar. Alert tersebut tidak masuk ke Diagnostic Service dan bukan bagian dari kriteria penerimaan Diagnostic MVP.

---

## 🧭 Urutan Pembacaan Dokumen Otoritatif (*Authoritative Reading Order*)

1. **[Halaman Index ini](index.md)** untuk gambaran umum ruang lingkup dan batasan sistem.
2. **[TomcatDown Rule Specification](tomcat-down-rule-specification.md)** untuk spesifikasi aturan evaluasi TD-01 s/d TD-08 dan ekstensibilitas rulepack.
3. **[Alertmanager Webhook Contract](alertmanager-webhook-contract.md)** untuk kontrak penerimaan webhook dari Alertmanager.
4. **[Target and Evidence Contract](target-and-evidence-contract.md)** untuk batas isolasi target dan sumber bukti terbatas.
5. **[Restricted Event Collector Contract](restricted-event-collector-contract.md)** untuk kontrak pengumpulan bukti host/container secara rootless.
6. **[Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)** untuk taksonomi klasifikasi, confidence, dan Canonical Result JSON.
7. **[SQLite Lifecycle Contract](sqlite-lifecycle-contract.md)** untuk persistensi status insiden, mode WAL, dan proteksi kapasitas.
8. **[Notification and Integration Contract](notification-and-integration-contract.md)** untuk format laporan 7-seksi dan batasan integrasi.
9. **[Non-Functional and Security Contract](non-functional-and-security-contract.md)** untuk batasan resource, 5-layer ingestion guard, dan keamanan rootless.
10. **[Runtime Configuration and Verification Contract](runtime-configuration-and-verification-contract.md)** untuk konfigurasi `application.json`, hak akses file, dan verifikasi runtime.
11. **[Requirements Traceability](requirements-traceability.md)** untuk matriks pemetaan pemenuhan seluruh persyaratan pilot.
12. **[Knowledge Base and AI Enrichment Architecture](knowledge-base-and-ai-enrichment-architecture.md)** untuk arsitektur 5-layer basis pengetahuan dan integrasi AI.
13. **[Gap Register](gap-register.md)** untuk catatan penutupan seluruh kesenjangan teknis pilot.
14. **Katalog ADR Tomcat Monitoring** ([`docs/adr/tomcat-monitoring/index.md`](../../../adr/tomcat-monitoring/index.md)) untuk dasar keputusan arsitektur formal.

ADR yang diterima memiliki prioritas tertinggi untuk keputusan arsitektur. Kontrak teknis mengatur domain spesifiknya. Source code repositori dan bukti verifikasi live pada runtime menjadi sumber kebenaran implementasi aktual.

---

## ✅ Kriteria Keluar Pilot (*Pilot Exit Criteria*)

Seluruh kriteria keluar (*exit criteria*) telah diverifikasi dan terpenuhi 100%:

- [x] Siklus hidup firing, duplicate, material-update, dan resolved lulus end-to-end;
- [x] Bukti telemetri antar target Tomcat terisolasi secara ketat dan tidak dapat saling silang;
- [x] Jalur high-confidence (`TD-06`, `TD-09`), partial, evidence-only, dan `UNDETERMINED` telah diuji;
- [x] Normalisasi bukti dan rule versioning menghasilkan diagnosis yang deterministik dan konsisten;
- [x] SQLite bertahan melewati restart container dan menegakkan retensi serta proteksi kapasitas;
- [x] Pesan laporan 7-seksi (HTML dan Plain Text) tersanitasi dengan rekomendasi SOP Bahasa Indonesia;
- [x] Disabled bridge dan TrueSight tidak menghasilkan aktivitas jaringan atau antrean;
- [x] Percobaan akses path arbitrary, container control, atau command execution ditolak;
- [x] Penambahan aturan deklaratif (`POST /api/v1/rules`) aman dan langsung aktif tanpa restart;
- [x] Seluruh blocking gaps telah diselesaikan.

---

## 📌 Status Terkini (*Current Status*)

**Fase Diagnostic MVP Pilot Selesai 100% dan Terverifikasi Live.** Seluruh alur end-to-end dari Prometheus, Alertmanager, Diagnostic Service (`0.1.4`), Restricted Event Collector, Declarative Rulepack Engine, alur pengayaan AI, hingga notifikasi Mailpit dan pemulihan (*resolved*) telah diuji dan beroperasi stabil pada lingkungan persisten `devops-lab`. Dokumen konsolidasi dan perencanaan fase berikutnya dicatat pada [TN-020](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md).

---

## 🔗 Related Documentation

- [Tomcat Monitoring Architecture](../architecture/index.md)
- [Tomcat Monitoring Engineering Journal](../engineering-journal/index.md)
- [Diagnostic MVP Pilot Engineering Journal](../engineering-journal/diagnostic-mvp-pilot/index.md)
- [Tomcat Monitoring ADR Catalog](../../../adr/tomcat-monitoring/index.md)

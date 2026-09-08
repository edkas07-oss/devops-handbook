# TM-ADR-0018

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0018 |
| **Title** | Adopt Strict Declarative Rulepack Engine and Append-Only Ingestion API |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Rule and Extensibility Architecture |
| **Status** | Accepted |
| **Date** | 2026-09-02 |

---

## 🔍 Overview

Diagnostic Service mengadopsi mesin aturan deklaratif berbasis skema JSON (`rulepack-v1.schema.json`), evaluasi dinamis di dalam memori (*in-memory dynamic evaluation*) tanpa *restart* container, serta antarmuka *Append-Only Rule Ingestion* (`POST /api/v1/rules`) dengan penolakan eksplisit terhadap mutasi atau penghapusan aturan.

## 🌍 Context

Pada fase awal MVP, seluruh aturan diagnostik (`TD-01` s.d. `TD-08`) dikodekan secara statis (*hard-coded*) di dalam modul aplikasi. Pendekatan ini memiliki sejumlah kelemahan seiring bertambahnya pola kegagalan baru:

1. **Ketergantungan Siklus Rilis Aplikasi:** Penambahan satu aturan kegagalan baru memerlukan modifikasi kode sumber, proses *build* ulang image container, dan *restart* layanan produksi, yang meningkatkan risiko *downtime* observabilitas.
2. **Ketiadaan Validasi Skema Standar:** Tanpa validasi skema yang ketat, aturan kustom berisiko mengandung kesalahan sintaksis, logika pencocokan bukti yang cacat (*faulty matchers*), atau ketiadaan tindakan rekomendasi (*remediation actions*).
3. **Risiko Integritas Audit:** Kemampuan mengubah (*update*) atau menghapus (*delete*) aturan yang sedang berjalan dapat merusak jejak audit (*auditability*) dan merusak konsistensi diagnosis insiden historis.

## ⚖️ Decision

Ditetapkan keputusan arsitektur untuk mentransformasi sistem aturan diagnostik menjadi **Strict Declarative Rulepack Platform**:

1. **Format Aturan Deklaratif Standar (`rulepack-v1.schema.json`):**
   - Setiap paket aturan (*rulepack*) didefinisikan dalam format JSON terstruktur yang memuat metadata identitas (`id`, `name`, `version`, `severity`), matcher bukti (*predicates*, *operators*, *thresholds*), dan rekomendasi tindakan kanonikal (*actionable remediation playbook*).
   - Validasi ketat ditegakkan melalui *5-Layer Validation Guard* (Schema Structure, Matcher Semantic, Output Contract, Target Resolution, Logic Evaluation) sebelum aturan dapat diterima sistem.

2. **Persistensi Terisolasi dan Hot-Reload Dinamis:**
   - Aturan kustom yang lolos validasi disimpan secara persisten di tabel SQLite `custom_rules` (Migration `005`).
   - Komponen `DynamicRuleEvaluator` memuat seluruh aturan aktif ke dalam memori saat *startup* dan menyediakan mekanisme penyegaran seketika (*hot-reloading*) saat ada aturan baru yang terdaftar, tanpa menghentikan atau me-restart container Diagnostic Service.

3. **Prinsip Imutabilitas dan Append-Only API:**
   - Ingesti aturan hanya dilayani melalui endpoint `POST /api/v1/rules`.
   - Endpoint mutasi dan penghapusan (`PUT /api/v1/rules/:id`, `PATCH /api/v1/rules/:id`, `DELETE /api/v1/rules/:id`) ditolak secara eksplisit dengan kode status HTTP `405 Method Not Allowed`.
   - Setiap pembaruan logika aturan wajib diterbitkan sebagai versi aturan baru (*immutable rule versioning*) guna menjaga ketertelusuran forensik.

## 🏛️ Architecture

```text
Operator / Forensic AI Pipeline
          |
          | HTTP POST /api/v1/rules (rulepack payload)
          v
+-------------------------------------------------------------------+
| Diagnostic Service Runtime                                        |
|                                                                   |
|  [ Ingestion Guard: 5-Layer Schema & Semantic Validator ]        |
|                            | (Valid)                              |
|                            v                                      |
|  [ SQLite Database: table `custom_rules` (Persistent Store) ]    |
|                            |                                      |
|                            v (Hot-Reload Notification)            |
|  [ DynamicRuleEvaluator (In-Memory Active Rule Cache) ]           |
|                            |                                      |
|                            v (Evaluates on TomcatDown Alerts)     |
|  [ Multi-Source Evidence Correlation Engine ]                     |
+-------------------------------------------------------------------+
```

## 💡 Rationale

- **Zero Downtime Rule Extensibility:** Tim SRE dapat memperluas jangkauan deteksi pola kegagalan Tomcat baru secara instan tanpa mengganggu kontinuitas pemantauan.
- **Integritas Forensik dan Auditability:** Penegakan *append-only* menjamin bahwa hasil diagnosis historis yang disimpan di database selalu dapat ditelusuri ke versi aturan persis yang mengevaluasinya pada saat kejadian.
- **Fail-Safe Operation:** Validasi 5 lapis mencegah malformasi payload atau aturan ilegal menginjeksi kode berbahaya atau merusak memori evaluator.

## ⚠️ Consequences

- **Kelebihan:**
  - Kemudahan integrasi otomatis dengan sistem sintesis aturan forensik (*Out-of-Band AI loop*).
  - Isolasi kegagalan aturan kustom tanpa memengaruhi aturan bawaan (*built-in baseline rules*).
- **Keterbatasan:**
  - Memerlukan skema migrasi database (`005_create_custom_rules.sql`) dan pengelolaan memori cache aturan di runtime.
  - Aturan yang sudah tidak relevan (*deprecated*) harus dinonaktifkan via flag status atau digantikan oleh versi aturan yang lebih baru, bukan dihapus dari database.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-09-02**

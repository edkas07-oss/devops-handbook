# TM-ADR-0006

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0006 |
| **Title** | Use Deterministic Multi-Source Evidence for Diagnostic Assessment |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Asesmen diagnostik menggunakan korelasi deterministik dari multi-sumber bukti yang dibatasi dan dinormalisasi (*bounded normalized evidence*). Runtime AI/LLM pada level produksi tidak digunakan.

## 🌍 Context

Alert Prometheus mengidentifikasi sebuah gejala (*symptom*). Bukti pendukung seperti metrik, log, artefak crash (seperti file `hs_err_pid`), siklus hidup container (*lifecycle*), event host, dan health check aplikasi dapat mendukung atau menyangkal suatu dugaan penyebab. Namun, satu sinyal umum saja tidak dapat membuktikan akar masalah (*Root Cause Analysis / RCA*) secara aman dan andal.

## ⚖️ Decision

Seluruh aturan diagnostik mengikuti alur: `Bukti (Evidence) -> Pengamatan (Observation) -> Asesmen (Assessment) -> Rekomendasi Tindakan (Recommended Action)`.

Setiap bukti mencatat sumber (*source*), target, waktu, status pengumpulan (*collection status*), bobot keyakinan (*strength*), serta nilai yang telah disanitasi dan dibatasi batas ukurannya (*bounded sanitized value*). Bukti yang tidak tersedia tetap dicatat secara eksplisit (*missing evidence remains explicit*). Input ternormalisasi dan versi aturan yang sama harus selalu menghasilkan output penilaian yang sama persis (deterministik).

## 🏛️ Architecture

Diagnostic Service mengumpulkan bukti dari adapter yang telah terdaftar dalam allowlist, menormalisasi bukti, menerapkan tabel keputusan (*decision table*) aturan berversi, dan menghasilkan satu hasil kanonikal (*canonical result*).

## 💡 Rationale

Aturan deterministik dapat diaudit (*auditable*), dapat direproduksi (*reproducible*), memiliki batasan konsumsi sumber daya (*resource-bounded*), serta cocok dengan lingkup bukti pilot yang tersedia. Penilaian berbasis skor generik, penentuan RCA berbasis sinyal tunggal, dan runtime LLM ditolak karena berisiko melebih-lebihkan kausalitas (*overstating causality*) serta menambah ketergantungan operasional yang tidak perlu.

## ⚠️ Consequences

- Aturan diagnostik (*rules*) dan berkas pengujian (*test fixtures*) memerlukan pemeliharaan eksplisit.
- Hasil asesmen yang belum dapat dipastikan (*undetermined*) atau hanya terbukti sebagian (*partial*) tetap ditampilkan apa adanya secara transparan, bukan dipaksakan menjadi kesimpulan penyebab yang dikarang (*invented cause*).

## 📌 Status

**Accepted — implementasi ditunda (implementation pending).**

## 📅 Date

**2026-08-30**

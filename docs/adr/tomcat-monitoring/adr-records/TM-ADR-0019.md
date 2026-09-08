# TM-ADR-0019

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0019 |
| **Title** | Adopt Out-of-Band AI Forensic Enrichment Loop for Diagnostic Rule Synthesis |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic AI and Continuous Learning Architecture |
| **Status** | Accepted |
| **Date** | 2026-09-03 |

---

## 🔍 Overview

Mengukuhkan arsitektur **5-Layer Knowledge Base Feedback Loop** di mana insiden anomali yang belum teridentifikasi (*UNDETERMINED / TD-08*) mempertahankan seluruh rekaman forensik di database SQLite, sehingga analisis pasca-insiden (*post-mortem*) dapat memanfaatkan kapabilitas LLM/AI secara *out-of-band* (di luar jalur evaluasi runtime produksi) untuk mensintesis paket aturan deklaratif baru (`rulepack-v1.schema.json`) dan diinjeksikan secara aman ke dalam Diagnostic Service.

## 🌍 Context

Pada [TM-ADR-0006](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring/adr-records/TM-ADR-0006.md), telah diputuskan bahwa runtime evaluasi produksi tidak boleh bergantung pada LLM/AI secara langsung demi menjaga kepastian (*determinism*), reproduktibilitas audit, latensi rendah, serta menghindari halusinasi kausalitas pada saat insiden aktif terjadi.

Namun, dalam operasional enterprise, pola kegagalan baru yang belum terpetakan (seperti kebocoran thread tertentu, *deadlock*, atau anomali konfigurasi langka) pasti akan muncul. Jika insiden tersebut tidak cocok dengan aturan yang ada, sistem akan menandainya sebagai `UNDETERMINED`. Tim SRE membutuhkan metode sistematis untuk memanfaatkan kecerdasan AI dalam menganalisis data forensik insiden tanpa melanggar batasan deterministik runtime produksi.

## ⚖️ Decision

Ditetapkan pola arsitektur **Out-of-Band AI Forensic Enrichment Loop** yang terdiri dari 5 lapisan (*5-layer cycle*):

1. **Layer 1 — Forensic Multi-Source Ingestion:**
   - Diagnostic Service mengumpulkan telemetri multi-sumber (metrik Prometheus, log kontainer, artefak crash, event spool host) saat insiden terjadi.
2. **Layer 2 — Deterministic Evaluation & Undetermined Fallback:**
   - Engine mengevaluasi aturan yang ada. Jika tidak ada aturan yang cocok (*no rule match*), insiden diklasifikasikan secara transparan sebagai `UNDETERMINED` (TD-08).
   - Seluruh snapshot bukti (*evidence payload*) disimpan secara persisten di tabel SQLite `incidents` dan `incident_evidence`.
3. **Layer 3 — Out-of-Band AI Post-Mortem Synthesis:**
   - Secara *offline* / *out-of-band* (tidak menghalangi jalur alerting utama), data forensik dari SQLite diekstraksi dan dianalisis menggunakan LLM/AI.
   - AI merekonstruksi hipotesis kegagalan dan mensintesis definisi aturan deklaratif baru yang sesuai dengan standar `rulepack-v1.schema.json` (misalnya aturan `TD-09` untuk deteksi *stale thread exhaustion*).
4. **Layer 4 — Schema & Test Fixture Verification Gate:**
   - Rulepack hasil sintesis AI wajib melalui gerbang validasi skema (*Schema Validation*) dan pengujian deterministik terhadap *test fixture* di lingkungan lab sebelum disetujui.
5. **Layer 5 — Ingestion & In-Memory Hot-Reload:**
   - Rulepack yang telah terverifikasi didaftarkan ke Diagnostic Service melalui API `POST /api/v1/rules` ([TM-ADR-0018](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring/adr-records/TM-ADR-0018.md)), disimpan ke tabel `custom_rules`, dan dimuat ke dalam memori evaluator seketika.

## 🏛️ Architecture

```text
[ Jalur Kritis Runtime Produksi (100% Deterministik) ]
Prometheus Alert --> Diagnostic Service Ingestion
                            |
                     Evaluasi Aturan
                       /         \
          (Cocok)     /           \  (Tidak Cocok)
                     v             v
       RCA Teridentifikasi     UNDETERMINED (TD-08)
             |                     |
             +--------+------------+
                      |
                      v
             SQLite Database (Forensic Evidence Stored)
                      |
======================|===============================================
                      v [ Ekstraksi Forensik Pasca-Insiden (Out-of-Band) ]
[ Siklus AI Enrichment & Knowledge Base (Offline / Asynchronous) ]
                      |
                      v
          LLM / AI Post-Mortem Analysis
                      |
                      v
          Sintesis Rulepack Baru (e.g. TD-09)
                      |
                      v
          Validasi Skema & Uji Fixture Lab
                      |
                      v
       HTTP POST /api/v1/rules (Hot-Reload ke Runtime)
```

## 💡 Rationale

- **Mempertahankan Keandalan Runtime TM-ADR-0006:** Evaluasi insiden langsung di lini depan tetap 100% deterministik, cepat (< 500ms), tanpa ketergantungan jaringan eksternal atau risiko API timeout dari penyedia model AI.
- **Continuous Observability Evolution:** Sistem tidak stagnan; setiap kali kegagalan baru terjadi, bukti forensik yang lengkap menjadi bahan baku pembelajaran untuk memperkaya basis aturan diagnostik secara berkelanjutan.
- **Human-in-the-Loop & Schema Safety:** Aturan hasil penalaran AI tidak langsung dieksekusi secara buta, melainkan melewati validasi skema ketat dan verifikasi lab terlebih dahulu.

## ⚠️ Consequences

- **Kelebihan:**
  - Menjembatani kebutuhan kecerdasan analitik modern dengan standar determinisme dan kepatuhan perbankan/enterprise yang ketat.
  - Tidak ada biaya latensi (*zero latency penalty*) pada jalur pengiriman notifikasi alert aktif.
- **Keterbatasan:**
  - Penambahan aturan baru memerlukan alur kerja analitik pasca-insiden (baik secara manual oleh SRE dengan bantuan AI tooling, maupun pipeline batch otomatis).
  - Diperlukan kedisiplinan dalam memelihara dataset *test fixture* dan skema migrasi database.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-09-03**

# TM-ADR-0023

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0023 |
| **Title** | Adopt Multi-Domain Diagnostic Dispatcher and Mandatory Per-Alert Decision Engine Governance |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Rule, Decision Engine, and Observability Governance Architecture |
| **Status** | Accepted |
| **Date** | 2026-09-09 |

---

## 🔍 Overview

Platform Tomcat Monitoring menetapkan arsitektur **Multi-Domain Diagnostic Dispatcher** pada Diagnostic Service dan menegakkan kebijakan tata kelola observabilitas **Zero Undecided Alerts**, di mana setiap aturan alert yang didefinisikan di Prometheus **wajib** memiliki pasangan Decision Engine deterministik dan rekomendasi SOP baku yang terdaftar secara resmi di Diagnostic Service.

---

## 🌍 Context

1. **Keterbatasan Asumsi Vertical Slice MVP Terdahulu (TM-ADR-0017):**
   * Pada fase Diagnostic MVP Pilot, investigasi diagnostik sengaja dibatasi hanya pada satu skenario vertikal tunggal, yaitu ketersediaan proses runtime Tomcat (`TomcatDown`) melalui Decision Tree `TD-01` hingga `TD-08`.
   * Akibatnya, modul evaluasi bawaan di-hardcode dengan identitas `ruleId: "TomcatDown"`.

2. **Perluasan Universal Ingestion (TM-ADR-0016):**
   * Sesuai prinsip *Single Canonical Notification Authority* (TM-ADR-0016), seluruh alert dari Prometheus/Alertmanager (termasuk kegagalan health check HTTP aplikasi dan sinyal emas performa/saturasi JVM) dialirkan secara universal ke Diagnostic Service melalui webhook HTTPS.
   * Ketika alert performa JVM (`TomcatGCPauseHigh`, `TomcatThreadPoolSaturated`, `TomcatGCOverheadHigh`, `TomcatOldGenMemoryPressure`) dan alert aplikasi (`TomcatApplicationHealthFailed`) masuk, ketiadaan mekanisme *dispatching* multi-domain menyebabkan seluruh alert tersebut secara keliru dinilai oleh pohon keputusan `TomcatDown` dan menghasilkan laporan/email dengan subjek yang tidak akurat (`TomcatDown`).

3. **Prinsip Tata Kelola Observabilitas Baku (Observability Governance):**
   * Dalam standar rekayasa keandalan sistem (SRE), sistem tidak boleh mendefinisikan dan menyalakan alert monitoring tanpa adanya prosedur analisis diagnosis dan rencana penanganan (*Standard Operating Procedure*) yang baku.
   * Setiap alert yang firing harus dapat diklasifikasikan penyebabnya secara presisi berdasarkan bukti forensik dan telemetri yang relevan dengan domain masalahnya.

---

## ⚖️ Decision

Ditetapkan keputusan arsitektur dan tata kelola diagnostik sebagai berikut:

1. **Penegakan Prinsip *Zero Undecided Alerts*:**
   * Ditetapkan aturan tata kelola bahwa **setiap penambahan alert rule di Prometheus wajib diiringi dengan pendaftaran Decision Engine dan SOP rekomendasi mitigasi resmi di Diagnostic Service**.
   * Tidak diperbolehkan adanya alert aktif yang tidak memiliki logika evaluasi dan penanganan baku.

2. **Penerapan Arsitektur *Multi-Domain Diagnostic Dispatcher*:**
   * `DiagnosticWorker` tidak lagi memanggil evaluator tunggal `TomcatDown`, melainkan menggunakan komponen **`DiagnosticEngineDispatcher`** (*Strategy Pattern*) yang memetakan `event.labels.alertname` ke Decision Engine domain yang berwenang.
   * Sistem mengelompokkan logika diagnosis ke dalam 4 domain baku:
     1. **Runtime Availability Domain (`TomcatDown`):** Engine `evaluateTomcatDown` dengan cabang `TD-01` s/d `TD-08`.
     2. **Application Health Domain (`TomcatApplicationHealthFailed`, `TelegrafHealthScrapeUnavailable`, `TomcatApplicationHealthMetricsMissing`):** Engine `evaluateApplicationHealth` dengan cabang `AH-01` s/d `AH-05`.
     3. **JVM Memory & GC Domain (`TomcatGCPauseHigh`, `TomcatGCOverheadHigh`, `TomcatOldGenMemoryPressure`):** Engine `evaluateJvmWorkload` dengan cabang `GC-01` s/d `GC-04`.
     4. **Concurrency Saturation Domain (`TomcatThreadPoolSaturated`):** Engine `evaluateConcurrencySaturation` dengan cabang `TH-01` s/d `TH-03`.

3. **Preservasi Identitas Kanonikal Alert (`Rule ID Fidelity`):**
   * Atribut `ruleId` pada Canonical Result v1, Laporan Investigasi 7-Seksi SRE, dan subjek notifikasi email SMTP **wajib mempertahankan nama alert asli** (`event.labels.alertname`), seperti `[WARNING] [LAB] Tomcat Service: TomcatGCPauseHigh (Target: lab/tomcat-01/default)`.

4. **Hierarki Evaluasi 2-Lapis (Layered Evaluation Pipeline):**
   * **Layer 2 (Dynamic Custom Rules / Ingested Rulepacks):** Dievaluasi terlebih dahulu untuk mendeteksi pola regex spesifik pada log/spool.
   * **Layer 1 (Built-in Domain Engines):** Dievaluasi melalui Dispatcher jika tidak ada custom rule Layer 2 yang cocok.

---

## 📊 Matriks 4 Domain Decision Engine Baku

| Domain Insiden | Alert Names Terdampak | Decision Engine | Cabang Keputusan (*Branches*) | Fokus Bukti Forensik & Telemetri |
| :--- | :--- | :--- | :--- | :--- |
| **Ketersediaan Runtime** | `TomcatDown` | `evaluateTomcatDown` | `TD-01` s/d `TD-08` | Status kontainer Podman, cgroup OOM Killer, fatal crash artifact (`hs_err_pid.log`), port binding 9404, dan log shutdown. |
| **Kesehatan HTTP Aplikasi** | `TomcatApplicationHealthFailed`<br/>`TelegrafHealthScrapeUnavailable`<br/>`TomcatApplicationHealthMetricsMissing` | `evaluateApplicationHealth` | `AH-01` s/d `AH-05` | HTTP status code endpoint `/health`, latency timeout probe Telegraf, ketersediaan daemon scraper Telegraf. |
| **Performa Memori & GC JVM** | `TomcatGCPauseHigh`<br/>`TomcatGCOverheadHigh`<br/>`TomcatOldGenMemoryPressure` | `evaluateJvmWorkload` | `GC-01` s/d `GC-04` | Jeda STW max (`jvm_gc_pause_seconds_max`), persentase GC CPU overhead sum, utilisasi pool Tenured / Old Gen. |
| **Saturasi Konkurensi** | `TomcatThreadPoolSaturated` | `evaluateConcurrency` | `TH-01` s/d `TH-03` | Rasio busy/current thread pool connector HTTP, kapasitas antrean request, deteksi thread starvation. |

---

## 🏛️ Architecture

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'edgeLabelBackground': 'transparent',
    'fontSize': '12px'
  }
}}%%
flowchart TD
    %% Ingestion
    AM["Alertmanager (Webhook HTTPS)"] -->|Payload Universal v4| INGEST["Ingest & Normalize Webhook"]
    INGEST -->|Enqueue Normalized Event| DB[(SQLite Database)]
    
    %% Worker
    DB -->|Claim Queue Item| WORKER["Diagnostic Worker Loop"]
    WORKER -->|Ambil Bukti Terkorelasikan| EVIDENCE["Evidence Collector Pipeline"]
    
    %% Dispatcher
    WORKER -->|Dispatch(alertname, evidence)| DISP{"Diagnostic Engine<br/>Dispatcher"}
    
    %% Layer 2 Custom Rules
    DISP -->|1. Cek Layer 2| L2["Layer 2: Dynamic Custom Rules<br/>(Pattern Matching Log/Spool)"]
    L2 -->|Match| RESULT["Canonical Result v1"]
    
    %% Layer 1 Domain Engines
    DISP -->|2. Fallback Domain Engine| L1["Layer 1: Built-in Domain Engines"]
    
    L1 -->|alertname = TomcatDown| E1["Runtime Engine (TD-01..08)"]
    L1 -->|alertname = TomcatAppHealth*| E2["App Health Engine (AH-01..05)"]
    L1 -->|alertname = TomcatGC* / OldGen| E3["JVM Memory & GC Engine (GC-01..04)"]
    L1 -->|alertname = TomcatThreadPool*| E4["Concurrency Engine (TH-01..03)"]
    
    E1 --> RESULT
    E2 --> RESULT
    E3 --> RESULT
    E4 --> RESULT
    
    %% Output
    RESULT --> RENDER["Result Renderer<br/>(Laporan 7-Seksi SRE)"]
    RENDER --> SMTP["SMTP Adapter (Mailpit / Relay)"]
```

---

## 🎯 Consequences

### Konsekuensi Positif (*Positive Consequences*)
1. **Presisi Diagnostik Tinggi:** Operator on-call menerima laporan investigasi dan subjek email yang secara akurat merefleksikan domain masalah spesifik (GC, Thread, HTTP, atau Crash).
2. **Kepatuhan Tata Kelola (*Governance Compliance*):** Menjamin bahwa setiap alert monitoring yang aktif memiliki alur diagnosis dan rekomendasi mitigasi yang jelas tanpa adanya titik buta (*zero unhandled alert*).
3. **Modularitas & Ekstensibilitas:** Penambahan domain alert baru di masa depan cukup dilakukan dengan mendaftarkan sub-engine baru pada Dispatcher tanpa merusak engine yang telah ada.

### Konsekuensi Negatif & Mitigasi (*Negative Consequences & Mitigations*)
1. **Beban Pemeliharaan Engine Domain:**
   * *Konsekuensi:* Menambah jumlah berkas logika domain engine yang harus dipelihara dan diuji unit.
   * *Mitigasi:* Menggunakan pola struktur data input/output asesmen yang seragam (`branch`, `category`, `classification`, `confidence`, `assessment`, `recommendedActions`).
2. **Kebutuhan Pengujian Unit & Live yang Komprehensif:**
   * *Konsekuensi:* Setiap cabang keputusan domain engine harus divalidasi dengan fixture pengujian khusus.
   * *Mitigasi:* Menyediakan unit test terisolasi per domain engine di `test/unit/` dan skrip simulasi live beban kerja di `scripts/`.

---

## 🔗 Related Documents

- [TM-ADR-0016 — Designate Diagnostic Service as the Canonical Incident Notification Authority](TM-ADR-0016.md)
- [TM-ADR-0017 — Adopt Vertical Slice Minimum Viable Product (MVP) Scoping for Diagnostic Pilot](TM-ADR-0017.md)
- [TM-ADR-0018 — Adopt Strict Declarative Rulepack Engine and Append-Only Ingestion API](TM-ADR-0018.md)
- [TM-ADR-0022 — Adopt JVM Garbage Collection and Concurrency Saturation Signals over Static Raw Thresholds](TM-ADR-0022.md)
- [TN-004 — Implement JVM GC and Concurrency Saturation Alert Rules](../../../projects/tomcat-monitoring/engineering-journal/monitoring-platform-integration/TN-004-implement-jvm-gc-and-concurrency-saturation-alert-rules.md)
- [TN-005 — Verify JVM GC and Concurrency Saturation Alert Rules in Live Runtime](../../../projects/tomcat-monitoring/engineering-journal/monitoring-platform-integration/TN-005-verify-jvm-gc-and-concurrency-saturation-alert-rules-in-live-runtime.md)
- [TN-006 — Implement Multi-Domain Diagnostic Dispatcher and Per-Alert Decision Engine Governance](../../../projects/tomcat-monitoring/engineering-journal/monitoring-platform-integration/TN-006-implement-multi-domain-diagnostic-dispatcher-and-decision-engines.md)

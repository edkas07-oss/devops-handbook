# TN-006 — Implement Target Isolation, Evidence Adapters, and TomcatDown Engine

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Mengimplementasikan target isolation, bounded evidence adapters, dan seluruh
branch deterministic `TomcatDown` tanpa mengakses runtime aktual.

## 🌍 Background

TN-005 menyediakan durable ingestion dan queue. Tahap berikutnya harus
mengubah accepted alert menjadi evidence yang tidak dapat melintasi target,
generation, path, atau time window, lalu mengevaluasinya dengan decision table
yang telah diterima.

## 📚 Scope

Scope mencakup trusted target registry, canonical evidence, UTC/generation
window isolation, bounded local-file dan collector-spool reads, Prometheus dan
application-health adapters, TD-01 sampai TD-08 engine, tests, validator,
README, dan current-state documentation.

Collector service, HTTP server, notification, image, deployment, integration
configuration, commit, dan push tidak termasuk scope.

## 📋 Prerequisites

| Prerequisite | State |
| --- | --- |
| TN-005 source | Included in shared commit `aa55170` |
| Target and Evidence Contract | Accepted |
| TomcatDown Rule Specification | Accepted |
| Restricted Collector runtime | Not required; fixture spool only |
| External Prometheus or health endpoint | Not used; fetch fixtures only |
| Implementation authorization | Approved 2026-08-31 |

## 🔄 Technical Workflow

Alur teknis pengumpulan bukti terisolasi (*isolated evidence collection*) dan evaluasi pohon keputusan `TomcatDown`:

```text
1. Trusted target config -> 2. target registry
                         -> 3. bounded adapters -> 4. isolated evidence
                                                -> 5. TD-01 through TD-08
```

### Rincian Aktivitas Alur Kerja

1. **Trusted target config:**
   Konfigurasi non-secret `targets.json` lokal yang mendefinisikan target resmi yang diizinkan untuk dipantau (`environment`, `host`, `tomcat_instance`, health URL, query Prometheus, path log, dan path spool).
2. **target registry:**
   Registri target terisolasi yang memvalidasi integritas konfigurasi: menolak target di luar allowlist, menolak URL non-HTTPS, serta memblokir path berbahaya (path traversal `../`, symlink, atau path di luar direktori yang disetujui).
3. **bounded adapters:**
   Adapter bukti khusus yang dibatasi secara ketat untuk mencegah kebocoran data atau konsumsi sumber daya berlebih:
    - **local-file adapter:** Membaca cuplikan log aplikasi host (`catalina.out`) dengan batas ukuran maksimum 64 KiB dan sensor redaksi data sensitif.
    - **collector-spool adapter:** Membaca rekaman spool status container atomik (`.tmp` $\to$ `.json`) dari direktori spool collector (maksimal 200 berkas).
    - **application-health adapter:** Melakukan probe endpoint HTTP `/health` dengan batas waktu timeout agresif (maksimal 3000ms).
    - **prometheus adapter:** Mengambil metrik telemetri via Prometheus API menggunakan label selector exact-match dan batas waktu query 5000ms.
4. **isolated evidence:**
   Pengumpulan dan agregasi seluruh bukti telemetri yang dibatasi hanya pada jendela waktu kejadian insiden (`startsAt ± 5 menit`) untuk memastikan bukti terisolasi dan spesifik pada insiden Tomcat terkait.
5. **TD-01 through TD-08:**
   Evaluasi bukti oleh Decision Engine deterministik terhadap 8 cabang aturan built-in (`TD-01` s/d `TD-08`) untuk menetapkan klasifikasi akar masalah (*root cause*), asesmen, dan tingkat keyakinan (*confidence*).

### Pseudocode Alur Pengumpulan Bukti & Evaluasi

```python
# Berkas Implementasi: src/application/target-registry.js, src/adapters/*.js, & src/domain/tomcat-down-engine.js

def execute_target_diagnosis(target_id, event):
    # 1. Trusted target config: Muat file konfigurasi targets.json lokal (config/targets.json)
    raw_config = load_target_config("config/targets.json")

    # 2. target registry: Validasi dan resolusi target terhadap allowlist (src/application/target-registry.js)
    target = target_registry.resolve(target_id, raw_config)
    if not target:
        raise UntrustedTargetError(f"Target {target_id} tidak terdaftar pada targets.json")

    # 3. bounded adapters: Eksekusi adapter bukti berbatas waktu dan ukuran (src/adapters/*.js)
    # 4. isolated evidence: Batasi jendela waktu bukti startsAt ± 5 menit (src/domain/evidence.js)
    time_window = calculate_time_window(event.starts_at, delta_minutes=5)
    evidence_items = []

    # - local-file adapter: Baca cuplikan log catalina.out maks 64 KiB (src/adapters/local-file-evidence-adapter.js)
    log_excerpt = local_file_adapter.read_tail(target.log_path, max_bytes=65536)
    if log_excerpt:
        evidence_items.append({"source": "local-file", "data": log_excerpt})

    # - collector-spool adapter: Baca rekaman status container atomik .tmp -> .json (src/adapters/collector-spool-adapter.js)
    spool_records = collector_spool_adapter.read_window(target.spool_path, time_window)
    evidence_items.extend(spool_records)

    # - application-health adapter: Probe status HTTP /health timeout 3000ms (src/adapters/application-health-adapter.js)
    health_status = application_health_adapter.check(target.health_url, timeout_ms=3000)
    evidence_items.append({"source": "application-health", "data": health_status})

    # - prometheus adapter: Kueri metrik telemetri Prometheus exact label match (src/adapters/prometheus-adapter.js)
    metric_sample = prometheus_adapter.query_instant(target.prometheus_query, time_window.end)
    evidence_items.append({"source": "prometheus", "data": metric_sample})

    # 5. TD-01 through TD-08: Evaluasi deterministik terhadap cabang TD-01 s/d TD-08 (src/domain/tomcat-down-engine.js)
    diagnostic_result = evaluate_tomcat_down(evidence_items)
    return diagnostic_result
```

### Pemetaan Berkas Implementasi & Self-Documentation

Setiap tahapan alur kerja dan pseudocode di atas diimplementasikan secara modular pada berkas sumber (*source code*) repositori `tomcat-diagnostic-service` dengan standar *self-documentation* Bahasa Indonesia:

| Tahap Alur Kerja | Berkas Sumber (*Source File*) | Fungsi / Komponen Utama | Standar *Self-Documentation* & Batasan |
| --- | --- | --- | --- |
| **1. Trusted target config** | `config/targets.json` | Konfigurasi Target Non-secret | Menampung allowlist target terdaftar beserta parameter path log, spool, URL health, dan selector Prometheus. |
| **2. target registry** | `src/application/target-registry.js` | `TargetRegistry`, `canonicalTargetId()` | Membentuk target ID kanonikal, memvalidasi normalisasi path absolut, menolak symlink/traversal, dan memverifikasi skema HTTPS. |
| **3. bounded adapters** | `src/adapters/bounded-file-reader.js`<br/>`src/adapters/local-file-evidence-adapter.js`<br/>`src/adapters/collector-spool-adapter.js`<br/>`src/adapters/application-health-adapter.js`<br/>`src/adapters/prometheus-adapter.js` | `readBoundedFile()`<br/>`collectLocalFileEvidence()`<br/>`readCollectorSpool()`<br/>`collectApplicationHealth()`<br/>`PrometheusAdapter.query()` | Penegakan batas buffer dan timeout ketat (file 64 KiB, health 3000ms, Prometheus 5000ms) serta redaksi data sensitif. |
| **4. isolated evidence** | `src/domain/evidence.js` | `createEvidence()`, `withinWindow()` | Standardisasi model bukti kanonikal, pembuatan hash SHA-256 evidence ID, dan isolasi observasi pada jendela waktu insiden (`startsAt ± 5m`). |
| **5. TD-01 through TD-08** | `src/domain/tomcat-down-engine.js` | `evaluateTomcatDown()` | Mesin evaluasi aturan keputusan bawaan (*Built-in Decision Engine Layer 1*) 8 cabang (`TD-01` s/d `TD-08`). |

## 🧭 Implementation Plan

| Tahap | Rencana |
| :--- | :--- |
| **Establish Trusted Target Identity** | Membentuk registri target terisolasi dari konfigurasi lokal dan menolak identity atau path yang tidak valid. |
| **Implement Target-Isolated Adapters** | Mengimplementasikan adapter pembaca file berbatas, status container, dan scrape bukti Prometheus. |
| **Implement the TomcatDown Rule Engine** | Mengimplementasikan pohon keputusan deterministik 8 cabang (`TD-01` s/d `TD-08`). |
| **Run Source Verification** | Menjalankan validasi statis dan unit tests untuk membuktikan isolasi target dan akurasi evaluasi aturan. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Establish Trusted Target Identity

Target registry membentuk identity `environment/host/tomcat_instance` dari
local configuration. Ia menolak duplicate identity, unsafe path, non-HTTPS
health URL, dan Prometheus selector yang bukan exact label matcher. Webhook
tidak dapat memilih endpoint atau path evidence.

!!! success "Expected Result"

    Hanya target allowlisted yang memperoleh trusted evidence mapping.

**Actual Result:** Unknown target dan unsafe mapping ditolak oleh unit tests.

</div>

<div class="procedure-step" markdown>

### Implement Bounded Evidence Adapters

| Adapter | Implemented boundary |
| --- | --- |
| Prometheus | Trusted selector, one attempt, total timeout 5 seconds |
| Application health | Trusted HTTPS URL; hanya status HTTP disimpan |
| Log/crash file | Configured root, maksimum 500 lines/512 KiB, redaction |
| Collector spool | Read-only JSON, maksimum 16 KiB/record dan 200 files/run |

Traversal dan symbolic link ditolak. Evidence dinormalisasi dengan stable ID,
target, generation, UTC timestamp, status, strength, value, dan redaction
state. Evidence di luar identity, generation, atau time window dikeluarkan.

!!! success "Expected Result"

    Adapter menghasilkan bounded evidence tanpa menerima path atau endpoint
    dari alert payload.

**Actual Result:** Adapter tersedia sebagai source; tidak ada endpoint atau
host evidence aktual yang diakses.

</div>

<div class="procedure-step" markdown>

### Implement the TomcatDown Decision Table

| Branch | Decisive evidence | Assessment |
| --- | --- | --- |
| TD-01 | JMX gagal, health hidup, container running | JMX/TLS/scrape path probable |
| TD-02 | JMX dan health gagal plus OOM | Confirmed OOM |
| TD-03–TD-05 | Correlated crash, bind, atau stop evidence | Confirmed cause |
| TD-06 | Container exited tanpa cause evidence | Undetermined |
| TD-07 | Running, health timeout, long pause | Possible unresponsive Tomcat |
| TD-08 | Missing atau contradicting evidence | Undetermined |

Engine tidak menggunakan numeric score dan tidak menjalankan recommended
action.

!!! success "Expected Result"

    Evidence dan rule version yang sama selalu menghasilkan branch,
    classification, dan confidence yang sama.

**Actual Result:** TD-01 sampai TD-08 dan confidence mapping tersedia.

</div>

<div class="procedure-step" markdown>

### Verify Isolation and Rule Behavior

```bash
./scripts/validate.sh
bash -n scripts/*.sh
podman run --rm --name tomcat-diagnostic-tn006-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Run pertama lulus 16 tests. Review berikutnya menambahkan conflicting-state
fallback, exact-selector validation, HTTPS enforcement, dan spool-isolation
test. Run tersebut semula dilaporkan 18 entries; evidence correction kemudian
membatasi discovery ke `*.test.js` dan menghasilkan 17 substantive tests, 0
fail.

!!! success "Expected Result"

    Seluruh branch, timeout/no-retry, isolation, bounds, traversal, symlink,
    dan malformed-spool behavior lulus.

**Actual Result:** Run awal melaporkan 18 entries. Evidence review menemukan
satu entry adalah fixture file. Setelah `npm test` dibatasi ke `*.test.js`, 17
substantive tests lulus dan container dihapus otomatis dengan `--rm`.

</div>

</div>

## 📁 Artifact Manifest

TN-006 menambahkan capability berikut di atas source TN-005:

| Path | Responsibility |
| --- | --- |
| `src/application/target-registry.js` | Canonical target dan trusted mapping validation |
| `src/domain/evidence.js` | Evidence identity, status, strength, dan isolation window |
| `src/domain/tomcat-down-engine.js` | Deterministic TD-01 sampai TD-08 evaluation |
| `src/adapters/prometheus-adapter.js` | One-attempt query dan five-second timeout status |
| `src/adapters/application-health-adapter.js` | Bounded health HTTP status evidence |
| `src/adapters/bounded-file-reader.js` | Root confinement, traversal/symlink rejection, byte/line bounds |
| `src/adapters/local-file-evidence-adapter.js` | Sanitized log/crash excerpt evidence |
| `src/adapters/collector-spool-adapter.js` | Bounded read-only collector record ingestion |
| `test/unit/adapters.test.js` | Prometheus and application-health behavior |
| `test/unit/collector-spool-adapter.test.js` | Malformed, target, generation, dan time filtering |
| `test/unit/evidence-isolation.test.js` | Registry, path, target, generation, dan time isolation |
| `test/unit/tomcat-down-engine.test.js` | TD-01 sampai TD-08, confidence, dan contradiction tests |

## 🧪 Test Scenario Matrix

| Boundary | Scenarios |
| --- | --- |
| Target registry | Accepted identity; unknown identity; unsafe path; selector injection; non-HTTPS URL |
| Filesystem | Traversal; symlink; byte and line truncation |
| Evidence isolation | Different target, generation, and UTC window rejected |
| Prometheus | Success; explicit timeout; exactly one attempt |
| Application health | HTTP `503` recorded as `up=false` without body persistence |
| Collector spool | Matching record accepted; wrong target/time and malformed JSON excluded |
| Rule engine | TD-01 through TD-08, contract confidence, conflicting direct state |

## 🧭 Reproduction Boundary

Tests menggunakan Node.js `24.18.0` temporary container, fixture-only HTTP
responses, temporary directories, dan no external network endpoint. Command
sequence tersedia pada procedure verification.

TN-005 dan TN-006 source disimpan bersama pada commit `aa55170`. Exact TN-006
files tercantum pada artifact manifest. Gunakan:

```bash
git checkout aa55170
./scripts/validate.sh
npm test
```

`npm test` membutuhkan Node.js `24.18.0`; gunakan temporary-container command
pada procedure bila host tidak menyediakan exact runtime. Commit ini masih
lokal dan belum membuktikan remote publication.

## ✅ Verification

| Method | Expected Result | Actual Result |
| --- | --- | --- |
| `./scripts/validate.sh` | Source dan forbidden-interface boundary konsisten | Passed |
| `bash -n scripts/*.sh` | Shell syntax valid | Passed |
| `npm test` pada temporary Node.js `24.18.0` container | Hanya `*.test.js` dijalankan; seluruh branch, timeout/no-retry, isolation, bounds, dan spool filtering lulus | Passed: 17 substantive tests |

Tidak ada network endpoint atau host evidence aktual yang diakses. Temporary
container dihapus otomatis dengan `--rm`.

## 🖥️ Commands Executed

Command aktual ditempatkan pada procedure sesuai chronology. `npm test`
dijalankan dua kali. Source dibuat melalui workspace patch; tidak ada shell
command yang memutasinya.

Read-only discovery dan closure checks yang material:

```bash
git status --short --branch
rg --files src test config migrations | sort
sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/diagnostic-mvp/target-and-evidence-contract.md
sed -n '1,300p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/diagnostic-mvp/diagnostic-result-and-confidence-contract.md
sed -n '1,220p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/diagnostic-mvp/restricted-event-collector-contract.md
git diff --check
git status --short --branch
podman ps -a --filter name=tomcat-diagnostic-tn006-node --format '{{.Names}} {{.Status}}'
podman run --rm --name tomcat-diagnostic-test-evidence-correction --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
git add README.md package.json package-lock.json scripts/validate.sh config migrations src test
git diff --cached --check
git commit -m "feat(diagnostic-service): implement durable diagnostic engine foundation"
```

Source-control result: commit `aa55170`, shared oleh TN-005 dan TN-006.

## 🧾 Outcome

Target and evidence boundary serta deterministic rule engine tersedia dan
lulus isolated tests. Hasil ini belum membuktikan worker orchestration,
canonical-result persistence, HTTP runtime, notification, atau end-to-end
diagnosis.

## ⏭️ Next Steps

Tahap berikutnya mengimplementasikan worker orchestration, canonical result
version 1, persistence, health/metrics model, dan Mailpit renderer. Image dan
component runtime tetap digabungkan pada verification teknis berikutnya, bukan
TN dokumentasi-only.

## 🔗 Related Documentation

- [TN-005 — Implement Durable Diagnostic Ingestion and Queue](TN-005-implement-durable-diagnostic-ingestion-and-queue.md)
- [Target and Evidence Contract](../../diagnostic-mvp/target-and-evidence-contract.md)
- [TomcatDown Rule Specification](../../diagnostic-mvp/tomcat-down-rule-specification.md)

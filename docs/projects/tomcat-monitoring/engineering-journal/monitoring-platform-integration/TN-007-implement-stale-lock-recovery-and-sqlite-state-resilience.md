# TN-007 — Implement Stale Lock Recovery and SQLite State Resilience

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Code or Rule Implementation |
| Project | Tomcat Monitoring |
| Phase | Monitoring Platform Integration |
| Activity Date | 2026-09-10 |
| Recorded Date | 2026-09-10 |
| Owner | Eddy Wiyatno |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-10 |

## 🎯 Objective

Mengimplementasikan mekanisme **Stale Lock Recovery** ([TASK-TM-004](../../follow-up-tasks.md#task-tm-004-implementasi-stale-lock-recovery-pada-worker-ingestion)) dan rutinitas **Housekeeping & Retention Pruning Database SQLite** ([TASK-TM-005](../../follow-up-tasks.md#task-tm-005-penjadwalan-housekeeping--pruning-database-sqlite)) pada `tomcat-diagnostic-service` (v0.1.6) guna memenuhi kewajiban ketahanan mesin status (*state machine resilience*) dan penyimpanan berbatas (*bounded storage*) sesuai [TM-ADR-0015](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md).

**Target Utama & Kriteria Keberhasilan:**

1. **Meniadakan Zombie Alert Pasca-Restart (*Zero Orphaned Processing Events*):**
   Memastikan setiap event alert yang tertahan di status `processing` akibat interupsi container (seperti `kill -9`, cgroup OOM Killer, atau restart host) dipulihkan secara otomatis ke antrean `queued` saat container startup atau melalui batas waktu sewa (*lease timeout*).
2. **Pencegahan Infinite Crash Loop (*Bounded Retries*):**
   Menerapkan counter `retry_count` dan batasan `maxRetries` (default: 3). Jika pemrosesan suatu event berulang kali memicu crash hingga melampaui batas maksimum, status event diubah secara deterministik menjadi `failed` dan counter error dicatat.
3. **Pembersihan Data Historis Berbatas (*Bounded Storage Retention*):**
   Menyediakan rutinitas atomik `pruneHistoricalRecords({ retentionDays })` yang menghapus data kadaluwarsa (`events`, `requests`, `canonical_results`, `evidence_summaries`, `notification_attempts`, dan resolved `incidents`) sesuai urutan *Foreign Key* dan menjalankan `PRAGMA incremental_vacuum`.
4. **Metrik Observabilitas Ketahanan & Ukuran Database:**
   Mengekspos metrik Prometheus:
   - `diagnostic_stale_locks_recovered_total` (counter pemulihan lock).
   - `diagnostic_stale_locks_exhausted_total` (counter retry habis / failed).
   - `diagnostic_housekeeping_runs_total` (counter siklus housekeeping).
   - `diagnostic_records_pruned_total` (counter baris terhapus).
   - `diagnostic_db_size_bytes` (gauge ukuran file database fisik).
5. **Verifikasi Komprehensif (Unit, Component, & Live Crash Injection):**
   Mencapai 100% test pass rate pada pengujian unit (59/59 passing), validasi statis integritas (`validate.sh`), pengujian component image, serta pengujian empiris simulasi crash dan restart pada runtime `devops-lab`.

## 🌍 Background

Pada implementasi awal pola *Asynchronous Webhook Ingestion with Durable SQLite Acceptance* ([TM-ADR-0015](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)), worker mengklaim item antrean melalui `claimNext()` dengan langsung mengubah status dari `queued` menjadi `processing`.

Namun, muncul keterbatasan struktural:
- Jika container mati mendadak saat worker sedang mengumpulkan bukti telemetri atau mengevaluasi aturan, record pada tabel `work_queue` akan tertahan dengan `state = 'processing'` dan `completed_at = NULL`.
- Ketika container hidup kembali, metode `claimNext()` hanya mencari item berstatus `state = 'queued'`, sehingga event yang tertahan tersebut menjadi "zombie" yang tidak pernah diproses maupun dikirimkan laporannya ke tim SRE.
- Selain itu, tanpa adanya mekanisme pembersihan otomatis (*retention pruning*), database SQLite akan terus bertambah besar seiring waktu (*unbounded storage*), yang dapat memicu kehabisan ruang disk pada volume persisten rootless container.

Oleh karena itu, `TASK-TM-004` dan `TASK-TM-005` dirumuskan sebagai langkah wajib sebelum sistem observabilitas dihubungkan dengan pengumpul bukti live yang lebih kompleks.

## 📚 Scope

Pekerjaan implementasi mencakup komponen berikut:

- **`tomcat-diagnostic-service`:**
  - [`migrations/007-stale-lock-recovery-and-retention.sql`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/migrations/007-stale-lock-recovery-and-retention.sql): Migrasi penambahan kolom `retry_count`, `lease_expires_at`, dan indeks pendukung housekeeping.
  - [`src/adapters/sqlite-repository.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/adapters/sqlite-repository.js): Pembaruan `claimNext()` dan `complete()`, serta implementasi `recoverStaleLocks()`, `pruneHistoricalRecords()`, dan `getDatabaseSizeBytes()`.
  - [`src/application/application.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/application/application.js): Eksekusi pemulihan awal pada `DiagnosticApplication.start()` serta eksekusi periodik pada worker loop.
  - [`src/application/health-metrics.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/application/health-metrics.js): Dukungan penambahan batch count pada `increment()` dan metrik baru.
  - [`config/schemas/application-config-v1.schema.json`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/config/schemas/application-config-v1.schema.json): Penambahan properti opsional `staleLockTimeoutMs`, `maxRetries`, `retentionDays`, dan `housekeepingIntervalMs`.
  - [`test/unit/stale-lock-and-retention.test.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/test/unit/stale-lock-and-retention.test.js): Pengujian unit terisolasi untuk skenario recovery, retry limit, dan foreign-key safe pruning.
  - [`test/integration/application-lifecycle.test.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/test/integration/application-lifecycle.test.js): Pengujian integrasi pemulihan siklus startup.
  - [`test/component/image-runtime-database-probe.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/test/component/image-runtime-database-probe.js): Pemutakhiran ekspektasi versi migrasi skema [1..7].
  - [`VERSION`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/VERSION), [`package.json`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/package.json), [`package-lock.json`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/package-lock.json): Peningkatan versi semantik ke `0.1.6`.
  - [`scripts/validate.sh`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/scripts/validate.sh) & [`scripts/test-image.sh`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/scripts/test-image.sh): Sinkronisasi audit integritas file migrasi.
- **`tomcat-monitoring`:**
  - [`scripts/deploy-diagnostic-service.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/deploy-diagnostic-service.sh): Pemutakhiran pinning image ke versi `0.1.6` (`sha256:31e4668648d0935494cf424923c7a15af1adf48fb288d8775011dc5813893f3a`).
- **`devops-handbook`:**
  - [`docs/projects/tomcat-monitoring/engineering-journal/monitoring-platform-integration/TN-007-implement-stale-lock-recovery-and-sqlite-state-resilience.md`](TN-007-implement-stale-lock-recovery-and-sqlite-state-resilience.md): Technical Note implementasi dan bukti empiris.
  - [`docs/projects/tomcat-monitoring/follow-up-tasks.md`](../../follow-up-tasks.md): Rekonsiliasi task `TASK-TM-018`, `TASK-TM-004`, dan `TASK-TM-005` $\rightarrow$ `Completed` ✅.

## 📋 Prerequisites

| Prasyarat | Status | Keterangan |
| :--- | :---: | :--- |
| **TM-ADR-0015 Accepted** | ✅ Terpenuhi | Pola Asynchronous Durable SQLite Webhook Ingestion telah disetujui. |
| **Node.js 24 Runtime** | ✅ Terpenuhi | Base image `localhost/nodejs:24.18.0` siap pada host Podman. |
| **Diagnostic Service v0.1.5** | ✅ Terpenuhi | Baseline Multi-Domain Dispatcher (54 unit test pass) beroperasi normal. |
| **Rootless Podman Runtime** | ✅ Terpenuhi | Volume `diagnostic_data` aktif pada network `devops-lab`. |

## 🔨 Implementation Details

### 1. Skema Database & Migrasi (007)

Migrasi [`migrations/007-stale-lock-recovery-and-retention.sql`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/migrations/007-stale-lock-recovery-and-retention.sql) menambahkan kolom dan indeks:

```sql
ALTER TABLE work_queue ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE work_queue ADD COLUMN lease_expires_at TEXT;

CREATE INDEX IF NOT EXISTS work_queue_stale_idx ON work_queue(state, started_at);
CREATE INDEX IF NOT EXISTS events_accepted_at_idx ON events(accepted_at);
CREATE INDEX IF NOT EXISTS requests_accepted_at_idx ON requests(accepted_at);
CREATE INDEX IF NOT EXISTS canonical_results_created_at_idx ON canonical_results(created_at);
CREATE INDEX IF NOT EXISTS notification_attempts_attempted_at_idx ON notification_attempts(attempted_at);
```

### 2. Logika Stale Lock Recovery & Housekeeping

Dalam [`src/adapters/sqlite-repository.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/adapters/sqlite-repository.js):

- **Lease Assignment saat Klaim:**
  Ketika worker memanggil `claimNext({ timeoutMs, now })`, sistem mencatat timestamp `started_at` dan `lease_expires_at = now + timeoutMs`.
- **Transisi Status Stale Recovery:**
  Metode `recoverStaleLocks({ timeoutMs, maxRetries, now })` berjalan dalam transaksi `BEGIN IMMEDIATE`:
  - Item berstatus `processing` dengan `started_at <= cutoff` atau `lease_expires_at <= now` diidentifikasi.
  - Jika `retry_count < maxRetries`: `state = 'queued'`, `started_at = NULL`, `lease_expires_at = NULL`, `retry_count = retry_count + 1`.
  - Jika `retry_count >= maxRetries`: `state = 'failed'`, `completed_at = now`, `lease_expires_at = NULL`.
- **Foreign-Key Safe Pruning:**
  Metode `pruneHistoricalRecords({ retentionDays, now })` menghapus rekaman dalam urutan dependensi:
  1. `evidence_summaries` $\rightarrow$ 2. `notification_attempts` $\rightarrow$ 3. `canonical_results` $\rightarrow$ 4. `work_queue` $\rightarrow$ 5. `events` $\rightarrow$ 6. `requests` $\rightarrow$ 7. resolved `incidents`.
  Dilanjutkan dengan `PRAGMA incremental_vacuum` untuk mengembalikan ruang disk yang tidak terpakai.

## 🔬 Verification Evidence

### 1. Hasil Unit & Integration Test (100% Pass)

Eksekusi seluruh unit dan integration test di lingkungan kontainer Node.js 24:

```bash
podman run --rm --userns=keep-id --volume "${PWD}:/app:ro,Z" --workdir /app localhost/nodejs:24.18.0 node --test test/unit/*.test.js test/integration/*.test.js
```

Hasil:
```text
✔ startup failure keeps readiness false and closes the migrated database (84.47636ms)
✔ one worker loop stops before database close during graceful shutdown (38.257071ms)
✔ startup lifecycle invokes stale lock recovery and updates db metrics (23.813413ms)
✔ Rules API strict guards, persistence, hot-reload, and 405 rejection (166.721517ms)
✔ single worker persists canonical result before completing queue item (108.484456ms)
✔ worker sends initial, one material update, and resolved notification (44.229615ms)
✔ resolved without stored firing is explicit and still notifies (9.330148ms)
✔ commits before acceptance and suppresses duplicate work across reopen (102.313869ms)
✔ rolls back the request when queue capacity is exhausted (39.217496ms)
✔ correlates firing and resolved events to one incident (29.707903ms)
✔ rolls back a failed forward migration (2.809123ms)
✔ Prometheus adapter performs one successful bounded query (15.943286ms)
✔ Prometheus timeout is explicit and is not retried (0.550042ms)
✔ application health reports HTTP state without response content (1.583681ms)
✔ canonical hash excludes volatile timing and material change is bounded (2.076267ms)
✔ renderer preserves seven-section order and escapes HTML (1.228492ms)
✔ canonical result rejects invalid confidence (0.780242ms)
✔ collector spool accepts only bounded records for the target window (19.315229ms)
✔ createDefaultEvidenceCollector reads spool evidence from target (96.072569ms)
✔ loads versioned non-secret configuration and mounted files (127.417648ms)
✔ rejects invalid configuration without exposing mounted secret (64.705871ms)
✔ isBuiltinBranch detects all built-in branches across 4 domains (2.967429ms)
✔ evaluateApplicationHealth resolves AH-01 through AH-04 accurately (0.867713ms)
✔ evaluateJvmWorkload resolves GC-01 through GC-04 accurately (0.306243ms)
✔ evaluateConcurrency resolves TH-01 accurately (0.245838ms)
✔ DynamicRuleEvaluator dispatches events to the appropriate domain engine while preserving ruleId (0.869923ms)
✔ DynamicRuleEvaluator prioritizes Layer 2 custom rules over Layer 1 domain dispatching (0.406154ms)
✔ registry rejects unknown identity and non-normalized evidence paths (2.72594ms)
✔ bounded reader rejects traversal and symlinks and enforces bounds (1.893643ms)
✔ evidence window isolates target, generation, and UTC time (14.290151ms)
✔ health and metrics expose bounded operational state without target labels (3.51861ms)
✔ Prometheus serialization rejects unsafe metric identities (0.587918ms)
✔ HTTP boundary rejects auth, media type, and oversized bodies (5.492856ms)
✔ health and metrics interfaces expose bounded state (0.655793ms)
✔ SIGTERM and SIGINT share one idempotent graceful-shutdown path (5.243328ms)
✔ normalizes a valid TomcatDown firing event deterministically (14.180781ms)
✔ normalizes universal monitoring alerts (TomcatGCPauseHigh) deterministically (0.361099ms)
✔ rejects an identity outside the local allowlist (1.437274ms)
✔ rejects unsupported alert schema (0.279296ms)
✔ notification delivery persists bounded retries before succeeding (4.54311ms)
✔ notification delivery stops before retry would exceed maximum age (0.422633ms)
✔ SMTP errors are reduced to bounded codes (0.291864ms)
✔ isBuiltinBranch detects TD-01 through TD-08 (1.610529ms)
✔ DynamicRuleEvaluator falls back to built-in engine when no custom rules match (0.848855ms)
✔ DynamicRuleEvaluator matches custom rule on local_file log excerpt (0.513944ms)
✔ DynamicRuleEvaluator supports hot-reloading via registerRule (0.389276ms)
✔ isSafeRegex detects unsafe and safe regex patterns (1.892383ms)
✔ createRulepackValidator accepts valid rulepack payload with category (47.428294ms)
✔ createRulepackValidator rejects invalid category enum (15.502814ms)
✔ createRulepackValidator rejects invalid schema or inconsistent confidence (9.043384ms)
✔ createRulepackValidator rejects unsafe regex pattern in rule payload (7.783604ms)
✔ SMTP adapter produces bounded multipart message without network (19.548629ms)
✔ claimNext sets lease_expires_at and started_at properly (56.820826ms)
✔ recoverStaleLocks re-queues expired processing items and increments retry_count (28.465313ms)
✔ recoverStaleLocks marks item as failed when maxRetries is reached (16.929269ms)
✔ pruneHistoricalRecords removes expired records in foreign key order and preserves active ones (17.283958ms)
✔ evaluates every TomcatDown decision-table branch (17.733528ms)
✔ uses contract confidence rather than a numeric score (1.404726ms)
✔ contradicting direct state falls back to TD-08 (1.881464ms)
ℹ tests 59
ℹ suites 0
ℹ pass 59
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 551.958059
```

### 2. Validasi Statis & Pembangunan Image v0.1.6

- Validasi statis: `bash scripts/validate.sh` $\rightarrow$ `Static validation passed: schema, migration, source, and dependency boundaries are consistent.`
- Pembangunan image: `bash scripts/build.sh` $\rightarrow$ `Successfully tagged localhost/tomcat-diagnostic-service:0.1.6` (Image ID: `c6759bcfc5ff54a2b2f1a79fb60d4ea5f4acc939484c791f2e7416c524223c53`, Digest: `sha256:31e4668648d0935494cf424923c7a15af1adf48fb288d8775011dc5813893f3a`).
- Pengujian image: `bash scripts/test-image.sh` $\rightarrow$ `PASSED`.
- Pengujian komponen image: `bash scripts/test-image-component.sh` $\rightarrow$ `PASSED (ExitCode: 0, Schema migrations: [1..7])`.

### 3. Bukti Empiris Simulasi Crash & Recovery pada Runtime Live

1. **Injeksi Stale Item:**
   Item simulasi dengan `state = 'processing'`, `started_at = 10m lalu`, dan `retry_count = 0` dimasukkan langsung ke database persisten kontainer `diagnostic-service` (`event_id = 39`).
2. **Simulasi Restart Kontainer:**
   Kontainer di-restart melalui `podman restart diagnostic-service`.
3. **Hasil Evaluasi Otomatis:**
   - Metrik Prometheus membuktikan eksekusi pemulihan:
     ```text
     diagnostic_housekeeping_runs_total 1
     diagnostic_stale_locks_recovered_total 1
     notification_attempts_total{status="sent"} 1
     notification_deliveries_total{status="sent"} 1
     diagnostic_db_size_bytes 303104
     ```
   - Kueri status database membuktikan tugas selesai:
     ```json
     {
       "id": 39,
       "event_id": 39,
       "state": "completed",
       "retry_count": 1,
       "completed_at": "2026-09-10T03:36:38.289Z"
     }
     ```
   - Mailpit mencatat penerimaan email laporan resmi insiden: `[CRITICAL] [LAB] Tomcat Service: TomcatDown (Target: lab/tomcat-01/default)`.

## 📌 Conclusion & Next Steps

Implementasi `TASK-TM-004` dan `TASK-TM-005` telah berhasil diselesaikan secara penuh pada rilis `tomcat-diagnostic-service` **v0.1.6**, menutup seluruh kesenjangan ketahanan antrean dan retensi penyimpanan database SQLite ([TM-ADR-0015](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)).

**Langkah Selanjutnya pada Roadmap:**
- Menindaklanjuti **Kategori 5** pada [`follow-up-tasks.md`](../../follow-up-tasks.md), khususnya:
  - [`TASK-TM-016`](../../follow-up-tasks.md#task-tm-016-integrasi-live-prometheus-evidence-adapter-pada-application-lifecycle-kesiapan-produksi-metrik): Integrasi Live Prometheus Evidence Adapter pada `createDefaultEvidenceCollector`.
  - [`TASK-TM-013`](../../follow-up-tasks.md#task-tm-013-integrasi-shared-persistent-volume-mount-untuk-log-runtime-tomcat-kesiapan-produksi-tn-019): Integrasi Shared Persistent Volume Mount untuk Log Runtime Tomcat `catalina.out`.

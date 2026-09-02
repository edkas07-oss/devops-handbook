# TN-017 — Verify End-to-End Incident Diagnostic Flow

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-02 |
| Recorded Date | 2026-09-02 |
| Owner | Antigravity Agent |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-02 |

## 🎯 Objective

Melakukan pengujian dan verifikasi *end-to-end* skenario insiden Tomcat down pada environment persisten `devops-lab`. Membuktikan bahwa *Restricted Event Collector* merekam bukti *lifecycle* container secara atomik ke spool host, Prometheus mendeteksi ketidaksediaan metrik dan memicu alert `TomcatDown`, Alertmanager merutekan webhook ke Diagnostic Service, Diagnostic Service mengumpulkan bukti spool dan mengevaluasi keputusan deterministik (TD-06), menyimpan canonical result ke database SQLite, serta mengirimkan laporan diagnosis *firing* dan notifikasi pemulihan *resolved* secara lengkap ke Mailpit.

## 🌍 Background

Pada tahap sebelumnya, persistent runtime monitoring ([TN-015](TN-015-deploy-persistent-monitoring-runtime.md)) dan Restricted Event Collector beserta runtime Tomcat ([TN-016](TN-016-implement-restricted-collector-and-tomcat-runtime.md)) telah berhasil dibangun dan di-deploy. Namun, korelasi bukti runtime dari spool direktori *read-only* ke dalam Diagnostic Service, evaluasi branch engine TomcatDown (TD-06), persistensi evidence summaries ke SQLite, dan pengiriman notifikasi terintegrasi ke Mailpit saat insiden riil belum diuji secara *end-to-end*.

## 📚 Scope

1. Penyelarasan schema dan format evidence record pada repositori `tomcat-diagnostic-event-collector` (enum `strength`: `direct`, `supporting`, `contextual`; default canonical target ID: `lab/tomcat-01/default`).
2. Implementasi default evidence collector pipeline pada `tomcat-diagnostic-service` (`src/application/application.js`) untuk membaca evidence spool secara terisolasi dan memilih snapshot observasi terbaru per tipe evidence.
3. Eksekusi unit/integration test suite, kenaikan versi `0.1.2`, dan pembuatan application image `localhost/tomcat-diagnostic-service:0.1.2` dari immutable base.
4. Pembaruan orchestration deployment (`scripts/deploy-diagnostic-service.sh`) di `tomcat-monitoring` dengan image digest baru.
5. Eksekusi simulasi insiden (penghentian container Tomcat), verifikasi pencatatan spool atomik, firing alert Prometheus/Alertmanager, korelasi branch TD-06, persistensi SQLite, dan pengiriman email *firing* ke Mailpit.
6. Eksekusi simulasi pemulihan (start Tomcat), verifikasi pencatatan status running, resolution alert Prometheus/Alertmanager, penghubungan riwayat insiden di SQLite, dan pengiriman email *resolved* ke Mailpit.

## 📋 Prerequisites

- Network `devops-lab` aktif dengan Prometheus, Alertmanager, Mailpit, dan Diagnostic Service beroperasi.
- Container `tomcat-jmx-exporter` aktif mengekspos metrik HTTPS pada port 9404.
- Restricted Event Collector beroperasi memantau container event secara rootless di host.

## ⚖️ Execution Decision

1. Schema dan logic `tomcat-diagnostic-event-collector` diselaraskan ke nilai strength kanonikal `direct` untuk state container aktual agar kompatibel dengan kontrak domain `evidence.js`.
2. `DiagnosticApplication` mengintegrasikan `readCollectorSpool` secara otomatis ke dalam default pipeline bukti, mengisolasi target ID dan time window insiden, serta menyaring observasi terbaru per tipe bukti guna mencegah kontradiksi *state* historis.
3. Pengujian insiden dilakukan secara live pada runtime `devops-lab` dengan menghentikan container Tomcat (`podman stop tomcat-jmx-exporter`) dan memverifikasi seluruh alur telemetri tanpa intervensi manual terhadap database atau mailer.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Align Collector Contract and Evidence Formats** | Menyelaraskan enum schema dan collector values pada `tomcat-diagnostic-event-collector`. |
| **Implement Default Evidence Collector in Diagnostic Service** | Mengimplementasikan `createDefaultEvidenceCollector` pada `src/application/application.js`, menguji test suite, bump versi ke `0.1.2`, dan build image baru. |
| **Deploy Updated Diagnostic Service Image and Spool Integration** | Memperbarui `deploy-diagnostic-service.sh` dengan digest `0.1.2` dan me-redeploy container persisten. |
| **Execute Incident Simulation and Firing Verification** | Menghentikan container Tomcat, memverifikasi rekaman spool atomik, firing `TomcatDown`, evaluasi branch TD-06, penyimpanan SQLite, dan email *firing* di Mailpit. |
| **Execute Recovery Simulation and Resolved Verification** | Menjalankan kembali Tomcat, memverifikasi rekaman status running, resolusi alert, persistensi SQLite, dan email *resolved* di Mailpit. |

## ⚙️ Implementation

<div class="procedure-sequence" markdown>

<div class="procedure-step" markdown>

### Align Collector Contract and Evidence Formats

**Action:** Memperbarui `config/schemas/event-record-v1.schema.json` untuk mendukung enum strength (`direct`, `supporting`, `contextual`) dan status (`collected`, `not_found`, `unavailable`), memperbarui `src/collector.sh` untuk menggunakan target ID kanonikal `lab/tomcat-01/default` serta strength `direct`, dan menyesuaikan `test/test-collector.sh`.

!!! success "Expected Result"

    `scripts/validate.sh` dan `test/test-collector.sh` pada `tomcat-diagnostic-event-collector` lulus validasi dan component test.

**Actual Result:** Validasi baseline dan test suite lulus (1 spool event tervalidasi terhadap schema).

</div>

<div class="procedure-step" markdown>

### Implement Default Evidence Collector in Diagnostic Service

**Action:** Memperbarui `src/application/application.js` pada `tomcat-diagnostic-service` dengan fungsi `createDefaultEvidenceCollector` yang mengonsumsi `readCollectorSpool`, memilih observasi terbaru per tipe bukti dalam rentang window insiden, dan menyematkannya ke `DiagnosticWorker`. Menambahkan unit test di `test/unit/collector-spool-adapter.test.js`, menaikkan versi ke `0.1.2`, memvalidasi source, dan membangun image `localhost/tomcat-diagnostic-service:0.1.2`.

!!! success "Expected Result"

    37 regression/integration tests lulus, validator lulus, dan application image baru terbentuk dengan digest exact immutable.

**Actual Result:** 37 tests lulus, image berhasil di-build dengan digest `sha256:0dcb912511da5e9fa8c8b75b202cece765dc9096bd55882c86764cd985226f3a`.

</div>

<div class="procedure-step" markdown>

### Deploy Updated Diagnostic Service Image and Spool Integration

**Action:** Memperbarui `scripts/deploy-diagnostic-service.sh` pada repositori `tomcat-monitoring` dengan digest image baru `0.1.2`, lalu menjalankan skrip deployment ulang container `diagnostic-service` dan `alertmanager`.

!!! success "Expected Result"

    Container `diagnostic-service` berjalan dengan image `0.1.2`, bind-mount `/run/tomcat-diagnostic/spool:ro,z` aktif, dan endpoint `/health/ready` merespons `200 OK`.

**Actual Result:** Container `diagnostic-service` aktif dan healthy (`{"live":true,"ready":true}`).

</div>

<div class="procedure-step" markdown>

### Execute Incident Simulation and Firing Verification

**Action:** Menjalankan daemon Restricted Event Collector di host, lalu menghentikan container `tomcat-jmx-exporter` (`podman stop tomcat-jmx-exporter`).

1. Collector mencatat snapshot `container_state: "exited"` dan `runtime_oom: {"exitCode": 143, "oomKilled": false}` secara atomik ke `/tmp/diagnostic-spool`.
2. Prometheus mendeteksi target HTTPS JMX Exporter unreachable (`up == 0`), status rule `TomcatDown` berpindah dari `pending` ke `firing` setelah 2 menit.
3. Alertmanager menerima alert `TomcatDown` dan meneruskan webhook ke `https://diagnostic-service:8443/api/v1/alerts/alertmanager`.
4. Diagnostic Service mengonsumsi webhook, worker mengumpulkan bukti spool, mengevaluasi branch **TD-06** (*Container exited; cause undetermined*), menyimpan canonical result (ID 5 & 7) ke SQLite `canonical_results` dan `evidence_summaries`, serta mengirimkan email notifikasi ke Mailpit.

!!! success "Expected Result"

    Canonical result tersimpan di SQLite dengan branch `TD-06` dan bukti `container_state`/`runtime_oom`, serta email berlabel `[firing] TomcatDown lab/tomcat-01/default` diterima di Mailpit dengan 7 seksi analisis lengkap.

**Actual Result:** Canonical result `diag-e5b861cd...` (ID 5) dan `diag-392fa5fe...` (ID 7) tersimpan di SQLite dengan branch TD-06, notification attempt berstatus `sent`, dan email HTML 7 seksi diterima di Mailpit.

</div>

<div class="procedure-step" markdown>

### Execute Recovery Simulation and Resolved Verification

**Action:** Menjalankan kembali container Tomcat (`./scripts/deploy-tomcat.sh`).

1. Collector mencatat snapshot `container_state: "running"` dan `runtime_oom: {"exitCode": 0, "oomKilled": false}`.
2. Prometheus melakukan scrape ulang dan mendeteksi target `up == 1`, alert `TomcatDown` bertransisi menjadi `inactive` (resolved).
3. Alertmanager mengirimkan webhook `resolved` ke Diagnostic Service.
4. Diagnostic Service memproses event resolved, mengorelasikannya dengan riwayat firing sebelumnya (ID 7), menyimpan canonical result (ID 8) ke SQLite, dan mengirimkan email notifikasi pemulihan `[resolved] TomcatDown lab/tomcat-01/default` ke Mailpit.

!!! success "Expected Result"

    Canonical result resolusi tersimpan di SQLite (lifecycleStatus `resolved`), notification attempt berstatus `sent`, dan email resolusi diterima di Mailpit.

**Actual Result:** Canonical result ID 8 tersimpan di SQLite dengan status `resolved` (branch TD-06), notification attempt berhasil dikirim, dan email pemulihan diterima di Mailpit.

</div>

</div>

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Unit & Integration Tests | 37 tests lulus pada `tomcat-diagnostic-service` | Lulus (37 pass, 0 fail) | `npm test` output di container Node.js |
| Collector Atomic Spool | File `.json` terbuat atomik tanpa sisa `.tmp`, schema valid | Lulus | Snapshot `container_state: exited` & `runtime_oom: exitCode 143` |
| Prometheus Rule Evaluation | Rule `TomcatDown` bertransisi `pending` -> `firing` saat down, dan `inactive` saat up | Lulus | Query `/api/v1/rules` Prometheus |
| Alertmanager Route Dispatch | Alertmanager mengirim webhook ke receiver `lab-diagnostic-service` | Lulus | Webhook diterima pada Diagnostic Service port 8443 |
| Engine Decision Evaluation | Diagnostic Service mengevaluasi bukti spool menjadi branch TD-06 | Lulus | Canonical result branch `TD-06`, classification `undetermined` |
| SQLite Persistence | Result, evidence summaries, dan notification attempts tersimpan di SQLite | Lulus | Record tersimpan di tabel `canonical_results`, `evidence_summaries`, `notification_attempts` |
| Mailpit Firing Notification | Email laporan diagnosis insiden diterima di Mailpit | Lulus | Message `[firing] TomcatDown lab/tomcat-01/default` dengan 7 seksi HTML |
| Mailpit Resolved Notification | Email notifikasi pemulihan diterima di Mailpit | Lulus | Message `[resolved] TomcatDown lab/tomcat-01/default` diterima di Mailpit |

## ✅ Operator Validation

| Elemen | Keterangan |
| --- | --- |
| **State** | Evidence terverifikasi secara live di lingkungan `devops-lab`. |
| **Owner** | Operator Monitoring / Eddy Wiyatno. |
| **Validation Target** | Mailpit Web UI (pesan diagnosis insiden dan resolusi) dan database SQLite Diagnostic Service. |
| **Access Method** | Buka browser ke `http://127.0.0.1:8025` (Mailpit Web UI) atau query SQLite container `diagnostic-service`. |
| **Evidence Lifetime** | Pesan tersimpan persisten di Mailpit container dan volume `diagnostic_data` (`/var/lib/tomcat-diagnostic/diagnostic.db`). |
| **Acceptance Criteria** | 1. Email `[firing] TomcatDown lab/tomcat-01/default` menampilkan 7 seksi (Alert Summary, Diagnostic Assessment `Container exited; cause undetermined`, Key Metrics Snapshot, Correlated Log Evidence, Unavailable/Contradicting Evidence, Recommended Operator Actions, Rule & Diagnostic Traceability).<br/>2. Email `[resolved] TomcatDown lab/tomcat-01/default` menampilkan status pemulihan layanan. |
| **Closure Record** | Skenario insiden dan pemulihan telah terbukti beroperasi secara deterministik dari hulu ke hilir. |

## 🖥️ Commands Executed

```bash
# 1. Validasi repositori collector
cd /home/eddywiyatno/git/tomcat-diagnostic-event-collector
./scripts/validate.sh
./test/test-collector.sh

# 2. Validasi, test, dan build Diagnostic Service
cd /home/eddywiyatno/git/tomcat-diagnostic-service
./scripts/validate.sh
podman run --rm -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:z -w /app localhost/nodejs:24.18.0 npm test
./scripts/build.sh
./scripts/test-image.sh

# 3. Deployment ulang runtime
cd /home/eddywiyatno/git/tomcat-monitoring
./scripts/deploy-diagnostic-service.sh
./scripts/deploy-alertmanager.sh
./scripts/deploy-tomcat.sh

# 4. Menjalankan collector daemon di host
SPOOL_DIR=/tmp/diagnostic-spool /home/eddywiyatno/git/tomcat-diagnostic-event-collector/src/collector.sh &

# 5. Simulasi Insiden (Tomcat Down)
podman stop tomcat-jmx-exporter

# 6. Memeriksa spool evidence dan rule Prometheus
ls -la /tmp/diagnostic-spool
curl -s http://127.0.0.1:9090/api/v1/alerts
curl -s http://127.0.0.1:9093/api/v2/alerts

# 7. Memeriksa SQLite database dan Mailpit email
podman exec diagnostic-service node -e "
import sqlite3 from 'node:sqlite';
const db = new sqlite3.DatabaseSync('/var/lib/tomcat-diagnostic/diagnostic.db');
console.log(db.prepare('SELECT id, diagnostic_id, result_json FROM canonical_results ORDER BY id DESC LIMIT 1').get());
console.log(db.prepare('SELECT * FROM notification_attempts ORDER BY id DESC LIMIT 2').all());
db.close();
"
curl -s http://127.0.0.1:8025/api/v1/messages

# 8. Simulasi Pemulihan (Tomcat Up)
./scripts/deploy-tomcat.sh
```

## 🧾 Outcome

Skenario insiden `TomcatDown` dan pemulihan layanan telah berhasil diuji dan diverifikasi secara *end-to-end* pada environment `devops-lab`. Alur telemetri lengkap mulai dari Restricted Event Collector, Prometheus, Alertmanager, Diagnostic Service (evaluasi branch TD-06, persistensi SQLite), hingga Mailpit delivery terbukti bekerja secara deterministik tanpa intervensi manual.

## 🎓 Lessons Learned

1. **Bind Mount Inode Lifetime:** Ketika melakukan bind mount direktori host ke container (`--volume /tmp/diagnostic-spool:...`), direktori host tidak boleh dihapus dengan `rm -rf` karena container akan tetap menunjuk pada inode lama yang telah ter-unlink. Pembersihan spool harus menggunakan `rm -f /tmp/diagnostic-spool/*`.
2. **Latest Observation Sifting:** Saat membaca bukti dari spool historis, pengelompokan berdasarkan `type` dan pemilihan timestamp observasi terbaru (`latest observation`) sangat penting untuk mencegah kontradiksi antara state *running* awal dan state *exited* insiden dalam rentang window yang sama.
3. **Material Update Guard:** Mekanisme pencegahan notifikasi duplikat di Diagnostic Service terbukti efektif meredam pengiriman email berulang ketika penilaian diagnosis tidak mengalami perubahan material.

## ⏭️ Next Steps

Konsolidasi hasil verifikasi fase Diagnostic MVP Pilot ke dokumentasi arsitektur dan operasional utama Tomcat Monitoring di DevOps Handbook, serta persiapan fase implementasi berikutnya.

## 🔗 Related Documentation

- [TN-015 — Deploy Persistent Monitoring Runtime](TN-015-deploy-persistent-monitoring-runtime.md)
- [TN-016 — Implement Restricted Collector and Tomcat Runtime](TN-016-implement-restricted-collector-and-tomcat-runtime.md)
- [Diagnostic MVP Pilot Engineering Journal](index.md)
- [Target and Evidence Contract](../../diagnostic-mvp/target-and-evidence-contract.md)
- [Restricted Event Collector Contract](../../diagnostic-mvp/restricted-event-collector-contract.md)

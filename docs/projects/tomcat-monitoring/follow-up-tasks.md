# Follow-up Tasks

## 🔍 Overview

Dokumen ini mencatat seluruh daftar tugas kelanjutan (*follow-up tasks*), kewajiban desain arsitektur, dan backlog teknis untuk proyek Tomcat Monitoring setelah penyelesaian fase Diagnostic MVP Pilot.

Daftar tugas ini disusun untuk menindaklanjuti konsekuensi dan keterbatasan yang diidentifikasi dalam *Architecture Decision Records* (TM-ADR-0014 hingga TM-ADR-0017), hasil evaluasi kesenjangan (*Gap Register*), serta peta jalan integrasi platform monitoring menuju kesiapan lingkungan produksi.

---

## 🎯 Objectives

1. **Meniadakan Titik Buta Notifikasi (*Zero Silent Failure*):**
   Mengimplementasikan pemantauan kesehatan mandiri (*health scrape*) terhadap Diagnostic Service guna mengantisipasi keterbatasan arsitektur pengirim notifikasi tunggal (TM-ADR-0016).
2. **Memperkuat Ketahanan Mesin Status (*State Resilience*):**
   Menyediakan mekanisme pemulihan antrean macet (*stale lock recovery*) pada database SQLite lokal saat terjadi restart container yang tidak terduga (TM-ADR-0015).
3. **Membangun Rekam Jejak Tindakan Operator (*Operator Audit Trail*):**
   Menyediakan pencatatan umpan balik operasional atas rekomendasi tindakan manual sesuai prinsip *Zero Automatic Remediation* (TM-ADR-0014).
4. **Memperluas Cakupan Diagnosis (*Scope Expansion*):**
   Mengembangkan aturan deteksi untuk skenario degradasi pra-crash secara bertahap sesuai pendekatan *Vertical Slice MVP* (TM-ADR-0017).
5. **Menuntaskan Integrasi Platform Observabilitas:**
   Menyediakan dashboard visualisasi Grafana, standardisasi log aggregation, otomatisasi deployment Ansible, dan persiapan integrasi enterprise event bridge (TN-020).

---

## 📋 Task List

### Kategori 1: Pemantauan Mandiri Diagnostic Service (Mitigasi TM-ADR-0016)

Kategori ini merupakan prioritas utama (*Critical*) untuk mengantisipasi keterbatasan pada **TM-ADR-0016** (*Designate Diagnostic Service as the Canonical Incident Notification Authority*). Karena Diagnostic Service menjadi satu-satunya pihak yang berwenang mengirimkan notifikasi `TomcatDown`, kegagalan pada container Diagnostic Service tidak boleh menyebabkan tim operasional kehilangan pemberitahuan (*silent failure*).

```text
                                Prometheus
                                    |
                    +---------------+---------------+
                    | (Scrape)                      | (Scrape)
                    v                               v
          [Tomcat JMX Exporter]          [Diagnostic Service]
                    |                               |
              (up == 0)                       (up == 0)
                    |                               |
                    v                               v
              Alertmanager                    Alertmanager
                    |                               |
             (Alert: TomcatDown)             (Alert: DiagnosticServiceDown)
                    |                               |
                    v                               | (Bypass Webhook)
         [Webhook HTTPS Internal]                   |
                    |                               |
                    v                               v
           Diagnostic Service              [Direct SMTP Delivery]
                    |                               |
                    v                               v
                 Mailpit                         Mailpit
           (Laporan Diagnosis)             (Alert Darurat Operator)
```

#### TASK-TM-001: Konfigurasi Scrape Target `/health` Diagnostic Service di Prometheus

- **Status:** `Completed` ✅
- **Deskripsi:**
  Menambahkan target scrape baru pada konfigurasi Prometheus (`prometheus.yml`) untuk memantau endpoint kesehatan HTTP Diagnostic Service (`GET /health`) secara reguler.
- **Kebutuhan Teknis:**
  - Job name: `tomcat-diagnostic-service`.
  - Skema: HTTPS dengan verifikasi TLS internal menggunakan CA bersama (`diagnostic-service-ca.crt`).
  - Endpoint target: `https://diagnostic-service:8443/health`.
  - Scrape interval: `15s`, scrape timeout: `5s`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Prometheus menghasilkan metrik `up{job="tomcat-diagnostic-service"} == 1` ketika container Diagnostic Service beroperasi normal.
  - Metrik berubah menjadi `up == 0` dalam toleransi waktu 1 siklus scrape saat service dimatikan.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Konfigurasi [`prometheus.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/prometheus.yml) dan initializer volume [`initialize-prometheus-volumes.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/initialize-prometheus-volumes.sh) disesuaikan untuk menyalin truststore CA.
  - Validasi Promtool: `promtool check config config/prometheus/prometheus.yml` $\rightarrow$ `SUCCESS`.
  - Query Prometheus API saat container aktif:
    ```json
    {"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"diagnostic-service:8443","job":"tomcat-diagnostic-service"},"value":[1788855610.066,"1"]}]}}
    ```
  - Query Prometheus API saat container dimatikan (`podman stop diagnostic-service`):
    ```json
    {"metric":{"__name__":"up","instance":"diagnostic-service:8443","job":"tomcat-diagnostic-service"},"value":[1788855677.756,"0"]}
    ```

#### TASK-TM-002: Pembuatan Alert Rule `DiagnosticServiceDown` di Prometheus

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mendefinisikan aturan alert Prometheus untuk mendeteksi matinya Diagnostic Service atau kegagalan komunikasi scrape internal.
- **Kebutuhan Teknis:**
  - Alert name: `DiagnosticServiceDown`.
  - Formula evaluasi: `up{job="tomcat-diagnostic-service"} == 0`.
  - Durasi (`for`): `1m` (untuk menghindari transient network blip).
  - Severity: `critical`.
  - Annotations: Memuat ringkasan bahwa jalur notifikasi otomatis insiden Tomcat terputus dan operator harus segera memeriksa status container service.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Alert berpindah ke status `firing` pada Prometheus dashboard setelah container disimulasikan mati selama lebih dari 1 menit.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Aturan ditambahkan pada [`application-health.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/rules/application-health.yml).
  - Unit test promtool ditambahkan pada [`application-health.test.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/tests/application-health.test.yml):
    `promtool test rules application-health.test.yml` $\rightarrow$ `SUCCESS`.
  - Status aktif di Prometheus API (`http://127.0.0.1:9090/api/v1/alerts`) setelah simulasi downtime > 1m:
    ```json
    {
      "labels": {
        "alertname": "DiagnosticServiceDown",
        "check": "service-availability",
        "instance": "diagnostic-service:8443",
        "job": "tomcat-diagnostic-service",
        "service": "diagnostic-service",
        "severity": "critical"
      },
      "state": "firing",
      "value": "0e+00"
    }
    ```

#### TASK-TM-003: Konfigurasi Direct SMTP Routing di Alertmanager untuk Alert Monitoring Mandiri

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mengonfigurasi rute khusus di Alertmanager (`alertmanager.yml`) agar seluruh alert terkait kesehatan Diagnostic Service langsung dikirimkan melalui jalur email langsung (direct SMTP) ke Mailpit / kanal on-call, sepenuhnya melewati webhook Diagnostic Service.
- **Kebutuhan Teknis:**
  - Routing rule: Cocokkan label `alertname="DiagnosticServiceDown"`.
  - Receiver: `direct-email-emergency` (koneksi SMTP langsung ke Mailpit `mailpit:1025`, `send_resolved: true`).
  - Webhook bypass: Notifikasi darurat dikirim langsung via SMTP tanpa melalui webhook Diagnostic Service.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Saat container Diagnostic Service dimatikan paksa, Alertmanager mengirimkan email alert darurat langsung ke Mailpit dengan subjek `[FIRING] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown`.
  - Saat container dihidupkan kembali, Alertmanager mengirimkan email `[RESOLVED] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown`.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Konfigurasi [`alertmanager.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/alertmanager/alertmanager.yml) divalidasi dengan `amtool check-config` $\rightarrow$ `SUCCESS (3 receivers)`.
  - Mailpit API (`http://127.0.0.1:8025/api/v1/messages`) merekam penerimaan email darurat:
    1. **Emergency Firing Email:**
       - Subject: `[FIRING] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown (Instance: diagnostic-service:8443)`
       - From: `alertmanager@tomcat-monitoring.invalid`
       - To: `operator@tomcat-monitoring.invalid`
       - Route: Direct SMTP to Mailpit (Bypassing Diagnostic Service Webhook)
    2. **Emergency Resolved Email:**
       - Subject: `[RESOLVED] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown (Instance: diagnostic-service:8443)`
       - Content: `Diagnostic Service target diagnostic-service:8443 has recovered and is scrapeable again. Automated incident notification pipeline is restored.`

#### TASK-TM-017: Migrasi Universal Ingestion Alertmanager ke Diagnostic Service

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mengubah konfigurasi root route dan receiver pada Alertmanager (`alertmanager.yml`) sehingga seluruh alert monitoring tanpa terkecuali (ketersediaan runtime `TomcatDown`, kesehatan aplikasi `TomcatApplicationHealthFailed`, sinyal emas JVM `TomcatGCPauseHigh`/`TomcatThreadPoolSaturated`/`TomcatGCOverheadHigh`/`TomcatOldGenMemoryPressure`, dan kehilangan sinyal `TelegrafHealthScrapeUnavailable`) dialirkan langsung ke Diagnostic Service melalui webhook HTTPS internal.
- **Kebutuhan Teknis:**
  - Ubah default receiver root: `route: receiver: lab-diagnostic-service`.
  - Hapus receiver direct email `lab-mailpit` untuk notifikasi insiden operasional guna menegakkan prinsip *Single Canonical Notification Authority*.
  - Pertahankan satu-satunya sub-route darurat: matcher `alertname="DiagnosticServiceDown"` mengarah ke `direct-email-emergency` (direct SMTP bypass).
  - Skema JSON Webhook v4 di Diagnostic Service (`alertmanager-webhook-v4.schema.json`) digeneralisasi untuk menerima seluruh jenis alert dengan label identitas target wajib (`environment`, `host`, `tomcat_instance`, `job`, `instance`, `service`, `check`).
  - Label identitas `tomcat_instance: default` disematkan pada seluruh rule Prometheus di `jvm-workload-performance.yml` dan `application-health.yml`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Tidak ada alert insiden atau degradasi performa yang mengirimkan email mentah Alertmanager langsung ke Mailpit.
  - Seluruh notifikasi insiden dipublikasikan secara seragam oleh Diagnostic Service melalui format kanonikal Laporan Investigasi 7-Seksi SRE.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Skema webhook digeneralisasi dan diverifikasi melalui unit test `normalize-webhook.test.js` (48 passing).
  - Image Diagnostic Service `localhost/tomcat-diagnostic-service:0.1.4` (digest `sha256:1fea49330dc36e05dd65920a0b40da3742ac0046b7b9d6d9a0821f2479ca89f7`) berhasil dibangun dan lulus smoke test image.
  - Validasi Promtool dan Alertmanager config: `promtool test rules` $\rightarrow$ `SUCCESS`, `amtool check-config` $\rightarrow$ `SUCCESS (2 receivers)`.
  - Verifikasi isolasi rute webhook di disposable container (`verify-alertmanager-diagnostic-service.sh`) $\rightarrow$ `sqlite_events=2 (firing=1, resolved=1)`, `sqlite_probe=passed`.
  - Verifikasi live runtime insiden (`verify-jvm-workload-live.sh`) membuktikan transisi 4 alert JVM (`TomcatGCPauseHigh`, `TomcatThreadPoolSaturated`, `TomcatGCOverheadHigh`, `TomcatOldGenMemoryPressure`) hingga status firing dan recovery.
  - SQLite database Diagnostic Service merekam seluruh 30 event alert secara persisten, dan Mailpit merekam Laporan Investigasi 7-Seksi SRE resmi dari pengirim `diagnostic@tomcat-monitoring.invalid`.

#### TASK-TM-018: Implementasi Multi-Domain Diagnostic Dispatcher & Built-in Decision Engines

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mengembangkan arsitektur Dispatcher modular di `tomcat-diagnostic-service` untuk mendistribusikan evaluasi alert berdasarkan `event.labels.alertname` ke 4 sub-engine domain resmi (`TD-xx`, `AH-xx`, `GC-xx`, `TH-xx`) serta mempreservasi identitas `ruleId` pada subjek notifikasi email dan laporan 7-seksi SRE sesuai **TM-ADR-0023** (*Zero Undecided Alerts*).
- **Kebutuhan Teknis:**
  - Implementasi `src/domain/application-health-engine.js` (Cabang `AH-01` s/d `AH-05`).
  - Implementasi `src/domain/jvm-workload-engine.js` (Cabang `GC-01` s/d `GC-04`).
  - Implementasi `src/domain/concurrency-engine.js` (Cabang `TH-01` s/d `TH-03`).
  - Implementasi `src/domain/rulepack-loader.js` yang merutekan Layer 2 Dynamic Custom Rules dan Layer 1 Built-in Domain Engines.
  - Penyesuaian `diagnostic-worker.js`, `canonical-result.js`, dan `result-renderer.js` untuk preservasi nama alert dinamis.
  - Pembangunan image baru `localhost/tomcat-diagnostic-service:0.1.5` dan verifikasi live runtime beban kerja JVM.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Setiap alert yang masuk diproses oleh sub-engine domain yang tepat.
  - Subjek email di Mailpit secara akurat menampilkan nama alert asli (`TomcatGCPauseHigh`, `TomcatThreadPoolSaturated`, dll) bukan hardcoded `TomcatDown`.
  - Seluruh unit test domain engine dan dispatcher lulus 100%.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Lulus 54 unit test domain engines dan dispatcher pada `test/unit/domain-engines.test.js`.
  - Image `localhost/tomcat-diagnostic-service:0.1.5` diverifikasi live melalui `verify-jvm-workload-live.sh`.
  - Didokumentasikan secara lengkap pada [TN-006](engineering-journal/monitoring-platform-integration/TN-006-implement-multi-domain-diagnostic-dispatcher-and-decision-engines.md) dan [TM-ADR-0023](../../adr/tomcat-monitoring/adr-records/TM-ADR-0023.md).

---

### Kategori 2: Ketahanan Mesin Status & Penyimpanan Persisten (Mitigasi TM-ADR-0015)

Kategori ini menindaklanjuti konsekuensi teknis pada **TM-ADR-0015** (*Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern*), terkait pemrosesan status event dan pencegahan penumpukan data (*bounded storage*).

Karena Diagnostic Service menggunakan *Embedded SQLite* tanpa server database eksternal dan tanpa peran DBA, Diagnostic Service **wajib memiliki kemampuan mengelola dan memelihara database SQLite-nya sendiri (*self-managed / autonomous engine*)**, yang mencakup **3 pilar utama**:

```text
+-----------------------------------------------------------------------------+
|               Self-Managed SQLite Lifecycle in Diagnostic Service           |
+-----------------------------------------------------------------------------+
| 1. Self-Healing State Recovery (TASK-TM-004):                                |
|    Mendeteksi & memulihkan antrean macet (stale processing lock) pasca-crash|
|    secara otomatis tanpa intervensi manual operator / DBA.                  |
+-----------------------------------------------------------------------------+
| 2. Automated Storage Housekeeping & Pruning (TASK-TM-005):                  |
|    Memangkas event/log lama (> 30 hari) secara teratur & menjalankan        |
|    PRAGMA incremental_vacuum untuk mencegah kebocoran disk (bounded storage).|
+-----------------------------------------------------------------------------+
| 3. Autonomous Storage Telemetry & Quota Guard:                              |
|    Memantau ukuran file fisik database (diagnostic_db_size_bytes) dan       |
|    mengeksposnya ke Prometheus untuk pemantauan kapasitas host.             |
+-----------------------------------------------------------------------------+
```

---

#### TASK-TM-004: Implementasi Stale Lock Recovery pada Worker Ingestion

- **Status:** `Completed` ✅
- **Deskripsi:**
  Membangun mekanisme pemulihan otomatis untuk event alert yang tertahan di status `processing` akibat container Diagnostic Service restart mendadak di tengah proses analisis (*zero orphaned processing events*).
- **Kebutuhan Teknis:**
  - Penambahan kolom `retry_count` dan `lease_expires_at` pada tabel `work_queue` melalui migrasi `007-stale-lock-recovery-and-retention.sql`.
  - Pada `SqliteRepository.claimNext()`: sematkan batas waktu sewa `lease_expires_at = now + timeoutMs`.
  - Metode `recoverStaleLocks({ timeoutMs, maxRetries })`:
    1. Cari event dengan status `processing` yang memiliki usia lock kadaluwarsa (`started_at <= cutoff` atau `lease_expires_at <= now`).
    2. Jika `retry_count < maxRetries`: kembalikan status event menjadi `queued`, kosongkan lease, dan lakukan increment `retry_count`.
    3. Jika `retry_count >= maxRetries`: tandai sebagai `failed` untuk mencegah *infinite crash loop*.
  - Eksekusi pemulihan otomatis saat startup `DiagnosticApplication.start()` dan periodik pada worker loop.
  - Metrik Prometheus: `diagnostic_stale_locks_recovered_total` dan `diagnostic_stale_locks_exhausted_total`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Event yang terinterupsi saat berstatus `processing` secara otomatis dipulihkan ke `queued` dan dieksekusi hingga `completed` setelah container di-restart.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Unit test `test/unit/stale-lock-and-retention.test.js` membuktikan pemulihan status, kenaikan retry counter, dan transisi ke `failed` saat limit tercapai.
  - Injeksi event stale live (`event_id = 39`) pada container `diagnostic-service` diverifikasi sukses pulih pasca-restart: status `processing` $\rightarrow$ `completed` (`retry_count = 1`), metrik `diagnostic_stale_locks_recovered_total = 1`, dan email laporan terkirim ke Mailpit.
  - Didokumentasikan pada [TN-007](engineering-journal/monitoring-platform-integration/TN-007-implement-stale-lock-recovery-and-sqlite-state-resilience.md).

#### TASK-TM-005: Penjadwalan Housekeeping & Pruning Database SQLite

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mengimplementasikan rutinitas pembersihan otomatis (*retention cleanup*) pada database SQLite untuk membatasi ukuran disk persisten sesuai Service Level Objective (SLO).
- **Kebutuhan Teknis:**
  - Metode atomik `pruneHistoricalRecords({ retentionDays })` pada `SqliteRepository`:
    - Hapus rekam data kadaluwarsa dalam urutan relasi *Foreign Key* (`evidence_summaries`, `notification_attempts`, `canonical_results`, `work_queue`, `events`, `requests`, dan resolved `incidents`).
    - Jalankan perintah SQLite `PRAGMA incremental_vacuum`.
  - Tambahkan gauge metrik Prometheus `diagnostic_db_size_bytes` dan counter `diagnostic_housekeeping_runs_total`.
  - Eksekusi pada startup aplikasi dan loop berkala.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Data historis yang melewati batas retensi dibersihkan secara konsisten tanpa melanggar *Foreign Key constraints* dan ukuran file database terpantau via metrik.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Unit test `test/unit/stale-lock-and-retention.test.js` memvalidasi penghapusan terurut dan preservasi insiden aktif.
  - Metrik live pada endpoint `/metrics` mengekspos `diagnostic_housekeeping_runs_total 1` dan `diagnostic_db_size_bytes 303104`.
  - Didokumentasikan pada [TN-007](engineering-journal/monitoring-platform-integration/TN-007-implement-stale-lock-recovery-and-sqlite-state-resilience.md).

---

### Kategori 3: Tata Kelola Audit & Umpan Balik Tindakan Operator (TM-ADR-0014)

Kategori ini mendukung implementasi kebijakan **TM-ADR-0014** (*Enforce Zero Automatic Remediation for Diagnostic Service*), memastikan bahwa tindakan manual yang direkomendasikan sistem kepada operator dapat ditelusuri (*traceable*).

#### TASK-TM-006: Penyediaan Endpoint Audit Log untuk Konfirmasi Tindakan Operator

- **Status:** `Descoped / Superseded` ⚪
- **Deskripsi:**
  Menyediakan antarmuka pencatatan (*audit log endpoint*) pada Diagnostic Service agar tim operasional dapat mengonfirmasi eksekusi rekomendasi manual yang tercantum pada laporan insiden.
- **Hasil Evaluasi Arsitektural:**
  Berdasarkan evaluasi operasional nyata, penambahan manual REST API pada edge diagnostic service di masing-masing host menambah friksi operasional bagi SRE on-call dan tidak praktis untuk kebutuhan audit. Sesuai model operasional terpadu, Laporan Investigasi 7-Seksi SRE yang diterima bersama oleh Tim SRE dan Tim Monitoring diarsipkan secara terpusat. Tim Monitoring bertindak sebagai *custodian* resmi data bukti (*evidence dossier*) untuk audit dan post-mortem review, sehingga endpoint manual edge tidak diperlukan.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Tata kelola audit didukung penuh melalui arsip Laporan 7-Seksi SRE dan sistem ITSM/ticketing terpusat.

---

### Kategori 4: Perluasan Skenario Aturan Diagnostik (TM-ADR-0017)

Sesuai strategi bertahap pada **TM-ADR-0017** (*Adopt Vertical Slice Minimum Viable Product Scoping for Diagnostic Pilot*), setelah skenario `TomcatDown` terbukti stabil, sistem diperluas untuk mendeteksi degradasi performa sebelum terjadi downtime total.

#### TASK-TM-007: Perumusan Rulepack Skenario Degradasi Thread Starvation

- **Status:** `Completed` ✅ (TN-004)
- **Deskripsi:**
  Menyusun aturan Prometheus `TomcatThreadPoolSaturated` untuk mendeteksi kejenuhan penuh 100% pada Tomcat Connector Thread Pool (`tomcat_threads_busy_threads / tomcat_threads_current_threads >= 1.0` selama `for: 5m`) sesuai TM-ADR-0022.
- **Kebutuhan Teknis:**
  - Pemicu: Alert Prometheus `TomcatThreadPoolSaturated` (rasio thread sibuk terhadap kapasitas thread aktif = 100% berkelanjutan 5m).
  - Korelasi bukti: Metrik MBean `tomcat_threads_busy_threads` dan `tomcat_threads_current_threads`.
  - Aturan evaluasi: Klasifikasi insiden degradasi konkurensi sebelum terjadi kegagalan fatal (*task rejection*).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Rulepack lulus validasi unit test promtool dan aktif dievaluasi di Prometheus runtime.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Didefinisikan pada [`jvm-workload-performance.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/rules/jvm-workload-performance.yml).
  - Diuji unit pada [`jvm-workload-performance.test.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/tests/jvm-workload-performance.test.yml) $\rightarrow$ `SUCCESS`.
  - Dibukukan pada [TN-004](engineering-journal/monitoring-platform-integration/TN-004-implement-jvm-gc-and-concurrency-saturation-alert-rules.md) dan diverifikasi live pada [TN-005](engineering-journal/monitoring-platform-integration/TN-005-verify-jvm-gc-and-concurrency-saturation-alert-rules-in-live-runtime.md).

#### TASK-TM-008: Perumusan Rulepack Skenario Memory Pressure & GC Thrashing

- **Status:** `Completed` ✅ (TN-004 / TN-005)
- **Deskripsi:**
  Menyusun aturan Prometheus untuk Sinyal Emas GC JVM (`TomcatGCPauseHigh`, `TomcatGCOverheadHigh`, `TomcatOldGenMemoryPressure`) untuk mendeteksi latensi STW, inefisiensi CPU akibat GC thrashing, dan retensi Old Gen pasca-GC sesuai TM-ADR-0022.
- **Kebutuhan Teknis:**
  - Pemicu:
    - `TomcatGCPauseHigh`: Jeda STW $> 1.5\text{s}$ (`for: 1m`).
    - `TomcatGCOverheadHigh`: GC CPU overhead `(rate(jvm_gc_pause_seconds_sum[5m]) * 100) > 15` (`for: 5m`).
    - `TomcatOldGenMemoryPressure`: Retensi memori Old Gen `(used / max) * 100 > 90` (`for: 10m`).
  - Aturan evaluasi: Menghasilkan peringatan proaktif sebelum proses JVM dimatikan oleh cgroup OOM Killer kernel.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Rulepack lulus validasi unit test promtool dan aktif dievaluasi di Prometheus runtime.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Didefinisikan pada [`jvm-workload-performance.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/rules/jvm-workload-performance.yml).
  - Diuji unit pada [`jvm-workload-performance.test.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/config/prometheus/tests/jvm-workload-performance.test.yml) $\rightarrow$ `SUCCESS`.
  - Dibukukan pada [TN-004](engineering-journal/monitoring-platform-integration/TN-004-implement-jvm-gc-and-concurrency-saturation-alert-rules.md) dan diverifikasi live pada [TN-005](engineering-journal/monitoring-platform-integration/TN-005-verify-jvm-gc-and-concurrency-saturation-alert-rules-in-live-runtime.md).

---

### Kategori 5: Observabilitas & Kesiapan Platform Produksi (Roadmap TN-020)

Kategori ini mencakup pekerjaan infrastruktur dan platform monitoring menyeluruh sebagaimana dipetakan pada **TN-020**.

#### TASK-TM-009: Penyediaan Dashboard Grafana Terpusat untuk Tomcat & Monitoring Stack

- **Status:** `Descoped / Superseded` ⚪
- **Deskripsi:**
  Membangun template dashboard visualisasi Grafana yang memadukan metrik kesehatan runtime Tomcat, JVM, dan infrastruktur monitoring.
- **Hasil Evaluasi Arsitektural:**
  Kebutuhan visualisasi Grafana dikesampingkan (*descoped*) atas kesepakatan desain arsitektur karena platform monitoring stack difokuskan pada investigasi akar masalah otonom (*autonomous root-cause investigation*), pengiriman laporan kanonikal 7-seksi SRE via Enterprise SMTP Relay, dan query langsung Prometheus TSDB tanpa dependensi UI visualisasi tambahan.

#### TASK-TM-010: Standardisasi Log Aggregation & Pengelolaan Host Spool

- **Status:** `Completed` ✅ (TN-011)
- **Deskripsi:**
  Menstandarkan pola penulisan log aplikasi Tomcat pada Podman Named Volume `tomcat_logs` dan siklus hidup direktori spool host persisten (`${HOME}/.local/share/tomcat-monitoring/spool`, izin `0700`) dengan mekanisme pembersihan otonom (*Zero Unbounded Spool*).
- **Kebutuhan Teknis:**
  - Penegakan pembersihan otomatis berkas spool atomik `.json` yang melewati batas usia (`DEFAULT_MAX_SPOOL_AGE_HOURS=24`) oleh daemon Event Collector.
  - Penegakan kuota kapasitas jumlah berkas maksimal (`DEFAULT_MAX_SPOOL_FILES=1000`) melalui mekanisme *FIFO pruning* (menghapus berkas tertua terlebih dahulu saat terjadi *event storm*).
  - Pembersihan berkas temporer yatim/terlantar (`DEFAULT_STALE_TMP_AGE_MINUTES=60`).
  - Verifikasi isolasi hak akses direktori spool (izin `0700` milik user rootless) dan berkas bukti (`0600`).
  - Konsolidasi dokumentasi SOP manajemen daemon event collector dan volume log Tomcat pada README repositori terkait.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Direktori spool tidak mengalami pertumbuhan berkas tak terkendali, kuota berkas terjaga secara bounded, dan hak akses direktori serta berkas bukti terkunci ketat.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Parameter retensi dikonfigurasi di [`CONFIG`](file:///home/eddywiyatno/git/tomcat-diagnostic-event-collector/CONFIG) dan divalidasi oleh `scripts/validate.sh` $\rightarrow$ `SUCCESS`.
  - Logika `prune_stale_spool_records` di [`src/collector.sh`](file:///home/eddywiyatno/git/tomcat-diagnostic-event-collector/src/collector.sh) lulus 100% pada unit & component test [`test/test-collector.sh`](file:///home/eddywiyatno/git/tomcat-diagnostic-event-collector/test/test-collector.sh) (memvalidasi pemangkasan file `.json` lama, file `.tmp` stale, preservasi file valid, penegakan FIFO cap, dan izin `0700`/`0600`).
  - Daemon `systemd --user` `tomcat-diagnostic-event-collector.service` terpasang dan berstatus `active (running)` di `devops-lab`.
  - Seluruh 62 unit dan integration test pada `tomcat-diagnostic-service` tetap lulus 100% tanpa regresi saat membaca spool persisten.
  - Didokumentasikan secara lengkap pada [TN-011](engineering-journal/monitoring-platform-integration/TN-011-implement-and-verify-spool-lifecycle-and-log-retention.md).

#### TASK-TM-011: Otomatisasi Deployment Menggunakan Playbook Ansible

- **Status:** `Completed` ✅
- **Deskripsi:**
  Mengembangkan dan memvalidasi Ansible Playbooks dan Roles modular untuk penyediaan infrastruktur armada peladen (*fleet provisioning*) dan deployment tumpukan monitoring (*container stack deployment*) secara idempoten pada platform Tomcat Monitoring.
- **Kebutuhan Teknis:**
  - Pemisahan batas tanggung jawab ke dalam 3 Ansible Roles modular:
    1. `role_host_prep`: Inisialisasi direktori izin ketat `0700` (`spool`, `secrets`, `tls`), material rahasia & sertifikat TLS (`0400`/`0444`), *network bridge* `devops-lab`, dan 8 *named volumes*.
    2. `role_event_collector`: Templating unit `systemd --user` `tomcat-diagnostic-event-collector.service`, registrasi dan aktivasi daemon host.
    3. `role_container_stack`: Rekonsiliasi *desired state* deklaratif untuk Mailpit, Postfix Enterprise Relay, Tomcat JMX Exporter, Prometheus, Alertmanager, Diagnostic Service, serta *multi-endpoint readiness probing*.
  - Penyusunan inventori hierarkis lintas lingkungan (`inventories/lab.ini`, `inventories/staging.ini`, `inventories/production.ini`, dan `inventories/group_vars/all.yml`).
  - Pembuatan runner adaptif `scripts/run-ansible-playbook.sh` dengan dukungan biner lokal dan kontainer pengontrol terisolasi `localhost/ansible-controller:1.0` (`--network host`, socket Podman mount, volume pengguna).
  - Penegakan tata kelola *Zero Secret Leakage* dan izin berkas ketat tanpa *hardcoded credentials*.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Seluruh rangkaian validasi sintaksis Ansible dan tata kelola direktori lulus 100% (`scripts/validate-ansible.sh` dan `scripts/validate.sh`).
  - Playbook `deploy-stack.yml` berhasil men-deploy seluruh komponen dari kondisi bersih (*clean host*) dan membuktikan kesiapan seluruh endpoint layanan (`ok=35`, `changed=2`, `failed=0`).
  - Eksekusi ulang `deploy-stack.yml` membuktikan idempotensi 100% tanpa mutasi yang tidak diinginkan (`ok=33`, `changed=0`, `failed=0`, `skipped=18`).
  - Seluruh rangkaian uji insiden *live* (`verify-postfix-relay.sh`, `verify-alertmanager-webhook.sh`) lulus 100% di atas tumpukan yang di-deploy via Ansible.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Didokumentasikan secara lengkap pada [TN-009](engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md).
  - Validasi sintaksis `validate-ansible.sh` $\rightarrow$ `SUCCESS (deploy-stack.yml & provision-fleet.yml)`.
  - First run `deploy-stack.yml` $\rightarrow$ `ok=35, changed=2, failed=0, skipped=15`.
  - Idempotency rerun `deploy-stack.yml` $\rightarrow$ `ok=33, changed=0, failed=0, skipped=18`.
  - Live incident verification `verify-postfix-relay.sh` $\rightarrow$ `PASS: Seluruh pengujian Pola A berhasil diverifikasi!`.

#### TASK-TM-012: Integrasi Enterprise Notification Bridge (TrueSight / Webhook Enterprise)

- **Status:** `Descoped / Superseded` ⚪
- **Deskripsi:**
  Menyiapkan adapter integrasi eksternal menuju sistem manajemen event enterprise (seperti TrueSight Operations Management atau Event Bridge) ketika infrastruktur target tersedia.
- **Hasil Evaluasi Arsitektural:**
  Integrasi TrueSight dikesampingkan (*descoped*) karena tidak ada infrastruktur TrueSight pada target lingkungan. Jalur notifikasi insiden operasional telah selesai dan terbukti handal menggunakan **Enterprise SMTP Relay (Pola A)** dengan enkripsi STARTTLS Port 587, otentikasi Cyrus SASL, dan kepatuhan 4 RFC Enterprise Headers ([TASK-TM-015](file:///home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/follow-up-tasks.md#task-tm-015-konfigurasi-enterprise-smtp-relay--otentikasi-terenkripsi-kesiapan-produksi-notifikasi) / [TN-010](engineering-journal/monitoring-platform-integration/TN-010-implement-and-verify-enterprise-smtp-configuration-and-headers.md)).

#### TASK-TM-019: Otomatisasi CI/CD Pipeline Menggunakan Jenkins

- **Status:** `Completed` ✅ (TN-001 s.d. TN-007)
- **Deskripsi:**
  Mengimplementasikan pipeline Continuous Integration dan Continuous Deployment (CI/CD) otomatis berbasis Jenkins untuk membangun (*build*), menguji (*automated linting, contract validation, and unit/integration testing*), mempublikasikan image kontainer, dan men-deploy stack Tomcat Monitoring ke lingkungan runtime Podman rootless secara *zero-touch*.
- **Kebutuhan Teknis:**
  - Penyusunan declarative `Jenkinsfile` pada repositori terkait (`tomcat-monitoring`, `tomcat-diagnostic-service`, `tomcat-diagnostic-event-collector`).
  - Tahapan pipeline otomatis:
    1. **Stage 1 — Source Checkout & Linting:** Checkout branch `main`, verifikasi shell syntax, dan validasi contract non-secret (`./scripts/validate.sh`).
    2. **Stage 2 — Automated Testing:** Eksekusi unit tests, schema validation, dan component assertions.
    3. **Stage 3 — Container Image Build & Digest Pinning:** Pembuatan immutable container images menggunakan Podman / Buildah serta penentuan digest SHA-256 lokal.
    4. **Stage 4 — Continuous Deployment (CD):** Pembaruan kontainer runtime (`deploy-*.sh`) dengan kebijakan rollback otomatis (*zero-downtime deployment*).
    5. **Stage 5 — Post-Deployment Verification:** Eksekusi smoke test & live incident pipeline verification (`test-tomcatdown-live.sh`, `verify-postfix-relay.sh`).
  - Manajemen kredensial dan secret injection aman via Jenkins Credentials Store (mencegah kebocoran rahasia ke Git).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Setiap commit / push ke repository Git secara otomatis memicu eksekusi pipeline Jenkins.
  - Pipeline menolak (*fail-fast*) setiap perubahan yang melanggar kontrak validasi atau gagal dalam rangkaian uji otomatis.
  - Deployment ke runtime Podman rootless berjalan lancar dengan status build `SUCCESS` dan seluruh verifikasi pasca-deploy lulus 100%.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Deklaratif `Jenkinsfile` diimplementasikan dan diverifikasi pada `tomcat-diagnostic-service` (TN-004), `tomcat-diagnostic-event-collector` (TN-005), dan `tomcat-monitoring` (TN-006).
  - Eksekusi *live* di Jenkins Controller membuktikan kelulusan 100% build `SUCCESS` pada agen DooD non-root `builder-01` (TN-007).
  - Verifikasi otomatis insiden `TomcatDown` membuktikan penerimaan Laporan Investigasi 7-Seksi SRE via Postfix STARTTLS + SASL Relay Bridge di Mailpit (TN-007).

#### TASK-TM-020: Standardisasi Portabilitas Runtime Kontainer Multi-Engine (Podman & Docker Support)

- **Status:** `Completed` ✅ (TN-008)
- **Deskripsi:**
  Mengimplementasikan pustaka pembantu `container-runtime-helper.sh` dan menstandarisasi portabilitas eksekusi kontainer multi-mesin (Podman dan Docker dual-engine support) secara adaptif di seluruh 5 repositori ekosistem platform Tomcat Monitoring sesuai arsitektur [TM-ADR-0026](../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md).
- **Kebutuhan Teknis:**
  - Deteksi runtime otomatis via `detect_container_engine` dengan urutan probe `podman` lalu `docker` dan kemampuan override deklaratif via berkas `CONFIG` (`CONTAINER_ENGINE`).
  - Pelindung relabeling volume SELinux adaptif (`get_volume_flag`) yang hanya menyematkan flag `:z`/`:Z`/`:ro,z` jika host aktif SELinux (`getenforce`) dan engine adalah Podman, serta beralih ke `:ro` atau tanpa flag pada Docker maupun host non-SELinux.
  - Isolasi flag `--userns=keep-id` (`get_userns_flag`) eksklusif untuk Podman.
  - Abstraksi *lifecycle assertions* seragam (`container_exists`, `image_exists`, `volume_exists`, `network_exists`).
  - Refaktorisasi skrip operasional di 5 repositori (`ansible-controller`, `alertmanager`, `tomcat-diagnostic-service`, `tomcat-diagnostic-event-collector`, `tomcat-monitoring`).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Seluruh skrip operasional dapat berjalan secara deterministik di lingkungan Podman maupun Docker tanpa modifikasi manual berkas.
  - 100% kelulusan quality gates (validasi statis, unit/integration tests, dan live verification suites) tanpa regresi.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Validasi sintaks Bash `bash -n` lintas 5 repositori $\rightarrow$ `Exit Code 0 (PASS)`.
  - Validasi statis & 62 unit/integration test suites `tomcat-diagnostic-service` $\rightarrow$ `PASS (62/62 tests)`.
  - Validasi governance & retensi spool `tomcat-diagnostic-event-collector` $\rightarrow$ `PASS (100%)`.
  - Validasi baseline contract & verifikasi webhook / Mailpit `tomcat-monitoring` $\rightarrow$ `PASS`.
  - Didokumentasikan secara lengkap pada [TN-008](engineering-journal/continuous-integration-and-deployment/TN-008-implement-and-standardize-multi-engine-container-runtime-portability.md) dan [TM-ADR-0026](../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md).

#### TASK-TM-013: Integrasi Shared Persistent Volume Mount untuk Log Runtime Tomcat (Kesiapan Produksi TN-019)

- **Status:** `Completed` ✅ (TN-008)
- **Deskripsi:**
  Mengonfigurasi volume mount persisten antara container runtime Tomcat (`tomcat-jmx-exporter`) dan host/Diagnostic Service agar log aplikasi real-time (`catalina.out` dan `catalina.YYYY-MM-DD.log`) dapat dibaca langsung oleh Diagnostic Service tanpa bergantung pada injeksi manual atau mock fixture pengujian.
- **Kebutuhan Teknis:**
  - Perbarui skrip peluncuran container Tomcat ([`scripts/run.sh`](file:///home/eddywiyatno/git/tomcat-jmx-exporter/scripts/run.sh) & [`scripts/deploy-tomcat.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/deploy-tomcat.sh)) untuk menyertakan volume mount Podman Named Volume:
    `--volume "${LOG_VOLUME:-tomcat_logs}:/usr/local/tomcat/logs:z"`.
  - Standarisasi seluruh penyimpanan persisten monitoring menggunakan Podman Named Volumes (`diagnostic_data`, `prometheus_data`, `alertmanager_data`, dan `tomcat_logs`) untuk mengeliminasi dependensi direktori `/tmp` yang volatile dan menghindari path host absolut.
  - Verifikasi bahwa log aplikasi yang ditulis saat startup atau error runtime secara otomatis terbaca oleh `bounded-file-reader` pada `diagnostic-service` via `--volume "tomcat_logs:/run/tomcat-diagnostic/logs:ro,z"`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Log runtime container Tomcat hidup tersinkronisasi langsung ke mount `/run/tomcat-diagnostic/logs/catalina.out` (atau daily log) pada Diagnostic Service via Named Volume `tomcat_logs`.
  - Skenario diagnosis kegagalan aplikasi nyata (seperti error connection pool, OOM, atau bind exception) dapat dievaluasi secara otomatis dari log asli tanpa intervensi penulisan manual `echo`.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Parameter volume `--volume "${LOG_VOLUME:-tomcat_logs}:/usr/local/tomcat/logs:z"` dipasang pada `tomcat-jmx-exporter/scripts/run.sh`.
  - Verifikasi live runtime membuktikan berkas log terbentuk otomatis pada Named Volume `tomcat_logs` dan cuplikan log tersaji pada Seksi 4 (*Correlated Log Evidence*) di laporan email Mailpit.
  - Didokumentasikan pada [TN-008](engineering-journal/monitoring-platform-integration/TN-008-integrate-live-prometheus-evidence-adapter-and-shared-persistent-logs.md).

#### TASK-TM-014: Otomatisasi Service & Daemonization Event Collector (Kesiapan Produksi TN-016)

- **Status:** `Completed` ✅
- **Deskripsi:**
  Membangun skrip deployment otomatis dan unit service `systemd --user` untuk menjalankan `tomcat-diagnostic-event-collector` sebagai daemon persisten di latar belakang, menggantikan eksekusi manual ad-hoc atau one-shot saat pengujian.
- **Kebutuhan Teknis:**
  - Implementasi skrip deployment [`scripts/deploy-event-collector.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/deploy-event-collector.sh) pada repositori `tomcat-monitoring`.
  - Pembuatan unit service `~/.config/systemd/user/tomcat-diagnostic-event-collector.service` dengan restart policy `always`.
  - Pengalihan path spooling dari direktori ephemeral `/tmp/diagnostic-spool` ke path persisten non-volatile dengan hak akses `0700` (`${HOME}/.local/share/tomcat-monitoring/spool`).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Restricted Event Collector aktif secara otomatis sebagai daemon background dan segera merekam event Podman (`died`, `stop`, `oom`, `start`) ke direktori spool secara atomik tanpa intervensi manual operator.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Unit test `test/test-collector.sh` dan validator `scripts/validate.sh` pada `tomcat-diagnostic-event-collector` lulus 100% dengan verifikasi izin direktori `0700`.
  - Skrip deployment `scripts/deploy-event-collector.sh` memasang dan mengaktifkan service `systemd --user` `tomcat-diagnostic-event-collector.service` dengan status `active (running)`.
  - Direktori spool persisten `${HOME}/.local/share/tomcat-monitoring/spool` di-mount secara *read-only* ke container `diagnostic-service` (`/run/tomcat-diagnostic/spool:ro,z`).
  - Verifikasi live runtime membuktikan event container (`stop`/`start`) secara otomatis terekam oleh daemon background ke dalam berkas JSON berversi dan berhasil dikonsumsi oleh Diagnostic Service serta dipersistensikan ke tabel SQLite `evidence_summaries`.
  - Didokumentasikan pada [TN-009](engineering-journal/monitoring-platform-integration/TN-009-implement-and-verify-event-collector-daemonization-and-persistent-spool.md).

#### TASK-TM-015: Konfigurasi Enterprise SMTP Relay & Otentikasi Terenkripsi (Kesiapan Produksi Notifikasi)

- **Status:** `Completed` ✅ (TN-010)
- **Deskripsi:**
  Mengembangkan konfigurasi SMTP Relay produksi yang mendukung `requireTLS`, otentikasi kredensial Cyrus SASL terisolasi, dan header email standar enterprise RFC (`Auto-Submitted`, `X-Priority`, `X-Incident-Target`, `X-Diagnostic-Rule`).
- **Kebutuhan Teknis:**
  - Konfigurasi parameter `smtp` pada `application-config-v1.schema.json` dan `application.json` (`host`, `port: 587`, `secure: false`, `requireTLS: true`, path file username & password).
  - Manajemen secret file kredensial SMTP dengan izin ketat `0400`/`0444` yang dipasang via volume mount rootless.
  - Penambahan header standar enterprise RFC pada `src/adapters/smtp-adapter.js` (`Auto-Submitted: auto-generated`, `X-Priority: 1/3`, `X-Incident-Target`, `X-Diagnostic-Rule`).
  - Verifikasi otomatis alur pengiriman terenkripsi dan terotentikasi via suite `verify-postfix-relay.sh`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Laporan diagnostik 7-seksi SRE terkirim secara aman melalui enterprise SMTP relay terotentikasi, lolos negative testing auth, dan memuat seluruh header enterprise pada inbox penerima.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Image Diagnostic Service `localhost/tomcat-diagnostic-service:0.1.8` (digest `sha256:4519277d6a36d8ce0ce9cf01434ee0f0302e1ba4a63e3b0abe883e4497b5ab2e`) dibangun dan lulus 62 unit/integration tests (100% pass).
  - Suite pengujian otomatis `scripts/verify-postfix-relay.sh` memvalidasi:
    1. Penolakan koneksi relay tanpa kredensial SASL (`554 5.7.1 Access denied`).
    2. Penolakan koneksi dengan password salah (`535 5.7.8 Authentication failed`).
    3. Pengiriman terotentikasi via Submission Port 587 (TLSv1.3 + SASL PLAIN).
    4. End-to-end incident webhook evaluation dan pengiriman laporan 7-seksi SRE.
    5. Verifikasi kepatuhan header RFC (`Auto-Submitted: auto-generated`, `X-Priority: 1`, `X-Incident-Target: lab/tomcat-01/default`, `X-Diagnostic-Rule: TomcatDown`) via Mailpit API.
    6. Audit antrean Postfix bersih (`Mail queue is empty`).
  - Didokumentasikan secara lengkap pada [TN-010](engineering-journal/monitoring-platform-integration/TN-010-implement-and-verify-enterprise-smtp-configuration-and-headers.md).

#### TASK-TM-016: Integrasi Live Prometheus Evidence Adapter pada Application Lifecycle (Kesiapan Produksi Metrik)

- **Status:** `Completed` ✅ (TN-008)
- **Deskripsi:**
  Menghubungkan modul `PrometheusAdapter` ke dalam fungsi pengumpul bukti live `createDefaultEvidenceCollector` pada `src/application/application.js` dan menyertakan `prometheusSelector` pada allowlist `targets.json` di runtime deployment.
- **Kebutuhan Teknis:**
  - Panggil `prometheusAdapter.query()` saat worker mengeksekusi analisis insiden `firing`.
  - Tambahkan konfigurasi `prometheusSelector` (misal: `job="tomcat-jmx-exporter",instance="tomcat-jmx-exporter:9404"`) pada target allowlist.
  - Pastikan timeout agresif (5000ms) tidak memblokir rantai evaluasi bukti lainnya jika Prometheus tidak responsif.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Snapshot metrik live (memory pool, thread busy, scrape health) secara otomatis terlampir pada `evidence_summaries` di database SQLite saat insiden `TomcatDown` diproses.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Skema konfigurasi diperbarui (`application-config-v1.schema.json`) dan diverifikasi melalui 61 unit dan integration tests (100% pass).
  - Snapshot metrik live `up`, `jvm_memory_pool_used_bytes`, dan `tomcat_threads_busy_threads` tersimpan di SQLite `evidence_summaries` dan dirender pada Seksi 3 (*Key Metrics Snapshot*) Laporan SRE di Mailpit.
  - Didokumentasikan pada [TN-008](engineering-journal/monitoring-platform-integration/TN-008-integrate-live-prometheus-evidence-adapter-and-shared-persistent-logs.md).

#### TASK-TM-025: Integrasi Enterprise Container Registry & Konfigurasi Siklus Hidup Citra Plug-and-Play

- **Status:** `Completed` ✅ (TN-010)
- **Deskripsi:**
  Mengimplementasikan standardisasi integrasi repositori citra tingkat enterprise (*Enterprise Container Registry Integration*) yang bersifat siap pakai (*Plug-and-Play*) dan nir-modifikasi logika (*Zero Logic Modification*) di seluruh 5 repositori ekosistem platform Tomcat Monitoring.
- **Kebutuhan Teknis:**
  - Standardisasi variabel konfigurasi deklaratif (`REGISTRY_URL`, `REGISTRY_NAMESPACE`, `REGISTRY_TLS_VERIFY`, `IMAGE_PULL_POLICY`, `REGISTRY_AUTH_FILE`) pada `CONFIG` dan `inventories/group_vars/all.yml`.
  - Penyediaan template enterprise `CONFIG.example` dan `inventories/production.ini.example`.
  - Implementasi helper autentikasi terisolasi `scripts/registry-login-helper.sh` berbasis `--authfile`.
  - Penambahan task rekonsiliasi penarikan citra deklaratif `roles/role_container_stack/tasks/pull_images.yml` di Ansible.
  - Penyusunan SOP Panduan Migrasi Enterprise Container Registry.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Migrasi ke registry privat kantor (Harbor/Nexus/Quay) dapat dieksekusi murni via berkas konfigurasi deklaratif tanpa mengubah kode logika.
  - Seluruh rangkaian validasi statis, sintaksis Ansible, dan verifikasi insiden *live* lulus 100%.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Didokumentasikan secara lengkap pada [TN-010](engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md).
  - Pembangunan citra dengan parameter Harbor (`harbor.internal.corp:5000/tomcat-monitoring/...`) berhasil dan lulus verifikasi.
  - Validasi sintaksis `validate-ansible.sh` dan `validate.sh` $\rightarrow$ `SUCCESS`.
#### TASK-TM-026: Perancangan & Standardisasi Orkestrasi Multi-OS via Container Engine Socket API dan Kakas Go (tmctl & tm-agent)

- **Status:** `Completed (Design & Architecture)` ✅ (TN-011)
- **Deskripsi:**
  Merancang dan membakukan arsitektur orkestrasi lintas sistem operasi (Linux dan Windows) berbasis Container Engine Socket API (Podman / Docker) serta mendefinisikan spesifikasi kakas baris perintah tunggal `tmctl` (Go CLI) dan agen pengumpul event kontainer `tm-agent` (Go Daemon) untuk menuntaskan keterikatan pada shell Linux.
- **Kebutuhan Teknis:**
  - Evaluasi batas arsitektur Container Engine Socket API (Unix Socket, Windows Named Pipe, TCP mTLS).
  - Spesifikasi subperintah `tmctl` (`stack deploy/status/clean`, `rules ingest/export`, `registry login`, `validate`).
  - Spesifikasi streaming socket dan format snapshot `tm-agent` sesuai skema `event-record-v1.schema.json`.
  - Desain refaktorisasi Ansible roles deklaratif dan *OS Fact Branching*.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Desain arsitektur menuntaskan keterikatan pada skrip Bash di mesin target untuk mode manual dan otomatis.
  - Dokumentasi keputusan arsitektur [TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md) dan jurnal rekayasa [TN-011](engineering-journal/continuous-integration-and-deployment/TN-011-design-cross-platform-container-engine-api-orchestration-and-agent-architecture.md) dibakukan.
- **Bukti Verifikasi (*Verification Evidence*):**
  - Pembakuan [TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md).
  - Pembakuan [TN-011](engineering-journal/continuous-integration-and-deployment/TN-011-design-cross-platform-container-engine-api-orchestration-and-agent-architecture.md).

---

## 🛠️ Implementation Priority Matrix

| Task ID | Nama Task | Prioritas | Status | Sumber Acuan | Komponen Terdampak | Kriteria Hasil |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **TASK-TM-001** | Scrape Target `/health` Diagnostic Service | **P0 (Blocker)** | `Completed` ✅ | TM-ADR-0016 | Prometheus | Metrik `up` aktif untuk Diagnostic Service |
| **TASK-TM-002** | Alert Rule `DiagnosticServiceDown` | **P0 (Blocker)** | `Completed` ✅ | TM-ADR-0016 | Prometheus | Alert firing saat service mati > 1m |
| **TASK-TM-003** | Direct SMTP Emergency Route Alertmanager | **P0 (Blocker)** | `Completed` ✅ | TM-ADR-0016 | Alertmanager | Email darurat ke Mailpit bypass webhook |
| **TASK-TM-017** | Migrasi Universal Ingestion Alertmanager | **P0 (Blocker)** | `Completed` ✅ | TM-ADR-0016 | Alertmanager / DS | Seluruh alert diarahkan ke Diagnostic Service |
| **TASK-TM-018** | Multi-Domain Diagnostic Dispatcher | **P0 (Blocker)** | `Completed` ✅ | TM-ADR-0023 | Diagnostic Service | Dispatcher modular 4 domain engine & fidelity alertname |
| **TASK-TM-004** | Stale Lock Recovery Worker SQLite | **P1 (High)** | `Completed` ✅ | TM-ADR-0015 | Diagnostic Service | Re-queue otomatis event status processing (TN-007) |
| **TASK-TM-005** | Housekeeping & Retention DB SQLite | **P1 (High)** | `Completed` ✅ | TM-ADR-0015 | Diagnostic Service | Pembersihan data lama & disk terkendali (TN-007) |
| **TASK-TM-013** | Persistent Volume Mount Log Tomcat | **P1 (High)** | `Completed` ✅ | TN-019 / TN-008 | Tomcat Runtime / DS | Log container live terbaca otomatis oleh DS (TN-008) |
| **TASK-TM-014** | Daemonization Restricted Event Collector | **P1 (High)** | `Completed` ✅ | TN-016 / TN-009 | Event Collector | Collector berjalan sebagai systemd user service (TN-009) |
| **TASK-TM-015** | Enterprise SMTP Relay Configuration | **P1 (High)** | `Completed` ✅ | GAP-014 / TN-010 | Diagnostic Service | Notifikasi terkirim via relay SMTP TLS resmi (TN-010) |
| **TASK-TM-016** | Live Prometheus Evidence Wire-up | **P1 (High)** | `Completed` ✅ | GAP-004 / TN-008 | Diagnostic Service | Metrik live otomatis terlampir di evidence (TN-008) |
| **TASK-TM-019** | Otomatisasi CI/CD Pipeline Jenkins | **P1 (High)** | `Completed` ✅ | [TN-001](engineering-journal/continuous-integration-and-deployment/TN-001-design-production-ready-jenkins-cicd-pipeline-architecture.md) | Jenkins / CI-CD | Pipeline build, test, & deploy rootless otomatis (TN-001 s.d. TN-007) |
| **TASK-TM-020** | Portabilitas Multi-Engine Runtime (Podman/Docker) | **P1 (High)** | `Completed` ✅ | [TM-ADR-0026](../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md) | Seluruh Repositori | Helper adaptif, SELinux guard, userns guard (TN-008) |
| **TASK-TM-025** | Integrasi Enterprise Container Registry (Plug-and-Play) | **P1 (High)** | `Completed` ✅ | [TN-010](engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md) | Seluruh Repositori | Migrasi deklaratif ke Harbor/Nexus nir-modifikasi logika (TN-010) |
| **TASK-TM-026** | Standarisasi Orkestrasi Multi-OS & Go Tooling | **P1 (High)** | `Completed` ✅ | [TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md) | Seluruh Repositori | Arsitektur Container Engine API, tmctl CLI, & tm-agent (TN-011) |
| **TASK-TM-006** | Audit Trail Endpoint Tindakan Operator | **P2 (Medium)** | `Descoped` ⚪ | TM-ADR-0014 | Diagnostic Service | Digantikan arsip dossier 7-seksi terpusat |
| **TASK-TM-007** | Rulepack Thread Starvation | **P2 (Medium)** | `Completed` ✅ | TM-ADR-0017 / TM-ADR-0022 | Prometheus | Rule saturasi thread pool 100% (TN-004) |
| **TASK-TM-008** | Rulepack Memory Pressure & GC | **P2 (Medium)** | `Completed` ✅ | TM-ADR-0017 / TM-ADR-0022 | Prometheus | Sinyal Emas GC Pause, Overhead, Old Gen (TN-004) |
| **TASK-TM-009** | Dashboard Observabilitas Grafana | **P2 (Medium)** | `Descoped` ⚪ | TN-020 | Grafana | Fokus investigasi otonom & laporan email SRE |
| **TASK-TM-010** | Standardisasi Log & Spool Cleanup | **P2 (Medium)** | `Completed` ✅ | TN-020 / TN-011 | Event Collector / Host | Spool pruning 24h, cap 1000, & isolasi 0700 (TN-011) |
| **TASK-TM-011** | Ansible Playbook Deployment | **P3 (Planned)** | `Completed` ✅ | [TN-009](engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md) | Ansible / Podman | Zero-touch provisioning & deployment idempoten (TN-009) |
| **TASK-TM-012** | Integrasi TrueSight / Event Bridge | **P3 (Deferred)** | `Descoped` ⚪ | GAP-015 / TN-020 | Integration Bridge | Digantikan Enterprise SMTP Relay resmi (TN-010) |

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](diagnostic-mvp/index.md)
- [Diagnostic MVP Gap Register](diagnostic-mvp/gap-register.md)
- [Tomcat Monitoring Architecture](architecture/index.md)
- [Continuous Integration and Deployment Engineering Journal](engineering-journal/continuous-integration-and-deployment/index.md)
- [SOP: Panduan Migrasi Enterprise Container Registry](operations/enterprise-container-registry-migration-guide.md)
- [TM-ADR-0014 — Enforce Zero Automatic Remediation](../../adr/tomcat-monitoring/adr-records/TM-ADR-0014.md)
- [TM-ADR-0015 — Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern](../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)
- [TM-ADR-0016 — Designate Diagnostic Service as Canonical Incident Notification Authority](../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0017 — Adopt Vertical Slice MVP Scoping for Diagnostic Pilot](../../adr/tomcat-monitoring/adr-records/TM-ADR-0017.md)
- [TM-ADR-0024 — Adopt Decoupled Component CI and Orchestrated Stack CD Pipeline Architecture](../../adr/tomcat-monitoring/adr-records/TM-ADR-0024.md)
- [TM-ADR-0025 — Delineate Responsibilities Between Jenkins Release Orchestration and Ansible Configuration Provisioning](../../adr/tomcat-monitoring/adr-records/TM-ADR-0025.md)
- [TM-ADR-0026 — Adopt Adaptive Multi-Engine Container Runtime Portability for Podman and Docker Environments](../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md)
- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling for Multi-OS Orchestration](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TN-020 — Consolidate Diagnostic MVP Portfolio and Plan Next Phase](engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md)

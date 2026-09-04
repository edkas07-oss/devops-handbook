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

- **Deskripsi:**
  Menambahkan target scrape baru pada konfigurasi Prometheus (`prometheus.yml`) untuk memantau endpoint kesehatan HTTP Diagnostic Service (`GET /health`) secara reguler.
- **Kebutuhan Teknis:**
  - Job name: `tomcat-diagnostic-service`.
  - Skema: HTTPS dengan verifikasi TLS internal menggunakan CA bersama.
  - Endpoint target: `https://tomcat-diagnostic-service:8443/health`.
  - Scrape interval: `15s`, scrape timeout: `5s`.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Prometheus menghasilkan metrik `up{job="tomcat-diagnostic-service"} == 1` ketika container Diagnostic Service beroperasi normal.
  - Metrik berubah menjadi `up == 0` dalam toleransi waktu 1 siklus scrape saat service dimatikan.

#### TASK-TM-002: Pembuatan Alert Rule `DiagnosticServiceDown` di Prometheus

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

#### TASK-TM-003: Konfigurasi Direct SMTP Routing di Alertmanager untuk Alert Monitoring Mandiri

- **Deskripsi:**
  Mengonfigurasi rute khusus di Alertmanager (`alertmanager.yml`) agar seluruh alert terkait kesehatan Diagnostic Service langsung dikirimkan melalui jalur email langsung (direct SMTP) ke Mailpit / kanal on-call, sepenuhnya melewati webhook Diagnostic Service.
- **Kebutuhan Teknis:**
  - Routing rule: Cocokkan label `alertname="DiagnosticServiceDown"` atau `alertname="DiagnosticServiceScrapeUnavailable"`.
  - Receiver: `direct-email-emergency` (koneksi SMTP langsung ke Mailpit / relay server).
  - Webhook bypass: Pastikan tidak ada pengiriman balik ke webhook Diagnostic Service yang sedang tidak aktif.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Saat container Diagnostic Service dimatikan paksa, Alertmanager mengirimkan email alert darurat langsung ke Mailpit dengan subjek `[FIRING] DiagnosticServiceDown`.
  - Saat container dihidupkan kembali, Alertmanager mengirimkan email `[RESOLVED] DiagnosticServiceDown`.

---

### Kategori 2: Ketahanan Mesin Status & Penyimpanan Persisten (Mitigasi TM-ADR-0015)

Kategori ini menindaklanjuti konsekuensi teknis pada **TM-ADR-0015** (*Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern*), terkait pemrosesan status event dan pencegahan penumpukan data (*bounded storage*).

#### TASK-TM-004: Implementasi Stale Lock Recovery pada Worker Ingestion

- **Deskripsi:**
  Membangun mekanisme pemulihan otomatis untuk event alert yang tertahan di status `processing` akibat container Diagnostic Service restart mendadak di tengah proses analisis.
- **Kebutuhan Teknis:**
  - Penambahan kolom `lease_expires_at` atau audit `updated_at` pada tabel `alert_events`.
  - Saat worker inisialisasi pada startup:
    1. Cari event dengan status `processing` yang memiliki usia lock lebih lama dari ambang batas toleransi (misal: > 300 detik).
    2. Kembalikan status event menjadi `pending` disertai penambahan counter `retry_count` dan pencatatan log interupsi crash.
    3. Jika `retry_count` telah melampaui batas maksimum (misal: 3 kali), tandai sebagai `failed` dan buat alert diagnostik khusus agar tidak terjadi perulangan tanpa henti (*infinite crash loop*).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Event yang sengaja diinterupsi dengan `kill -9` saat berstatus `processing` dapat dipulihkan secara otomatis dan diselesaikan hingga berstatus `completed` setelah container aktif kembali.

#### TASK-TM-005: Penjadwalan Housekeeping & Pruning Database SQLite

- **Deskripsi:**
  Mengimplementasikan rutinitas pembersihan otomatis (*retention cleanup*) pada database SQLite untuk membatasi ukuran disk persisten sesuai Service Level Objective (SLO).
- **Kebutuhan Teknis:**
  - Hapus rekam data `alert_events`, `canonical_results`, dan `delivery_attempts` yang berusia lebih dari kebijakan retensi (misal: 30 hari).
  - Jalankan perintah SQLite `PRAGMA incremental_vacuum` atau `VACUUM` terjadwal di luar jam sibuk.
  - Tambahkan metrik Prometheus kustom untuk memantau ukuran file SQLite (`diagnostic_db_size_bytes`) dan jumlah record aktif.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Database SQLite tidak melampaui alokasi volume maksimum dan data yang kedaluwarsa dibersihkan secara konsisten tanpa mengunci transaksi aktif.

---

### Kategori 3: Tata Kelola Audit & Umpan Balik Tindakan Operator (TM-ADR-0014)

Kategori ini mendukung implementasi kebijakan **TM-ADR-0014** (*Enforce Zero Automatic Remediation for Diagnostic Service*), memastikan bahwa tindakan manual yang direkomendasikan sistem kepada operator dapat ditelusuri (*traceable*).

#### TASK-TM-006: Penyediaan Endpoint Audit Log untuk Konfirmasi Tindakan Operator

- **Deskripsi:**
  Menyediakan antarmuka pencatatan (*audit log endpoint*) pada Diagnostic Service agar tim operasional dapat mengonfirmasi eksekusi rekomendasi manual yang tercantum pada laporan insiden.
- **Kebutuhan Teknis:**
  - Endpoint baru: `POST /api/v1/incidents/{incident_id}/actions`.
  - Payload memuat: ID insiden, identitas operator, jenis tindakan yang diambil (misal: restart Tomcat, penambahan memory heap, penyesuaian connection pool), dan catatan teknis.
  - Data disimpan secara *append-only* di tabel `operator_actions` pada SQLite.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Setiap laporan insiden dapat dihubungkan dengan rekam jejak tindakan nyata yang diambil oleh tim SRE saat sesi evaluasi pasca-insiden (*post-mortem*).

---

### Kategori 4: Perluasan Skenario Aturan Diagnostik (TM-ADR-0017)

Sesuai strategi bertahap pada **TM-ADR-0017** (*Adopt Vertical Slice Minimum Viable Product Scoping for Diagnostic Pilot*), setelah skenario `TomcatDown` terbukti stabil, sistem diperluas untuk mendeteksi degradasi performa sebelum terjadi downtime total.

#### TASK-TM-007: Perumusan Rulepack Skenario Degradasi Thread Starvation

- **Deskripsi:**
  Menyusun paket aturan deklaratif (*declarative rulepack*) untuk mendeteksi kondisi penumpukan thread pada Tomcat Connector sebelum aplikasi berhenti merespons.
- **Kebutuhan Teknis:**
  - Pemicu: Alert Prometheus `TomcatHighThreadUsage` (rasio thread aktif terhadap kapasitas maksimal > 85%).
  - Korelasi bukti: Metrik MBean `tomcat_thread_pool_current_threads_busy` dan thread dump Java.
  - Aturan evaluasi: Klasifikasi insiden ke domain `RUNTIME_RESOURCE` dengan rekomendasi eskalasi kapasitas atau identifikasi thread macet (*deadlock/hung threads*).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Rulepack lulus validasi 5-Layer Guard dan dapat diuji melalui simulasi beban thread tinggi.

#### TASK-TM-008: Perumusan Rulepack Skenario Memory Pressure & GC Thrashing

- **Deskripsi:**
  Menyusun aturan diagnosis pra-OOM untuk mendeteksi kebocoran memori (*memory leak*) atau aktivitas Garbage Collection berlebih yang menurunkan throughput aplikasi secara drastis.
- **Kebutuhan Teknis:**
  - Pemicu: Alert Prometheus `TomcatHighHeapUsage` (heap > 90% selama > 5 menit berturut-turut).
  - Korelasi bukti: Metrik `jvm_gc_collection_seconds_sum`, frekuensi GC minor/major, dan log garbage collection.
  - Aturan evaluasi: Menghasilkan tingkat keyakinan (*confidence level*) tinggi untuk indikasi *Memory Leak* sebelum proses JVM terbunuh oleh OS cgroup OOM Killer.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Laporan diagnostik terkirim sebelum crash terjadi, memberikan jendela waktu bagi operator untuk melakukan heap dump dan mitigasi terencana.

---

### Kategori 5: Observabilitas & Kesiapan Platform Produksi (Roadmap TN-020)

Kategori ini mencakup pekerjaan infrastruktur dan platform monitoring menyeluruh sebagaimana dipetakan pada **TN-020**.

#### TASK-TM-009: Penyediaan Dashboard Grafana Terpusat untuk Tomcat & Monitoring Stack

- **Deskripsi:**
  Membangun template dashboard visualisasi Grafana yang memadukan metrik kesehatan runtime Tomcat, JVM, dan infrastruktur monitoring.
- **Kebutuhan Teknis:**
  - Panel JVM: Heap memory pool, non-heap usage, GC duration & throughput, live threads, class loading.
  - Panel Tomcat Connector: Active connections, request rate, error rate 4xx/5xx, processing time percentile (p95, p99).
  - Panel Monitoring Health: Status scrape Prometheus, antrean alert Alertmanager, ketersediaan Diagnostic Service, dan metrik latensi SQLite.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Dashboard tersedia dalam format JSON deklaratif, dapat diimpor langsung ke instance Grafana, dan menampilkan visualisasi real-time yang akurat.

#### TASK-TM-010: Standardisasi Log Aggregation & Pengelolaan Host Spool

- **Deskripsi:**
  Menstandarkan pola penulisan log aplikasi Tomcat dan siklus hidup direktori spool kolektor host (`/tmp/diagnostic-spool`).
- **Kebutuhan Teknis:**
  - Konfigurasi rotasi file log Tomcat menggunakan `logrotate` atau internal rotasi Tomcat (`catalina.out`, `localhost_access_log`).
  - Penegakan pembersihan otomatis file spool atomik `.json` yang telah melewati batas usia (misal: > 24 jam) oleh daemon Event Collector.
  - Verifikasi isolasi hak akses direktori spool (izin `0700` milik user rootless).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Direktori spool tidak mengalami pertumbuhan berkas tak terkendali dan izin direktori terlindungi dari akses proses lain.

#### TASK-TM-011: Otomatisasi Deployment Menggunakan Playbook Ansible

- **Deskripsi:**
  Mengembangkan playbook Ansible untuk penyediaan (*provisioning*) dan pembaruan (*zero-touch deployment*) seluruh stack monitoring.
- **Kebutuhan Teknis:**
  - Playbook mencakup pembuatan pod/container Podman rootless, pembuatan volume persisten, distribusi sertifikat TLS, penyusunan konfigurasi allowlist `targets.json`, dan pendaftaran systemd user service.
  - Manajemen secret (bearer token dan TLS private key) menggunakan Ansible Vault.
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Seluruh stack monitoring dapat dibangun ulang dari nol (*clean host*) secara terotomatisasi dan langsung lulus seluruh acceptance test.

#### TASK-TM-012: Integrasi Enterprise Notification Bridge (TrueSight / Webhook Enterprise)

- **Deskripsi:**
  Menyiapkan adapter integrasi eksternal menuju sistem manajemen event enterprise (seperti TrueSight Operations Management atau Event Bridge) ketika infrastruktur target tersedia.
- **Kebutuhan Teknis:**
  - Implementasi komponen penerjemah dari format *canonical result v1* ke format slot / kelas event TrueSight (`msend` payload).
  - Penutupan item kesenjangan **GAP-014** (TLS Produksi & DR) dan **GAP-015** (Integrasi TrueSight).
- **Kriteria Penerimaan (*Acceptance Criteria*):**
  - Event insiden berhasil diterima oleh enterprise event bridge dengan metadata severity, host, slot mapping, dan rekomendasi SOP yang sesuai standar enterprise.

---

## 🛠️ Implementation Priority Matrix

| Task ID | Nama Task | Prioritas | Sumber Acuan | Komponen Terdampak | Kriteria Hasil |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **TASK-TM-001** | Scrape Target `/health` Diagnostic Service | **P0 (Blocker)** | TM-ADR-0016 | Prometheus | Metrik `up` aktif untuk Diagnostic Service |
| **TASK-TM-002** | Alert Rule `DiagnosticServiceDown` | **P0 (Blocker)** | TM-ADR-0016 | Prometheus | Alert firing saat service mati > 1m |
| **TASK-TM-003** | Direct SMTP Emergency Route Alertmanager | **P0 (Blocker)** | TM-ADR-0016 | Alertmanager | Email darurat ke Mailpit bypass webhook |
| **TASK-TM-004** | Stale Lock Recovery Worker SQLite | **P1 (High)** | TM-ADR-0015 | Diagnostic Service | Re-queue otomatis event status processing |
| **TASK-TM-005** | Housekeeping & Retention DB SQLite | **P1 (High)** | TM-ADR-0015 | Diagnostic Service | Pembersihan data lama & disk terkendali |
| **TASK-TM-006** | Audit Trail Endpoint Tindakan Operator | **P2 (Medium)** | TM-ADR-0014 | Diagnostic Service | Log persisten tindakan manual SRE |
| **TASK-TM-007** | Rulepack Thread Starvation | **P2 (Medium)** | TM-ADR-0017 | Diagnostic Service | Deteksi degradasi thread pra-downtime |
| **TASK-TM-008** | Rulepack Memory Pressure & GC | **P2 (Medium)** | TM-ADR-0017 | Diagnostic Service | Deteksi dini memory leak pra-OOM |
| **TASK-TM-009** | Dashboard Observabilitas Grafana | **P2 (Medium)** | TN-020 | Grafana | Dashboard terpusat JVM, Tomcat, & Health |
| **TASK-TM-010** | Standardisasi Log & Spool Cleanup | **P2 (Medium)** | TN-020 / TN-016 | Event Collector / Host | Rotasi teratur & spool cleanup atomik |
| **TASK-TM-011** | Ansible Playbook Deployment | **P3 (Planned)** | TN-020 | Ansible / Podman | Zero-touch deployment seluruh stack |
| **TASK-TM-012** | Integrasi TrueSight / Event Bridge | **P3 (Deferred)** | GAP-015 / TN-020 | Integration Bridge | Pengiriman event terintegrasi enterprise |

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](diagnostic-mvp/index.md)
- [Diagnostic MVP Gap Register](diagnostic-mvp/gap-register.md)
- [Tomcat Monitoring Architecture](architecture/index.md)
- [TM-ADR-0014 — Enforce Zero Automatic Remediation](../../adr/tomcat-monitoring/adr-records/TM-ADR-0014.md)
- [TM-ADR-0015 — Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern](../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)
- [TM-ADR-0016 — Designate Diagnostic Service as Canonical Incident Notification Authority](../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0017 — Adopt Vertical Slice MVP Scoping for Diagnostic Pilot](../../adr/tomcat-monitoring/adr-records/TM-ADR-0017.md)
- [TN-020 — Consolidate Diagnostic MVP Portfolio and Plan Next Phase](engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md)

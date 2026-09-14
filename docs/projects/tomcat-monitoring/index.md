# Tomcat Monitoring

## Overview

Tomcat Monitoring adalah project generic yang menyediakan kapabilitas
monitoring ringan untuk Apache Tomcat berbasis container. JMX Exporter
dijalankan sebagai Java Agent di dalam JVM Tomcat untuk mengambil metrics secara
lokal tanpa mengaktifkan remote JMX.

Prometheus dijalankan sebagai container di dalam monitoring stack project dan
mengumpulkan metrics melalui HTTPS untuk menyediakan current dan historical
data bagi dashboard serta evaluasi alert. Telegraf memeriksa HTTP health
endpoint aplikasi untuk membedakan kondisi JVM yang aktif dari aplikasi yang
tidak sehat atau tidak dapat merespons.

Pendekatan embedded dipilih karena cakupan monitoring saat ini berfokus pada
runtime metrics dan application health tanpa membutuhkan platform observability
end-to-end. Analisis log dilakukan secara insidental menggunakan log lokal
dengan retensi dua sampai empat minggu. Dengan memanfaatkan kapasitas CPU dan
memory yang masih tersedia pada host, project dapat menyediakan monitoring
ringan tanpa menambah biaya dan administrasi full observability platform.

Project ini bersifat *platform-agnostic*, artinya alert tidak terikat pada satu
notification channel atau event management system tertentu. Target lab
email capture menggunakan Mailpit lokal telah diverifikasi tanpa Google
credential atau external delivery. Gmail App Password tidak lagi menjadi
baseline. Persistent Prometheus, Alertmanager, dan lab-only Mailpit sekarang
membuktikan real application-health firing/resolved delivery. Integrasi
TrueSight melalui Integration Bridge dipertahankan sebagai desain masa depan
dan tidak dikerjakan pada lab saat ini; external delivery belum
diimplementasikan.

## Project Objectives

- Menyediakan observability berbasis metrics untuk runtime Apache Tomcat dan
  JVM.
- Menyediakan dashboard untuk melihat kondisi, performa, dan historical metrics.
- Menghasilkan alert berdasarkan kondisi dan aturan yang dapat diukur.
- Meneruskan status firing dan resolved ke sistem eksternal.
- Menyediakan implementasi yang konsisten, dapat direproduksi, dan dapat
  diverifikasi.

## Scope

| Area | Scope |
| --- | --- |
| Runtime | Mendukung implementasi Apache Tomcat berbasis container sebagai application runtime yang dimonitor. |
| Metrics instrumentation | Mengambil metrics JVM dan Tomcat secara lokal dari dalam JVM tanpa mengaktifkan remote JMX. |
| Application health | Memeriksa HTTP health endpoint untuk mendeteksi aplikasi yang tidak merespons, mengalami timeout, atau berada dalam kondisi tidak sehat. |
| Metrics collection | Mengumpulkan dan menyimpan metrics runtime sebagai time-series untuk melihat kondisi saat ini maupun riwayat sebelumnya. |
| Visualization | Menampilkan current dan historical data mengenai kondisi serta performa runtime Tomcat dan JVM. |
| Alerting | Mengevaluasi kondisi JVM, aplikasi, dan monitoring signal, kemudian menghasilkan alert ketika terjadi gangguan serta resolved notification setelah kondisi kembali normal. |
| External integration | Meneruskan alert ke notification channel atau event management system. Lab memisahkan local email capture dari external delivery; integrasi TrueSight ditunda. |
| Security | Mengamankan komunikasi metrics menggunakan HTTPS dengan server-side TLS serta membatasi akses hanya dari sumber monitoring yang diizinkan. |
| Exclusion | Tidak mencakup Tomcat non-container, business metrics, distributed tracing, centralized log management, maupun jalur akses eksternal aplikasi. |

## Technology Stack

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Container Runtime | Rootless Podman | Menjalankan Tomcat dan monitoring containers |
| Application Runtime | Apache Tomcat | Menjalankan aplikasi yang dimonitor |
| Metrics Instrumentation | JMX Exporter Java Agent | Membaca JMX lokal dan menyediakan endpoint metrics melalui HTTPS |
| Metrics Collection | Prometheus | Mengumpulkan, menyimpan, dan mengevaluasi metrics |
| Application Health | Telegraf | Memeriksa HTTP health endpoint aplikasi dari container network yang sama |
| Visualization | Metrics Dashboard | Memvisualisasikan kondisi dan historical metrics |
| Alert Management | Alertmanager | Melakukan grouping, deduplication, dan routing alert |
| Notification Verification | Mailpit | Direct-upstream `v1.31.0` persistent lab utility; real Prometheus firing/resolved SMTP capture verified on 2026-08-28 |
| Operator CLI Tooling | [`tmctl`](references/tmctl-cli-reference.md) | Single static binary CLI berbasis Go untuk orkestrasi Socket API multi-OS (Linux & Windows) |
| Host Event Collector Daemon | [`tm-agent`](references/tm-agent-daemon-reference.md) | Single static binary daemon berbasis Go untuk socket event streaming dan atomic evidence spooling |
| External Integration | Integration Bridge | Mengonversi webhook untuk integrasi TrueSight |
| Event Management | TrueSight | Menjadi target desain masa depan dan tidak tersedia pada lab saat ini |
| Documentation | MkDocs | Menerbitkan dokumentasi project |

## Current Status

| Capability | Status |
| --- | --- |
| Monitoring architecture | Topology defined; persistent lab JMX and application health flow verified |
| Rootless Podman runtime | Available and verified on `devops-lab` |
| Tomcat container provisioning | Persistent JMX lab target runs the lab-only JSP health application; production application provisioning planned |
| Tomcat JMX Exporter source | Current source `231cb91` published to Gitea; source validation and local image build passed on 2026-08-25 |
| Tomcat monitoring instrumentation | Current-source image `localhost/tomcat-jmx-exporter:1.0.0` deployed with internal HTTPS metrics, lab health application, and no host-published application or metrics port |
| Prometheus container | Persistent lab runtime uses existing named volumes; controlled replacement retained TSDB continuity and enabled healthy `alertmanager:9093` delivery on 2026-08-28 |
| Telegraf container | Persistent lab runtime checks the Tomcat JSP health endpoint and is scraped by Prometheus through internal `telegraf:9273` |
| Container status monitoring | Metrics source not determined |
| Monitoring implementation | Persistent JMX and Telegraf targets `up=1`; persistent Prometheus, Alertmanager, and Mailpit captured real `TelegrafHealthScrapeUnavailable` firing/resolved email on 2026-08-28 |
| End-to-end verification | Completed untuk alur monitoring alert, diagnosis deterministik `TomcatDown` (TD-01..TD-09), hot-reloading rulepack, dan resolved recovery |
| Diagnostic MVP Pilot | Completed 100%. Diagnostic Service Node.js 24 ESM (`0.1.3`), SQLite persisten, Restricted Event Collector, Declarative Rulepack Engine, alur pengayaan AI, dan notifikasi Mailpit firing/resolved terverifikasi live di `devops-lab` |

## Diagnostic MVP Pilot

Fase Diagnostic MVP Pilot telah selesai dan terverifikasi secara penuh. Sistem
membuktikan alur otomatisasi diagnosis insiden deterministik berbasis bukti
terbatas tanpa tindakan remediasi otomatis:

```text
Prometheus (TomcatDown) -> Alertmanager -> Diagnostic Service
    -> SQLite diagnostic_data & evidence correlation
    -> Mailpit (7-Section SRE Report) -> Resolved Notification
```

Arsitektur sistem diperkuat oleh **5-Layer Knowledge Base and AI Enrichment Architecture**:
- **Layer 1 (Deterministic Core):** Evaluasi pohon keputusan built-in `TD-01` s/d `TD-08` dengan latensi nol dan kinerja deterministik tinggi.
- **Layer 2 (Local Rulepack Knowledge Base):** Evaluator aturan dinamis berbasis schema JSON (`rulepack-v1.schema.json`) dan tabel `custom_rules` pada SQLite.
- **Layer 3 (Ephemeral Spool & Audit Store):** Pengumpulan log/crash artifacts dan spool event host atomik melalui Restricted Event Collector (`/tmp/diagnostic-spool`).
- **Layer 4 (AI Post-Mortem & Rule Formulation):** Analisis forensik offline oleh LLM eksternal / SRE untuk memformulasikan rule deklaratif baru (`TD-09` — *DatabaseConnectionPoolExhausted*) saat insiden tidak terpetakan (`UNDETERMINED`).
- **Layer 5 (Safe Hot-Ingestion API Boundary):** Penambahan aturan baru secara instan melalui `POST /api/v1/rules` dengan 5-Layer Ingestion Guard (Auth, Schema, Collision, Size Limit, Safety) dan immutabilitas append-only (penolakan operasi mutasi 405 Method Not Allowed) tanpa memerlukan restart container.

Lihat [Diagnostic MVP](diagnostic-mvp/index.md) dan [Engineering Journal Diagnostic MVP Pilot](engineering-journal/diagnostic-mvp-pilot/index.md) untuk detail arsitektur, kontrak, dan histori verifikasi lengkap.

## Next Phase: Monitoring Platform Integration

Setelah fase pondasi dan pilot diagnostik terbukti 100%, pengembangan dilanjutkan
ke **Monitoring Platform Integration Phase** dengan fokus:
1. **Dashboard Observabilitas:** Menyediakan visualisasi metrik JVM dan Tomcat Connector berbasis Grafana/Prometheus.
2. **Standardisasi Log & Multi-Target:** Integrasi log terpusat dan perluasan target allowlist multi-instance.
3. **Otomatisasi CI/CD & Ansible:** Pipeline pengujian otomatis dan provisioning zero-touch.

Seluruh daftar tugas kelanjutan, termasuk mitigasi pemantauan mandiri (*health scrape*) Diagnostic Service (TM-ADR-0016), ketahanan mesin status SQLite (TM-ADR-0015), pencatatan audit tindakan operator (TM-ADR-0014), dan perluasan aturan diagnosis (TM-ADR-0017), didokumentasikan pada halaman [Follow-up Tasks](follow-up-tasks.md).

## Documentation Structure

| Section | Purpose |
| --- | --- |
| [Architecture](architecture/index.md) | Menjelaskan desain, aliran data, dan kontrol keamanan |
| [Diagnostic MVP](diagnostic-mvp/index.md) | Mendefinisikan pilot `TomcatDown`, evidence, state, security, dan notification contract |
| [Development](development/index.md) | Menjelaskan workflow pengembangan dan pengujian |
| [Infrastructure](infrastructure/index.md) | Mendefinisikan container, network, storage, dan certificate prerequisites |
| [CI/CD](ci-cd/index.md) | Menjelaskan pipeline build, test, dan deployment |
| [Operations](operations/index.md) | Menjelaskan coverage monitoring dan aktivitas operasional |
| [Follow-up Tasks](follow-up-tasks.md) | Memuat daftar tugas kelanjutan, backlog teknis, dan mitigasi arsitektur |
| [Troubleshooting](troubleshooting/index.md) | Menyediakan panduan diagnosis dan penyelesaian masalah |
| [FAQ](faq.md) | Menyajikan tanya jawab teknis, logika diagnosis multi-error, dan tata kelola AI |
| [Engineering Journal](engineering-journal/index.md) | Menyimpan histori perencanaan dan implementasi |
| [References](references/index.md) | Mengumpulkan repository, ADR, dan referensi eksternal |

## Documentation Model

```text
Engineering activity
        ↓
Engineering Journal ──→ Architecture Decision Records
        ↓
Review and consolidation
        ↓
Current-state project documentation
```

Engineering Journal mempertahankan konteks historis. Architecture,
Development, Infrastructure, CI/CD, Operations, dan Troubleshooting menjelaskan
kondisi serta prosedur yang berlaku saat ini.

## Success Criteria

- JMX Exporter membaca metrics dari JVM tanpa remote JMX.
- Prometheus mengambil metrics melalui HTTPS dan memverifikasi sertifikat
  JMX Exporter.
- Telegraf memeriksa HTTP health endpoint aplikasi dari container network yang
  sama dan menyediakan hasilnya kepada Prometheus.
- Dashboard menampilkan kondisi, performa, dan historical metrics Tomcat.
- Alert firing dan resolved diproses oleh Alertmanager.
- Alertmanager email dapat ditangkap dan diperiksa secara lokal tanpa
  credential atau external delivery melalui persistent lab-only Mailpit.
- Integrasi TrueSight melalui Integration Bridge dapat ditambahkan kemudian
  ketika environment target tersedia.
- Status scrape, container, dan endpoint HTTP dapat dibedakan setelah sumber
  container status metrics ditetapkan.
- Hilangnya HTTP health metrics dapat dibedakan dari hasil health check yang
  gagal.
- Implementasi dan hasil verifikasi dapat direproduksi dari source project.

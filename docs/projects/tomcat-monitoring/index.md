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
notification channel atau event management system tertentu. Pada implementasi
saat ini, alert diteruskan ke TrueSight melalui Alertmanager dan Integration
Bridge.

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
| External integration | Meneruskan alert ke notification channel atau event management system. Implementasi saat ini mendukung integrasi dengan TrueSight. |
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
| External Integration | Integration Bridge | Mengonversi webhook untuk integrasi TrueSight |
| Event Management | TrueSight | Menerima dan mengelola event pada implementasi saat ini |
| Documentation | MkDocs | Menerbitkan dokumentasi project |

## Current Status

| Capability | Status |
| --- | --- |
| Monitoring architecture | Topology defined; persistent lab JMX flow verified |
| Rootless Podman runtime | Available and verified |
| Tomcat container provisioning | Persistent JMX lab target runs the lab-only JSP health application; production application provisioning planned |
| Tomcat JMX Exporter source | Current source `231cb91` published to Gitea; source validation and local image build passed on 2026-08-25 |
| Tomcat monitoring instrumentation | Current-source image `localhost/tomcat-jmx-exporter:1.0.0` deployed with internal HTTPS metrics, lab health application, and no host-published application or metrics port |
| Prometheus container | Persistent lab runtime uses existing named volumes; dashboard and strict JMX TLS scrape verified on 2026-08-25 through `http://edkas-pc1:9090` |
| Telegraf container | Persistent lab runtime checks the Tomcat JSP health endpoint and is scraped by Prometheus through internal `telegraf:9273` |
| Container status monitoring | Metrics source not determined |
| Monitoring implementation | Persistent JMX and Telegraf targets `up=1`; JVM, Tomcat, and successful application-health metrics available; alerting and external integration pending |
| End-to-end verification | Not started |

## Documentation Structure

| Section | Purpose |
| --- | --- |
| [Architecture](architecture/index.md) | Menjelaskan desain, aliran data, dan kontrol keamanan |
| [Development](development/index.md) | Menjelaskan workflow pengembangan dan pengujian |
| [Infrastructure](infrastructure/index.md) | Mendefinisikan container, network, storage, dan certificate prerequisites |
| [CI/CD](ci-cd/index.md) | Menjelaskan pipeline build, test, dan deployment |
| [Operations](operations/index.md) | Menjelaskan coverage monitoring dan aktivitas operasional |
| [Troubleshooting](troubleshooting/index.md) | Menyediakan panduan diagnosis dan penyelesaian masalah |
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
- Alert dapat diteruskan ke TrueSight melalui Integration Bridge.
- Status scrape, container, dan endpoint HTTP dapat dibedakan setelah sumber
  container status metrics ditetapkan.
- Hilangnya HTTP health metrics dapat dibedakan dari hasil health check yang
  gagal.
- Implementasi dan hasil verifikasi dapat direproduksi dari source project.

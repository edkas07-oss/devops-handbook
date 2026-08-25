# Infrastructure

## Overview

Infrastructure menyediakan environment untuk menjalankan Tomcat Monitoring.
Tomcat, Prometheus, dan Telegraf dijalankan sebagai container terpisah. JMX
Exporter menjadi bagian dari JVM di dalam container Tomcat dan tidak
menggunakan remote JMX.

Provisioning host, network, storage, dan certificate berada di luar lifecycle
runtime aplikasi. Deployment harus memverifikasi prerequisites, tetapi tidak
boleh mengubah firewall atau menerbitkan certificate secara otomatis tanpa
proses infrastructure yang telah ditetapkan.

## Infrastructure Components

| Component | Purpose | Current State |
| --- | --- | --- |
| Gitea | Menyimpan source dan konfigurasi project | Available |
| Development workstation | Menjadi local development environment | Available |
| Rootless Podman `4.9.3` | Menjalankan Tomcat dan monitoring components | Available |
| Tomcat container | Menjalankan application runtime yang dimonitor | Planned |
| JMX Exporter Java Agent | Mengekspos JVM dan Tomcat metrics secara lokal | Available in local derived image; deployment planned |
| Reusable JMX Agent procedure | Menjelaskan pemasangan, TLS configuration, build, dan validation secara reusable | Required in root How-to; not yet published |
| Prometheus container | Mengumpulkan dan menyimpan time-series metrics | Persistent lab runtime verified; isolated JMX TLS scrape verified without persistent-state mutation |
| Telegraf container | Menjalankan local HTTP health check aplikasi | Configuration contract implemented locally; runtime planned |
| Persistent metrics storage | Mempertahankan historical metrics | Named volume `prometheus_data` available; retention, sizing, backup, and recovery not determined |
| Container network | Menghubungkan Prometheus dengan endpoint JMX Exporter | Alias `tomcat-jmx-exporter` verified on lab network `devops-lab`; persistent and end-to-end integration pending |
| TLS certificate and trust | Mengamankan scrape endpoint menggunakan server-side TLS | Temporary self-signed JMX CA trust and strict failure behavior verified; production certificate lifecycle not determined |
| Application health endpoint | Memberikan status aplikasi yang dapat diverifikasi Telegraf | Interface `/health` defined; implementation planned |
| Alertmanager | Mengelola dan meneruskan alert | Planned |
| Integration Bridge | Meneruskan alert ke TrueSight | Planned |

`Available` menunjukkan komponen telah tersedia pada kondisi project saat ini.
`Planned` menunjukkan komponen termasuk dalam desain tetapi belum
diimplementasikan. `Not determined` menunjukkan keputusan teknis masih harus
dibuat sebelum implementasi.

JMX Exporter Java Agent diperlakukan sebagai kebutuhan infrastructure tambahan
karena harus tersedia di dalam Tomcat image sebelum integrasi Prometheus
dilakukan. Halaman ini hanya menetapkan kebutuhan dan statusnya. Prosedur teknis
reusable harus tersedia pada [root How-to](../../../how-to/index.md), sedangkan
nilai khusus project tetap berada pada source repository dan deployment
configuration.

## Container Host Requirements

- Host menggunakan Linux dan menjalankan Podman dalam mode rootless.
- Tomcat, Prometheus, dan Telegraf dijalankan sebagai container terpisah.
- Container Tomcat dapat memuat JMX Exporter sebagai Java Agent ketika JVM
  dimulai.
- Prometheus dapat mengakses endpoint HTTPS JMX Exporter pada network path yang
  diizinkan.
- Telegraf dapat mengakses HTTP health endpoint aplikasi melalui container
  network yang sama dengan Tomcat.
- Telegraf mengakses internal Tomcat HTTP connector pada container port `8080`,
  bukan host-published port.
- Prometheus dapat mengambil health metrics yang dihasilkan Telegraf.
- Remote JMX tidak diaktifkan atau dipublikasikan dari container Tomcat.
- Persistent storage tersedia untuk mempertahankan historical metrics sesuai
  retention policy yang akan ditetapkan.
- Certificate dan trust material dapat dipasang ke container sebagai read-only
  secret.
- Host menyediakan kapasitas CPU, memory, dan storage yang memadai berdasarkan
  sizing yang belum ditetapkan.
- Firewall hanya mengizinkan port yang diperlukan oleh alur monitoring.

## Network Requirements

| Flow | Protocol | Security | Status |
| --- | --- | --- | --- |
| Prometheus to JMX Exporter | HTTPS ke port `9404`, path `/metrics` | Server-side TLS dan source restriction | Isolated Prometheus scrape, hostname verification, untrusted-CA failure, and recovery verified on 2026-08-25; persistent integration pending |
| Telegraf to application health endpoint | HTTP ke internal Tomcat port `8080`, path `/health` | Network isolation | Defined by topology; integration pending |
| Prometheus to Telegraf | HTTP ke port internal `9273`, path `/metrics` | Network restriction pending | Configuration contract implemented locally; not runtime-verified |
| Dashboard to Prometheus | HTTP ke host port `9090` pada lab | Trusted VPN lab; TLS dan authentication belum tersedia | Browser tablet verified through `http://edkas-pc1:9090` on 2026-08-24 |
| Prometheus to Alertmanager | Not determined | Not determined | Not determined |
| Alertmanager to Integration Bridge | Webhook; protocol not determined | Not determined | Designed, not verified |
| Integration Bridge to TrueSight | SNMP Trap atau `msend` | Not determined | Designed, not verified |

Hostname, container network, firewall rule, dan port komponen monitoring yang
belum disebutkan pada topology masih harus ditetapkan. JMX Exporter port `9404`,
metrics path `/metrics`, internal Tomcat port `8080`, dan health path `/health`
sudah menjadi bagian dari interface design.

## Application Health Check Requirements

- Telegraf dijalankan sebagai container terpisah dan berada pada container
  network yang sama dengan Tomcat.
- Plugin `inputs.http_response` digunakan untuk memeriksa health endpoint
  aplikasi.
- Health check memverifikasi expected HTTP status code dan response body, bukan
  hanya keberhasilan membuka koneksi TCP.
- Response timeout dan check interval harus ditetapkan berdasarkan kebutuhan
  operasional.
- Health endpoint harus membuktikan bahwa application context dapat memproses
  dan memberikan response.
- Hasil pemeriksaan harus tersedia sebagai metrics yang dapat dikumpulkan
  Prometheus.
- Prometheus harus menghasilkan alert ketika health check gagal dan ketika
  health metrics tidak lagi diterima.
- HTTP check hanya membuktikan kesehatan aplikasi dari container network lokal.
  Load balancer, reverse proxy, DNS, firewall eksternal, dan jalur akses pengguna
  berada di luar scope pemeriksaan ini.

Health path ditetapkan sebagai `/health` berdasarkan topology. Contract
sementara menggunakan HTTP `200`, body yang menyatakan status `UP`, timeout
`5s`, interval `30s`, dan Telegraf Prometheus client internal
`:9273/metrics`. Target URL diberikan melalui `TOMCAT_HEALTH_URL` saat runtime.
Nilai ini telah memiliki source contract dan static validation, tetapi belum
runtime-verified bersama Telegraf, Prometheus, atau application endpoint nyata.

## Storage Requirements

Prometheus memerlukan persistent storage agar historical metrics tidak hilang
ketika container dibuat ulang. Infrastructure harus menentukan:

- Storage type dan mount location;
- Retention period;
- Kapasitas awal dan batas pertumbuhan;
- Ownership dan permission;
- Backup requirement; serta
- Recovery procedure.

Lab runtime menggunakan named volume `prometheus_data` yang dipasang
read-write ke `/prometheus`. Permission data untuk runtime non-root telah
terverifikasi melalui startup TSDB. Configuration menggunakan
`prometheus_config` dan trust material menggunakan `prometheus_truststore`;
keduanya dipasang read-only tanpa host bind.

Default retention `15d` terlihat pada runtime log, tetapi belum diterima
sebagai project retention policy. Capacity, growth limit, backup, dan recovery
tetap berstatus `Not determined`.

## Certificate Requirements

- JMX Exporter menyajikan certificate untuk endpoint HTTPS.
- Prometheus memiliki CA certificate yang diperlukan untuk memverifikasi
  certificate JMX Exporter.
- JMX Exporter tidak meminta client certificate dari Prometheus.
- Private key tidak disimpan di dalam container image atau Git repository.
- Certificate dan private key dipasang ke container Tomcat sebagai read-only
  secret.
- Proses issuance, distribution, renewal, revocation, dan ownership certificate
  masih harus ditetapkan.

## Ownership Boundary

| Concern | Owner |
| --- | --- |
| Host packages, users, container runtime, dan firewall | Infrastructure owner; not determined |
| Container network dan persistent storage | Infrastructure owner; not determined |
| Certificate issuance, distribution, dan renewal | Infrastructure atau PKI process; not determined |
| Generic Tomcat image dan runtime configuration | Repository `tomcat` |
| JMX Exporter binary dan Java Agent startup contract | Repository `tomcat-jmx-exporter` |
| Reusable JMX Agent installation and validation procedure | Root How-to; not yet published |
| JMX Exporter configuration | Tomcat Monitoring project |
| Telegraf HTTP health check configuration | Tomcat Monitoring project |
| Prometheus scrape configuration dan alert rules | Tomcat Monitoring project |
| Dashboard dan Alertmanager configuration | Tomcat Monitoring project |
| Integration Bridge dan TrueSight mapping | Tomcat Monitoring project dan TrueSight owner |
| Runtime service continuity | Container runtime or service manager; not determined |

## Planned Provisioning Validation

Podman telah diverifikasi menggunakan temporary Tomcat container. Pada tahap
berikutnya, target runtime akan dibuat melalui CI/CD dan Ansible untuk
membuktikan bahwa environment dapat dibuat secara konsisten dan dapat
direproduksi.

Validation tersebut direncanakan mencakup:

- Provisioning Rootless Podman prerequisites;
- Pembuatan target Tomcat containers;
- Penerapan network dan published port;
- Pemasangan embedded monitoring instrumentation;
- Pemeriksaan idempotency Ansible;
- Verifikasi metrics dan local HTTP health check; serta
- Verifikasi hasil provisioning melalui pipeline CI/CD.

CI/CD dan Ansible provisioning belum diimplementasikan. Bagian ini mencatat
target validation, bukan hasil yang sudah dicapai.

## Pending Infrastructure Decisions

Keputusan berikut harus diselesaikan sebelum infrastructure dapat
diimplementasikan:

- Execution model untuk CI/CD dan Ansible provisioning;
- CI build dan image publication contract `tomcat-jmx-exporter`;
- Reusable JMX Exporter Java Agent procedure pada root How-to;
- Lokasi deployment selain persistent lab runtime Prometheus;
- Container network dan port allocation;
- Persistent storage dan retention policy;
- CPU, memory, dan storage sizing;
- Certificate authority dan certificate lifecycle;
- Sumber metrics untuk container status;
- Expected response, timeout, dan interval HTTP health check `/health`;
- Mekanisme scrape health metrics dari Telegraf;
- Ownership Integration Bridge dan koneksi TrueSight.

## Current Status

Rootless Podman telah tersedia dan diverifikasi pada development environment.
Derived image `localhost/tomcat-jmx-exporter:1.0.0` dengan JMX Exporter `1.6.0`
telah dibangun dari current source `231cb91` dan lulus local HTTPS/JVM smoke
test pada 2026-08-25. Container image masih lokal dan belum dipublikasikan ke
registry atau di-deploy ke target runtime.

Persistent lab container `prometheus` berjalan pada network `devops-lab`,
memublikasikan host port `9090`, dan menggunakan named volumes
`prometheus_config`, `prometheus_truststore`, serta `prometheus_data` tanpa host
bind. Semantic configuration, readiness, mount modes, dan akses dashboard dari
tablet melalui VPN telah diverifikasi pada 2026-08-24. System CA bundle pada
truststore hanya membuktikan runtime trust-file contract; JMX Exporter dan
Telegraf scrape belum diverifikasi. Alertmanager, production certificate,
serta provisioning melalui CI/CD dan Ansible belum diimplementasikan.

## Related Pages

- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [CI/CD](../ci-cd/index.md)
- [Operations](../operations/index.md)
- [Engineering Journal](../engineering-journal/index.md)

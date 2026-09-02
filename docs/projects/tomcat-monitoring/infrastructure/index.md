# Infrastructure

## Overview

Infrastructure menyediakan environment untuk menjalankan Tomcat Monitoring.
Tomcat, Prometheus, dan Telegraf dijalankan sebagai container terpisah. JMX
Exporter menjadi bagian dari JVM di dalam container Tomcat dan tidak
menggunakan remote JMX. Target Diagnostic MVP menambahkan satu Diagnostic
Service dan satu local state volume per host Tomcat serta restricted event
collector; component tersebut belum diimplementasikan pada runtime.

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
| Tomcat container | Menjalankan application runtime yang dimonitor | Persistent JMX lab target runs lab-only JSP health application; production application planned |
| JMX Exporter Java Agent | Mengekspos JVM dan Tomcat metrics secara lokal | Persistent lab target deployed and verified together with lab health application |
| Reusable JMX Agent procedure | Menjelaskan pemasangan, TLS configuration, build, dan validation secara reusable | Required in root How-to; not yet published |
| Prometheus container | Mengumpulkan dan menyimpan time-series metrics | Persistent lab runtime and strict JMX TLS scrape verified |
| Telegraf container | Menjalankan local HTTP health check aplikasi | Persistent lab runtime deployed and scraped successfully by Prometheus |
| Persistent metrics storage | Mempertahankan historical metrics | Named volume `prometheus_data` available; retention, sizing, backup, and recovery not determined |
| Container network | Menghubungkan Prometheus, Telegraf, dan Tomcat/JMX target | Persistent aliases `tomcat-jmx-exporter` and `telegraf` verified on `devops-lab` |
| TLS certificate and trust | Mengamankan scrape endpoint menggunakan server-side TLS | Persistent lab material installed and strict verification passed; production certificate lifecycle not determined |
| Application health endpoint | Memberikan status aplikasi yang dapat diverifikasi Telegraf | Lab-only JSP `/health` deployed and verified; production application endpoint planned |
| Alertmanager | Mengelola dan meneruskan alert | Persistent local image `1.0.0` runtime uses named configuration/data volumes; real Prometheus firing/resolved delivery verified |
| Mailpit SMTP capture | Menangkap email Alertmanager pada persistent lab-only topology | Direct-upstream `v1.31.0` runs without named volume; loopback API and real firing/resolved capture verified |
| Diagnostic Service | Menerima `TomcatDown`, mengelola state, mengumpulkan evidence terbatas, dan mengirim diagnostic notification | Source, digest-pinned `0.1.1` image, dan disposable HTTPS/SQLite/Mailpit/SIGTERM verification tersedia; persistent runtime belum tersedia |
| SQLite diagnostic state | Mempertahankan event, incident, deduplication, canonical result, dan delivery state | Named volume `diagnostic_data` diterima; database dan physical volume belum dibuat |
| Restricted Event Collector | Mengumpulkan event host dan container yang diizinkan tanpa memberi akses kontrol host kepada Diagnostic Service | Ownership diterima; repository dan host service belum dibuat |
| Normalized collector spool | Menyediakan record event terbatas melalui mount read-only ke Diagnostic Service | Contract diterima; format fisik, permission, retention, dan runtime belum diimplementasikan |
| Dedicated diagnostic network | Menghubungkan Alertmanager dan Diagnostic Service tanpa host-published service port | Contract diterima; network attachment belum diimplementasikan |
| Diagnostic TLS dan bearer material | Mengamankan webhook internal dari Alertmanager | Exact container paths and lab modes accepted; generation, rotation, and deployment pending |
| Integration Bridge | Meneruskan alert ke TrueSight | Deferred; TrueSight tidak tersedia pada lab |

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
- Satu Diagnostic Service direncanakan per host Tomcat dan hanya menangani
  target lokal yang tercantum pada allowlist.
- Diagnostic Service menggunakan satu worker, queue maksimum 50, timeout
  diagnostic 60 detik, memory limit 256 MiB, dan CPU limit 500 millicores.
- Diagnostic Service tidak memperoleh broad Podman socket, host namespace,
  arbitrary command, runtime-control, atau arbitrary-path access.
- Restricted Event Collector berjalan sebagai rootless host service terpisah
  dan hanya menulis record ternormalisasi yang telah diizinkan.

## Network Requirements

| Flow | Protocol | Security | Status |
| --- | --- | --- | --- |
| Prometheus to JMX Exporter | HTTPS ke port `9404`, path `/metrics` | Server-side TLS dan container-network-only access | Persistent strict TLS scrape and hostname verification passed on 2026-08-25; JMX metrics port is not published on the host |
| Telegraf to application health endpoint | HTTP ke internal Tomcat port `8080`, path `/health` | Container-network-only access; no host port | Persistent lab integration verified on 2026-08-25 |
| Prometheus to Telegraf | HTTP ke port internal `9273`, path `/metrics` | Container-network-only access; no host port | Persistent target `up=1` and successful health metrics verified on 2026-08-25 |
| Dashboard to Prometheus | HTTP ke host port `9090` pada lab | Trusted VPN lab; TLS dan authentication belum tersedia | Browser tablet verified through `http://edkas-pc1:9090` on 2026-08-24 |
| Prometheus to Alertmanager | HTTP ke internal `alertmanager:9093` pada `devops-lab` | Container-network-only access; no Alertmanager host port | Healthy active target and real application-health firing/resolved delivery verified on 2026-08-28 |
| Alertmanager to Mailpit | Internal `mailpit:1025` pada `devops-lab`; SMTP tidak dipublikasikan | Mailpit API/UI hanya `127.0.0.1:8025`; no external relay, credential, atau personal recipient | Persistent lab-only firing/resolved capture verified on 2026-08-28 |
| Alertmanager to Diagnostic Service | HTTPS ke `diagnostic-service:8443/api/v1/alerts/alertmanager` | Strict TLS, bearer authentication, dedicated internal network, CA dan token read-only dari non-Git storage; tanpa host port | Contract diterima; routing, certificate, token, dan runtime belum diimplementasikan |
| Diagnostic Service to Prometheus | Query metrics terbatas melalui Prometheus API | Target dan query berasal dari local allowlist; endpoint fisik dan trust contract belum ditetapkan | Direncanakan; belum diimplementasikan atau diverifikasi |
| Diagnostic Service to Mailpit | SMTP internal untuk diagnostic firing, update, failed/partial, dan resolved | Tidak menggunakan external relay atau personal recipient pada lab | Disposable firing/resolved delivery verified; persistent delivery belum diimplementasikan |
| Diagnostic Service to Integration Bridge | Canonical JSON projection | Tidak ada endpoint, credential, connection, retry, queue, atau worker ketika disabled | Disabled; activation memerlukan contract terpisah |
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
Nilai ini memiliki source contract dan static validation. Runtime lab
verification menggunakan application fixture dijelaskan berikutnya.

Persistent lab verification pada 2026-08-25 menggunakan exploded JSP fixture
yang diproses Tomcat. Endpoint menghasilkan HTTP `200` dan JSON
`{"status":"UP"}`; Telegraf menghasilkan status-code match `1`, string match
`1`, dan result code `0`; Prometheus menghasilkan target
`telegraf-health` `up=1`. Fixture ini bukan production application health
implementation.

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

Persistent JMX cutover pada 2026-08-25 mempertahankan volume yang sama. New
Prometheus menemukan healthy TSDB blocks, menyelesaikan WAL replay, dan mencapai
readiness tanpa restart. Hasil ini membuktikan continuity pada exact named-
volume boundary, bukan backup atau recovery policy.

Persistent Alertmanager menggunakan `alertmanager_config` read-only dan
`alertmanager_data` read-write. Controlled restart mempertahankan exact data
volume, persisted `nflog` dan `silences`, serta tidak menghasilkan duplicate
Mailpit message. Persistent Mailpit tidak memakai named volume; captured
message history boleh hilang pada replacement dan Technical Note menjadi
source evidence. Protected `prometheus_config_tn035_rollback` serta stopped
`prometheus-tn035-rollback` dipertahankan sampai stability acceptance dan
exact destructive cleanup authorization tersedia.

Default retention `15d` terlihat pada runtime log, tetapi belum diterima
sebagai project retention policy. Capacity, growth limit, backup, dan recovery
tetap berstatus `Not determined`.

Diagnostic Service menggunakan named volume `diagnostic_data` pada path
`/var/lib/tomcat-diagnostic/diagnostic.db`. SQLite menggunakan WAL mode dengan
satu logical writer, target ukuran 100 MiB, dan hard acceptance boundary 250
MiB. Initialization, migration, retention 30 hari untuk resolved data,
checkpoint, integrity check, capacity check, dan incremental vacuum berjalan
otomatis menurut accepted contract. Schema, migration, dan disposable database
lifecycle telah diimplementasikan; physical named volume, backup, recovery,
retention, dan capacity behavior belum diverifikasi. Disposable
multi-component verification menggunakan temporary bind directory dan tidak
mengubah persistent named-volume decision. Penghapusan volume atau database
tetap merupakan exact-target destructive action yang memerlukan authorization
terpisah.

## Certificate Requirements

- JMX Exporter menyajikan certificate untuk endpoint HTTPS.
- Prometheus memiliki CA certificate yang diperlukan untuk memverifikasi
  certificate JMX Exporter.
- JMX Exporter tidak meminta client certificate dari Prometheus.
- Private key tidak disimpan di dalam container image atau Git repository.
- Certificate dan private key dipasang ke container Tomcat sebagai read-only
  secret.
- Persistent lab menggunakan self-signed certificate dengan SAN
  `DNS:tomcat-jmx-exporter`, validity 365 hari, dan renewal trigger ketika
  remaining validity mencapai 30 hari.
- Material persistent lab disimpan di luar source repository pada
  `/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls`.
  Directory menggunakan mode `0700`; private key, password file, dan PKCS12
  menggunakan `0600`; public certificate menggunakan `0444`.
- Project owner memiliki lab lifecycle dan rootless Podman user memiliki
  filesystem material. Previous material dipertahankan sampai new target
  terbukti `up=1`; removal memerlukan exact-path inspection serta destructive
  authorization.
- Production issuance, distribution, renewal, revocation, dan ownership tetap
  harus ditetapkan secara terpisah.
- Webhook Diagnostic Service wajib menggunakan strict TLS dan bearer
  authentication pada dedicated internal network tanpa host-published port.
- Alertmanager memverifikasi CA Diagnostic Service. CA dan bearer token berasal
  dari non-Git storage serta dipasang read-only; nilai token dan authorization
  header tidak boleh masuk log, SQLite, image, atau repository.
- Container path, lab ownership, dan permission material TLS serta bearer token
  Diagnostic Service ditetapkan TN-011. Rotation, reload/replacement, dan
  production lifecycle tetap prerequisite sebelum webhook deployment.

## Ownership Boundary

| Concern | Owner |
| --- | --- |
| Host packages, users, container runtime, dan firewall | Infrastructure owner; not determined |
| Container network dan persistent storage | Infrastructure owner; not determined |
| Persistent lab self-signed certificate lifecycle | Project owner sebagai lab runtime owner; filesystem material dimiliki rootless Podman user |
| Production certificate issuance, distribution, dan renewal | Infrastructure atau PKI process; not determined |
| Generic Tomcat image dan runtime configuration | Repository `tomcat` |
| JMX Exporter binary dan Java Agent startup contract | Repository `tomcat-jmx-exporter` |
| Reusable JMX Agent installation and validation procedure | Root How-to; not yet published |
| JMX Exporter configuration | Tomcat Monitoring project |
| Lab-only Tomcat health application fixture | Tomcat Monitoring project |
| Telegraf HTTP health check configuration | Tomcat Monitoring project |
| Prometheus scrape configuration dan alert rules | Tomcat Monitoring project |
| Generic Alertmanager image dan runtime lifecycle | Repository `alertmanager` |
| Dashboard dan Alertmanager configuration | Tomcat Monitoring project |
| Mailpit persistent lab-only verification utility | Upstream owns image lifecycle; `tomcat-monitoring` owns immutable reference, persistent integration, verification, and exact cleanup |
| Diagnostic Service source, dependency lock, image lifecycle, migration, dan component test | Repository `tomcat-diagnostic-service` |
| Diagnostic target allowlist, routing, secret reference, deployment, integration validation, dan lab orchestration | Repository `tomcat-monitoring` |
| Restricted Event Collector source, packaging, lifecycle, dan component test | Repository `tomcat-diagnostic-event-collector`; repository belum dibuat |
| SQLite schema, migration, housekeeping, dan application-level data lifecycle | Repository `tomcat-diagnostic-service` |
| Physical diagnostic volume, network, TLS/token storage, dan host resource allocation | Integration/platform owner; lab paths and modes accepted, persistent resource creation pending |
| Integration Bridge dan TrueSight mapping | Tomcat Monitoring project dan TrueSight owner |
| Runtime service continuity | Project owner/operator; manual start and recovery accepted for persistent lab, automatic host-boot orchestration deferred |

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
- Production certificate authority dan certificate lifecycle;
- Sumber metrics untuk container status;
- External SMTP relay, provider identity, sender, authentication, TLS, secret
  lifecycle, dan recipient handling bila inbox delivery kembali diperlukan.
- Ownership Integration Bridge dan koneksi TrueSight ketika future target
  tersedia.
- Format target allowlist dan stable container generation source.
- Effective Tomcat log, rotation, JVM fatal artifact, dan read-only mount
  locations.
- Rootless collector permission matrix, spool bounds, dan cleanup behavior.
- Rotation, CA distribution, serta reload/replacement lifecycle TLS dan bearer
  secret Diagnostic Service; TN-011 telah menetapkan container path dan lab mode.
- Host CPU, memory, filesystem baseline, dan safe failure-injection procedure
  sebelum resource serta end-to-end acceptance.

## Current Status

Rootless Podman telah tersedia dan diverifikasi pada development environment.
Derived image `localhost/tomcat-jmx-exporter:1.0.0` dengan JMX Exporter `1.6.0`
telah dibangun dari current source `231cb91` dan lulus local HTTPS/JVM smoke
test pada 2026-08-25. Container image masih lokal dan belum dipublikasikan ke
registry; image tersebut digunakan oleh persistent generic JMX lab target pada
`devops-lab` tanpa host-published metrics port.

Persistent lab container `prometheus` berjalan pada network `devops-lab`,
memublikasikan host port `9090`, dan menggunakan named volumes
`prometheus_config`, `prometheus_truststore`, serta `prometheus_data` tanpa host
bind. Semantic configuration, readiness, mount modes, dan akses dashboard dari
tablet melalui VPN telah diverifikasi. Pada 2026-08-25, truststore diperbarui
dengan public self-signed certificate persistent target dan Prometheus
menghasilkan JMX `up=1`, `jvm_memory_heap_used_bytes`, serta `tomcat_server`
dengan `insecure_skip_verify: false`.

Persistent lab Tomcat target juga memuat read-only JSP health application pada
root context. Persistent Telegraf memeriksa
`http://tomcat-jmx-exporter:8080/health` dan menyediakan metrics pada internal
`:9273/metrics`; Prometheus scrape pool `telegraf-health` menghasilkan `up=1`.
Endpoint, metrics semantics, JMX continuity, no-host-port boundary, dan restart
persistence lulus pada 2026-08-25. Stopped original JMX container sempat
dipertahankan sebagai `tomcat-jmx-exporter-rollback`, lalu dihapus pada
2026-08-26 setelah exact-target inspection dan successful-cutover cleanup
authorization. Active replacement, image, bind files, dan TLS material tetap
tersedia; post-cleanup JMX dan Telegraf tetap `up=1` dengan application-health
result `0`. Production certificate serta provisioning melalui CI/CD dan
Ansible belum diimplementasikan. Alertmanager sekarang memiliki
accepted runtime ownership, lab integration contract, dan statically verified
generic runtime source. Local image `localhost/alertmanager:1.0.0` telah lulus
Alertmanager, `amtool`, serta non-root component smoke test. Non-secret routing
configuration dan Prometheus delivery reference lulus static serta semantic
validation. Pada 2026-08-28, persistent container memakai
`alertmanager_config` dan `alertmanager_data`; controlled restart kembali ready
tanpa duplicate notification. Replacement Prometheus melihat satu healthy
active Alertmanager dan real `TelegrafHealthScrapeUnavailable` menghasilkan
matching firing/resolved email. Actual Integration Bridge dan external
delivery belum dibuat atau diverifikasi.

Alert-template contract sekarang menetapkan operator severity
`normal`, `warning`, dan `critical`; positive resolved alert names; identical
body keys; serta green/orange/red visual mapping. Telegraf scrape unavailable
menjadi critical dan seluruh application-health rules menyediakan `service`
serta `check`. Disposable Alertmanager-Mailpit rendering dan Prometheus
config/rule tests untuk contract telah lulus. Contract telah dipromosikan ke
persistent Alertmanager dan Prometheus; controlled Telegraf cycle menghasilkan
critical `TelegrafHealthScrapeUnavailable` dan normal
`TelegrafHealthScrapeAvailable` sebagai message ketujuh dan kedelapan. Enam
earlier messages tetap merupakan rejected historical evidence.

Direct Gmail email sempat dipilih sebagai next lab notification path, kemudian
digantikan oleh Mailpit lokal pada 2026-08-27. Current lab implementation
menggunakan persistent Mailpit tanpa Google credential, personal recipient,
named volume, atau external delivery. Immutable Mailpit `v1.31.0` manifest
identity pada `linux/amd64` berjalan pada `devops-lab`; SMTP tetap internal di
`mailpit:1025` dan API/UI hanya dipublikasikan pada `127.0.0.1:8025`.
Synthetic isolated capture tetap menjadi regression evidence, sedangkan real
Prometheus firing/resolved capture lulus pada 2026-08-28.

Persistent lab self-signed certificate lifecycle telah ditetapkan pada
2026-08-25. Material aktif tersimpan pada accepted non-Git directory, dipasang
read-only ke JMX target, dan certificate berlaku sampai 2027-08-25 dengan
renewal trigger 30 hari sebelum expiry. Production certificate lifecycle tetap
`Not determined`.

Persistent lab saat ini bersifat operator-managed. Automatic restart dan
host-boot orchestration tidak diterapkan atau diverifikasi; operator melakukan
start dan recovery manual. Dashboard, container-status metrics, CI/CD/Ansible,
external delivery, production deployment, dan end-to-end verification tetap
menjadi pekerjaan future pada phase terpisah.

Untuk Diagnostic MVP, repository `tomcat-diagnostic-service` tersedia pada
commit `611a83d`; source, migration, secure startup, dan digest-pinned image
telah lulus source atau disposable verification. TN-011 menetapkan exact
runtime paths, lab permissions, immutable image consumption, artifact
ownership, dan disposable topology. Collector repository dan host service,
persistent SQLite volume, environment allowlist, routing, rebuilt application
image, evidence mounts, spool, deployment orchestration, serta end-to-end
verification belum tersedia. SMTP worker orchestration telah lulus source dan
ephemeral socket tests. Current persistent lab tetap
menggunakan alur Alertmanager langsung ke Mailpit.

## Related Pages

- [TM-ADR-0003 — Use Host-Managed Non-Git TLS Material for the Persistent Lab](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0003.md)
- [TM-ADR-0005 — Use Mailpit as the Persistent Lab Notification Verification Target](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md)
- [TM-ADR-0008 — Use a Restricted Host Event Collector with a Normalized Evidence Spool](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md)
- [TM-ADR-0009 — Use SQLite for Local Diagnostic State](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0009.md)
- [TM-ADR-0010 — Deploy One Bounded Diagnostic Service per Tomcat Host](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)
- [TM-ADR-0012 — Decouple TrueSight Through a Disabled Integration Bridge](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0012.md)
- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [CI/CD](../ci-cd/index.md)
- [Operations](../operations/index.md)
- [Engineering Journal](../engineering-journal/index.md)
- [Diagnostic MVP](../diagnostic-mvp/index.md)

# Development

## Overview

Bagian ini menjelaskan workflow pengembangan Tomcat Monitoring. Source project
dibagi antara generic Tomcat image, derived JMX Exporter image, monitoring
configuration, Diagnostic Service, dan restricted event collector sesuai
repository boundary. Setiap perubahan tetap dapat ditelusuri melalui Git tanpa
mencampur lifecycle artefak.

Pembagian repository mengikuti kebutuhan pada
[Deployment Topology](../architecture/index.md#deployment-topology). Repository
`tomcat` menyediakan runtime dasar, `tomcat-jmx-exporter` menyediakan komponen
instrumentasi, dan `tomcat-monitoring` akan mengintegrasikan Prometheus,
Telegraf, alerting, serta deployment automation. Repository
`tomcat-diagnostic-service` memiliki source aplikasi, dependency lock, image
lifecycle, migration, dan component test Diagnostic Service, sedangkan
repository collector terpisah direncanakan untuk host-runtime evidence.

Repository `tomcat-monitoring` telah dibuat di Gitea dan di-clone ke
development environment. Baseline layout, component configurations, dan static
validators tersedia; JMX Exporter baseline masih memerlukan runtime integration
verification.
Repository `tomcat-jmx-exporter` telah memiliki source yang dipublikasikan ke
Gitea. Current source `231cb91` telah lulus local image build dan HTTPS/JVM
smoke test pada 2026-08-25, sedangkan CI untuk image tersebut belum dibuat.

## Repository Responsibilities

Source project dibagi berdasarkan lifecycle dan tanggung jawab berikut:

| Repository | Responsibility | Status |
| --- | --- | --- |
| `tomcat` | Menyediakan generic Tomcat container image | Available |
| `tomcat-jmx-exporter` | Menyediakan derived Tomcat image dengan embedded JMX Exporter | Current source published and local component build verified |
| `alertmanager` | Menyediakan generic Alertmanager container image dan lifecycle runtime | Local image `1.0.0` built; Alertmanager, `amtool`, and non-root smoke test passed |
| `tomcat-monitoring` | Menyediakan configuration, automation, dashboard, alert, dan integration | Persistent Prometheus–Alertmanager–Mailpit–Diagnostic Service end-to-end delivery verified |
| `tomcat-diagnostic-service` | Memiliki source Diagnostic Service, dependency lock, image lifecycle, declarative rulepack engine, migration, dan component test | Available; image `0.1.3` (digest `sha256:e781b9fb1cdad484763ab17ec5c0c0004da3fd4775ba5d88eba651382099aae8`), 46 tests passed |
| `tomcat-diagnostic-event-collector` | Memiliki source, schema, packaging, dan component test restricted rootless host collector | Available; atomic `.tmp` -> `.json` spooling, 3 component tests passed |

Target allowlist diagnostic, integrasi Prometheus dan Alertmanager,
configuration deployment non-secret, serta end-to-end verification tetap
dimiliki `tomcat-monitoring`. Repository yang tersedia tidak memberikan
authorization otomatis untuk implementation.

Repository `tomcat-jmx-exporter` tidak menyimpan JMX Exporter JAR sebagai binary
di Git. Build mengambil versi `1.6.0` yang telah dipin dan memverifikasi
checksum pada host serta di dalam image build.

```text
tomcat-jmx-exporter/
├── CONFIG
├── Containerfile
├── PROJECT
├── README.md
├── VERSION
├── entrypoint.sh
├── examples/
│   └── jmx-exporter.yml
└── scripts/
    ├── build.sh
    ├── clean.sh
    ├── run.sh
    └── test.sh
```

## Repository State

| Item | Current State |
| --- | --- |
| Remote repository | [Gitea `tomcat-jmx-exporter`](http://edkas-pc1:3000/gitadm/tomcat-jmx-exporter) |
| Default development branch | `main` |
| Initial commit | `82175bb1047272fa2ba89f28b8de9d6d7608778d` |
| Latest published commit | `231cb915cc2e058abd1fa0377877b120a9d7e2be` |
| Working tree | Clean |
| Upstream tracking | Not configured on local branch |
| CI pipeline | Not implemented |
| Container image publication | Local image only; registry not determined |
| Diagnostic Service repository | Gitea `tomcat-diagnostic-service` tersedia (`main` / clean) |
| Diagnostic Service local state | Latest commit `9b2c98e`; 46 unit/integration tests passed; version `0.1.3` (digest `sha256:e781b9fb1cda`) |
| Restricted Event Collector repository | Gitea `tomcat-diagnostic-event-collector` tersedia (`main` / clean); commit `94b8723`; 3 component tests passed |

## Development Workflow

Workflow berikut menjadi target proses pengembangan dan belum
diimplementasikan secara end-to-end.

```text
Review architecture topology and repository boundary
        ↓
Prepare required source repository and development tools
        ↓
Implement or update one topology component
        ↓
Run configuration validation
        ↓
Run container-based local test
        ↓
Verify the component interface required by topology
        ↓
Commit and push to Gitea
        ↓
CI validates the project
```

## Local Development

Development dilakukan pada Linux workstation menggunakan Git dan Rootless
Podman. Repository lokal tersedia pada:

```text
/home/eddywiyatno/git/tomcat-monitoring
/home/eddywiyatno/git/tomcat-jmx-exporter
/home/eddywiyatno/git/tomcat-diagnostic-service
```

Repository `tomcat-diagnostic-service` memiliki current local commit `84c42c1`.
Source menambahkan exact-pinned Ajv, schema, forward migration, isolated
`node:sqlite` adapter, durable ingestion, deduplication, dan queue berkapasitas
50. Target registry, bounded evidence adapters, dan TD-01 sampai TD-08 engine
juga tersedia. Worker, canonical-result persistence, health/metrics model, dan
seven-section renderers kemudian lulus bersama seluruh regression suite: 22
tests pada 2026-08-31. HTTPS request dan SMTP delivery boundaries kemudian
lulus 25 regression serta 2 ephemeral socket tests. Versioned configuration,
mounted-file secret loading, migration-before-readiness startup, single worker
loop, Prometheus serialization, dan graceful shutdown kemudian lulus 31
regression serta 3 ephemeral component tests. TN-010 membangun dan
memverifikasi digest-pinned image; TN-011 menetapkan integration-owned runtime
configuration contract. TN-013 membangun `0.1.1` dan memverifikasi disposable
Mailpit/SQLite runtime. Persistent component runtime belum diterapkan atau
diverifikasi. Repository
`tomcat-diagnostic-event-collector` belum tersedia.

TN-010 mem-pin base `localhost/nodejs` ke OCI digest, membangun application
image `0.1.0` dan `latest`, serta memverifikasi non-root runtime, production
dependencies, mounted HTTPS configuration, SQLite migrations, dan SIGTERM.
Image tetap lokal; persistent runtime dan deployment belum dilakukan.

Runtime consumption menggunakan exact digest, configuration dan allowlist
non-secret milik `tomcat-monitoring`, serta certificate/token/SMTP credential
dari non-Git storage. TN-012 menghubungkan canonical result, renderer,
persisted attempts, bounded retry, dan SMTP adapter serta lulus source/socket
tests. TN-013 rebuild memuat perubahan tersebut dan lulus Mailpit
multi-component test; persistent route tetap menjadi pekerjaan terpisah.

Pada `tomcat-jmx-exporter`, current source tersedia pada branch `main` melalui
commit `231cb91` dan local `origin/main` menunjuk commit yang sama. Working tree
lokal bersih, tetapi branch lokal belum mencatat upstream tracking terhadap
`origin/main`. Podman `4.9.3` tersedia dalam mode rootless.

Build dan smoke test derived image dijalankan dari repository
`tomcat-jmx-exporter`:

```bash
./scripts/build.sh
./scripts/test.sh
```

Command tersebut menjadi interface development untuk JMX Exporter. Penjelasan
teknis reusable mengenai pemasangan dan validasi Java Agent harus ditempatkan
pada [root How-to](../../../how-to/index.md). Selama How-to khusus JMX Exporter
belum diterbitkan, README dan scripts pada repository `tomcat-jmx-exporter`
menjadi referensi implementasi sementara.

Current source `231cb91` dibangun menjadi image lokal
`localhost/tomcat-jmx-exporter:1.0.0` pada 2026-08-25. Self-cleaning component
test memverifikasi HTTPS `/metrics`, JMX scrape duration, dan JVM heap metric.
Hasil local component tersebut belum membuktikan registry publication atau
deployment. Isolated Prometheus integration pada 2026-08-25 kemudian
memverifikasi strict TLS scrape, failure dengan untrusted CA, dan recovery.
Runtime menghasilkan Tomcat series `tomcat_server`, bukan nama konfigurasi
awal `tomcat_server_info`. Source contract kemudian direkonsiliasi untuk
menggunakan canonical runtime name `tomcat_server`.

## Configuration Development

- Pisahkan konfigurasi berdasarkan tanggung jawab komponen.
- Gunakan placeholder atau environment variable untuk nilai antar-environment.
- Jangan menyimpan password, private key, token, atau credential di repository.
- Validasi syntax dan behavior konfigurasi sebelum perubahan di-commit.
- Simpan source, dependency, migration, image lifecycle, dan component test
  Diagnostic Service pada repository `tomcat-diagnostic-service`; simpan target
  allowlist, routing, secret reference, deployment, dan integration validation
  pada `tomcat-monitoring`.
- Perbarui dokumentasi current-state ketika implementasi mengubah kondisi
  project.

## Source Control Workflow

- Gunakan setiap repository Gitea sebagai source of truth untuk artefak yang
  menjadi tanggung jawabnya.
- Buat perubahan dari working tree lokal dan tinjau diff sebelum commit.
- Gunakan commit yang menjelaskan satu perubahan engineering secara jelas.
- Jangan memasukkan generated data, runtime state, certificate, atau secret ke
  dalam commit.
- Gunakan hasil CI sebagai bukti validasi setelah pipeline tersedia.

## Related Pages

- [TM-ADR-0002 — Separate Generic Runtime Images from Monitoring Integration Configuration](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md)
- [TM-ADR-0010 — Deploy One Bounded Diagnostic Service per Tomcat Host](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)
- [TM-ADR-0013 — Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md)
- [Diagnostic MVP](../diagnostic-mvp/index.md)
- [Development Environment Setup](setup.md)
- [Architecture](../architecture/index.md)
- [Infrastructure](../infrastructure/index.md)
- [CI/CD](../ci-cd/index.md)
- [Engineering Journal](../engineering-journal/index.md)

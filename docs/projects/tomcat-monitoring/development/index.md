# Development

## Overview

Bagian ini menjelaskan workflow pengembangan Tomcat Monitoring. Source project
dibagi antara generic Tomcat image, derived JMX Exporter image, dan monitoring
configuration sesuai repository boundary. Setiap perubahan tetap dapat
ditelusuri melalui Git tanpa mencampur lifecycle artefak.

Pembagian repository mengikuti kebutuhan pada
[Deployment Topology](../architecture/index.md#deployment-topology). Repository
`tomcat` menyediakan runtime dasar, `tomcat-jmx-exporter` menyediakan komponen
instrumentasi, dan `tomcat-monitoring` akan mengintegrasikan Prometheus,
Telegraf, alerting, serta deployment automation.

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
| `tomcat-monitoring` | Menyediakan configuration, automation, dashboard, alert, dan integration | Persistent Prometheus–Alertmanager–Mailpit firing/resolved delivery verified; external delivery pending |
| `tomcat-diagnostic-service` | Future Diagnostic Service source, image lifecycle, migrations, and component tests | Ownership accepted; repository not created |
| `tomcat-diagnostic-event-collector` | Future rootless host collector source, packaging, and component tests | Ownership accepted; repository not created |

Diagnostic target allowlist, Prometheus and Alertmanager integration,
non-secret deployment configuration, and end-to-end verification remain owned
by `tomcat-monitoring`. Repository creation and implementation require a
separate approved plan.

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
```

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
- [Development Environment Setup](setup.md)
- [Architecture](../architecture/index.md)
- [Infrastructure](../infrastructure/index.md)
- [CI/CD](../ci-cd/index.md)
- [Engineering Journal](../engineering-journal/index.md)

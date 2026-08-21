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
development environment, tetapi belum memiliki commit atau struktur source.
Repository `tomcat-jmx-exporter` telah memiliki initial commit dan source-nya
telah dipublikasikan ke Gitea. Local derived image dari source revision awal
telah lulus smoke test, sedangkan CI untuk image tersebut belum dibuat.
Self-documentation bahasa Indonesia telah di-commit sebagai `d392717` dan
dipublikasikan ke branch `origin/main`; clean image build dari current commit
belum diverifikasi.

## Repository Responsibilities

Source project dibagi berdasarkan lifecycle dan tanggung jawab berikut:

| Repository | Responsibility | Status |
| --- | --- | --- |
| `tomcat` | Menyediakan generic Tomcat container image | Available |
| `tomcat-jmx-exporter` | Menyediakan derived Tomcat image dengan embedded JMX Exporter | Source and Indonesian self-documentation published |
| `tomcat-monitoring` | Menyediakan configuration, automation, dashboard, alert, dan integration | Initialized |

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
| Latest published commit | `d39271715e20f527b45752831cd6e5e901743b53` |
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

Pada `tomcat-monitoring`, working tree masih kosong dan branch `main` belum
memiliki commit. Pada `tomcat-jmx-exporter`, source awal tersedia pada branch
`main` melalui commit `82175bb`. Self-documentation bahasa Indonesia telah
dipublikasikan melalui commit `d392717`, dan `origin/main` menunjuk commit yang
sama. Working tree lokal bersih, tetapi branch lokal belum mencatat upstream
tracking terhadap `origin/main`. Podman `4.9.3` tersedia dalam mode rootless.

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

Local image yang telah lulus smoke test dibangun sebelum commit `d392717`.
Karena itu, current source publication dan local image verification dicatat
sebagai hasil berbeda sampai clean build serta smoke test current source
dijalankan.

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

- [Development Environment Setup](setup.md)
- [Architecture](../architecture/index.md)
- [Infrastructure](../infrastructure/index.md)
- [CI/CD](../ci-cd/index.md)
- [Engineering Journal](../engineering-journal/index.md)

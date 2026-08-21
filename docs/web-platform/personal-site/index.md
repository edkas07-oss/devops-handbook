# Personal Site

## Overview

Personal Site adalah project website yang ditujukan untuk menampilkan profil
profesional, Curriculum Vitae, portofolio, serta artikel mengenai teknologi
informasi dan manajemen.

Project ini dibangun sebagai static site menggunakan Hugo dan di-host
menggunakan NGINX container. Pendekatan ini menghasilkan website yang cepat,
ringan, mudah dipelihara, serta dapat dibangun dan di-deploy secara konsisten.

## Project Objectives

- Menyediakan sumber informasi utama mengenai profil profesional pemilik situs.
- Mempublikasikan artikel IT, infrastructure, DevOps, dan manajemen.
- Menampilkan pengalaman, kompetensi, dan portofolio secara terstruktur.
- Menyediakan website statis yang cepat, ringan, dan mudah dipelihara.
- Menerapkan software delivery lifecycle yang dapat direproduksi.

## Scope

| Area | Scope |
| --- | --- |
| Content | Menampilkan profil profesional, Curriculum Vitae, portofolio, serta artikel mengenai teknologi informasi dan manajemen. |
| Audience | Menyediakan informasi profesional yang dapat diakses oleh pembaca publik melalui website. |
| Website delivery | Menghasilkan static website yang cepat, ringan, dan mudah dipelihara. |
| Publishing | Mendukung proses build dan deployment otomatis agar perubahan konten dapat dipublikasikan secara konsisten dan dapat direproduksi. |
| Runtime | Menjalankan website menggunakan container-based web runtime untuk melayani konten statis. |
| Exclusion | Tidak mencakup authentication, user-generated content, transactional feature, database application, maupun dynamic backend service. |

## Technology Stack

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Static Site Generator | Hugo Extended | Menghasilkan HTML dan static assets |
| Source Control | Git dan Gitea | Menyimpan source code dan pipeline definition |
| Automation | Jenkins | Menjalankan pipeline CI dan CD |
| Container Runtime | Rootless Podman | Menjalankan build tools dan web runtime |
| Artifact Storage | MinIO | Menyimpan immutable CI artifact |
| Web Server | NGINX | Melayani HTTP request untuk konten statis |
| Documentation | MkDocs | Menerbitkan dokumentasi engineering project |

## Current Status

| Capability | Status |
| --- | --- |
| Hugo development workflow | Implemented |
| Continuous Integration | Implemented and verified |
| Artifact publication to MinIO | Implemented and verified |
| Continuous Deployment | Implemented and verified |
| NGINX runtime on Podman | Running |
| HTTP endpoint | Accessible and verified |
| Infrastructure provisioning with Ansible | Planned |

## Documentation Structure

| Section | Purpose |
| --- | --- |
| [Architecture](architecture/index.md) | Menjelaskan desain dan hubungan antarkomponen |
| [Development](development/index.md) | Menjelaskan workflow pengembangan Hugo |
| [Infrastructure](infrastructure/index.md) | Mendefinisikan platform dan runtime prerequisites |
| [CI/CD](ci-cd/index.md) | Menjelaskan pipeline yang berlaku saat ini |
| [Operations](operations/index.md) | Menjelaskan aktivitas operasional runtime |
| [Troubleshooting](troubleshooting/index.md) | Menyediakan panduan diagnosis dan penyelesaian masalah |
| [Engineering Journal](engineering-journal/index.md) | Menyimpan histori perencanaan dan implementasi |
| [References](references/index.md) | Mengumpulkan ADR, repository, dan referensi terkait |

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

Engineering Journal mempertahankan konteks historis. Halaman Architecture,
Development, Infrastructure, CI/CD, Operations, dan Troubleshooting menjelaskan
kondisi serta prosedur yang berlaku saat ini.

## Success Criteria

- Source Hugo dapat dikembangkan dan diuji secara lokal.
- CI menghasilkan `public/index.html` dan artifact yang dapat ditelusuri.
- Artifact tersimpan pada MinIO dan tidak dibangun ulang saat CD.
- CD mengisi `www-personal-site` dan menjalankan `personal-site-web`.
- NGINX mengakses konten statis melalui read-only volume mount.
- Healthcheck container dan HTTP endpoint memberikan hasil sukses.

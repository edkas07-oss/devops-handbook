# Infrastructure

## Overview

Infrastructure menyediakan environment yang dibutuhkan pipeline dan runtime
Personal Site. Provisioning host berada di luar lifecycle release aplikasi:
Jenkins memverifikasi prerequisites, tetapi tidak menginstal Podman atau membuka
firewall pada setiap deployment.

## Infrastructure Components

| Component | Purpose | Current State |
| --- | --- | --- |
| Gitea | Source control | Available |
| Jenkins Controller | Pipeline orchestration | Available |
| Jenkins agent `builder-01` | CI/CD execution host | Available |
| Rootless Podman | Container runtime | Available |
| MinIO | Artifact storage | Available |
| NGINX image | Generic web runtime | `localhost/nginx-image:1.0` |
| Podman network | Runtime connectivity | `web` |
| Podman volume | Active website content | `www-personal-site` |

## Deployment Host Requirements

- Jenkins agent berjalan sebagai user non-root pemilik rootless Podman storage.
- User memiliki konfigurasi subordinate UID/GID yang sesuai.
- Podman dapat menjalankan container tanpa privilege escalation.
- Image `localhost/nginx-image:1.0` tersedia pada local image storage user.
- Network `web` tersedia.
- Agent dapat mengakses MinIO melalui
  `http://host.containers.internal:9000`.
- Port host `8091`, `8443`, dan `2224` tidak digunakan service lain.
- Firewall mengizinkan port yang memang akan dipublikasikan.

## Ownership Boundary

| Concern | Owner |
| --- | --- |
| Host packages, users, SSH, subuid/subgid | Infrastructure automation |
| Podman installation, network, and firewall | Infrastructure automation |
| Jenkins agent service | Infrastructure automation |
| Application artifact build | Jenkins CI |
| Artifact selection and volume update | Jenkins CD |
| Container health and HTTP validation | Jenkins CD |
| Runtime service continuity | Podman/systemd; planned improvement |

## Planned Ansible Phase

Ansible akan digunakan pada fase berikutnya untuk membuat kondisi host dapat
direproduksi. Scope awal yang direncanakan:

- menyiapkan user dan rootless Podman;
- memasang Java dan Jenkins agent prerequisites;
- memastikan network `web` dan volume `www-personal-site` tersedia;
- mengelola firewall;
- menyiapkan systemd user service atau Podman Quadlet; dan
- menjalankan infrastructure preflight validation.

Implementasi Ansible belum dimulai. Catatan ini mendefinisikan boundary agar
provisioning infrastructure tidak bercampur dengan release pipeline.

## Related Pages

- [Architecture](../architecture/index.md)
- [CI/CD](../ci-cd/index.md)
- [Operations](../operations/index.md)

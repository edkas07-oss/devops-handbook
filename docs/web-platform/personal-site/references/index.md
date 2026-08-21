# References

## Overview

Halaman ini mengumpulkan repository, Architecture Decision Record, internal
documentation, dan dokumentasi vendor yang menjadi referensi Personal Site.

## Project Repositories

| Repository | Purpose |
| --- | --- |
| `personal-site` | Hugo source, content, Jenkins pipelines, dan deployment configuration |
| `nginx-image` | Generic NGINX runtime image |
| `devops-handbook` | Project documentation dan engineering journal |
| `nginx-automation` | Infrastructure automation; integrasi Personal Site masih direncanakan |

## Architecture Decision Records

ADR tetap dikelola pada koleksi root karena mekanisme tersebut juga dapat
digunakan oleh project lain. Personal Site memakai prefix `PS-ADR`.

- [Personal Site ADR Catalog](../../../adr/personal-site/index.md)
- [PS-ADR-0007 — Use Pipeline as Code](../../../adr/personal-site/adr-records/PS-ADR-0007.md)
- [PS-ADR-0008 — Adopt Stage-Based CI Pipeline](../../../adr/personal-site/adr-records/PS-ADR-0008.md)
- [PS-ADR-0009 — Use Containerized Pipeline Environment](../../../adr/personal-site/adr-records/PS-ADR-0009.md)
- [PS-ADR-0011 — Deploy Immutable CI Artifact](../../../adr/personal-site/adr-records/PS-ADR-0011.md)
- [PS-ADR-0012 — Store Static Content in Podman Named Volume](../../../adr/personal-site/adr-records/PS-ADR-0012.md)
- [PS-ADR-0013 — Execute Deployment through Dedicated Jenkins Agent](../../../adr/personal-site/adr-records/PS-ADR-0013.md)
- [PS-ADR-0014 — Keep Application Deployment Configuration Outside Generic Runtime Image](../../../adr/personal-site/adr-records/PS-ADR-0014.md)

## Internal Documentation

- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [CI/CD](../ci-cd/index.md)
- [Operations](../operations/index.md)
- [Troubleshooting](../troubleshooting/index.md)
- [Engineering Journal](../engineering-journal/index.md)

## Vendor Documentation

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Podman Documentation](https://docs.podman.io/)
- [MinIO Documentation](https://min.io/docs/)
- [NGINX Documentation](https://nginx.org/en/docs/)

External documentation is used for product behavior and command reference.
Project-specific decisions and tested procedures remain documented in this
handbook.

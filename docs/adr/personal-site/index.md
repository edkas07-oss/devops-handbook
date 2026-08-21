---
title: Personal Site Architecture Decision Records
---

## 🔍 Overview

Halaman ini berisi seluruh **Architecture Decision Records (ADR)** yang digunakan pada project **Personal Site**.

Setiap ADR mendokumentasikan keputusan arsitektur yang memengaruhi desain, implementasi, deployment, maupun pengembangan Personal Site.

Dokumentasi ini berfungsi sebagai pusat referensi untuk memahami alasan di balik setiap keputusan arsitektur yang diterapkan pada project Personal Site.

---

## 📚 Architecture Decision Catalog

| ADR ID | Title | Project | Section | Status | Date |
| ------ | ----- | ------- | ------- | ------ | ---- |
| [**PS-ADR-0001**](adr-records/PS-ADR-0001.md){: target="_blank" } | Use Jenkins as Automation Server | Personal Site | CI/CD | Accepted | 2026-08-06 |
| [**PS-ADR-0002**](adr-records/PS-ADR-0002.md){: target="_blank" } | Containerized Ephemeral Build Environment (DooD with Rootless Podman) | Personal Site | Infrastructure & CI/CD Pipeline | Accepted | 2026-08-01 |
| [**PS-ADR-0003**](adr-records/PS-ADR-0003.md){: target="_blank" } | Externalized Static Content Storage | Personal Site | Architecture | Accepted | 2026-07-21 |
| [**PS-ADR-0004**](adr-records/PS-ADR-0004.md){: target="_blank" } | Generic Runtime Container | Personal Site | Architecture | Accepted | 2026-07-21 |
| [**PS-ADR-0005**](adr-records/PS-ADR-0005.md){: target="_blank" } | Separate Source Code and Deployment Artifacts | Personal Site | Repository Structure | Accepted | 2026-07-21 |
| [**PS-ADR-0006**](adr-records/PS-ADR-0006.md){: target="_blank" } | Use Personal Access Token for Gitea Repository | Personal Site | Security | Accepted | 2026-08-01 |
| [**PS-ADR-0007**](adr-records/PS-ADR-0007.md){: target="_blank" } | Use Pipeline as Code | Personal Site | Automation | Accepted | 2026-07-29 |
| [**PS-ADR-0008**](adr-records/PS-ADR-0008.md){: target="_blank" } | Adopt Stage-Based CI Pipeline | Personal Site | CI/CD | Accepted | 2026-08-04 |
| [**PS-ADR-0009**](adr-records/PS-ADR-0009.md){: target="_blank" } | Use Containerized Pipeline Environment | Personal Site | CI/CD | Accepted | 2026-08-04 |
| [**PS-ADR-0010**](adr-records/PS-ADR-0010.md){: target="_blank" } | Use Object Storage for Build Artifact | Personal Site | CI/CD | Superseded by PS-ADR-0003 | 2026-08-04 |
| [**PS-ADR-0011**](adr-records/PS-ADR-0011.md){: target="_blank" } | Deploy Immutable CI Artifact | Personal Site | Continuous Deployment | Accepted | 2026-08-08 |
| [**PS-ADR-0012**](adr-records/PS-ADR-0012.md){: target="_blank" } | Store Static Content in Podman Named Volume | Personal Site | Continuous Deployment | Accepted | 2026-08-08 |
| [**PS-ADR-0013**](adr-records/PS-ADR-0013.md){: target="_blank" } | Execute Deployment through Dedicated Jenkins Agent | Personal Site | Continuous Deployment | Accepted | 2026-08-08 |
| [**PS-ADR-0014**](adr-records/PS-ADR-0014.md){: target="_blank" } | Keep Application Deployment Configuration Outside Generic Runtime Image | Personal Site | Continuous Deployment | Accepted | 2026-08-08 |

---

## � ADR Mapping

Tabel berikut memetakan setiap ADR Project Personal Site dengan dokumen teknis atau worklog yang merujuk keputusan tersebut.

| ADR ID | Title | Referenced In |
| ------ | ----- | ------------- |
| PS-ADR-0001 | Use Jenkins as Automation Server | TN-001, TN-003 |
| PS-ADR-0002 | Containerized Ephemeral Build Environment (DooD with Rootless Podman) | TN-002 |
| PS-ADR-0003 | Externalized Static Content Storage | TN-004 |
| PS-ADR-0004 | Generic Runtime Container | Belum dirujuk secara eksplisit |
| PS-ADR-0005 | Separate Source Code and Deployment Artifacts | TN-004 |
| PS-ADR-0006 | Use Personal Access Token for Gitea Repository | TN-003 |
| PS-ADR-0007 | Use Pipeline as Code | TN-005, TN-006 |
| PS-ADR-0008 | Adopt Stage-Based CI Pipeline | Worklog WK-001 Build Pipeline |
| PS-ADR-0009 | Use Containerized Pipeline Environment | TN-003, TN-004 |
| PS-ADR-0010 | Use Object Storage for Build Artifact | Superseded by PS-ADR-0003 |
| PS-ADR-0011 | Deploy Immutable CI Artifact | Continuous Deployment TN-001 |
| PS-ADR-0012 | Store Static Content in Podman Named Volume | Continuous Deployment TN-001 |
| PS-ADR-0013 | Execute Deployment through Dedicated Jenkins Agent | Continuous Deployment TN-001, TN-002 |
| PS-ADR-0014 | Keep Application Deployment Configuration Outside Generic Runtime Image | Continuous Deployment TN-002, TN-003 |

---

## �📝 Summary

Pada halaman ini telah dijelaskan:

- Daftar seluruh Architecture Decision Record (ADR) yang digunakan pada project Personal Site.
- Informasi ringkas mengenai setiap keputusan arsitektur.
- Hubungan antara setiap ADR dengan bagian dokumentasi project yang terkait.

Klik **ADR ID** pada tabel di atas untuk melihat pembahasan lengkap mengenai konteks, keputusan, alasan pemilihan solusi, serta konsekuensi dari masing-masing Architecture Decision Record.

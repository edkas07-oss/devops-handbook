---
title: Apache Tomcat Enterprise Architecture Decision Records
---

## 🔍 Overview

Halaman ini berisi Architecture Decision Records (ADR) untuk project **Apache Tomcat Enterprise**. Setiap ADR mendokumentasikan konteks masalah, alternatif yang dievaluasi, keputusan arsitektur yang diambil, serta konsekuensi teknis dan operasional yang dihasilkan.

## 📚 Architecture Decision Catalog

| ADR ID | Title | Project | Section | Status | Date |
| --- | --- | --- | --- | --- | --- |
| [**TC-ADR-0001**](adr-records/TC-ADR-0001.md){: target="_blank" } | Adopt Greenfield Hardened OCI Container Architecture for Apache Tomcat | Apache Tomcat Enterprise | Architecture | Accepted | 2026-09-21 |
| [**TC-ADR-0002**](adr-records/TC-ADR-0002.md){: target="_blank" } | Enforce Pre-Flight Static XML Configuration Audit and CIS Tomcat Benchmark | Apache Tomcat Enterprise | Security Architecture | Accepted | 2026-09-21 |
| [**TC-ADR-0003**](adr-records/TC-ADR-0003.md){: target="_blank" } | Decouple Configuration State Using Engine Runtime Named Volumes with Read-Only Mounts | Apache Tomcat Enterprise | Storage and Container Architecture | Accepted | 2026-09-21 |
| [**TC-ADR-0004**](adr-records/TC-ADR-0004.md){: target="_blank" } | Consolidate Multi-Platform Lifecycle and Hardening Governance into Unified Go Operator (tcctl) | Apache Tomcat Enterprise | Tooling and Automation Architecture | Accepted | 2026-09-21 |
| [**TC-ADR-0005**](adr-records/TC-ADR-0005.md){: target="_blank" } | Adopt Native OpenSSL PEM Connector and Automated TLS Lifecycle Governance via tcctl | Apache Tomcat Enterprise | Security and TLS Architecture | Accepted | 2026-09-21 |
| [**TC-ADR-0006**](adr-records/TC-ADR-0006.md){: target="_blank" } | Refactor Zero-Downtime Rollout to Temporary Staging Containers with Canonical Name Promotion | Apache Tomcat Enterprise | Deployment and Rollout Architecture | Accepted | 2026-09-22 |
| [**TC-ADR-0007**](adr-records/TC-ADR-0007.md){: target="_blank" } | Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler and Day-1/Day-2 Decoupling | Apache Tomcat Enterprise | GitOps and Continuous Deployment | Accepted | 2026-09-22 |
| [**TC-ADR-0008**](adr-records/TC-ADR-0008.md){: target="_blank" } | Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access | Apache Tomcat Enterprise | Infrastructure Security and Provisioning | Accepted | 2026-09-22 |
| [**TC-ADR-0009**](adr-records/TC-ADR-0009.md){: target="_blank" } | Enterprise Drive Separation and Transparent Host Bind-Mount Hierarchy for Multi-Instance Tomcat Containers | Apache Tomcat Enterprise | Storage and Runtime Architecture | Accepted | 2026-09-23 |

## 🗺️ ADR Mapping

| ADR ID | Title | Referenced In |
| --- | --- | --- |
| **TC-ADR-0001** | Adopt Greenfield Hardened OCI Container Architecture for Apache Tomcat | Platform Foundation TN-001, [Tomcat Architecture](../../projects/tomcat/architecture/index.md), [Security Hardening](../../projects/tomcat/security-hardening/index.md) |
| **TC-ADR-0002** | Enforce Pre-Flight Static XML Configuration Audit and CIS Tomcat Benchmark | Platform Foundation TN-001, TN-002, [Security Hardening](../../projects/tomcat/security-hardening/index.md), [Vulnerability Assessment](../../projects/tomcat/vulnerability-assessment/index.md) |
| **TC-ADR-0003** | Decouple Configuration State Using Engine Runtime Named Volumes with Read-Only Mounts | Platform Foundation TN-002, [Tomcat Architecture](../../projects/tomcat/architecture/index.md), [Update Management](../../projects/tomcat/update-management/index.md) |
| **TC-ADR-0004** | Consolidate Multi-Platform Lifecycle and Hardening Governance into Unified Go Operator (tcctl) | Platform Foundation TN-002, [Update Management](../../projects/tomcat/update-management/index.md), [Vulnerability Assessment](../../projects/tomcat/vulnerability-assessment/index.md) |
| **TC-ADR-0005** | Adopt Native OpenSSL PEM Connector and Automated TLS Lifecycle Governance via tcctl | Platform Foundation TN-003, [SSL Management](../../projects/tomcat/ssl-management/index.md) |
| **TC-ADR-0006** | Refactor Zero-Downtime Rollout to Temporary Staging Containers with Canonical Name Promotion | Platform Foundation TN-004, [Update Management](../../projects/tomcat/update-management/index.md) |
| **TC-ADR-0007** | Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler and Day-1/Day-2 Decoupling | Platform Foundation TN-004, [Update Management](../../projects/tomcat/update-management/index.md) |
| **TC-ADR-0008** | Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access | Platform Foundation TN-004, [Update Management](../../projects/tomcat/update-management/index.md) |
| **TC-ADR-0009** | Enterprise Drive Separation and Transparent Host Bind-Mount Hierarchy for Multi-Instance Tomcat Containers | Platform Foundation TN-006, [Tomcat Architecture](../../projects/tomcat/architecture/index.md), [Update Management](../../projects/tomcat/update-management/index.md) |


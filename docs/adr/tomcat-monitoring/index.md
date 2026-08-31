---
title: Tomcat Monitoring Architecture Decision Records
---

## 🔍 Overview

Halaman ini berisi Architecture Decision Records (ADR) yang digunakan pada
project Tomcat Monitoring. Setiap ADR menjelaskan konteks, pilihan, alasan, dan
konsekuensi keputusan arsitektur yang memengaruhi implementasi project.

## 📚 Architecture Decision Catalog

| ADR ID | Title | Project | Section | Status | Date |
| --- | --- | --- | --- | --- | --- |
| [**TM-ADR-0001**](adr-records/TM-ADR-0001.md){: target="_blank" } | Adopt Embedded Monitoring Instrumentation for Apache Tomcat | Tomcat Monitoring | Architecture | Accepted | 2026-08-18 |
| [**TM-ADR-0002**](adr-records/TM-ADR-0002.md){: target="_blank" } | Separate Generic Runtime Images from Monitoring Integration Configuration | Tomcat Monitoring | Development Architecture | Accepted | 2026-08-26 |
| [**TM-ADR-0003**](adr-records/TM-ADR-0003.md){: target="_blank" } | Use Host-Managed Non-Git TLS Material for the Persistent Lab | Tomcat Monitoring | Infrastructure Security | Accepted | 2026-08-25 |
| [**TM-ADR-0004**](adr-records/TM-ADR-0004.md){: target="_blank" } | Separate Application Failure from Monitoring Signal Loss | Tomcat Monitoring | Monitoring Architecture | Accepted | 2026-08-25 |
| [**TM-ADR-0005**](adr-records/TM-ADR-0005.md){: target="_blank" } | Use Mailpit as the Persistent Lab Notification Verification Target | Tomcat Monitoring | Notification Architecture | Accepted | 2026-08-27 |
| [**TM-ADR-0006**](adr-records/TM-ADR-0006.md){: target="_blank" } | Use Deterministic Multi-Source Evidence for Diagnostic Assessment | Tomcat Monitoring | Diagnostic Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0007**](adr-records/TM-ADR-0007.md){: target="_blank" } | Treat TomcatDown as a Composite Diagnostic Trigger | Tomcat Monitoring | Alert and Diagnostic Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0008**](adr-records/TM-ADR-0008.md){: target="_blank" } | Use a Restricted Host Event Collector with a Normalized Evidence Spool | Tomcat Monitoring | Diagnostic Security Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0009**](adr-records/TM-ADR-0009.md){: target="_blank" } | Use SQLite for Local Diagnostic State | Tomcat Monitoring | Diagnostic Data Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0010**](adr-records/TM-ADR-0010.md){: target="_blank" } | Deploy One Bounded Diagnostic Service per Tomcat Host | Tomcat Monitoring | Diagnostic Deployment Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0011**](adr-records/TM-ADR-0011.md){: target="_blank" } | Use Per-Rule Decision Tables for Diagnostic Confidence | Tomcat Monitoring | Diagnostic Rule Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0012**](adr-records/TM-ADR-0012.md){: target="_blank" } | Decouple TrueSight Through a Disabled Integration Bridge | Tomcat Monitoring | External Integration Architecture | Accepted | 2026-08-30 |
| [**TM-ADR-0013**](adr-records/TM-ADR-0013.md){: target="_blank" } | Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service | Tomcat Monitoring | Diagnostic Service Implementation Architecture | Accepted | 2026-08-31 |

## 🗺️ ADR Mapping

| ADR ID | Title | Referenced In |
| --- | --- | --- |
| TM-ADR-0001 | Adopt Embedded Monitoring Instrumentation for Apache Tomcat | Runtime Monitoring Foundation TN-001 |
| TM-ADR-0002 | Separate Generic Runtime Images from Monitoring Integration Configuration | Monitoring Integration TN-006, TN-009, TN-025, and TN-026 |
| TM-ADR-0003 | Use Host-Managed Non-Git TLS Material for the Persistent Lab | Monitoring Integration TN-018, TN-019, and TN-020 |
| TM-ADR-0004 | Separate Application Failure from Monitoring Signal Loss | Monitoring Integration TN-021 through TN-024 |
| TM-ADR-0005 | Use Mailpit as the Persistent Lab Notification Verification Target | Monitoring Integration TN-030 through TN-035 |
| TM-ADR-0006 | Use Deterministic Multi-Source Evidence for Diagnostic Assessment | Diagnostic MVP Pilot TN-001 and Diagnostic MVP contracts |
| TM-ADR-0007 | Treat TomcatDown as a Composite Diagnostic Trigger | Diagnostic MVP Pilot TN-001 and TomcatDown rule specification |
| TM-ADR-0008 | Use a Restricted Host Event Collector with a Normalized Evidence Spool | Diagnostic MVP Pilot TN-001 and collector contract |
| TM-ADR-0009 | Use SQLite for Local Diagnostic State | Diagnostic MVP Pilot TN-001 and SQLite lifecycle contract |
| TM-ADR-0010 | Deploy One Bounded Diagnostic Service per Tomcat Host | Diagnostic MVP Pilot TN-001 and non-functional contract |
| TM-ADR-0011 | Use Per-Rule Decision Tables for Diagnostic Confidence | Diagnostic MVP Pilot TN-001 and result contract |
| TM-ADR-0012 | Decouple TrueSight Through a Disabled Integration Bridge | Diagnostic MVP Pilot TN-001 and integration contract |
| TM-ADR-0013 | Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service | Diagnostic MVP Pilot TN-003 and Development |

## 📝 Summary

Katalog ini menjadi sumber referensi keputusan arsitektur Tomcat Monitoring.
Dokumentasi project menjelaskan hasil yang berlaku, sedangkan Engineering
Journal mencatat perjalanan teknis dan penerapan setiap keputusan.

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

## 🗺️ ADR Mapping

| ADR ID | Title | Referenced In |
| --- | --- | --- |
| TM-ADR-0001 | Adopt Embedded Monitoring Instrumentation for Apache Tomcat | Runtime Monitoring Foundation TN-001 |
| TM-ADR-0002 | Separate Generic Runtime Images from Monitoring Integration Configuration | Monitoring Integration TN-006, TN-009, TN-025, and TN-026 |
| TM-ADR-0003 | Use Host-Managed Non-Git TLS Material for the Persistent Lab | Monitoring Integration TN-018, TN-019, and TN-020 |
| TM-ADR-0004 | Separate Application Failure from Monitoring Signal Loss | Monitoring Integration TN-021 through TN-024 |
| TM-ADR-0005 | Use Mailpit as the Persistent Lab Notification Verification Target | Monitoring Integration TN-030 through TN-035 |

## 📝 Summary

Katalog ini menjadi sumber referensi keputusan arsitektur Tomcat Monitoring.
Dokumentasi project menjelaskan hasil yang berlaku, sedangkan Engineering
Journal mencatat perjalanan teknis dan penerapan setiap keputusan.

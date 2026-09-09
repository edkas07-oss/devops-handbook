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
| [**TM-ADR-0014**](adr-records/TM-ADR-0014.md){: target="_blank" } | Enforce Zero Automatic Remediation for Diagnostic Service | Tomcat Monitoring | Diagnostic Safety and Operational Governance Architecture | Accepted | 2026-08-31 |
| [**TM-ADR-0015**](adr-records/TM-ADR-0015.md){: target="_blank" } | Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern | Tomcat Monitoring | Diagnostic Ingestion Architecture | Accepted | 2026-08-31 |
| [**TM-ADR-0016**](adr-records/TM-ADR-0016.md){: target="_blank" } | Designate Diagnostic Service as the Canonical Incident Notification Authority | Tomcat Monitoring | Incident Notification and Alerting Architecture | Accepted | 2026-08-31 |
| [**TM-ADR-0017**](adr-records/TM-ADR-0017.md){: target="_blank" } | Adopt Vertical Slice Minimum Viable Product (MVP) Scoping for Diagnostic Pilot | Tomcat Monitoring | Diagnostic Architecture Strategy | Accepted | 2026-08-31 |
| [**TM-ADR-0018**](adr-records/TM-ADR-0018.md){: target="_blank" } | Adopt Strict Declarative Rulepack Engine and Append-Only Ingestion API | Tomcat Monitoring | Diagnostic Rule and Extensibility Architecture | Accepted | 2026-09-02 |
| [**TM-ADR-0019**](adr-records/TM-ADR-0019.md){: target="_blank" } | Adopt Out-of-Band AI Forensic Enrichment Loop for Diagnostic Rule Synthesis | Tomcat Monitoring | Diagnostic AI and Continuous Learning Architecture | Accepted | 2026-09-03 |
| [**TM-ADR-0020**](adr-records/TM-ADR-0020.md){: target="_blank" } | Enforce Bounded Incident Notification Delivery Lifecycle and Exponential Backoff Retries | Tomcat Monitoring | Incident Notification and Delivery Architecture | Accepted | 2026-09-01 |
| [**TM-ADR-0021**](adr-records/TM-ADR-0021.md){: target="_blank" } | Adopt Layered Failure Resilience, Container Auto-Healing, and Monitoring Domain Separation | Tomcat Monitoring | Infrastructure Resilience and Fault-Tolerance Architecture | Accepted | 2026-09-08 |
| [**TM-ADR-0022**](adr-records/TM-ADR-0022.md){: target="_blank" } | Adopt JVM Garbage Collection and Concurrency Saturation Signals over Static Raw Thresholds | Tomcat Monitoring | Observability, Alerting Strategy, and Workload Health Architecture | Accepted | 2026-09-08 |
| [**TM-ADR-0023**](adr-records/TM-ADR-0023.md){: target="_blank" } | Adopt Multi-Domain Diagnostic Dispatcher and Mandatory Per-Alert Decision Engine Governance | Tomcat Monitoring | Diagnostic Rule, Decision Engine, and Observability Governance Architecture | Accepted | 2026-09-09 |

## 🗺️ ADR Mapping

| ADR ID | Title | Referenced In |
| --- | --- | --- |
| TM-ADR-0001 | Adopt Embedded Monitoring Instrumentation for Apache Tomcat | Runtime Monitoring Foundation TN-001, Diagnostic Pilot TN-020 |
| TM-ADR-0002 | Separate Generic Runtime Images from Monitoring Integration Configuration | Monitoring Integration TN-006, TN-009, TN-025, TN-026; Diagnostic Pilot TN-010, TN-020 |
| TM-ADR-0003 | Use Host-Managed Non-Git TLS Material for the Persistent Lab | Monitoring Integration TN-018, TN-019, TN-020; Diagnostic Pilot TN-020 |
| TM-ADR-0004 | Separate Application Failure from Monitoring Signal Loss | Monitoring Integration TN-021 through TN-024; Diagnostic Pilot TN-014, TN-020 |
| TM-ADR-0005 | Use Mailpit as the Persistent Lab Notification Verification Target | Monitoring Integration TN-030 through TN-035; Diagnostic Pilot TN-011, TN-020 |
| TM-ADR-0006 | Use Deterministic Multi-Source Evidence for Diagnostic Assessment | Diagnostic MVP Pilot TN-001, TN-006, TN-017, TN-019, TN-020 |
| TM-ADR-0007 | Treat TomcatDown as a Composite Diagnostic Trigger | Diagnostic MVP Pilot TN-001, TN-006, TN-014, TN-017, TN-020 |
| TM-ADR-0008 | Use a Restricted Host Event Collector with a Normalized Evidence Spool | Diagnostic MVP Pilot TN-001, TN-004, TN-006, TN-015, TN-017, TN-020 |
| TM-ADR-0009 | Use SQLite for Local Diagnostic State | Diagnostic MVP Pilot TN-001, TN-002, TN-003, TN-011, TN-015, TN-017, TN-020 |
| TM-ADR-0010 | Deploy One Bounded Diagnostic Service per Tomcat Host | Diagnostic MVP Pilot TN-001, TN-010, TN-011, TN-015, TN-017, TN-020 |
| TM-ADR-0011 | Use Per-Rule Decision Tables for Diagnostic Confidence | Diagnostic MVP Pilot TN-001, TN-006, TN-017, TN-018, TN-020 |
| TM-ADR-0012 | Decouple TrueSight Through a Disabled Integration Bridge | Diagnostic MVP Pilot TN-001, TN-011, TN-017, TN-020 |
| TM-ADR-0013 | Use Node.js 24 ESM and Isolated Built-Built-In SQLite for Diagnostic Service | Diagnostic MVP Pilot TN-003, TN-005, TN-007, TN-008, TN-009, TN-010, TN-011, TN-012, TN-013, TN-014, TN-015, TN-017, TN-018, TN-019, TN-020 |
| TM-ADR-0014 | Enforce Zero Automatic Remediation for Diagnostic Service | Diagnostic MVP Pilot TN-001, TN-007, TN-017, TN-020 |
| TM-ADR-0015 | Adopt Asynchronous Webhook Ingestion with Durable SQLite Acceptance Pattern | Diagnostic MVP Pilot TN-001, TN-008, TN-017, TN-020 |
| TM-ADR-0016 | Designate Diagnostic Service as the Canonical Incident Notification Authority | Diagnostic MVP Pilot TN-001, TN-007, TN-009, TN-012, TN-017, TN-020; Monitoring Integration TN-001, TN-004, TN-005, TN-006 |
| TM-ADR-0017 | Adopt Vertical Slice Minimum Viable Product (MVP) Scoping for Diagnostic Pilot | Diagnostic MVP Pilot TN-001, TN-007, TN-017, TN-020 |
| TM-ADR-0018 | Adopt Strict Declarative Rulepack Engine and Append-Only Ingestion API | Diagnostic MVP Pilot TN-018, TN-019, TN-020 |
| TM-ADR-0019 | Adopt Out-of-Band AI Forensic Enrichment Loop for Diagnostic Rule Synthesis | Diagnostic MVP Pilot TN-019, TN-020 |
| TM-ADR-0020 | Enforce Bounded Incident Notification Delivery Lifecycle and Exponential Backoff Retries | Diagnostic MVP Pilot TN-012, TN-017, TN-020 |
| TM-ADR-0021 | Adopt Layered Failure Resilience, Container Auto-Healing, and Monitoring Domain Separation | Monitoring Integration TN-002 |
| TM-ADR-0022 | Adopt JVM Garbage Collection and Concurrency Saturation Signals over Static Raw Thresholds | Monitoring Integration TN-003, TN-004, TN-005 |
| TM-ADR-0023 | Adopt Multi-Domain Diagnostic Dispatcher and Mandatory Per-Alert Decision Engine Governance | Monitoring Integration TN-006 |


## 📝 Summary

Katalog ini menjadi sumber referensi keputusan arsitektur Tomcat Monitoring.
Dokumentasi project menjelaskan hasil yang berlaku, sedangkan Engineering
Journal mencatat perjalanan teknis dan penerapan setiap keputusan.

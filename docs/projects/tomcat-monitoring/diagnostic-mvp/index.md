# Diagnostic MVP

## 🔍 Overview

Diagnostic MVP menambahkan diagnosis deterministik berbasis evidence pada alur
alert Tomcat Monitoring. Seluruh komponen Diagnostic Service, Restricted Event
Collector, Declarative Rulepack Engine, integrasi Alertmanager, persistensi SQLite,
dan notifikasi Mailpit telah diimplementasikan 100% dan terverifikasi secara live
pada lingkungan persisten `devops-lab` (TN-001 s/d TN-019).

Arsitektur sistem mengadopsi **5-Layer Knowledge Base and AI Enrichment Architecture**:
evaluasi pohon keputusan deterministik `TD-01` s/d `TD-08`, evaluasi dynamic rulepack
(`rulepack-v1.schema.json`) untuk aturan kustom seperti `TD-09` (*DatabaseConnectionPoolExhausted*),
serta ingestion API `POST /api/v1/rules` dengan 5 lapis pengamanan (*Strict 5-Layer Ingestion Guard*)
yang memungkinkan penambahan aturan baru secara instan (*hot-loaded*) tanpa restart container.

## 🎯 Pilot Objective

Target pertama adalah alur berikut:

```text
Prometheus
    -> Alertmanager
    -> Diagnostic Service
    -> SQLite and bounded evidence correlation
    -> Mailpit (7-Section SRE Report)
    -> resolved notification
```

Diagnostic Service memberi bantuan RCA. Ia tidak menjalankan restart, kill,
configuration change, container control, atau automatic remediation.

## 📚 Scope

| Capability | Pilot state |
| --- | --- |
| `TomcatDown` diagnostic | Engine, rulepack loader, and end-to-end flow verified live on `devops-lab` |
| Application health as `TomcatDown` evidence | Allowed and verified when mapped to the same target |
| `ApplicationHealthCheckFailed` diagnostic | Deferred and disabled |
| `TomcatHighHeapUsage` diagnostic | Deferred and disabled |
| Mailpit delivery | Persistent lab delivery verified for firing, 7-section report, and resolved |
| Declarative Rulepack Engine & Rules API | Implemented and verified live (5-Layer Ingestion Guard, hot-reloading) |
| AI Enrichment Workflow | Verified live (forensics extraction -> AI rule synthesis -> instant remapping) |
| Integration Bridge | Disabled; no connection, retry, or queue work |
| TrueSight | Disabled and not a pilot dependency |
| Automatic remediation | Excluded |

Existing application-health alerts remain monitoring alerts. They do not enter
the Diagnostic Service and are not part of Diagnostic MVP acceptance.

## 🧭 Authoritative Reading Order

1. This page for scope and precedence.
2. [TomcatDown Rule Specification](tomcat-down-rule-specification.md).
3. [Alertmanager Webhook Contract](alertmanager-webhook-contract.md).
4. [Target and Evidence Contract](target-and-evidence-contract.md).
5. [Restricted Event Collector Contract](restricted-event-collector-contract.md).
6. [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md).
7. [SQLite Lifecycle Contract](sqlite-lifecycle-contract.md).
8. [Notification and Integration Contract](notification-and-integration-contract.md).
9. [Non-Functional and Security Contract](non-functional-and-security-contract.md).
10. [Runtime Configuration and Verification Contract](runtime-configuration-and-verification-contract.md).
11. [Requirements Traceability](requirements-traceability.md).
12. [Knowledge Base and AI Enrichment Architecture](knowledge-base-and-ai-enrichment-architecture.md).
13. [Gap Register](gap-register.md).
14. Related accepted ADRs in the Tomcat Monitoring ADR catalog.

An accepted ADR takes precedence for its architectural decision. A dedicated
contract governs its domain. Repository source and verified runtime evidence
govern implementation claims. Conflicts must be recorded in the gap register;
they must not be resolved silently in source.

## ✅ Pilot Exit Criteria

Seluruh kriteria keluar (*exit criteria*) telah diverifikasi dan terpenuhi:

- [x] Firing, duplicate, material-update, dan resolved lifecycles lulus end-to-end;
- [x] Evidence antar target Tomcat terisolasi secara ketat dan tidak dapat saling silang;
- [x] High-confidence (`TD-06`, `TD-09`), partial, evidence-only, dan `UNDETERMINED` paths telah diuji;
- [x] Normalisasi bukti dan rule versioning menghasilkan diagnosis yang deterministik dan konsisten;
- [x] SQLite bertahan melewati restart container dan menegakkan retensi serta proteksi kapasitas;
- [x] Pesan laporan 7-seksi (HTML dan Plain Text) tersanitasi dengan rekomendasi SOP Bahasa Indonesia;
- [x] Disabled bridge dan TrueSight tidak menghasilkan aktivitas jaringan atau antrean;
- [x] Percobaan akses path arbitrary, container control, atau command execution ditolak;
- [x] Penambahan aturan deklaratif (`POST /api/v1/rules`) aman dan langsung aktif tanpa restart;
- [x] Seluruh blocking gaps telah diselesaikan.

## 📌 Current Status

**Fase Diagnostic MVP Pilot Selesai 100% dan Terverifikasi Live.** Seluruh alur
end-to-end dari Prometheus, Alertmanager, Diagnostic Service (`0.1.3`), Restricted
Event Collector, Declarative Rulepack Engine, alur pengayaan AI, hingga notifikasi
Mailpit dan pemulihan (*resolved*) telah diuji dan beroperasi stabil pada lingkungan
persisten `devops-lab`. Dokumen konsolidasi dan perencanaan fase berikutnya dicatat
pada [TN-020](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md).

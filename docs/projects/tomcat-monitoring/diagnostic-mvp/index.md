# Diagnostic MVP

## 🔍 Overview

Diagnostic MVP menambahkan diagnosis deterministik berbasis evidence pada alur
alert Tomcat Monitoring. Desain telah diterima pada 2026-08-30. Schema,
migration, durable SQLite ingestion, queue, target isolation, bounded evidence
adapters, dan deterministic `TomcatDown` engine telah diterapkan pada source.
Digest-pinned application image telah lulus disposable HTTPS/SQLite/SIGTERM
dan Mailpit notification verification. Persistent container, collector, dan end-to-end runtime belum
diimplementasikan atau diverifikasi.

Single-worker orchestration, canonical-result persistence, material-update
guard, health/metrics model, seven-section renderers, bounded SMTP retry,
attempt persistence, dan firing/material/resolved notification lifecycle telah
tersedia di source. TN-013 membuktikan Mailpit firing/resolved delivery,
duplicate suppression, persisted attempts, text/HTML content, dan SQLite reopen.

HTTPS request boundary dan SMTP adapter pada commit `bc4b7ae` telah lulus
ephemeral socket tests pada TN-008. Source commit `a398349` menambahkan versioned
non-secret configuration, mounted-file secret loader, migration-before-
readiness startup, tepat satu worker loop, Prometheus text serialization, dan
graceful shutdown. Tiga component tests membuktikan temporary HTTPS, SQLite,
dan fake SMTP; seluruh certificate dan database fixture telah dibersihkan.
TN-010 membangun baseline image. TN-013 kemudian membangun image `0.1.1` dan memverifikasi
non-root metadata, dependency content, mounted HTTPS configuration, SQLite
migration, Mailpit aktual, serta SIGTERM secara disposable. Persistent runtime,
deployment, actual Alertmanager route, dan end-to-end behavior belum diverifikasi.

TN-011 menetapkan exact runtime configuration paths, mount/permission boundary,
immutable image consumption, ownership, dan disposable multi-component
verification contract. Contract tersebut tidak membuat integration files atau
runtime resources.

Pilot pertama hanya menerima `TomcatDown`. Application health boleh menjadi
supporting evidence untuk incident tersebut, tetapi bukan diagnostic rule.
`ApplicationHealthCheckFailed` dan `TomcatHighHeapUsage` tetap deferred.

Implementation menggunakan Node.js `24.18.0` LTS dengan plain ESM JavaScript
dan built-in `node:sqlite` yang diisolasi melalui satu adapter. Source,
dependency, dan local image tersedia; persistent runtime belum tersedia.

## 🎯 Pilot Objective

Target pertama adalah alur berikut:

```text
Prometheus
    -> Alertmanager
    -> Diagnostic Service
    -> SQLite and bounded evidence correlation
    -> Mailpit
    -> resolved notification
```

Diagnostic Service memberi bantuan RCA. Ia tidak menjalankan restart, kill,
configuration change, container control, atau automatic remediation.

## 📚 Scope

| Capability | Pilot state |
| --- | --- |
| `TomcatDown` diagnostic | Engine and source lifecycle implemented; end-to-end flow not verified |
| Application health as `TomcatDown` evidence | Allowed when mapped to the same target |
| `ApplicationHealthCheckFailed` diagnostic | Deferred and disabled |
| `TomcatHighHeapUsage` diagnostic | Deferred and disabled |
| Mailpit delivery | Active target; source/socket and disposable actual Mailpit capture verified |
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

The pilot may be accepted only after:

- firing, duplicate, material-update, and resolved lifecycles pass end to end;
- evidence from one Tomcat identity cannot cross into another identity;
- high-confidence, partial, evidence-only, failed, and unavailable-source paths
  are tested;
- the same normalized evidence and rule version produce the same result;
- SQLite survives restart and enforces retention and capacity protection;
- plain-text and HTML messages are sanitized and visible in Mailpit;
- disabled bridge and TrueSight produce no network, retry, or queue activity;
- arbitrary command, path, container-control, and host-control requests fail;
- all blocking gaps are resolved or explicitly accepted.

## 📌 Current Status

**Application source termasuk notification orchestration, configuration,
startup lifecycle, TN-013 local image, dan disposable Mailpit integration telah
terverifikasi; persistent diagnostic runtime belum tersedia.** Deployment,
actual Alertmanager route, named-volume restart durability, collector, dan
end-to-end behavior belum diverifikasi.

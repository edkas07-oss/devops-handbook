# Diagnostic MVP Pilot Engineering Journal

## 🔍 Overview

Phase ini mencatat discovery, keputusan, implementasi, dan verification untuk
alur `TomcatDown` dari Prometheus sampai resolved notification. Ia dimulai
setelah phase Monitoring Integration and Runtime Deployment ditutup.

## 🎯 Objective

Membuktikan alur deterministik berikut tanpa automatic remediation:

```text
Prometheus -> Alertmanager -> Diagnostic Service
    -> SQLite and bounded evidence -> Mailpit -> resolved
```

## 📄 Technical Notes

1. **[TN-001 — Define Diagnostic MVP Architecture and Contract](TN-001-define-diagnostic-mvp-architecture-and-contract.md)**

    Mencatat revalidasi repository dan brainstorming package, menerima
    `TomcatDown`-only scope, menetapkan ownership, security, collector, SQLite,
    result, notification contract, serta documentation-native handoff tanpa
    implementasi atau runtime mutation.

2. **[TN-002 — Reconcile Diagnostic MVP Current-State Consolidation](TN-002-reconcile-diagnostic-mvp-current-state-consolidation.md)**

    Mereview hasil TN-001 dan melebur capability Diagnostic MVP ke section
    Architecture, Development, dan Infrastructure yang sudah menjadi
    current-state source of truth, sekaligus menetapkan standar konsolidasi
    feature lintas project.

3. **[TN-003 — Define Diagnostic Service Repository Implementation and Validation Contract](TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md)**

    Menerima Node.js 24 ESM dan isolated built-in SQLite, menetapkan repository
    serta validation contract, menutup GAP-001, dan mempertahankan source
    implementation sebagai authorization terpisah.

4. **[TN-004 — Establish Diagnostic Service Repository Governance and Static Validation Baseline](TN-004-establish-diagnostic-service-repository-governance-and-static-validation-baseline.md)**

    Membentuk governance, metadata dependency-free, dan static validation
    baseline repository Diagnostic Service tanpa business logic, build, atau
    runtime container.

5. **[TN-005 — Implement Durable Diagnostic Ingestion and Queue](TN-005-implement-durable-diagnostic-ingestion-and-queue.md)**

    Mengimplementasikan webhook schema, SQLite migration, durable event
    ingestion, deduplication, dan bounded persistent queue beserta tests.

6. **[TN-006 — Implement Target Isolation, Evidence Adapters, and TomcatDown Engine](TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md)**

    Mengimplementasikan trusted target mapping, bounded evidence collection,
    isolation, dan deterministic TD-01 sampai TD-08 engine.

## 📌 Phase Status

**In Progress.** Durable ingestion, target isolation, evidence adapters, dan
deterministic engine telah lulus isolated tests. Worker orchestration, result
persistence, HTTP runtime, notification, dan end-to-end verification tertunda.

## 🧭 Reproducibility Status

| Technical Note | Reproduction anchor |
| --- | --- |
| TN-001 | Handbook commit `c924459` |
| TN-002 | Handbook commit `f50a92d` |
| TN-003 | Handbook commit `2c0535e` |
| TN-004 | Handbook record `3cd4ea2`; source baseline `03f1296` |
| TN-005 | Source commit `aa55170`; exact path manifest pada TN |
| TN-006 | Source commit `aa55170`; 17 substantive tests |

TN-005 dan TN-006 berbagi satu source commit karena keduanya membentuk satu
verified diagnostic-engine foundation. Commit masih lokal dan belum dipush.

## 🔗 Related Documentation

- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Tomcat Monitoring Engineering Journal](../index.md)
- [Tomcat Monitoring ADR](../../../../adr/tomcat-monitoring/index.md)

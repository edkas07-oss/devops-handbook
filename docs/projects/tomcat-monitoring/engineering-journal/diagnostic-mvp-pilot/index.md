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

## 📌 Phase Status

**In Progress.** Architecture and documentation contract accepted; source,
configuration, runtime, and end-to-end verification have not started.

## 🔗 Related Documentation

- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Tomcat Monitoring Engineering Journal](../index.md)
- [Tomcat Monitoring ADR](../../../../adr/tomcat-monitoring/index.md)

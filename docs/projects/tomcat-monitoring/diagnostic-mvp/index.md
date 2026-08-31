# Diagnostic MVP

## 🔍 Overview

Diagnostic MVP menambahkan diagnosis deterministik berbasis evidence pada alur
alert Tomcat Monitoring. Desain telah diterima pada 2026-08-30, tetapi source,
configuration, image, container, SQLite database, collector, dan end-to-end
runtime belum diimplementasikan atau diverifikasi.

Pilot pertama hanya menerima `TomcatDown`. Application health boleh menjadi
supporting evidence untuk incident tersebut, tetapi bukan diagnostic rule.
`ApplicationHealthCheckFailed` dan `TomcatHighHeapUsage` tetap deferred.

Implementation plan menerima Node.js `24.18.0` LTS dengan plain ESM JavaScript
dan built-in `node:sqlite` yang diisolasi melalui satu adapter. Keputusan
toolchain tersebut belum berarti source, dependency, image, atau runtime telah
tersedia.

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
| `TomcatDown` diagnostic | Accepted design; not implemented |
| Application health as `TomcatDown` evidence | Allowed when mapped to the same target |
| `ApplicationHealthCheckFailed` diagnostic | Deferred and disabled |
| `TomcatHighHeapUsage` diagnostic | Deferred and disabled |
| Mailpit delivery | Active target for the future pilot flow |
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
10. [Requirements Traceability](requirements-traceability.md).
11. [Gap Register](gap-register.md).
12. Related accepted ADRs in the Tomcat Monitoring ADR catalog.

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

**Accepted design and implementation plan — not implemented or runtime
verified.** Approval of this documentation does not authorize source changes,
dependency installation, image build, container mutation, deployment, atau
end-to-end testing.

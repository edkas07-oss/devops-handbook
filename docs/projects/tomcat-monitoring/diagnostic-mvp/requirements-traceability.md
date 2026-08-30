# Diagnostic MVP Requirements Traceability

## 🔍 Overview

This matrix maps accepted pilot requirements to contracts and future evidence.
All implementation evidence is currently `Not available`.

| ID | Requirement | Contract | Required future evidence |
| --- | --- | --- | --- |
| PILOT-001 | Only `TomcatDown` enters diagnostic routing | Scope; rule specification | Enabled-rule and Alertmanager route tests |
| ING-001 | Authenticated firing/resolved webhook | Webhook contract | TLS, token, schema, and API tests |
| ING-002 | SQLite commit occurs before `202` | Webhook; SQLite | Failure-injection and restart test |
| ING-003 | Duplicate event is idempotent across restart | Webhook; SQLite | Replay test before and after restart |
| ID-001 | Only allowlisted canonical target is accepted | Target contract | Unknown, mismatch, and cross-target tests |
| RULE-001 | `up=0` is a trigger, not proof | Rule specification | JMX-only failure scenario |
| RULE-002 | Evidence is bounded and correlated | Rule; evidence contracts | Source fixtures and boundary tests |
| RULE-003 | Missing evidence is explicit | Result contract | Unavailable-source tests |
| RULE-004 | Contradictions precede supporting evidence | Rule specification | Contradiction fixtures |
| RULE-005 | Confidence follows decision table | Result contract; ADR | Branch unit tests |
| RULE-006 | Same inputs and rule version are deterministic | Result contract | Regression hash test |
| RES-001 | Canonical result validates semantic combinations | Result contract | Schema and semantic tests |
| MSG-001 | Plain-text and HTML preserve canonical meaning | Notification contract | Golden files |
| MSG-002 | Firing, update, partial, failed, and resolved render | Notification contract | Lifecycle template tests |
| DEL-001 | Mailpit is the only active pilot target | Notification contract | SMTP and Mailpit assertions |
| DEL-002 | Disabled bridge performs no work | Notification contract | Network, queue, and metric assertions |
| DB-001 | Initialization and migrations are automatic | SQLite contract | Empty-volume startup test |
| DB-002 | Incident and dedup state survive restart | SQLite contract | Restart test |
| DB-003 | Retention and capacity protection are automatic | SQLite contract | Housekeeping and limit tests |
| NFR-001 | One bounded service isolates multiple local targets | NFR; deployment ADR | Multi-target isolation test |
| NFR-002 | Worker, queue, timeout, and evidence bounds apply | NFR contract | Load and timeout tests |
| SEC-001 | Service cannot control containers or host | Security; collector contracts | Negative authorization tests |
| SEC-002 | Collector exposes only normalized allowlisted records | Collector contract | Abuse and spool-contract tests |
| OPS-001 | Health and capacity metrics are exported | NFR contract | Metrics contract test |

## ⏳ Deferred Requirements

| ID | Requirement | Promotion condition |
| --- | --- | --- |
| DEF-APP-001 | `ApplicationHealthCheckFailed` diagnostic rule | Pilot exit criteria and separate rule approval |
| DEF-HEAP-001 | `TomcatHighHeapUsage` diagnostic rule | Pilot exit criteria, baseline, and rule approval |
| DEF-TS-001 | Integration Bridge and TrueSight activation | Target contract, security, mapping, and delivery approval |

Deferred items are not pilot failures.

## 📌 Status

**Requirements accepted; implementation and verification evidence pending.**

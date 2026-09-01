# Diagnostic MVP Requirements Traceability

## 🔍 Overview

This matrix maps accepted pilot requirements to contracts and remaining
evidence. Source and disposable image evidence exists for selected rows, but no
persistent or end-to-end diagnostic evidence is available.

| ID | Requirement | Contract | Evidence state and remaining requirement |
| --- | --- | --- | --- |
| PILOT-001 | Only `TomcatDown` enters diagnostic routing | Scope; rule specification | Enabled-rule and Alertmanager route tests |
| ING-001 | Authenticated firing/resolved webhook | Webhook contract | Source and disposable HTTPS/token tests passed; firing/resolved integration remains |
| ING-002 | SQLite commit occurs before `202` | Webhook; SQLite | Failure-injection and restart test |
| ING-003 | Duplicate event is idempotent across restart | Webhook; SQLite | Temporary-database source replay passed; persistent-volume restart remains |
| ID-001 | Only allowlisted canonical target is accepted | Target contract | Source unknown/mismatch tests passed; multi-target runtime remains |
| RULE-001 | `up=0` is a trigger, not proof | Rule specification | JMX-only failure scenario |
| RULE-002 | Evidence is bounded and correlated | Rule; evidence contracts | Source fixtures and boundary tests |
| RULE-003 | Missing evidence is explicit | Result contract | Unavailable-source tests |
| RULE-004 | Contradictions precede supporting evidence | Rule specification | Contradiction fixtures |
| RULE-005 | Confidence follows decision table | Result contract; ADR | TD-01 through TD-08 branch unit tests passed |
| RULE-006 | Same inputs and rule version are deterministic | Result contract | Regression hash test |
| RULE-007 | Prometheus attempt has a five-second deadline, no in-run retry, and explicit fallback | Rule specification | Timely response, timeout, unavailable marker, and continued log/spool evidence tests |
| RES-001 | Canonical result validates semantic combinations | Result contract | Source semantic tests passed; integration persistence remains |
| MSG-001 | Plain-text and HTML preserve canonical meaning | Notification contract | Source renderer tests passed; delivered-message comparison remains |
| MSG-002 | Firing, update, partial, failed, and resolved render | Notification contract | Lifecycle template tests |
| MSG-003 | Email renders seven ordered sections with bounded sanitized metrics and log evidence | Notification contract | Plain-text/HTML ordering, unavailable section, redaction, and overclaim-prevention tests |
| DEL-001 | Mailpit is the only active pilot target | Notification contract | SMTP adapter socket test passed; worker wiring and Mailpit assertions remain |
| DEL-002 | Disabled bridge performs no work | Notification contract | Network, queue, and metric assertions |
| DB-001 | Initialization and migrations are automatic | SQLite contract | Temporary directory and image migration tests passed; empty named volume remains |
| DB-002 | Incident and dedup state survive restart | SQLite contract | Source reopen test passed; persistent-volume restart remains |
| DB-003 | Retention and capacity protection are automatic | SQLite contract | Housekeeping and limit tests |
| NFR-001 | One bounded service isolates multiple local targets | NFR; deployment ADR | Multi-target isolation test |
| NFR-002 | Worker, queue, timeout, and evidence bounds apply | NFR contract | Load and timeout tests |
| SEC-001 | Service cannot control containers or host | Security; collector contracts | Negative authorization tests |
| SEC-002 | Collector exposes only normalized allowlisted records | Collector contract | Abuse and spool-contract tests |
| OPS-001 | Health and capacity metrics are exported | NFR contract | Health/metrics source and disposable probes passed; capacity metrics remain |

## ⏳ Deferred Requirements

| ID | Requirement | Promotion condition |
| --- | --- | --- |
| DEF-APP-001 | `ApplicationHealthCheckFailed` diagnostic rule | Pilot exit criteria and separate rule approval |
| DEF-HEAP-001 | `TomcatHighHeapUsage` diagnostic rule | Pilot exit criteria, baseline, and rule approval |
| DEF-TS-001 | Integration Bridge and TrueSight activation | Target contract, security, mapping, and delivery approval |

Deferred items are not pilot failures.

## 📌 Status

**Requirements accepted; implementation and verification evidence pending.**

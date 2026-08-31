# Diagnostic MVP Gap Register

## 🔍 Overview

The documentation decision closes scope and architecture choices but does not
claim implementation readiness where repository or lab evidence is absent.

| ID | Open item | Closure evidence | Gate | Owner |
| --- | --- | --- | --- | --- |
| GAP-001 | Create `tomcat-diagnostic-service` repository and governance | Approved repository plan, source contract, and validation interface | Before service implementation | Project owner / engineer |
| GAP-002 | Create `tomcat-diagnostic-event-collector` repository | Approved host-runtime plan and privilege assessment | Before collector implementation | Platform owner / engineer |
| GAP-003 | Physical SQLite schema and migration mechanism | Reviewed implementation design and schema tests | Before schema freeze | Service owner |
| GAP-004 | Target allowlist physical format | Validated configuration schema for `lab + edkas-pc1 + tomcat-jmx-exporter` | Before webhook tests | Integration owner |
| GAP-005 | Stable container generation source | Rootless Podman evidence and recreation semantics | Before correlation tests | Platform owner |
| GAP-006 | Authoritative logs and rotation | Effective Tomcat/JULI/stdout mounts and retention | Before log adapter | Tomcat owner |
| GAP-007 | JVM fatal artifact location | Effective JVM arguments and writable artifact mount | Before crash adapter | Tomcat owner |
| GAP-008 | Rootless collector evidence permissions | cgroup, user-service, journal, and Podman access matrix | Before collector test | Platform owner |
| GAP-009 | Diagnostic TLS and bearer secret lifecycle | Non-Git paths, permissions, rotation, CA mount, and reload process | Before webhook deployment | Security/platform owner |
| GAP-010 | SMTP retry values | Attempts, backoff, maximum age, and queue bounds | Before delivery implementation | Service owner |
| GAP-011 | Collector spool bounds | Retention duration, maximum records, total size, and cleanup behavior | Before collector schema freeze | Collector owner |
| GAP-012 | Host resource baseline | CPU, memory, filesystem, and representative workload evidence | Before NFR acceptance | Lab owner |
| GAP-013 | Safe failure injection procedures | Approved OOM, JMX loss, stop, crash, outage, and recovery methods | Before end-to-end tests | Project owner / engineer |
| GAP-014 | Production TLS, HA, backup, and recovery | Production architecture decision | Production-only | Security/platform owner |
| GAP-015 | TrueSight class, slots, credentials, and delivery semantics | Separate accepted integration contract | Deferred | Integration owner |

An item is closed append-oriented with observed evidence, accepted value,
affected artifact, resolver/date, and verification consequence. A decision that
changes an ADR boundary requires a new or superseding ADR.

## ✅ Closure Records

| ID | Resolution | Affected artifact | Resolver/date | Verification consequence |
| --- | --- | --- | --- | --- |
| GAP-001 | Closed. Repository location is observed; Node.js 24 ESM, isolated built-in SQLite, repository layout, source boundary, and validation interface are accepted. | TN-003, TM-ADR-0013, Development | Project owner / 2026-08-31 | Repository governance and static validation baseline may be planned; source implementation still requires a separate approved scope |

## 📌 Status

**Open — GAP-001 closed; GAP-002 through GAP-015 retain their recorded gates.**

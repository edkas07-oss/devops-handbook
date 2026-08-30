# TM-ADR-0010

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0010 |
| **Title** | Deploy One Bounded Diagnostic Service per Tomcat Host |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Deployment Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

One lightweight Diagnostic Service per Tomcat host handles one or more
explicitly allowlisted local Tomcat targets with one worker.

## 🌍 Context

Evidence is host-local and must not cross targets. Monitoring overhead must not
compete materially with Tomcat. The service also has a reusable source and
image lifecycle distinct from integration configuration.

## ⚖️ Decision

Repository `tomcat-diagnostic-service` owns application source, dependency
lock, image lifecycle, migrations, and component tests. `tomcat-monitoring`
owns target configuration, routing, secrets references, deployment,
integration validation, and lab orchestration. Initial limits are one worker,
queue 50, 60-second diagnostic timeout, 256 MiB memory, and 500m CPU.

## 🏛️ Architecture

Each host deploys one service and one local state volume. Canonical identity and
allowlist isolate multiple Tomcat instances on that host.

## 💡 Rationale

Per-container services duplicate overhead; one central multi-host service
weakens locality and expands credentials. A bounded per-host service balances
isolation, evidence locality, and resource use.

## ⚠️ Consequences

Two new runtime repositories are required for service and collector. Horizontal
active-active operation is excluded, and host capacity requires representative
testing.

## 📌 Status

**Accepted — repositories, image, and deployment pending.**

## 📅 Date

**2026-08-30**

# TM-ADR-0008

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0008 |
| **Title** | Use a Restricted Host Event Collector with a Normalized Evidence Spool |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Security Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Host and container evidence is exposed through a rootless collector that writes
a bounded normalized spool read-only to Diagnostic Service.

## 🌍 Context

Mounting a broad Podman socket or adding host command access would turn an
evidence consumer into a runtime-control surface. Some host evidence also has
different privilege and lifecycle requirements from the service container.

## ⚖️ Decision

A separately owned `tomcat-diagnostic-event-collector` host runtime reads only
allowlisted identities and evidence types, then atomically writes versioned
bounded records. Diagnostic Service cannot send arbitrary queries or actions.
Evidence unavailable to approved rootless access remains unavailable.

## 🏛️ Architecture

`Host evidence -> restricted collector -> normalized spool -> read-only
Diagnostic Service adapter` is a one-way boundary.

## 💡 Rationale

The spool form removes a request/control API, permits strict schema and size
validation, and isolates host permissions from the service container.

## ⚠️ Consequences

A separate repository and lifecycle are required. Retention, atomicity,
permissions, and freshness need explicit tests; some evidence may be absent in
rootless mode.

## 📌 Status

**Accepted — collector repository and runtime pending.**

## 📅 Date

**2026-08-30**

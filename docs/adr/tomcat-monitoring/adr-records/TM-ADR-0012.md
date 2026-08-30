# TM-ADR-0012

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0012 |
| **Title** | Decouple TrueSight Through a Disabled Integration Bridge |
| **Project** | Tomcat Monitoring |
| **Section** | External Integration Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Mailpit is the only active Diagnostic MVP delivery target. Future TrueSight
delivery is isolated behind an Integration Bridge that remains disabled.

## 🌍 Context

TrueSight contracts, credentials, security, event classes, slots, and closure
semantics are unavailable. Adding `msend` or general SNMP dependencies to the
Diagnostic Service would couple diagnosis to one external platform.

## ⚖️ Decision

Diagnostic Service renders Mailpit email from the canonical result. When
disabled, Integration Bridge and TrueSight have no endpoint, credential,
connection, retry, queue, or worker activity. Future activation sends a bounded
canonical JSON projection; only the bridge owns TrueSight mapping and transport.

This decision clarifies the activation state described by TM-ADR-0001 without
changing its embedded instrumentation architecture: TrueSight is a future
target, not a current lab implementation.

## 🏛️ Architecture

`Canonical result -> Mailpit` is active. `Canonical result -.-> Integration
Bridge -.-> TrueSight` remains disabled.

## 💡 Rationale

The boundary keeps diagnostic semantics platform-independent and prevents an
unavailable external system from affecting classification or Mailpit delivery.

## ⚠️ Consequences

The pilot does not prove TrueSight delivery. Activation requires a separate
contract, secrets, mapping, lifecycle, failure, and resolved-state verification.

## 📌 Status

**Accepted — bridge and TrueSight disabled.**

## 📅 Date

**2026-08-30**

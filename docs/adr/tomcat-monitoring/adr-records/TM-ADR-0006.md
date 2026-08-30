# TM-ADR-0006

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0006 |
| **Title** | Use Deterministic Multi-Source Evidence for Diagnostic Assessment |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Diagnostic assessment uses deterministic correlation of bounded normalized
evidence. A production AI/LLM runtime is not used.

## 🌍 Context

A Prometheus alert identifies a symptom. Metrics, logs, crash artifacts,
container lifecycle, host events, and application health can support or
contradict a cause, but a single generic signal cannot safely establish RCA.

## ⚖️ Decision

All rules follow `Evidence -> Observation -> Assessment -> Recommended Action`.
Evidence records source, target, time, collection status, strength, and bounded
sanitized value. Missing evidence remains explicit. The same normalized input
and rule version must produce the same result.

## 🏛️ Architecture

Diagnostic Service collects from allowlisted adapters, normalizes evidence,
applies a versioned rule decision table, and emits one canonical result.

## 💡 Rationale

Deterministic rules are auditable, reproducible, resource-bounded, and suitable
for the available pilot evidence. Generic scoring, single-signal RCA, and an
LLM runtime were rejected because they could overstate causality or add an
unnecessary operational dependency.

## ⚠️ Consequences

Rules and fixtures require explicit maintenance. Unknown and partial outcomes
remain visible instead of being converted into an invented cause.

## 📌 Status

**Accepted — implementation pending.**

## 📅 Date

**2026-08-30**

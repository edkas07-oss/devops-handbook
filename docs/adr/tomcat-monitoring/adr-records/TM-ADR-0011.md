# TM-ADR-0011

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0011 |
| **Title** | Use Per-Rule Decision Tables for Diagnostic Confidence |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Rule Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Diagnostic classification and confidence are assigned by explicit versioned
rule branches rather than a generic additive score.

## 🌍 Context

Evidence sources differ in authority and can contradict one another. Numeric or
generic scores would imply precision that the pilot has not validated.

## ⚖️ Decision

Each rule specifies ordered evidence conditions, contradictions,
classification, allowed confidence, and required direct evidence. Confirmed
cause requires high-confidence direct evidence with time correlation.
`undetermined` and `not_supported` have no confidence value.

## 🏛️ Architecture

Normalized evidence enters the selected rule version; the first matching
approved branch produces assessment fields in canonical result version `1`.

## 💡 Rationale

Decision tables are testable, explainable, and deterministic. Generic scores,
percentages, and renderer-side interpretation were rejected.

## ⚠️ Consequences

Every promoted diagnostic rule requires its own reviewed table and fixtures.
Rule changes require versioning and deterministic regression tests.

## 📌 Status

**Accepted — engine and fixtures pending.**

## 📅 Date

**2026-08-30**

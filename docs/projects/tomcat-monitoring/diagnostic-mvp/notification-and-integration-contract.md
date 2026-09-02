# Notification and Integration Contract

## 🔍 Overview

Mailpit is the only active Diagnostic MVP delivery target. Integration Bridge
and TrueSight remain represented as future boundaries but are disabled.

## ✉️ Mailpit Delivery

Alertmanager routes `TomcatDown` exclusively to Diagnostic Service with
resolved delivery enabled. It does not also send the raw `TomcatDown` alert to
Mailpit. Diagnostic Service sends sanitized plain-text and HTML mail through
internal `mailpit:1025` using `.invalid` sender and recipient identities.

Existing application-health alerts may continue using their current direct
Mailpit route. They are monitoring notifications, not Diagnostic MVP results or
acceptance evidence.

## 📋 Message Contract

Each message preserves canonical meaning and includes lifecycle, environment,
target, incident time, processing status, assessment, confidence when allowed,
supporting and unavailable evidence summary, recommended operator actions,
rule identity, and diagnostic identifier.

Plain-text and HTML renderers use the same semantic order:

| Order | Section | Required content |
| ---: | --- | --- |
| 1 | Alert Summary | Alert title, lifecycle, severity, environment, target, and incident time |
| 2 | Diagnostic Assessment | Processing status, classification, primary assessment, and confidence only when the classification allows it |
| 3 | Key Metrics Snapshot | Bounded primary metrics with observation time and query status, or an explicit unavailable/timeout marker |
| 4 | Correlated Log Evidence | Bounded sanitized excerpts selected by target, runtime generation, evidence window, and accepted diagnostic rule |
| 5 | Unavailable or Contradicting Evidence | Sources that timed out, were unavailable, were not configured, or contradicted the primary assessment |
| 6 | Recommended Operator Actions | Safe actions for an operator; never executable remediation |
| 7 | Rule and Diagnostic Traceability | Rule ID/version, diagnostic ID, result hash, and evidence timestamps needed for correlation |

The fourth section is not an arbitrary tail of the latest log. It contains only
correlated excerpts that passed identity, time-window, size, and redaction
controls. The renderer uses root-cause wording only for a classification that
permits that claim. Partial, possible, symptom-only, or undetermined results
state their limitation explicitly. A missing metrics or log section is rendered
with its collection status and is never silently removed.

Required lifecycle behavior:

- exactly one initial firing diagnostic per incident;
- no message for an identical duplicate;
- at most one message for a material canonical-result update in the pilot;
- a partial, evidence-only, or failed message must state its limitation;
- exactly one resolved message, reusing the firing summary without claiming
  permanent remediation.

Delivery status is independent of classification and confidence. SMTP failure
is stored and retried with bounded policy; it cannot change the diagnostic.

## 🚫 Disabled Integration

When disabled, Integration Bridge and TrueSight have no configured endpoint,
credential, connection attempt, retry, queue item, or delivery worker. Future
activation receives only a bounded canonical JSON projection. The bridge alone
would own TrueSight slot mapping and `msend` or SNMP execution.

Diagnostic Service contains no `msend`, general SNMP runtime dependency, or
automatic remediation path.

## 📌 Status

**Accepted, implemented, and disposable-runtime verified.** Renderer, worker
orchestration, persisted attempts, bounded retry, initial/resolved lifecycle,
duplicate suppression, and actual Mailpit plain-text/HTML capture have evidence
on the TN-013 image digest. Persistent runtime, actual Alertmanager diagnostic
route, material/failed runtime scenarios, and end-to-end correlation remain
unverified. Existing direct Alertmanager–Mailpit delivery remains the verified
persistent monitoring runtime.

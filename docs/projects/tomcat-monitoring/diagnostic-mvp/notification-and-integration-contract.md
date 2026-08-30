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

**Accepted contract — Diagnostic Service delivery not implemented. Existing
direct Alertmanager–Mailpit delivery remains the verified current state.**

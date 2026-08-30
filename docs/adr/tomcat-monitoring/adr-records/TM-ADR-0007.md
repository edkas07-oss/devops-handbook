# TM-ADR-0007

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0007 |
| **Title** | Treat TomcatDown as a Composite Diagnostic Trigger |
| **Project** | Tomcat Monitoring |
| **Section** | Alert and Diagnostic Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

`up{job="tomcat-jmx-exporter"} == 0` for two minutes triggers diagnosis; it does
not prove that Tomcat is down.

## 🌍 Context

Scrape failure can result from Tomcat termination, JMX Exporter, TLS,
configuration, network, or Prometheus-path failure. Application health can
remain available while JMX scraping fails.

## ⚖️ Decision

The first pilot enables only `TomcatDown`. It correlates Prometheus, optional
application health, logs, crash artifacts, runtime, and host evidence through a
versioned decision table. Application-health and high-heap diagnostic rules
remain disabled.

## 🏛️ Architecture

Prometheus detects the sustained condition, Alertmanager sends firing and
resolved events, and Diagnostic Service determines whether Tomcat is proven
unavailable or the failure belongs to another path.

## 💡 Rationale

This preserves fast metric-based detection without converting monitoring-path
failure into a false root-cause claim.

## ⚠️ Consequences

The result may legitimately be partial or undetermined. More evidence adapters
and isolation tests are required than for a direct alert email.

## 📌 Status

**Accepted — rule and diagnostic implementation pending.**

## 📅 Date

**2026-08-30**

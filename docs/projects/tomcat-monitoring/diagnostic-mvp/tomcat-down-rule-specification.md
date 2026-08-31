# TomcatDown Rule Specification

## 🔍 Overview

`TomcatDown` detects a sustained Prometheus scrape failure for the configured
Tomcat JMX Exporter target and triggers bounded evidence correlation. The alert
does not prove that Tomcat is down.

## 📋 Alert Contract

| Field | Pilot value |
| --- | --- |
| Alert name | `TomcatDown` |
| Expression | `up{job="tomcat-jmx-exporter"} == 0` |
| Duration | `2m` |
| Severity | `critical` |
| Scrape interval used by the decision | `30s` |
| Service label | `tomcat` |
| Check label | `runtime-availability` |

The two-minute duration represents four current scrape intervals. A future
change to scrape interval, target naming, expression, or duration requires a
contract review and matching rule tests.

Required identity labels are `environment`, `host`, and `tomcat_instance`.
`job` and `instance` identify the technical scrape endpoint. `application` is
optional context and is not part of the `TomcatDown` identity.

## 🧩 Evidence Window and Sources

The rule evaluates bounded evidence from 15 minutes before `startsAt` through
two minutes after the diagnostic begins, subject to the global 60-second
processing timeout.

| Source | Purpose | Requirement |
| --- | --- | --- |
| Prometheus | Scrape state, last successful sample, and error context when available | Required attempt |
| Application health | Distinguish a live application from JMX/TLS/scrape-path failure | Supporting; optional |
| Tomcat logs | Lifecycle, startup failure, orderly shutdown, bind, and JVM error evidence | Required attempt when configured |
| JVM crash artifacts | Correlate a fatal JVM termination | Optional bounded evidence |
| Restricted event collector | Container exit, OOM, stop, restart, cgroup, and approved host event evidence | Required attempt when configured |

Unavailable evidence is reported as unavailable. It is not interpreted as
proof that an event did not occur.

The Prometheus adapter has one total five-second deadline per diagnostic run,
including connection and response processing. It performs one attempt without
an in-run retry. A timeout produces evidence status `timeout` and does not fail
the whole diagnostic. The worker continues with every other configured source,
including bounded Tomcat logs, crash artifacts, application health, and the
restricted event collector spool. The canonical result and notification must
identify Prometheus as unavailable rather than omitting it or treating missing
metrics as proof of a Tomcat condition.

## ⚖️ Deterministic Decision Table

The first matching branch in this table governs the primary assessment.

| Branch | Correlated evidence | Assessment | Confidence |
| --- | --- | --- | --- |
| TD-01 | JMX scrape fails; application health succeeds; container is running | Tomcat is not proven down; JMX Exporter, TLS, or scrape path failed | `medium` |
| TD-02 | JMX and application health fail; runtime records OOM kill or cgroup `oom_kill` increase before exit | Container terminated by OOM mechanism | `high` |
| TD-03 | Fatal JVM marker, matching crash artifact, and runtime death event correlate | JVM fatal crash | `high` |
| TD-04 | Startup sequence, connector `BindException`, and incomplete startup correlate | Connector startup failed because the configured port could not bind | `high` |
| TD-05 | Orderly shutdown log and explicit stop event correlate | Controlled or externally requested shutdown | `high` |
| TD-06 | Container is exited, but no rule-approved cause evidence is available | Container exited; cause undetermined | no confidence |
| TD-07 | Container runs while JMX and health time out with supporting long-pause evidence | Tomcat may be unresponsive; process is not proven down | `medium` |
| TD-08 | Required sources are unavailable or evidence conflicts without a decisive branch | Cause undetermined from available evidence | no confidence |

Contradicting direct evidence is evaluated before supporting evidence. Generic
log text alone cannot establish a confirmed cause. Result selection is
deterministic for the same normalized evidence and `rule_version`.

## 🔄 Lifecycle

- The first unique firing event runs the diagnostic and produces one initial
  canonical result.
- Duplicate firing delivery performs no repeated diagnosis or notification.
- A material canonical-result change may produce one update during the pilot.
- Resolved processing reuses the stored firing result; it does not run a full
  diagnosis again.
- A resolved event without stored firing state is accepted as
  `resolved_without_previous_firing` and must not invent a prior diagnosis.

## ✅ Acceptance Scenarios

Tests must cover JMX-only failure, application and JMX failure, OOM kill, JVM
fatal crash, controlled shutdown, unexplained exit, unavailable evidence,
Prometheus completion within five seconds, Prometheus timeout fallback without
retry, duplicate firing, one material update, Mailpit failure, restart
persistence, and resolved delivery.

## 📌 Status

**Accepted specification — not implemented or verified.**

# Non-Functional and Security Contract

## 🔍 Overview

Diagnostic completeness is subordinate to Tomcat availability. All work is
bounded and the service degrades explicitly when evidence or host capacity is
unavailable.

## 📏 Pilot Limits

| Control | Initial limit |
| --- | ---: |
| Diagnostic workers | 1 |
| Accepted-work queue | 50 |
| Diagnostic timeout | 60 seconds |
| Container memory limit | 256 MiB |
| Container CPU limit | 500 millicores |
| Idle memory target | 64 MiB |
| Idle CPU target | 10 millicores |
| Webhook request | 256 KiB |
| Log lines/input | 500 lines / 512 KiB |
| Persisted evidence summary | 256 KiB per incident |
| SQLite target/hard size | 100 MiB / 250 MiB |

When host CPU exceeds 90%, available memory is below 512 MiB, or approved
filesystem availability is below 5%, optional metric and log work is skipped.
The service emits a partial evidence-only result. Thresholds require cooldown
or hysteresis before optional work resumes.

## 🔐 Security Boundary

- Webhook uses strict TLS, bearer authentication, a dedicated internal network,
  no host port, a 256 KiB limit, and schema validation.
- Secret and TLS material remain non-Git and read-only.
- Diagnostic Service has no broad Podman socket, host namespace, arbitrary
  command, runtime-control, or arbitrary-path access.
- Evidence paths and target mapping come only from local allowlisted
  configuration.
- Collector spool and Tomcat evidence mounts are read-only to the service.
- Untrusted labels, annotations, logs, and artifacts are sanitized before
  persistence, logs, metrics labels, and notifications.
- Production contains no LLM runtime, vector database, continuous log index,
  message broker, or separately administered database.

## 🩺 Health and Metrics

Liveness only indicates the process can run. Readiness requires valid
configuration, successful schema migration, writable SQLite below its hard
limit, and ability to durably accept work. Missing optional evidence sources do
not fail readiness.

Metrics cover accepted/rejected/duplicate events, queue depth, processing and
collection duration, result status, unavailable sources, notification result,
SQLite size, housekeeping, capacity shedding, and identity rejections. Metrics
must not expose sensitive label or evidence content.

## 📌 Status

**Accepted limits — representative resource tests have not been run.**

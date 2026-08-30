# Alertmanager Webhook Contract

## 🔍 Overview

Alertmanager pushes standard webhook schema version `4` events to the
Diagnostic Service. Each alert item is validated, normalized, persisted, and
processed independently.

## 🔗 Endpoint

```http
POST /api/v1/alerts/alertmanager
Content-Type: application/json
Authorization: Bearer <token>
```

The accepted lab service URL is:

```text
https://diagnostic-service:8443/api/v1/alerts/alertmanager
```

The endpoint is available only on a dedicated internal container network and
has no host-published port. Alertmanager validates the service CA. The bearer
token and CA material are mounted read-only from non-Git storage.

## 📥 Required Data

Required top-level fields are `version`, `groupKey`, `status`, `receiver`, and a
non-empty `alerts` array. Required per-alert fields are:

- `status`, with `firing` or `resolved`;
- `labels` and `annotations`;
- `startsAt` and `endsAt`;
- Alertmanager `fingerprint`.

Required labels for `TomcatDown` are `alertname`, `severity`, `environment`,
`host`, `tomcat_instance`, `job`, `instance`, `service`, and `check`.
`application` is optional supporting context.

The service rejects an identity that does not match its local target allowlist.
Annotations are untrusted presentation data and cannot select paths, commands,
containers, evidence sources, or configuration.

## 🆔 Event Identity

The alert fingerprint pairs firing and resolved states. Idempotency uses:

```text
event_key = fingerprint + status + event_time
```

`event_time` is `startsAt` for firing and `endsAt` for resolved. `groupKey` is
stored for observability but is not an incident identity.

## 🔄 Processing

1. Authenticate the request and enforce `application/json` plus the 256 KiB
   request limit.
2. Validate schema version, fields, timestamps, labels, and allowlisted target.
3. Normalize each alert independently and calculate its event key.
4. Persist the accepted event in SQLite with a uniqueness constraint.
5. Return `202 Accepted` only after the transaction commits.
6. Queue diagnostic work for the single worker.

Metrics queries, evidence collection, and notification delivery do not hold the
webhook connection open.

## 🌐 Response Contract

| Status | Meaning |
| ---: | --- |
| `202` | Authenticated events were durably accepted |
| `400` | Invalid JSON, schema, timestamp, or required identity |
| `401` | Missing or invalid bearer token |
| `413` | Request exceeds 256 KiB |
| `415` | Content type is not `application/json` |
| `429` | Queue capacity prevents safe acceptance |
| `503` | Service or SQLite cannot durably accept work |

Duplicate delivery returns a controlled accepted/duplicate response and does
not repeat diagnostic or notification work.

## 🔐 Security

- TLS certificate verification and bearer authentication are both required.
- Secrets, token values, and raw authorization headers are never logged or
  stored in SQLite.
- Request data cannot select a filesystem path or executable action.
- Request, parsing, SQLite, queue, and downstream operations use bounded
  timeouts.
- Unsupported alert names are recorded as unsupported and do not activate a
  deferred diagnostic rule.

## 📌 Status

**Accepted contract — not implemented or verified.**

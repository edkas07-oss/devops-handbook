# Target and Evidence Contract

## 🔍 Overview

Diagnostic evidence is accepted only when it resolves to one explicitly
configured Tomcat target. This prevents evidence crossing between containers,
hosts, environments, or recreated runtime generations.

## 🆔 Canonical Identity

The canonical identity is:

```text
environment + host + tomcat_instance
```

The first lab identity is:

```text
lab + edkas-pc1 + tomcat-jmx-exporter
```

`job` and `instance` are technical endpoint labels and do not replace the
logical identity. Application identity and health-probe location are optional
target configuration used as supporting evidence.

The local allowlist maps the canonical identity to trusted values such as the
Prometheus selector, container identity, generation marker, log source, crash
artifact directory, application-health query, and collector spool partition.
The webhook cannot override these mappings.

## 📦 Evidence Object

Every evidence item contains:

- stable `evidence_id`, `source`, and normalized `type`;
- canonical `target_id` and, when available, runtime generation;
- UTC `observed_at` and collection timestamp;
- collection status: `collected`, `not_found`, `no_data`, `unavailable`,
  `timeout`, `unauthorized`, `not_configured`, or `invalid_response`;
- strength: `direct`, `supporting`, or `contextual`;
- bounded typed value and redaction state.

`not_found` means the source was successfully checked. It is distinct from
`unavailable` and `not_configured`.

## 🔎 Evidence Isolation

- Prometheus queries include the allowlisted target selector.
- Log and crash reads use configured directories and reject symlink escape,
  traversal, and path values supplied by events.
- Collector records carry the same target identity and generation.
- Timestamp windows are bounded and evaluated in UTC.
- A container ID or start timestamp mismatch prevents correlation with an
  earlier generation unless an explicit lifecycle event connects them.
- Evidence outside the identity or time window is excluded and recorded as an
  isolation rejection metric.

## 🧹 Redaction and Bounds

Credentials, tokens, cookies, session identifiers, request bodies, and
unbounded stack traces are excluded or redacted before persistence. One
incident may read at most 500 log lines and 512 KiB of log input and persist at
most 256 KiB of summarized evidence.

## 📌 Status

**Accepted and partially implemented.** Target registry, isolation checks, and
bounded evidence adapters have source-test evidence. Environment allowlist,
real evidence mounts, restricted collector, and end-to-end isolation remain
unverified.

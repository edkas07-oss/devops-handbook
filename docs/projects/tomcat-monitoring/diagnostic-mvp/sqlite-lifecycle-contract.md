# SQLite Lifecycle Contract

## 🔍 Overview

SQLite menjadi local durable state store satu Diagnostic Service per Tomcat
host. Ia menyimpan event identity, incident lifecycle, bounded canonical
result, dan delivery state; bukan raw log archive atau monitoring database.

## 💾 Storage Contract

| Item | Pilot value |
| --- | --- |
| Named volume | `diagnostic_data` |
| Database path | `/var/lib/tomcat-diagnostic/diagnostic.db` |
| Journal mode | WAL |
| Writer model | One service, one worker, single logical writer |
| Target size | 100 MiB |
| Hard limit | 250 MiB |

Schema initialization and forward migration run automatically before readiness.
A failed migration prevents webhook acceptance. An accepted event transaction
commits before HTTP `202` is returned, and event keys have a uniqueness
constraint that survives restart.

## 🔄 Retention and Housekeeping

- Active incidents remain until a resolved event is recorded.
- Resolved normalized events, canonical results, evidence summaries, and
  delivery state remain for 30 days.
- Raw webhook bodies are discarded after validated normalization.
- Hourly and startup housekeeping perform retention deletion, WAL checkpoint,
  integrity/capacity checks, and incremental vacuum where needed.
- At the 100 MiB target, oldest eligible resolved records are removed first.
- Active incident state is never deleted automatically for capacity recovery.
- At 250 MiB, if safe housekeeping cannot recover capacity, readiness fails and
  new webhooks receive `503` until capacity is restored safely.

Named-volume removal, database deletion, manual repair, export, or recovery is
an exact-target destructive/operational action requiring separate approval.
Backup and production disaster recovery are outside the pilot.

## 📋 Minimum Logical Data

The physical schema must represent schema migrations, requests, events,
incidents, target identity, canonical results, evidence summaries,
custom rules (`custom_rules` with unique branches), notification attempts,
deduplication keys, and housekeeping state. Physical tables and indexes are
finalized during implementation design.

## ✅ Acceptance

Tests must cover empty-volume initialization, migration failure, commit before
`202`, restart deduplication, firing/resolved correlation, WAL recovery,
retention, target and hard capacity thresholds, and protection of active
incidents.

## 📌 Status

**Accepted and partially implemented.** Migrations, durable ingestion,
deduplication, queue, canonical results, and disposable database lifecycle have
source/image evidence. Persistent named-volume restart, housekeeping,
retention, capacity, corruption, and recovery behavior remain unverified.

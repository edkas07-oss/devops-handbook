# TM-ADR-0009

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0009 |
| **Title** | Use SQLite for Local Diagnostic State |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Data Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Each host-local Diagnostic Service uses SQLite for durable event, incident,
canonical-result, deduplication, and delivery state.

## 🌍 Context

Webhook acceptance must survive restart, pair firing with resolved events, and
avoid duplicate work. The pilot has one worker and does not need a separately
administered database.

## ⚖️ Decision

SQLite runs in WAL mode on named volume `diagnostic_data`. Initialization,
migration, checkpoint, retention, and incremental vacuum are automatic. Data
targets 100 MiB and cannot exceed a 250 MiB acceptance boundary. Active
incident state is never automatically deleted for capacity recovery.

## 🏛️ Architecture

The service commits a unique normalized event transaction before returning
`202`, then processes it asynchronously through one worker.

## 💡 Rationale

SQLite provides transactional restart-persistent local state with low resource
and operational overhead. In-memory state cannot survive restart; an external
database is disproportionate for the pilot.

## ⚠️ Consequences

Active-active service deployment is excluded. Schema migration, corruption,
capacity, and volume recovery behavior require explicit testing.

## 📌 Status

**Accepted — physical schema and implementation pending.**

## 📅 Date

**2026-08-30**

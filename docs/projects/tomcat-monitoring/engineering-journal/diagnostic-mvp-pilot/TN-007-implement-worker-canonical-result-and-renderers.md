# TN-007 — Implement Worker, Canonical Result, and Renderers

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Mengubah durable queue item menjadi persisted canonical result melalui satu
worker, lalu membentuk plain-text/HTML content dan operational state tanpa HTTP
atau SMTP runtime.

## 📚 Scope

Migration `002`, single worker, 60-second deadline, canonical result v1,
deterministic hash, material-change guard, persistence, health/metrics model,
seven-section renderers, tests, validator, README, dan current-state docs.
HTTP/TLS, SMTP, Mailpit runtime, image, deployment, commit, dan push excluded.

## 📋 Prerequisites

| Item | State |
| --- | --- |
| TN-005/TN-006 source | Commit `aa55170`, synchronized with `origin/main` |
| Node runtime | Local image `localhost/nodejs:24.18.0` |
| Tests | Temporary container and SQLite only |

## 🧭 Implementation Plan

```text
durable queue -> single worker -> bounded evidence -> TD rule
              -> canonical result v1 -> SQLite -> text/HTML renderer
```

## ⚙️ Implementation

<div class="procedure" markdown>
<div class="procedure-step" markdown>

### Add Result Persistence

`002-canonical-results.sql` adds `canonical_results`, bounded
`evidence_summaries`, and one material-update counter per incident. Repository
methods load the queued event, persist result/evidence, and atomically reserve
the only allowed material update.

!!! success "Expected Result"

    Result and evidence commit before queue state becomes completed.

**Actual Result:** Temporary-SQLite integration test proves one result,
completed queue state, and first-true/second-false update reservation.

</div>
<div class="procedure-step" markdown>

### Build and Render the Canonical Result

Canonical result validates processing status and classification/confidence,
sorts evidence, records unavailable sources, and hashes stable content while
excluding volatile timing. Text and HTML share seven ordered sections; HTML
escapes untrusted values.

!!! success "Expected Result"

    Same semantic input produces the same hash and both renderers preserve the
    accepted message order without strengthening the assessment.

**Actual Result:** Hash, material-change, confidence rejection, order, and HTML
escaping tests pass.

</div>
<div class="procedure-step" markdown>

### Run the Single Worker

Worker claims one queue item, applies a 60-second global deadline, evaluates
TD-01–TD-08, persists the canonical result, then completes the queue item.
Failure marks the item failed. Health/metrics state contains only bounded
operational labels.

!!! success "Expected Result"

    Exactly one item is processed and no deadline timer remains active after
    evidence completes.

**Actual Result:** First run hung because the losing `Promise.race` timer was
not cleared. The process was terminated, leaving the temporary container.
Worker was changed to clear the timer in `finally`; the exact stale container
was removed after approval and tests were repeated.

</div>
<div class="procedure-step" markdown>

### Verify the Complete Source

```bash
./scripts/validate.sh
bash -n scripts/*.sh
podman run --rm --name tomcat-diagnostic-tn007-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

!!! success "Expected Result"

    Existing ingestion/isolation tests and new worker/result/renderer tests all
    pass using only temporary state.

**Actual Result:** Final run passed 22 tests, 0 failed. Container was removed
automatically.

</div>
</div>

## 📁 Artifact Manifest

| Path | Responsibility |
| --- | --- |
| `migrations/002-canonical-results.sql` | Result/evidence persistence and update guard |
| `src/application/diagnostic-worker.js` | Single-worker lifecycle and deadline |
| `src/domain/canonical-result.js` | Schema semantics, hash, material change |
| `src/application/result-renderer.js` | Seven-section text/HTML output |
| `src/application/health-metrics.js` | Liveness, readiness, counters, gauges |
| `src/adapters/sqlite-repository.js` | Queue-event load and result persistence |
| `test/unit/canonical-result.test.js` | Hash, validation, render order, escaping |
| `test/unit/health-metrics.test.js` | Operational state without sensitive labels |
| `test/integration/diagnostic-worker.test.js` | Queue-to-result transaction lifecycle |

## 🧪 Test Scenario Matrix

| Boundary | Scenarios |
| --- | --- |
| Worker | Single claim, persistence before completion, timer cleanup |
| Canonical result | Stable hash, valid confidence, material change |
| SQLite | Migration 002, evidence rows, one update reservation |
| Renderer | Seven-section order and HTML escaping |
| Health/metrics | Live/ready state, counter/gauge, no target label |
| Regression | All TN-005/TN-006 tests remain passing |

## 🖥️ Commands Executed

Chronological commands are shown in procedure. Failed-run cleanup was:

```bash
podman rm -f tomcat-diagnostic-tn007-node
```

The test command ran three times: the first was terminated due to the timer
bug, the second passed 21 tests, and the final run passed 22 after adding
material-update and health/metrics coverage. Source files were created through
workspace patches, not shell mutation.

Source-control handoff kemudian diotorisasi dan dijalankan:

```bash
git add README.md scripts/validate.sh migrations/002-canonical-results.sql \
  src/adapters/sqlite-repository.js src/application/diagnostic-worker.js \
  src/application/health-metrics.js src/application/result-renderer.js \
  src/domain/canonical-result.js test/integration/diagnostic-worker.test.js \
  test/unit/canonical-result.test.js test/unit/health-metrics.test.js
git diff --cached --check
git commit -m "feat(diagnostic-service): persist and render canonical results"
```

Actual result adalah commit `1ea79fa`. Commit belum dipush pada closure TN-007.

## 🧭 Reproduction Guide

```bash
git checkout 1ea79fa
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn007-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Expected result adalah static validation passed dan 22 tests passed. Gunakan
clean clone/worktree sebelum checkout agar perubahan lokal tidak tertimpa.

## ✅ Verification

| Method | Expected | Actual |
| --- | --- | --- |
| Static validator and Bash syntax | Source contract valid | Passed |
| `npm test` in Node.js 24.18.0 | New and regression scenarios pass | 22 passed |
| Runtime integration | HTTP, SMTP, Mailpit behavior | Not verified; excluded |

## 🧾 Outcome

Queue-to-canonical-result processing, persistence, material-update guard,
operational state, and notification rendering are implemented and locally
tested. Network delivery and service endpoints remain unimplemented.

## ⏭️ Next Steps

Implement HTTP/TLS service interfaces, bearer authentication, request limits,
health/metrics endpoints, and SMTP delivery; then build and run disposable
component verification under separate authorization.

## 🔗 Related Documentation

- [TN-006](TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md)
- [Diagnostic Result Contract](../../diagnostic-mvp/diagnostic-result-and-confidence-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)

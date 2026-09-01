# TN-012 — Implement Bounded Notification Delivery Orchestration

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-01 |
| Recorded Date | 2026-09-01 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-01 |

## 🎯 Objective

Menghubungkan canonical result ke renderer dan SMTP adapter dengan lifecycle
notification, persistence, serta retry yang bounded dan dapat diuji.

## 🌍 Background

TN-011 menetapkan runtime contract dan menemukan bahwa renderer, SMTP adapter,
serta tabel `notification_attempts` tersedia tetapi belum terhubung ke worker.
GAP-010 belum menetapkan retry; GAP-016 memblokir Mailpit multi-component test.

## 📚 Scope

Scope yang disetujui meliputi source, schema bila diperlukan, unit/integration/
component tests, validator, README, current-state documentation, dan live
journal. Policy yang diterima: maksimal tiga attempts, backoff 1 dan 5 detik,
maximum age 60 detik, serta existing work queue berkapasitas 50 tanpa queue
kedua.

Verification memakai exact ephemeral container
`tomcat-diagnostic-tn012-test`, immutable Node.js base, dan `--rm`. Tidak ada
image build, Mailpit runtime, network, volume, deployment, commit, atau push.
Disposable multi-component runtime dipindahkan ke TN-013.

## 📋 Prerequisites

| Prerequisite | Actual result |
| --- | --- |
| Diagnostic Service baseline | `3c81a30` |
| Handbook baseline | `7ffaff4` |
| Working trees | Clean saat discovery |
| Renderer, SMTP adapter, migration 003 | Tersedia |
| Retry policy | Disetujui 2026-09-01 |
| Test runtime | Immutable Node.js digest tersedia menurut TN-010; current inspect terhalang sandbox |
| Runtime/cleanup authorization | Exact test container dan `--rm` disetujui |

## ⚖️ Execution Decision

- Canonical result dipersist sebelum SMTP.
- Setiap attempt dicatat `pending`, kemudian diperbarui menjadi `sent` atau
  `failed`; hanya error code bounded yang disimpan.
- Delivery failure tidak mengubah classification atau confidence.
- Initial firing dikirim sekali, duplicate tidak dikirim, material update
  maksimal sekali, dan resolved memakai firing context tanpa mengarang cause.
- Work queue existing menjadi satu-satunya queue; tidak ada delivery worker
  atau concurrency baru.
- Resource runtime yang sebelumnya memakai label TN-012 dipindahkan menjadi
  TN-013 pada current-state contract; TN-011 tetap menjadi historical record.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Catat Baseline** | Catat source, contract, authorization, gap, dan failed discovery. |
| **Implementasikan Notification Lifecycle** | Tambahkan decision, persistence, renderer/SMTP wiring, retry, dan metrics. |
| **Verifikasi Source dan Socket** | Jalankan validator, regression, component tests, dan exact cleanup check. |
| **Konsolidasikan Dokumentasi** | Perbarui README, contract, gap/traceability, current state, navigation, dan TN. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Catat Baseline

Command material yang telah dijalankan:

```bash
git status --short --branch
git log -2 --oneline --decorate
sed -n '/^## 🧾 Outcome/,$p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md
rg -n 'GAP-010|GAP-016|retry|notification|TN-012|TN-013' docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot
rg --files src test migrations config
rg -n 'render|material_update|notification_attempt|recordNotificationAttempt|reserveMaterialUpdate|lifecycleStatus|resultHash' src test migrations config
```

Review juga memakai `sed` pada application, worker, repository, renderer,
SMTP adapter, migrations, schema, tests, serta notification/rule contracts.

**Actual Result:** Baseline dan gap terpetakan. `saveCanonicalResult()` belum
mengembalikan result ID; lifecycle notification dan retry belum tersedia.

!!! success "Expected Result"

    Implementation dimulai dari exact baseline dan accepted policy.

</div>

<div class="procedure-step" markdown>

### Implementasikan Notification Lifecycle

Perubahan manual memakai `apply_patch`. Implementasi menambahkan coordinator
retry, wiring application/worker, result-ID handoff, lookup firing result,
attempt transition, atomic material/resolved reservation, migration 004,
metrics, serta unit/integration/socket scenarios.

Review setelah test awal menemukan duplicate resolved dengan `endsAt` berbeda
masih dapat mengirim ulang. Resolution menambahkan
`resolved_notification_count` dan atomic reservation; migration expectations
serta image-static checks diperbarui.

**Actual Result:** Initial firing, satu material update, exactly one resolved,
resolved tanpa firing, bounded retry, sanitized error code, dan result-before-
delivery persistence diimplementasikan tanpa dependency atau queue baru.

!!! success "Expected Result"

    Source mengirim notification sesuai lifecycle dan merekam retry bounded.

</div>

<div class="procedure-step" markdown>

### Verifikasi Source dan Socket

Static checks dijalankan berulang setelah source berubah:

```bash
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
```

Regression dan component command memakai exact container yang sama:

```bash
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn012-test$)" && \
podman run --rm --name tomcat-diagnostic-tn012-test --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d \
  npm test && \
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn012-test$)"

test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn012-test$)" && \
podman run --rm --name tomcat-diagnostic-tn012-test --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d \
  npm run test:component && \
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn012-test$)"
```

**Actual Result:** Final regression 36 passed, 0 failed/skipped. Component
suite 2 passed dan 2 skipped; skip adalah TLS/config scenarios lama yang
memerlukan external certificate fixture. SMTP adapter socket dan new complete
worker-to-SMTP socket scenario passed. Exact container absent setelah setiap
`--rm`.

Final source verification diulang pada 2026-09-02 terhadap working tree yang
sama. Bash/static checks, 36 regression tests, 2 SMTP component scenarios, dan
exact cleanup kembali menghasilkan result yang sama; dua external-fixture
scenarios tetap terlihat sebagai skipped.

!!! success "Expected Result"

    Static validation, regression, socket component, dan cleanup lulus.

</div>

<div class="procedure-step" markdown>

### Konsolidasikan Dokumentasi

README, runtime/notification contracts, gap register, traceability,
current-state pages, phase navigation, dan TN-012 diperbarui dengan
`apply_patch`. Runtime resource prefix berpindah dari TN-012 ke TN-013.

**Actual Result:** GAP-010 dan GAP-016 ditutup berdasarkan source/socket
evidence. TN-010 image dinyatakan stale terhadap TN-012 source; rebuilt image,
Mailpit, dan runtime tetap tidak diklaim.

!!! success "Expected Result"

    Current state, gaps, evidence, dan next runtime boundary konsisten.

</div>

</div>

## 🛠️ Troubleshooting

| Attempt | Actual result | Resolution |
| --- | --- | --- |
| Membaca `src/presentation/diagnostic-renderer.js` | Path tidak ada | Renderer ditemukan di `src/application/result-renderer.js` |
| Menjalankan `node --version` pada host | `node` tidak tersedia | Test akan memakai immutable Node.js container |
| Inspect image Node.js dalam sandbox | Podman metadata read-only | Gunakan authorized container execution saat verification |
| Regression Podman pertama dalam sandbox | Sticky-bit metadata gagal pada read-only runtime path | Rerun authorized di luar restricted sandbox; 36 tests passed |
| Component run pertama | SMTP passed; dua TLS/config tests skipped | Tambahkan worker-to-SMTP socket scenario; final 2 passed, 2 fixture-dependent skipped |
| Lifecycle review setelah test | Resolved event berbeda dapat mengirim lebih dari sekali | Tambahkan migration 004 dan atomic resolved reservation; rerun passed |

## ⚙️ Commands Executed

Command aktual ditempatkan pada procedure sesuai chronology. Tidak ada command
yang menulis source; perubahan memakai `apply_patch`. Podman commands hanya
membuat exact ephemeral test container dengan automatic `--rm`.

## 📁 Artifact Manifest

| Artifact | Responsibility |
| --- | --- |
| `src/application/notification-delivery.js` | Retry policy, bounded error code, attempt orchestration, dan metrics |
| `src/application/diagnostic-worker.js` | Firing/material/resolved decision, render, dan delivery handoff |
| `src/application/application.js` | SMTP dan notification coordinator wiring |
| `src/adapters/sqlite-repository.js` | Result ID, prior firing lookup, attempt transition, dan atomic reservations |
| `migrations/004-notification-lifecycle.sql` | Exactly-one resolved notification state |
| Unit/integration/component tests | Retry, lifecycle, persistence, dan actual SMTP socket evidence |
| Validator/image scripts dan README | Source manifest, migration expectation, dan public contract |
| Handbook contract/current-state/TN | Accepted policy, evidence, gaps, dan TN-013 handoff |

## 🧪 Test-Scenario Matrix

| Scenario | Layer | Actual result |
| --- | --- | --- |
| Three attempts with 1/5-second backoff | Unit | Passed |
| Maximum age stops an ineligible retry | Unit | Passed |
| SMTP error is reduced to bounded code | Unit | Passed |
| Initial firing and identical-result suppression | Integration | Passed |
| Maximum one material update | Integration | Passed |
| Exactly one resolved notification | Integration | Passed after migration 004 resolution |
| Resolved without stored firing | Integration | Passed; explicit undetermined result |
| Attempt persistence and queue completion | Integration | Passed |
| SMTP adapter actual socket | Socket component | Passed |
| Worker → SQLite → renderer → SMTP socket | Socket component | Passed |
| Existing TLS/config component fixtures | Socket component | 2 skipped; external fixtures not supplied |
| Mailpit, image, dan persistent runtime | Runtime | Not run; excluded |

## ✅ Verification

| Method | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| `./scripts/validate.sh` | Source/dependency/migration boundary konsisten | Passed | Validator output |
| `bash -n scripts/*.sh` | Seluruh Bash valid | Passed | Exit `0` |
| `npm test` via immutable container | Seluruh regression lulus | 36 passed, 0 failed/skipped | Node test output |
| `npm run test:component` via immutable container | SMTP scenarios lulus; unavailable fixtures terlihat | 2 passed, 2 skipped | Node test output |
| Exact cleanup check | Container absent | Passed | `podman ps -aq` dan final `test !` |
| Documentation checks | Diff, heading, link, navigation, whitespace valid | Passed; MkDocs CLI unavailable |

## 🖥️ Source-Control Handoff

Setelah technical closure, project owner memberikan authorization terpisah
untuk commit. Staging memakai exact TN-012 source manifest, lalu dijalankan:

```bash
git diff --cached --check
git commit -m "feat(diagnostic-service): add bounded notification delivery"
```

**Actual Result:** Source commit `84c42c1`. Push tidak dilakukan.

## 🧹 Cleanup Evidence

`tomcat-diagnostic-tn012-test` dibuat hanya oleh `podman run --rm` dan absent
setelah setiap failed/successful command. Tidak ada network, named volume,
host temporary directory, certificate, database, atau image baru. Final
read-only cleanup query menghasilkan `container_absent=true`.

## 🧭 Reproduction Boundary

Source baseline adalah `3c81a30` dan final TN-012 commit adalah `84c42c1`.
Reproduction memerlukan commit tersebut, immutable Node.js digest, dan commands
di atas. TN-010 image tidak memuat TN-012 source; image/Mailpit/runtime
reproduction menjadi TN-013.

## 🧾 Outcome

Completed. Notification lifecycle dan bounded retry diimplementasikan dengan
result-before-delivery persistence, maximum one material update, exactly one
resolved notification, sanitized attempt state, serta no-second-queue
boundary. Static/Bash checks, 36 regression tests, dan 2 SMTP socket component
tests lulus. Dua TLS/config component scenarios tidak dijalankan karena
external fixtures tidak tersedia. Exact container dibersihkan; image, Mailpit,
dan persistent runtime tidak dibuat. Source telah dicommit sebagai `84c42c1`;
push tidak dilakukan.

## ⏭️ Next Steps

Siapkan approved TN-013 untuk rebuild image dari exact TN-012 revision dan
disposable Diagnostic Service–Mailpit verification. Persistent deployment dan
actual Alertmanager route tetap memerlukan scope terpisah.

## 🔗 Related Documentation

- [TN-011](TN-011-define-diagnostic-service-runtime-configuration-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)
- [Runtime Contract](../../diagnostic-mvp/runtime-configuration-and-verification-contract.md)
- [Gap Register](../../diagnostic-mvp/gap-register.md)

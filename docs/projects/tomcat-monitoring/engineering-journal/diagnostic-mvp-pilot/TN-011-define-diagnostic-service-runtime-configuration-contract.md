# TN-011 — Define Diagnostic Service Runtime Configuration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
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

Menetapkan kontrak konfigurasi runtime milik integration owner, konsumsi image
immutable, kepemilikan artifact, dan verifikasi multi-component disposable
sebelum persistent deployment.

## 🌍 Background

TN-010 menghasilkan commit `611a83d` dan image digest
`sha256:a849a9e39a49ffcacb11733b0ad19e5e5f29c10451f8fd284f2b218f71c2dff1`.
Konfigurasi mounted, HTTPS, migrasi SQLite, metrics, dan SIGTERM telah lulus
disposable image test. Path integration, permission, secret boundary, topology
Mailpit, dan cleanup lintas component belum ditetapkan.

Project owner menyetujui plan dokumentasi TN-011 setelah discovery read-only.
Approval tidak mencakup perubahan source, build image, resource runtime,
cleanup, commit, atau push.

## 📚 Scope

Scope yang disetujui:

- review read-only source, ADR, contract Diagnostic MVP, runtime Node.js, dan
  ownership Mailpit;
- contract konfigurasi runtime dan disposable verification;
- panduan konsumsi pada README Diagnostic Service;
- konsolidasi current state, gap, traceability, navigation, dan TN-011; serta
- verifikasi dokumentasi dan static validation.

Source/schema implementation, repository `tomcat-monitoring`, build atau pull
image, container test, network, volume, database, deployment, external SMTP,
perubahan Alertmanager/Prometheus, cleanup mutation, commit, dan push tidak
termasuk scope.

## 📥 Inputs

| Input | Evidence |
| --- | --- |
| TN-010 | Revision, image ID/digest, verification, cleanup, dan next step |
| Source aplikasi | Schema v1, loader, startup, worker, renderer, SMTP adapter, dan migration |
| Arsitektur | TM-ADR-0005, TM-ADR-0009, TM-ADR-0010, TM-ADR-0012, dan TM-ADR-0013 |
| Contract | Webhook, target/evidence, SQLite, notification, dan NFR |
| Runtime | Diagnostic Service, Node.js, integration repository, non-Git storage, dan Mailpit |

## 📋 Prerequisites

| Prerequisite | Actual result |
| --- | --- |
| Source Diagnostic Service `611a83d` | Satisfied |
| Identity image TN-010 tersedia | Satisfied |
| ADR terkait berstatus Accepted | Satisfied |
| Schema, loader, lifecycle, migration, renderer, dan SMTP adapter dapat direview | Satisfied |
| Owner service, integration, secret, storage, dan Mailpit dapat dibedakan | Satisfied |
| Plan dokumentasi-only disetujui | Satisfied pada 2026-09-01 |
| Authorization runtime | Tidak diperlukan dan tidak diminta |

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Catat Baseline** | Catat revision, batas remote, image, authorization, dan exclusion. |
| **Tetapkan Contract Runtime** | Tetapkan path, value, permission, owner, image, topology, dan cleanup gate. |
| **Konsolidasikan Current State** | Perbarui README, project pages, gap, traceability, dan navigation. |
| **Verifikasi dan Tutup** | Periksa diff, whitespace, heading, link, navigation, dan MkDocs bila tersedia. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Catat Baseline

Command aktual pada kedua repository:

```bash
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
git log -1 --oneline --decorate
sed -n '1,260p' AGENTS.md
rg --files
git diff --stat
git diff --name-status
git ls-remote --heads origin main
git ls-remote origin refs/heads/main
```

`git ls-remote` mencapai Gitea tetapi gagal karena username non-interaktif
tidak tersedia. Live remote berstatus `Not verified`; local `HEAD` dan
`origin/main` sama. Review `sed` dan `rg` mencakup README, `CONFIG`,
`Containerfile`, schema/loader, startup/worker/SMTP, TN-010, ADR, dan contract.

Inspect image pertama gagal karena sandbox tidak dapat menulis metadata Podman.
Retry read-only yang disetujui berhasil:

```bash
podman image inspect \
  localhost/tomcat-diagnostic-service@sha256:a849a9e39a49ffcacb11733b0ad19e5e5f29c10451f8fd284f2b218f71c2dff1 \
  --format 'id={{.Id}} digest={{.Digest}} user={{.Config.User}} workdir={{.Config.WorkingDir}} cmd={{json .Config.Cmd}}'
```

**Actual Result:** Baseline awal bersih: Diagnostic Service `611a83d` dan
handbook `4a40288`. Image ID/digest, user `node`, workdir `/app`, dan command
sesuai TN-010. Handoff berikutnya berisi hanya perubahan TN-011 dan dipertahankan.

!!! success "Expected Result"

    Revision, image, repository boundary, authorization, dan batas remote
    tercatat sebelum perubahan.

</div>

<div class="procedure-step" markdown>

### Tetapkan Contract Runtime

Contract dibuat dengan `apply_patch`; tidak ada shell command yang menulis
file. Contract menetapkan value, path, mode, owner, immutable reference, nama
resource disposable, layer verifikasi, dan cleanup gate.

Review menemukan `SmtpAdapter`, renderer, dan tabel notification telah ada,
tetapi belum terhubung ke `DiagnosticApplication` dan `DiagnosticWorker`.
Kondisi ini dicatat sebagai prerequisite source, bukan capability runtime.

**Actual Result:** Contract ditambahkan. Persistent target tetap named volume
`diagnostic_data`; TN-012 menggunakan temporary bind agar cleanup memiliki
exact target tanpa membuat named volume.

!!! success "Expected Result"

    Seluruh path, mode, permission, owner, image, verification layer, dan
    blocker memiliki contract eksplisit.

</div>

<div class="procedure-step" markdown>

### Konsolidasikan Current State

README, navigation Diagnostic MVP, gap/traceability, phase navigation, dan
project pages diperbarui dengan `apply_patch`.

**Actual Result:** Dokumentasi membedakan capability source, disposable image
evidence, accepted runtime contract, dan runtime yang belum diverifikasi.

!!! success "Expected Result"

    Public contract dan current-state pages menyampaikan status yang konsisten.

</div>

<div class="procedure-step" markdown>

### Verifikasi dan Tutup

Command aktual pada Diagnostic Service:

```bash
./scripts/validate.sh && git diff --check && git status --short --branch && git diff --stat
```

Command aktual pada handbook:

```bash
git diff --check
if rg -n '[[:blank:]]+$' \
  docs/projects/tomcat-monitoring/diagnostic-mvp/runtime-configuration-and-verification-contract.md \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md; then
  exit 1
fi
test -f docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-010-build-and-verify-diagnostic-service-image.md
test -f docs/projects/tomcat-monitoring/diagnostic-mvp/runtime-configuration-and-verification-contract.md
test -f docs/projects/tomcat-monitoring/diagnostic-mvp/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0009.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0010.md
rg -n '^## |^### ' \
  docs/projects/tomcat-monitoring/diagnostic-mvp/runtime-configuration-and-verification-contract.md \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md
rg -n 'runtime-configuration-and-verification-contract.md|TN-011-define-diagnostic-service-runtime-configuration-contract.md' \
  docs/projects/tomcat-monitoring/diagnostic-mvp/.pages \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages \
  docs/projects/tomcat-monitoring/diagnostic-mvp/index.md \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md
if command -v mkdocs >/dev/null 2>&1; then
  mkdocs build --strict --site-dir /tmp/tomcat-monitoring-tn011-site
else
  echo 'MkDocs CLI not available; render validation not run.'
fi
git status --short --branch
git diff --stat
```

**Actual Result:** Static validation, `git diff --check`, trailing-whitespace,
heading, file-target, dan navigation checks passed. MkDocs CLI tidak tersedia;
render tidak dijalankan dan dependency tidak dipasang.

!!! success "Expected Result"

    Seluruh pemeriksaan lulus atau tercatat `Not run` tanpa mutation runtime.

</div>

</div>

## 🛠️ Troubleshooting

| Attempt | Actual result | Resolution |
| --- | --- | --- |
| Live `git ls-remote` | Username Gitea tidak tersedia | Remote live `Not verified`; local ref dilaporkan terpisah |
| Inspect Podman dalam sandbox | Metadata runtime tidak dapat ditulis | Retry read-only yang disetujui berhasil; image tidak berubah |
| Pemeriksaan MkDocs | CLI tidak tersedia | Render `Not run`; dependency tidak dipasang |

## 🔍 Findings

| Finding | State | Consequence |
| --- | --- | --- |
| Schema v1 memuat seluruh field TN-011 | Verified | Tidak perlu perubahan schema/source |
| Loader mewajibkan absolute path dan mounted secret file | Verified | Integration dapat memakai bounded container path |
| Image tidak membawa config, certificate, secret, allowlist, atau SQLite | Verified | Runtime mount tetap milik integration |
| SMTP belum terhubung ke worker lifecycle | Verified | Mailpit test menunggu implementation source |
| Retry SMTP belum diputuskan | Open | GAP-010 tetap terbuka |
| Local ref sama, remote live memerlukan credential | Observed | Push/alignment remote tidak diklaim |

## ⚠️ Risks

| Risk | Control |
| --- | --- |
| Mutable tag memilih bytes berbeda | Gunakan exact digest |
| Parent mount mengekspos material lain | Mount hanya exact file/directory |
| Numeric user berbeda antar-host | Inspect digest dan uji permission sebelum runtime |
| Temporary bind dianggap desain persistent | Pertahankan `diagnostic_data`; bind hanya untuk TN-012 |
| Mailpit dianggap external delivery | Batasi klaim sebagai disposable internal evidence |
| Cleanup mengenai resource lain | Exact name/path, collision check, dan approval terpisah |

## ❓ Open Questions

| Pertanyaan | State | Closure |
| --- | --- | --- |
| Retry attempts, backoff, maximum age, dan queue bounds SMTP | Open | Contract implementation delivery diterima |
| Numeric UID/GID `node` untuk host TN-012 | Open | Exact digest inspect dan permission probe |
| Actual Alertmanager route | Deferred | Configuration dan end-to-end TN terpisah |
| Lifecycle production TLS/SMTP/storage | Deferred | Approval security/platform |

## 🤝 Decision Handoff

Diagnostic Service dikonsumsi dengan exact digest. Artifact environment berada
di `tomcat-monitoring` atau non-Git storage. Mailpit hanya target disposable
internal. Persistent SQLite tetap memakai named volume, terpisah dari temporary
test storage. Arah ini menerapkan TM-ADR-0005, TM-ADR-0009, TM-ADR-0010,
TM-ADR-0012, dan TM-ADR-0013 tanpa keputusan arsitektur baru.

## ⚙️ Commands Executed

| Tahap | Lokasi command |
| --- | --- |
| Catat Baseline | Procedure **Catat Baseline** |
| Tetapkan Contract Runtime | Tidak ada shell write; memakai `apply_patch` |
| Konsolidasikan Current State | Tidak ada shell write; memakai `apply_patch` |
| Verifikasi dan Tutup | Procedure **Verifikasi dan Tutup** |

Command `sed`, `rg`, `rg --files`, `git diff`, `git status`, dan `git log`
digunakan read-only pada input yang tercantum. Command aktual material berada
pada procedure sesuai chronology.

## 📁 Artifact Manifest

| Artifact | Responsibility |
| --- | --- |
| `tomcat-diagnostic-service/README.md` | Panduan immutable image dan mount |
| `runtime-configuration-and-verification-contract.md` | Contract runtime authoritative |
| Contract status, gap, dan traceability pages | Batas evidence dan pekerjaan tersisa |
| Project current-state pages | Ringkasan kondisi berlaku |
| `.pages` dan phase index | Navigation contract dan TN-011 |
| TN-011 | Authorization, chronology, evidence, cleanup, dan handoff |

Tidak ada artifact runtime baru. Application image dan base immutable tetap
menjadi artifact TN-010.

## 🧪 Test-Scenario Matrix

| Scenario | Expected result | Actual result |
| --- | --- | --- |
| Mapping schema/loader | Seluruh field didukung atau deferred | Passed |
| Immutable identity | App, Node.js client, dan Mailpit exact serta traceable | Passed |
| Ownership dan mount | Read-only input serta read-write SQLite jelas | Passed |
| Klaim SMTP | Orchestration yang belum ada tidak dinyatakan verified | Passed |
| Current-state consolidation | Implemented, Accepted, Pending, dan Not verified terpisah | Passed |
| Link, navigation, dan Markdown | Target ada dan static checks lulus | Passed |
| MkDocs render | Build jika CLI tersedia | Not run; CLI unavailable |
| Runtime integration | Tidak menghasilkan klaim runtime | Not run; excluded |

## ✅ Verification

| Method | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| `./scripts/validate.sh` | Source boundary konsisten | Passed | Validator 2026-09-01 |
| `git diff --check` kedua repo | Tidak ada whitespace error | Passed | Exit `0` |
| Scan untracked Markdown | Tidak ada trailing whitespace | Passed | Tidak ada match |
| Heading, target file, dan `.pages` | Heading urut dan entry dapat dijangkau | Passed | `rg` dan `test -f` exit `0` |
| MkDocs strict render | Build bila CLI tersedia | Not run | CLI unavailable; install excluded |
| Runtime tests | Tidak ada klaim runtime | Not run | Excluded |

## 🧹 Cleanup Evidence

TN-011 tidak membuat container, network, volume, database, certificate,
temporary directory, atau generated runtime artifact. Cleanup tidak diperlukan.
Final images TN-010 tetap dipertahankan.

## 🧭 Reproduction Boundary

Review dapat diulang dari Diagnostic Service `611a83d` dan handbook `4a40288`
dengan artifact manifest dan static verification di atas. TN-011 tidak
mereproduksi image build, socket test, Mailpit capture, SQLite restart, atau
persistent runtime. Live remote juga tidak termasuk evidence karena credential
origin tidak tersedia.

## 🧾 Outcome

Completed. Contract path, immutable image, mount/permission, ownership,
disposable topology, verification layer, dan cleanup gate telah diterima serta
dikonsolidasikan. Static dan documentation checks lulus; MkDocs render tidak
dijalankan karena CLI tidak tersedia. Tidak ada source atau runtime state yang
berubah.

## ⏭️ Next Steps

Implementasikan dan uji orchestration notification serta retry pada source.
Setelah itu, siapkan authorization TN-012 dengan exact temporary directory,
image, container, network, mount, port, dan cleanup command sebelum membuat
resource.

## 🔗 Related Documentation

- [TN-010](TN-010-build-and-verify-diagnostic-service-image.md)
- [Kontrak Runtime](../../diagnostic-mvp/runtime-configuration-and-verification-contract.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [TM-ADR-0009](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0009.md)
- [TM-ADR-0010](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)

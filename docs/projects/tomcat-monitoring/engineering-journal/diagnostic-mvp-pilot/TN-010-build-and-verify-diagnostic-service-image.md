# TN-010 — Build and Verify Diagnostic Service Image

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
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-01 |

## 🎯 Objective

Implement, build, dan verify reproducible Diagnostic Service application image
berbasis immutable local Node.js runtime tanpa persistent runtime atau
deployment.

## 🌍 Background

TN-009 menghasilkan source commit `a398349` dengan versioned configuration,
startup lifecycle, 31 regression tests, dan 3 ephemeral component tests.
Application image belum tersedia karena immutable Node.js base identity belum
dibuktikan saat TN-009 ditutup.

Read-only inspection pada 2026-09-01 membuktikan local base berikut:

- reference `localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d`;
- image ID `bccb45bc1e48a07ac6c2cd36f7352bccb555e8b3e6070cbefa727d83d6dee3bc`;
- Node.js `24.18.0`, user `node`, working directory `/app`; dan
- upstream base annotation `sha256:4ba75f835bb8802193e4c114572113d4b26f95f6f094f4b5229d2a77773e0afc`.

## 📚 Scope

Approved scope mencakup source/image lifecycle pada `tomcat-diagnostic-service`,
documentation pada `devops-handbook`, local image build, static image checks,
dan disposable HTTPS/SQLite/signal component verification.

Exact targets:

- images `localhost/tomcat-diagnostic-service:0.1.0` dan `:latest` dipertahankan;
- disposable container `tomcat-diagnostic-tn010-component`; dan
- temporary directory `/tmp/tomcat-diagnostic-tn010-component` dibersihkan.

Persistent container, named volume, deployment, monitoring integration,
perubahan repository `nodejs`, image cleanup, commit, dan push tidak termasuk
scope.

## 📋 Prerequisites

| Prerequisite | Expected state | Initial evidence |
| --- | --- | --- |
| Diagnostic source | Clean `a398349`, aligned with `origin/main` | `git status` dan `git rev-parse` |
| Handbook | Clean `27dc12c`, aligned with `origin/main` | `git status` dan `git rev-parse` |
| Node.js repository | Clean `cc19da4`, aligned with `origin/main` | Read-only inspection |
| Immutable base | Local digest and image ID available | `podman image inspect` |
| Build/runtime authorization | Approved with exact target and cleanup boundary | Project-owner response on 2026-09-01 |

## ⚖️ Execution Decision

Application `Containerfile` memakai local base digest, memasang exact locked
production dependencies, menyalin only runtime artifacts, berjalan sebagai
non-root, dan menetapkan application command dengan mounted configuration.
Image verification dipisahkan dari source tests dan disposable socket runtime.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Record the Approved Baseline** | Mencatat revision, immutable identity, authorization, targets, dan exclusions. |
| **Implement the Image Lifecycle** | Menambahkan Containerfile, ignore contract, build, dan image-test scripts. |
| **Implement Disposable Runtime Verification** | Menambahkan fixture/probe dan orchestration untuk HTTPS, SQLite, metadata, serta signal. |
| **Run Source Verification** | Menjalankan validator, shell syntax, dan regression tests. |
| **Build and Inspect the Image** | Membangun version/latest tags dan memverifikasi immutable ancestry serta runtime content. |
| **Run Disposable Image Verification** | Menjalankan exact temporary component, SIGTERM, SQLite inspection, dan cleanup. |
| **Consolidate Documentation and Close** | Memperbarui README, current state, navigation, manifests, evidence, dan outcome. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Record the Approved Baseline

Commands pada repository utama:

```bash
git status --short --branch && git rev-parse HEAD && git rev-parse origin/main && sed -n '300,440p' README.md 2>/dev/null || true && sed -n '1,240p' AGENTS.md && sed -n '1,220p' CONFIG && sed -n '1,220p' package.json
git status --short --branch && git rev-parse HEAD && git rev-parse origin/main && sed -n '1,460p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md && rg -n "immutable|base identity|image lifecycle|Containerfile|component image|TN-010" docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/development/index.md docs/adr/tomcat-monitoring
```

Command pada repository `nodejs` setelah membaca AGENTS.md:

```bash
git status --short --branch && git rev-parse HEAD && git rev-parse origin/main && sed -n '1,260p' AGENTS.md && rg --files -g '!node_modules/**' | sort && for f in README.md PROJECT VERSION CONFIG Containerfile; do if test -f "$f"; then echo "### $f"; sed -n '1,260p' "$f"; fi; done && rg -n "immutable|digest|identity|24\.18\.0|build|smoke|component" . --glob '*.md' --glob 'CONFIG' --glob 'Containerfile' --glob 'scripts/*.sh'
```

Contract dan local image inspection:

```bash
sed -n '1,180p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md && rg -n "nodejs|Node.js Base|cc19da4|24.18.0-alpine3.24|localhost/nodejs" docs --glob '*.md' | head -200
podman image inspect localhost/nodejs:24.18.0 --format '{{json .}}'
```

!!! success "Expected Result"

    Source revisions, immutable base, approved external targets, dan exclusions
    tersedia sebelum source atau image mutation.

**Actual Result:** Passed. Tidak ada repository `nodejs` change atau image
mutation pada discovery.

</div>

<div class="procedure-step" markdown>

### Implement the Image Lifecycle

`Containerfile`, `.containerignore`, `CONFIG`, build/static-image scripts,
validator, dan README diterapkan melalui `apply_patch`. Build memakai exact
base digest dan image ID, `npm ci --omit=dev`, user `node`, port `8443`, serta
mounted configuration command. Executable bits dan source gate menggunakan:

```bash
git status --short --branch && git diff --check && test ! -e /tmp/tomcat-diagnostic-tn010-component && for f in Containerfile .containerignore scripts/build.sh scripts/test-image.sh scripts/test-image-component.sh test/component/image-runtime-fixture.js test/component/image-runtime-probe.js test/component/image-runtime-database-probe.js; do echo "### $f"; sed -n '1,320p' "$f"; done
rg --files -g '!node_modules/**' | sort && for f in scripts/*.sh .containerignore; do if test -f "$f"; then echo "### $f"; sed -n '1,280p' "$f"; fi; done && sed -n '1,220p' CONFIG && sed -n '1,220p' scripts/validate.sh
chmod 0755 scripts/build.sh scripts/test-image.sh scripts/test-image-component.sh && ./scripts/validate.sh && bash -n scripts/*.sh && podman run --rm --name tomcat-diagnostic-tn010-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
```

!!! success "Expected Result"

    Image lifecycle memakai immutable base, build context mengecualikan test/
    secret/local state, dan source baseline tetap lulus.

**Actual Result:** Passed. Static validation, seluruh shell syntax, dan 31
regression tests lulus sebelum build.

</div>

<div class="procedure-step" markdown>

### Implement Disposable Runtime Verification

Fixture, HTTPS probe, SQLite probe, dan exact-container orchestration diterapkan
melalui `apply_patch`. Script memakai trap untuk menghapus hanya
`tomcat-diagnostic-tn010-component`; temporary directory tetap di bawah kontrol
caller sampai cleanup evidence dicatat.

!!! success "Expected Result"

    Verification dapat membuktikan mounted configuration, HTTPS endpoints,
    migration, SIGTERM, dan cleanup tanpa named volume atau network baru.

**Actual Result:** Implemented. Dua runtime issue ditemukan dan diselesaikan
pada execution step **Run Disposable Image Verification**.

</div>

<div class="procedure-step" markdown>

### Run Source Verification

Source gate aktual:

```bash
chmod 0755 scripts/build.sh scripts/test-image.sh scripts/test-image-component.sh && ./scripts/validate.sh && bash -n scripts/*.sh && podman run --rm --name tomcat-diagnostic-tn010-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
```

!!! success "Expected Result"

    Validator, Bash syntax, dan regression tests lulus tanpa application image.

**Actual Result:** Passed: 31 tests, 0 failed, 0 skipped, 286 ms.

</div>

<div class="procedure-step" markdown>

### Build and Inspect the Image

Initial build berhasil, tetapi image-static test gagal tanpa output. Inspection
membuktikan `org.opencontainers.image.base.name` kosong karena `ARG BASE_IMAGE`
sebelum `FROM` tidak berada pada stage scope. `ARG BASE_IMAGE` dideklarasikan
ulang setelah `FROM`, lalu exact tags dibangun ulang.

```bash
./scripts/build.sh
./scripts/test-image.sh && podman image inspect localhost/tomcat-diagnostic-service:0.1.0 --format '{{json .}}'
podman image inspect localhost/tomcat-diagnostic-service:0.1.0 --format 'user={{.Config.User}} workdir={{.Config.WorkingDir}} cmd={{json .Config.Cmd}} labels={{json .Config.Labels}} id={{.Id}} digest={{.Digest}}' && podman image inspect localhost/tomcat-diagnostic-service:latest --format 'id={{.Id}} digest={{.Digest}}'
./scripts/validate.sh && bash -n scripts/*.sh && ./scripts/build.sh && ./scripts/test-image.sh && podman image inspect localhost/tomcat-diagnostic-service:0.1.0 --format 'id={{.Id}} digest={{.Digest}} base={{index .Config.Labels "org.opencontainers.image.base.name"}} user={{.Config.User}} workdir={{.Config.WorkingDir}} cmd={{json .Config.Cmd}}'
```

!!! success "Expected Result"

    Version dan latest tags memiliki identity sama; base pin, labels, non-root,
    Node.js, dependency, entrypoint, runtime files, dan exclusions cocok.

**Actual Result:** Passed setelah resolution. Kedua tags menunjuk image ID
`20841a7dd248a7d07cca306fb0eda5eed2f2c75cfd2b3860d179a357b448fa25`
dan digest `sha256:a849a9e39a49ffcacb11733b0ad19e5e5f29c10451f8fd284f2b218f71c2dff1`.
Node.js `v24.18.0`, Ajv `8.20.0`, dan Nodemailer `9.0.6` terbukti; test,
repository metadata, certificate, secret, dan SQLite artifact absent.

</div>

<div class="procedure-step" markdown>

### Run Disposable Image Verification

Temporary certificate dibuat hanya pada approved exact directory:

```bash
test ! -e /tmp/tomcat-diagnostic-tn010-component && mkdir /tmp/tomcat-diagnostic-tn010-component && openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -addext subjectAltName=DNS:localhost,IP:127.0.0.1 -keyout /tmp/tomcat-diagnostic-tn010-component/server.key -out /tmp/tomcat-diagnostic-tn010-component/server.crt
./scripts/test-image-component.sh /tmp/tomcat-diagnostic-tn010-component
```

Attempt pertama gagal pada fixture `EACCES` sebelum application container
dibuat. Resolution menambahkan `--userns=keep-id` pada seluruh disposable
containers. Attempt kedua melewati HTTPS dan SIGTERM, tetapi SQLite probe gagal
karena mount `:ro` mencegah SQLite locking walaupun API dibuka read-only.

```bash
bash -n scripts/*.sh && ./scripts/test-image-component.sh /tmp/tomcat-diagnostic-tn010-component
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn010-component$)" && find /tmp/tomcat-diagnostic-tn010-component -maxdepth 1 -printf '%f %m %u:%g %s\n' | sort
bash -n scripts/*.sh && ./scripts/test-image-component.sh /tmp/tomcat-diagnostic-tn010-component && test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn010-component$)"
```

Final resolution mempertahankan `DatabaseSync(..., { readOnly: true })` dan
memberi writable bind mount hanya kepada post-stop probe. Full rerun lulus.
Exact cleanup kemudian dijalankan:

```bash
rm -r /tmp/tomcat-diagnostic-tn010-component && test ! -e /tmp/tomcat-diagnostic-tn010-component && test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn010-component$)"
```

!!! success "Expected Result"

    Mounted TLS/token/allowlist/config, HTTPS live/ready/metrics, migration
    versions 1–3, SIGTERM exit `0`, dan exact cleanup terbukti.

**Actual Result:** Passed setelah dua resolutions. Tidak ada persistent
container, named volume, network baru, atau temporary directory tersisa.

</div>

<div class="procedure-step" markdown>

### Consolidate Documentation and Close

README, validator, Diagnostic MVP, Architecture, Development, Infrastructure,
phase navigation, dan TN-010 diperbarui melalui `apply_patch`. Mapping dan
final source/image review menggunakan:

```bash
rg -n "Diagnostic Service|image belum|image.*belum|TN-010|a398349|persistent runtime" docs/projects/tomcat-monitoring/{architecture/index.md,development/index.md,infrastructure/index.md,diagnostic-mvp/index.md} docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/{index.md,.pages} | head -200
./scripts/validate.sh && bash -n scripts/*.sh && ./scripts/test-image.sh && podman image inspect localhost/tomcat-diagnostic-service:0.1.0 localhost/tomcat-diagnostic-service:latest --format 'tags={{json .RepoTags}} id={{.Id}} digest={{.Digest}} created={{.Created}} size={{.Size}} base={{index .Config.Labels "org.opencontainers.image.base.name"}} base_id={{index .Config.Labels "io.tomcat-diagnostic.base.image.id"}} user={{.Config.User}} workdir={{.Config.WorkingDir}} cmd={{json .Config.Cmd}}' && test ! -e /tmp/tomcat-diagnostic-tn010-component && test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn010-component$)" && git diff --check && git status --short --branch && git diff --stat
./scripts/validate.sh && bash -n scripts/*.sh && git diff --check && test ! -e /tmp/tomcat-diagnostic-tn010-component && git status --short --branch && git diff --stat
git diff --check && test -f docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-010-build-and-verify-diagnostic-service-image.md && rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-010-build-and-verify-diagnostic-service-image.md && rg -n 'TN-010' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages && git status --short --branch && git diff --stat
```

Source-control handoff dijalankan setelah technical closure. README wording
dibuat netral melalui `apply_patch` sebelum staging karena image lifecycle
sudah tidak lagi berupa working-tree-only state. README dikecualikan dari build
context sehingga perubahan wording tidak mengubah verified image identity.

```bash
./scripts/validate.sh && bash -n scripts/*.sh && git diff --check && git status --short --branch && git diff --stat
git add .containerignore Containerfile CONFIG README.md scripts/build.sh scripts/test-image.sh scripts/test-image-component.sh scripts/validate.sh test/component/image-runtime-fixture.js test/component/image-runtime-probe.js test/component/image-runtime-database-probe.js
git diff --cached --check && git status --short && git diff --cached --stat
git commit -m "feat(diagnostic-service): add verified image lifecycle"
```

Actual source commit adalah `611a83d`.

!!! success "Expected Result"

    Source, image identity, component evidence, cleanup, documentation, dan
    exclusions konsisten serta reproducible dari exact working tree.

**Actual Result:** Passed untuk source/image review. Documentation render tetap
dibatasi pada source checks karena MkDocs CLI tidak tersedia dari TN-009.

</div>

</div>

## ✅ Verification

| Layer | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| Static validation | Digest, lifecycle artifacts, package, dan security boundaries konsisten | Passed | `./scripts/validate.sh` |
| Shell syntax | Seluruh scripts valid | Passed | `bash -n scripts/*.sh` |
| Source regression | Existing behavior tetap lulus | 31 passed, 0 failed/skipped | Ephemeral base-runtime test |
| Image build | Version/latest tags dibangun dari immutable base | Passed after one label resolution | Build output dan inspect |
| Image-static | Non-root, Node/dependencies, labels, command, content/exclusions cocok | Passed | `scripts/test-image.sh` |
| Image component | Mounted HTTPS/config, readiness, metrics, SQLite, SIGTERM | Passed after two fixture/probe resolutions | `scripts/test-image-component.sh` |
| Cleanup | Exact container/directory absent | Passed | `podman ps -aq` dan `test ! -e` |
| Persistent runtime/deployment | Excluded | Not run | Scope boundary |

## ⚙️ Commands Executed

| Tahap | Lokasi command aktual |
| --- | --- |
| Record the Approved Baseline | Procedure step **Record the Approved Baseline** |
| Implement the Image Lifecycle | Procedure step **Implement the Image Lifecycle** |
| Implement Disposable Runtime Verification | Tidak ada shell write; perubahan memakai `apply_patch` |
| Run Source Verification | Procedure step **Run Source Verification** |
| Build and Inspect the Image | Procedure step **Build and Inspect the Image** |
| Run Disposable Image Verification | Procedure step **Run Disposable Image Verification** |
| Consolidate Documentation and Close | Procedure step **Consolidate Documentation and Close** |

Section ini hanya menjadi indeks. Command aktual tetap berada pada procedure
step sesuai chronology.

## 📁 Artifact Manifest

| Artifact | Responsibility/identity |
| --- | --- |
| `Containerfile` | Digest-pinned non-root application image |
| `.containerignore` | Excludes VCS, tests, local dependencies, secrets, SQLite |
| `CONFIG` | Base digest and exact local image ID |
| `scripts/build.sh` | Builds `0.1.0` and `latest` after base-ID validation |
| `scripts/test-image.sh` | Metadata/runtime-content verification |
| `scripts/test-image-component.sh` | Exact disposable runtime orchestration and trap cleanup |
| `test/component/image-runtime-*.js` | Fixture, HTTPS, and read-only SQLite probes |
| Final image | ID `20841a7dd248...`; digest `sha256:a849a9e39a49...`; size 171,248,820 bytes |

## 🧪 Test-Scenario Matrix

| Scenario | Layer | Result |
| --- | --- | --- |
| Base digest and image ID match CONFIG | Pre-build | Passed |
| Static validator, Bash syntax, 31 regressions | Source | Passed |
| Version/latest same identity | Image build | Passed |
| User `node`, `/app`, Node `24.18.0`, exact dependencies | Image-static | Passed |
| No tests, metadata, certificate, secret, or SQLite in image | Image-static | Passed |
| Mounted configuration and trusted HTTPS live/ready/metrics | Image component | Passed |
| SQLite migrations 1–3 after shutdown | Image component | Passed |
| SIGTERM exits zero within five seconds | Image component | Passed |
| Exact container and directory cleanup | Cleanup | Passed |

## 🧹 Cleanup Evidence

`tomcat-diagnostic-tn010-component` dibersihkan oleh trap pada failed dan
successful attempts. `/tmp/tomcat-diagnostic-tn010-component` dihapus melalui
exact approved command; final container query dan `test ! -e` passed. Kedua
final image tags dipertahankan dan tidak dihapus.

## 🧭 Reproduction Boundary

Source baseline `a398349` dan final TN-010 commit `611a83d` menghasilkan image
ID `20841a7dd248a7d07cca306fb0eda5eed2f2c75cfd2b3860d179a357b448fa25`
dan digest `sha256:a849a9e39a49ffcacb11733b0ad19e5e5f29c10451f8fd284f2b218f71c2dff1`.
Reproduction memerlukan commit `611a83d`, local base digest, dan commands pada
setiap procedure step. Registry publication dan persistent runtime tidak
dibuktikan.

## 🧾 Outcome

Completed. Digest-pinned application image dibangun dan lulus source,
image-static, serta disposable HTTPS/SQLite/SIGTERM verification. Exact
temporary resources dibersihkan; final image tags dipertahankan. Tidak ada
persistent runtime, deployment, push, atau image publication. Source telah
dicommit sebagai `611a83d`.

## ⏭️ Next Steps

Define integration-owned non-secret runtime configuration, certificate/token/
allowlist mounts, dan disposable multi-component contract sebelum persistent
deployment dipertimbangkan.

## 🔗 Related Documentation

- [TN-009 — Implement Application Configuration and Startup Lifecycle](TN-009-implement-application-configuration-and-startup-lifecycle.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [TM-ADR-0002 — Separate Generic Runtime Images from Monitoring Integration Configuration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md)
- [TM-ADR-0010 — Deploy One Bounded Diagnostic Service per Tomcat Host](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)
- [TM-ADR-0013 — Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md)

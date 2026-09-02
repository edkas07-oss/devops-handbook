# TN-013 — Rebuild and Verify Diagnostic Service–Mailpit Runtime

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation and Verification |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-02 |
| Recorded Date | 2026-09-02 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Source, build, runtime, replacement, and cleanup approved/executed |
| Approved By | Project owner |
| Approval Date | 2026-09-02 |

## 🎯 Objective

Membangun ulang Diagnostic Service dari source TN-012 sebagai versioned image
baru dan membuktikan disposable HTTPS-to-SQLite-to-SMTP flow menggunakan
Mailpit aktual tanpa membuat persistent deployment.

## 🌍 Background

TN-012 menyelesaikan notification orchestration pada source commit `84c42c1`,
tetapi image TN-010 masih berasal dari source lama dan belum memuat perubahan
tersebut. Runtime contract TN-011 menyerahkan rebuild serta disposable
multi-component verification kepada TN-013.

## 📚 Scope

Scope yang disetujui meliputi metadata patch version, integration verifier,
validator/README terkait, live journal, static/source validation, local image
build/test, dan pembuatan exact temporary directory. Disposable runtime hanya
boleh berjalan setelah manifest exact memperoleh authorization berikutnya.

Persistent container, named volume, host port, deployment, actual Alertmanager
route, image removal, commit, dan push tidak termasuk. Destructive cleanup
memerlukan authorization terpisah setelah exact target tersedia.

## 📋 Prerequisites

| Prerequisite | Actual result |
| --- | --- |
| Diagnostic Service baseline | Clean dan sinkron `origin/main` pada `84c42c1` |
| Handbook baseline | Clean dan sinkron `origin/main` pada `db2ade2` |
| Integration repository baseline | Clean dan sinkron `origin/main` pada `a672434` |
| TN-012 source verification | 36 regression dan 2 SMTP socket component tests passed |
| Immutable Node.js base | Accepted digest `sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d` |
| Mailpit image | Accepted `v1.31.0` manifest digest dari runtime contract |
| Runtime contract | TN-011/current-state contract accepted |
| Current authorization | Source/docs edits, static validation, image build/test, dan temp directory approved |
| Mailpit local availability | Exact accepted digest tersedia |

## ⚖️ Execution Decision

- Patch version menjadi `0.1.1`; tag `0.1.0` tetap mempertahankan artifact
  TN-010 dan tag `latest` akan berpindah ke rebuilt image.
- Integration verifier dimiliki `tomcat-monitoring`; application image lifecycle
  tetap dimiliki `tomcat-diagnostic-service`.
- Runtime memakai exact image digest, internal-only network, tanpa host publish,
  temporary bind storage, dan restart disabled.
- Image dipertahankan. Exact containers, network, dan temporary directory hanya
  dibersihkan setelah evidence dicatat dan cleanup disetujui.

## 🛠️ Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Register Live Record** | Catat baseline, approval, scope, dan planned gates. |
| **Version and Verifier** | Bump metadata ke `0.1.1` dan tambahkan disposable verifier serta static contract. |
| **Source and Image Verification** | Jalankan Bash/static/regression checks, build, dan image-static tests. |
| **Resolve Runtime Manifest** | Buat exact temp directory, fixture non-secret, lalu publikasikan semua identity/mount/cleanup target. |
| **Runtime Verification** | Setelah approval, jalankan Diagnostic Service, client, dan Mailpit; kumpulkan evidence. |
| **Authorized Cleanup** | Setelah approval terpisah, hapus exact disposable resources dan buktikan tidak tersisa. |

## ⚙️ Implementation

### Register Live Record

Command discovery aktual:

```bash
git status --short --branch
git log -2 --oneline --decorate
git ls-remote --heads origin main
sed -n '1,260p' AGENTS.md
sed -n '/^## 🧾 Outcome/,$p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-012-implement-bounded-notification-delivery-orchestration.md
sed -n '1,260p' PROJECT VERSION CONFIG package.json Containerfile scripts/build.sh scripts/test-image.sh scripts/test-image-component.sh
rg -n 'smtp|notification|mail|tls|bearer|ready|metrics|webhook|worker' README.md config src test scripts migrations
sed -n '1,360p' scripts/verify-alertmanager-mailpit.sh
sed -n '1,340p' scripts/verify-alertmanager-webhook.sh
sed -n '1,280p' scripts/validate.sh
```

**Expected Result:** Exact source identity, ownership boundary, versioning gap,
dan reusable verification pattern diketahui sebelum edit.

**Actual Result:** Ketiga repository clean dan sinkron dengan remote. Source
masih memakai `0.1.0`; rebuild pada versi tersebut akan mengaburkan artifact
TN-010. `tomcat-monitoring` memiliki pola verifier disposable dengan identity
guard, tetapi TN-013 memerlukan verifier khusus tanpa host publish.

### Version and Verifier

Perubahan manual memakai `apply_patch`. Diagnostic Service metadata dinaikkan
dari `0.1.0` ke `0.1.1`; image test diperkuat dengan version-label dan command
assertion. Integration repository menerima fixture preparation, runtime
verifier, HTTPS/Mailpit probe, SQLite probe, validator contract, serta usage
documentation.

Verifier tidak memiliki cleanup trap. Keputusan ini disengaja agar destructive
cleanup tetap menjadi approval gate terpisah dan failed runtime evidence tidak
hilang otomatis.

**Expected Result:** Image lama tidak tertimpa secara semantik dan runtime
interface memenuhi exact topology tanpa host port/named volume.

**Actual Result:** Source menyediakan versioned `0.1.1` lifecycle dan verifier
memakai exact network/container/image identities dari accepted contract.

### Source and Image Verification

Command aktual:

```bash
# tomcat-monitoring
chmod 0755 scripts/prepare-diagnostic-service-mailpit.sh scripts/verify-diagnostic-service-mailpit.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check

# tomcat-diagnostic-service
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check

test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn013-test$)" && \
podman run --rm --name tomcat-diagnostic-tn013-test --userns=keep-id \
  --volume /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z \
  --workdir /app \
  localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d \
  npm test && \
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn013-test$)"

./scripts/build.sh
./scripts/test-image.sh
podman image inspect localhost/tomcat-diagnostic-service:0.1.1 --format \
  'image_id={{.Id}} digest={{.Digest}} user={{.Config.User}} workdir={{.Config.WorkingDir}} command={{json .Config.Cmd}} version={{index .Config.Labels "org.opencontainers.image.version"}}'
podman run --rm --pull=never localhost/tomcat-diagnostic-service:0.1.1 id
```

**Expected Result:** Source tests lulus, image menggunakan immutable base,
metadata/runtime-static contract sesuai, dan effective identity dapat dibuktikan.

**Actual Result:** Static/Bash/diff checks lulus. Regression menghasilkan 36
passed, 0 failed/skipped dan exact test container absent. Build menghasilkan
image ID `e634d9914a4a022feb8dcc2fabc6b2b26166b9bee00d7f688e5393d45537f2f2`
dengan digest `sha256:2bd61dee74da16f29775c7643255b63361101e00c86fdc57b797d278ed431ab2`.
Image-static tests lulus dengan Node.js `v24.18.0`, exact production dependency,
user `node` (`1000:1000`), workdir `/app`, version `0.1.1`, dan accepted command.
Tag `latest` menunjuk digest baru; tag `0.1.0` tetap pada digest TN-010.

### Resolve Runtime Manifest

Command aktual:

```bash
mktemp -d /tmp/tomcat-diagnostic-tn013.XXXXXX
./scripts/prepare-diagnostic-service-mailpit.sh /tmp/tomcat-diagnostic-tn013.pRPWNF
find /tmp/tomcat-diagnostic-tn013.pRPWNF -maxdepth 2 \
  -printf '%M %u:%g %p\n' | sort
openssl x509 -in /tmp/tomcat-diagnostic-tn013.pRPWNF/tls/server.crt \
  -noout -subject -ext subjectAltName
```

**Expected Result:** Exact empty path berubah menjadi bounded fixture tree
dengan accepted permissions dan certificate identity tanpa runtime mutation.

**Actual Result:** Resolved path adalah
`/tmp/tomcat-diagnostic-tn013.pRPWNF`. Seluruh directory mode `0700`, public
input `0444`, private key/token `0400`, owner `eddywiyatno:eddywiyatno`
(`1000:1000`), dan certificate memiliki `CN`/SAN `diagnostic-service`. Belum
ada container atau network TN-013.

### Runtime Attempt 1 and Source Resolution

Setelah exact manifest disetujui, verifier dijalankan dengan initial image
digest `sha256:2bd61dee74da16f29775c7643255b63361101e00c86fdc57b797d278ed431ab2`:

```bash
DIAGNOSTIC_IMAGE='localhost/tomcat-diagnostic-service@sha256:2bd61dee74da16f29775c7643255b63361101e00c86fdc57b797d278ed431ab2' \
  ./scripts/verify-diagnostic-service-mailpit.sh \
  /tmp/tomcat-diagnostic-tn013.pRPWNF
```

**Expected Result:** Seluruh runtime assertions termasuk SQLite reopen dan
mode contract lulus.

**Actual Result:** TLS trust, live/ready/metrics, bearer rejection,
firing/duplicate/resolved, dua Mailpit messages, serta plain-text/HTML passed.
Diagnostic container menerima SIGTERM dan exit `0`. Database probe kemudian
gagal `unable to open database file` karena exact data bind dipasang read-only
pada client sementara driver SQLite memerlukan locking access.

Read-only inspection membuktikan database dapat dibaca byte-for-byte dan
Diagnostic Service exit `0`. Inspection juga menemukan defect contract:
database dibuat mode `0644`, bukan `0600`. Source diperbaiki agar repository
mengatur database ke `0600` saat create dan reopen. Probe diubah untuk membuka
snapshot read-only setelah shutdown dan menambahkan application reopen/
readiness verification.

Regression setelah fix kembali menghasilkan 36 passed, 0 failed/skipped.
Rebuild dan image-static tests menghasilkan final candidate:

```text
image ID: 1c8261a2d47fe7c013fe943c72529a4ba9afc7383e6de0079478f36ddd4d7a6c
digest: sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f
```

Failed resources dan database lama masih dipertahankan. Replacement/reset
memerlukan destructive authorization sebelum final runtime attempt.

### Authorized Reset and Final Runtime Attempt

Project owner mengizinkan exact failed-resource replacement. ID guard cocok,
kemudian tiga failed containers, failed network, dan hanya exact
`/tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db` dihapus. Certificate,
configuration, token, directory, volume baseline, dan images dipertahankan.

Final command:

```bash
DIAGNOSTIC_IMAGE='localhost/tomcat-diagnostic-service@sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f' \
  ./scripts/verify-diagnostic-service-mailpit.sh \
  /tmp/tomcat-diagnostic-tn013.pRPWNF
```

**Expected Result:** Final exact digest memenuhi seluruh disposable runtime
contract dan resource tetap tersedia sampai cleanup approval.

**Actual Result:** Passed. HTTPS CA trust, live/ready, metrics, bearer
rejection, firing/duplicate/resolved sequence, dua bounded text/HTML messages,
schema migrations 1–4, dua events/results/completed queue items/sent attempts,
SQLite snapshot, database mode `0600`, application database reopen, readiness
setelah reopen, dan graceful SIGTERM exit `0` terbukti. Tidak ada host publish,
restart policy `no`, dan volume state unchanged.

Final retained resource IDs:

| Resource | Exact ID/state |
| --- | --- |
| Network `tm-tn013-diagnostic` | `5287f6d8e668f7f909a8db55b1507d0a61783508e058b20fb9556726945be1b3` |
| Diagnostic Service | `2704173d623ff3c846231bb5787593c863215b45fbd5195160cd9c4bbbfd7ec1`; exited `0` |
| HTTPS client | `a41befdeee44d0c63c7e7e10d25685c35a86268b8805efe4825298fea8286ae7`; running |
| Mailpit | `8eaac4c6af9084b9275db598eee848251f69ddc50b9ad76d426d5d9f5c329b1e`; running |
| SQLite | `/tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db`; `0600`, `1000:1000` |

### Authorized Final Cleanup

Setelah evidence dicatat, project owner mengizinkan cleanup exact successful
resources. Command aktual menggunakan ID guard, membandingkan volume state
sebelum dan sesudah container removal, menghapus resolved directory, lalu
memeriksa resource absence serta retained images:

```bash
test "$(podman inspect tm-tn013-diagnostic-service --format '{{.Id}}')" = \
  '2704173d623ff3c846231bb5787593c863215b45fbd5195160cd9c4bbbfd7ec1'
test "$(podman inspect tm-tn013-diagnostic-client --format '{{.Id}}')" = \
  'a41befdeee44d0c63c7e7e10d25685c35a86268b8805efe4825298fea8286ae7'
test "$(podman inspect tm-tn013-diagnostic-mailpit --format '{{.Id}}')" = \
  '8eaac4c6af9084b9275db598eee848251f69ddc50b9ad76d426d5d9f5c329b1e'
test "$(podman network inspect tm-tn013-diagnostic --format '{{.Id}}')" = \
  '5287f6d8e668f7f909a8db55b1507d0a61783508e058b20fb9556726945be1b3'
test -d /tmp/tomcat-diagnostic-tn013.pRPWNF
podman volume ls --format '{{.Name}}' | sort | \
  cmp --silent /tmp/tomcat-diagnostic-tn013.pRPWNF/volume-baseline.txt -
podman rm --force \
  tm-tn013-diagnostic-service \
  tm-tn013-diagnostic-client \
  tm-tn013-diagnostic-mailpit
podman network rm tm-tn013-diagnostic
podman volume ls --format '{{.Name}}' | sort | \
  cmp --silent /tmp/tomcat-diagnostic-tn013.pRPWNF/volume-baseline.txt -
rm -rf -- /tmp/tomcat-diagnostic-tn013.pRPWNF
test ! -d /tmp/tomcat-diagnostic-tn013.pRPWNF
```

Absence checks memakai `podman container exists` untuk tiga exact names dan
`podman network exists tm-tn013-diagnostic`; retained checks memakai `podman
image exists` untuk `0.1.0`, `0.1.1`, `latest`, exact Node.js digest, dan exact
Mailpit digest.

**Expected Result:** Hanya disposable resources hilang, volume state tidak
berubah, dan seluruh accepted images tetap tersedia.

**Actual Result:** `cleanup_result=passed containers_absent=true
network_absent=true temporary_root_absent=true volume_state=unchanged
images_retained=true`. Idle client tidak berhenti dalam 10 detik sehingga
Podman memakai `SIGKILL`; exact container tetap berhasil dihapus.

## 🛠️ Troubleshooting

| Attempt | Actual result | Resolution |
| --- | --- | --- |
| Membaca `package-lock.json` dari integration repository | File tidak ada | Ulangi pembacaan dari repository Diagnostic Service |
| Patch journal evidence pertama | Context line tidak cocok | Baca ulang TN-013 dan terapkan patch terhadap exact current content |
| Runtime attempt 1 database probe | Client read-only bind tidak dapat membuka SQLite untuk locking | Probe exact file melalui read-only snapshot dan tambah application reopen check |
| Runtime attempt 1 file-mode inspection | Database mode aktual `0644` | Set `0600` pada repository create/reopen, tambah regression assertion, rebuild image |
| Read-only `ls -Z` dalam client | BusyBox `ls` tidak mendukung option `-Z` | Gunakan `stat`, byte-read, host label query, dan `podman unshare stat` |
| Patch journal runtime evidence pertama | Salah satu trailing context tidak cocok | Baca ulang exact section dan terapkan patch lebih kecil |
| Failed-resource removal | Idle client tidak berhenti dalam 10 detik; Podman memakai `SIGKILL` | Exact ID-guarded removal tetap berhasil; final client cleanup perlu mencatat behavior yang sama bila berulang |
| Network evidence template | `.Containers` dan `.containers` tidak tersedia pada inspect template | Gunakan container inspect sebagai membership evidence; jangan mengarang field network inspect |
| Final cleanup idle client | `SIGTERM` tidak menghentikan idle probe dalam 10 detik | Podman memakai `SIGKILL`; exact removal dan seluruh post-cleanup checks passed |

## ⚙️ Commands Executed

Command utama dicatat secara kronologis pada procedure. Perubahan file manual
dilakukan dengan `apply_patch`. Command diagnostic dan resolution aktual yang
melengkapi chronology adalah:

```bash
podman inspect tm-tn013-diagnostic-service --format \
  'diagnostic_id={{.Id}} state={{.State.Status}} exit={{.State.ExitCode}} mounts={{json .Mounts}}'
podman inspect tm-tn013-diagnostic-client --format \
  'client_id={{.Id}} state={{.State.Status}} user={{.Config.User}} mounts={{json .Mounts}}'
podman inspect tm-tn013-diagnostic-mailpit --format \
  'mailpit_id={{.Id}} state={{.State.Status}}'
podman network inspect tm-tn013-diagnostic --format 'network_id={{.Id}}'
podman exec tm-tn013-diagnostic-client id
podman exec tm-tn013-diagnostic-client sh -c \
  'stat -c "%a %u:%g %n" /runtime /runtime/data /runtime/data/diagnostic.db; test -r /runtime/data/diagnostic.db; head -c 16 /runtime/data/diagnostic.db | od -An -tx1'
find /tmp/tomcat-diagnostic-tn013.pRPWNF/data -maxdepth 1 \
  -printf '%M %u:%g %s %p\n'
podman logs tm-tn013-diagnostic-service
podman unshare stat -c '%a %u:%g %n' \
  /tmp/tomcat-diagnostic-tn013.pRPWNF/data \
  /tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db
```

Source resolution dan rebuild memakai:

```bash
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
podman run --rm --name tomcat-diagnostic-tn013-fix-test --userns=keep-id \
  --volume /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z \
  --workdir /app \
  localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d \
  npm test
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn013-fix-test$)"
podman exec tm-tn013-diagnostic-client node --check database-probe.js
podman exec tm-tn013-diagnostic-client node --check reopen-probe.js
./scripts/build.sh
./scripts/test-image.sh
podman image inspect localhost/tomcat-diagnostic-service:0.1.1 --format \
  'image_id={{.Id}} digest={{.Digest}} user={{.Config.User}} version={{index .Config.Labels "org.opencontainers.image.version"}}'
```

Failed-resource reset setelah authorization memakai exact ID guards yang sama
dengan final cleanup, `podman rm --force` untuk tiga failed names,
`podman network rm tm-tn013-diagnostic`, lalu:

```bash
rm -- /tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db
test ! -e /tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db
```

Final evidence memakai:

```bash
stat -c 'database_mode=%a owner=%u:%g size=%s path=%n' \
  /tmp/tomcat-diagnostic-tn013.pRPWNF/data/diagnostic.db
cmp --silent \
  /tmp/tomcat-diagnostic-tn013.pRPWNF/volume-baseline.txt \
  /tmp/tomcat-diagnostic-tn013.pRPWNF/volume-after-runtime.txt
podman image inspect localhost/tomcat-diagnostic-service:0.1.1 --format \
  'versioned_id={{.Id}} digest={{.Digest}}'
podman image inspect localhost/tomcat-diagnostic-service:latest --format \
  'latest_id={{.Id}} digest={{.Digest}}'
```

Network membership template attempts berikut gagal dan tidak dipakai sebagai
evidence:

```bash
podman network inspect tm-tn013-diagnostic --format \
  'network_id={{.Id}} containers={{len .Containers}}'
podman network inspect tm-tn013-diagnostic --format \
  'network_id={{.Id}} containers={{json .containers}}'
```

Final source/documentation verification setelah cleanup memakai:

```bash
# tomcat-diagnostic-service dan tomcat-monitoring
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check

# exact ephemeral final regression
podman run --rm --name tomcat-diagnostic-tn013-final-test \
  --userns=keep-id \
  --volume /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z \
  --volume /home/eddywiyatno/git/tomcat-monitoring/fixtures/diagnostic-service-mailpit:/probe:ro,Z \
  --workdir /app \
  localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d \
  sh -eu -c 'npm test; node --check /probe/runtime-probe.js; node --check /probe/database-probe.js; node --check /probe/reopen-probe.js'
test ! "$(podman ps -aq --filter name=^tomcat-diagnostic-tn013-final-test$)"

# handbook
git diff --check
rg -n 'TN-013-rebuild-and-verify-diagnostic-service-mailpit-runtime\.md' \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md \
  docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages
```

## 📁 Artifact Manifest

| Artifact | Responsibility | Current state |
| --- | --- | --- |
| Diagnostic `VERSION`, `package.json`, `package-lock.json`, `Containerfile` | Application/image identity `0.1.1` | Implemented and image verified |
| Diagnostic `src/adapters/sqlite-repository.js` | Enforce database mode `0600` on create/reopen | Implemented and regression/runtime verified |
| Diagnostic `test/integration/sqlite-ingestion.test.js` | Permission create/reopen assertions | Passed |
| Diagnostic `scripts/test-image.sh`, `README.md` | Image command/version assertions and public digest/status | Verified |
| Monitoring `scripts/prepare-diagnostic-service-mailpit.sh` | Exact generated fixture preparation | Verified; generated directory cleaned |
| Monitoring `scripts/verify-diagnostic-service-mailpit.sh` | Three-container disposable orchestration and assertions | Final runtime passed |
| Monitoring `fixtures/diagnostic-service-mailpit/runtime-probe.js` | HTTPS, webhook, metrics, and Mailpit assertions | Syntax/runtime passed |
| Monitoring `fixtures/diagnostic-service-mailpit/database-probe.js` | Read-only SQLite snapshot assertions | Syntax/runtime passed |
| Monitoring `fixtures/diagnostic-service-mailpit/reopen-probe.js` | Application database reopen/readiness assertion | Syntax/runtime passed |
| Monitoring `scripts/validate.sh`, `README.md`, `validation/README.md` | Static contract and operator boundary | Static validation passed |
| Handbook TN-013, phase navigation, Diagnostic MVP contracts/current-state pages | Chronology, evidence, current state, and handoff | Consolidated |
| `/tmp/tomcat-diagnostic-tn013.pRPWNF` | Generated certificate/token/config/database evidence | Removed after authorization |
| `TN-005-implement-durable-diagnostic-ingestion-and-queue.md` | Unrelated pre-existing user change | Preserved and excluded from TN-013 manifest |

## 🧪 Test-Scenario Matrix

| Scenario | Layer | Current result |
| --- | --- | --- |
| Bash/static validation | Source/static | Passed in both repositories |
| Regression tests | Source/unit/integration | 36 passed, 0 failed/skipped |
| Image metadata/content | Image | Passed for exact `0.1.1` digest |
| TLS/live/ready/metrics/auth rejection | Runtime integration | Final digest passed |
| Webhook → worker → SQLite | Runtime integration | Final digest passed; database `0600` and reopen passed |
| SMTP attempt → Mailpit text/HTML | Runtime integration | Final digest passed; 2 sent attempts/messages |
| SIGTERM | Runtime integration | Passed twice; exit `0` |
| Exact cleanup | Runtime integration | Passed; images retained |

## ✅ Verification

| Method | Expected result | Actual result |
| --- | --- | --- |
| Bash/static/diff checks | Source contracts valid | Passed |
| Regression via exact ephemeral container | All source tests pass | 36 passed; container absent |
| Build | Versioned/latest image from immutable base | Passed |
| Image-static probes | Identity, content, dependency, user, command valid | Passed |
| Runtime integration attempt 1 | Full contract | Partial: notification flow passed; SQLite mode/reopen failed |
| Regression and rebuild after resolution | Mode `0600`, source and image valid | 36 passed; final candidate image-static passed |
| Final runtime integration | Full disposable contract | Passed |
| Resource/volume evidence | No host ports/volume mutation; exact IDs retained | Passed |
| Exact cleanup | Containers, network, and directory absent; images retained | Passed |
| Final regression and fixture syntax | Exact final working tree remains valid | 36 passed, 0 failed/skipped; three fixture files valid |
| Final cleanup re-audit | Exact resources remain absent and images available | Passed |
| Documentation validation | Diff, navigation, headings, links, whitespace | Passed; MkDocs CLI not available |

## 🧹 Cleanup Evidence

Exact test containers, three final runtime containers, network
`tm-tn013-diagnostic`, dan `/tmp/tomcat-diagnostic-tn013.pRPWNF` absent setelah
authorized cleanup. Named/anonymous volume state unchanged. Images `0.1.0`,
`0.1.1`, `latest`, immutable Node.js, dan immutable Mailpit tetap tersedia.

## 🧭 Reproduction Boundary

Baseline source adalah `84c42c1`, handbook `db2ade2`, dan integration
repository `a672434`. Initial rebuilt working tree menghasilkan digest
`sha256:2bd61dee74da16f29775c7643255b63361101e00c86fdc57b797d278ed431ab2`;
runtime resolution menghasilkan final candidate digest
`sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f`.
Exact changed-file manifest tersedia pada Artifact Manifest; final source
commits belum dibuat karena commit/push berada di luar approved technical
scope. Cleanup evidence telah tersedia.

## 🖥️ Source-Control Handoff

Ketiga branch tetap pada published baselines `84c42c1`, `a672434`, dan
`db2ade2`. Perubahan TN-013 belum di-commit atau di-push. Handbook juga memiliki
perubahan pengguna pada TN-005 yang tidak termasuk manifest dan harus tetap
dikecualikan dari staging TN-013.

## 🧾 Outcome

Completed. Runtime attempt 1 menemukan SQLite mode/reopen defect. Source fix,
36 regression tests, rebuilt image-static verification, final HTTPS/SQLite/
Mailpit runtime, database reopen, mode `0600`, graceful shutdown, dan exact
cleanup kemudian lulus. Tidak ada host port, named volume baru, persistent
container, deployment, atau actual Alertmanager route. Images dipertahankan;
commit dan push belum dilakukan.

## ⏭️ Next Steps

Lakukan source-control handoff hanya setelah authorization terpisah. TN
berikutnya dapat menetapkan actual Alertmanager diagnostic route atau
persistent Diagnostic Service deployment; collector dan end-to-end pilot
tetap membutuhkan scope tersendiri.

## 🔗 Related Documentation

- [TN-012](TN-012-implement-bounded-notification-delivery-orchestration.md)
- [Runtime Contract](../../diagnostic-mvp/runtime-configuration-and-verification-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)

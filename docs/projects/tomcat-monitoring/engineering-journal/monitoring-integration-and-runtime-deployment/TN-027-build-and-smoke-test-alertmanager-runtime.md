# TN-027 — Build and Smoke Test Alertmanager Runtime

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-26 |
| Recorded Date | 2026-08-26 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-26 |

## 🎯 Objective

Membangun image lokal `localhost/alertmanager:1.0.0` dari exact upstream pin
`quay.io/prometheus/alertmanager:v0.34.0` dan membuktikan Alertmanager,
`amtool`, official runtime contract, non-root user, serta disposable cleanup.

## 🌍 Background

TN-026 membentuk generic Alertmanager runtime source dan menyelesaikan static
verification tanpa menarik image atau menjalankan container. Component build
dan smoke test masih diperlukan sebelum repository `tomcat-monitoring` dapat
bergantung pada runtime tersebut untuk configuration integration.

Project owner menyetujui TN-027 untuk exact upstream pull bila belum tersedia,
local build, disposable `--rm` smoke tests, image inspection, dan cleanup
audit. Authorization tidak mencakup Alertmanager configuration, named volume,
persistent container, port publication, Prometheus integration, webhook,
external notification, image cleanup, source change, commit, atau push.

## 📚 Scope

Aktivitas ini mencakup:

- Memeriksa source identity, Podman availability, upstream image, target tags,
  dan container collision.
- Menarik hanya `quay.io/prometheus/alertmanager:v0.34.0` karena belum tersedia.
- Mencatat upstream image ID, digest, user, entrypoint, command, dan exposed
  port.
- Membangun `localhost/alertmanager:1.0.0` dan
  `localhost/alertmanager:latest` melalui approved build interface.
- Memverifikasi kedua tag memiliki image ID yang sama dan OCI labels benar.
- Menjalankan Alertmanager serta `amtool` version checks dengan disposable
  `--rm` containers.
- Memverifikasi configured user `nobody`, inherited entrypoint/command/port,
  tidak ada retained container, dan tidak ada volume baru dari test.
- Memperbarui Engineering Journal dan current-state documentation.

Configuration, receiver, secret, named volume, network creation, persistent
runtime, host port, webhook, firing/resolved delivery, external integration,
source correction, image removal, commit, dan push tidak termasuk.

## 📋 Criteria

| Criterion | Expected Result |
| --- | --- |
| Preflight | Podman tersedia; source sesuai TN-026; upstream dan target state diketahui; tidak ada target tag atau container collision. |
| Upstream | Exact `v0.34.0` tersedia lokal dengan immutable identity dan official non-root contract. |
| Local build | Tag `localhost/alertmanager:1.0.0` dan `:latest` terbentuk dari current source dan menunjuk image ID yang sama. |
| Metadata | Project, source version, Alertmanager version, user, entrypoint, command, dan port sesuai contract. |
| Alertmanager binary | Disposable container melaporkan version `0.34.0`. |
| `amtool` binary | Disposable container melaporkan version `0.34.0`. |
| Cleanup | Tidak ada container atau volume baru yang tertinggal setelah `--rm` tests. |
| Source continuity | Build dan test tidak mengubah source working tree. |

## 📋 Method

Gunakan source lifecycle interfaces TN-026 dengan `--pull=never` untuk build
dan smoke test. Pull upstream dilakukan eksplisit hanya setelah preflight
membuktikan image belum tersedia. Target tags diinspeksi sebelum dan setelah
build agar tag yang sudah ada tidak tertimpa tanpa audit.

Image hasil build dipertahankan untuk integration activity berikutnya. Smoke
containers menggunakan `--rm`; post-test audit memeriksa exact image ancestor
dan dangling-volume creation time tanpa menghapus resource lain.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Run the Source and Local-Image Preflight** | Memeriksa source, Podman, upstream state, target tags, dan collision. |
| **Pull and Inspect the Exact Upstream** | Mengambil exact upstream dan mencatat immutable identity serta runtime contract. |
| **Build the Local Runtime Image** | Membentuk versioned dan `latest` tags dari current source. |
| **Inspect the Candidate and Run the Smoke Tests** | Memeriksa metadata, binary, `amtool`, dan user non-root. |
| **Audit the Post-Test Identity and Cleanup** | Memastikan assertions lulus dan test tidak meninggalkan container atau volume baru. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Run the Source and Local-Image Preflight

**Purpose.** Membuktikan source revision, Podman, collision state, serta apakah
upstream pull diperlukan sebelum mengubah image store.

**Command actually executed.**

```bash
# /home/eddywiyatno/git/alertmanager
git status --short --branch
sed -n '1,260p' AGENTS.md
sed -n '1,220p' PROJECT
sed -n '1,220p' VERSION
sed -n '1,220p' CONFIG
sed -n '1,220p' Containerfile
sed -n '1,260p' scripts/build.sh
sed -n '1,260p' scripts/test.sh

# Initial sandboxed Podman preflight
podman version --format 'client={{.Client.Version}}'
if podman image exists quay.io/prometheus/alertmanager:v0.34.0; then printf 'upstream_image=present\n'; else printf 'upstream_image=absent\n'; fi
if podman image exists localhost/alertmanager:1.0.0; then printf 'versioned_target=present\n'; else printf 'versioned_target=absent\n'; fi
if podman image exists localhost/alertmanager:latest; then printf 'latest_target=present\n'; else printf 'latest_target=absent\n'; fi
podman ps --all --filter ancestor=quay.io/prometheus/alertmanager:v0.34.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'

# Approved preflight retry outside read-only sandbox
podman version --format 'client={{.Client.Version}}'
if podman image exists quay.io/prometheus/alertmanager:v0.34.0; then printf 'upstream_image=present\n'; else printf 'upstream_image=absent\n'; fi
if podman image exists localhost/alertmanager:1.0.0; then printf 'versioned_target=present\n'; else printf 'versioned_target=absent\n'; fi
if podman image exists localhost/alertmanager:latest; then printf 'latest_target=present\n'; else printf 'latest_target=absent\n'; fi
podman ps --all --filter ancestor=quay.io/prometheus/alertmanager:v0.34.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
```

!!! success "Expected Result"

    Podman dan exact source tersedia; target tags serta container collision
    tidak ada; upstream state diketahui secara valid.

**Actual Result:** initial Podman commands gagal karena sandbox
tidak dapat menetapkan sticky bit pada `/run/user/1000/libpod`; output
`absent` dari conditional checks tersebut tidak digunakan sebagai evidence.

**Evidence:** approved retry melaporkan Podman `4.9.3`, upstream absent, kedua target tags
absent, dan tidak ada container untuk upstream atau target ancestor.

</div>

<div class="procedure-step" markdown>

### Pull and Inspect the Exact Upstream

**Purpose.** Menyediakan satu-satunya base image yang diizinkan dan merekam
immutable identity sebelum build.

**Command actually executed.**

```bash
podman pull quay.io/prometheus/alertmanager:v0.34.0
podman image inspect quay.io/prometheus/alertmanager:v0.34.0 --format 'id={{.Id}} digest={{.Digest}} repo_digests={{json .RepoDigests}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}} ports={{json .Config.ExposedPorts}}'
if podman image exists localhost/alertmanager:1.0.0; then printf 'versioned_target=present\n'; else printf 'versioned_target=absent\n'; fi
if podman image exists localhost/alertmanager:latest; then printf 'latest_target=present\n'; else printf 'latest_target=absent\n'; fi
```

!!! success "Expected Result"

    Exact upstream tersedia; target tags tetap absent; official non-root user
    dan runtime interface diketahui.

**Actual Result:** pull exact upstream berhasil dan target tags tetap absent.

**Evidence:** image ID `c4e1c067b29e...`, inspected digest
`sha256:690c7b525f43...`, serta Quay index dan manifest repo digests yang
tercatat. Image menggunakan user `nobody`, entrypoint `/bin/alertmanager`,
default config `/etc/alertmanager/alertmanager.yml`, storage
`/alertmanager`, dan exposed port `9093/tcp`. Target tags tetap absent.

</div>

<div class="procedure-step" markdown>

### Build the Local Runtime Image

**Purpose.** Membentuk versioned candidate dan latest convenience tag dari
current source tanpa implicit pull.

**Command actually executed.**

```bash
bash -n CONFIG scripts/*.sh
test "$(sed -n 's/^BASE_IMAGE=//p' CONFIG)" = quay.io/prometheus/alertmanager:v0.34.0
test "$(sed -n 's/^IMAGE_NAME=//p' CONFIG)" = localhost/alertmanager
test "$(<VERSION)" = 1.0.0
./scripts/build.sh
```

!!! success "Expected Result"

    Build menggunakan exact local upstream dan menghasilkan kedua target tags
    tanpa source correction.

**Actual Result:** build lulus seluruh lima Containerfile steps tanpa retry
atau source deviation.

**Evidence:** image ID `ca27172ead92...`; Podman menandai image yang sama
sebagai `localhost/alertmanager:1.0.0` dan
`localhost/alertmanager:latest`.

</div>

<div class="procedure-step" markdown>

### Inspect the Candidate and Run the Smoke Tests

**Purpose.** Membuktikan metadata, inherited runtime contract, Alertmanager,
`amtool`, dan non-root user sebelum image dikonsumsi integration repository.

**Command actually executed.**

```bash
podman image inspect localhost/alertmanager:1.0.0 --format 'id={{.Id}} parent={{.Parent}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}} ports={{json .Config.ExposedPorts}} title={{index .Config.Labels "org.opencontainers.image.title"}} version={{index .Config.Labels "org.opencontainers.image.version"}} alertmanager_version={{index .Config.Labels "io.prometheus.alertmanager.version"}}'
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{.Id}}')" = "$(podman image inspect localhost/alertmanager:latest --format '{{.Id}}')"
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
./scripts/test.sh
```

!!! success "Expected Result"

    Candidate mempertahankan user, entrypoint, command, dan port upstream;
    labels serta tags benar; kedua binaries melaporkan `0.34.0`; test
    containers self-clean.

**Actual Result:** metadata candidate sesuai dan kedua smoke tests lulus.

**Evidence:** candidate ID `ca27172ead92...`, user `nobody`, entrypoint
`/bin/alertmanager`, official default command, dan
port `9093/tcp`. Labels melaporkan project `alertmanager`, source version
`1.0.0`, dan Alertmanager `v0.34.0`; kedua tags memiliki ID yang sama.
Alertmanager dan `amtool` sama-sama melaporkan version `0.34.0`, revision
`085f0ef7eb41...`, Go `1.26.6`, serta platform `linux/amd64`.

</div>

<div class="procedure-step" markdown>

### Audit the Post-Test Identity and Cleanup

**Purpose.** Memastikan assertions final lulus dan disposable execution tidak
meninggalkan container atau storage TN-027.

**Command actually executed.**

```bash
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{.Config.User}}')" = nobody
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{json .Config.Entrypoint}}')" = '["/bin/alertmanager"]'
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{index .Config.Labels "org.opencontainers.image.title"}}')" = alertmanager
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = 1.0.0
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{index .Config.Labels "io.prometheus.alertmanager.version"}}')" = v0.34.0
test "$(podman image inspect localhost/alertmanager:1.0.0 --format '{{.Id}}')" = "$(podman image inspect localhost/alertmanager:latest --format '{{.Id}}')"
podman image inspect localhost/alertmanager:1.0.0 --format 'id={{.Id}} size={{.Size}} user={{.Config.User}} volumes={{json .Config.Volumes}} created={{.Created}}'
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
git status --short --branch
podman volume ls --filter dangling=true --format 'name={{.Name}} driver={{.Driver}}'
podman volume inspect da14760a0e01813bf6bcc503e8c716831a3f986001f14e6d1cee7a884df987f1 92c0004dfd0ed4679b38fd8ce9ce04ca3b99fdc731f3ef89e5e772a9b1db8eb0 010bf588f018d991c51739fc322d678b60f22c12e77485224837de18e9f32459 2df1fa88bb0cbd285de9b14a782f964686afb9b66036e361aaa4be01a92d0ec6 8c937e681a10e0b1cbfd95c74497e24360c0139894ff4d26e2155ab66d91944e 6b338381e06114aa1cbb6787c2a30bdf210c4d9cf4aaf2035ba13b6f44b91ba6 --format 'name={{.Name}} created={{.CreatedAt}} anonymous={{index .Labels "io.podman.volume.is_anonymous"}}'
```

!!! success "Expected Result"

    Seluruh assertions lulus, tidak ada candidate container, source tidak
    berubah, dan tidak ada dangling volume baru milik TN-027.

**Actual Result:** assertions lulus, ancestor query kosong, dan source status
tidak berubah.

**Evidence:** candidate size `82689848` bytes, user tetap `nobody`, dan image declares
`/alertmanager` as a volume. Container ancestor query returned no rows. Six
dangling volumes existed, but inspection showed creation dates from 2026-08-07
through 2026-08-25; all predate TN-027 and were left unchanged. Source Git
status remained the same untracked TN-026 source inventory.

</div>

</div>

## ⚙️ Commands Executed

Seluruh Podman, source assertion, dan cleanup-audit commands dicatat verbatim
pada lima tahap `Implementation` di atas sesuai urutan pelaksanaan. Command
documentation verification berikut dijalankan setelah TN dan current-state
handoff diperbarui.

```bash
# /home/eddywiyatno/git/devops-handbook
git diff --check
git status --short --branch
sed -n '1,360p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-027-build-and-smoke-test-alertmanager-runtime.md
rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-027-build-and-smoke-test-alertmanager-runtime.md
rg -n 'TN-027|TN-027-build-and-smoke' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/development/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-027-build-and-smoke-test-alertmanager-runtime.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-027-build-and-smoke-test-alertmanager-runtime.md
command -v mkdocs
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/alertmanager status --short --branch
```

## 📋 Evidence

| Evidence | Result |
| --- | --- |
| Upstream identity | ID `c4e1c067b29e...`; inspected digest `sha256:690c7b525f43...`; official user `nobody`. |
| Candidate identity | ID `ca27172ead92...`; tags `1.0.0` and `latest`; labels `alertmanager`, `1.0.0`, and `v0.34.0`. |
| Runtime contract | Entrypoint `/bin/alertmanager`; official config and storage arguments; port `9093/tcp`; volume `/alertmanager`. |
| Binary result | Alertmanager and `amtool` version `0.34.0`, revision `085f0ef7eb41...`, `linux/amd64`. |
| Cleanup result | No retained candidate container; no dangling volume created on 2026-08-26. |

## ⚠️ Exceptions

MkDocs render berstatus `Not verified` karena executable tidak tersedia dan
dependency tidak dipasang. Seluruh source-level documentation checks lulus.

Data write permission, readiness, configuration semantics, and integration
behavior tidak diuji karena memerlukan named volumes, configuration, receiver,
dan runtime scope yang sengaja dikecualikan dari TN-027.

## ✅ Conclusion

Seluruh TN-027 criteria lulus. Image lokal
`localhost/alertmanager:1.0.0` berhasil dibangun dari exact upstream
`v0.34.0`; Alertmanager dan `amtool` dapat dieksekusi; official user,
entrypoint, command, port, labels, dan tag identity konsisten. Disposable
containers self-clean dan tidak menghasilkan dangling volume baru.

Hasil ini membuktikan component image build dan smoke-test boundary saja. Ia
tidak membuktikan data-volume write permission dengan named volume project,
Alertmanager configuration, readiness, route grouping, webhook payload,
firing/resolved delivery, Prometheus integration, persistence, rollback, atau
external notification flow.

## 🧾 Outcome

Generic Alertmanager runtime image sekarang tersedia secara lokal dan lulus
component verification. Exact upstream serta image hasil build dipertahankan;
image cleanup tidak termasuk authorization. Tidak ada source correction,
persistent container, named volume, network, receiver, secret, source-control
mutation, atau external-state integration yang dilakukan.

## ⏭️ Next Steps

Aktivitas terkecil berikutnya adalah menetapkan implementation plan non-secret
Alertmanager configuration, validator, Prometheus delivery reference, dan
isolated disposable receiver fixture berdasarkan TN-025. Persistent runtime,
actual Integration Bridge endpoint, secret source, dan TrueSight tetap
memerlukan prerequisite serta authorization terpisah.

## 🔗 Related Documentation

- [TN-026 — Establish Alertmanager Runtime Repository](TN-026-establish-alertmanager-runtime-repository.md)
- [TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract](TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

# TN-026 — Establish Alertmanager Runtime Repository

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-26 |
| Recorded Date | 2026-08-26 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-26 |

## 🎯 Objective

Membentuk source repository runtime Alertmanager generik berdasarkan ownership
dan lifecycle contract TN-025 tanpa membangun image atau menjalankan runtime.

## 🌍 Background

TN-025 menetapkan repository generik baru `alertmanager` sebagai owner upstream
pin, image identity, build, smoke test, run, dan cleanup lifecycle. Repository
`tomcat-monitoring` tetap memiliki Alertmanager configuration, routing,
receiver reference, validation, Prometheus delivery, dan orchestration.

Project owner kemudian menyediakan repository kosong
`/home/eddywiyatno/git/alertmanager` dan mengotorisasi kelanjutan aktivitas.
Repository belum memiliki commit, source, atau perubahan pengguna. Scope
session dikonfirmasi hanya untuk source runtime dan static verification; pull,
build, component test, container, volume, cleanup, commit, dan push tetap
memerlukan authorization terpisah.

## 📚 Scope

Aktivitas ini mencakup:

- Menambahkan governance khusus repository runtime Alertmanager.
- Menetapkan project identity `alertmanager` versi source `1.0.0`.
- Mem-pin upstream `quay.io/prometheus/alertmanager:v0.34.0`.
- Menambahkan minimal Containerfile yang mempertahankan official non-root user,
  entrypoint, binary, dan port contract.
- Menambahkan generic build, smoke-test, run, dan exact-container cleanup
  interfaces.
- Menambahkan README dan build-context exclusion untuk menjaga generic runtime
  boundary.
- Menjalankan static syntax, inventory, permission, whitespace, identity, dan
  sensitive-pattern verification.
- Memperbarui Engineering Journal dan current-state documentation sesuai hasil
  aktual.

Image pull, build, `podman run`, binary execution, component smoke test,
configuration project, receiver, secret, persistent resource, cleanup aktual,
commit, dan push tidak termasuk.

## 📋 Prerequisites

| Prerequisite | State | Evidence |
| --- | --- | --- |
| Runtime ownership contract | Completed and accepted. | TN-025. |
| Repository target | Available and empty. | Git melaporkan `No commits yet on main...origin/main [gone]`; initial `rg --files` tidak menemukan source. |
| User changes | Tidak ada pada repository target. | Initial Git status tidak menampilkan tracked atau untracked file. |
| Upstream identity | Defined. | TN-025 dan official Prometheus Download menetapkan release `0.34.0`. |
| Implementation authorization | Approved for source and static verification. | Project owner menyediakan repository dan meminta aktivitas dilanjutkan pada 2026-08-26. |

## ⚖️ Execution Decision

Source mengikuti pola lifecycle generik Prometheus dan Telegraf tanpa menyalin
configuration integration. Containerfile hanya menambahkan OCI labels di atas
official pinned image; official user dan entrypoint dipertahankan agar source
tidak mengarang runtime behavior sebelum build verification.

`run.sh` mewajibkan named configuration dan data volumes yang sudah tersedia,
tidak membuat keduanya, tidak memuat receiver atau secret, dan tidak
memublikasikan port secara default. Optional UI publication hanya mengikat
loopback `127.0.0.1`. `clean.sh` hanya menargetkan named container dan tidak
menghapus image, volume, atau data.

Keputusan tersebut menerapkan TN-025 dan TM-ADR-0001 tanpa mengubah topology
atau external-integration boundary, sehingga ADR baru tidak diperlukan.

## 📋 Implementation Plan

1. Tambahkan repository governance, identity metadata, upstream pin,
   build-context exclusions, dan Containerfile minimal.
2. Tambahkan build, smoke-test, run, serta cleanup interfaces yang tidak
   memiliki project configuration atau persistent default.
3. Tambahkan README yang menjelaskan contract dan verification boundary.
4. Terapkan executable mode pada scripts dan jalankan static verification.
5. Konsolidasikan hasil aktual ke Engineering Journal serta current-state
   documentation tanpa menyatakan image atau runtime telah diverifikasi.

## ⚙️ Implementation

Repository `alertmanager` sekarang memiliki:

- `AGENTS.md` untuk generic runtime, authorization, verification, cleanup, dan
  secret governance;
- `PROJECT`, `VERSION`, dan `CONFIG` untuk identity
  `localhost/alertmanager:1.0.0` serta upstream pin `v0.34.0`;
- `.containerignore` yang mengecualikan repository metadata dan common
  certificate, key, serta environment material;
- `Containerfile` minimal yang mempertahankan official runtime contract dan
  hanya menambahkan OCI labels;
- `scripts/build.sh` dengan `--pull=never` dan versioned image tags;
- `scripts/test.sh` untuk future Alertmanager version, `amtool` version, dan
  configured non-root user verification;
- `scripts/run.sh` dengan explicit configuration/data volumes, internal network,
  no-host-port default, optional loopback publication, dan exact collision
  check;
- `scripts/clean.sh` yang hanya menghapus named container dan tidak menyentuh
  image atau volumes; serta
- `README.md` yang membedakan static source, component build/test,
  configuration, persistent integration, dan external notification evidence.

Tidak ada `alertmanager.yml`, receiver, webhook URL, credential, certificate,
secret, data, automation deployment, atau runtime-generated artifact yang
ditambahkan.

## 🛠️ Troubleshooting

Initial `chmod 0755 scripts/*.sh` gagal untuk seluruh script dengan
`Read-only file system` karena repository baru belum termasuk writable sandbox
session. Tidak ada file content yang hilang atau berubah akibat kegagalan
tersebut.

Exact four-file `chmod` kemudian diulang setelah filesystem approval diberikan
dan berhasil. Final mode check membuktikan seluruh lifecycle script memiliki
mode `0755`.

## ⚙️ Commands Executed

```bash
# Repository handoff discovery
git status --short --branch
rg --files
for path in /home/eddywiyatno/git/alertmanager/AGENTS.md /home/eddywiyatno/git/AGENTS.md /home/eddywiyatno/AGENTS.md /home/AGENTS.md; do if test -f "$path"; then printf '%s\n' "$path"; fi; done

# Runtime precedent review
sed -n '1,280p' /home/eddywiyatno/git/prometheus/entrypoint.sh
sed -n '1,280p' /home/eddywiyatno/git/prometheus/scripts/build.sh
sed -n '1,280p' /home/eddywiyatno/git/prometheus/scripts/test.sh
sed -n '1,280p' /home/eddywiyatno/git/prometheus/scripts/run.sh
sed -n '1,280p' /home/eddywiyatno/git/prometheus/scripts/clean.sh
sed -n '1,280p' /home/eddywiyatno/git/prometheus/.containerignore
sed -n '1,280p' /home/eddywiyatno/git/telegraf/entrypoint.sh
sed -n '1,280p' /home/eddywiyatno/git/telegraf/scripts/build.sh
sed -n '1,280p' /home/eddywiyatno/git/telegraf/scripts/test.sh
sed -n '1,280p' /home/eddywiyatno/git/telegraf/scripts/run.sh
sed -n '1,280p' /home/eddywiyatno/git/telegraf/scripts/clean.sh
sed -n '1,280p' /home/eddywiyatno/git/telegraf/.containerignore

# Source inventory review after approved patch application
git status --short --branch
rg --files | sort
stat -c '%a %n' scripts/*.sh
sed -n '1,260p' AGENTS.md
sed -n '1,220p' README.md
sed -n '1,220p' CONFIG
sed -n '1,220p' Containerfile
sed -n '1,280p' scripts/build.sh
sed -n '1,280p' scripts/test.sh
sed -n '1,320p' scripts/run.sh
sed -n '1,220p' scripts/clean.sh

# Initial executable-mode application; failed because sandbox mounted target read-only
chmod 0755 scripts/*.sh

# Approved retry outside the read-only sandbox
chmod 0755 scripts/build.sh scripts/test.sh scripts/run.sh scripts/clean.sh

# Static source verification
bash -n CONFIG scripts/*.sh
rg -n '[[:blank:]]+$' . --glob '!/.git/**'
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@' . --glob '!/.git/**'
test "$(<PROJECT)" = alertmanager
test "$(<VERSION)" = 1.0.0
test "$(sed -n 's/^ALERTMANAGER_VERSION=//p' CONFIG)" = v0.34.0
test "$(sed -n 's/^BASE_IMAGE=//p' CONFIG)" = quay.io/prometheus/alertmanager:v0.34.0
test "$(stat -c '%a' scripts/build.sh)" = 755
test "$(stat -c '%a' scripts/test.sh)" = 755
test "$(stat -c '%a' scripts/run.sh)" = 755
test "$(stat -c '%a' scripts/clean.sh)" = 755
test -f AGENTS.md
test -f PROJECT
test -f VERSION
test -f CONFIG
test -f .containerignore
test -f Containerfile
test -f README.md
test -f scripts/build.sh
test -f scripts/test.sh
test -f scripts/run.sh
test -f scripts/clean.sh
git diff --check
git status --short --branch

# Handbook documentation verification
git diff --check
git status --short --branch
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md
rg -n 'TN-026|TN-026-establish-alertmanager' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/development/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-026-establish-alertmanager-runtime-repository.md
command -v mkdocs
```

Whitespace dan sensitive-pattern scans tidak menemukan match sehingga `rg`
mengembalikan exit code `1`, sesuai expected empty result. `git diff --check`
tidak menemukan error pada tracked diff; seluruh source masih untracked karena
repository belum memiliki initial commit. Inventory dan explicit content scans
melengkapi verification untuk untracked files.

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Shell syntax | `CONFIG` dan empat lifecycle scripts dapat diparse Bash. | Passed. | `bash -n CONFIG scripts/*.sh` exit `0`. |
| Source inventory | Governance, identity, build context, Containerfile, README, dan empat scripts tersedia. | Passed. | Eleven exact `test -f` checks lulus. |
| Identity and upstream pin | Project `alertmanager`, source version `1.0.0`, dan exact upstream `v0.34.0` konsisten. | Passed. | Explicit content assertions terhadap `PROJECT`, `VERSION`, dan `CONFIG` lulus. |
| Executable modes | Seluruh lifecycle scripts memiliki mode `0755`. | Passed after approved retry. | Empat exact `stat` assertions lulus. |
| Generic boundary | Tidak ada configuration project, receiver, secret material, persistent data, atau host-port default. | Passed untuk source inspection. | Targeted source review, `.containerignore`, README, Containerfile, dan scripts. |
| Whitespace and sensitive patterns | Tidak ada trailing whitespace atau material sensitif. | Passed. | Kedua targeted scans tidak menemukan match; `git diff --check` tidak menemukan error. |
| Documentation structure and navigation | TN-026, phase index, `.pages`, relative targets, dan current-state handoff konsisten. | Passed. | Heading inventory, navigation search, exact target checks, scans, dan handbook `git diff --check` lulus. |
| MkDocs render | Site dapat dirender tanpa error. | Not verified. | `mkdocs` executable tidak tersedia dan dependency tidak dipasang. |
| Image build and component smoke test | Image dibangun dari exact upstream dan binary, `amtool`, serta non-root runtime terbukti. | Not verified; di luar authorization TN-026. | Menjadi mandatory scope Technical Note build berikutnya. |
| Alertmanager configuration and integration | Route, receiver, webhook, firing/resolved, persistence, dan Prometheus delivery lulus. | Not verified; di luar scope TN-026. | Tetap menjadi activity integration setelah runtime image terverifikasi. |

## 🧾 Outcome

Source repository Alertmanager generik telah terbentuk dan lulus static syntax,
inventory, identity, executable-mode, whitespace, sensitive-pattern, serta
boundary review. Repository memiliki exact upstream pin dan lifecycle
interfaces tanpa mengambil alih configuration atau external integration milik
`tomcat-monitoring`.

Tidak ada image yang dipull atau dibangun, binary atau container yang
dijalankan, network atau volume yang dibuat, resource yang dibersihkan, maupun
Git commit atau push yang dilakukan. Karena itu image build, official runtime
user, binary compatibility, data permission, readiness, dan cleanup behavior
belum dapat dinyatakan terverifikasi.

## ⏭️ Next Steps

Technical Note berikutnya dapat membangun dan smoke-test image
`localhost/alertmanager:1.0.0` setelah exact image, pull policy, disposable
resource, expected result, dan cleanup authorization disetujui. Configuration
integration tidak dimulai sebelum runtime image lulus component verification.

## 🔗 Related Documentation

- [TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract](TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [Prometheus Download](https://prometheus.io/download/)

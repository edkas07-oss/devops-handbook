# TN-012 — Implement Prometheus Scrape Configuration and Lab Access

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-24 |
| Recorded Date | 2026-08-24 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-24 |

## 🎯 Objective

Mengimplementasikan scrape configuration Prometheus beserta validator
source-level dan menyediakan optional host-port publication untuk akses
dashboard pada environment lab.

## 🌍 Background

TN-011 menerima target scrape, timing, TLS trust reference, ownership, dan
validation boundary Prometheus. Project owner kemudian menyetujui
Implementation Gate TN-012 serta meminta agar dashboard Prometheus dapat
diakses dari tablet melalui VPN menggunakan hostname PC `edkas-pc1`.

Browser di tablet tidak dapat menggunakan container network alias. Akses
tersebut memerlukan port container `9090` dipublikasikan pada host, kemudian
tablet mengakses `http://edkas-pc1:<host-port>` melalui VPN.

## 📚 Scope

- Tambahkan `config/prometheus/prometheus.yml` non-secret untuk scrape JMX
  Exporter dan Telegraf sesuai TN-011.
- Tambahkan validator source-level Prometheus dan integrasikan dengan baseline
  validator repository `tomcat-monitoring`.
- Perbarui documentation contract yang langsung berubah.
- Perluas `prometheus/scripts/run.sh` agar caller dapat memberikan host port
  secara eksplisit tanpa menjadikannya default runtime.
- Catat implementation, verification, dan residual boundary pada TN-012.

Build, image pull, menjalankan container, perubahan VPN atau firewall,
certificate generation, semantic `promtool` execution, cleanup, commit,
publication, dan deployment tidak termasuk scope.

## 📋 Prerequisites

| Prerequisite | State | Evidence |
| --- | --- | --- |
| Prometheus scrape contract | Satisfied | Decision Gate TN-011 berstatus `Completed`. |
| Runtime ownership | Satisfied | Generic runtime berada pada repository `prometheus`; integration configuration berada pada `tomcat-monitoring`. |
| Source repositories | Satisfied | `tomcat-monitoring` dan `prometheus` bersih sebelum implementation. |
| Documentation worktree | Controlled | Hanya TN-011, phase index, dan navigation hasil aktivitas sebelumnya yang belum di-commit. |
| Runtime verification resources | Not required | Build, container, network runtime, CA material, dan cleanup berada di luar scope. |

## ⚖️ Execution Decision

- `prometheus.yml` menggunakan target internal
  `tomcat-jmx-exporter:9404` melalui HTTPS dan `telegraf:9273` melalui HTTP.
- Source validator memeriksa field contract dan larangan inline secret tanpa
  mengklaim semantic YAML validation.
- Runtime `run.sh` tetap tidak memublikasikan port secara default. Optional
  argumen keempat berupa host port akan menghasilkan publish
  `<host-port>:9090` untuk penggunaan lab yang disetujui caller.
- `edkas-pc1` tetap merupakan hostname PC pada VPN, bukan container alias dan
  tidak disimpan sebagai runtime default.

## 🛠️ Scope Changes

Setelah approval awal TN-012, project owner meminta perubahan
`prometheus/scripts/run.sh` agar dashboard lab dapat diakses dari tablet melalui
VPN. Project owner menjelaskan bahwa PC diakses menggunakan hostname
`edkas-pc1` dan menerima pemisahan antara container alias dengan host port
publication pada 2026-08-24.

Scope change diterima hanya untuk optional publish interface tanpa default
port. Menjalankan container, membuka firewall, mengubah VPN, atau membuktikan
akses browser tetap membutuhkan verification scope terpisah.

## 🛠️ Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Register the Technical Note and Navigation** | Membuat TN-012 dan memastikan urutannya dapat ditemukan. |
| **Implement the Prometheus Integration Configuration** | Menambahkan konfigurasi scrape dan validator pada `tomcat-monitoring`. |
| **Implement the Optional Lab Host Port** | Menambahkan argumen host port tanpa mengubah default runtime generik. |
| **Validate the Source Changes** | Menjalankan pemeriksaan sintaks, contract, input negatif, whitespace, dan diff. |
| **Consolidate the Handoff and Result Boundary** | Menutup aktivitas serta membedakan hasil source dari runtime yang belum diuji. |

## ⚙️ Implementation

### Prometheus integration configuration

Repository `tomcat-monitoring` menerima perubahan berikut:

| Source | Change |
| --- | --- |
| `config/prometheus/prometheus.yml` | Menambahkan dua scrape job, global interval `30s`, timeout `10s`, dan CA trust reference tanpa secret. |
| `scripts/validate-prometheus.sh` | Menambahkan structural contract checker untuk target, timing, TLS verification, jumlah job, dan inline-secret prohibition. |
| `scripts/validate.sh` | Mewajibkan artifact Prometheus dan menjalankan validator baru sebelum Telegraf validator. |
| Prometheus dan validation README | Mendokumentasikan contract, verification boundary, serta keputusan yang masih deferred. |
| Root README | Menyelaraskan repository status dan baseline validation capability. |

**Expected result.** Repository memiliki configuration dan validator lokal
yang dapat dijalankan tanpa dependency atau runtime.

**Actual result.** File configuration serta validator tersedia,
`validate-prometheus.sh` executable, dan baseline validation berhasil
menjalankan validator Prometheus serta Telegraf.

### Optional lab dashboard publication

Repository `prometheus` menerima perubahan berikut:

- `scripts/run.sh` menerima optional argumen keempat `[host-port]`;
- argumen kosong mempertahankan behavior tanpa published port;
- host port numerik `1-65535` menghasilkan `--publish
  <host-port>:9090`; dan
- README mencatat contoh `9090`, URL `http://edkas-pc1:9090`, serta VPN,
  firewall, dan trust boundary caller.

**Expected result.** Caller dapat meminta publication dashboard secara
eksplisit tanpa menambahkan environment-specific hostname atau published port
default pada runtime source.

**Actual result.** Source memenuhi expected interface. Non-numeric port dan
port `70000` ditolak sebelum command mencapai Podman; valid publication belum
dijalankan karena container runtime berada di luar scope.

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Register the Technical Note and Navigation

1. Buat TN-012 sebagai live record.
2. Daftarkan TN setelah TN-011 pada phase index dan navigation.
3. Pastikan file dan referensinya tersedia.

```bash
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md
rg -n 'TN-012-implement-prometheus-scrape-configuration-and-lab-access\.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
```

!!! success "Expected Result"

    TN-012 tersedia dan terdaftar setelah TN-011.

**Actual Result:** file dan kedua referensi navigation tersedia.

**Evidence:** `test -f` serta pencarian reference lulus.

</div>

<div class="procedure-step" markdown>

### Implement the Prometheus Integration Configuration

1. Tambahkan `prometheus.yml` dan validator Prometheus.
2. Hubungkan validator baru ke baseline validation.
3. Jalankan pemeriksaan source monitoring.

```bash
chmod 0755 scripts/validate-prometheus.sh
bash -n scripts/*.sh
./scripts/validate.sh
```

!!! success "Expected Result"

    Konfigurasi dan validator tersedia; seluruh validation source monitoring
    lulus tanpa menjalankan container.

**Actual Result:** validator Prometheus dan Telegraf dijalankan oleh baseline
validation dan seluruhnya lulus.

**Evidence:** tiga pesan success dari `./scripts/validate.sh` dan executable
check pada `scripts/validate-prometheus.sh`.

</div>

<div class="procedure-step" markdown>

### Implement the Optional Lab Host Port

1. Tambahkan argumen `[host-port]` pada `prometheus/scripts/run.sh`.
2. Pertahankan perilaku tanpa published port ketika argumen kosong.
3. Uji penolakan nilai non-numerik dan nilai di luar rentang.

```bash
bash -n entrypoint.sh scripts/*.sh
if ./scripts/run.sh README.md /tmp prometheus invalid; then exit 1; else printf 'Expected rejection passed: non-numeric host port was rejected before Podman execution.\n'; fi
if ./scripts/run.sh README.md /tmp prometheus 70000; then exit 1; else printf 'Expected rejection passed: out-of-range host port was rejected before Podman execution.\n'; fi
```

!!! success "Expected Result"

    Host port valid bersifat opsional, sedangkan input `invalid` dan `70000`
    ditolak sebelum Podman dijalankan.

**Actual Result:** kedua input negatif ditolak sesuai rencana dan default tanpa
host port tetap dipertahankan.

**Evidence:** kedua invocation berakhir non-zero dengan pesan rejection yang
diharapkan; shell syntax lulus.

</div>

<div class="procedure-step" markdown>

### Validate the Source Changes

Jalankan pemeriksaan ulang pada source monitoring, runtime Prometheus, dan
dokumentasi yang berubah.

```bash
git diff --check
rg -n '[[:blank:]]+$' README.md config/prometheus/README.md config/prometheus/prometheus.yml validation/README.md scripts/validate.sh scripts/validate-prometheus.sh
```

!!! success "Expected Result"

    Tidak ada syntax, contract, whitespace, atau perubahan di luar scope yang
    menggagalkan handoff.

**Actual Result:** pemeriksaan source dan dokumentasi lulus; trailing-whitespace
scan tidak menemukan match.

**Evidence:** hasil rinci per repository tersedia pada Commands Executed dan
tabel Verification.

</div>

<div class="procedure-step" markdown>

### Consolidate the Handoff and Result Boundary

1. Catat artifact yang telah tersedia.
2. Catat semantic validation dan browser access sebagai `Not verified`.
3. Arahkan runtime verification ke TN-013.

!!! success "Expected Result"

    Pembaca dapat membedakan source yang telah diverifikasi dari runtime dan
    akses browser yang belum diuji.

**Actual Result:** Outcome dan Next Steps menyatakan batas tersebut dan
menyerahkan runtime verification ke TN-013.

**Evidence:** tabel Verification, Outcome, dan Related Documentation konsisten.

</div>

</div>

## ✅ Verification

| Verification | Expected result | Actual result and evidence |
| --- | --- | --- |
| Monitoring shell syntax | Seluruh script lolos `bash -n`. | Passed; `bash -n scripts/*.sh` selesai tanpa error. |
| Monitoring baseline | Layout, sensitive filename, Prometheus contract, dan Telegraf contract lulus. | Passed; `./scripts/validate.sh` menampilkan tiga success message. |
| Prometheus runtime shell syntax | Entrypoint dan seluruh script lolos `bash -n`. | Passed; command selesai tanpa error. |
| Invalid host port | Nilai non-numeric dan di luar range ditolak sebelum Podman. | Passed; `invalid` dan `70000` masing-masing menghasilkan pesan rejection yang diharapkan. |
| Source whitespace | Tidak ada whitespace error atau trailing whitespace pada target source. | Passed; `git diff --check` lulus dan trailing-whitespace scan tidak menghasilkan match. |
| Semantic Prometheus config | `promtool check config` menerima configuration. | Not verified; execution tidak termasuk approved scope. |
| Browser access | Tablet dapat membuka dashboard melalui `http://edkas-pc1:9090`. | Not verified; container run, VPN route, firewall, dan browser test tidak termasuk scope. |

## ⚙️ Commands Executed

### Source readiness review

```bash
git status --short --branch
sed -n '1,260p' README.md
sed -n '1,260p' config/prometheus/README.md
sed -n '1,320p' scripts/validate.sh
sed -n '1,260p' validation/README.md
sed -n '1,260p' scripts/validate-telegraf.sh
git status --short --branch
sed -n '1,260p' README.md
sed -n '1,240p' CONFIG
sed -n '1,300p' scripts/run.sh
sed -n '1,280p' scripts/test.sh
git status --short --branch
git diff --check
git diff -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-define-prometheus-scrape-configuration-contract.md
```

### Monitoring source implementation verification

```bash
chmod 0755 scripts/validate-prometheus.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
git status --short --branch
git diff -- README.md config/prometheus/README.md config/prometheus/prometheus.yml validation/README.md scripts/validate.sh scripts/validate-prometheus.sh
test -x scripts/validate-prometheus.sh
sed -n '1,240p' config/prometheus/prometheus.yml
sed -n '1,300p' scripts/validate-prometheus.sh
rg -n '[[:blank:]]+$' README.md config/prometheus/README.md config/prometheus/prometheus.yml validation/README.md scripts/validate.sh scripts/validate-prometheus.sh
```

`bash -n`, baseline validation, executable check, dan `git diff --check`
berhasil. Trailing-whitespace scan tidak menghasilkan match.

### Prometheus runtime source verification

```bash
bash -n entrypoint.sh scripts/*.sh
if ./scripts/run.sh README.md /tmp prometheus invalid; then exit 1; else printf 'Expected rejection passed: non-numeric host port was rejected before Podman execution.\n'; fi
if ./scripts/run.sh README.md /tmp prometheus 70000; then exit 1; else printf 'Expected rejection passed: out-of-range host port was rejected before Podman execution.\n'; fi
git diff --check
git status --short --branch
git diff -- README.md scripts/run.sh
sed -n '1,260p' scripts/run.sh
sed -n '1,240p' README.md
rg -n '[[:blank:]]+$' README.md scripts/run.sh
```

Dua invocation `run.sh` merupakan negative validation. Keduanya berakhir
non-zero dengan pesan yang diharapkan sebelum Podman dijalankan. Shell syntax
dan whitespace check lulus; trailing-whitespace scan tidak menghasilkan match.

### Documentation worktree review

```bash
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git diff --check
git status --short --branch
```

Trailing-whitespace scan tidak menghasilkan match dan tracked documentation
diff tidak memiliki whitespace error. TN-011 serta TN-012 masih untracked;
tidak ada commit yang dibuat.

### Final source and documentation review

Repository `tomcat-monitoring`:

```bash
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
if rg -n '[[:blank:]]+$' README.md config/prometheus/README.md config/prometheus/prometheus.yml validation/README.md scripts/validate.sh scripts/validate-prometheus.sh; then exit 1; fi
test -x scripts/validate-prometheus.sh
git status --short --branch
```

Repository `prometheus`:

```bash
bash -n entrypoint.sh scripts/*.sh
git diff --check
if rg -n '[[:blank:]]+$' README.md scripts/run.sh; then exit 1; fi
rg -n 'host-port|host_port|--publish|edkas-pc1|9090' README.md scripts/run.sh
git status --short --branch
```

Repository `devops-handbook`:

```bash
git diff --check
if rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages; then exit 1; fi
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-define-prometheus-scrape-configuration-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
rg -n '^#|Status \||TN-012|Scope Changes|Verification|Outcome' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
command -v mkdocs
git status --short --branch
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md
```

Seluruh source-level check lulus. `command -v mkdocs` tidak menghasilkan path;
dependency tidak dipasang dan render validation berstatus `Not verified`.

### Final closure verification

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring diff --check
/home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
git -C /home/eddywiyatno/git/prometheus diff --check
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
git diff --check
rg -n '^\| Status \| Completed \|$|^## (🎯 Objective|🌍 Background|📚 Scope|📋 Prerequisites|⚖️ Execution Decision|🛠️ Scope Changes|🛠️ Implementation Plan|⚙️ Implementation|✅ Verification|⚙️ Commands Executed|🧾 Outcome|⏭️ Next Steps|🔗 Related Documentation)$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-implement-prometheus-scrape-configuration-and-lab-access.md
rg -n 'TN-012-implement-prometheus-scrape-configuration-and-lab-access\.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git status --short --branch
```

## 🔄 Source-Control Handoff

Prometheus scrape configuration, validator, dan volume-initialization contract
pada repository `tomcat-monitoring` disimpan pada commit `0df9414`.

## 🧾 Outcome

Approved implementation selesai pada repository `tomcat-monitoring`,
`prometheus`, dan Engineering Journal. Scrape configuration serta validator
source-level tersedia, sedangkan runtime Prometheus mempertahankan no-publish
default dan menerima host port optional untuk penggunaan lab.

Source validation lulus. Tidak ada container, image, network, firewall, VPN,
atau browser state yang diubah. Semantic configuration, live scrape, dan akses
`http://edkas-pc1:9090` belum diverifikasi; MkDocs render juga belum
diverifikasi karena executable tidak tersedia.

## ⏭️ Next Steps

Aktivitas berikutnya memerlukan authorization terpisah untuk menjalankan
`promtool`, menyiapkan CA test, menjalankan container dengan target dan cleanup
yang spesifik, serta memverifikasi akses browser melalui
`http://edkas-pc1:9090`.

## 🔗 Related Documentation

- [TN-011 — Define Prometheus Scrape Configuration Contract](TN-011-define-prometheus-scrape-configuration-contract.md)
- [Monitoring Integration and Runtime Deployment](index.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)

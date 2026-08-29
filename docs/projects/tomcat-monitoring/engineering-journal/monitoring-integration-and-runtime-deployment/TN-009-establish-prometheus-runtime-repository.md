# TN-009 — Establish Prometheus Runtime Repository

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-22 |
| Recorded Date | 2026-08-22 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-22 |

## 🎯 Objective

Membentuk repository `prometheus` sebagai OCI runtime generik terpisah sebelum configuration scrape dan integrasi Prometheus dimulai pada `tomcat-monitoring`.

## 🌍 Background

Telegraf telah memiliki repository runtime generik, sedangkan Prometheus belum
memiliki source owner untuk upstream pin, image build, smoke test, run, dan
cleanup. Konfigurasi scrape tetap harus dimiliki `tomcat-monitoring` agar image
runtime dapat digunakan kembali tanpa target atau secret project.

## ⚖️ Runtime Component Ownership Gate

| Question | Decision |
| --- | --- |
| Reusable image lifecycle? | Ya: upstream pinning, build, smoke test, entrypoint, run, dan cleanup. |
| Existing generic runtime? | Tidak ada; repository `/home/eddywiyatno/git/prometheus` baru tersedia dan kosong. |
| Generic runtime owner | Repository `prometheus`. |
| Project configuration owner | Repository `tomcat-monitoring`. |
| Upstream pin | `docker.io/prom/prometheus:v3.13.2`, LTS terbaru pada halaman download resmi saat assessment. |

## 📚 Scope

Repository `prometheus` hanya akan berisi metadata image, Containerfile, entrypoint generik, README, dan script local lifecycle. `prometheus.yml`, scrape target JMX Exporter/Telegraf, alert rules, credentials, TLS material, data volume, port host, target deployment, dan publication berada di luar scope TN ini.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Inspect Repository Availability and the Runtime Pattern** | Memeriksa repository kosong dan mempelajari pola lifecycle Telegraf. |
| **Verify the Official Upstream Selection** | Memilih Prometheus LTS dan memeriksa mount contract resmi. |
| **Implement the Generic Runtime Source** | Menambahkan metadata, Containerfile, entrypoint, dan lifecycle scripts tanpa konfigurasi project. |
| **Apply Executable Modes and Run Static Validation** | Memeriksa permission, shell syntax, whitespace, dan file inventory. |
| **Record the Runtime Handoff** | Mencatat hasil source-level dan batas sebelum build serta smoke test. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Inspect Repository Availability and the Runtime Pattern

**Purpose.** Memastikan repository target tersedia serta membandingkan contract generik Telegraf tanpa menyalin configuration integration.

**Command actually executed.**

```bash
test -d /home/eddywiyatno/git/prometheus && printf 'directory=present\n' || printf 'directory=absent\n'
git -C /home/eddywiyatno/git/prometheus status --short --branch
rg --files /home/eddywiyatno/git/prometheus -g 'AGENTS.md' -g 'README.md' -g 'Containerfile' -g 'CONFIG' -g 'PROJECT' -g 'VERSION' -g 'entrypoint.sh' -g 'scripts/*' | sort
sed -n '1,240p' /home/eddywiyatno/git/telegraf/README.md
sed -n '1,220p' /home/eddywiyatno/git/telegraf/Containerfile
sed -n '1,240p' /home/eddywiyatno/git/telegraf/scripts/run.sh
sed -n '1,220p' /home/eddywiyatno/git/telegraf/scripts/test.sh
```

!!! success "Expected Result"

    Repository Prometheus tersedia, tidak ada source awal, dan pattern runtime
    generik dapat direview.

**Actual Result:** directory tersedia dan belum memiliki source awal.

**Evidence:** Git menyatakan `No commits yet on main...origin/main [gone]`;
pencarian source kosong dan repository Telegraf hanya direview sebagai pola.

</div>

<div class="procedure-step" markdown>

### Verify the Official Upstream Selection

**Purpose.** Memilih versi upstream yang stabil dan dipin sebelum source image dibuat.

**Method actually used.** Halaman Download dan Installation Prometheus resmi direview pada 2026-08-22.

!!! success "Expected Result"

    Versi upstream dan contract mount configuration/data dapat dibuktikan tanpa
    menjalankan image.

**Actual Result:** Prometheus `v3.13.2` dipilih sebagai LTS tanpa menjalankan
image atau membuat volume.

**Evidence:** halaman Download dan Installation resmi mencatat versi serta
mount path `/etc/prometheus/prometheus.yml` dan `/prometheus`.

</div>

<div class="procedure-step" markdown>

### Implement the Generic Runtime Source

**Purpose.** Menyediakan lifecycle image reusable tanpa memasukkan configuration atau deployment contract milik solution monitoring.

**Implementation actually performed.** Source berikut ditambahkan pada repository `/home/eddywiyatno/git/prometheus`: `AGENTS.md`, `PROJECT`, `VERSION`, `CONFIG`, `.containerignore`, `Containerfile`, `entrypoint.sh`, `README.md`, serta `scripts/build.sh`, `scripts/test.sh`, `scripts/run.sh`, dan `scripts/clean.sh`.

!!! success "Expected Result"

    Runtime pin, image identity, entrypoint, dan lifecycle interface tersedia;
    konfigurasi serta data runtime project tidak ikut masuk source.

**Actual Result:** source runtime generik berhasil dibuat tanpa konfigurasi atau
data project.

**Evidence:** `CONFIG` mem-pin `docker.io/prom/prometheus:v3.13.2`; entrypoint
dan lifecycle scripts mempertahankan input configuration/data dari caller.

</div>

<div class="procedure-step" markdown>

### Apply Executable Modes and Run Static Validation

**Purpose.** Memastikan entrypoint dan lifecycle scripts dapat dijalankan dan memiliki sintaks shell yang valid sebelum image build diotorisasi.

**Command actually executed.**

```bash
chmod 0755 /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/build.sh /home/eddywiyatno/git/prometheus/scripts/test.sh /home/eddywiyatno/git/prometheus/scripts/run.sh /home/eddywiyatno/git/prometheus/scripts/clean.sh
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
git -C /home/eddywiyatno/git/prometheus diff --check
git -C /home/eddywiyatno/git/prometheus status --short
```

!!! success "Expected Result"

    File executable; tidak ada syntax atau whitespace error; status hanya
    menampilkan source runtime baru yang belum di-commit.

**Actual Result:** permission, shell syntax, dan whitespace check lulus.

**Evidence:** status menampilkan tepat source runtime baru sebagai untracked
files dan tidak menampilkan artifact di luar scope.

</div>

<div class="procedure-step" markdown>

### Record the Runtime Handoff

1. Catat artifact source yang telah tersedia.
2. Catat bahwa build, image pull, smoke test, dan runtime belum dilakukan.
3. Tautkan ADR ownership dan TN build berikutnya.

!!! success "Expected Result"

    Pembaca dapat membedakan source yang telah divalidasi dari image dan runtime
    yang belum diuji.

**Actual Result:** repository generik tersedia dan lulus static validation;
build serta runtime tetap menjadi scope TN-010.

**Evidence:** Outcome, Next Steps, dan TM-ADR-0002 mencatat handoff serta batas
hasil.

</div>

</div>

## 🖥️ Commands Executed

Command aktual tersedia pada empat procedure step pertama. Tahap `Record the
Runtime Handoff` mengonsolidasikan evidence dan tidak menambahkan runtime
command baru.

## 🧾 Outcome

Repository Prometheus generik telah tersedia dan lolos static validation. Ia belum dibangun, dipull, diuji sebagai image, atau dijalankan. Karena itu tidak ada klaim bahwa binary Prometheus, permission data runtime, scrape, storage, atau monitoring end-to-end sudah terverifikasi.

## ⏭️ Next Steps

Langkah paling dekat adalah local build dan smoke test image Prometheus pada scope terpisah. Setelah runtime image lulus, configuration `prometheus.yml` dan scrape target JMX Exporter/Telegraf dapat dimulai sebagai Technical Note integration berikutnya.

## 🔗 Related Documentation

- [TM-ADR-0002 — Separate Generic Runtime Images from Monitoring Integration Configuration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md)
- [Prometheus Download](https://prometheus.io/download/)
- [Prometheus Installation](https://prometheus.io/docs/prometheus/latest/installation/)
- [TN-006 — Establish Telegraf Runtime Repository](TN-006-establish-telegraf-runtime-repository.md)

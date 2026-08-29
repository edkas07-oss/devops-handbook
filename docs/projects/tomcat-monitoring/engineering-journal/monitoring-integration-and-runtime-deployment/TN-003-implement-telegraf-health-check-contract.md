# TN-003 — Implement Telegraf Health Check Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Menyediakan configuration Telegraf non-secret dan validator source-level untuk
memeriksa health endpoint Tomcat sesuai contract sementara yang disetujui.

## 🌍 Background

Project owner menyetujui contract sementara: `GET /health` melalui internal
Tomcat port `8080`, HTTP `200`, body yang menyatakan status `UP`, timeout lima
detik, dan interval tiga puluh detik. Port internal Telegraf `9273` digunakan
sebagai asumsi sementara karena merupakan default documented untuk
`outputs.prometheus_client`; ia belum menjadi deployment decision.

## 📚 Scope

Aktivitas ini membuat satu configuration Telegraf dan validator Bash yang
memeriksa contract statis. Target URL diberikan melalui environment variable
non-secret agar nama container tidak dikunci dalam source. Aktivitas tidak
menentukan image version, menjalankan Telegraf atau Prometheus, membangun image,
membuat container/network, maupun memverifikasi application endpoint nyata.

## 📋 Prerequisites

- Baseline repository dan `scripts/validate.sh` tersedia dari TN-002.
- Contract sementara health check telah disetujui oleh project owner.
- Configuration menggunakan `inputs.http_response` dan
  `outputs.prometheus_client` sesuai documentation upstream.

## ⚖️ Execution Decision

Configuration memakai `${TOMCAT_HEALTH_URL}` sebagai input runtime non-secret,
`response_status_code = 200`, regex body status `UP`, timeout `5s`, interval
`30s`, dan Prometheus client internal `:9273/metrics`. Ini merupakan
implementation contract sementara, bukan penetapan deployment topology final.

## ⚙️ Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Prepare the Telegraf Health-Check Contract** | Menambahkan konfigurasi, validator component, dan integrasi validator baseline. |
| **Validate the Shell Scripts** | Memastikan seluruh validator Bash memiliki sintaks yang valid. |
| **Validate the Telegraf Source Contract** | Memeriksa field health check yang diwajibkan. |
| **Validate the Integrated Baseline** | Memastikan validator Telegraf dipanggil oleh interface utama. |
| **Check the Runtime Verification Boundary** | Memeriksa ketersediaan binary dan mencatat bagian yang belum diuji. |

## ⚙️ Implementation

`config/telegraf/health-check.conf` menggunakan `inputs.http_response` dan
`outputs.prometheus_client`. Target URL berasal dari
`TOMCAT_HEALTH_URL`, sehingga deployment nanti menentukan nama container tanpa
mengubah source. `scripts/validate-telegraf.sh` memeriksa field contract, dan
`scripts/validate.sh` menjalankan validator component tersebut sebagai bagian
dari baseline repository validation.

## ⚙️ Execution Record

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Prepare the Telegraf Health-Check Contract

Tambahkan artifact pada bagian Implementation dan jadikan validator component
dapat dijalankan.

```bash
chmod 0755 /home/eddywiyatno/git/tomcat-monitoring/scripts/validate-telegraf.sh
```

!!! success "Expected Result"

    Konfigurasi dan validator tersedia; validator memiliki permission executable.

**Actual Result:** artifact tersedia dan permission berhasil diterapkan.

**Evidence:** command `chmod` selesai tanpa error.

</div>

<div class="procedure-step" markdown>

### Validate the Shell Scripts

```bash
bash -n /home/eddywiyatno/git/tomcat-monitoring/scripts/*.sh
```

!!! success "Expected Result"

    Seluruh validator Bash memiliki sintaks yang valid.

**Actual Result:** pemeriksaan lulus.

**Evidence:** command selesai tanpa syntax error.

</div>

<div class="procedure-step" markdown>

### Validate the Telegraf Source Contract

```bash
/home/eddywiyatno/git/tomcat-monitoring/scripts/validate-telegraf.sh
```

!!! success "Expected Result"

    Field URL, status, body, timeout, interval, dan endpoint metrics sesuai
    contract.

**Actual Result:** validator component lulus.

**Evidence:** output `Telegraf source validation passed`.

</div>

<div class="procedure-step" markdown>

### Validate the Integrated Baseline

```bash
/home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
```

!!! success "Expected Result"

    Interface baseline menjalankan validator Telegraf dan keduanya lulus.

**Actual Result:** kedua validation lulus.

**Evidence:** output success dari validator Telegraf dan baseline.

</div>

<div class="procedure-step" markdown>

### Check the Runtime Verification Boundary

```bash
command -v telegraf
```

!!! success "Expected Result"

    Ketersediaan binary diketahui sehingga batas runtime verification dapat
    dicatat dengan tepat.

**Actual Result:** binary tidak ditemukan; parse test tidak dijalankan.

**Evidence:** `command -v telegraf` tidak menghasilkan path. Runtime parse
ditandai `Not verified`, bukan dianggap berhasil.

</div>

</div>

## ✅ Verification

| Criterion | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Shell syntax | `bash -n scripts/*.sh` | Seluruh script Bash valid | Passed | Command selesai tanpa syntax error. |
| Telegraf source contract | `./scripts/validate-telegraf.sh` | Field URL, status, body, timeout, interval, dan metrics endpoint sesuai contract | Passed | Output: `Telegraf source validation passed: health-check contract statis valid.` |
| Baseline integration | `./scripts/validate.sh` | Validator component dipanggil oleh interface baseline | Passed | Validator Telegraf berjalan dan baseline validation lulus. |
| Whitespace | `git diff --check` | Tidak ada whitespace error | Passed | Command selesai tanpa output error. |
| Handbook render | `mkdocs` availability check | Render documentation diperiksa bila tool tersedia | Not verified | Command `mkdocs` tidak tersedia; dependency tidak dipasang karena di luar scope. |
| Telegraf runtime parse | `telegraf --test` | Binary mem-parsing configuration | Not verified | Binary `telegraf` tidak tersedia; dependency tidak dipasang dan runtime tidak diotorisasi. |
| Prometheus scrape and application health | Container-based integration test | Prometheus mengambil Telegraf metrics dan endpoint aplikasi memenuhi contract | Not verified | Tidak ada container, network, atau deployment dalam scope aktivitas ini. |

## 📝 Commands Executed

```bash
bash -n scripts/*.sh
./scripts/validate-telegraf.sh
./scripts/validate.sh
git diff --check
git -C devops-handbook diff --check -- docs/projects/tomcat-monitoring
command -v telegraf
command -v mkdocs
```

## 📝 Documentation Mapping

Source contract berada pada `config/telegraf/health-check.conf`; validator
source-level berada pada `scripts/validate-telegraf.sh`. Infrastructure dan
project current-state documentation diperbarui untuk menandai contract ini
sebagai implemented locally tetapi belum runtime-verified.

## 🧾 Outcome

Telegraf health-check contract sementara telah diimplementasikan dan lolos
source validation. Tidak ada klaim bahwa Telegraf, Prometheus, atau application
endpoint telah berjalan. Port `9273` dan parameter contract lainnya harus
dikonfirmasi ulang pada design deployment sebelum digunakan pada target runtime.

## ⏭️ Next Steps

Component verification telah diotorisasi dengan resource berikut:

| Resource | Exact scope |
| --- | --- |
| Telegraf image | Pull `docker.io/library/telegraf:1.39.3-alpine`; tag patch dipin, bukan `latest`. |
| Fixture image | Pull `docker.io/library/busybox:1.38.0` untuk HTTP fixture dan client sementara. |
| Network | Buat lalu hapus `tomcat-monitoring-verify`; tidak ada port host yang dipublikasikan. |
| Fixture container | Buat lalu hapus `tomcat-monitoring-health-fixture`, menyediakan `/health` pada port container `8080`. |
| Telegraf container | Buat lalu hapus `tomcat-monitoring-telegraf-verify`, mengekspos `9273/metrics` hanya pada network test. |
| Temporary files | Buat di temporary directory `/tmp` dan hapus setelah test; tidak ada named volume atau secret production. |

Verification harus memeriksa respons sehat (`200` dan body status `UP`), body
tidak sesuai, dan status tidak sesuai. Hasilnya hanya dapat membuktikan parse
configuration dan behavior `inputs.http_response`/`outputs.prometheus_client`
pada component test. Prometheus scrape, application Tomcat nyata, TLS, dan
deployment tetap `Not verified` sampai scope terpisah disetujui.

## 🔗 Related Documentation

- [TN-002 — Initialize Monitoring Repository Validation Contract](TN-002-initialize-monitoring-repository-validation-contract.md)
- [Telegraf HTTP Response Input Plugin](https://docs.influxdata.com/telegraf/v1/input-plugins/http_response/)
- [Telegraf Prometheus Client Output Plugin](https://docs.influxdata.com/telegraf/v1/output-plugins/prometheus_client/)
- [Telegraf Environment Variables](https://docs.influxdata.com/telegraf/v1/configuration/environment-variables/)
- [Infrastructure](../../infrastructure/index.md)

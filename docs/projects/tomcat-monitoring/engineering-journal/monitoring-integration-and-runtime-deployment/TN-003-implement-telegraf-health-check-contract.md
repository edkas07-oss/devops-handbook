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

1. Tambahkan configuration Telegraf dengan input HTTP response dan output
   Prometheus client.
2. Tambahkan validator yang memeriksa field contract wajib tanpa memerlukan
   binary Telegraf.
3. Integrasikan validator component ke baseline validation interface.
4. Jalankan syntax dan source validation; catat batas runtime verification.

## ⚙️ Implementation

`config/telegraf/health-check.conf` menggunakan `inputs.http_response` dan
`outputs.prometheus_client`. Target URL berasal dari
`TOMCAT_HEALTH_URL`, sehingga deployment nanti menentukan nama container tanpa
mengubah source. `scripts/validate-telegraf.sh` memeriksa field contract, dan
`scripts/validate.sh` menjalankan validator component tersebut sebagai bagian
dari baseline repository validation.

## ⚙️ Execution Record

| Sequence | Purpose | Command actually executed | Expected / actual result |
| --- | --- | --- | --- |
| 1 | Make component validator executable | `chmod 0755 /home/eddywiyatno/git/tomcat-monitoring/scripts/validate-telegraf.sh` | Expected executable script; actual completed. |
| 2 | Validate all Bash scripts | `bash -n /home/eddywiyatno/git/tomcat-monitoring/scripts/*.sh` | Expected no syntax error; actual passed. |
| 3 | Validate Telegraf contract | `/home/eddywiyatno/git/tomcat-monitoring/scripts/validate-telegraf.sh` | Expected mandatory fields match approved contract; actual output `Telegraf source validation passed`. |
| 4 | Validate integrated baseline | `/home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh` | Expected parent validator invokes component validator; actual both validations passed. |
| 5 | Check runtime binary availability | `command -v telegraf` | Expected observation only; actual no binary found, so parse test remained not verified. |

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

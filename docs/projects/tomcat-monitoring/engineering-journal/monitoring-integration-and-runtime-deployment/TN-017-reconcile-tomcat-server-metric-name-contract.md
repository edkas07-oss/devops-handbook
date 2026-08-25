# TN-017 — Reconcile Tomcat Server Metric Name Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-25 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Menyelaraskan JMX Exporter source contract, static validator, dan documentation
dengan canonical runtime metric name `tomcat_server` yang dibuktikan TN-016.

## 🌍 Background

TN-016 memverifikasi bahwa rule bernama `tomcat_server_info` menghasilkan
runtime series `tomcat_server`. Upstream JMX Exporter mengklasifikasikan
penghapusan suffix `_info` sebagai working-as-designed behavior, sedangkan
Prometheus client naming contract menyatakan `_info` merupakan reserved suffix
yang dihapus dari base metric name saat sanitization.

Project owner menerima `tomcat_server` sebagai canonical runtime contract dan
menyetujui source-only reconciliation pada 2026-08-25.

## 📚 Scope

- Ubah JMX Exporter baseline rule dari `tomcat_server_info` menjadi
  `tomcat_server`.
- Selaraskan static validator dan component README.
- Tutup Open Question TN-016 secara append-oriented dan konsolidasikan
  current-state documentation.
- Jalankan shell syntax, component dan repository validators, whitespace,
  diff, navigation, serta documentation checks.

Container, volume, TLS material, runtime verification baru, dependency, image
build, cleanup runtime, dan commit tidak termasuk scope. TN-014 serta
TN-015 dipertahankan sebagai historical records.

## 📋 Prerequisites

| Prerequisite | Expected state | Initial result |
| --- | --- | --- |
| Runtime evidence | TN-016 membuktikan actual series `tomcat_server`. | Passed. |
| Decision | Project owner menerima `tomcat_server` sebagai canonical contract. | Passed on 2026-08-25. |
| Source repository | `tomcat-monitoring` bersih sebelum implementation. | Passed. |
| Documentation repository | Hanya perubahan TN-016 yang terotorisasi tersedia. | Passed; changes dipertahankan. |

## ⚖️ Execution Decision

Gunakan `tomcat_server` sebagai canonical source dan downstream metric name.
Keputusan ini mengikuti observed runtime behavior serta upstream reserved-name
sanitization dan menghindari contract yang tidak dapat dihasilkan oleh current
JMX Exporter runtime.

## 🗺️ Implementation Plan

1. Buat live TN-017 dan navigation entry.
2. Ubah exact metric name pada configuration, validator, dan component README.
3. Catat resolution pada TN-016 dan hapus pending mismatch dari current-state
   pages tanpa mengubah historical TN-014 atau TN-015.
4. Jalankan seluruh source dan documentation verification dalam scope.
5. Finalisasi status, outcome, residual boundary, dan next step.

## ⚙️ Commands Executed

### Readiness and decision discovery

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/devops-handbook status --short --branch
rg -n 'tomcat_server_info|tomcat_server|two-rule|baseline metric' /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring --glob '!engineering-journal/**'
sed -n '1,280p' /home/eddywiyatno/git/tomcat-monitoring/scripts/validate-jmx-exporter.sh
sed -n '1,180p' /home/eddywiyatno/git/tomcat-monitoring/config/jmx-exporter/jmx-exporter.yml
sed -n '1,200p' /home/eddywiyatno/git/tomcat-monitoring/config/jmx-exporter/README.md
```

Source repository bersih. Handbook hanya memiliki authorized TN-016 journal,
navigation, dan current-state changes. Exact source references berada pada
configuration, validator, dan component README.

### Source validation and review

```bash
bash -n scripts/*.sh
./scripts/validate-jmx-exporter.sh
./scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$' config/jmx-exporter/jmx-exporter.yml config/jmx-exporter/README.md scripts/validate-jmx-exporter.sh
rg -n 'tomcat_server_info|tomcat_server' config/jmx-exporter/jmx-exporter.yml config/jmx-exporter/README.md scripts/validate-jmx-exporter.sh
git diff -- config/jmx-exporter/jmx-exporter.yml config/jmx-exporter/README.md scripts/validate-jmx-exporter.sh
git status --short --branch
```

Shell syntax, component validator, dan repository baseline validator lulus.
Diff serta trailing-whitespace checks bersih. Source diff berisi tepat tiga
files dan mempertahankan TLS structure, dua-rule count, password reference,
serta secret boundary.

### Documentation validation and final review

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-reconcile-tomcat-server-metric-name-contract.md
rg -n 'TN-016|TN-017|tomcat_server_info|tomcat_server|Resolution recorded by TN-017' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-reconcile-tomcat-server-metric-name-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-reconcile-tomcat-server-metric-name-contract.md
command -v mkdocs
git diff --stat
git status --short --branch
```

Handbook diff dan trailing-whitespace checks lulus. TN-016 serta TN-017
tersedia dan terdaftar berurutan pada navigation serta phase index. Historical
expected name tetap berada pada TN-014, TN-015, dan TN-016 evidence; resolution
dicatat pada TN-016 serta TN-017 tanpa menulis ulang evidence lama. MkDocs
render berstatus `Not verified` karena executable tidak tersedia dan dependency
tidak dipasang.

## 🛠️ Implementation

1. Mengubah JMX Exporter baseline rule name dari `tomcat_server_info` menjadi
   `tomcat_server` tanpa mengubah pattern, value, label, atau type.
2. Mengubah exact static-validator expectation ke `tomcat_server`.
3. Mendokumentasikan reserved `_info` normalization dan canonical runtime name
   pada component README.
4. Menambahkan resolution append-oriented pada TN-016 dan menyelaraskan project
   overview, Development, Operations, serta phase overview.
5. Mempertahankan TN-014 dan TN-015 sebagai historical decision serta
   implementation evidence.

## ✅ Verification

| Method | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| Shell syntax | Seluruh scripts valid. | Passed. | `bash -n scripts/*.sh`. |
| Component validation | Exact canonical name dan two-rule TLS contract diterima. | Passed. | `./scripts/validate-jmx-exporter.sh`. |
| Repository validation | Seluruh component contracts tetap valid. | Passed. | `./scripts/validate.sh`. |
| Source scope | Hanya configuration, component validator, dan README berubah. | Passed. | Targeted diff dan Git status. |
| Historical boundary | TN-014, TN-015, dan TN-016 evidence tidak ditulis ulang. | Passed. | Targeted reference review; resolution ditambahkan secara append-oriented. |
| Documentation | Diff, whitespace, navigation, links, dan current-state boundary valid. | Passed kecuali MkDocs render tidak tersedia. | Handbook checks dan file existence tests. |
| Runtime boundary | Tidak ada runtime atau image mutation. | Passed by executed-command review. | Tidak ada Podman, build, TLS, atau cleanup command pada TN-017. |

## 🔄 Source-Control Handoff

Canonical `tomcat_server` source contract disimpan pada commit repository
`tomcat-monitoring` `9975139`. Isolated TLS verification, metric-name
reconciliation, navigation, dan current-state documentation disimpan pada
commit Handbook `aa2cbf9`.

## 🧾 Outcome

Source contract, validator, dan documentation kini menggunakan
`tomcat_server` sebagai canonical baseline metric name. Open Question TN-016
ditutup melalui accepted decision dan append-oriented resolution. Seluruh
mandatory source-level verification lulus.

Tidak ada container, volume, TLS material, runtime test, dependency, image,
atau external state yang diubah. Runtime behavior tidak diuji ulang karena
berada di luar approved source-only scope; observed behavior tetap menggunakan
evidence TN-016. Source dan documentation changes kemudian disimpan sesuai
`Source-Control Handoff`.

## ⏭️ Next Steps

Persistent JMX scrape integration tetap memerlukan activity dan authorization
terpisah.

## 🔗 Related Documentation

- [TN-016 — Verify Isolated JMX Exporter TLS Scrape Integration](TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md)
- [TN-015 — Implement JMX Exporter Baseline Configuration and Validation](TN-015-implement-jmx-exporter-baseline-configuration-and-validation.md)
- [Tomcat Monitoring](../../index.md)
- [JMX Exporter issue #982 — `_info` suffix is working as designed](https://github.com/prometheus/jmx_exporter/issues/982)
- [Prometheus client metric-name sanitization](https://github.com/prometheus/client_java/blob/main/prometheus-metrics-model/src/main/java/io/prometheus/metrics/model/snapshots/PrometheusNaming.java)

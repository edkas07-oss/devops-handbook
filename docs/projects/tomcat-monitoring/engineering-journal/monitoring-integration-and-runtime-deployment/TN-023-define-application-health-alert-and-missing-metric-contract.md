# TN-023 — Define Application-Health Alert and Missing-Metric Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-25 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Menetapkan contract alert Prometheus yang membedakan application health check
gagal, health metrics hilang, dan scrape target Telegraf tidak tersedia,
termasuk perilaku firing dan resolved sebagai handoff implementasi berikutnya.

## 🌍 Background

TN-022 membuktikan persistent Telegraf menghasilkan application-health metrics
dan berhasil di-scrape Prometheus melalui job `telegraf-health`. Project juga
mensyaratkan kegagalan aplikasi dapat dibedakan dari hilangnya health metrics;
ketiadaan alert health tidak boleh dianggap sehat ketika signal monitoring
sendiri tidak tersedia.

Current-state Architecture masih menyatakan integrasi Prometheus dan Telegraf
belum dilaksanakan. Pernyataan tersebut tertinggal dari hasil TN-022 dan harus
direkonsiliasi sebelum menjadi dasar implementasi alert.

Project owner menyetujui TN-023 dan perubahan dokumentasi contract pada
2026-08-25. Authorization tidak mencakup perubahan source repository, rule
implementation, build, runtime inspection atau mutation, container test,
cleanup, commit, maupun push.

## 📚 Scope

Aktivitas ini mencakup:

- Mengidentifikasi canonical source signal dan label stabil dari source serta
  evidence yang telah tersedia.
- Menetapkan pemisahan kondisi, ekspresi PromQL baseline, durasi `for`,
  severity, annotation, serta firing dan resolved semantics.
- Mendefinisikan verification criteria untuk implementation Technical Note
  berikutnya.
- Merekonsiliasi bagian Current Status pada Architecture dengan hasil TN-022.
- Memperbarui phase index dan navigation untuk TN-023.

Implementasi rule, perubahan repository `tomcat-monitoring`, semantic
`promtool` validation, reload atau replacement Prometheus, Alertmanager,
notification routing, TrueSight, production health semantics, runtime
verification, cleanup container, commit, dan push tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| Telegraf source contract | Interval `30s`, timeout `5s`, expected HTTP `200`, expected body status `UP`, serta stable tags `service="tomcat"` dan `check="application-health"`. |
| Prometheus source contract | Canonical job `telegraf-health` melakukan scrape internal `telegraf:9273/metrics` setiap `30s`. |
| TN-008 | Healthy menghasilkan status-code match `1`, string match `1`, dan result code `0`; body mismatch menghasilkan result code `1`; status mismatch menghasilkan result code `6`. |
| TN-022 | Persistent target menghasilkan `up{job="telegraf-health"}=1` dan healthy metrics setelah controlled restart. |
| Operations | Health failure, missing health metrics, dan JMX availability merupakan kondisi yang harus dapat dibedakan. |
| TM-ADR-0001 | Prometheus mengevaluasi alert; Alertmanager menangani grouping, deduplication, dan routing firing/resolved alert. |

## 🔍 Findings

### Signal boundaries

| Condition | Canonical Signal | Interpretation |
| --- | --- | --- |
| Telegraf scrape unavailable | `up{job="telegraf-health"} == 0` | Prometheus tidak dapat mengambil metrics dari Telegraf; application health tidak diketahui. |
| Health metric missing | Telegraf `up == 1`, tetapi tidak ada `http_response_result_code` untuk stable application-health identity | Scrape endpoint tersedia, tetapi expected health series tidak dihasilkan atau tidak diteruskan. |
| Application health failed | Stable application-health series tersedia dan aggregated result code tidak sama dengan `0` | Telegraf mencapai hasil non-success seperti body mismatch, status mismatch, timeout, atau connection failure. |
| Application health healthy | Telegraf `up == 1`, expected result series tersedia, dan aggregated result code sama dengan `0` | Local container-network health contract terpenuhi; kondisi ini tidak membuktikan jalur akses eksternal atau dependency production. |

`http_response_response_status_code_match` dan
`http_response_response_string_match` dipertahankan sebagai diagnostic signals.
Alert utama menggunakan `http_response_result_code` karena signal tersebut
mewakili composite result yang sudah membedakan healthy dan non-success pada
component verification.

### Label identity

Alert identity hanya menggunakan stable labels berikut:

- `job` dan `instance` dari Prometheus target;
- `service="tomcat"`; dan
- `check="application-health"`.

Label Telegraf seperti `result`, `status_code`, `url`, atau `server` dapat
berubah bersama hasil pemeriksaan dan tidak digunakan untuk grouping alert.
Nilai tersebut tetap dapat digunakan sebagai diagnostic evidence pada metric
atau dashboard, tetapi tidak boleh membuat alert baru hanya karena detail
failure berubah.

### Timing boundary

Ketiga alert menggunakan baseline `for: 2m`. Nilai ini menahan transient
failure yang lebih pendek dari beberapa siklus scrape `30s`, tetapi tetap
memberikan notification awal dalam skala menit. Nilai tersebut merupakan lab
baseline, bukan production service-level objective.

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Satu alert berdasarkan `up` saja | Tidak dapat membedakan application failure dari collector atau scrape failure. | Rejected |
| `absent()` global untuk missing metric | Sederhana, tetapi menghasilkan satu vector tanpa mempertahankan identity target dan kurang sesuai jika target bertambah. | Rejected |
| Set difference antara healthy scrape dan expected health series | Mempertahankan target identity dan hanya firing ketika scrape Telegraf masih sehat. | Selected |
| Gunakan label `result` sebagai alert identity | Label berubah saat failure berubah dan dapat menghasilkan alert churn. | Rejected |
| Gunakan aggregated `result_code` dengan stable labels | Menjaga identity dan menggunakan composite success contract yang telah diverifikasi. | Selected |

## ⚠️ Risks

| Risk | State | Mitigation |
| --- | --- | --- |
| Missing-metric alert menduplikasi scrape-down alert | Mitigated | Missing rule hanya memilih target dengan `up == 1`. |
| Diagnostic label berubah dan menghasilkan alert churn | Mitigated | Aggregate menggunakan stable `job`, `instance`, `service`, dan `check`. |
| Baseline `2m` tidak sesuai kebutuhan production | Accepted for lab | Production owner harus menetapkan SLO dan escalation timing sebelum production rollout. |
| Source metric berubah pada versi Telegraf berikutnya | Open | Implementation dan upgrade verification harus menjalankan semantic rule test terhadap artifact identity yang digunakan. |

## ⚖️ Recommendation

Implementasi berikutnya menggunakan tiga alert rules terpisah.

### TelegrafHealthScrapeUnavailable

```promql
up{job="telegraf-health"} == 0
```

- `for`: `2m`
- Severity: `warning`
- Firing: Prometheus gagal melakukan scrape Telegraf selama baseline duration.
- Resolved: `up` kembali `1`.
- Boundary: Menyatakan monitoring path unavailable, bukan application failure.

### TomcatApplicationHealthMetricsMissing

```promql
up{job="telegraf-health"} == 1
unless on (job, instance)
count by (job, instance) (
  http_response_result_code{
    job="telegraf-health",
    service="tomcat",
    check="application-health"
  }
)
```

- `for`: `2m`
- Severity: `warning`
- Firing: Telegraf scrape sehat, tetapi expected application-health result
  series tidak tersedia selama baseline duration.
- Resolved: Expected result series kembali atau Telegraf scrape menjadi
  unavailable dan tanggung jawab berpindah ke scrape-unavailable alert.
- Boundary: Tidak menduplikasi scrape-down condition.

### TomcatApplicationHealthFailed

```promql
max by (job, instance, service, check) (
  http_response_result_code{
    job="telegraf-health",
    service="tomcat",
    check="application-health"
  }
) != 0
and on (job, instance)
up{job="telegraf-health"} == 1
```

- `for`: `2m`
- Severity: `critical`
- Firing: Composite application-health result tetap non-zero selama baseline
  duration sementara Telegraf scrape sehat.
- Resolved: Aggregated result kembali `0`, result series hilang dan missing
  rule mengambil tanggung jawab, atau scrape unavailable dan scrape rule
  mengambil tanggung jawab.
- Boundary: Membuktikan local application-health contract gagal; tidak
  membuktikan jalur akses pengguna eksternal gagal.

Setiap rule harus memiliki `summary` yang stabil dan `description` yang
menjelaskan signal boundary, target `{{ $labels.instance }}`, serta nilai
aktual jika tersedia. Annotation tidak boleh memuat credential, URL sensitif,
atau environment secret.

## 📋 Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Berapa duration dan severity yang sesuai untuk production application? | Deferred | Project owner bersama production application owner | Production SLO, scrape interval, notification expectation, dan escalation timing diterima. | Production alert rollout; tidak memblokir lab baseline implementation. |
| Label routing apa yang dibutuhkan Alertmanager dan TrueSight? | Deferred | Project owner bersama Alertmanager atau TrueSight integration owner | Routing tree, receiver contract, event mapping, dan secret injection boundary diterima. | Alertmanager dan external integration; tidak memblokir Prometheus rule implementation. |
| Bagaimana compatibility rule diverifikasi saat Telegraf atau plugin di-upgrade? | Open | Runtime and integration maintainers | Upgrade workflow memiliki semantic metric fixture atau component evidence untuk canonical series dan stable labels. | Upgrade acceptance; tidak memblokir current-version implementation. |

## 🤝 Decision Handoff

Contract tiga-signal, stable-label aggregation, lab baseline `for: 2m`, dan
severity di atas diterima sebagai dasar planning implementasi berikutnya.
Retrospective ADR review pada 2026-08-29 menilai pemisahan tiga failure signal
sebagai keputusan jangka panjang dengan alternatif bermakna. Keputusan tersebut
kemudian dicatat pada
[TM-ADR-0004](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md).

Implementation tetap memerlukan Technical Note baru dan Implementation Gate
yang menetapkan exact rule file, Prometheus `rule_files` loading, validator,
semantic `promtool` test, runtime application method, failure injection,
rollback, serta cleanup. Approval TN-023 tidak memberikan authorization
tersebut.

## ⚙️ Commands Executed

Seluruh command pada aktivitas ini bersifat read-only atau documentation
verification. Tidak ada perubahan source project atau runtime command yang
dijalankan.

```bash
# Repository status and current journal discovery
git status --short --branch
rg --files docs/projects/tomcat-monitoring docs/adr/tomcat-monitoring
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,280p' docs/projects/tomcat-monitoring/index.md
sed -n '1,260p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,820p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md

# Governance and current-state source inputs
sed -n '1,1000p' docs/standards/documentation-standards.md
sed -n '1,1000p' docs/standards/engineering-journal-standards.md
sed -n '1,1000p' docs/standards/writing-standards.md
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,220p' docs/projects/tomcat-monitoring/operations/index.md
rg -n -C 4 'missing|alert|Alertmanager|health metric|health-check' docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md

# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
git diff --check
sed -n '1,240p' config/telegraf/health-check.conf
sed -n '1,200p' config/prometheus/prometheus.yml
sed -n '1,200p' config/prometheus/README.md
rg -n -C 3 'alert|missing|health' README.md config scripts

# Historical signal evidence and navigation
rg -n -C 5 'result_code|status_code_match|string_match|missing|absent|up\{|telegraf-health' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
sed -n '1,120p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages

# Documentation verification
git diff --check
git status --short --branch
git diff --stat
git diff -- docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
rg -n 'TN-023|TN-023-define-application' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
command -v mkdocs
sed -n '1,330p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
```

Trailing-whitespace dan secret-pattern scans tidak menghasilkan temuan sehingga
`rg` mengembalikan exit code `1`; hasil tersebut merupakan expected empty
result, bukan verification failure. `command -v mkdocs` juga tidak menghasilkan
path karena executable tidak tersedia.

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Review metadata, heading, dan phase placement | TN-023 mengikuti base structure dan nomor berikutnya pada phase aktif. | Passed. | Heading inventory dan phase index menunjukkan TN-023 setelah TN-022. |
| Review source mapping dan contract consistency | Canonical job, metric, tags, dan healthy/failure semantics cocok dengan source serta TN evidence. | Passed untuk static contract. | `telegraf-health`, `http_response_result_code`, `service="tomcat"`, dan `check="application-health"` ditemukan pada source serta TN-008/TN-022. |
| Review navigation dan relative targets | TN tersedia pada `.pages`, phase index, dan seluruh related target ada. | Passed. | Navigation search dan lima exact `test -f` checks lulus. |
| Review diff, whitespace, dan sensitive patterns | Tidak ada whitespace error atau secret material pada approved documentation scope. | Passed. | `git diff --check` lulus; whitespace dan secret scans tidak menemukan match. |
| Review current-state reconciliation | Architecture tidak lagi menyatakan Prometheus dan Telegraf belum dilaksanakan serta tetap membatasi unverified capability. | Passed. | Current Status sekarang mencatat persistent lab integration dan menyatakan alert rule serta end-to-end flow belum diverifikasi. |
| MkDocs render | Site dapat dirender tanpa error. | Not verified. | `mkdocs` executable tidak tersedia dan dependency tidak dipasang. |
| PromQL semantic dan runtime behavior | Rule expressions lulus `promtool`, firing, resolved, missing-series, dan scrape-down test. | Not verified; di luar scope TN-023. | Menjadi mandatory criteria pada implementation Technical Note berikutnya. |

## 🧾 Outcome

Contract tiga signal selesai ditetapkan: Telegraf scrape unavailable, health
metric missing ketika scrape sehat, dan application health failed ketika
composite result non-zero. Stable label identity, lab timing baseline,
severity, firing/resolved boundary, risk, open question, serta implementation
handoff telah tersedia.

Architecture current state telah direkonsiliasi dengan hasil TN-022 tanpa
menyatakan alert rule atau end-to-end flow sudah terverifikasi. Dokumentasi
source-level lulus review; MkDocs render, PromQL semantic validation, dan
runtime behavior tetap belum diverifikasi. Repository `tomcat-monitoring` dan
runtime tidak berubah.

## ⏭️ Next Steps

Setelah contract selesai diverifikasi, buka Technical Note implementation
terpisah dengan exact source plan, semantic validation, runtime verification,
rollback, cleanup, dan authorization baru.

## 🔗 Related Documentation

- [TN-022 — Deploy Persistent Tomcat Lab Health Application and Telegraf Integration](TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md)
- [TN-008 — Verify Telegraf Health Check with Edkas-pc1 Alias](TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md)
- [Architecture](../../architecture/index.md)
- [Operations](../../operations/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [TM-ADR-0004 — Separate Application Failure from Monitoring Signal Loss](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md)

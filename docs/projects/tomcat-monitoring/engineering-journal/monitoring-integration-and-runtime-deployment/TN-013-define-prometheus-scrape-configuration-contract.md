# TN-013 — Define Prometheus Scrape Configuration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
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

Menetapkan contract non-secret minimum untuk configuration scrape Prometheus
dan validator source-level sebelum implementation dilakukan pada repository
`tomcat-monitoring`.

## 🌍 Background

TN-012 menyelesaikan rekonsiliasi runtime Prometheus dan menunjuk
`prometheus.yml` beserta static validation sebagai integration slice
berikutnya. Runtime generik Prometheus sudah tersedia dan telah lulus smoke
test, tetapi `config/prometheus/README.md` masih melarang configuration
executable sebelum target, interval, TLS reference, dan validation interface
yang diperlukan disetujui.

Project owner menyetujui TN-013 sebagai decision dan documentation scope pada
2026-08-24. Approval tersebut tidak mencakup perubahan source configuration,
build, runtime test, cleanup, commit, push, atau deployment.

## 📚 Scope

- Menetapkan target alias internal, protocol, port, path, interval, timeout,
  dan TLS trust reference untuk scrape JMX Exporter serta Telegraf.
- Menetapkan bentuk minimum `prometheus.yml` dan interface validator lokal.
- Membedakan prerequisite source implementation dari keputusan deployment yang
  dapat tetap deferred.
- Mendaftarkan TN-013 pada phase index dan navigation.

Configuration source, storage dan retention, alert rules, certificate
lifecycle, runtime resource, build, test, container, cleanup, commit, push,
publication, dan deployment tidak termasuk scope.

## 📥 Inputs

| Source | Fact used by this activity |
| --- | --- |
| TN-012 | Configuration `prometheus.yml` dan static validation adalah kandidat integration activity berikutnya. |
| Architecture dan Infrastructure | Prometheus mengambil JMX metrics melalui HTTPS `9404/metrics` dan Telegraf metrics melalui HTTP `9273/metrics`; Telegraf menggunakan interval `30s`. |
| Runtime Prometheus | Repository generik mem-pin Prometheus `v3.13.2`, menerima configuration melalui bind mount, dan tidak memiliki scrape target project. |
| Runtime component contracts | Alias lokal bawaan adalah `tomcat-jmx-exporter` dan `telegraf`; configuration integration tetap dimiliki `tomcat-monitoring`. |

## 🔍 Findings

| Area | State | Finding |
| --- | --- | --- |
| Runtime ownership | Verified | Runtime Prometheus generik tersedia pada repository `prometheus`; scrape configuration dimiliki `tomcat-monitoring`. |
| JMX scrape interface | Defined | Endpoint menggunakan HTTPS pada alias internal `tomcat-jmx-exporter`, port `9404`, dan path `/metrics`. |
| Telegraf scrape interface | Defined | Endpoint menggunakan HTTP pada alias internal `telegraf`, port `9273`, dan path `/metrics`. |
| Scrape timing | Defined for component integration | Interval `30s` selaras dengan interval health check Telegraf; timeout `10s` menjaga timeout lebih kecil dari interval. |
| TLS trust | Partially defined | Prometheus harus memverifikasi server certificate menggunakan CA file read-only; lifecycle dan source CA production belum ditentukan. |
| Deployment state | Deferred | Nama network aktual, target host, storage, retention, sizing, dan certificate lifecycle tidak diperlukan untuk source-level configuration. |

Alias `tomcat-jmx-exporter` dan `telegraf` merupakan service-discovery contract
di dalam network runtime, bukan nama container persistent atau deployment
target. Deployment automation nantinya harus memasang alias tersebut atau
memberikan configuration environment-specific melalui mekanisme yang
disetujui.

## 💡 Alternatives

| Alternative | State | Assessment |
| --- | --- | --- |
| Menulis target host deployment langsung di `prometheus.yml` | Rejected | Mengikat source reusable pada environment yang belum ditentukan. |
| Menunggu seluruh storage, certificate, dan deployment decision | Rejected | Keputusan tersebut tidak diperlukan untuk memvalidasi scrape configuration source-level. |
| Menggunakan alias service internal dan runtime-injected CA file | Selected | Menjaga configuration non-secret dan dapat diuji tanpa menetapkan deployment host. |
| Mengandalkan pemeriksaan teks sebagai satu-satunya validasi YAML | Rejected | Pemeriksaan contract lokal berguna untuk baseline, tetapi semantic validation tetap memerlukan `promtool`. |

## ⚖️ Decision

Decision Gate TN-013 menerima contract implementation berikut:

| Concern | Accepted contract |
| --- | --- |
| JMX target | `tomcat-jmx-exporter:9404`, scheme `https`, path `/metrics` |
| Telegraf target | `telegraf:9273`, scheme `http`, path `/metrics` |
| Global scrape interval | `30s` |
| Global scrape timeout | `10s` |
| TLS trust reference | CA file read-only pada `/run/secrets/tomcat-monitoring/jmx-exporter-ca.crt`; certificate verification tidak boleh dinonaktifkan |
| Configuration owner | `tomcat-monitoring/config/prometheus/prometheus.yml` |
| Source validator | `tomcat-monitoring/scripts/validate-prometheus.sh`, dipanggil oleh `scripts/validate.sh` |
| Semantic validator | `promtool check config` dari runtime Prometheus `v3.13.2`; dijalankan hanya dalam verification scope yang disetujui |

Contract ini merupakan keputusan implementasi lokal di dalam architecture
TM-ADR-0001. Ia tidak mengubah topology atau security boundary sehingga tidak
memerlukan ADR baru.

## ⚠️ Risks

| Risk | State | Mitigation or follow-up |
| --- | --- | --- |
| Certificate tidak memiliki SAN untuk alias JMX | Open | Certificate yang digunakan pada runtime verification harus valid untuk `tomcat-jmx-exporter`; owner certificate menutup risk saat issuance contract ditetapkan. |
| Static checker menerima YAML yang ditolak Prometheus | Mitigated | Wajibkan semantic validation dengan `promtool` pada verification activity terpisah sebelum runtime integration. |
| Alias service tidak tersedia pada deployment network | Open | Deployment owner harus memasang alias atau mengajukan configuration override melalui scope terpisah. |
| CA file tidak tersedia saat Prometheus dimulai | Open | Runtime orchestration harus memasang CA file read-only sebelum component test atau deployment. |

## ❓ Open Questions

| Question | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Apa nama network dan deployment target aktual? | Deferred | Infrastructure owner | Target inventory dan network plan disetujui. | Runtime integration dan deployment; tidak memblokir source implementation. |
| Bagaimana issuance, distribution, renewal, dan revocation CA/certificate production? | Deferred | Infrastructure atau PKI owner | Certificate lifecycle dan secret injection contract disetujui. | TLS-enabled runtime integration; tidak memblokir source implementation. |
| Berapa storage capacity dan retention Prometheus? | Deferred | Project owner dan infrastructure owner | Retention policy, sizing, mount, dan permission disetujui. | Persistent runtime deployment; tidak memblokir scrape configuration source. |
| Validator source-level minimum apa yang diterapkan tanpa parser YAML baru? | Answered | Project owner | Structural contract checker memeriksa file, field wajib, target, TLS verification, dan larangan inline secret; `promtool` tetap menjadi semantic validator. | Tidak ada setelah Decision Gate TN-013. |

## 💡 Recommendation

Buat TN-014 sebagai implementation activity terpisah untuk menambahkan
`prometheus.yml`, `validate-prometheus.sh`, wiring ke validator baseline, dan
documentation contract pada repository `tomcat-monitoring`. Source-level checks
harus berjalan tanpa dependency baru; `promtool` verification dicatat sebagai
`Not verified` sampai verification scope yang mengizinkan penggunaan runtime
Prometheus disetujui.

## 🧭 Decision Handoff

TN-013 memenuhi Decision Gate untuk source implementation TN-014, tetapi bukan
Implementation Gate. TN-014 memerlukan approval baru yang menyebutkan source
files, validator behavior, expected result, dan verification boundary.

Runtime test berikutnya memerlukan scope tersendiri yang menentukan image,
configuration path, CA material non-production, network, target aliases,
container name, cleanup target, expected result, dan actual evidence.

## ⚙️ Commands Executed

### Handoff and repository discovery

```bash
sed -n '1,240p' /home/eddywiyatno/git/prompt-template/prompt-next-technical-note.md
git status --short --branch
sed -n '1,240p' AGENTS.md
rg --files
git status --short --branch
sed -n '1,260p' AGENTS.md
rg --files docs/projects/tomcat-monitoring docs/adr/tomcat-monitoring
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,320p' docs/projects/tomcat-monitoring/index.md
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-reconcile-and-commit-prometheus-runtime-journal-evidence.md
```

### Contract and governance review

```bash
sed -n '1,260p' README.md
sed -n '1,260p' config/README.md
sed -n '1,260p' config/prometheus/README.md
sed -n '1,300p' scripts/validate.sh
rg -n 'prometheus\.yml|Prometheus|scrape|certificate|TLS|Open Question|prerequisite' README.md config validation scripts
rg -n 'prometheus\.yml|static validation|Prometheus configuration|scrape_config|scrape|certificate|TLS|Open Question|prerequisite' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-001-define-monitoring-integration-configuration-and-validation-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-010-establish-prometheus-runtime-repository.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-build-and-smoke-test-prometheus-runtime.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
sed -n '1,180p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-001-define-monitoring-integration-configuration-and-validation-contract.md
sed -n '60,220p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '80,135p' docs/projects/tomcat-monitoring/architecture/index.md
sed -n '90,125p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-010-establish-prometheus-runtime-repository.md
sed -n '116,145p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-011-build-and-smoke-test-prometheus-runtime.md
git status --short --branch
sed -n '1,280p' AGENTS.md
sed -n '1,240p' README.md
sed -n '1,180p' CONFIG
```

Perintah status dan contract terakhir dijalankan pada repository `prometheus`,
`telegraf`, dan `tomcat-jmx-exporter`. Seluruh repository source yang diperiksa
bersih; `devops-handbook` juga bersih dan local `main` satu commit di depan
local `origin/main` sebelum TN-013 dibuat.

### Documentation standards and navigation review

```bash
git status --short --branch
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,300p' docs/standards/engineering-journal-standards.md
sed -n '201,460p' docs/standards/engineering-journal-standards.md
sed -n '461,720p' docs/standards/engineering-journal-standards.md
sed -n '721,940p' docs/standards/engineering-journal-standards.md
sed -n '1,280p' docs/standards/writing-standards.md
sed -n '140,280p' docs/standards/writing-standards.md
sed -n '1,180p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
```

### Documentation verification

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
rg -n '^#|Status \||TN-013|prometheus.yml|tomcat-jmx-exporter:9404|telegraf:9273|jmx-exporter-ca.crt' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git diff --stat
git diff -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git status --short --branch
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-reconcile-and-commit-prometheus-runtime-journal-evidence.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'TN-013-define-prometheus-scrape-configuration-contract\.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git diff --check
command -v mkdocs
```

`rg` trailing-whitespace tidak menghasilkan match. Pemeriksaan `command -v
mkdocs` tidak menghasilkan path; dependency tidak dipasang karena tidak
termasuk authorization.

### Final closure verification

```bash
sed -n '188,260p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-012-reconcile-and-commit-prometheus-runtime-journal-evidence.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '^\| Status \| Completed \|$|^## (🎯 Objective|🌍 Background|📚 Scope|📥 Inputs|🔍 Findings|💡 Alternatives|⚖️ Decision|⚠️ Risks|❓ Open Questions|💡 Recommendation|🧭 Decision Handoff|⚙️ Commands Executed|✅ Review Result|🧾 Outcome|⏭️ Next Steps|🔗 Related Documentation)$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
rg -n 'TN-013-define-prometheus-scrape-configuration-contract\.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git status --short --branch
```

## ✅ Review Result

| Check | Expected result | Actual result and evidence |
| --- | --- | --- |
| Placement dan numbering | TN-013 berada pada phase aktif setelah TN-012. | Passed; file TN-013 tersedia dan phase index serta `.pages` mendaftarkannya setelah TN-012. |
| Required structure | Metadata dan base section Discovery and Assessment tersedia. | Passed; objective, background, scope, inputs, findings, alternatives, risks, open questions, recommendation, decision handoff, outcome, dan related documentation tersedia. |
| Relative links | Seluruh target related documentation tersedia. | Passed; pemeriksaan `test -f` lulus untuk TN-012, Architecture, Infrastructure, dan TM-ADR-0001. |
| Whitespace dan tracked diff | Tidak ada trailing whitespace atau whitespace error. | Passed; trailing-whitespace scan dan `git diff --check` tidak menghasilkan error. |
| MkDocs render | Site dapat dibangun dengan tool yang tersedia. | Not verified; executable `mkdocs` tidak tersedia dan dependency tidak dipasang. |

## 🧾 Outcome

Decision Gate selesai. Target scrape, timing, TLS trust reference, ownership
configuration, dan dua lapisan validation telah ditetapkan tanpa mengubah
source atau runtime. Open question deployment memiliki owner, closure
condition, dan blocked activity; tidak ada open item yang menghalangi source
implementation TN-014.

TN-013, phase index, dan navigation telah direview. Residual gap hanya MkDocs
render yang tidak diverifikasi karena executable tidak tersedia.

## ⏭️ Next Steps

Minta Implementation Gate terpisah untuk TN-014 dengan scope perubahan
`config/prometheus/prometheus.yml`, `config/prometheus/README.md`,
`scripts/validate-prometheus.sh`, `scripts/validate.sh`, `README.md`, dan live
Engineering Journal. Build, container, semantic `promtool` execution, cleanup,
commit, dan push tetap memerlukan authorization terpisah atau exclusion yang
eksplisit.

## 🔗 Related Documentation

- [TN-012 — Reconcile and Commit Prometheus Runtime Journal Evidence](TN-012-reconcile-and-commit-prometheus-runtime-journal-evidence.md)
- [Monitoring Integration and Runtime Deployment](index.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

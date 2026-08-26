# TN-024 — Implement and Verify Prometheus Application-Health Alert Rules

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-25–2026-08-26 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Mengimplementasikan tiga Prometheus application-health alert rules berdasarkan
contract TN-023, membuktikan semantic validity, dan memverifikasi firing serta
resolved behavior pada persistent lab tanpa merusak scrape atau data continuity.

## 🌍 Background

TN-023 menetapkan signal boundary untuk Telegraf scrape unavailable, expected
health metric missing, dan application health failed. Repository integration
belum memiliki rule file atau `rule_files` loading, sedangkan persistent lab
belum pernah memuat atau mengevaluasi contract tersebut.

Project owner menyetujui TN-024 pada 2026-08-25. Authorization saat ini hanya
mencakup source dan documentation changes serta static dan semantic
verification. Persistent runtime mutation, failure injection, commit, push,
dan cleanup tidak diotorisasi.

Read-only preflight kemudian disetujui pada 2026-08-25. Setelah exact target,
rollback, failure injection, dan cleanup boundary tersedia, project owner
menyetujui Runtime Verification Gate pada tanggal yang sama. Session terputus
karena usage limit ketika missing-metric fixture aktif dan dilanjutkan pada
2026-08-26 berdasarkan exact resumed-state audit.

## 📚 Scope

Authorized scope saat ini mencakup:

- Menambahkan non-secret Prometheus rule file untuk tiga alert TN-023.
- Menambahkan `rule_files` loading contract pada Prometheus configuration.
- Memperluas static validator dan repository required-file contract.
- Memperbarui initialization interface agar rule source dapat ditempatkan pada
  existing `prometheus_config` volume ketika runtime application disetujui.
- Memperbarui source dan current-state documentation sesuai hasil aktual.
- Menjalankan shell, static, dan semantic `promtool` verification menggunakan
  resource sementara yang self-cleaning bila binary host tidak tersedia.

Persistent Prometheus replacement atau reload, persistent volume mutation,
failure injection, Alertmanager, notification routing, TrueSight, production
semantics, cleanup persistent resource, commit, dan push tidak termasuk
authorization saat ini.

Runtime Verification Gate berikutnya memperluas authorized scope hanya untuk
versioned empty-metrics fixture, `prometheus_config` update, controlled
Prometheus replacement, controlled Telegraf stop/start, two exact disposable
failure fixtures, rollback-on-failure, serta cleanup disposable resources.
Successful-cutover Prometheus rollback container dan snapshot harus retained;
commit dan push tetap tidak diotorisasi.

## 📋 Prerequisites

| Prerequisite | State | Evidence |
| --- | --- | --- |
| Alert contract | Completed and accepted. | TN-023. |
| Repository worktrees | Clean before implementation. | `git status --short --branch` pada `tomcat-monitoring` dan `devops-handbook`. |
| Source ownership | Prometheus integration configuration dan validator dimiliki `tomcat-monitoring`. | Repository `AGENTS.md` dan root README. |
| Semantic verifier | Ready and verified. | Local Prometheus image menyediakan `promtool`; check dan rule tests lulus tanpa pull. |
| Runtime authorization | Approved after preflight. | Project owner menerima exact Runtime Verification Gate pada 2026-08-25. |

## ⚖️ Execution Decision

Rule ditempatkan pada `config/prometheus/rules/application-health.yml` dan
dimuat dari `/etc/prometheus/rules/*.yml`. Existing `prometheus_config` volume
tetap menjadi pemilik runtime configuration; initialization interface akan
menyalin `prometheus.yml` dan rule file ke volume yang sama tanpa menghapus
`prometheus_data`.

Implementasi menerapkan TM-ADR-0001 dan contract TN-023 tanpa mengubah topology
atau component ownership, sehingga ADR baru tidak diperlukan.

## 📋 Implementation Plan

1. Tambahkan rule source, loading path, static checks, required-file entry, dan
   initialization copy contract.
2. Perbarui README serta current-state documentation agar membedakan source
   implementation dari runtime verification.
3. Jalankan shell syntax, repository validation, sensitive-pattern scan,
   `promtool check rules`, dan `promtool check config` tanpa network pull.
4. Pertahankan status `In Progress` dan berhenti pada Runtime Verification Gate
   sampai exact persistent target, application method, failure injection,
   rollback, dan cleanup mendapat authorization.

## ⚙️ Implementation

Source implementation menghasilkan:

- `config/prometheus/rules/application-health.yml` dengan tiga alert, stable
  identity, severity, annotation, dan lab baseline `for: 2m` dari TN-023;
- `rule_files` loading melalui `/etc/prometheus/rules/*.yml`;
- synthetic fixture yang menguji healthy, failed, missing-metric,
  scrape-unavailable, dan resolved transitions;
- perluasan static validator dan required-file inventory;
- initialization copy contract yang menempatkan main configuration dan rules
  pada existing `prometheus_config` volume tanpa menghapus data volume; serta
- source dan current-state documentation yang membedakan semantic result dari
  persistent runtime state.

Tidak ada persistent container atau volume yang diubah atau dibersihkan.
Semantic verification menggunakan image lokal `localhost/prometheus:1.0.0`
dengan container `--rm` dan `--pull=never`. Setelah source verification,
persistent lab diperiksa secara read-only melalui Runtime Verification
Preflight yang disetujui terpisah.

Runtime implementation kemudian:

- menambahkan empty-metrics fixture dan Prometheus-compatible BusyBox
  responder;
- menyimpan previous configuration pada protected rollback snapshot;
- memperbarui `prometheus_config` melalui self-cleaning initializer;
- mengganti Prometheus ID `d57c910c7c6...` dengan ID `5efe0dc00a65...`
  menggunakan image, network, port, arguments, truststore, dan data volume yang
  sama;
- mempertahankan original Prometheus sebagai stopped
  `prometheus-tn024-rollback`;
- membuktikan healthy baseline, tiga mutually exclusive firing conditions,
  dan resolved recovery; serta
- memulihkan exact original Telegraf ID `e5324e075418...` dan membersihkan
  seluruh disposable failure containers.

Prometheus menemukan healthy TSDB blocks, menyelesaikan WAL replay, dan tetap
ready melalui `localhost` serta `edkas-pc1`. Existing
`tomcat-jmx-exporter-rollback` tidak diubah.

## 🛠️ Troubleshooting

Rule-unit test pertama tidak memuat rule karena fixture menggunakan
`rules/application-health.yml`, sementara `promtool` me-resolve path relatif
terhadap directory file test. Path diperbaiki menjadi
`../rules/application-health.yml`.

Test kedua membuktikan alert firing, tetapi expected resolved time `2m30s`
terlalu awal. Notasi series `1x5` mencakup nilai awal ditambah lima pengulangan,
sehingga nilai sehat pertama tersedia pada `3m`. Expected evaluation time
diselaraskan ke `3m`; final test kemudian lulus.

Read-only preflight juga memiliki dua failed commands. BusyBox `find` pada
Prometheus image tidak mendukung `-printf`; inventory diulang dengan `-print`
dan `ls`. Asumsi nama public certificate `public.crt` salah; actual non-secret
source adalah `server.crt`, lalu checksum-nya berhasil dicocokkan dengan CA
yang terpasang.

BusyBox `httpd` pertama menghasilkan HTTP `200`, tetapi tidak mengirim
`Content-Type`. Prometheus 3.13.2 menolak scrape dengan error
`non-compliant scrape target sending blank Content-Type`, sehingga target
menjadi `up=0` dan belum memenuhi missing-metric boundary. Fixture diperbaiki
dengan executable `respond.sh` dan BusyBox `nc -lk` agar mengirim
`text/plain; version=0.0.4`; corrected target stabil `up=1` tanpa health series.

Stop terhadap initial BusyBox `httpd` fixture tidak selesai melalui SIGTERM
dalam 10 detik sehingga Podman menggunakan SIGKILL sebelum exact container
removal. Resource tersebut disposable dan ID-nya diverifikasi sebelum cleanup.

Session berhenti karena usage limit ketika corrected missing-metric fixture
masih running dan original Telegraf stopped. Resumed audit pada 2026-08-26
membuktikan exact IDs tetap konsisten, Prometheus ready, target `up=1`, health
series absent, dan missing alert pending. Verification dilanjutkan dari state
tersebut; fixture tidak dibuat ulang dan tidak ada histori yang direkayasa.

## 📋 Runtime Verification Preflight

Project owner menyetujui read-only persistent-lab preflight pada 2026-08-25.
Approval tidak mencakup source change tambahan, persistent mutation, failure
injection, atau cleanup.

| Item | Observed State | Evidence |
| --- | --- | --- |
| Prometheus | ID `d57c910c7c6...`, image `localhost/prometheus:1.0.0` ID `e0bbb3929e2f...`, running, restart `0`. | Exact `podman inspect`. |
| Runtime arguments | `--config.file=/etc/prometheus/prometheus.yml` dan `--storage.tsdb.path=/prometheus`; HTTP lifecycle flag tidak tersedia. | Container command inspection. |
| Topology | Network `devops-lab`, host port `9090`, config dan truststore volumes read-only, data volume read-write. | Mount, network, and port inspection. |
| Active configuration | Hanya `/etc/prometheus/prometheus.yml`; tidak ada rules directory dan alert API mengembalikan groups kosong. | BusyBox-compatible inventory, status/config API, and rules API. |
| CA continuity | Non-secret `server.crt` sama dengan mounted `jmx-exporter-ca.crt`, SHA-256 `6f0dbd6c8535...`. | Host and container checksum comparison. |
| Baseline health | Readiness passed; JMX dan Telegraf `up=1`; health result `0`; JVM heap dan `tomcat_server` masing-masing tersedia. | Read-only Prometheus API queries. |
| Telegraf | ID `e5324e075418...`, image ID `4f8c425e8fd8...`, user `telegraf`, canonical health URL dan config mount tersedia. | Exact `podman inspect`. |
| Failure fixture runtime | Local BusyBox `1.38.0` tersedia; proposed TN-024 resource names tidak digunakan. | Image existence and collision checks. |
| Existing rollback | `tomcat-jmx-exporter-rollback` ID `a5e42f2719...` tetap exited dan di luar TN-024 cleanup scope. | Exact container inspection. |

### Proposed runtime application

Persistent application memerlukan controlled Prometheus replacement karena
active command tidak mengaktifkan HTTP lifecycle reload. Proposed sequence:

1. Ulangi exact identity, worktree, health, image, volume, network, port, dan
   collision checks.
2. Buat rollback snapshot pada
   `/home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024`
   yang menyimpan previous `prometheus.yml` tanpa secret.
3. Jalankan approved initialization interface dengan non-secret
   `server.crt`; initializer exact `prometheus-volume-init` menyalin main
   configuration dan rules ke `prometheus_config`, lalu self-cleanup. Data dan
   truststore content tidak dihapus.
4. Stop Prometheus ID `d57c910c7c6...`, rename menjadi
   `prometheus-tn024-rollback`, lalu buat replacement bernama `prometheus`
   menggunakan exact image, arguments, network, port, dan tiga named volumes.
5. Verifikasi readiness, loaded rule groups, healthy no-alert state, JMX dan
   Telegraf `up=1`, baseline metrics, TSDB continuity, dan dashboard access.

Stopped Prometheus rollback container dan rollback snapshot dipertahankan
setelah successful cutover. Penghapusannya memerlukan exact destructive
authorization terpisah.

### Proposed failure injection

Failure injection tidak mengubah Tomcat application atau persistent Telegraf
configuration:

1. Tambahkan versioned empty-metrics fixture dan static contract pada
   repository untuk menghasilkan HTTP `200` tanpa application-health series.
2. Stop exact Telegraf ID `e5324e075418...` tanpa rename atau removal.
3. Jalankan `telegraf-tn024-failed` menggunakan current Telegraf image,
   configuration, dan alias `telegraf`, tetapi arahkan health URL ke lab path
   yang menghasilkan non-success. Verifikasi hanya
   `TomcatApplicationHealthFailed` firing setelah duration contract.
4. Remove exact failed-fixture container setelah ID diperiksa, lalu jalankan
   `telegraf-tn024-missing` menggunakan local BusyBox, alias `telegraf`, dan
   versioned empty-metrics fixture. Verifikasi Telegraf scrape `up=1` dan hanya
   `TomcatApplicationHealthMetricsMissing` firing.
5. Remove exact missing-fixture container setelah ID diperiksa dan biarkan
   alias tidak tersedia. Verifikasi hanya
   `TelegrafHealthScrapeUnavailable` firing.
6. Start original Telegraf ID `e5324e075418...`; verifikasi `up=1`, result `0`,
   seluruh alert resolved, dan JMX serta Prometheus continuity.

Disposable fixture cleanup hanya mencakup exact IDs
`telegraf-tn024-failed` dan `telegraf-tn024-missing` yang dibuat TN-024.

### Proposed rollback

Jika Prometheus cutover atau verification gagal:

1. Stop dan remove replacement `prometheus` hanya setelah ID dibandingkan
   dengan ID hasil TN-024.
2. Pulihkan previous `prometheus.yml` dari exact rollback snapshot dan hilangkan
   TN-024 rules dari config volume melalui controlled initializer.
3. Rename `prometheus-tn024-rollback` kembali menjadi `prometheus`, start, dan
   verifikasi readiness, two scrape targets, baseline metrics, dan data volume.
4. Untuk failure-injection error, remove hanya exact disposable fixture ID dan
   start original Telegraf ID `e5324e075418...`, lalu verifikasi healthy state.

Rollback tidak menghapus `prometheus_data`, truststore, persistent Tomcat,
original Telegraf, atau existing `tomcat-jmx-exporter-rollback`.

## 📋 Scope Changes

| Date | Change | Reason and Impact | Approval |
| --- | --- | --- | --- |
| 2026-08-25 | Tambahkan read-only persistent-lab preflight. | Exact target, application method, rollback, failure injection, dan cleanup boundary perlu dibuktikan sebelum mutation; tidak ada runtime state change. | Approved by project owner. |
| 2026-08-25 | Tambahkan versioned empty-metrics fixture, controlled Prometheus replacement, Telegraf failure injection, rollback-on-failure, dan exact disposable cleanup. | Mandatory runtime behavior dan continuity criteria TN-024 tidak dapat ditutup hanya dengan synthetic tests. Successful-cutover rollback resources retained; commit dan push tetap excluded. | Approved by project owner. |

## 🚀 Runtime Verification Result

| Stage | Actual Result |
| --- | --- |
| Prometheus cutover | Replacement ID `5efe0dc00a65...` loaded one rule group with three healthy rules; original ID `d57c910c7c6...` retained exited. |
| Healthy baseline | JMX dan Telegraf `up=1`, health result `0`, all alerts inactive, localhost dan `edkas-pc1` ready. |
| Application failed | Disposable Telegraf produced HTTP `404` and result code `6`; only `TomcatApplicationHealthFailed` reached `firing`. |
| Metrics missing | Corrected responder remained `up=1` with no result series; only `TomcatApplicationHealthMetricsMissing` reached `firing`. |
| Scrape unavailable | No `telegraf` alias produced `up=0` and DNS no-such-host; missing alert resolved and only `TelegrafHealthScrapeUnavailable` reached `firing`. |
| Recovery | Original Telegraf ID `e5324e075418...` returned to `up=1` and result `0`; alert API became empty and all rules returned `inactive`. |
| Continuity | JMX remained `up=1`; JVM heap and `tomcat_server` remained available; TSDB used the same data volume and completed block/WAL recovery. |
| Disposable cleanup | `telegraf-tn024-failed`, `telegraf-tn024-missing`, dan `prometheus-volume-init` tidak tersedia after verification. |
| Successful-cutover cleanup | Setelah authorization 2026-08-26, stopped `prometheus-tn024-rollback` ID `d57c...` dan exact TN-024 snapshot dihapus; active runtime dan volumes tetap sehat. |

## ⚙️ Commands Executed

```bash
# Handoff discovery sebelum implementation
git status --short --branch
sed -n '1,240p' AGENTS.md
rg --files docs/projects/tomcat-monitoring docs/adr/tomcat-monitoring
sed -n '1,260p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,320p' docs/projects/tomcat-monitoring/index.md
sed -n '1,300p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
sed -n '1,280p' docs/projects/tomcat-monitoring/architecture/index.md
sed -n '1,260p' docs/projects/tomcat-monitoring/operations/index.md
rg --files
sed -n '1,240p' config/prometheus/prometheus.yml
rg -n -C 4 'prometheus|promtool|rule_files|alert' README.md config scripts
sed -n '1,260p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
sed -n '1,240p' scripts/validate-prometheus.sh
sed -n '1,220p' scripts/initialize-prometheus-volumes.sh
sed -n '1,180p' config/prometheus/README.md
rg -n -C 5 'prometheus|telegraf|tomcat-jmx-exporter|devops-lab|rollback|cleanup|Next Steps|Status \\|' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md

# Governance review setelah approval
find .. -name AGENTS.md -print
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,1200p' docs/standards/documentation-standards.md
sed -n '1,1400p' docs/standards/engineering-journal-standards.md
sed -n '1,1000p' docs/standards/writing-standards.md
sed -n '1,340p' docs/standards/engineering-journal-standards.md
sed -n '341,520p' docs/standards/engineering-journal-standards.md
sed -n '521,680p' docs/standards/engineering-journal-standards.md
sed -n '681,1040p' docs/standards/engineering-journal-standards.md

# Failed navigation read; wrong working directory, no state change
sed -n '1,120p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages

# Source validation dan semantic verifier discovery
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
git diff --stat
git status --short
command -v promtool || true
# Initial sandboxed attempt failed before image inspection
podman image exists localhost/prometheus:1.0.0
# Approved read-only retry succeeded
podman image exists localhost/prometheus:1.0.0
sed -n '1,240p' AGENTS.md
sed -n '1,240p' Containerfile
sed -n '1,220p' entrypoint.sh 2>/dev/null || true
rg -n 'promtool|ENTRYPOINT|CMD' README.md Containerfile scripts

# Semantic rule dan configuration checks; temporary self-cleaning containers
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro localhost/prometheus:1.0.0 /bin/promtool check rules /etc/prometheus/rules/application-health.yml
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro localhost/prometheus:1.0.0 /bin/promtool check config /etc/prometheus/prometheus.yml

# Initial rule-unit test; failed because relative rule path resolved under tests
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/promtool test rules tests/application-health.test.yml

# Second rule-unit test; rule loaded, resolved expectation at 2m30s was early
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/promtool test rules tests/application-health.test.yml

# Corrected rule-unit test and combined final semantic verification
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/promtool test rules tests/application-health.test.yml
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c '/bin/promtool check rules rules/application-health.yml && /bin/promtool check config prometheus.yml && /bin/promtool test rules tests/application-health.test.yml'

# Final source and documentation review
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|bearer_token:|^[[:space:]]*password:' config/prometheus README.md validation/README.md scripts/initialize-prometheus-volumes.sh scripts/validate-prometheus.sh scripts/validate.sh
git status --short --branch
git diff --stat
rg -n 'TN-024|TN-024-implement-and-verify' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
rg -n '[[:blank:]]+$|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
command -v mkdocs
git diff -- README.md config/prometheus/prometheus.yml config/prometheus/README.md config/prometheus/rules/application-health.yml config/prometheus/tests/application-health.test.yml scripts/initialize-prometheus-volumes.sh scripts/validate-prometheus.sh scripts/validate.sh validation/README.md
git diff -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md

# Approved read-only persistent-lab preflight
podman inspect prometheus --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} image_id={{.Image}} status={{.State.Status}} started={{.State.StartedAt}} restart={{.RestartCount}} user={{.Config.User}} command={{json .Config.Cmd}} entrypoint={{json .Config.Entrypoint}} restart_policy={{json .HostConfig.RestartPolicy}} ports={{json .HostConfig.PortBindings}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}}:aliases={{json $value.Aliases}};{{end}} mounts={{range .Mounts}}{{.Type}}:{{.Name}}:{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect telegraf --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}}:aliases={{json $value.Aliases}};{{end}} mounts={{range .Mounts}}{{.Type}}:{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}}:aliases={{json $value.Aliases}};{{end}} mounts={{range .Mounts}}{{.Type}}:{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter-rollback --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} restart={{.RestartCount}}'
podman image inspect localhost/prometheus:1.0.0 --format 'id={{.Id}} digest={{.Digest}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}}'

# BusyBox find -printf failed; remaining read-only checks continued
podman exec prometheus /bin/sh -c 'find /etc/prometheus -maxdepth 3 -printf "%M %u:%g %p\n" | sort; printf "configuration\n"; sed -n "1,220p" /etc/prometheus/prometheus.yml; printf "promtool\n"; /bin/promtool check config /etc/prometheus/prometheus.yml'

# Compatible inventory and live API checks
podman exec prometheus /bin/sh -c 'find /etc/prometheus -maxdepth 3 -print | sort; printf "permissions\n"; ls -la /etc/prometheus'
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://localhost:9090/api/v1/status/config
curl --fail --silent --show-error 'http://localhost:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query

# Historical contract, certificate, and collision discovery
rg -n -C 4 'initialize-prometheus-volumes|public.crt|prometheus_config|reload|SIGHUP|web.enable-lifecycle|rollback' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
find /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls -maxdepth 1 -type f -printf '%f\n' | sort
# Failed assumption: file does not exist
sha256sum /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/public.crt
podman exec prometheus sha256sum /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt
sha256sum /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
podman exec prometheus sha256sum /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt
podman ps --all --filter name=prometheus-tn024-rollback --filter name=telegraf-tn024-rollback --filter name=prometheus-volume-init --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman inspect telegraf --format 'id={{.Id}} image={{.ImageName}} image_id={{.Image}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} command={{json .Config.Cmd}} env={{json .Config.Env}} restart_policy={{json .HostConfig.RestartPolicy}} security_opt={{json .HostConfig.SecurityOpt}} cap_add={{json .HostConfig.CapAdd}} cap_drop={{json .HostConfig.CapDrop}} read_only={{.HostConfig.ReadonlyRootfs}}'
podman image exists docker.io/library/busybox:1.38.0
podman ps --all --filter name=telegraf-tn024-failed --filter name=telegraf-tn024-missing --filter name=prometheus-tn024-rollback --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'

# Runtime Gate source fixture and final preflight
chmod 0755 fixtures/prometheus-empty-metrics/respond.sh
bash -n fixtures/prometheus-empty-metrics/respond.sh scripts/*.sh
./scripts/validate.sh
git diff --check
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c '/bin/promtool check rules rules/application-health.yml && /bin/promtool check config prometheus.yml && /bin/promtool test rules tests/application-health.test.yml'
test "$(podman inspect prometheus --format '{{.Id}}')" = d57c910c7c6b04700e5736797bbb5c5b0e048319f339687bfa2efba1e723a7b4
test "$(podman inspect telegraf --format '{{.Id}}')" = e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463
podman image exists localhost/prometheus:1.0.0
podman image exists localhost/telegraf:1.0.0
podman image exists docker.io/library/busybox:1.38.0
podman network exists devops-lab
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
! podman container exists prometheus-tn024-rollback
! podman container exists prometheus-volume-init
! podman container exists telegraf-tn024-failed
! podman container exists telegraf-tn024-missing
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query

# Rollback snapshot and prometheus_config update
test ! -e /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024
install -d -m 0700 /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024
podman cp prometheus:/etc/prometheus/prometheus.yml /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml
chmod 0600 /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml
sha256sum /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml
./scripts/initialize-prometheus-volumes.sh /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
! podman container exists prometheus-volume-init
podman exec prometheus /bin/sh -c 'find /etc/prometheus -maxdepth 3 -print | sort; /bin/promtool check config /etc/prometheus/prometheus.yml'
curl --fail --silent --show-error 'http://localhost:9090/api/v1/rules?type=alert'

# Controlled Prometheus replacement
podman stop prometheus
test "$(podman inspect prometheus --format '{{.Id}}')" = d57c910c7c6b04700e5736797bbb5c5b0e048319f339687bfa2efba1e723a7b4
test "$(podman inspect prometheus --format '{{.State.Status}}')" = exited
podman rename prometheus prometheus-tn024-rollback
podman run --detach --pull=never --name prometheus --network devops-lab --publish 9090:9090 --volume prometheus_config:/etc/prometheus:ro --volume prometheus_truststore:/run/secrets/tomcat-monitoring:ro --volume prometheus_data:/prometheus localhost/prometheus:1.0.0 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
podman inspect prometheus --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} ports={{json .HostConfig.PortBindings}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}}:aliases={{json $value.Aliases}};{{end}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}} command={{json .Config.Cmd}}'
podman inspect prometheus-tn024-rollback --format 'id={{.Id}} name={{.Name}} status={{.State.Status}}'
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://edkas-pc1:9090/-/ready
curl --fail --silent --show-error 'http://localhost:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error http://localhost:9090/api/v1/status/tsdb
podman logs --tail 120 prometheus

# Initial sandboxed localhost query failed; escalated retry proved runtime healthy
curl --fail --silent --show-error 'http://localhost:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}} restart={{.RestartCount}} error={{.State.Error}}'
sleep 30
curl --fail --silent --show-error 'http://localhost:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts

# Application-failed injection and firing verification
test "$(podman inspect telegraf --format '{{.Id}}')" = e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463
podman stop telegraf
podman run --detach --pull=never --name telegraf-tn024-failed --network devops-lab --network-alias telegraf --env TOMCAT_HEALTH_URL=http://tomcat-jmx-exporter:8080/tn024-not-found --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro localhost/telegraf:1.0.0 --config /etc/telegraf/telegraf.conf
podman inspect telegraf-tn024-failed --format 'id={{.Id}} status={{.State.Status}} image={{.ImageName}} user={{.Config.User}} ports={{json .HostConfig.PortBindings}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}}:aliases={{json $value.Aliases}};{{end}}'
sleep 35
podman logs --tail 120 telegraf-tn024-failed
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -qO- http://telegraf:9273/metrics
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts
sleep 55
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts
sleep 55
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts

# Failed fixture cleanup and initial missing fixture
test "$(podman inspect telegraf-tn024-failed --format '{{.Id}}')" = c30518114bdc2700bd4d7b781acbad534ec213b7de80ef563d47002b9048afe3
podman stop telegraf-tn024-failed
podman rm c30518114bdc2700bd4d7b781acbad534ec213b7de80ef563d47002b9048afe3
podman run --detach --pull=never --name telegraf-tn024-missing --network devops-lab --network-alias telegraf --volume /home/eddywiyatno/git/tomcat-monitoring/fixtures/prometheus-empty-metrics:/www:ro docker.io/library/busybox:1.38.0 httpd -f -p 9273 -h /www
sleep 35
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -S -O- http://telegraf:9273/metrics
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error 'http://localhost:9090/api/v1/targets?state=active'

# Content-Type diagnosis and corrected responder
podman run --rm --pull=never docker.io/library/busybox:1.38.0 nc --help
chmod 0755 fixtures/prometheus-empty-metrics/respond.sh
bash -n fixtures/prometheus-empty-metrics/respond.sh scripts/*.sh
./scripts/validate.sh
git diff --check
test "$(podman inspect telegraf-tn024-missing --format '{{.Id}}')" = e6fbf46e0d67122cdc7ba671337a9497a324902a4d9f06b0d743f075b132cdbc
podman stop telegraf-tn024-missing
podman rm e6fbf46e0d67122cdc7ba671337a9497a324902a4d9f06b0d743f075b132cdbc
podman run --detach --pull=never --name telegraf-tn024-missing --network devops-lab --network-alias telegraf --volume /home/eddywiyatno/git/tomcat-monitoring/fixtures/prometheus-empty-metrics:/www:ro docker.io/library/busybox:1.38.0 nc -lk -p 9273 -e /www/respond.sh

# Session resume audit and missing-metric firing
git status --short --branch
git diff --check
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}} restart={{.RestartCount}} started={{.State.StartedAt}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect prometheus-tn024-rollback --format 'id={{.Id}} status={{.State.Status}}'
podman inspect telegraf --format 'id={{.Id}} status={{.State.Status}} started={{.State.StartedAt}}'
podman inspect telegraf-tn024-missing --format 'id={{.Id}} status={{.State.Status}} image={{.ImageName}} command={{json .Config.Cmd}}'
curl --fail --silent --show-error 'http://localhost:9090/api/v1/targets?state=active'
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts
curl --fail --silent --show-error --get --data-urlencode 'query=min_over_time(up{job="telegraf-health"}[10m])' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=changes(up{job="telegraf-health"}[10m])' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count_over_time(http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}[10m])' http://localhost:9090/api/v1/query
sleep 45
curl --fail --silent --show-error http://localhost:9090/api/v1/alerts

# Missing fixture cleanup and scrape-unavailable firing
test "$(podman inspect telegraf-tn024-missing --format '{{.Id}}')" = f89d2acd0543b7f5ae8c8d66563c7b1ee11e3f7c283f1aaf94bea62eaf6b2673
podman stop telegraf-tn024-missing
podman rm f89d2acd0543b7f5ae8c8d66563c7b1ee11e3f7c283f1aaf94bea62eaf6b2673
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error 'http://localhost:9090/api/v1/targets?state=active'
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"} == 0' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"} == 1 unless on (job, instance) count by (job, instance) (http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"})' http://localhost:9090/api/v1/query
sleep 40
curl --max-time 10 --fail --silent --show-error http://localhost:9090/api/v1/alerts

# Original Telegraf restoration and final audit
test "$(podman inspect telegraf --format '{{.Id}}')" = e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463
podman start telegraf
sleep 35
podman logs --tail 100 telegraf
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error http://localhost:9090/api/v1/alerts
bash -n fixtures/prometheus-empty-metrics/respond.sh scripts/*.sh
./scripts/validate.sh
git diff --check
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c '/bin/promtool check rules rules/application-health.yml && /bin/promtool check config prometheus.yml && /bin/promtool test rules tests/application-health.test.yml'
! podman container exists telegraf-tn024-failed
! podman container exists telegraf-tn024-missing
! podman container exists prometheus-volume-init
stat -c '%a %n' /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024 /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml

# Documentation consolidation and closure review
git diff --check
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
rg -n 'TN-024|TN-024-implement-and-verify' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '[[:blank:]]+$|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
rg -n 'not loaded on persistent Prometheus|Rules belum diterapkan|belum dimuat atau diuji|Runtime Verification Gate pending|Status \\| In Progress' docs/projects/tomcat-monitoring docs/adr/tomcat-monitoring
command -v mkdocs
git status --short --branch
git diff --stat

# Authorized successful-cutover cleanup
test "$(podman inspect prometheus-tn024-rollback --format '{{.Id}}')" = d57c910c7c6b04700e5736797bbb5c5b0e048319f339687bfa2efba1e723a7b4
test "$(podman inspect prometheus-tn024-rollback --format '{{.State.Status}}')" = exited
test -f /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml
test "$(find /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024 -mindepth 1 -maxdepth 1 | wc -l)" -eq 1
test "$(podman inspect prometheus --format '{{.Id}}')" = 5efe0dc00a6507f0f7c33ca946717bee9cb05feaadfc2802586602e4ae8098a3
podman rm d57c910c7c6b04700e5736797bbb5c5b0e048319f339687bfa2efba1e723a7b4
rm /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024/prometheus.yml
rmdir /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024
! podman container exists prometheus-tn024-rollback
test ! -e /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/application-health-alerts-tn024
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
podman inspect tomcat-jmx-exporter-rollback --format 'id={{.Id}} status={{.State.Status}}'
curl --max-time 10 --fail --silent --show-error http://localhost:9090/-/ready
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health",service="tomcat",check="application-health"}' http://localhost:9090/api/v1/query
curl --max-time 10 --fail --silent --show-error http://localhost:9090/api/v1/alerts
```

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Source and shell validation | Required files, static contract, and shell syntax pass. | Passed. | `bash -n scripts/*.sh` dan `./scripts/validate.sh` exit `0`; validator melaporkan scrape dan alert contract valid. |
| Prometheus rule and configuration check | Tiga rules ditemukan dan main configuration memuat satu rule file tanpa semantic error. | Passed. | Final combined `promtool` run melaporkan `SUCCESS: 3 rules found`, `SUCCESS: 1 rule files found`, dan valid configuration syntax. |
| Synthetic state transitions | Healthy tidak firing; failed, missing, dan scrape-down firing terpisah setelah `2m`; failed kembali resolved ketika result `0`. | Passed setelah dua fixture corrections. | Final `promtool test rules` menghasilkan `SUCCESS`. |
| Source and documentation review | Diff bersih dari whitespace error dan sensitive material; navigation serta relative targets tersedia. | Passed. | `git diff --check`, targeted scans, navigation search, dan exact file checks lulus. |
| MkDocs render | Site dapat dirender tanpa error. | Not verified. | `mkdocs` executable tidak tersedia dan dependency tidak dipasang. |
| Runtime preflight | Exact target, topology, loaded state, baseline health, certificate identity, rollback, and collision state are known without mutation. | Passed after two corrected discovery commands. | Persistent IDs, mounts, API state, matching certificate checksums, and empty TN-024 collision filters recorded above. |
| Runtime alert behavior | Healthy, failed, missing, scrape-down, and resolved transitions match TN-023. | Passed. Each injected condition produced only its responsible alert after `for: 2m`; original Telegraf recovery returned the alert API to empty. | Prometheus alert/rule APIs, target API, direct metrics, and exact fixture identities. |
| Persistent continuity | JMX scrape, Telegraf scrape, readiness, and named data volume remain healthy. | Passed. Replacement loaded the same data volume, recovered healthy blocks and WAL, remained ready, and ended with both targets `up=1`. | Prometheus logs, TSDB status, mount inspection, localhost/`edkas-pc1` readiness, and final queries. |
| Disposable cleanup | Only exact TN-024 failure fixtures are removed after use. | Passed. Failed and missing fixture containers serta initializer tidak tersedia; original Telegraf runs. | Exact ID assertions and container existence checks. |
| Rollback readiness and cleanup | Previous Prometheus configuration and container remain recoverable until cleanup approval, then only exact retained targets are removed. | Passed and cleaned after authorization. | Pre-cleanup ID, state, path, count, and permissions matched; post-cleanup rollback targets are absent, all three named volumes remain, JMX and Telegraf report `up=1`, application-health result is `0`, and the alert API is empty. |

## 📋 Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah controlled Prometheus replacement dan config-volume update diotorisasi? | Answered | Project owner | Approved on 2026-08-25 and executed with retained rollback. | Closed; runtime loading and continuity passed. |
| Apakah controlled Telegraf handoff dan disposable failure fixtures diotorisasi? | Answered | Project owner | Approved on 2026-08-25; original restored and exact disposable resources cleaned. | Closed; firing and resolved behavior passed. |
| Kapan successful-cutover rollback resources TN-024 boleh dihapus? | Answered | Project owner | Authorized and completed on 2026-08-26 after exact target and active-state checks. | Closed; active runtime re-verification passed. |

## 🧾 Outcome

Tiga application-health alert rules selesai diimplementasikan, dimuat pada
persistent Prometheus, dan lulus static, semantic, synthetic, serta actual
runtime verification. Application failed, missing metric, dan Telegraf scrape
unavailable terbukti menjadi mutually exclusive alert responsibilities;
original Telegraf recovery mengembalikan seluruh alert ke inactive.

Prometheus replacement ID `5efe0dc00a65...`, original Telegraf ID
`e5324e075418...`, strict JMX scrape, application health result, dashboard
readiness, dan existing TSDB data berada dalam healthy final state pada
2026-08-26. Disposable resources, stopped Prometheus rollback, dan TN-024
snapshot telah dibersihkan setelah exact authorization. Named volumes,
unrelated `tomcat-jmx-exporter-rollback`, Alertmanager, dan notification flow
tidak diubah; dua capability terakhir tetap belum diverifikasi.

## ⏭️ Next Steps

Lanjutkan kandidat aktivitas terkecil berikutnya melalui TN dan Decision Gate
baru. Alertmanager contract, routing labels, receiver boundary, secret
injection, dan external notification flow tetap outstanding.

## 🔗 Related Documentation

- [TN-023 — Define Application-Health Alert and Missing-Metric Contract](TN-023-define-application-health-alert-and-missing-metric-contract.md)
- [Architecture](../../architecture/index.md)
- [Operations](../../operations/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

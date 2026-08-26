# TN-022 — Deploy Persistent Tomcat Lab Health Application and Telegraf Integration

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Deployment or Migration |
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

Menerapkan persistent Telegraf application-health integration terhadap aplikasi
Tomcat lab minimal, lalu membuktikan endpoint aktual, health metrics,
Prometheus scrape, restart persistence, dan existing JMX continuity.

## 🌍 Background

Project owner menerima contract TN-021 dan mengizinkan aplikasi kecil sebagai
target pertama. Existing persistent `tomcat-jmx-exporter` menjalankan generic
JMX target tanpa application WAR; directory `webapps` kosong. Prometheus dan
JMX scrape sehat, sedangkan query `up{job="telegraf"}` belum memiliki series.

Aplikasi dipilih sebagai exploded JSP webapp karena diproses oleh Tomcat,
memberikan endpoint exact `/health`, tidak memerlukan dependency download atau
image baru, dan dapat dipasang tanpa mengubah repository generic `tomcat` atau
`tomcat-jmx-exporter`.

## 📚 Scope

Planned scope berikut belum diotorisasi untuk eksekusi:

- Menambahkan lab-only JSP webapp dan static validator pada repository
  `tomcat-monitoring`.
- Mengganti persistent container `tomcat-jmx-exporter` menggunakan image,
  network alias, configuration, dan TLS material yang sama, ditambah satu
  read-only application mount.
- Menjalankan persistent container `telegraf` dengan configuration project dan
  non-secret `TOMCAT_HEALTH_URL`.
- Memverifikasi direct endpoint, Telegraf metrics, Prometheus scrape, restart
  persistence, JMX continuity, dan absence of host-published application atau
  metrics ports.
- Mempertahankan stopped rollback container sampai successful-cutover cleanup
  mendapatkan authorization terpisah.
- Memperbarui Engineering Journal dan current-state documentation berdasarkan
  hasil aktual.

Push, registry publication, production application, external access, alerting,
dan perubahan Prometheus configuration atau named volumes tidak termasuk.
Rollback-container deletion juga tidak termasuk tanpa exact destructive-action
authorization setelah stability acceptance.

## 📋 Prerequisites

| Prerequisite | Actual State | Evidence |
| --- | --- | --- |
| TN-021 contract | Accepted by project owner on 2026-08-25. | TN-021 resolution. |
| Monitoring source worktree | Clean before planned source change. | `git status --short --branch`. |
| Persistent JMX target | Running, restart count `0`, image `localhost/tomcat-jmx-exporter:1.0.0`, no host port. | Container ID `a5e42f2719d7...`. |
| Current application | `/usr/local/tomcat/webapps` has no deployed application. | Read-only container file inventory. |
| Prometheus | Running on `devops-lab`, restart count `0`, port `9090`, existing named volumes unchanged. | Container ID `d57c910c7c6...`. |
| Current JMX scrape | `up{job="tomcat-jmx-exporter"}=1`. | Prometheus API query. |
| Current Telegraf scrape | No series returned for `up{job="telegraf"}`. | Prometheus API query. |
| Telegraf image | Local image available, user `telegraf`. | ID `4f8c425e8fd8...`. |
| Diagnostic image | BusyBox `1.38.0` available locally. | ID `c6348fa86ba0...`; no pull required. |
| Resource names | No existing `telegraf` or `tomcat-jmx-exporter-rollback` container. | Filtered container inspection. |
| Tooling | `zip` and Java runtime available; no package installation required. | Local command discovery. |

## ⚖️ Execution Decision

### Application source and ownership

Repository `tomcat-monitoring` owns a lab-only fixture:

```text
fixtures/tomcat-health-app/
└── WEB-INF/
    ├── health.jsp
    └── web.xml
```

`web.xml` maps `/health` to the JSP under `WEB-INF`. JSP returns content type
`application/json` and body `{"status":"UP"}`. A new static validator checks
the mapping and response contract, lalu dipanggil oleh `scripts/validate.sh`.
Fixture tidak dipromosikan sebagai production application.

### Exact persistent resources

| Resource | Exact Contract |
| --- | --- |
| Application source | `/home/eddywiyatno/git/tomcat-monitoring/fixtures/tomcat-health-app` |
| Application mount | Read-only bind to `/usr/local/tomcat/webapps/ROOT` |
| Active application/JMX container | `tomcat-jmx-exporter` |
| Rollback container | `tomcat-jmx-exporter-rollback`, stopped and retained on successful cutover; removed on 2026-08-26 after separate cleanup authorization |
| Application/JMX image | `localhost/tomcat-jmx-exporter:1.0.0` |
| Application URL | `http://tomcat-jmx-exporter:8080/health` on `devops-lab` |
| JMX endpoint | Existing internal `https://tomcat-jmx-exporter:9404/metrics` |
| Telegraf container and alias | `telegraf` on `devops-lab` |
| Telegraf image | `localhost/telegraf:1.0.0` |
| Telegraf metrics | Internal `http://telegraf:9273/metrics` |
| Host port policy | No new host port; only existing Prometheus `9090` remains published |
| Persistent storage | No new named volume; application and Telegraf configuration use read-only repository binds |

Generic image source, TLS directory, Prometheus volumes, network, and JMX
configuration remain unchanged.

## 🚀 Change Plan

1. Create the JSP fixture, static validator, and source documentation; run the
   full repository validator.
2. Recheck exact IDs, mounts, image identities, network, target names, and
   existing Prometheus/JMX health.
3. Stop `tomcat-jmx-exporter`, rename it to
   `tomcat-jmx-exporter-rollback`, then create the replacement with identical
   runtime arguments plus the application mount.
4. Verify `/health` from a `--rm --pull=never` BusyBox client on `devops-lab`
   before creating Telegraf.
5. Start `telegraf` with no host port and inject
   `TOMCAT_HEALTH_URL=http://tomcat-jmx-exporter:8080/health`.
6. Verify container identity, logs, direct endpoint, Telegraf health metrics,
   Prometheus `up`, existing JMX metrics, dashboard readiness, and restart
   persistence.
7. Consolidate current-state documentation. Keep the stopped rollback
   container until separate successful-cutover cleanup approval.

## 💾 Rollback Plan

Rollback is atomic for the application-health objective:

1. Remove `telegraf` if it was created.
2. Stop and remove the replacement `tomcat-jmx-exporter` only after its ID is
   checked against the new-container ID recorded during execution.
3. Rename `tomcat-jmx-exporter-rollback` back to
   `tomcat-jmx-exporter` and start it.
4. Verify the restored container ID lineage, no host port, JMX target `up=1`,
   baseline metrics, and Prometheus readiness.

Source changes remain available for diagnosis and are not reset automatically.
Prometheus is not replaced, sehingga its named volumes and historical data are
outside rollback mutation.

## 🚀 Deployment

### Implement the lab application source

Exploded root webapp, Servlet 4.0 descriptor, JSP response, dan static validator
ditambahkan ke repository `tomcat-monitoring`. `scripts/validate.sh` memanggil
validator baru. Shell syntax, component contract, full repository baseline,
dan `git diff --check` lulus sebelum runtime diubah.

### Confirm the exact pre-cutover state

Pengulangan preflight setelah session interruption membuktikan:

- JMX target ID `a5e42f2719d7...` running dengan restart count `0`;
- Prometheus ID `d57c910c7c6...` running dengan existing three named volumes;
- JMX `up=1`, JVM heap count `1`, dan `tomcat_server` count `1`;
- names `telegraf` dan `tomcat-jmx-exporter-rollback` belum digunakan;
- images, network, application source, TLS material, dan configuration tersedia;
  serta
- application directories `0755` dan source files `0644`.

### Replace the JMX target with the mounted application

Original container dihentikan dan di-rename menjadi
`tomcat-jmx-exporter-rollback`. Replacement ID
`30da6d70bd638b174196f53020ef345fc8a4a9dc66859da9c98ea9b4190b8712`
menggunakan image, JMX config, TLS material, network, dan alias yang sama,
ditambah read-only mount application ke `/usr/local/tomcat/webapps/ROOT`.
Tidak ada host port baru.

Tomcat log membuktikan deployment root webapp selesai. Temporary BusyBox client
dengan `--rm --pull=never` menerima HTTP `200`, content type JSON, dan
`{"status":"UP"}` dari exact internal URL. Prometheus JMX target kembali
`up=1`, dengan JVM heap dan `tomcat_server` masing-masing count `1`.

### Deploy persistent Telegraf

Persistent Telegraf ID
`e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463`
berjalan sebagai image user `telegraf`, menggunakan alias `telegraf`, config
mount read-only, no host port, dan exact non-secret environment URL. Log
menunjukkan `http_response` loaded dan Prometheus client listen pada `:9273`.

Direct metrics menghasilkan status-code match `1`, string match `1`, dan
result code `0`. Query awal `job="telegraf"` kosong karena canonical job name
aktual adalah `telegraf-health`; Prometheus target API dan corrected queries
kemudian membuktikan scrape pool sehat dengan `up=1`.

### Verify restart persistence

`tomcat-jmx-exporter` dan `telegraf` direstart secara terkontrol. Setelah satu
scrape interval, exact container IDs tetap sama dengan new started timestamps,
direct `/health` tetap `200/UP`, direct Telegraf metrics tetap `1/1/0`, dan
kedua Prometheus targets berstatus `up` tanpa `lastError`. JMX baseline metrics,
localhost readiness, serta `edkas-pc1` readiness juga lulus.

Original ID `a5e42f2719d7...` tetap stopped sebagai
`tomcat-jmx-exporter-rollback`. Rollback tidak dijalankan karena target state
lulus; successful-cutover cleanup belum diotorisasi.

## ✅ Verification

| Criterion | Expected Result | Current Result |
| --- | --- | --- |
| Source validation | Fixture mapping, JSON response, shell syntax, and repository baseline pass. | Passed. |
| Application endpoint | Network client receives HTTP `200`, JSON content type, and `{"status":"UP"}` from exact URL. | Passed before and after restart. |
| JMX replacement | Same image/config/TLS/network alias, application mount read-only, no host port. | Passed; replacement ID `30da6d70bd63...`. |
| Telegraf runtime | Persistent `telegraf` runs as image user, no host port, config mount read-only. | Passed; ID `e5324e075418...`. |
| Telegraf semantics | Status-code match and string match equal `1`; result code equals `0`. | Passed against actual JSP application. |
| Prometheus scrape | `up{job="telegraf-health"}=1` and health metrics are present. | Passed after canonical job-label correction. |
| JMX continuity | `up{job="tomcat-jmx-exporter"}=1`, JVM heap and `tomcat_server` remain available. | Passed before cutover, after replacement, and after restart. |
| Restart persistence | Application, Telegraf metrics, and JMX recover after controlled restart. | Passed after one scrape interval. |
| Port boundary | No host publication for `8080`, `9404`, or `9273`. | Passed; only existing Prometheus `9090` remains published. |
| Rollback readiness | Original JMX container remains stopped under exact rollback name until cleanup approval. | Passed; ID `a5e42f2719d7...` retained. |
| Documentation | Journal, navigation, current state, links, and whitespace pass review. | Passed; MkDocs render remains `Not verified` because executable is unavailable. |

Historical body/status mismatch behavior remains proven by TN-008 and will not
be recreated by mutating the persistent application. TN-022 must prove healthy
behavior against the actual Tomcat lab application and unavailable behavior
through Prometheus before target startup; it must not reinterpret TN-008 as
persistent evidence.

## ⚙️ Commands Executed

Only read-only planning discovery has run. Initial Podman calls inside the
filesystem sandbox failed before inspection because `/run/user/1000/libpod`
was read-only; the same read-only inspections were then rerun with approved
runtime access. No container or image mutation occurred.

```bash
# Git and source layout
git status --short --branch
rg --files
sed -n '1,220p' scripts/validate.sh

# Initial sandboxed attempts; failed before inspection
podman inspect tomcat-jmx-exporter --format '<selected runtime fields>'
podman exec tomcat-jmx-exporter sh -c 'find /usr/local/tomcat/webapps ...'
podman inspect prometheus --format '<selected runtime fields>'

# Successful read-only runtime discovery
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} restart={{.RestartCount}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Type}}:{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}} command={{json .Config.Cmd}}'
podman exec tomcat-jmx-exporter sh -c 'find /usr/local/tomcat/webapps -mindepth 1 -maxdepth 3 -printf "%P %y\n" | sort; printf "webapps.dist\n"; find /usr/local/tomcat/webapps.dist -mindepth 1 -maxdepth 2 -printf "%P %y\n" | sort | head -80'
podman inspect prometheus --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} restart={{.RestartCount}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Type}}:{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter --format 'user={{.Config.User}} workdir={{.Config.WorkingDir}} entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}} env={{json .Config.Env}} labels={{json .Config.Labels}} restart_policy={{json .HostConfig.RestartPolicy}} security_opt={{json .HostConfig.SecurityOpt}} cap_add={{json .HostConfig.CapAdd}} cap_drop={{json .HostConfig.CapDrop}} read_only={{.HostConfig.ReadonlyRootfs}} health={{json .Config.Healthcheck}}'
podman image inspect localhost/telegraf:1.0.0 --format 'id={{.Id}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}}'
podman ps --all --filter name=telegraf --filter name=tomcat-jmx-exporter-rollback --format 'name={{.Names}} status={{.Status}} image={{.Image}}'
podman exec tomcat-jmx-exporter sh -c 'command -v wget || true; command -v busybox || true; command -v python3 || true; command -v java || true'
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
podman image inspect docker.io/library/busybox:1.38.0 --format 'id={{.Id}} names={{json .RepoTags}}'
podman network inspect devops-lab --format 'name={{.Name}} driver={{.Driver}} containers={{range $id, $value := .Containers}}{{$value.Name}};{{end}}'
podman ps --filter network=devops-lab --format 'name={{.Names}} image={{.Image}} ports={{.Ports}} status={{.Status}}'

# Source and journal references
rg -n -A20 -B10 "podman run.*tomcat-jmx-exporter|--name tomcat-jmx-exporter|tomcat-jmx-exporter-rollback" docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
command -v jar
command -v zip
java -version
git log -1 --oneline
git status --short --branch
```

The in-container `curl` check failed because the active image has no `curl`;
direct endpoint evidence must use the approved BusyBox network client. Initial
host `curl` queries inside the sandbox could not reach port `9090` and were
rerun successfully with runtime access. Network inspect formatting also failed
because the selected `.Containers` field was unavailable; filtered `podman ps`
then confirmed current network members without mutation.

### Planning-document verification

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
rg -n 'TN-022|TN-022-deploy-persistent' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
git status --short --branch
```

Diff, relative targets, headings, navigation, trailing whitespace, dan
secret-pattern checks lulus. MkDocs render tetap `Not verified` karena
executable tidak tersedia dan dependency tidak dipasang.

### Source implementation and validation

```bash
chmod 0755 scripts/validate-tomcat-health-app.sh
bash -n scripts/*.sh
./scripts/validate-tomcat-health-app.sh
./scripts/validate.sh
git diff --check
git status --short --branch
```

### Repeated exact pre-cutover check

Rangkaian pertama terputus bersama session sebelum output diterima. Karena
seluruh command bersifat read-only, rangkaian yang sama diulang dari awal dan
lulus.

```bash
set -euo pipefail
readonly TN022_OLD_JMX_ID=a5e42f2719d76b37ac38678ee7a4ec50724da7497c4a88f2e1200ef6da470196
readonly TN022_PROMETHEUS_ID=d57c910c7c6b04700e5736797bbb5c5b0e048319f339687bfa2efba1e723a7b4
readonly TN022_APP_DIR=/home/eddywiyatno/git/tomcat-monitoring/fixtures/tomcat-health-app
readonly TN022_TLS_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls
test "$(podman inspect tomcat-jmx-exporter --format '{{.Id}}')" = "${TN022_OLD_JMX_ID}"
test "$(podman inspect tomcat-jmx-exporter --format '{{.State.Status}}')" = running
test "$(podman inspect prometheus --format '{{.Id}}')" = "${TN022_PROMETHEUS_ID}"
test "$(podman inspect prometheus --format '{{.State.Status}}')" = running
! podman container exists tomcat-jmx-exporter-rollback
! podman container exists telegraf
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman image exists localhost/telegraf:1.0.0
podman image exists docker.io/library/busybox:1.38.0
podman network exists devops-lab
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
test -f /home/eddywiyatno/git/tomcat-monitoring/config/jmx-exporter/jmx-exporter.yml
test -f /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf
test -f "${TN022_APP_DIR}/WEB-INF/web.xml"
test -f "${TN022_APP_DIR}/WEB-INF/health.jsp"
test -f "${TN022_TLS_DIR}/keystore.p12"
test -f "${TN022_TLS_DIR}/keystore-password"
test -z "$(podman port tomcat-jmx-exporter)"
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
stat -c '%a %n' "${TN022_APP_DIR}" "${TN022_APP_DIR}/WEB-INF" "${TN022_APP_DIR}/WEB-INF/web.xml" "${TN022_APP_DIR}/WEB-INF/health.jsp"
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}}'
```

### Controlled JMX replacement and application check

```bash
set -euo pipefail
readonly TN022_OLD_JMX_ID=a5e42f2719d76b37ac38678ee7a4ec50724da7497c4a88f2e1200ef6da470196
readonly TN022_MONITORING_REPO=/home/eddywiyatno/git/tomcat-monitoring
readonly TN022_TLS_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls
podman stop tomcat-jmx-exporter
test "$(podman inspect tomcat-jmx-exporter --format '{{.State.Status}}')" = exited
podman rename tomcat-jmx-exporter tomcat-jmx-exporter-rollback
test "$(podman inspect tomcat-jmx-exporter-rollback --format '{{.Id}}')" = "${TN022_OLD_JMX_ID}"
test "$(podman inspect tomcat-jmx-exporter-rollback --format '{{.State.Status}}')" = exited
podman run --detach --name tomcat-jmx-exporter --network devops-lab --network-alias tomcat-jmx-exporter --volume "${TN022_MONITORING_REPO}/config/jmx-exporter/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro" --volume "${TN022_TLS_DIR}/keystore.p12:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro" --volume "${TN022_TLS_DIR}/keystore-password:/run/secrets/tomcat-jmx-exporter/keystore-password:ro" --volume "${TN022_MONITORING_REPO}/fixtures/tomcat-health-app:/usr/local/tomcat/webapps/ROOT:ro" localhost/tomcat-jmx-exporter:1.0.0
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} status={{.State.Status}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter-rollback --format 'id={{.Id}} name={{.Name}} status={{.State.Status}} ports={{json .HostConfig.PortBindings}}'
podman logs --tail 120 tomcat-jmx-exporter
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -S -O- http://tomcat-jmx-exporter:8080/health
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
```

Replacement command dijalankan dengan failure branch yang akan mengembalikan
original name dan start state bila `podman run` gagal. Branch tersebut tidak
terpicu karena replacement berhasil.

### Persistent Telegraf deployment and scrape diagnostics

```bash
podman run --detach --name telegraf --network devops-lab --network-alias telegraf --env TOMCAT_HEALTH_URL=http://tomcat-jmx-exporter:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro localhost/telegraf:1.0.0 --config /etc/telegraf/telegraf.conf
podman inspect telegraf --format 'id={{.Id}} name={{.Name}} image={{.ImageName}} user={{.Config.User}} status={{.State.Status}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Source}}:{{.Destination}}:rw={{.RW}};{{end}} health_url={{range .Config.Env}}{{if eq . "TOMCAT_HEALTH_URL=http://tomcat-jmx-exporter:8080/health"}}{{.}}{{end}}{{end}}'
podman logs --tail 100 telegraf
sleep 35
podman logs --tail 120 telegraf
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -qO- http://telegraf:9273/metrics
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_status_code_match{job="telegraf"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_string_match{job="telegraf"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf"}' http://localhost:9090/api/v1/query
sed -n '1,120p' config/prometheus/prometheus.yml
curl --fail --silent --show-error http://localhost:9090/api/v1/targets
curl --fail --silent --show-error --get --data-urlencode 'query=up' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_status_code_match' http://localhost:9090/api/v1/query
```

Four job-filtered queries returned empty vectors because `job="telegraf"` was
not the configured label. Source and target diagnostics identified canonical
`job="telegraf-health"`; no runtime change was needed.

### Pre-restart and post-restart verification

```bash
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}} started={{.State.StartedAt}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect telegraf --format 'id={{.Id}} status={{.State.Status}} started={{.State.StartedAt}} restart={{.RestartCount}} user={{.Config.User}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter-rollback --format 'id={{.Id}} status={{.State.Status}}'
test -z "$(podman port tomcat-jmx-exporter)"
test -z "$(podman port telegraf)"
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://edkas-pc1:9090/-/ready
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_status_code_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_string_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
podman restart tomcat-jmx-exporter telegraf
sleep 35
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -S -O- http://tomcat-jmx-exporter:8080/health
podman run --rm --pull=never --network devops-lab docker.io/library/busybox:1.38.0 wget -qO- http://telegraf:9273/metrics | grep -E '^http_response_(response_status_code_match|response_string_match|result_code)'
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://edkas-pc1:9090/-/ready
curl --fail --silent --show-error http://localhost:9090/api/v1/targets
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_status_code_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_string_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}} started={{.State.StartedAt}} restart={{.RestartCount}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect telegraf --format 'id={{.Id}} status={{.State.Status}} started={{.State.StartedAt}} restart={{.RestartCount}} user={{.Config.User}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}} restart={{.RestartCount}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman logs --tail 80 tomcat-jmx-exporter
podman logs --tail 80 telegraf
```

### Final source and documentation validation

```bash
# /home/eddywiyatno/git/tomcat-monitoring
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' README.md scripts/validate.sh scripts/validate-tomcat-health-app.sh fixtures/tomcat-health-app/WEB-INF/web.xml fixtures/tomcat-health-app/WEB-INF/health.jsp
git status --short --branch

# /home/eddywiyatno/git/devops-handbook
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
rg -n 'Telegraf scrape, Alertmanager|Prometheus belum melakukan scrape|Telegraf.*runtime planned|integration pending|application runtime planned|implementation planned|not runtime-verified|Execution menunggu exact Implementation Gate' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
command -v mkdocs
git status --short --branch
```

Source validation, Bash syntax, diff, whitespace, required targets, dan
secret-pattern checks lulus. Contradiction scan hanya menemukan valid pending
scope untuk alerting/external integration. Generic runtime repositories tetap
clean. MkDocs path tidak ditemukan, sehingga render tidak dijalankan.

### Final closure audit

```bash
# Source closure
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
git status --short --branch
rg -n '[[:blank:]]+$' README.md scripts/validate.sh scripts/validate-tomcat-health-app.sh fixtures/tomcat-health-app/WEB-INF/web.xml fixtures/tomcat-health-app/WEB-INF/health.jsp

# Handbook closure
git diff --check
git status --short --branch
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md

# Final live-state audit
test "$(podman inspect tomcat-jmx-exporter --format '{{.Id}}')" = 30da6d70bd638b174196f53020ef345fc8a4a9dc66859da9c98ea9b4190b8712
test "$(podman inspect telegraf --format '{{.Id}}')" = e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463
test "$(podman inspect tomcat-jmx-exporter-rollback --format '{{.Id}}')" = a5e42f2719d76b37ac38678ee7a4ec50724da7497c4a88f2e1200ef6da470196
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_status_code_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_response_string_match{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=http_response_result_code{job="telegraf-health"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}} ports={{json .HostConfig.PortBindings}}'
podman inspect telegraf --format 'id={{.Id}} status={{.State.Status}} user={{.Config.User}} ports={{json .HostConfig.PortBindings}}'
podman inspect tomcat-jmx-exporter-rollback --format 'id={{.Id}} status={{.State.Status}}'

# Authorized successful-cutover cleanup on 2026-08-26
test "$(podman inspect tomcat-jmx-exporter-rollback --format '{{.Id}}')" = a5e42f2719d76b37ac38678ee7a4ec50724da7497c4a88f2e1200ef6da470196
test "$(podman inspect tomcat-jmx-exporter-rollback --format '{{.State.Status}}')" = exited
test "$(podman inspect tomcat-jmx-exporter --format '{{.Id}}')" = 30da6d70bd638b174196f53020ef345fc8a4a9dc66859da9c98ea9b4190b8712
podman rm a5e42f2719d76b37ac38678ee7a4ec50724da7497c4a88f2e1200ef6da470196
! podman container exists tomcat-jmx-exporter-rollback
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman exec prometheus wget -qO- http://127.0.0.1:9090/-/ready
podman exec prometheus wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22tomcat-jmx-exporter%22%7D'
podman exec prometheus wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22telegraf-health%22%7D'
podman exec prometheus wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=http_response_result_code%7Bjob%3D%22telegraf-health%22%2Cservice%3D%22tomcat%22%2Ccheck%3D%22application-health%22%7D'
podman exec prometheus wget -qO- http://127.0.0.1:9090/api/v1/alerts
```

Kedua trailing-whitespace scans tidak menghasilkan temuan dan karena itu
masing-masing mengembalikan exit code `1` dari `rg`; validation dan
`git diff --check` sebelumnya lulus. Live-state audit mengembalikan exit code
`0` dengan Telegraf `up=1`, match metrics `1/1`, result code `0`, JMX `up=1`,
no host port, dan rollback container tetap `exited`.

## 🔄 Source-Control Handoff

Source fixture, validator, dan README repository `tomcat-monitoring` disimpan
pada commit `6b38380` (`feat: add Tomcat lab health integration fixture`).
Commit tersebut dibuat setelah staged diff, static validation, shell syntax,
dan whitespace review lulus.

```bash
git add README.md scripts/validate.sh scripts/validate-tomcat-health-app.sh fixtures/tomcat-health-app/WEB-INF/web.xml fixtures/tomcat-health-app/WEB-INF/health.jsp
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git status --short
git diff --cached -- README.md scripts/validate.sh scripts/validate-tomcat-health-app.sh fixtures/tomcat-health-app/WEB-INF/web.xml fixtures/tomcat-health-app/WEB-INF/health.jsp
git commit -m "feat: add Tomcat lab health integration fixture"
git status --short --branch
git show --stat --oneline -1
git rev-parse HEAD
```

TN-021 resolution, TN-022 record, navigation, dan current-state pages disimpan
dalam satu local Handbook commit setelah final staged review. Handbook commit
identity dilaporkan pada session handoff karena hash tidak dapat ditulis secara
self-referential ke commit yang sama. Generic runtime repositories tidak
berubah. Push tetap manual operator.

## 🧾 Outcome

Persistent Tomcat lab health application dan Telegraf integration berhasil
diterapkan. Application endpoint, direct Telegraf metrics, Prometheus scrape,
JMX continuity, no-host-port boundary, dan restart persistence memenuhi
expected result. Prometheus container serta named volumes tidak diganti.

Rollback tidak diperlukan. Original JMX container dihentikan dengan nama
`tomcat-jmx-exporter-rollback`, dipertahankan selama cutover verification, lalu
dihapus pada 2026-08-26 setelah exact-target inspection dan successful-cutover
cleanup authorization terpisah. Image, bind files, TLS material, dan active
replacement tidak dihapus. Post-cleanup verification menghasilkan JMX dan
Telegraf `up=1`, application-health result `0`, serta alert API kosong. JSP
fixture hanya membuktikan lab integration dan tidak menyatakan production
application dependencies sehat.

## ⏭️ Next Steps

Lanjutkan alert rule dan missing-health-metric design sebagai technical
activity terpisah. Production application health semantics, CI/CD provisioning,
Alertmanager, dan external integration tetap outstanding.

## 🔗 Related Documentation

- [TN-021 — Define Persistent Telegraf Application-Health Integration Contract](TN-021-define-persistent-telegraf-application-health-integration-contract.md)
- [TN-020 — Deploy Persistent Lab JMX TLS Scrape Integration](TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md)
- [TN-008 — Verify Telegraf Health Check with Edkas-pc1 Alias](TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

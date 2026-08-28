# TN-035 — Implement and Verify Persistent Prometheus–Alertmanager–Mailpit Delivery

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Deployment or Migration |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-28 |
| Recorded Date | 2026-08-28 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-28 |

## 🎯 Objective

Menerapkan persistent Alertmanager dan Mailpit pada lab, menghubungkan
persistent Prometheus, serta membuktikan firing dan resolved delivery dari real
application-health rule sampai Mailpit tanpa kehilangan baseline scrape atau
Prometheus data continuity.

## 🌍 Background

TN-034 menerima persistent integration contract setelah TN-033 hanya
membuktikan isolated synthetic API v2 delivery. Source Prometheus sudah
mereferensikan `alertmanager:9093`, tetapi active configuration belum memuat
target tersebut dan persistent Alertmanager serta Mailpit belum tersedia.

Project owner menyetujui documentation dan implementation scope TN-035 pada
2026-08-28. Authorization mencakup source change, validation, persistent
resource creation, controlled Prometheus replacement, dan bounded Telegraf
stop/start. Commit, push, external delivery, destructive named-volume cleanup,
serta penghapusan retained rollback state tidak diotorisasi.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- menambah initializer dan validator persistent Alertmanager pada repository
  `tomcat-monitoring`;
- menjalankan shell, static, `amtool`, dan `promtool` validation;
- membuat containers `mailpit` dan `alertmanager` pada existing `devops-lab`;
- membuat volumes `alertmanager_config` dan `alertmanager_data`;
- memperbarui existing `prometheus_config` melalui protected rollback snapshot
  dan controlled replacement container `prometheus`;
- menghentikan serta menjalankan kembali exact original `telegraf` secara
  terbatas untuk memicu real `TelegrafHealthScrapeUnavailable`;
- memverifikasi firing/resolved capture, readiness, scrape, rule, storage, dan
  recovery; serta
- membersihkan hanya initializer dan temporary failure resources setelah exact
  identity diperiksa.

Persistent containers, Alertmanager volumes, existing Prometheus volumes,
stopped original Prometheus rollback container, dan protected configuration
snapshot dipertahankan. External delivery, Gmail, Integration Bridge,
TrueSight, production HA, host-boot automation, image publication, commit,
push, dan destructive retained-state cleanup tidak termasuk.

## 📋 Prerequisites

| Prerequisite | Expected State | Initial State |
| --- | --- | --- |
| Git worktrees | Perubahan lokal diketahui dan tidak ditimpa. | `tomcat-monitoring` bersih saat preflight; TN-034 dan navigation changes pada `devops-handbook` dipertahankan. |
| Runtime images | Exact local Alertmanager dan Prometheus images serta immutable Mailpit image tersedia. | Passed: local image IDs `ca27172e…` dan `e0bbb392…`; Mailpit digest `sha256:c96991d9…c9ce24`, `linux/amd64`. |
| Persistent baseline | Exact Prometheus, Telegraf, Tomcat/JMX, network, mounts, port, readiness, rules, dan storage identity diketahui. | Passed: three exact containers running on `devops-lab`; both scrape targets `up=1`; three rules `inactive/ok`. |
| Candidate resources | Nama container, volume, port, initializer, dan rollback target tidak berbenturan. | Passed: containers `alertmanager`, `mailpit`, and rollback names; Alertmanager volumes; ports `8025` and `9093` were unused. |
| Rollback | Original Prometheus identity serta protected configuration snapshot dapat dipertahankan. | Passed: original ID `5efe0dc0…`; snapshot volume `prometheus_config_tn035_rollback` retained with matching old-config checksums. |

## ⚖️ Execution Decision

TN-035 menerapkan accepted contract TN-034: single-instance persistent
Alertmanager memakai generic local image dan named volumes; Mailpit memakai
immutable direct-upstream image tanpa named volume; Prometheus diterapkan ulang
dengan existing network, port, truststore, serta data volume; dan original
Prometheus serta protected configuration snapshot dipertahankan sebagai
rollback state.

## 🛠️ Change Plan

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Verify Exact Preflight State

1. Periksa worktree, image, container, volume, network, port, active
   configuration, rules, readiness, dan baseline query.
2. Catat exact IDs, mount mode, image identity, serta rollback trigger.
3. Berhenti sebelum mutation jika identity atau baseline tidak sesuai contract.

!!! success "Expected Result"

    Seluruh target dan rollback state diketahui tanpa mengubah runtime.

</div>

<div class="procedure-step" markdown>

### Implement and Validate Source Interfaces

1. Tambahkan Alertmanager named-volume initializer dan static contract checks.
2. Perbarui operator-facing source documentation.
3. Jalankan shell/static validation, `amtool check-config`, dan `promtool`
   semantic checks sebelum runtime mutation.

!!! success "Expected Result"

    Source dan semantic configuration memenuhi accepted persistent contract.

</div>

<div class="procedure-step" markdown>

### Create Persistent Notification Components

1. Inisialisasi exact Alertmanager configuration serta data volumes.
2. Jalankan persistent Mailpit dengan internal SMTP dan loopback-only API/UI.
3. Jalankan persistent Alertmanager tanpa host port dan buktikan readiness serta
   SMTP reachability.

!!! success "Expected Result"

    Exact persistent Mailpit dan Alertmanager tersedia pada `devops-lab` tanpa
    external delivery atau host SMTP publication.

</div>

<div class="procedure-step" markdown>

### Replace Prometheus with Retained Rollback

1. Simpan protected snapshot active configuration.
2. Stop dan rename exact original Prometheus sebagai rollback container.
3. Perbarui configuration volume dan jalankan replacement `prometheus` dengan
   image, network, port, truststore, serta data volume yang sama.
4. Verifikasi readiness, healthy active Alertmanager, scrape, rules, dan data
   continuity.

!!! success "Expected Result"

    Replacement Prometheus sehat dan mengirim ke persistent Alertmanager,
    sedangkan original container serta configuration snapshot tetap tersedia.

</div>

<div class="procedure-step" markdown>

### Verify Firing and Resolved Delivery

1. Catat Mailpit baseline dan exact Telegraf identity.
2. Stop exact original Telegraf sampai real scrape-unavailable alert firing dan
   email matching diterima.
3. Start kembali exact Telegraf dan tunggu resolved alert serta email matching.
4. Verifikasi kedua scrape target `up=1`, rules kembali inactive, dan baseline
   metrics tetap tersedia.

!!! success "Expected Result"

    Mailpit menangkap matching firing dan resolved email dari real Prometheus
    rule, lalu seluruh baseline monitoring pulih.

</div>

</div>

## ↩️ Rollback Plan

Rollback dipicu jika source atau semantic validation gagal, persistent
component tidak ready, replacement Prometheus gagal mempertahankan exact
contract, active Alertmanager tidak sehat, scrape/rules/data continuity gagal,
atau Telegraf tidak pulih.

Sebelum cutover, original Prometheus harus di-stop dan di-rename tanpa dihapus.
Jika cutover gagal, stop dan hapus hanya replacement Prometheus setelah ID
cocok, pulihkan configuration dari protected snapshot, rename serta start
original Prometheus, start exact original Telegraf bila diperlukan, lalu
verifikasi baseline. Persistent Alertmanager dan Mailpit tidak dihapus tanpa
authorization cleanup baru; named volume tidak dihapus secara implisit.

## 🚀 Deployment or Migration

### Implement Source Interfaces

Repository `tomcat-monitoring` menambahkan
`scripts/initialize-alertmanager-volumes.sh`. Interface membuat exact
`alertmanager_config` dan `alertmanager_data`, menyalin non-secret
configuration melalui `podman cp`, menetapkan permission untuk runtime user
`65534:65534`, mempertahankan existing data, dan membersihkan hanya
`alertmanager-volume-init`.

Aggregate validator sekarang memerlukan interface tersebut. Alertmanager
static validator memeriksa exact names, copy mechanism, executable shell
syntax, exact initializer cleanup, dan larangan volume deletion. README source,
configuration, dan validation contract juga diperbarui.

Shell/static validation lulus. Disposable `amtool` menerima satu receiver dan
route; `promtool` menemukan tiga rules, menerima main configuration dengan satu
rule file, dan menyelesaikan seluruh rule-unit tests dengan `SUCCESS`. Seluruh
hasil ini tersedia sebelum runtime mutation.

### Create Persistent Alertmanager and Mailpit

Initializer membuat dua Alertmanager volumes lalu absent setelah completion.
Persistent Mailpit ID `e357c1f3…` menggunakan immutable accepted digest pada
`devops-lab`, tanpa volume, internal SMTP `mailpit:1025`, dan hanya
`127.0.0.1:8025` untuk API/UI. API melaporkan `v1.31.0`.

Persistent Alertmanager ID `ff2d4b2f…` menggunakan exact local image,
`alertmanager_config:/etc/alertmanager:ro`, dan
`alertmanager_data:/alertmanager:rw` tanpa host port. Readiness dan active
configuration lulus. Controlled restart mempertahankan exact container serta
mounts dan kembali ready.

### Retain Rollback and Replace Prometheus

Active old configuration memiliki checksum `e7022906…` dan tidak memuat
`alerting`. Exact snapshot ke `prometheus_config_tn035_rollback` menghasilkan
checksum yang sama; disposable snapshot containers kemudian absent.

Original Prometheus ID `5efe0dc0…` di-stop dan di-rename menjadi
`prometheus-tn035-rollback`. Existing `prometheus_config` diperbarui melalui
initializer resmi; CA checksum tetap `6f0dbd6c…`. Replacement ID `897f4ec3…`
kembali ready dengan image, `devops-lab`, host port `9090`, truststore, dan
`prometheus_data` yang sama. API kemudian melaporkan exactly one active URL
`http://alertmanager:9093/api/v2/alerts`.

Historical query pada timestamp `1787885500`, sebelum cutover, tetap
menghasilkan kedua target `up=1`. Evidence tersebut membuktikan TSDB continuity
pada existing data volume; stopped original container dan protected snapshot
tetap retained.

### Verify Real Firing and Resolved Delivery

Mailpit baseline berjumlah nol. Exact Telegraf ID `e5324e07…` di-stop pada
09:58:47 WIB dengan safety restore guard. Rule
`TelegrafHealthScrapeUnavailable` berpindah `inactive` → `pending` → `firing`
pada 10:02:07. Mailpit menerima matching firing email pada 10:02:48 setelah
accepted `group_wait: 30s`.

Exact Telegraf dijalankan kembali pada 10:02:48; scrape menjadi `up=1` pada
10:03:08 dan rule kembali `inactive` pada 10:04:08. Matching resolved email
diterima pada 10:07:39 sesuai accepted `group_interval: 5m`. Assertions
memverifikasi sender/recipient synthetic, subject, alert name, job, instance,
dan severity pada kedua message.

### Verify Final Persistent State

Final audit menunjukkan kedua targets `up`, health result `0`, tiga rules
`inactive/ok`, satu active Alertmanager, dan exactly two Mailpit messages.
Controlled Alertmanager restart mempertahankan exact container dan data volume,
menyimpan `nflog` serta `silences`, kembali menjadi active target, dan tidak
menghasilkan duplicate email.

Initializer serta snapshot containers absent. Persistent Prometheus,
Alertmanager, Mailpit, Telegraf, dan Tomcat/JMX tetap running. Original
Prometheus rollback container tetap stopped; six accepted persistent volumes,
termasuk protected snapshot, tetap tersedia.

## 🛠️ Troubleshooting

Initial Podman preflight dari sandbox gagal dengan read-only error pada
`/run/user/1000/libpod`. Query yang sama diulangi melalui approved host runtime
access dan berhasil; kegagalan pertama tidak mengubah runtime.

Post-cutover assertion awal mengharapkan TSDB head `minTime` tidak maju dan
gagal karena head compaction menggeser window dari `1787881158739` menjadi
`1787882215465`. Mount inspection membuktikan exact `prometheus_data` tetap
digunakan, lalu historical instant query sebelum cutover mengembalikan kedua
target `up=1`. Verification criterion dikoreksi menjadi historical data
availability, bukan non-increasing head metadata.

## ↩️ Rollback Result

Rollback tidak dipicu karena replacement dan mandatory recovery criteria
lulus. Original `prometheus-tn035-rollback` serta protected configuration
snapshot tetap dipertahankan sesuai plan; keberadaannya bukan authorization
untuk menghapus keduanya.

## ✅ Verification

| Criterion | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Source readiness | Shell/static and semantic validation | Seluruh checks lulus sebelum mutation. | Passed | `bash -n`, aggregate validator, `amtool`, and combined `promtool` checks exit `0`. |
| Persistent components | Exact inspect, readiness, mounts, ports, network, restart continuity | Contract TN-034 terpenuhi. | Passed | Exact IDs, `devops-lab`, accepted mounts/ports, readiness, immutable Mailpit identity, and Alertmanager restart passed. |
| Prometheus delivery | API active Alertmanager dan real alert observation | Healthy target dan alert diterima Alertmanager. | Passed | Exactly one active API v2 URL; real scrape-unavailable rule reached `firing`. |
| Notification flow | Mailpit API/message assertions | Matching firing dan resolved email tersedia. | Passed | Exactly two messages with expected firing/resolved subjects, synthetic identities, and matching alert tokens. |
| Recovery | Target, rules, metric, TSDB, dan Telegraf checks | Baseline pulih tanpa data-volume replacement. | Passed after criterion correction | Two targets `up`, three rules `inactive/ok`, health result `0`, same data volume, and historical pre-cutover query available. |
| Cleanup boundary | Exact resource audit | Temporary resources absent; retained state tetap tersedia. | Passed | Four exact temporary containers absent; persistent runtime, rollback container, and six intended volumes retained. |
| Source and documentation review | Shell/static checks, diff review, navigation, links, and stale-state scan | Seluruh changed source dan documentation konsisten. | Passed | Aggregate validation and `git diff --check` exit `0`; navigation and relative targets present; stale current-state patterns absent. |
| MkDocs render | Site dapat dirender tanpa error. | Strict build passed. | Not verified | `mkdocs` executable tidak tersedia; dependency tidak dipasang. |

## 🖥️ Commands Executed

```bash
# Governance dan source discovery
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,942p' docs/standards/engineering-journal-standards.md
sed -n '1,380p' docs/standards/writing-standards.md
git status --short --branch
sed -n '1,320p' README.md
for f in scripts/*.sh; do sed -n '1,520p' "$f"; done
sed -n '1,340p' config/alertmanager/README.md
sed -n '1,340p' config/prometheus/README.md

# Initial sandbox-local Podman preflight failed before host access
podman ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Networks}}|{{.Ports}}|{{.Status}}'
podman volume ls --format '{{.Name}}'
podman network ls --format '{{.ID}}|{{.Name}}|{{.Driver}}'

# Approved host preflight repeated the queries and added exact inspections
podman image inspect --format '{{.Id}}|{{.RepoTags}}|{{.Digest}}|{{.Architecture}}|{{.Os}}' localhost/alertmanager:1.0.0 localhost/prometheus:1.0.0 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
podman inspect --format 'name={{.Name}} id={{.Id}} image={{.ImageName}} state={{.State.Status}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' prometheus telegraf tomcat-jmx-exporter
curl --silent --show-error --fail --output /tmp/tm-tn035-status-config.json http://127.0.0.1:9090/api/v1/status/config
curl --silent --show-error --fail --output /tmp/tm-tn035-alertmanagers.json http://127.0.0.1:9090/api/v1/alertmanagers
curl --silent --show-error --fail --output /tmp/tm-tn035-rules.json 'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --silent --show-error --fail --output /tmp/tm-tn035-targets.json 'http://127.0.0.1:9090/api/v1/targets?state=active'
curl --silent --show-error --fail --output /tmp/tm-tn035-up.json 'http://127.0.0.1:9090/api/v1/query?query=up'
curl --silent --show-error --fail --output /tmp/tm-tn035-tsdb.json http://127.0.0.1:9090/api/v1/status/tsdb
podman exec prometheus sha256sum /etc/prometheus/prometheus.yml /etc/prometheus/rules/application-health.yml /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt

# Source implementation and validation
chmod 0755 scripts/initialize-alertmanager-volumes.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager:/etc/alertmanager:ro --entrypoint /bin/amtool localhost/alertmanager:1.0.0 check-config /etc/alertmanager/alertmanager.yml
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c '/bin/promtool check rules rules/application-health.yml && /bin/promtool check config prometheus.yml && /bin/promtool test rules tests/application-health.test.yml'

# Persistent Alertmanager and Mailpit
./scripts/initialize-alertmanager-volumes.sh
podman run --detach --pull=never --name mailpit --network devops-lab --network-alias mailpit --publish 127.0.0.1:8025:8025 --env MP_DATABASE=/tmp/mailpit.db --env MP_MAX_MESSAGES=50 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
/home/eddywiyatno/git/alertmanager/scripts/run.sh alertmanager_config alertmanager_data alertmanager
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info
podman exec alertmanager /bin/sh -c 'wget -qO- http://127.0.0.1:9093/-/ready'
podman exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
podman restart alertmanager

# Protected snapshot and Prometheus cutover
podman volume create prometheus_config_tn035_rollback
podman run --rm --pull=never --name prometheus-tn035-snapshot --user 0 --entrypoint /bin/sh --volume prometheus_config:/source:ro --volume prometheus_config_tn035_rollback:/backup localhost/prometheus:1.0.0 -c 'cp -a /source/. /backup/; chmod -R a-w /backup'
podman run --rm --pull=never --name prometheus-tn035-snapshot-check --entrypoint /bin/sh --volume prometheus_config_tn035_rollback:/snapshot:ro localhost/prometheus:1.0.0 -c 'sha256sum /snapshot/prometheus.yml /snapshot/rules/application-health.yml'
podman stop prometheus
podman rename prometheus prometheus-tn035-rollback
./scripts/initialize-prometheus-volumes.sh /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
/home/eddywiyatno/git/prometheus/scripts/run.sh prometheus_config prometheus_truststore prometheus_data prometheus 9090
curl --fail --silent --show-error http://127.0.0.1:9090/-/ready

# Post-cutover query; initial minTime assertion failed
curl --silent --show-error --fail --output /tmp/tm-tn035-post-tsdb.json http://127.0.0.1:9090/api/v1/status/tsdb
python3 -c 'import json; h=json.load(open("/tmp/tm-tn035-post-tsdb.json"))["data"]["headStats"]; assert h["minTime"] <= 1787881158739'

# Corrected continuity and target health checks
curl --silent --show-error --fail --output /tmp/tm-tn035-historical-up.json 'http://127.0.0.1:9090/api/v1/query?query=up&time=1787885500'
python3 -c 'import json; r=json.load(open("/tmp/tm-tn035-historical-up.json"))["data"]["result"]; assert len(r) == 2 and all(x["value"][1] == "1" for x in r)'

# Bounded real-rule verification used an exact-ID safety restore trap
readonly TELEGRAF_ID='e5324e0754189b37c2f80eddc0ea9ab0d4fad75af3f9c288641e3861a3f24463'
restore_telegraf() {
    if podman container exists telegraf; then
        current_id="$(podman inspect --format '{{.Id}}' telegraf)"
        current_state="$(podman inspect --format '{{.State.Status}}' telegraf)"
        if [[ "${current_id}" == "${TELEGRAF_ID}" && "${current_state}" != running ]]; then
            podman start telegraf >/dev/null
        fi
    fi
}
trap restore_telegraf EXIT
test "$(podman inspect --format '{{.Id}}' telegraf)" = "${TELEGRAF_ID}"
podman stop telegraf
for attempt in $(seq 1 36); do
    curl --silent --show-error --fail --output /tmp/tm-tn035-firing-rules.json 'http://127.0.0.1:9090/api/v1/rules?type=alert'
    firing_state="$(python3 -c 'import json; p=json.load(open("/tmp/tm-tn035-firing-rules.json")); print(next(r["state"] for g in p["data"]["groups"] for r in g["rules"] if r["name"] == "TelegrafHealthScrapeUnavailable"))')"
    [[ "${firing_state}" == firing ]] && break
    sleep 10
done
for attempt in $(seq 1 18); do
    curl --silent --show-error --fail --output /tmp/tm-tn035-firing-messages.json http://127.0.0.1:8025/api/v1/messages
    firing_total="$(python3 -c 'import json; print(json.load(open("/tmp/tm-tn035-firing-messages.json"))["total"])')"
    (( firing_total >= 1 )) && break
    sleep 10
done
podman start telegraf
for attempt in $(seq 1 36); do
    curl --silent --show-error --fail --output /tmp/tm-tn035-recovery-rules.json 'http://127.0.0.1:9090/api/v1/rules?type=alert'
    curl --silent --show-error --fail --output /tmp/tm-tn035-recovery-up.json 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22telegraf-health%22%7D'
    rule_state="$(python3 -c 'import json; p=json.load(open("/tmp/tm-tn035-recovery-rules.json")); print(next(r["state"] for g in p["data"]["groups"] for r in g["rules"] if r["name"] == "TelegrafHealthScrapeUnavailable"))')"
    up_value="$(python3 -c 'import json; p=json.load(open("/tmp/tm-tn035-recovery-up.json")); r=p["data"]["result"]; print(r[0]["value"][1] if r else "absent")')"
    [[ "${rule_state}" == inactive && "${up_value}" == 1 ]] && break
    sleep 10
done
for attempt in $(seq 1 66); do
    curl --silent --show-error --fail --output /tmp/tm-tn035-resolved-messages.json http://127.0.0.1:8025/api/v1/messages
    resolved_total="$(python3 -c 'import json; print(json.load(open("/tmp/tm-tn035-resolved-messages.json"))["total"])')"
    (( resolved_total >= 2 )) && break
    sleep 10
done
trap - EXIT

# Final runtime and continuity audit
podman exec alertmanager sha256sum /alertmanager/nflog /alertmanager/silences
podman restart alertmanager
sleep 40
curl --silent --show-error --fail --output /tmp/tm-tn035-post-am-restart-messages.json http://127.0.0.1:8025/api/v1/messages
curl --silent --show-error --fail --output /tmp/tm-tn035-post-am-restart-target.json http://127.0.0.1:9090/api/v1/alertmanagers
ss -ltn '( sport = :8025 or sport = :9090 or sport = :9093 )'

# Final source and documentation review
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
rg -n 'TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/index.md
if command -v mkdocs >/dev/null; then mkdocs build --strict --site-dir /tmp/tm-tn035-mkdocs-site; else echo 'mkdocs=not-installed'; fi
```

## 🧾 Outcome

Implementation dan mandatory runtime verification selesai. Persistent
Prometheus–Alertmanager–Mailpit flow membuktikan real application-health
firing/resolved email tanpa credential atau external delivery. Baseline
Telegraf, JMX, rules, health metric, active Alertmanager, dan historical data
availability pulih serta lulus final audit.

Klaim ini dibatasi pada manual single-host persistent lab. Host-reboot
recovery, production HA, backup, external notification, Integration Bridge,
TrueSight, dan project-wide end-to-end monitoring belum diverifikasi. Retained
rollback state tetap menggunakan local storage dan memerlukan stability
acceptance serta destructive authorization sebelum cleanup.

Source dan documentation diff review lulus tanpa whitespace error. Navigation
serta relative links tersedia dan current-state pages telah dikonsolidasikan.
MkDocs render berstatus `Not verified` karena executable tidak tersedia;
dependency tidak dipasang.

## ⏭️ Next Steps

Project owner menilai stability window sebelum memberi exact destructive
authorization untuk `prometheus-tn035-rollback` dan
`prometheus_config_tn035_rollback`. Restart policy serta host-boot orchestration
tetap menjadi deferred operability decision; external delivery membutuhkan
contract dan authorization terpisah.

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Kapan retained original Prometheus dan protected configuration snapshot boleh dibersihkan? | Open | Project owner | Stability diterima dan exact destructive cleanup diotorisasi terpisah. | Cleanup retained rollback state only. |
| Apakah restart policy atau host-boot orchestration diperlukan? | Deferred | Project owner | Availability expectation dan orchestration owner ditetapkan. | Future operability work only. |

## 🔗 Related Documentation

- [TN-034 — Define Persistent Alertmanager and Prometheus Delivery Integration Contract](TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Tomcat Monitoring](../../index.md)

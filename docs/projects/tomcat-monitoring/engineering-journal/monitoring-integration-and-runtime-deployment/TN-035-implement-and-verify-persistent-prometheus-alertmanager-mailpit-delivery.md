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

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Review Governance and Source Contracts

Menetapkan instruction, documentation standard, source boundary, dan local
worktree state sebelum menentukan target runtime.

1. Baca documentation, Engineering Journal, dan writing standards.
2. Periksa Git status repository yang beririsan.
3. Baca source README, component contracts, dan seluruh lifecycle scripts yang
   menentukan implementation serta rollback behavior.

```bash
# /home/eddywiyatno/git/devops-handbook
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,942p' docs/standards/engineering-journal-standards.md
sed -n '1,380p' docs/standards/writing-standards.md
git status --short --branch

# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
sed -n '1,320p' README.md
for f in scripts/*.sh; do sed -n '1,520p' "$f"; done
sed -n '1,340p' config/alertmanager/README.md
sed -n '1,340p' config/prometheus/README.md
```

!!! success "Expected Result"

    Approved scope, repository ownership, applicable standards, worktree
    changes, dan lifecycle interfaces diketahui sebelum source atau runtime
    diubah.

**Actual Result**

TN-034 dan related navigation changes ditemukan pada handbook dan
dipertahankan. Source contract menetapkan `tomcat-monitoring` sebagai owner
configuration/integration, repository `alertmanager` serta `prometheus` sebagai
owner generic runtime, dan immutable upstream Mailpit sebagai accepted lab-only
exception.

**Evidence**

- Repository instructions dan tiga documentation standards dibaca sebelum
  perubahan.
- Source files serta runtime scripts yang menentukan image, mounts, ports,
  initialization, run, dan cleanup boundary telah direview.

</div>

<div class="procedure-step" markdown>

### Inspect Exact Runtime Preflight State

Memastikan baseline sehat dan seluruh exact mutation serta rollback targets
tidak berbenturan.

1. Jalankan initial Podman inventory dari sandbox.
2. Setelah sandbox ditolak oleh read-only runtime path, ulangi query yang sama
   melalui approved host access.
3. Periksa exact images, containers, mounts, network, volumes, ports, active
   Prometheus configuration, Alertmanager target state, rules, targets, query
   result, TSDB head, dan configuration checksums.

```bash
# Initial sandbox-local attempt; failed before inspection
podman ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Networks}}|{{.Ports}}|{{.Status}}'
podman volume ls --format '{{.Name}}'
podman network ls --format '{{.ID}}|{{.Name}}|{{.Driver}}'

# Approved host-access repeat
podman ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Networks}}|{{.Ports}}|{{.Status}}'
podman volume ls --format '{{.Name}}'
podman network ls --format '{{.ID}}|{{.Name}}|{{.Driver}}'
podman image inspect --format '{{.Id}}|{{.RepoTags}}|{{.Digest}}|{{.Architecture}}|{{.Os}}' localhost/alertmanager:1.0.0 localhost/prometheus:1.0.0 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
podman inspect --format 'name={{.Name}} id={{.Id}} image={{.ImageName}} state={{.State.Status}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' prometheus telegraf tomcat-jmx-exporter
curl --silent --show-error --fail --output /tmp/tm-tn035-status-config.json http://127.0.0.1:9090/api/v1/status/config
curl --silent --show-error --fail --output /tmp/tm-tn035-alertmanagers.json http://127.0.0.1:9090/api/v1/alertmanagers
curl --silent --show-error --fail --output /tmp/tm-tn035-rules.json 'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --silent --show-error --fail --output /tmp/tm-tn035-targets.json 'http://127.0.0.1:9090/api/v1/targets?state=active'
curl --silent --show-error --fail --output /tmp/tm-tn035-up.json 'http://127.0.0.1:9090/api/v1/query?query=up'
curl --silent --show-error --fail --output /tmp/tm-tn035-tsdb.json http://127.0.0.1:9090/api/v1/status/tsdb
podman exec prometheus sha256sum /etc/prometheus/prometheus.yml /etc/prometheus/rules/application-health.yml /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt
ss -ltn '( sport = :8025 or sport = :9093 )'
```

!!! success "Expected Result"

    Baseline sehat, exact identities diketahui, candidate resources tidak
    tersedia, dan rollback dapat disiapkan tanpa ambiguity.

**Actual Result**

Initial sandbox attempt gagal pada read-only `/run/user/1000/libpod` tanpa
mengubah runtime. Approved repeat menemukan Prometheus ID `5efe0dc0…`,
Telegraf ID `e5324e07…`, serta Tomcat/JMX running pada `devops-lab`; kedua
targets `up=1`, tiga rules `inactive/ok`, dan active Alertmanager masih kosong.

**Evidence**

- Exact Alertmanager dan Prometheus local images serta immutable Mailpit
  `linux/amd64` digest tersedia.
- Containers, volumes, initializer names, dan ports `8025` serta `9093` yang
  akan digunakan tidak berbenturan.
- Active Prometheus configuration belum memuat `alerting`, sehingga controlled
  replacement diperlukan.

</div>

<div class="procedure-step" markdown>

### Apply and Validate Source Interfaces

Membentuk initialization interface dan static guard sebelum runtime diubah.

1. Tambahkan `scripts/initialize-alertmanager-volumes.sh` untuk exact
   `alertmanager_config` dan `alertmanager_data` volumes.
2. Perluas aggregate serta Alertmanager validators untuk memeriksa exact names,
   `podman cp`, shell syntax, initializer cleanup, dan larangan volume deletion.
3. Perbarui source, configuration, dan validation documentation.
4. Jalankan shell/static validation, `amtool check-config`, serta combined
   `promtool` checks.

```bash
chmod 0755 scripts/initialize-alertmanager-volumes.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager:/etc/alertmanager:ro --entrypoint /bin/amtool localhost/alertmanager:1.0.0 check-config /etc/alertmanager/alertmanager.yml
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c '/bin/promtool check rules rules/application-health.yml && /bin/promtool check config prometheus.yml && /bin/promtool test rules tests/application-health.test.yml'
```

!!! success "Expected Result"

    Source interfaces memenuhi accepted persistent contract dan seluruh
    mandatory checks lulus sebelum runtime mutation.

**Actual Result**

Initializer dan validation guards berhasil diterapkan. Aggregate validation,
`amtool`, configuration/rule checks, dan seluruh rule-unit tests exit `0`.

**Evidence**

- `amtool` menemukan satu route dan satu receiver tanpa semantic error.
- `promtool` menemukan tiga rules serta satu rule file dan melaporkan
  `SUCCESS` untuk rule-unit tests.

</div>

<div class="procedure-step" markdown>

### Create Persistent Alertmanager and Mailpit

Membuat notification components pada accepted `devops-lab` boundary.

1. Inisialisasi exact Alertmanager configuration dan data volumes.
2. Jalankan Mailpit immutable tanpa named volume, dengan internal SMTP dan
   loopback-only API/UI.
3. Jalankan Alertmanager menggunakan exact local image serta read-only
   configuration mount.
4. Verifikasi image identity, mounts, ports, readiness, active configuration,
   dan controlled restart.

```bash
./scripts/initialize-alertmanager-volumes.sh
podman run --detach --pull=never --name mailpit --network devops-lab --network-alias mailpit --publish 127.0.0.1:8025:8025 --env MP_DATABASE=/tmp/mailpit.db --env MP_MAX_MESSAGES=50 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
/home/eddywiyatno/git/alertmanager/scripts/run.sh alertmanager_config alertmanager_data alertmanager
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info
podman exec alertmanager /bin/sh -c 'wget -qO- http://127.0.0.1:9093/-/ready'
podman exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
podman restart alertmanager
```

!!! success "Expected Result"

    Persistent Mailpit dan Alertmanager ready pada `devops-lab`; SMTP serta
    Alertmanager API tidak dipublikasikan pada host.

**Actual Result**

Mailpit ID `e357c1f3…` menjalankan accepted `v1.31.0` digest dengan hanya
`127.0.0.1:8025`. Alertmanager ID `ff2d4b2f…` memakai
`alertmanager_config:/etc/alertmanager:ro` dan
`alertmanager_data:/alertmanager:rw` tanpa host port. Controlled restart
mempertahankan exact ID dan kembali ready.

**Evidence**

- Mailpit API melaporkan version `v1.31.0`.
- Alertmanager readiness menghasilkan `OK`; `amtool check-config` menghasilkan
  `SUCCESS`.
- `alertmanager-volume-init` absent setelah initialization.

</div>

<div class="procedure-step" markdown>

### Retain Rollback and Replace Prometheus

Melakukan cutover tanpa menghilangkan original container atau configuration
rollback state.

1. Snapshot active `prometheus_config` ke protected rollback volume dan
   verifikasi checksum.
2. Stop serta rename exact original Prometheus menjadi rollback container.
3. Perbarui existing configuration volume melalui initializer resmi.
4. Jalankan replacement Prometheus dengan image, network, port, truststore, dan
   data volume yang sama.
5. Verifikasi readiness, active Alertmanager, target health, dan historical
   data availability.

```bash
podman volume create prometheus_config_tn035_rollback
podman run --rm --pull=never --name prometheus-tn035-snapshot --user 0 --entrypoint /bin/sh --volume prometheus_config:/source:ro --volume prometheus_config_tn035_rollback:/backup localhost/prometheus:1.0.0 -c 'cp -a /source/. /backup/; chmod -R a-w /backup'
podman run --rm --pull=never --name prometheus-tn035-snapshot-check --entrypoint /bin/sh --volume prometheus_config_tn035_rollback:/snapshot:ro localhost/prometheus:1.0.0 -c 'sha256sum /snapshot/prometheus.yml /snapshot/rules/application-health.yml'
podman stop prometheus
podman rename prometheus prometheus-tn035-rollback
./scripts/initialize-prometheus-volumes.sh /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
/home/eddywiyatno/git/prometheus/scripts/run.sh prometheus_config prometheus_truststore prometheus_data prometheus 9090
curl --fail --silent --show-error http://127.0.0.1:9090/-/ready

# Initial continuity assertion; failed because TSDB head minTime moved
curl --silent --show-error --fail --output /tmp/tm-tn035-post-tsdb.json http://127.0.0.1:9090/api/v1/status/tsdb
python3 -c 'import json; h=json.load(open("/tmp/tm-tn035-post-tsdb.json"))["data"]["headStats"]; assert h["minTime"] <= 1787881158739'

# Corrected continuity check
curl --silent --show-error --fail --output /tmp/tm-tn035-historical-up.json 'http://127.0.0.1:9090/api/v1/query?query=up&time=1787885500'
python3 -c 'import json; r=json.load(open("/tmp/tm-tn035-historical-up.json"))["data"]["result"]; assert len(r) == 2 and all(x["value"][1] == "1" for x in r)'
```

!!! success "Expected Result"

    Replacement Prometheus ready dan melihat healthy Alertmanager tanpa
    mengganti data volume; original container serta protected snapshot tetap
    tersedia.

**Actual Result**

Old configuration checksum `e7022906…` cocok dengan protected snapshot.
Original ID `5efe0dc0…` retained sebagai stopped
`prometheus-tn035-rollback`; replacement ID `897f4ec3…` kembali ready dan
melaporkan exactly one active URL
`http://alertmanager:9093/api/v2/alerts`.

Initial `minTime` assertion gagal karena head compaction menggeser window dari
`1787881158739` menjadi `1787882215465`. Criterion dikoreksi pada step yang
sama menjadi historical data availability; no rollback diperlukan.

**Evidence**

- CA checksum tetap `6f0dbd6c…`; replacement memakai existing
  `prometheus_data`.
- Historical query pada timestamp sebelum cutover tetap menghasilkan kedua
  targets `up=1`.

</div>

<div class="procedure-step" markdown>

### Verify Real Firing and Resolved Delivery

Membuktikan notification flow menggunakan real persistent Prometheus rule,
bukan synthetic API payload.

1. Pastikan Mailpit baseline kosong dan exact Telegraf identity cocok.
2. Pasang safety restore guard lalu stop exact Telegraf.
3. Tunggu rule berpindah menjadi `firing` dan validasi matching firing email.
4. Start kembali exact Telegraf.
5. Tunggu scrape recovery, rule `inactive`, dan matching resolved email.

```bash
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
```

!!! success "Expected Result"

    Mailpit menangkap matching firing dan resolved email; Telegraf kembali
    `up=1` dan rule kembali `inactive`.

**Actual Result**

Rule berpindah `inactive` → `pending` → `firing` pada 10:02:07 WIB. Firing
email diterima pada 10:02:48. Telegraf kemudian di-start, scrape kembali
`up=1`, rule menjadi `inactive`, dan resolved email diterima pada 10:07:39
sesuai accepted grouping interval.

**Evidence**

- Kedua subjects sesuai `TelegrafHealthScrapeUnavailable - telegraf:9273` dan
  status masing-masing `firing` serta `resolved`.
- Sender, recipient, alert name, job, instance, dan severity assertions lulus.

</div>

<div class="procedure-step" markdown>

### Verify Final Persistent State

Mengaudit recovery, persistence, retained rollback, dan exact cleanup boundary.

1. Verifikasi targets, rules, health metric, active Alertmanager, dan Mailpit
   message count.
2. Restart controlled Alertmanager dan periksa persisted state serta duplicate
   notification.
3. Audit persistent containers, stopped rollback container, volumes, temporary
   resource absence, dan host listeners.

```bash
podman exec alertmanager sha256sum /alertmanager/nflog /alertmanager/silences
podman restart alertmanager
sleep 40
curl --silent --show-error --fail --output /tmp/tm-tn035-post-am-restart-messages.json http://127.0.0.1:8025/api/v1/messages
curl --silent --show-error --fail --output /tmp/tm-tn035-post-am-restart-target.json http://127.0.0.1:9090/api/v1/alertmanagers

curl --silent --show-error --fail --output /tmp/tm-tn035-final-rules.json 'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --silent --show-error --fail --output /tmp/tm-tn035-final-targets.json 'http://127.0.0.1:9090/api/v1/targets?state=active'
curl --silent --show-error --fail --output /tmp/tm-tn035-final-up.json 'http://127.0.0.1:9090/api/v1/query?query=up'
curl --silent --show-error --fail --output /tmp/tm-tn035-final-health.json 'http://127.0.0.1:9090/api/v1/query?query=http_response_result_code%7Bjob%3D%22telegraf-health%22%7D'
curl --silent --show-error --fail --output /tmp/tm-tn035-final-messages.json http://127.0.0.1:8025/api/v1/messages

for name in prometheus telegraf tomcat-jmx-exporter alertmanager mailpit prometheus-tn035-rollback; do
    podman inspect --format 'name={{.Name}} id={{.Id}} state={{.State.Status}} image={{.ImageName}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' "$name"
done
for name in alertmanager-volume-init prometheus-volume-init prometheus-tn035-snapshot prometheus-tn035-snapshot-check; do
    podman container exists "$name"
done
for name in alertmanager_config alertmanager_data prometheus_config prometheus_truststore prometheus_data prometheus_config_tn035_rollback; do
    podman volume exists "$name"
done
ss -ltn '( sport = :8025 or sport = :9090 or sport = :9093 )'
```

!!! success "Expected Result"

    Baseline monitoring pulih, state Alertmanager bertahan, temporary resources
    absent, dan retained rollback resources tetap tersedia.

**Actual Result**

Final state memiliki dua targets `up`, health result `0`, tiga rules
`inactive/ok`, satu active Alertmanager, dan exactly two Mailpit messages.
Controlled restart mempertahankan exact Alertmanager serta data volume tanpa
duplicate email.

**Evidence**

- Persistent Prometheus, Alertmanager, Mailpit, Telegraf, dan Tomcat/JMX tetap
  running; original Prometheus rollback tetap stopped.
- Four temporary containers absent dan six accepted persistent volumes tetap
  tersedia.
- Host listeners hanya menunjukkan Mailpit API pada `127.0.0.1:8025` dan
  Prometheus pada `9090`; Alertmanager `9093` tidak dipublikasikan.

</div>

<div class="procedure-step" markdown>

### Consolidate and Review Documentation

Menyelaraskan source documentation, Engineering Journal, navigation, dan
current-state pages setelah runtime result berlaku.

1. Perbarui source README serta Alertmanager configuration/validation contract.
2. Perbarui TN-035, phase navigation, project overview, Architecture,
   Development, Infrastructure, dan Operations.
3. Jalankan source validation, whitespace review, navigation/link checks,
   stale-state scan, dan MkDocs availability check.

```bash
# /home/eddywiyatno/git/tomcat-monitoring
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check

# /home/eddywiyatno/git/devops-handbook
git diff --check
rg -n 'TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/index.md
rg -n -i 'persistent Alertmanager.*belum|runtime delivery not verified|deployment not verified|Mailpit.*disposable lab topology|persistent and external delivery pending' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
if command -v mkdocs >/dev/null; then mkdocs build --strict --site-dir /tmp/tm-tn035-mkdocs-site; else echo 'mkdocs=not-installed'; fi
```

!!! success "Expected Result"

    Source dan current-state documentation konsisten dengan verified runtime;
    navigation, links, dan changed files lulus review.

**Actual Result**

Source validation dan `git diff --check` lulus. Navigation serta related files
tersedia dan stale current-state scan tidak menemukan status lama pada target
pages. MkDocs render tidak dijalankan karena executable tidak tersedia.

**Evidence**

- Aggregate source validator melaporkan seluruh component contracts valid.
- TN-035 terdaftar pada `.pages` dan phase index.
- MkDocs dicatat `Not verified`; dependency tidak dipasang.

</div>

</div>

## ↩️ Rollback Result

Rollback tidak dipicu karena replacement dan mandatory recovery criteria
lulus. Original `prometheus-tn035-rollback` serta protected configuration
snapshot tetap dipertahankan sesuai plan; keberadaannya bukan authorization
untuk menghapus keduanya.

### Retire Accepted Rollback State

Setelah Enterprise SRE evidence diterima, project owner memberi exact
destructive authorization pada 2026-08-28 untuk menghapus stopped container
`prometheus-tn035-rollback`, named volume
`prometheus_config_tn035_rollback`, dan lima configuration rollback files.
Authorization tidak mencakup persistent active volumes atau temporary evidence
non-rollback.

```bash
set -euo pipefail
test "$(podman inspect --format '{{.Id}}' prometheus-tn035-rollback)" = \
  '5efe0dc00a6507f0f7c33ca946717bee9cb05feaadfc2802586602e4ae8098a3'
test "$(podman inspect --format '{{.State.Status}}' prometheus-tn035-rollback)" = \
  'exited'
test "$(podman volume inspect --format '{{.Name}}' prometheus_config_tn035_rollback)" = \
  'prometheus_config_tn035_rollback'
test -z "$(podman ps --all --filter volume=prometheus_config_tn035_rollback --format '{{.ID}}')"
for path in \
  /tmp/tm-tn035-alertmanager-body-rollback.yml \
  /tmp/tm-tn035-alertmanager-body-v1-rollback.yml \
  /tmp/tm-tn035-alertmanager-unified-rollback.yml \
  /tmp/tm-tn035-prometheus-unified-rule-rollback.yml \
  /tmp/tm-tn035-alertmanager-enterprise-rollback.yml; do
    test -f "$path"
done

podman rm 5efe0dc00a6507f0f7c33ca946717bee9cb05feaadfc2802586602e4ae8098a3
podman volume rm prometheus_config_tn035_rollback
rm -- \
  /tmp/tm-tn035-alertmanager-body-rollback.yml \
  /tmp/tm-tn035-alertmanager-body-v1-rollback.yml \
  /tmp/tm-tn035-alertmanager-unified-rollback.yml \
  /tmp/tm-tn035-prometheus-unified-rule-rollback.yml \
  /tmp/tm-tn035-alertmanager-enterprise-rollback.yml

if podman container exists prometheus-tn035-rollback; then exit 1; fi
if podman volume exists prometheus_config_tn035_rollback; then exit 1; fi
for path in \
  /tmp/tm-tn035-alertmanager-body-rollback.yml \
  /tmp/tm-tn035-alertmanager-body-v1-rollback.yml \
  /tmp/tm-tn035-alertmanager-unified-rollback.yml \
  /tmp/tm-tn035-prometheus-unified-rule-rollback.yml \
  /tmp/tm-tn035-alertmanager-enterprise-rollback.yml; do
    test ! -e "$path"
done

podman inspect --format 'name={{.Name}} id={{.Id}} state={{.State.Status}} image={{.ImageName}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}}' \
  prometheus telegraf tomcat-jmx-exporter alertmanager mailpit
for name in prometheus_config prometheus_truststore prometheus_data \
  alertmanager_config alertmanager_data; do
    podman volume exists "$name"
    printf 'volume=%s exists\n' "$name"
done
curl --fail --silent --show-error http://127.0.0.1:9090/-/ready
podman exec alertmanager wget -qO- http://127.0.0.1:9093/-/ready
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info
```

**Expected Result:** hanya exact retained rollback resources absent; persistent
monitoring containers dan active named volumes tetap tersedia serta ready.

**Actual Result:** cleanup passed. Exact container ID, stopped state, detached
rollback volume, dan lima files cocok sebelum deletion. Container, volume, dan
files kemudian absent. Prometheus, Telegraf, Tomcat/JMX, Alertmanager, serta
Mailpit tetap running; `prometheus_config`, `prometheus_truststore`,
`prometheus_data`, `alertmanager_config`, dan `alertmanager_data` tetap ada.
Prometheus serta Alertmanager readiness menghasilkan success dan Mailpit
`v1.31.0` tetap melaporkan `10` retained messages.

## ✅ Verification

| Criterion | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Source readiness | Shell/static and semantic validation | Seluruh checks lulus sebelum mutation. | Passed | `bash -n`, aggregate validator, `amtool`, and combined `promtool` checks exit `0`. |
| Persistent components | Exact inspect, readiness, mounts, ports, network, restart continuity | Contract TN-034 terpenuhi. | Passed | Exact IDs, `devops-lab`, accepted mounts/ports, readiness, immutable Mailpit identity, and Alertmanager restart passed. |
| Prometheus delivery | API active Alertmanager dan real alert observation | Healthy target dan alert diterima Alertmanager. | Passed | Exactly one active API v2 URL; real scrape-unavailable rule reached `firing`. |
| Notification flow | Mailpit API/message assertions | Matching firing dan resolved email tersedia. | Passed | Exactly two messages with expected firing/resolved subjects, synthetic identities, and matching alert tokens. |
| Corrected notification body | Static, isolated, and persistent real-rule firing/resolved verification | Firing memakai red banner dan active description; resolved memakai green banner dan recovery message tanpa stale firing description; inaccessible Alertmanager link absent. | Passed | `status_color_rendering=passed`, `resolved_stale_description=absent`, newest persistent pair passed exact HTML assertions, and runtime recovery passed. |
| Unified operator alert-template | Static validation, disposable semantic/render tests, controlled persistent deployment, and real-rule cycle | Subject/body memakai normal/warning/critical, positive resolved names, identical keys, complete labels, dan critical scrape-down severity. | Passed automated verification; rejected as too basic in visual review | Messages `2V6shq4dGekDSAOt2iXOZI` and `2IfpN1RgUUkx8JMwe9RxhX` passed exact assertions, but rejected on visual review as lacking enterprise layout. |
| Enterprise SRE alert-template (Option 1) | Static validation, disposable Mailpit test, controlled persistent deployment, real-rule cycle, and project-owner visual review | Subject memakai format `[CRITICAL/RESOLVED] [LAB] Tomcat Service: ...`, body memuat header banner, Alert/Recovery Summary box, Technical Details grid, Impact & Recommended Actions, dan footer metadata. | Passed; accepted by project owner on 2026-08-28 | Component/aggregate validators and `git diff --check` passed; disposable verification passed; mounted checksum matched source; persistent messages `5PfV1BUj3qVXGg6iyVCc8f` (critical) and `1thrY0Vplr9vcxqaLQp8yW` (resolved) passed exact HTML and layout assertions, remained available in Mailpit, and were visually accepted. |
| Recovery | Target, rules, metric, TSDB, dan Telegraf checks | Baseline pulih tanpa data-volume replacement. | Passed after criterion correction | Two targets `up`, three rules `inactive/ok`, health result `0`, same data volume, and historical pre-cutover query available. |
| Cleanup boundary | Exact resource audit | Temporary resources absent; retained state tetap tersedia. | Passed | Four exact temporary containers absent; persistent runtime, rollback container, and six intended volumes retained. |
| Source and documentation review | Shell/static checks, diff review, navigation, links, and stale-state scan | Seluruh changed source dan documentation konsisten. | Passed | Aggregate validation and `git diff --check` exit `0`; navigation and relative targets present; stale current-state patterns absent. |
| MkDocs render | Site dapat dirender tanpa error. | Strict build passed. | Not verified | `mkdocs` executable tidak tersedia; dependency tidak dipasang. |

## ✅ Operator Validation

Initial runtime objective TN-035 telah selesai, tetapi seluruh empat earlier
captured pairs ditolak sebagai operator acceptance evidence. Delapan earlier
messages merupakan historical evidence; enterprise SRE deployment sekarang
menambah critical/resolved pair kesembilan dan kesepuluh sebagai target review
baru.

| Item | Value |
| --- | --- |
| State | Accepted by project owner on 2026-08-28 |
| Owner | Project owner |
| Validation target | Messages `5PfV1BUj3qVXGg6iyVCc8f` (critical) dan `1thrY0Vplr9vcxqaLQp8yW` (resolved) with Enterprise SRE card layout |
| Access boundary | Mailpit API/UI hanya tersedia pada host loopback `127.0.0.1:8025` |
| Evidence retention | Mailpit tidak memakai named volume; review harus dilakukan sebelum container replacement |
| Closure record | Project owner menyatakan `Accepted` pada 2026-08-28 setelah exact pair diperiksa melalui Mailpit |

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Confirm Mailpit Evidence Availability

Pastikan Mailpit masih ready dan historical messages belum hilang sebelum
membuka UI. Langkah ini hanya memastikan evidence retention, bukan menerima
kontrak baru.

1. Jalankan readiness dan message-list query pada `edkas-pc1`.
2. Pastikan API dapat diakses dan `total` bernilai `10`.
3. Pastikan dua message terbaru adalah enterprise critical/resolved pair dan
   delapan earlier messages tetap tersedia sebagai historical rejected evidence.

```bash
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info \
  | python3 -m json.tool
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/messages \
  | python3 -m json.tool
```

!!! success "Expected Result"

    Mailpit API merespons, message total bernilai `10`, dua message terbaru
    merupakan enterprise SRE evidence, dan delapan earlier messages tetap
    tersedia.

Readiness check pada 2026-08-28 menemukan Mailpit `v1.31.0` running dan seluruh
historical messages tetap tersedia di inbox.

Eight historical messages yang ditolak mencakup:
* Initial pre-correction pair (resolved body menampilkan static firing description dan link internal).
* First corrected pair `0hparwQ9ljUTe0ZKEoEBla` & `08sZsOZDAP5ECXI28dtDM6` (custom body tidak mempertahankan status visual red/green).
* Visual-corrected pair `48qTLY3XaYk8NcDXLwpORP` & `3hIN8Z2K7qQn7xkcnA7V8O` (resolved subject/body masih memakai negative alert name).
* Unified pair `2V6shq4dGekDSAOt2iXOZI` & `2IfpN1RgUUkx8JMwe9RxhX` (ditolak pada 2026-08-28 karena layout tabel polos dan judul kurang mencerminkan standar penggunaan enterprise).

</div>

<div class="procedure-step" markdown>

### Open the Mailpit Web Interface

Pilih access method berdasarkan lokasi browser. Jangan memublikasikan port baru
atau mengubah container hanya untuk operator review.

1. Jika browser berjalan langsung pada `edkas-pc1`, buka
   `http://127.0.0.1:8025`.
2. Jika browser berada pada workstation lain, buat SSH tunnel dari workstation
   tersebut dan biarkan terminal tetap terbuka:

    ```bash
    ssh -N -L 8025:127.0.0.1:8025 <username>@edkas-pc1
    ```

3. Dari browser workstation, buka `http://127.0.0.1:8025`.
4. Jangan menggunakan `http://edkas-pc1:8025`; Mailpit sengaja hanya bind ke
   loopback host.

!!! success "Expected Result"

    Mailpit inbox tampil dan mempertahankan delapan historical messages tanpa
    mengubah network atau container configuration.

</div>

<div class="procedure-step" markdown>

### Inspect Historical Rejected Messages

Review messages lama hanya bila histori finding perlu dikonfirmasi. Jangan
mencatatnya sebagai accepted enterprise-template evidence.

1. Buka messages dengan subject lama.
2. Perhatikan perkembangan iterasi dari tabel polos awal, perbaikan warna,
   unifikasi status, hingga penolakan karena kurang memenuhi standar visual
   enterprise.

!!! success "Expected Result"

    Historical pairs dapat direkonstruksi beserta alasan penolakan masing-masing.

</div>

<div class="procedure-step" markdown>

### Validate Enterprise SRE Critical and Resolved Pair (Option 1)

Verified Enterprise SRE candidate telah dipromosikan secara terkontrol ke
persistent Prometheus serta Alertmanager. Gunakan exact message IDs agar
evidence baru tidak tertukar dengan eight-message historical baseline.

1. Pastikan deployment evidence mencatat source/runtime checksums dan hasil
   semantic checks yang sama.
2. Pastikan controlled real-rule cycle menghasilkan tepat satu pasangan baru
   setelah eight-message historical baseline:

    | State | Message ID | Created (UTC) |
    | --- | --- | --- |
    | Critical | `5PfV1BUj3qVXGg6iyVCc8f` | `2026-08-28T11:18:32.436Z` |
    | Resolved | `1thrY0Vplr9vcxqaLQp8yW` | `2026-08-28T11:23:32.437Z` |
3. Buka critical message dan cocokkan subject:
   `[CRITICAL] [LAB] Tomcat Service: TelegrafHealthScrapeUnavailable (Instance: telegraf:9273)`.
4. Buka resolved message dan cocokkan subject:
   `[RESOLVED] [LAB] Tomcat Service: TelegrafHealthScrapeAvailable (Instance: telegraf:9273)`.
5. Pada kedua body, pastikan struktur bagian lengkap:
   * **Header Banner**: `[ CRITICAL ] Tomcat Monitoring Alert` (merah) atau `[ RESOLVED ] Service Restored` (hijau) dengan badge `LAB Environment`.
   * **Summary Box**: `⚠️ Alert Summary` (dengan deskripsi gangguan aktif) atau `✅ Recovery Summary` (dengan pesan pemulihan scrape).
   * **Technical Details**: Grid key-value rapi untuk `Alert Name`, `Service / Check`, `Target Instance`, `Severity`, dan `Status`.
   * **Impact & Recommended Actions**: Panduan dampak operasional dan langkah penanganan konkret.
   * **Footer Metadata**: `Tomcat Monitoring Platform • Automated Incident Notification • Do not reply`.
6. Pastikan inaccessible Alertmanager link dan internal container hostname absent.

!!! success "Expected Result"

    Pasangan baru menyajikan notifikasi insiden bergaya Enterprise SRE modern
    yang informatif, actionable, bergradasi warna status jelas, dan siap diajukan
    kepada project owner untuk acceptance review.

**Actual Result:** full HTML assertions lulus untuk exact critical/resolved pair.
Subject, name, severity, descriptions, red/green banners, summary boxes,
technical details grid, impact/action guidance, dan footer layout sesuai
contract Option 1.

</div>

<div class="procedure-step" markdown>

### Record the Operator Decision

Tutup validation berdasarkan hasil visual review tanpa menjalankan ulang
failure injection.

1. Catat hasil sebagai `Accepted` bila kedua message memenuhi seluruh expected
   values.
2. Catat hasil sebagai `Rejected` dan sebutkan field atau message yang tidak
   sesuai bila ditemukan mismatch.
3. Jika inbox kosong atau Mailpit tidak ready, hentikan review dan laporkan
   evidence unavailable. Jangan stop Telegraf atau mengulang firing test tanpa
   authorization baru.
4. Jika menggunakan SSH tunnel, tekan `Ctrl+C` pada terminal tunnel setelah
   review selesai.

!!! success "Expected Result"

    Operator validation memiliki keputusan eksplisit dan tidak mengubah
    persistent monitoring runtime.

**Actual Result**

Project owner menyatakan exact Enterprise SRE critical/resolved pair
`Accepted` pada 2026-08-28. Sebelum keputusan, read-only host query memastikan
Mailpit `v1.31.0` ready dengan total `10` messages dan exact pair tetap menjadi
dua message terbaru. Full HTML serta browser rendering memperlihatkan subject,
red/green status banner, Alert/Recovery Summary, Technical Details, Impact &
Recommended Actions, dan footer sesuai accepted contract.

Tidak ada failure injection, container change, source change, atau runtime
mutation yang dilakukan selama Operator Validation. Initial sandbox query gagal
mencapai host loopback; approved host-access retry berhasil.

```bash
# Initial sandbox-local attempt; failed to reach the host loopback listener
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/messages

# Approved read-only host-access retry and exact-message retrieval
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/messages
for id in 5PfV1BUj3qVXGg6iyVCc8f 1thrY0Vplr9vcxqaLQp8yW; do
    curl --fail --silent --show-error "http://127.0.0.1:8025/api/v1/message/$id"
done

# Read-only UI route discovery and visual rendering
curl --fail --silent --show-error http://127.0.0.1:8025/
curl --fail --silent --show-error 'http://127.0.0.1:8025/dist/app.js?v1.31.0' \
  | rg -o '.{0,120}(message|Message).{0,180}' \
  | rg '(path|route|view|ID|id)' \
  | head -80
google-chrome --headless=new --disable-gpu --hide-scrollbars \
  --user-data-dir=/tmp/tm-tn035-chrome-critical \
  --window-size=1280,1400 \
  --screenshot=/tmp/tm-tn035-critical.png \
  http://127.0.0.1:8025/view/5PfV1BUj3qVXGg6iyVCc8f
google-chrome --headless=new --disable-gpu --hide-scrollbars \
  --user-data-dir=/tmp/tm-tn035-chrome-resolved \
  --window-size=1280,1400 \
  --screenshot=/tmp/tm-tn035-resolved.png \
  http://127.0.0.1:8025/view/1thrY0Vplr9vcxqaLQp8yW
file /tmp/tm-tn035-critical.png /tmp/tm-tn035-resolved.png
```

**Evidence**

- Critical message `5PfV1BUj3qVXGg6iyVCc8f` dan resolved message
  `1thrY0Vplr9vcxqaLQp8yW` cocok dengan exact IDs, timestamps, subjects, dan
  full HTML contract pada TN ini.
- Screenshots `/tmp/tm-tn035-critical.png` dan
  `/tmp/tm-tn035-resolved.png` menjadi transient visual-review evidence.
- Project-owner decision: `Accepted` pada 2026-08-28.

Documentation-only closure kemudian memperbarui Operator Validation, Outcome,
Next Steps, Open Questions, dan current-state Architecture tanpa mengubah
source atau runtime.

```bash
# /home/eddywiyatno/git/devops-handbook
git diff --check
git diff -- \
  docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md \
  docs/projects/tomcat-monitoring/architecture/index.md
for file in \
  docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md \
  docs/projects/tomcat-monitoring/architecture/index.md; do
    awk 'BEGIN { fenced=0 } /^```/ { fenced=!fenced; next } !fenced { print }' "$file"
done | rg -n 'Accepted by project owner|Accepted on 2026-08-28|Enterprise SRE visual evidence'
if for file in \
  docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md \
  docs/projects/tomcat-monitoring/architecture/index.md; do
    awk 'BEGIN { fenced=0 } /^```/ { fenced=!fenced; next } !fenced { print }' "$file"
  done | rg -n '\| State \| .*pending|project-owner visual acceptance tetap dicatat'; then
    exit 1
fi
git status --short --branch
```

**Actual Result:** targeted diff mempertahankan perubahan lokal sebelumnya,
acceptance state konsisten pada TN dan Architecture, stale pending-acceptance
text absent, dan `git diff --check` exit `0`. MkDocs tidak dijalankan karena
approved verification scope hanya mencakup targeted diff dan whitespace check.

</div>

</div>

## 🛠️ Post-validation Correction

Project owner menolak initial visual evidence pada 2026-08-28 karena resolved
email berwarna hijau tetapi body tetap menyampaikan static firing description
seolah-olah kondisi masih aktif. Default `View in Alertmanager` link juga
memakai internal container hostname walaupun Alertmanager API tidak
dipublikasikan ke host. Project owner menyetujui source correction; persistent
Alertmanager configuration replacement dan real failure injection tidak
termasuk authorization tersebut.

Project owner kemudian menyetujui persistent deployment dan real-rule
revalidation pada 2026-08-28. Scope tambahannya terbatas pada backup current
configuration, overwrite `alertmanager_config`, restart exact `alertmanager`,
bounded stop/start exact `telegraf`, dan verification tanpa memublikasikan port
Alertmanager, mengganti Mailpit, atau menghapus retained evidence dan volumes.

Project owner menolak first corrected persistent pair pada 2026-08-28 karena
resolved body masih menampilkan firing-condition context dan custom template
tidak mempertahankan red firing serta green resolved visual status. Project
owner menyetujui visual/content correction dan deployment ulang dengan runtime
boundary yang sama; seluruh earlier evidence tetap dipertahankan.

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Implement Status-specific Notification Body

1. Tambahkan conditional HTML berdasarkan Alertmanager `.Status`.
2. Nyatakan current state secara eksplisit untuk firing dan resolved.
3. Pertahankan annotation `description` sebagai `Alert condition context`.
4. Tampilkan alert name, instance, job, severity, service, dan check sebagai
   field terpisah.
5. Hilangkan default `View in Alertmanager` link karena URL-nya menggunakan
   internal container hostname sementara Alertmanager API sengaja tidak
   dipublikasikan ke host.
6. Perbarui static validator, isolated Mailpit assertions, dan configuration
   contract documentation.

!!! success "Expected Result"

    Source membedakan notification state dari static alert-rule annotation dan
    tetap mempertahankan operator-facing alert identity.

**Actual Result:** `config/alertmanager/alertmanager.yml` sekarang merender
`Alert condition is active` untuk firing dan `Alert condition is no longer
active` untuk resolved. Static description tetap tersedia dengan label
`Alert condition context`; custom body tidak lagi menampilkan inaccessible
`View in Alertmanager` link atau internal container hostname.

**Evidence:** configuration, validator, isolated verification fixture, dan
Alertmanager README berubah bersama pada source worktree `tomcat-monitoring`.

</div>

<div class="procedure-step" markdown>

### Validate Corrected Firing and Resolved Rendering

1. Jalankan shell dan aggregate source validation.
2. Jalankan isolated Alertmanager–Mailpit firing/resolved verification.
3. Koreksi fixture ketika failed assertion membuktikan synthetic payload belum
   memuat `description`.
4. Koreksi body-field assertions ketika custom template tidak lagi memakai
   raw default-label layout.
5. Ulangi verification dan audit exact disposable cleanup.

```bash
bash -n scripts/*.sh
./scripts/validate-alertmanager.sh
./scripts/validate.sh
./scripts/verify-alertmanager-mailpit.sh
```

!!! success "Expected Result"

    Source validation lulus; firing dan resolved body memuat state-specific
    text serta seluruh required fields; disposable resources dibersihkan tanpa
    mengubah persistent runtime.

**Actual Result:** dua percobaan awal gagal secara informatif pada fixture dan
legacy assertion, lalu final regression test lulus untuk sequence, identities,
subjects, status-specific body, labels, semantic configuration, serta cleanup.

**Evidence:** final output memuat `mailpit_sequence=firing,resolved`,
`status_specific_body=passed`, `message_body_group_labels=passed`,
`semantic_config=passed`, dan `cleanup_result=passed`. Persistent `mailpit` serta
dua pre-correction messages tidak menjadi target isolated test. Post-test audit
menemukan exact persistent containers `alertmanager` (`ff2d4b2f…`) dan
`mailpit` (`e357c1f3…`) tetap running serta Mailpit tetap menyimpan tepat dua
pre-correction messages.

</div>

<div class="procedure-step" markdown>

### Deploy Corrected Persistent Configuration

1. Verifikasi exact Alertmanager, Mailpit, dan Telegraf identities serta
   persistent mounts dan port boundary.
2. Salin active configuration ke protected temporary rollback file.
3. Inisialisasi ulang `alertmanager_config` dari corrected source.
4. Restart exact Alertmanager dan verifikasi ID, readiness, semantic config,
   source/runtime checksum, no-host-port boundary, dan retained Mailpit count.

```bash
podman cp alertmanager:/etc/alertmanager/alertmanager.yml \
  /tmp/tm-tn035-alertmanager-body-rollback.yml
chmod 0600 /tmp/tm-tn035-alertmanager-body-rollback.yml
sha256sum /tmp/tm-tn035-alertmanager-body-rollback.yml \
  config/alertmanager/alertmanager.yml
./scripts/initialize-alertmanager-volumes.sh
podman restart alertmanager
podman exec alertmanager /bin/sh -c \
  'wget -qO- http://127.0.0.1:9093/-/ready'
podman exec alertmanager amtool check-config \
  /etc/alertmanager/alertmanager.yml
podman exec alertmanager sha256sum \
  /etc/alertmanager/alertmanager.yml
```

!!! success "Expected Result"

    Corrected configuration aktif pada exact persistent Alertmanager tanpa
    mengubah container identity, data volume, Mailpit evidence, atau host-port
    boundary.

**Actual Result:** source/runtime checksum cocok pada `9c6c5350…`; exact
Alertmanager ID `ff2d4b2f…` tetap running dan ready; `amtool` menghasilkan
`SUCCESS`; port state tetap `{"9093/tcp":null}`; Mailpit tetap memiliki dua
pre-correction messages sebelum revalidation.

**Evidence:** prior configuration dipertahankan di
`/tmp/tm-tn035-alertmanager-body-rollback.yml` dengan checksum `6bb7905e…`.
Temporary initializer absent setelah deployment dan `alertmanager_data` tidak
diganti.

</div>

<div class="procedure-step" markdown>

### Repeat Real-rule Delivery and Verify Corrected HTML

1. Pastikan exact Telegraf running, rule inactive, scrape `up=1`, dan Mailpit
   baseline berjumlah dua.
2. Stop exact Telegraf dengan recovery guard dan poll rule sambil mencatat
   container state pada setiap iteration.
3. Setelah rule firing dan message ketiga tersedia, start kembali Telegraf.
4. Tunggu scrape `up=1`, rule inactive, dan resolved message keempat.
5. Ambil full HTML dua message terbaru dan jalankan required-field serta
   negative-link assertions.
6. Audit targets, rules, persistent IDs, runtime checksum, port boundary, dan
   temporary-resource absence.

```bash
podman stop telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error \
  http://127.0.0.1:8025/api/v1/messages
podman start telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22telegraf-health%22%7D'
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/targets?state=active'
```

!!! success "Expected Result"

    Corrected persistent firing/resolved pair tersedia; current-state text dan
    alert context benar; inaccessible Alertmanager link absent; seluruh
    monitoring baseline pulih.

**Actual Result:** clean diagnostic cycle mempertahankan Telegraf `exited`
selama pending, mencapai firing pada poll ke-10, menerima firing message ketiga,
memulihkan Telegraf, mencapai rule inactive dengan `up=1`, dan menerima
resolved message keempat setelah accepted group interval. Dua earlier guarded
attempts tidak menghasilkan message dan berakhir dengan Telegraf running;
Podman event/process audit memastikan tidak ada restart policy, timer, service,
watcher, atau polling process tertinggal sebelum clean cycle.

**Evidence:** persistent message IDs `0hparwQ9ljUTe0ZKEoEBla` (firing) dan
`08sZsOZDAP5ECXI28dtDM6` (resolved) lulus exact HTML assertions. Output memuat
`persistent_status_specific_body=passed`,
`persistent_inaccessible_alertmanager_link=absent`, two targets `up`, three
rules `inactive`, `mailpit_total=4`, dan `alertmanager_host_port=false`.
Container hostname hanya ditemukan pada MIME `Message-ID`, bukan body atau
hyperlink.

</div>

<div class="procedure-step" markdown>

### Refine Visual and Resolved-content Contract

1. Gunakan HTML email card dengan inline styling yang kompatibel dengan email
   client.
2. Render red banner `#c62828`, heading `[1] Firing`, active state, dan rule
   description hanya untuk firing.
3. Render green banner `#2e7d32`, heading `[1] Resolved`, dan explicit recovery
   message hanya untuk resolved.
4. Jangan render firing description atau `Alert condition context` pada
   resolved body.
5. Pertahankan alert identity fields dan inaccessible-link exclusion.
6. Perketat static serta isolated HTML assertions untuk warna dan stale-content
   absence.

!!! success "Expected Result"

    Firing dan resolved dapat dibedakan melalui warna serta isi; resolved body
    tidak lagi menyampaikan kondisi gangguan sebagai current atau contextual
    message.

**Actual Result:** template menggunakan red/green status banner dan conditional
content. Firing memuat `Description`; resolved memuat `Resolution: The alert
condition has cleared. The monitoring rule is no longer firing.` tanpa firing
description.

**Evidence:** static validation lulus; isolated output memuat
`status_color_rendering=passed`, `resolved_stale_description=absent`,
`status_specific_body=passed`, dan `cleanup_result=passed`.

</div>

<div class="procedure-step" markdown>

### Deploy Visual-corrected Alertmanager Revision

1. Pastikan exact Alertmanager tetap running, no-host-port boundary berlaku,
   dan Mailpit masih memiliki empat earlier messages.
2. Backup first corrected runtime configuration ke exact rollback file kedua.
3. Overwrite `alertmanager_config`, restart exact Alertmanager, dan verifikasi
   readiness, semantic config, checksum, ID, port, serta evidence retention.

```bash
podman cp alertmanager:/etc/alertmanager/alertmanager.yml \
  /tmp/tm-tn035-alertmanager-body-v1-rollback.yml
chmod 0600 /tmp/tm-tn035-alertmanager-body-v1-rollback.yml
./scripts/initialize-alertmanager-volumes.sh
podman restart alertmanager
podman exec alertmanager /bin/sh -c \
  'wget -qO- http://127.0.0.1:9093/-/ready'
podman exec alertmanager amtool check-config \
  /etc/alertmanager/alertmanager.yml
```

!!! success "Expected Result"

    Visual-corrected configuration aktif pada exact persistent Alertmanager;
    earlier messages, data volume, container identity, dan port boundary tidak
    berubah.

**Actual Result:** prior revision checksum `9c6c5350…` dipertahankan pada
`/tmp/tm-tn035-alertmanager-body-v1-rollback.yml`; active source/runtime
checksum menjadi `a6e44ba5…`. Alertmanager ID `ff2d4b2f…` tetap running dan
ready dengan `{"9093/tcp":null}`; Mailpit tetap memiliki empat messages sebelum
visual revalidation.

**Evidence:** `amtool` menghasilkan `SUCCESS`, initializer absent setelah
deployment, dan `alertmanager_data` tidak diganti.

</div>

<div class="procedure-step" markdown>

### Verify Persistent Red and Green Notification Pair

1. Stop exact Telegraf dengan recovery guard dan pertahankan state `exited`
   sampai rule firing.
2. Tunggu firing message kelima, lalu start kembali Telegraf.
3. Tunggu scrape `up=1`, rule inactive, dan resolved message keenam.
4. Periksa full HTML dua messages terbaru untuk status colors, conditional
   content, alert fields, stale-description absence, dan inaccessible-link
   absence.
5. Audit final targets, rules, container states, runtime checksum, port
   boundary, dan temporary-resource absence.

```bash
podman stop telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error \
  http://127.0.0.1:8025/api/v1/messages
podman start telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22telegraf-health%22%7D'
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/targets?state=active'
```

!!! success "Expected Result"

    Message kelima memiliki red firing visual dan active description; message
    keenam memiliki green resolved visual serta recovery message tanpa stale
    firing description; monitoring baseline pulih.

**Actual Result:** Telegraf tetap `exited` selama pending, rule mencapai firing,
message kelima diterima, Telegraf dipulihkan, scrape kembali `up=1`, rule
inactive, dan resolved message keenam diterima setelah group interval.

**Evidence:** message `48qTLY3XaYk8NcDXLwpORP` (firing) dan
`3hIN8Z2K7qQn7xkcnA7V8O` (resolved) lulus exact persistent HTML assertions.
Output memuat `persistent_status_color_rendering=passed`,
`persistent_resolved_stale_description=absent`,
`persistent_inaccessible_alertmanager_link=absent`, two targets `up`, three
rules `inactive`, all persistent containers running, `mailpit_total=6`, dan
`alertmanager_host_port=false`.

Project owner kemudian menolak pasangan ini sebagai acceptance evidence:
resolved presentation masih memakai negative name
`TelegrafHealthScrapeUnavailable` dan severity `warning`, sehingga subject dan
body tidak menyatakan kondisi normal secara konsisten.

</div>

<div class="procedure-step" markdown>

### Define Unified Operator Alert-template Contract

1. Pisahkan internal Alertmanager lifecycle dari operator-facing status tanpa
   mengubah internal `alertname` yang dipakai grouping dan correlation.
2. Tetapkan operator severity `critical` untuk firing scrape-down dan `normal`
   untuk resolved notification.
3. Map resolved presentation menjadi positive name:
   `TelegrafHealthScrapeAvailable`,
   `TomcatApplicationHealthMetricsAvailable`, atau
   `TomcatApplicationHealthNormal` sesuai internal alert.
4. Gunakan satu subject format:
   `[Tomcat Monitoring][<normal|warning|critical>]
   <presentation-alert-name> - <instance>`.
5. Gunakan body keys yang identik untuk seluruh states: `Alert name`,
   `Instance`, `Job`, `Severity`, `Service`, `Check`, dan `Description`; hanya
   values yang berubah mengikuti kondisi.
6. Pertahankan green `#2e7d32`, orange `#ef6c00`, dan red `#c62828` sebagai
   normal, warning, dan critical visual contract.
7. Lengkapi Prometheus labels `service` dan `check`, ubah Telegraf scrape-down
   rule menjadi `critical`, serta selaraskan rule tests dan validators.
8. Dokumentasikan kontrak pada Alertmanager README, Prometheus README,
   Architecture, Infrastructure, dan TN-035.

!!! success "Expected Result"

    Subject dan body menyampaikan semantic status yang sama; normal email tidak
    memuat negative alert name, warning/critical severity, atau stale failure
    description; critical dan normal memakai body key layout yang identik.

**Actual Result:** source candidate menerapkan unified subject/body mapping,
positive resolved names, complete labels, identical body keys, dan three-color
contract. Internal rule name tetap stabil untuk Alertmanager correlation.

**Evidence:** contract tersedia pada source-facing README dan current-state
Architecture/Infrastructure; exact static assertions ditambahkan untuk subject,
name mapping, severity, color, labels, descriptions, key layout, dan absence of
inaccessible Alertmanager link.

</div>

<div class="procedure-step" markdown>

### Validate Unified Alert-template Candidate

1. Jalankan syntax validation untuk seluruh scripts.
2. Jalankan Alertmanager, Prometheus, dan aggregate static validators.
3. Periksa whitespace errors pada source diff.
4. Jalankan disposable Alertmanager-Mailpit test untuk semantic config, exact
   subject/body render, warna, stale-content absence, dan cleanup audit.
5. Jalankan disposable Prometheus `promtool` config, rule, dan rule-fixture
   tests.
6. Pisahkan hasil disposable dari persistent runtime claims; jangan menyatakan
   candidate deployed sebelum exact runtime promotion benar-benar dilakukan.

```bash
bash -n scripts/*.sh
./scripts/validate-alertmanager.sh
./scripts/validate-prometheus.sh
./scripts/validate.sh
git diff --check
./scripts/verify-alertmanager-mailpit.sh
podman run --rm --pull=never \
  --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro \
  --workdir /etc/prometheus localhost/prometheus:1.0.0 /bin/sh -c \
  '/bin/promtool check rules rules/application-health.yml &&
   /bin/promtool check config prometheus.yml &&
   /bin/promtool test rules tests/application-health.test.yml'
```

!!! success "Expected Result"

    Static contract, semantic Alertmanager rendering, dan Prometheus rule tests
    lulus; persistent deployment dan real-rule email pair tetap dicatat
    terpisah sesuai evidence yang benar-benar dijalankan.

**Actual Result:** seluruh syntax/static validators, disposable
Alertmanager-Mailpit rendering, combined `promtool` checks, dan
`git diff --check` lulus. Source candidate belum dipromosikan ke persistent
runtime.

**Evidence:** output memuat `semantic_config=passed`,
`operator_status_subjects=critical,normal`, `unified_key_layout=passed`,
`status_color_rendering=passed`, `resolved_stale_description=absent`, dan
`cleanup_result=passed`; `promtool` menemukan tiga rules serta menyatakan config
dan rule tests `SUCCESS`. Active runtime tetap pada rejected visual-corrected
revision dan Mailpit tetap memiliki six historical messages.

</div>

<div class="procedure-step" markdown>

### Deploy Unified Alert-template to Persistent Runtime

1. Inspect exact `alertmanager`, `prometheus`, `mailpit`, dan `telegraf`
   identities, states, mounts, ports, serta six-message Mailpit baseline.
2. Backup active Alertmanager configuration dan Prometheus rule ke exact
   rollback files baru tanpa menimpa earlier backups.
3. Isi `alertmanager_config` melalui accepted initializer.
4. Isi hanya `prometheus_config` melalui exact temporary updater; jangan mount
   atau ubah `prometheus_data` dan `prometheus_truststore`.
5. Jalankan `amtool` dan `promtool` terhadap mounted files, lalu cocokkan source
   dan mounted checksums.
6. Restart exact `alertmanager` dan `prometheus`, kemudian verifikasi readiness,
   container identity, port boundary, targets, rules, serta updater absence.

```bash
podman cp alertmanager:/etc/alertmanager/alertmanager.yml \
  /tmp/tm-tn035-alertmanager-unified-rollback.yml
podman cp prometheus:/etc/prometheus/rules/application-health.yml \
  /tmp/tm-tn035-prometheus-unified-rule-rollback.yml
chmod 0600 /tmp/tm-tn035-alertmanager-unified-rollback.yml \
  /tmp/tm-tn035-prometheus-unified-rule-rollback.yml
./scripts/initialize-alertmanager-volumes.sh
podman create --name prometheus-config-update-tn035 --user 0 \
  --entrypoint /bin/sh --volume prometheus_config:/staging/config \
  localhost/prometheus:1.0.0 \
  -c 'chmod 0755 /staging/config /staging/config/rules;
      chmod 0444 /staging/config/prometheus.yml
        /staging/config/rules/application-health.yml'
podman cp config/prometheus/prometheus.yml \
  prometheus-config-update-tn035:/staging/config/prometheus.yml
podman cp config/prometheus/rules/application-health.yml \
  prometheus-config-update-tn035:/staging/config/rules/application-health.yml
podman start --attach prometheus-config-update-tn035
podman rm prometheus-config-update-tn035
podman exec alertmanager amtool check-config \
  /etc/alertmanager/alertmanager.yml
podman exec prometheus /bin/promtool check config \
  /etc/prometheus/prometheus.yml
podman exec prometheus /bin/promtool check rules \
  /etc/prometheus/rules/application-health.yml
podman restart alertmanager prometheus
```

!!! success "Expected Result"

    Verified source aktif pada exact persistent config volumes; semantic checks,
    readiness, identity, dan port contract lulus; data/truststore volumes serta
    six historical messages tidak berubah.

**Actual Result:** Alertmanager dan Prometheus semantic checks lulus sebelum
restart. Source dan mounted checksums sama: Alertmanager `be333a8c…`, Prometheus
main config `79e08fbe…`, dan rule `472ca3a3…`. Exact container IDs tetap
`ff2d4b2f…` dan `897f4ec3…`; Alertmanager tetap tidak memiliki host port.
Temporary updater absent dan baseline pulih ke two targets `up`, three rules
`inactive/ok`, health result `0`, serta six Mailpit messages.

**Evidence:** rollback checksums `a6e44ba5…` dan `492c6a26…` tersedia pada
`/tmp/tm-tn035-alertmanager-unified-rollback.yml` dan
`/tmp/tm-tn035-prometheus-unified-rule-rollback.yml`. Prometheus data dan
truststore volumes tidak dipasang pada updater.

</div>

<div class="procedure-step" markdown>

### Verify Persistent Unified Critical and Normal Pair

1. Stop exact `telegraf` dari verified six-message baseline.
2. Pertahankan Telegraf stopped sampai scrape down dan
   `TelegrafHealthScrapeUnavailable` mencapai `firing` dengan severity
   `critical`.
3. Pastikan critical message ketujuh diterima sebelum start kembali Telegraf.
4. Start exact `telegraf`, lalu tunggu target `up`, seluruh rules
   `inactive/ok`, dan normal message kedelapan setelah accepted group interval.
5. Ambil full HTML dua exact message terbaru dan periksa subject, identical body
   keys, status-specific values, colors, stale-content absence, dan
   inaccessible-link absence.
6. Audit final checksums, container identities/states, ports, targets, dan
   rules.

```bash
podman stop telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/rules?type=alert'
curl --fail --silent --show-error \
  http://127.0.0.1:8025/api/v1/messages
podman start telegraf
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/targets?state=active'
curl --fail --silent --show-error \
  'http://127.0.0.1:9090/api/v1/rules?type=alert'
```

!!! success "Expected Result"

    Critical email memakai negative failure name, severity critical, dan red
    banner; normal email memakai positive recovery name, severity normal, dan
    green banner. Kedua body memakai exact key layout yang sama dan baseline
    pulih sepenuhnya.

**Actual Result:** rule berpindah `inactive` → `pending` → `firing`; message
ketujuh diterima, Telegraf dipulihkan, target kembali `up`, seluruh rules
`inactive/ok`, dan message kedelapan diterima. Full HTML assertions lulus.

**Evidence:** critical message `2V6shq4dGekDSAOt2iXOZI` dibuat
`2026-08-28T10:04:32.436Z`; normal message `2IfpN1RgUUkx8JMwe9RxhX`
dibuat `2026-08-28T10:09:32.437Z`. Output memuat
`persistent_unified_html=passed`, `persistent_key_layout=identical`,
`persistent_colors=critical-red,normal-green`, dan
`persistent_inaccessible_alertmanager_link=absent`. Empat persistent containers
running, two targets `up`, three rules `inactive/ok`, dan Mailpit total `8`.

### Implement Enterprise SRE and Incident Operations Alert-template (Option 1)

1. Perbarui format subject menjadi format Enterprise SRE:
   `[<RESOLVED|CRITICAL|WARNING>] [LAB] Tomcat Service: <presentation-alert-name> (Instance: <instance>)`.
2. Susun HTML body dengan desain modern card (max-width 640px) berlatar `#f4f6f9`
   dan card `#ffffff` dengan rounded corners serta border halus.
3. Buat Header Banner berlatar merah `#c62828` (`[ CRITICAL ] Tomcat Monitoring Alert`),
   oranye `#ef6c00` (`[ WARNING ]`), atau hijau `#2e7d32` (`[ RESOLVED ] Service Restored`)
   dengan badge `LAB Environment`.
4. Buat Summary Box terpisah (`⚠️ Alert Summary` atau `✅ Recovery Summary`) dengan
   aksen border warna status.
5. Buat grid Technical Details rapi yang memuat `Alert Name`, `Service / Check`,
   `Target Instance`, `Severity`, dan `Status`.
6. Buat section Impact & Recommended Actions yang memberikan panduan dampak dan
   langkah penanganan konkret bagi operator on-call.
7. Pertahankan footer metadata otomatis dan ketiadaan link internal yang tidak
   dapat diakses operator.
8. Perbarui static validator `validate-alertmanager.sh`, disposable test
   `verify-alertmanager-mailpit.sh`, dan Alertmanager README.

!!! success "Expected Result"

    Source template mengadopsi standar Enterprise SRE (Option 1) dengan struktur
    card modern, ringkasan insiden/pemulihan, detail teknis, dan panduan mitigasi.

**Actual Result:** template `config/alertmanager/alertmanager.yml`, script
validator, script verifikasi disposable, dan README telah diperbarui dan
lulus seluruh validasi statis.

**Evidence:** source diff `config/alertmanager/alertmanager.yml`,
`scripts/validate-alertmanager.sh`, `scripts/verify-alertmanager-mailpit.sh`, dan
`config/alertmanager/README.md`.

</div>

<div class="procedure-step" markdown>

### Validate Enterprise SRE Alert-template Candidate

1. Jalankan syntax validation seluruh scripts: `bash -n scripts/*.sh`.
2. Jalankan Alertmanager static validator: `./scripts/validate-alertmanager.sh`.
3. Jalankan aggregate validator: `./scripts/validate.sh`.
4. Jalankan check-config semantik: `podman run --rm localhost/alertmanager:1.0.0 check-config /etc/alertmanager/alertmanager.yml`.
5. Jalankan verifikasi disposable Alertmanager–Mailpit: `./scripts/verify-alertmanager-mailpit.sh`.
6. Periksa whitespace diff: `git diff --check`.

```bash
bash -n scripts/*.sh
./scripts/validate-alertmanager.sh
./scripts/validate.sh
podman run --rm --pull=never \
  --volume /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager:/etc/alertmanager:ro \
  --entrypoint /bin/amtool localhost/alertmanager:1.0.0 check-config /etc/alertmanager/alertmanager.yml
./scripts/verify-alertmanager-mailpit.sh
git diff --check
```

!!! success "Expected Result"

    Seluruh validasi statis, semantik `amtool`, dan disposable Mailpit capture
    lulus dengan exit `0` serta membersihkan container sementara.

**Actual Result:** `validate-alertmanager.sh`, `validate.sh`, `amtool`, dan
`verify-alertmanager-mailpit.sh` lulus. Output disposable memuat
`subjects_validation=passed`, `status_specific_body=passed`,
`status_color_rendering=passed`, `resolved_stale_description=absent`,
`unified_key_layout=passed`, dan `cleanup_result=passed`.

**Evidence:** disposable test berjalan pada task ID terisolasi dan membersihkan
kontainer `tm-tn033-mailpit` dan `tm-tn033-alertmanager` tanpa sisa.

</div>

<div class="procedure-step" markdown>

### Deploy Enterprise SRE Alert-template to Persistent Runtime

1. Backup active runtime configuration ke `/tmp/tm-tn035-alertmanager-enterprise-rollback.yml`.
2. Inisialisasi volume `alertmanager_config` melalui `./scripts/initialize-alertmanager-volumes.sh`.
3. Jalankan `amtool check-config` terhadap mounted file.
4. Restart persistent container `alertmanager`.
5. Verifikasi readiness `http://127.0.0.1:9093/-/ready` dan kesesuaian checksum.

```bash
podman cp alertmanager:/etc/alertmanager/alertmanager.yml \
  /tmp/tm-tn035-alertmanager-enterprise-rollback.yml
chmod 0600 /tmp/tm-tn035-alertmanager-enterprise-rollback.yml
./scripts/initialize-alertmanager-volumes.sh
podman exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
podman restart alertmanager
podman exec alertmanager wget -qO- http://127.0.0.1:9093/-/ready
podman exec alertmanager sha256sum /etc/alertmanager/alertmanager.yml
```

!!! success "Expected Result"

    Persistent Alertmanager ready dengan source/runtime checksum cocok
    (`6b93a5e1…`) tanpa mengubah data volume atau host port boundary.

**Actual Result:** configuration volume terisi, `amtool` melaporkan `SUCCESS`,
Alertmanager kembali ready (`OK`), dan checksum source/runtime identik.

**Evidence:** backup tersimpan di `/tmp/tm-tn035-alertmanager-enterprise-rollback.yml`
dengan permission `0600`.

</div>

<div class="procedure-step" markdown>

### Verify Persistent Enterprise SRE Critical and Resolved Pair

1. Hentikan container `telegraf` untuk memicu alert `TelegrafHealthScrapeUnavailable`.
2. Tunggu hingga rule mencapai status `firing`.
3. Verifikasi pesan critical baru (message ke-9) diterima di Mailpit.
4. Start kembali container `telegraf`.
5. Tunggu hingga target scrape kembali `up=1` dan rule menjadi `inactive`.
6. Tunggu hingga pesan resolved baru (message ke-10) diterima di Mailpit.
7. Ambil full HTML kedua pesan dan verifikasi subjek, banner status, summary box,
   technical details, impact & recommended actions, dan footer metadata.

```bash
podman stop telegraf
# Poll Prometheus rules and Mailpit messages API until firing message received
podman start telegraf
# Poll Prometheus scrape up=1 and Mailpit messages API until resolved message received
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/messages
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/message/5PfV1BUj3qVXGg6iyVCc8f
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/message/1thrY0Vplr9vcxqaLQp8yW
```

!!! success "Expected Result"

    Mailpit menerima pesan critical ke-9 `5PfV1BUj3qVXGg6iyVCc8f` dan pesan
    resolved ke-10 `1thrY0Vplr9vcxqaLQp8yW` dengan layout Enterprise SRE Option 1
    lengkap; baseline monitoring pulih sepenuhnya.

**Actual Result:** siklus gangguan dan pemulihan berjalan mulus. Rule berpindah
`inactive` → `pending` → `firing` → `inactive`. Pesan ke-9 dan ke-10 diterima
dengan subject format `[CRITICAL] [LAB] Tomcat Service: ...` dan `[RESOLVED]
[LAB] Tomcat Service: ...` serta layout body card lengkap.

**Evidence:** persistent message ID `5PfV1BUj3qVXGg6iyVCc8f` (critical, dibuat
`2026-08-28T11:18:32.436Z`) dan `1thrY0Vplr9vcxqaLQp8yW` (resolved, dibuat
`2026-08-28T11:23:32.437Z`). Keduanya lulus audit full HTML layout.

</div>

</div>

## 🖥️ Commands Executed

Seluruh command aktual ditempatkan pada procedure step tempat command tersebut
dijalankan. Section ini menjadi indeks chronology agar command tidak terpisah
dari purpose, expected result, actual result, dan evidence.

| Order | Procedure Step | Command Scope |
| --- | --- | --- |
| 1 | [Review Governance and Source Contracts](#review-governance-and-source-contracts) | Standards, Git state, source contracts, dan lifecycle scripts |
| 2 | [Inspect Exact Runtime Preflight State](#inspect-exact-runtime-preflight-state) | Failed sandbox attempt, approved runtime inventory, APIs, dan checksums |
| 3 | [Apply and Validate Source Interfaces](#apply-and-validate-source-interfaces) | Source changes, shell/static validation, `amtool`, dan `promtool` |
| 4 | [Create Persistent Alertmanager and Mailpit](#create-persistent-alertmanager-and-mailpit) | Volume initialization, container creation, readiness, dan restart |
| 5 | [Retain Rollback and Replace Prometheus](#retain-rollback-and-replace-prometheus) | Snapshot, cutover, failed assertion, dan corrected continuity check |
| 6 | [Verify Real Firing and Resolved Delivery](#verify-real-firing-and-resolved-delivery) | Guarded Telegraf interruption, polling, recovery, dan message capture |
| 7 | [Verify Final Persistent State](#verify-final-persistent-state) | Runtime, persistence, cleanup-boundary, dan listener audit |
| 8 | [Consolidate and Review Documentation](#consolidate-and-review-documentation) | Source/docs validation, navigation, stale-state, dan render availability |
| Handoff | [Operator Validation](#operator-validation) | Read-only access, visual message review, dan acceptance criteria |
| Correction source | [Implement Status-specific Notification Body](#implement-status-specific-notification-body) | Status-specific HTML, inaccessible-link removal, validator, fixture, dan documentation |
| Correction test | [Validate Corrected Firing and Resolved Rendering](#validate-corrected-firing-and-resolved-rendering) | Failed fixture assertions, final isolated regression, dan cleanup audit |
| Correction deploy | [Deploy Corrected Persistent Configuration](#deploy-corrected-persistent-configuration) | Exact preflight, backup, volume overwrite, restart, checksum, readiness, dan port audit |
| Correction runtime | [Repeat Real-rule Delivery and Verify Corrected HTML](#repeat-real-rule-delivery-and-verify-corrected-html) | Guarded Telegraf cycle, polling, HTML assertions, recovery, dan final state audit |
| Visual correction | [Refine Visual and Resolved-content Contract](#refine-visual-and-resolved-content-contract) | Red/green email card, conditional content, dan stricter HTML assertions |
| Visual deploy | [Deploy Visual-corrected Alertmanager Revision](#deploy-visual-corrected-alertmanager-revision) | Second backup, volume overwrite, restart, semantic validation, dan evidence retention |
| Visual runtime | [Verify Persistent Red and Green Notification Pair](#verify-persistent-red-and-green-notification-pair) | Guarded real-rule cycle, color/content assertions, recovery, dan final audit |
| Unified contract | [Define Unified Operator Alert-template Contract](#define-unified-operator-alert-template-contract) | Normal/warning/critical semantics, positive resolved names, identical keys, labels, dan documentation |
| Unified static validation | [Validate Unified Alert-template Candidate](#validate-unified-alert-template-candidate) | Syntax, component validators, aggregate validator, diff check, dan evidence boundary |
| Unified deployment | [Deploy Unified Alert-template to Persistent Runtime](#deploy-unified-alert-template-to-persistent-runtime) | Exact preflight, backups, config-only volume updates, semantic checks, restart, dan baseline recovery |
| Unified runtime | [Verify Persistent Unified Critical and Normal Pair](#verify-persistent-unified-critical-and-normal-pair) | Controlled Telegraf cycle, critical/normal delivery, exact HTML assertions, dan final state audit |
| Enterprise contract | [Implement Enterprise SRE and Incident Operations Alert-template (Option 1)](#implement-enterprise-sre-and-incident-operations-alert-template-option-1) | Modern card HTML, Enterprise SRE subjects, Summary Box, Tech Details, Impact/Actions |
| Enterprise validation | [Validate Enterprise SRE Alert-template Candidate](#validate-enterprise-sre-alert-template-candidate) | Syntax checks, component/aggregate validators, `amtool`, and disposable Mailpit verification |
| Enterprise deploy | [Deploy Enterprise SRE Alert-template to Persistent Runtime](#deploy-enterprise-sre-alert-template-to-persistent-runtime) | Exact backup, volume update, `amtool`, container restart, checksum, and readiness check |
| Enterprise runtime | [Verify Persistent Enterprise SRE Critical and Resolved Pair](#verify-persistent-enterprise-sre-critical-and-resolved-pair) | Controlled Telegraf cycle, firing & resolved live capture, full HTML audit (messages 9 & 10) |
| Enterprise operator acceptance | [Record the Operator Decision](#record-the-operator-decision) | Failed sandbox query, approved read-only host query, exact-message retrieval, browser screenshots, and project-owner acceptance |
| Rollback retirement | [Retire Accepted Rollback State](#retire-accepted-rollback-state) | Exact identity gates, stopped container removal, named-volume removal, five rollback-file removals, and active runtime audit |
| Source-control handoff | [Source-Control Handoff](#source-control-handoff) | Failed sandbox staging attempt, approved staging review, local source commit, and no push |

## 🧾 Outcome

Implementation dan mandatory runtime verification selesai. Persistent
Prometheus–Alertmanager–Mailpit flow membuktikan real application-health
firing/resolved email tanpa credential atau external delivery. Baseline
Telegraf, JMX, rules, health metric, active Alertmanager, dan historical data
availability pulih serta lulus final audit.

Template notifikasi email Alertmanager telah disempurnakan ke format
**Enterprise SRE & Incident Operations Style (Option 1)**:

- Subjek berstandar enterprise:
  `[CRITICAL] [LAB] Tomcat Service: TelegrafHealthScrapeUnavailable (Instance: telegraf:9273)`
  dan
  `[RESOLVED] [LAB] Tomcat Service: TelegrafHealthScrapeAvailable (Instance: telegraf:9273)`.
- Body berformat responsive card modern dengan header banner status dan badge
  `LAB Environment`.
- Memuat kotak ringkasan insiden/pemulihan (*Alert/Recovery Summary*), tabel
  rincian teknis (*Technical Details*), panduan dampak dan tindakan mitigasi
  (*Impact & Recommended Actions*), serta footer otomatis.

Static validation, `amtool check-config`, dan disposable test
`verify-alertmanager-mailpit.sh` lulus. Deployment ke persistent runtime dan live
cycle menghasilkan pasangan pesan ke-9 (`5PfV1BUj3qVXGg6iyVCc8f`) dan ke-10
(`1thrY0Vplr9vcxqaLQp8yW`) yang lulus full layout audit.
Project owner kemudian menerima exact Enterprise SRE critical/resolved pair
tersebut melalui Operator Validation pada 2026-08-28.
Setelah exact authorization diberikan, retained TN-035 rollback container,
protected rollback volume, dan lima rollback files dihapus. Active monitoring
containers, persistent volumes, readiness, serta Mailpit evidence tetap utuh.

Source dan documentation diff review lulus tanpa whitespace error. Navigation
serta relative links tersedia dan current-state pages telah dikonsolidasikan.
MkDocs render berstatus `Not verified` karena executable tidak tersedia;
dependency tidak dipasang.

## ⏭️ Next Steps

Restart policy serta host-boot orchestration tetap menjadi deferred operability
decision. External delivery membutuhkan contract dan authorization terpisah.

## 🔄 Source-Control Handoff

Project owner mengotorisasi commit lokal setelah accepted rollback cleanup pada
2026-08-28. Authorization mencakup exact four-file source diff pada repository
`tomcat-monitoring` dan documentation closure diff pada `devops-handbook`;
push tidak termasuk.

Initial staging attempt gagal karena sandbox tidak dapat membuat
`.git/index.lock`. Approved host retry kemudian mereview staged scope dan
membuat source commit berikut:

```bash
# Initial sandbox-local attempt; failed at git add
git add -- config/alertmanager/README.md config/alertmanager/alertmanager.yml \
  scripts/validate-alertmanager.sh scripts/verify-alertmanager-mailpit.sh
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git commit -m "feat: add enterprise alert notification template"
git rev-parse --short=12 HEAD
git status --short --branch

# Approved host retry; /home/eddywiyatno/git/tomcat-monitoring
git add -- config/alertmanager/README.md config/alertmanager/alertmanager.yml \
  scripts/validate-alertmanager.sh scripts/verify-alertmanager-mailpit.sh
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git commit -m "feat: add enterprise alert notification template"
git rev-parse --short=12 HEAD
git status --short --branch
```

**Actual Result:** staged scope berisi hanya empat accepted Alertmanager
template, documentation, validator, dan disposable-verification files.
`git diff --cached --check` lulus dan local commit
`3e196f7ba2e1` (`feat: add enterprise alert notification template`) berhasil
dibuat. Repository `tomcat-monitoring` bersih dan `ahead 1`; push belum
dijalankan.

Documentation closure menggunakan exact two-file scope berikut sebagai tindakan
terakhir sesi:

```bash
# /home/eddywiyatno/git/devops-handbook
git diff --check
git add -- \
  docs/projects/tomcat-monitoring/architecture/index.md \
  docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git commit -m "docs(tomcat-monitoring): close enterprise alert validation"
git rev-parse --short=12 HEAD
git status --short --branch
```

Documentation commit identity dilaporkan pada session handoff karena commit
tidak dapat mencatat hash dirinya sendiri tanpa membuat follow-up commit. Push
tetap menjadi tindakan manual operator.

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah initial firing dan resolved email evidence diterima project owner? | Answered — Rejected on 2026-08-28 | Project owner | Resolved body masih menyajikan static firing description sebagai current message dan Alertmanager link memakai inaccessible internal hostname; source correction disetujui. | Initial evidence tidak dapat digunakan untuk acceptance. |
| Apakah first corrected persistent evidence diterima project owner? | Answered — Rejected on 2026-08-28 | Project owner | Resolved body masih memuat firing-condition context dan red/green visual status hilang; visual correction disetujui. | Intermediate evidence tidak dapat digunakan untuk acceptance. |
| Apakah visual-corrected persistent firing dan resolved evidence diterima project owner? | Answered — Rejected on 2026-08-28 | Project owner | Normal message masih memakai `TelegrafHealthScrapeUnavailable` dan severity `warning`; unified contract correction disetujui. | Visual-corrected evidence tidak dapat digunakan untuk acceptance. |
| Apakah unified critical dan normal notification evidence diterima project owner? | Answered — Rejected on 2026-08-28 | Project owner | Layout tabel polos dan format judul dianggap belum memenuhi standar penggunaan enterprise; perbaikan ke Enterprise SRE Option 1 disetujui. | Unified evidence tidak dapat digunakan untuk acceptance. |
| Apakah Enterprise SRE critical dan resolved notification evidence (Option 1) diterima project owner? | Answered — Accepted on 2026-08-28 | Project owner | Exact messages `5PfV1BUj3qVXGg6iyVCc8f` dan `1thrY0Vplr9vcxqaLQp8yW` tersedia, cocok dengan contract, dan diterima setelah visual review. | Tidak ada; operator acceptance selesai. |
| Kapan retained original Prometheus dan protected configuration snapshots boleh dibersihkan? | Answered — Authorized and completed on 2026-08-28 | Project owner | Setelah Operator Validation diterima, exact stopped container, named volume, dan lima rollback files diotorisasi serta terbukti absent; active runtime dan volumes tetap sehat. | Tidak ada; retained TN-035 rollback cleanup selesai. |
| Apakah restart policy atau host-boot orchestration diperlukan? | Deferred | Project owner | Availability expectation dan orchestration owner ditetapkan. | Future operability work only. |

## 🔗 Related Documentation

- [TN-034 — Define Persistent Alertmanager and Prometheus Delivery Integration Contract](TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Tomcat Monitoring](../../index.md)

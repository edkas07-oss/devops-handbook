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

## ✅ Operator Validation

Technical objective TN-035 berstatus `Completed`, tetapi project-owner review
terhadap captured email belum dicatat. Validation ini tidak mengubah runtime
dan harus diselesaikan sebelum stability acceptance atau rollback-state cleanup
diberikan.

| Item | Value |
| --- | --- |
| State | Ready for operator validation |
| Owner | Project owner |
| Validation target | Satu firing dan satu resolved email untuk `TelegrafHealthScrapeUnavailable` |
| Access boundary | Mailpit API/UI hanya tersedia pada host loopback `127.0.0.1:8025` |
| Evidence retention | Mailpit tidak memakai named volume; review harus dilakukan sebelum container replacement |
| Closure record | Project owner menyatakan `Accepted` atau `Rejected` beserta finding |

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Confirm Mailpit Evidence Availability

Pastikan Mailpit masih ready dan kedua captured messages belum hilang sebelum
membuka UI.

1. Jalankan readiness dan message-list query pada `edkas-pc1`.
2. Pastikan API dapat diakses dan `total` bernilai `2`.
3. Pastikan daftar memuat satu subject `firing` dan satu subject `resolved`.

```bash
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/info \
  | python3 -m json.tool
curl --fail --silent --show-error http://127.0.0.1:8025/api/v1/messages \
  | python3 -m json.tool
```

!!! success "Expected Result"

    Mailpit API merespons, message total bernilai `2`, dan firing serta resolved
    subjects tersedia untuk direview.

Readiness check pada 2026-08-28 menemukan Mailpit `v1.31.0` running dan kedua
subjects berikut masih tersedia:

```text
[Tomcat Monitoring][firing] TelegrafHealthScrapeUnavailable - telegraf:9273
[Tomcat Monitoring][resolved] TelegrafHealthScrapeUnavailable - telegraf:9273
```

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

    Mailpit inbox tampil dan memperlihatkan satu firing serta satu resolved
    message tanpa mengubah network atau container configuration.

</div>

<div class="procedure-step" markdown>

### Inspect Firing and Resolved Messages

Review kedua message secara terpisah agar state transition dan receiver
contract dapat diterima oleh project owner.

1. Buka message dengan subject `[Tomcat Monitoring][firing]
   TelegrafHealthScrapeUnavailable - telegraf:9273`.
2. Buka message dengan subject `[Tomcat Monitoring][resolved]
   TelegrafHealthScrapeUnavailable - telegraf:9273`.
3. Pada kedua message, cocokkan field berikut:

    | Field | Expected Value |
    | --- | --- |
    | From | `alertmanager@tomcat-monitoring.invalid` |
    | To | `operator@tomcat-monitoring.invalid` |
    | Alert name | `TelegrafHealthScrapeUnavailable` |
    | Instance | `telegraf:9273` |
    | Job | `telegraf-health` |
    | Severity | `warning` |

4. Pastikan message pertama menyatakan `Firing` dan message kedua menyatakan
   `Resolved`.
5. Pastikan description menjelaskan Prometheus tidak dapat scrape target
   Telegraf dan application health menjadi unknown.

!!! success "Expected Result"

    Project owner dapat membuktikan melalui UI bahwa kedua email memiliki
    identity, labels, description, dan firing/resolved transition yang sesuai
    contract TN-035.

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

Project owner memeriksa firing dan resolved email melalui Operator Validation,
lalu mencatat acceptance atau finding. Setelah validation diterima, project
owner menilai stability window sebelum memberi exact destructive authorization
untuk `prometheus-tn035-rollback` dan
`prometheus_config_tn035_rollback`. Restart policy serta host-boot
orchestration tetap menjadi deferred operability decision; external delivery
membutuhkan contract dan authorization terpisah.

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah firing dan resolved email evidence diterima project owner? | Open | Project owner | Operator Validation selesai dan hasil dicatat sebagai `Accepted`, atau finding dicatat sebagai `Rejected`. | Stability acceptance dan cleanup authorization. |
| Kapan retained original Prometheus dan protected configuration snapshot boleh dibersihkan? | Open | Project owner | Operator Validation accepted, stability diterima, dan exact destructive cleanup diotorisasi terpisah. | Cleanup retained rollback state only. |
| Apakah restart policy atau host-boot orchestration diperlukan? | Deferred | Project owner | Availability expectation dan orchestration owner ditetapkan. | Future operability work only. |

## 🔗 Related Documentation

- [TN-034 — Define Persistent Alertmanager and Prometheus Delivery Integration Contract](TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Tomcat Monitoring](../../index.md)

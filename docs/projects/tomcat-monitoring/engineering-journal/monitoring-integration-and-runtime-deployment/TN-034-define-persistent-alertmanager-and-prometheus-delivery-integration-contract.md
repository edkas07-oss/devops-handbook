# TN-034 — Define Persistent Alertmanager and Prometheus Delivery Integration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-27 |
| Recorded Date | 2026-08-27 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-27 |

## 🎯 Objective

Menghasilkan contract yang diterima untuk menerapkan persistent Alertmanager
dan memverifikasi firing serta resolved delivery dari persistent Prometheus
sampai Mailpit pada lab.

## 🌍 Background

TN-033 membuktikan Alertmanager email receiver menuju Mailpit melalui isolated
synthetic API v2 verification. Verification tersebut tidak membuktikan
persistent Alertmanager, Prometheus-to-Alertmanager delivery, atau notification
flow dari active Prometheus rules.

Project owner menyetujui documentation scope dan read-only assessment TN-034
pada 2026-08-27. Approval ini merupakan Documentation Gate. Persistent topology,
Mailpit lifecycle, runtime mutation, dan implementation authorization tetap
harus melewati Decision Gate serta Implementation Gate terpisah.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- menilai source contract, related Technical Notes, runtime repository, dan
  current persistent lab secara read-only;
- menentukan exact candidate topology, resource, storage, continuity,
  rollback, cleanup, dan verification boundary;
- membandingkan lifecycle Mailpit disposable dan persistent;
- mencatat recommendation dan Decision Handoff; serta
- memperbarui TN-034, phase index, dan navigation yang terkait langsung.

Source atau configuration change, image pull atau build, volume dan container
creation, runtime replacement atau stop/start, failure injection, cleanup,
commit, push, external delivery, Gmail, Integration Bridge, TrueSight, dan
secret tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| TN-025 | Alertmanager runtime dimiliki repository generik; integration repository memiliki configuration, volumes, Prometheus target, validation, dan orchestration. |
| TN-032 | Mailpit direct-upstream exception, immutable `v1.31.0` reference, dan no-volume lifecycle diterima hanya untuk disposable verification. Persistent use harus membuka ownership gate kembali. |
| TN-033 | Active source receiver menuju `mailpit:1025` dan isolated firing/resolved SMTP capture telah diverifikasi; persistent delivery belum dibuktikan. |
| Source repositories | Prometheus source mereferensikan `alertmanager:9093`; Alertmanager source menggunakan Mailpit internal dan generic runtime image tersedia sebagai `localhost/alertmanager:1.0.0`. |
| Persistent lab | Prometheus, Telegraf, dan Tomcat/JMX target berjalan pada `devops-lab`; Alertmanager serta Mailpit belum tersedia. |

## 🔍 Findings

### Verified facts

Read-only assessment pada 2026-08-27 menghasilkan fakta berikut:

| Concern | Observed State |
| --- | --- |
| Git state | `tomcat-monitoring`, `devops-handbook`, `prometheus`, dan `alertmanager` bersih serta sejajar dengan `origin/main`. |
| Existing topology | `prometheus`, `telegraf`, dan `tomcat-jmx-exporter` berjalan pada network `devops-lab`; Prometheus memublikasikan host port `9090`. |
| Persistent Prometheus storage | `prometheus_config`, `prometheus_truststore`, dan `prometheus_data` terpasang dengan mode yang telah diterima. |
| Active Prometheus configuration | Runtime memuat scrape dan alert rules, tetapi tidak memuat section `alerting`; API melaporkan `activeAlertmanagers: []`. |
| Source Prometheus configuration | Source sudah menetapkan API v2 target internal `alertmanager:9093`. |
| Alert rules | Tiga application-health rules aktif dan sehat; seluruhnya berada pada state `inactive` saat assessment. |
| Alertmanager image | Local `localhost/alertmanager:1.0.0` tersedia untuk `linux/amd64`; runtime source memin `quay.io/prometheus/alertmanager:v0.34.0`. |
| Candidate resources | Containers `alertmanager` dan `mailpit`, volumes `alertmanager_config`, `alertmanager_data`, serta `mailpit_data`, dan host ports `8025` serta `9093` tidak digunakan. |

Source/runtime gap berarti implementation tidak cukup dengan membuat
Alertmanager. TN-035 harus memasukkan controlled update terhadap
`prometheus_config` dan controlled Prometheus replacement karena active
Prometheus tidak dijalankan dengan HTTP lifecycle reload.

### Ownership and repository boundary

| Component | Proposed Ownership Contract |
| --- | --- |
| Alertmanager image | Generic `alertmanager` repository mempertahankan upstream pin, build, test, run, dan exact container cleanup interface. |
| Alertmanager integration | `tomcat-monitoring` memiliki `alertmanager.yml`, named-volume initialization, Prometheus delivery, persistent orchestration, and integration verification. |
| Mailpit image | Upstream `axllent/mailpit` tetap memiliki build dan release; accepted immutable TN-032 reference tetap digunakan. |
| Persistent Mailpit integration | `tomcat-monitoring` memiliki exact lab-only run contract, bounded host access, verification, and cleanup; tidak ada image build, retag, publication, atau production ownership. |

Penggunaan persistent Mailpit memperluas exception TN-032 yang sebelumnya
terbatas pada disposable verification. Perluasan tersebut merupakan Decision
Gate TN-034 dan tidak boleh dianggap accepted hanya dari approval dokumentasi.

### Proposed persistent topology

```text
Persistent Prometheus
  |-- API v2: alertmanager:9093 -------------------------.
  |                                                       |
  `-- evaluates application-health rules                  v
                                                  Persistent Alertmanager
                                                          |
                                                          | SMTP: mailpit:1025
                                                          v
                                                  Persistent lab Mailpit
                                                          |
                                                          `-- API/UI:
                                                              127.0.0.1:8025

All three monitoring components use network: devops-lab
Alertmanager port 9093 and Mailpit SMTP port 1025 remain internal.
```

| Resource | Proposed Exact Contract |
| --- | --- |
| Network | Existing `devops-lab`; tidak dibuat atau dihapus oleh TN-035. |
| Alertmanager container | `alertmanager`, image `localhost/alertmanager:1.0.0`, no host port. |
| Alertmanager configuration | Named volume `alertmanager_config`, mounted read-only at `/etc/alertmanager`. |
| Alertmanager data | Named volume `alertmanager_data`, mounted read-write at `/alertmanager`. |
| Mailpit container | `mailpit`, immutable TN-032 image reference, internal aliases from exact container name. |
| Mailpit SMTP | Internal `mailpit:1025`; never published to host. |
| Mailpit API/UI | Container `8025`, published only at `127.0.0.1:8025`. |
| Mailpit storage | No named volume; captured messages are lab verification state and may be lost on replacement. |
| Restart policy | Preserve the current lab convention: no automatic restart policy unless a separate operability decision accepts one. |
| Secret | None; sender and recipient remain synthetic `.invalid` identities. |

Persistent dalam contract ini berarti named containers dipertahankan setelah
successful verification. Ia tidak berarti automatic host-reboot recovery atau
production availability. Mailpit message history bukan source of truth;
Technical Note verification evidence tetap menjadi record hasil.

### Proposed implementation and rollback boundary

TN-035 harus menggunakan urutan berikut setelah implementation authorization:

1. Ulangi worktree, exact image, container, volume, network, port, active
   configuration, readiness, dan rule-state preflight.
2. Implementasikan source initializer serta validator untuk
   `alertmanager_config` dan `alertmanager_data`; jalankan shell, static,
   `amtool`, dan `promtool` checks sebelum runtime mutation.
3. Buat protected rollback snapshot untuk active Prometheus configuration dan
   pertahankan original Prometheus sebagai stopped rollback container selama
   verification.
4. Buat exact Alertmanager volumes, persistent Mailpit, dan persistent
   Alertmanager; buktikan readiness serta internal SMTP connectivity.
5. Perbarui `prometheus_config`, lakukan controlled Prometheus replacement
   dengan image, network, port, truststore, dan data volume yang sama, lalu
   buktikan `activeAlertmanagers` berisi target yang sehat.
6. Stop exact original Telegraf sementara untuk menghasilkan
   `TelegrafHealthScrapeUnavailable`, buktikan firing email, start kembali exact
   Telegraf, lalu buktikan resolved email dan baseline recovery.
7. Pertahankan successful persistent containers serta volumes. Cleanup hanya
   menargetkan temporary initializer dan failure resources; stopped rollback
   container serta snapshot dipertahankan sampai stability diterima dan exact
   destructive cleanup diotorisasi terpisah.

Jika cutover gagal, rollback harus menghentikan dan menghapus hanya replacement
Prometheus yang exact ID-nya cocok, memulihkan previous configuration, rename
serta start original Prometheus, start original Telegraf bila masih stopped,
dan memverifikasi scrape, rules, data continuity, serta ketiadaan active
Alertmanager target. Alertmanager dan Mailpit baru hanya boleh dihapus setelah
exact identity diperiksa dan cleanup diotorisasi; named volume tidak boleh
dihapus secara implisit.

### Verification boundary

| Criterion | Required Evidence | Does Not Prove |
| --- | --- | --- |
| Source and semantic readiness | Shell/static validation, `amtool check-config`, `promtool check config`, and exact image identity. | Persistent loading atau delivery. |
| Persistent components | Exact container/image/network/mount/port state, readiness, and Alertmanager data-volume continuity across controlled restart. | Production HA atau host-reboot recovery. |
| Prometheus delivery | Prometheus API reports healthy active Alertmanager and a real application-health rule reaches Alertmanager. | External inbox atau event-management delivery. |
| Notification flow | Mailpit captures matching firing and resolved email with stable labels and synthetic identities. | Gmail, Integration Bridge, TrueSight, or production notification SLO. |
| Recovery | Original Telegraf returns, alerts resolve, both scrape targets return `up=1`, baseline metrics remain available, and Prometheus TSDB uses the same data volume. | Full project end-to-end monitoring. |
| Cleanup | Temporary resources absent; persistent resources and retained rollback state match accepted boundary. | Authorization to delete retained containers, images, snapshots, or volumes. |

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Persistent Alertmanager with disposable Mailpit | Setelah test selesai, active receiver menunjuk target yang tidak tersedia dan menghasilkan retry/failure state. | Not recommended |
| Persistent Alertmanager without active receiver | Tidak konsisten dengan active source contract dan tidak membuktikan notification flow. | Rejected |
| Persistent Alertmanager and persistent lab Mailpit | Menjaga active receiver tersedia, membuktikan real Prometheus delivery, dan tetap menghindari credential serta external delivery. | Selected and accepted |
| Persistent Mailpit with named data volume | Mempertahankan message history tetapi menambah backup, cleanup, dan storage ownership yang tidak diperlukan sebagai verification evidence. | Not recommended |
| Persistent Mailpit without named data volume | Menjaga receiver tersedia dengan bounded lab contract; message continuity tidak diklaim. | Selected and accepted |
| Publish Alertmanager UI to host | Tidak diperlukan untuk Prometheus delivery atau Mailpit verification. | Rejected for baseline |

## ⚠️ Risks

| Risk | State | Mitigation or Follow-up |
| --- | --- | --- |
| Persistent direct-upstream Mailpit melampaui TN-032 | Mitigated by accepted contract | Project owner menerima explicit persistent lab-only exception pada 2026-08-27. |
| Prometheus replacement mengganggu scrape dan dashboard | Open implementation risk | Backup configuration, retain original container, preserve data volume, verify readiness and continuity, and define rollback triggers. |
| Telegraf stop sementara membuat application-health signal unavailable | Open implementation risk | Batasi pada exact original container, catat outage window, restore immediately after firing evidence, and verify recovery. |
| Alertmanager state hilang saat replacement | Mitigated by proposed contract | Gunakan `alertmanager_data` dan verifikasi continuity melalui controlled restart. |
| Mailpit messages hilang saat replacement | Accepted in recommendation | Treat capture as lab verification state; record evidence in TN and do not claim message persistence. |
| Persistent lab tidak pulih otomatis setelah host restart | Deferred | Tetapkan restart/boot orchestration pada operability activity terpisah sebelum production-like claim. |
| Retained rollback state menggunakan local storage | Open implementation risk | Record exact paths and IDs; cleanup only after stability acceptance and explicit destructive authorization. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah persistent lab Mailpit direct-upstream tanpa named volume diterima? | Answered | Project owner | Accepted on 2026-08-27: immutable image, exact resources, loopback API, no-volume continuity boundary, and persistent lab-only exception. | N/A; TN-035 tetap memerlukan implementation authorization. |
| Apakah controlled Telegraf stop/start boleh digunakan untuk real firing/resolved proof? | Answered | Project owner | Accepted on 2026-08-27 with exact-target preflight, bounded interruption, recovery criteria, and rollback. | N/A; execution tetap memerlukan TN-035 authorization. |
| Apakah stopped Prometheus rollback container dan protected snapshot harus dipertahankan setelah successful cutover? | Answered | Project owner | Accepted on 2026-08-27 through stability acceptance; exact cleanup requires separate destructive authorization. | N/A; retention menjadi requirement TN-035. |
| Apakah restart policy atau host-boot automation diperlukan pada lab? | Deferred | Project owner | Availability expectation and orchestration owner are defined. | Future operability work; tidak memblokir manual persistent lab baseline. |
| Apakah production HA, backup silence state, atau external notification diperlukan? | Deferred | Project owner and future environment owners | Production availability, secret, receiver, and external-delivery contracts are accepted. | Production rollout only. |

## 💡 Recommendation

Terima single-instance persistent Alertmanager dan persistent lab Mailpit pada
existing `devops-lab`. Alertmanager menggunakan exact generic local image,
named configuration serta data volumes, dan no host port. Mailpit menggunakan
accepted immutable TN-032 image, no named volume, internal-only SMTP, dan
loopback-only API/UI.

TN-035 harus memasukkan source initializer/validator, controlled Prometheus
configuration update and replacement, real rule firing melalui bounded
Telegraf stop/start, firing/resolved Mailpit assertions, data continuity,
rollback, and retained-success cleanup boundary. External delivery dan
production operability tetap deferred.

## 🤝 Decision Handoff

Project owner menerima recommendation sebagai lab integration contract pada
2026-08-27. Accepted decision mencakup:

- perluasan direct-upstream Mailpit menjadi persistent lab-only utility;
- exact topology, names, volumes, network, ports, and no-volume Mailpit storage;
- controlled Prometheus replacement dan retained rollback boundary;
- bounded Telegraf stop/start untuk real firing/resolved verification; serta
- separation antara persistent lab baseline, host-reboot recovery, external
  delivery, and production readiness.

Retrospective ADR review pada 2026-08-29 mengonsolidasikan keputusan Mailpit
lab tersebut ke
[TM-ADR-0005](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md).

Decision acceptance menutup TN-034, tetapi tidak mengizinkan source change,
image pull, container atau volume mutation, runtime interruption, cleanup,
commit, atau push. TN-035 tetap memerlukan approved implementation plan dan
authorization tersendiri.

## ⚙️ Commands Executed

```bash
# /home/eddywiyatno/git/devops-handbook
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,240p' docs/standards/engineering-journal-standards.md
sed -n '241,480p' docs/standards/engineering-journal-standards.md
sed -n '481,720p' docs/standards/engineering-journal-standards.md
sed -n '721,960p' docs/standards/engineering-journal-standards.md
sed -n '1,380p' docs/standards/writing-standards.md
sed -n '1,220p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
sed -n '1,240p' /home/eddywiyatno/git/tomcat-monitoring/config/prometheus/prometheus.yml
sed -n '1,240p' /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager/alertmanager.yml
for f in docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-{018,020,025,028,032}-*.md; do echo "$f"; rg -n '^## |^### ' "$f"; done
sed -n '61,218p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
sed -n '64,207p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md
sed -n '281,302p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
sed -n '868,893p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
rg -n -C 3 'prometheus_config|replace|rollback|backup|reload|volume' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md | sed -n '1,280p'

# /home/eddywiyatno/git/tomcat-monitoring
sed -n '1,280p' /home/eddywiyatno/git/alertmanager/AGENTS.md
for f in PROJECT VERSION CONFIG; do echo "$f=$(tr '\n' ' ' < /home/eddywiyatno/git/alertmanager/$f)"; done
sed -n '1,280p' /home/eddywiyatno/git/alertmanager/README.md
sed -n '1,260p' /home/eddywiyatno/git/alertmanager/Containerfile
for f in /home/eddywiyatno/git/alertmanager/scripts/*.sh; do echo "$f"; sed -n '1,260p' "$f"; done

# Initial Podman calls failed before inspection because sandbox access to
# /run/user/1000/libpod was read-only; the same read-only queries were repeated
# with approved runtime access.
podman ps --format '{{.Names}}|{{.Image}}|{{.Networks}}|{{.Ports}}|{{.Status}}'
podman volume ls --format '{{.Name}}'
podman network ls --format '{{.Name}}|{{.Driver}}'
podman image inspect --format '{{.Id}}|{{.RepoTags}}|{{.Digest}}|{{.Architecture}}|{{.Os}}' localhost/alertmanager:1.0.0
podman inspect --format 'name={{.Name}} image={{.ImageName}} restart={{.HostConfig.RestartPolicy.Name}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}} {{end}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' prometheus
podman inspect --format 'name={{.Name}} image={{.ImageName}} restart={{.HostConfig.RestartPolicy.Name}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}} {{end}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' telegraf
podman inspect --format 'name={{.Name}} image={{.ImageName}} restart={{.HostConfig.RestartPolicy.Name}} networks={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}} {{end}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}} {{end}} ports={{json .NetworkSettings.Ports}}' tomcat-jmx-exporter

# Initial sandbox-local requests could not reach the host loopback service; the
# same HTTP GET queries were repeated with approved host runtime access.
curl --silent --show-error --fail http://127.0.0.1:9090/api/v1/status/config
curl --silent --show-error --fail http://127.0.0.1:9090/api/v1/alertmanagers
curl --silent --show-error --fail 'http://127.0.0.1:9090/api/v1/rules?type=alert'
ss -ltn '( sport = :8025 or sport = :9093 )'
podman container exists alertmanager; printf 'alertmanager_exists=%s\n' "$?"
podman container exists mailpit; printf 'mailpit_exists=%s\n' "$?"
podman volume exists alertmanager_config; printf 'alertmanager_config_exists=%s\n' "$?"
podman volume exists alertmanager_data; printf 'alertmanager_data_exists=%s\n' "$?"
podman volume exists mailpit_data; printf 'mailpit_data_exists=%s\n' "$?"

# Documentation review
git status --short --branch
git diff --check
git diff --stat
git diff -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
rg -n 'TN-034|Status \| In Progress|Decision Gate pending|Objective belum selesai' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
if command -v mkdocs >/dev/null; then mkdocs --version; else echo 'mkdocs=not-installed'; fi
sed -n '1,380p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/index.md

# Decision acceptance and final documentation review
git diff --check
git status --short --branch
rg -n 'TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n '^\| Status \| Completed \|$|Selected and accepted|Accepted on 2026-08-27|Decision acceptance menutup TN-034' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-034-define-persistent-alertmanager-and-prometheus-delivery-integration-contract.md
```

## 🧾 Outcome

TN-034 selesai. Read-only assessment menghasilkan persistent integration
contract yang diterima project owner pada 2026-08-27. Source/runtime gap, exact
resources, ownership expansion, alternatives, risks, rollback, and verification
boundary telah diklasifikasikan.

Documentation review menemukan seluruh target relative link tersedia,
navigation dan phase entry konsisten, serta `git diff --check` lulus. MkDocs
executable tidak tersedia sehingga rendered-site build berstatus `Not
verified`; dependency tidak dipasang karena berada di luar authorization.

Decision ini hanya menjadi planning contract TN-035. Tidak ada source,
configuration, image, container, volume, network, port, runtime, cleanup, Git,
atau external state yang diubah oleh TN-034.

## ⏭️ Next Steps

```text
TN-033 isolated delivery verified
                |
                v
TN-034 proposed persistent contract
                |
                v
Project-owner Decision Gate
                |
                v
TN-035 implementation plan and authorization
                |
                v
Persistent Prometheus -> Alertmanager -> Mailpit verification
```

Ajukan TN-035 dengan exact implementation plan dan authorization terpisah.
Jangan melakukan runtime mutation atau cleanup hanya dari decision acceptance
TN-034.

## 🔗 Related Documentation

- [TM-ADR-0005 — Use Mailpit as the Persistent Lab Notification Verification Target](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md)
- [TN-033 — Implement and Verify Alertmanager Mailpit SMTP Capture](TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Tomcat Monitoring](../../index.md)

# TN-020 — Verify Isolated JMX Exporter TLS Scrape Integration

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
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

Membuktikan successful dan failed TLS scrape behavior antara temporary
Prometheus dan JMX Exporter pada isolated lab topology, lalu membersihkan
seluruh resource TN-020.

## 🌍 Background

TN-017 menetapkan accepted contract untuk lab TLS, isolated topology, failure
behavior, dan exact cleanup. TN-018 menerapkan two-rule JMX Exporter baseline,
sedangkan TN-019 menyimpan source serta decision evidence. Semantic parsing,
TLS handshake, hostname verification, dan Prometheus scrape belum diverifikasi.

Project owner menyetujui TN-020 pada 2026-08-25, termasuk pembuatan temporary
TLS material, containers `tomcat-jmx-exporter` dan `prometheus-tn020`, volumes
`prometheus_tn020_config`, `prometheus_tn020_truststore`, serta
`prometheus_tn020_data`, success/failure verification, dan exact cleanup.

## 📚 Scope

- Generate self-signed certificate dengan SAN `DNS:tomcat-jmx-exporter` pada
  TN-scoped temporary directory.
- Jalankan JMX Exporter dan temporary Prometheus pada existing network
  `devops-lab` tanpa host-port publication.
- Verifikasi target `up=1`, TLS hostname verification, serta dua baseline
  metrics melalui Prometheus API.
- Verifikasi untrusted certificate atau hostname mismatch menghasilkan target
  down tanpa menonaktifkan TLS verification.
- Hapus exact containers, tiga TN-scoped volumes, dan temporary TLS directory,
  lalu verifikasi cleanup.
- Catat chronology, expected result, actual result, dan evidence pada TN ini
  serta konsolidasikan verified current state.

Existing container `prometheus`, volumes `prometheus_config`,
`prometheus_truststore`, `prometheus_data`, image, network `devops-lab`,
`.artifacts`, production certificate lifecycle, full operational metric
catalog, deployment, commit, dan push tidak termasuk scope.

## ✅ Criteria

| Criterion | Expected result |
| --- | --- |
| Source and image identity | Current-source image ID `47eaad88a544` dan Prometheus image tersedia. |
| Isolation | Hanya exact TN-020 containers dan volumes dibuat pada existing `devops-lab`. |
| TLS success | Target `tomcat-jmx-exporter` berstatus `up=1` dengan hostname verification aktif. |
| Baseline metrics | Query API mengembalikan `jvm_memory_heap_used_bytes` dan `tomcat_server_info`. |
| TLS failure | Untrusted certificate atau hostname mismatch membuat target down tanpa `insecure_skip_verify`. |
| Persistent boundary | Existing Prometheus container dan volumes tidak diubah. |
| Cleanup | Exact TN-020 containers, volumes, dan TLS directory tidak tersisa. |

## 🧪 Method

1. Verifikasi source, image, tool, network, dan collision exact targets.
2. Buat temporary certificate, keystore, password file, serta TN-scoped
   Prometheus volumes.
3. Jalankan JMX Exporter dan Prometheus sementara, lalu verifikasi success
   melalui Prometheus API.
4. Ganti trust material temporary Prometheus dengan CA yang tidak dipercaya,
   jalankan ulang target test, dan verifikasi target down.
5. Pulihkan trusted CA, verifikasi target kembali up, lalu hapus seluruh exact
   temporary resources.
6. Validasi final source, documentation, dan cleanup state.

## 🛠️ Evidence

### Readiness and authorization

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/devops-handbook status --short --branch
git -C /home/eddywiyatno/git/tomcat-jmx-exporter status --short --branch
git -C /home/eddywiyatno/git/tomcat-monitoring rev-parse HEAD
git -C /home/eddywiyatno/git/tomcat-jmx-exporter rev-parse HEAD
git -C /home/eddywiyatno/git/prometheus rev-parse HEAD
podman container exists tomcat-jmx-exporter
podman container exists prometheus-tn020
podman volume exists prometheus_tn020_config
podman volume exists prometheus_tn020_truststore
podman volume exists prometheus_tn020_data
podman network exists devops-lab
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman image exists localhost/prometheus:1.0.0
podman image inspect localhost/tomcat-jmx-exporter:1.0.0 --format '{{.Id}} {{.Created}} {{json .Labels}}'
podman image inspect localhost/prometheus:1.0.0 --format '{{.Id}} {{.Created}} {{json .Labels}}'
command -v openssl
openssl version
```

Source repositories dan Handbook bersih. JMX Exporter source berada pada
`231cb915cc2e058abd1fa0377877b120a9d7e2be`; TN-008 mengaitkan revision
tersebut dengan local image ID `47eaad88a544`. Prometheus image ID
`e0bbb3929e2f` tersedia dan OpenSSL 3.0.13 tersedia.

Percobaan pertama command Podman gagal karena sandbox tidak dapat mengubah
permission `/run/user/1000/libpod`. Inspection yang sama berhasil setelah
runtime access disetujui. Exact collision result, network, dan image readiness
divalidasi kembali sebelum resource dibuat.

Final preflight tidak menemukan container atau volume dengan exact TN-020
names. Existing `prometheus` berstatus running, network `devops-lab` tersedia,
dan kedua image tersedia.

### Generate temporary TLS material

```bash
mktemp -d /tmp/tomcat-monitoring-tn020-tls.XXXXXX
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.key -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt -days 1 -subj /CN=tomcat-jmx-exporter -addext subjectAltName=DNS:tomcat-jmx-exporter
openssl rand -base64 24 -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password
chmod 0600 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.key /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password
openssl pkcs12 -export -inkey /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.key -in /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt -name tomcat-jmx-exporter -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore.p12 -passout file:/tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/tomcat-monitoring-tn020-tls.5v8Rve/untrusted.key -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/untrusted-ca.crt -days 1 -subj /CN=untrusted-tn020-ca
openssl x509 -in /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt -noout -subject -ext subjectAltName
openssl rand -base64 -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password 24
chmod 0600 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password
openssl pkcs12 -export -inkey /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.key -in /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt -name tomcat-jmx-exporter -out /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore.p12 -passout file:/tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password
chmod 0600 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore.p12
openssl pkcs12 -in /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore.p12 -passin file:/tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password -info -noout
```

Certificate memiliki SAN `DNS:tomcat-jmx-exporter`; private key, password
file, dan PKCS12 menggunakan mode `0600`. Percobaan pertama `openssl rand`
gagal karena posisi opsi `-out` tidak diterima dan keystore belum dibuat.
Command dikoreksi tanpa mencetak password; PKCS12 validation kemudian lulus.

### Initialize isolated volumes and start runtime

```bash
podman volume create prometheus_tn020_config
podman volume create prometheus_tn020_truststore
podman volume create prometheus_tn020_data
podman volume mount prometheus_tn020_config
podman volume mount prometheus_tn020_truststore
podman volume mount prometheus_tn020_data
podman unshare sh -c 'config_mount=$(podman volume mount prometheus_tn020_config); trust_mount=$(podman volume mount prometheus_tn020_truststore); data_mount=$(podman volume mount prometheus_tn020_data); install -m 0444 /home/eddywiyatno/git/tomcat-monitoring/config/prometheus/prometheus.yml "${config_mount}/prometheus.yml"; install -m 0444 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt "${trust_mount}/jmx-exporter-ca.crt"; chown 65534:65534 "${data_mount}"; chmod 0770 "${data_mount}"; stat -c "%a %u:%g %n" "${config_mount}/prometheus.yml" "${trust_mount}/jmx-exporter-ca.crt" "${data_mount}"'
podman run --detach --name tomcat-jmx-exporter --network devops-lab --volume /home/eddywiyatno/git/tomcat-monitoring/config/jmx-exporter/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro --volume /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore.p12:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro --volume /tmp/tomcat-monitoring-tn020-tls.5v8Rve/keystore-password:/run/secrets/tomcat-jmx-exporter/keystore-password:ro localhost/tomcat-jmx-exporter:1.0.0
podman run --detach --name prometheus-tn020 --network devops-lab --volume prometheus_tn020_config:/etc/prometheus:ro --volume prometheus_tn020_truststore:/run/secrets/tomcat-monitoring:ro --volume prometheus_tn020_data:/prometheus localhost/prometheus:1.0.0 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
podman ps --filter name=^tomcat-jmx-exporter$ --filter name=^prometheus-tn020$ --format '{{.Names}} {{.Status}} {{.Ports}}'
```

Volume creation berhasil. Direct `podman volume mount` gagal karena rootless
Podman mewajibkan user namespace; percobaan itu tidak menyalin file. Re-run
dengan `podman unshare` berhasil mengisi configuration dan truststore serta
menetapkan data directory ke mode `0770` dan UID/GID `65534`. Kedua containers
berstatus running tanpa host-published port.

### Verify successful scrape and metric behavior

```bash
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22tomcat-jmx-exporter%22%7D'
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/targets?state=active'
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=jvm_memory_heap_used_bytes'
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=tomcat_server_info'
podman logs --tail 30 tomcat-jmx-exporter
podman logs --tail 30 prometheus-tn020
podman exec prometheus-tn020 wget --help
podman exec tomcat-jmx-exporter sh -c 'command -v curl || command -v wget || true'
podman exec prometheus-tn020 wget -qO- --ca-certificate=/run/secrets/tomcat-monitoring/jmx-exporter-ca.crt https://tomcat-jmx-exporter:9404/metrics
podman exec prometheus-tn020 wget -S -O- --no-check-certificate -T 10 https://tomcat-jmx-exporter:9404/metrics
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=%7Bjob%3D%22tomcat-jmx-exporter%22%7D'
```

Prometheus melaporkan target `https://tomcat-jmx-exporter:9404/metrics`
`health=up`, tanpa `lastError`, dan `up=1`. Karena CA file digunakan serta
`insecure_skip_verify: false`, keberhasilan pada alias yang sama dengan SAN
membuktikan trust dan hostname verification aktif. JVM heap metric tersedia.

Query `tomcat_server_info` kosong. Inventory seluruh series membuktikan Tomcat
MBean rule menghasilkan `tomcat_server{version="Apache Tomcat/9.0.120"} 1`.
Dengan demikian Tomcat MBean mapping berfungsi, tetapi runtime metric name tidak
sesuai exact source contract.

BusyBox `wget` tidak mendukung `--ca-certificate`; diagnostic request dengan
`--no-check-certificate` juga timeout dan tidak digunakan sebagai evidence TLS.
Prometheus target API serta series inventory tetap memberikan evidence melalui
scrape path yang dikonfigurasi dengan strict verification.

### Verify strict TLS failure and recovery

```bash
podman rm --force prometheus-tn020
podman unshare sh -c 'trust_mount=$(podman volume mount prometheus_tn020_truststore); install -m 0444 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/untrusted-ca.crt "${trust_mount}/jmx-exporter-ca.crt"'
podman run --detach --name prometheus-tn020 --network devops-lab --volume prometheus_tn020_config:/etc/prometheus:ro --volume prometheus_tn020_truststore:/run/secrets/tomcat-monitoring:ro --volume prometheus_tn020_data:/prometheus localhost/prometheus:1.0.0 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/targets?state=active'
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22tomcat-jmx-exporter%22%7D'
podman inspect prometheus --format '{{.Name}} {{.State.Status}} {{.Id}} {{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}'
podman inspect prometheus-tn020 --format '{{.Name}} {{.State.Status}} {{.Id}} {{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}'
podman rm --force prometheus-tn020
podman unshare sh -c 'trust_mount=$(podman volume mount prometheus_tn020_truststore); install -m 0444 /tmp/tomcat-monitoring-tn020-tls.5v8Rve/server.crt "${trust_mount}/jmx-exporter-ca.crt"'
podman run --detach --name prometheus-tn020 --network devops-lab --volume prometheus_tn020_config:/etc/prometheus:ro --volume prometheus_tn020_truststore:/run/secrets/tomcat-monitoring:ro --volume prometheus_tn020_data:/prometheus localhost/prometheus:1.0.0 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=up%7Bjob%3D%22tomcat-jmx-exporter%22%7D'
podman exec prometheus-tn020 wget -qO- 'http://127.0.0.1:9090/api/v1/query?query=tomcat_server'
```

Untrusted CA menghasilkan `health=down`, `up=0`, dan error
`x509: certificate signed by unknown authority`. Persistent `prometheus` tetap
running pada container ID `43ac7dab851f` dengan volumes non-TN, sedangkan
temporary container hanya menggunakan tiga TN-scoped volumes. Setelah trusted
CA dipulihkan, target kembali `up=1` dan Tomcat series tersedia.

### Clean exact resources and verify final state

```bash
podman rm --force prometheus-tn020 tomcat-jmx-exporter
podman volume rm prometheus_tn020_config prometheus_tn020_truststore prometheus_tn020_data
rm -rf /tmp/tomcat-monitoring-tn020-tls.5v8Rve
podman ps -a --filter name=^tomcat-jmx-exporter$ --filter name=^prometheus-tn020$ --format '{{.Names}} {{.Status}}'
podman volume ls --filter name=^prometheus_tn020_config$ --filter name=^prometheus_tn020_truststore$ --filter name=^prometheus_tn020_data$ --format '{{.Name}}'
test ! -e /tmp/tomcat-monitoring-tn020-tls.5v8Rve
podman inspect prometheus --format '{{.Name}} {{.State.Status}} {{.Id}} {{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}'
podman network inspect devops-lab --format '{{.Name}}'
```

Exact containers, volumes, dan TLS directory berhasil dihapus. Collision scans
tidak menghasilkan output dan directory tidak tersedia. Persistent
`prometheus` tetap running dengan container ID serta tiga volumes semula;
network `devops-lab` tetap tersedia.

### Consolidate and validate documentation

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-verify-isolated-jmx-exporter-tls-scrape-integration.md
rg -n '^\| Status \| Completed \|$|TN-020|tomcat_server_info|tomcat_server|up=1|up=0|unknown authority' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-verify-isolated-jmx-exporter-tls-scrape-integration.md
command -v mkdocs
git diff --stat
git status --short --branch
```

Diff check lulus, trailing-whitespace scan tidak menemukan match, TN-020
terdaftar pada navigation dan phase index, serta current-state pages
mempertahankan result boundary. MkDocs render berstatus `Not verified` karena
executable tidak tersedia dan dependency tidak dipasang.

## ✅ Verification

| Method | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| Source and image inspection | Image yang diuji terhubung dengan current source. | Passed. | Source `231cb91`; image ID `47eaad88a544`, sesuai TN-008. |
| Prometheus target dan query API | TLS target up dan dua expected baseline names tersedia. | Partial; target `up=1` dan JVM metric tersedia, tetapi configured Tomcat name tidak. | Target API, JVM query, empty `tomcat_server_info` query, dan `tomcat_server` series. |
| Untrusted-CA test | Strict verification menurunkan target. | Passed; `up=0` dengan x509 unknown-authority error. | Target dan query API. |
| Trusted-CA recovery | Target kembali up tanpa menonaktifkan verification. | Passed; `up=1`. | Query API setelah CA restoration. |
| Isolation inspection | Persistent Prometheus tidak menggunakan TN volumes. | Passed. | Container IDs dan mount lists persistent serta temporary runtime. |
| Exact cleanup inspection | Tidak ada TN container, volume, atau TLS directory tersisa. | Passed. | Empty collision scans dan negative directory test. |
| Documentation validation | Diff, whitespace, navigation, dan references valid. | Passed kecuali MkDocs render tidak tersedia. | `git diff --check`, targeted scans, dan file checks. |

## 🔍 Findings

| Finding | State | Evidence |
| --- | --- | --- |
| Strict TLS success | Verified | Target `up=1` pada HTTPS alias yang cocok dengan certificate SAN dan `insecure_skip_verify: false`. |
| Strict TLS failure | Verified | Untrusted CA menghasilkan `up=0` dan explicit x509 verification error. |
| Recovery | Verified | Trusted CA restoration mengembalikan target ke `up=1`. |
| JVM baseline | Verified | `jvm_memory_heap_used_bytes` tersedia melalui Prometheus query. |
| Tomcat MBean mapping | Verified with naming exception | Runtime series `tomcat_server` memiliki label version Tomcat yang benar. |
| Isolation and cleanup | Verified | Persistent Prometheus tidak berubah dan seluruh exact TN resources dihapus. |

## ⚠️ Exceptions

Configured metric `tomcat_server_info` tidak tersedia dengan exact name pada
Prometheus 3.13.2. Runtime menghasilkan `tomcat_server` dengan expected Tomcat
version label. TN-020 tidak mengubah source karena configuration dan validator
reconciliation berada di luar authorized verification scope.

Telegraf target pada shared configuration berstatus down karena container
alias `telegraf` tidak tersedia. Kondisi ini expected dan berada di luar
JMX-only objective TN-020.

## ❓ Open Questions

| Question | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Apakah downstream contract menggunakan runtime series `tomcat_server`, atau source rule harus diubah agar exact `tomcat_server_info` tersedia? | Open | Project owner dan `tomcat-monitoring` source owner | Runtime naming behavior dinilai, satu canonical name diterima, lalu configuration, validator, dan current-state documentation direkonsiliasi. | Dashboard dan alert contract untuk Tomcat server-info metric; tidak memblokir TLS path evidence. |

### Resolution recorded by TN-021

Project owner menerima `tomcat_server` sebagai canonical runtime contract pada
2026-08-25. TN-021 merekonsiliasi configuration, validator, dan current-state
documentation; resolution tersebut menutup pertanyaan tanpa mengubah runtime
evidence historis TN-020.

## ⚙️ Commands Executed

Command discovery material tercatat pada `Readiness and authorization`.
Seluruh command mutation, verification, diagnostic, recovery, dan cleanup
tercatat secara kronologis pada bagian evidence berikutnya. Nilai password
tidak pernah dicetak.

## 📌 Conclusion

Successful TLS scrape, strict failure dengan untrusted CA, recovery, isolation,
dan cleanup memenuhi expected result. JVM baseline tersedia; Tomcat MBean
mapping terbukti dengan exception bahwa runtime series bernama
`tomcat_server`, bukan configured `tomcat_server_info`.

## 🧾 Outcome

Objective verification selesai pada isolated lab topology. Existing persistent
Prometheus dan network tidak diubah; seluruh TN-scoped runtime serta secret
material telah dibersihkan. Hasil ini tidak membuktikan persistent deployment,
Telegraf scrape, full metric coverage, alerting, atau end-to-end monitoring.

## ⏭️ Next Steps

Metric-name reconciliation dilanjutkan oleh
[TN-021](TN-021-reconcile-tomcat-server-metric-name-contract.md). Persistent
integration tetap memerlukan authorization terpisah.

## 🔗 Related Documentation

- [TN-017 — Define JMX Exporter Configuration and Lab TLS Integration Contract](TN-017-define-jmx-exporter-configuration-and-lab-tls-integration-contract.md)
- [TN-018 — Implement JMX Exporter Baseline Configuration and Validation](TN-018-implement-jmx-exporter-baseline-configuration-and-validation.md)
- [TN-019 — Commit JMX Exporter Baseline Configuration and Decision Evidence](TN-019-commit-jmx-exporter-baseline-configuration-and-decision-evidence.md)
- [Tomcat Monitoring](../../index.md)

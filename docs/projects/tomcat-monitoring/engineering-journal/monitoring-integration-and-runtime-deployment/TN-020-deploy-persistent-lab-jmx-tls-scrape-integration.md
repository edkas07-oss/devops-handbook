# TN-020 — Deploy Persistent Lab JMX TLS Scrape Integration

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

Mengintegrasikan persistent generic Tomcat/JMX target ke existing lab
Prometheus melalui strict HTTPS scrape, mempertahankan historical data, dan
membuktikan readiness, baseline metrics, serta rollback boundary.

## 🌍 Background

TN-018 menerima persistent integration contract dan TN-019 menutup prerequisite
self-signed certificate lifecycle untuk lab. Project owner kemudian menyetujui
documentation-only planning TN-020 pada 2026-08-25. Approval tersebut mencakup
source discovery, penyusunan plan, pencatatan Technical Note, navigation, dan
documentation checks; approval belum mencakup deployment atau runtime mutation.

Engineering Journal Standards menetapkan bahwa implementation planning berada
pada Technical Note yang nantinya dieksekusi. Karena itu TN-020 tetap `Planned`
sampai exact plan ini menerima Implementation Gate, lalu execution dan actual
result dicatat secara append-oriented pada TN yang sama.

Handbook memiliki controlled journal migration yang belum committed. TN-020
mempertahankan seluruh perubahan tersebut dan hanya menambahkan record serta
navigation baru.

## 📚 Scope

Planning yang sudah diotorisasi mencakup:

- validasi source contract dan repository ownership aktual;
- exact preflight, certificate generation, deployment, replacement, rollback,
  verification, dan cleanup plan;
- pencatatan readiness, risk, authorization boundary, dan evidence; serta
- penambahan TN-020 pada phase navigation.

Planned deployment yang masih menunggu authorization mencakup:

- membuat initial self-signed lab material pada accepted non-Git directory;
- menjalankan persistent container `tomcat-jmx-exporter` pada `devops-lab`
  tanpa host-published port;
- mencadangkan active Prometheus configuration dan CA trust;
- memperbarui `prometheus_config` serta `prometheus_truststore`, kemudian
  mengganti exact container `prometheus` dengan tetap menggunakan
  `prometheus_data`;
- memverifikasi readiness, dashboard, strict TLS contract,
  `jvm_memory_heap_used_bytes`, `tomcat_server`, dan mount data; serta
- menjalankan exact rollback bila cutover gagal.

Source atau configuration change, image build, image publication, application-
specific WAR, Telegraf integration, named-volume removal, production
certificate, commit, push, dan deployment di luar persistent lab tidak termasuk
scope. Successful-cutover cleanup tetap memerlukan authorization destruktif
terpisah terhadap exact target.

## 📋 Prerequisites

| Prerequisite | Readiness | Required evidence before mutation |
| --- | --- | --- |
| Architecture and target contract | Ready at decision level | TN-018, TN-019, dan TM-ADR-0001 tetap `Accepted` atau `Completed`. |
| Source identities | Ready for planning | `tomcat-monitoring` `9975139`, `tomcat-jmx-exporter` `231cb91`, `prometheus` `0e3d1f4`, dan `tomcat` `e2d2df6`; implementation wajib mengulang identity serta dirty-state check. |
| Tool availability | Observed for planning | `/usr/bin/openssl`, `/usr/bin/podman`, dan `/usr/bin/curl`; version dan functional access tetap diperiksa saat implementation. |
| Local images | Not verified in TN-020 | `localhost/tomcat-jmx-exporter:1.0.0` dan `localhost/prometheus:1.0.0` harus tersedia serta dihubungkan ke current source evidence. Tidak ada build di TN-020. |
| Existing runtime | Not inspected in TN-020 | Exact `prometheus`, network `devops-lab`, dan tiga named volumes harus tersedia; collision target lain wajib tidak tersedia. |
| Maintenance window | Pending | Project owner menerima controlled Prometheus stop, rename, replacement, readiness interval, dan rollback window. |
| Runtime authorization | Pending | Exact create, stop, rename, copy, start, remove-on-failure, dan rollback actions disetujui. |
| Cleanup authorization | Pending separately | Successful-cutover cleanup hanya menyasar stopped container `prometheus-rollback` dan rollback directory yang sudah diperiksa; named volumes tidak pernah menjadi cleanup target. |

Preflight berhenti tanpa mutation jika source identity berubah, source repository
dirty di luar baseline yang diterima, initial TLS atau rollback directory sudah
tersedia, exact container atau initializer name bertabrakan, image/network/
volume tidak tersedia, existing Prometheus tidak ready, mount atau port berbeda
dari accepted contract, atau maintenance dan rollback authorization belum
lengkap.

## ⚖️ Execution Decision

TN-020 menerapkan keputusan berikut tanpa mengubah architecture boundary:

- repository `tomcat-monitoring` memiliki integration sequence dan project
  configuration;
- repository `tomcat-jmx-exporter` tetap memiliki generic derived image;
- repository `prometheus` tetap memiliki generic collector runtime;
- existing `prometheus_config`, `prometheus_truststore`, dan
  `prometheus_data` dipertahankan sebagai exact volume targets;
- initial certificate material menggunakan contract TN-019 dan tidak masuk Git
  maupun image; serta
- Prometheus tetap menggunakan CA file dan `insecure_skip_verify: false`.

Generic `tomcat-jmx-exporter/scripts/run.sh` selalu memublikasikan host port
`8080` dan `9404`. Planned persistent integration tidak mengubah launcher
tersebut; ia menggunakan direct `podman run` milik integration activity agar
target hanya dapat diakses melalui `devops-lab`. Prometheus replacement tetap
menggunakan `prometheus/scripts/run.sh` karena launcher itu menerima exact named
volumes dan optional host port yang sesuai persistent contract.

Keputusan ini menerapkan [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
dan tidak memerlukan ADR baru.

## 🛠️ Change Plan

Seluruh command pada section ini adalah planned command dan belum dijalankan.
Nilai secret tidak boleh dicetak, disalin ke journal, atau diberikan sebagai
command-line literal.

### Establish execution context and run preflight

Jalankan sebagai rootless Podman user pada host persistent lab dari working
tree yang identitasnya telah disetujui.

```bash
readonly TM_TLS_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls
readonly TM_ROLLBACK_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover
readonly TM_MONITORING_REPO=/home/eddywiyatno/git/tomcat-monitoring
readonly TM_JMX_REPO=/home/eddywiyatno/git/tomcat-jmx-exporter
readonly TM_PROMETHEUS_REPO=/home/eddywiyatno/git/prometheus

git -C "${TM_MONITORING_REPO}" status --short
git -C "${TM_MONITORING_REPO}" rev-parse --short HEAD
git -C "${TM_JMX_REPO}" status --short
git -C "${TM_JMX_REPO}" rev-parse --short HEAD
git -C "${TM_PROMETHEUS_REPO}" status --short
git -C "${TM_PROMETHEUS_REPO}" rev-parse --short HEAD
test ! -e "${TM_TLS_DIR}"
test ! -e "${TM_ROLLBACK_DIR}"
test ! -e "${TM_ROLLBACK_DIR}.partial"
! podman container exists tomcat-jmx-exporter
podman container exists prometheus
! podman container exists prometheus-rollback
! podman container exists prometheus-volume-backup
! podman container exists prometheus-volume-restore
! podman container exists prometheus-volume-init
podman network exists devops-lab
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman image exists localhost/prometheus:1.0.0
podman inspect prometheus
curl --fail --silent --show-error http://localhost:9090/-/ready
```

Expected result: source identities cocok dengan approved baseline, repository
source bersih, creation targets tidak tersedia, existing persistent resources
dan images tersedia, `prometheus` menggunakan accepted network, ports, serta
volumes, dan readiness mengembalikan HTTP success. `podman inspect` direview
tanpa menyalin output panjang ke journal.

### Generate initial certificate material

Initial creation bersifat fail-closed: directory harus tidak tersedia dan tidak
boleh ditimpa. Password hanya dibaca melalui file.

```bash
install -d -m 0700 "${TM_TLS_DIR}"
umask 077
openssl rand -base64 48 > "${TM_TLS_DIR}/keystore-password"
openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 \
  -keyout "${TM_TLS_DIR}/server.key" \
  -out "${TM_TLS_DIR}/server.crt" \
  -subj /CN=tomcat-jmx-exporter \
  -addext subjectAltName=DNS:tomcat-jmx-exporter \
  -addext basicConstraints=critical,CA:FALSE \
  -addext keyUsage=critical,digitalSignature,keyEncipherment \
  -addext extendedKeyUsage=serverAuth
openssl pkcs12 -export \
  -inkey "${TM_TLS_DIR}/server.key" \
  -in "${TM_TLS_DIR}/server.crt" \
  -name tomcat-jmx-exporter \
  -out "${TM_TLS_DIR}/keystore.p12" \
  -passout "file:${TM_TLS_DIR}/keystore-password"
chmod 0700 "${TM_TLS_DIR}"
chmod 0600 "${TM_TLS_DIR}/server.key" \
  "${TM_TLS_DIR}/keystore.p12" \
  "${TM_TLS_DIR}/keystore-password"
chmod 0444 "${TM_TLS_DIR}/server.crt"
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout \
  -subject -issuer -dates -ext subjectAltName -ext extendedKeyUsage
openssl x509 -in "${TM_TLS_DIR}/server.crt" -checkend 2592000 -noout
openssl pkcs12 -in "${TM_TLS_DIR}/keystore.p12" \
  -passin "file:${TM_TLS_DIR}/keystore-password" -noout
stat -c '%a %n' "${TM_TLS_DIR}" "${TM_TLS_DIR}"/*
```

Expected result: certificate memiliki SAN `DNS:tomcat-jmx-exporter`, server-auth
usage, 365-day validity, dan lebih dari 30 hari remaining validity. Directory
dan file modes persis mengikuti TN-019; tidak ada secret value pada output.

### Start the persistent JMX target

Direct invocation sengaja tidak memiliki `--publish`.

```bash
podman run --detach \
  --name tomcat-jmx-exporter \
  --network devops-lab \
  --network-alias tomcat-jmx-exporter \
  --volume "${TM_MONITORING_REPO}/config/jmx-exporter/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro" \
  --volume "${TM_TLS_DIR}/keystore.p12:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro" \
  --volume "${TM_TLS_DIR}/keystore-password:/run/secrets/tomcat-jmx-exporter/keystore-password:ro" \
  localhost/tomcat-jmx-exporter:1.0.0
podman inspect tomcat-jmx-exporter
test -z "$(podman port tomcat-jmx-exporter)"
podman logs --tail 80 tomcat-jmx-exporter
```

Expected result: container berjalan dengan alias internal yang benar, tidak
memiliki host-published port, mount configuration dan TLS bersifat read-only,
serta startup log menunjukkan JMX Exporter HTTPS pada port internal `9404`
tanpa mencetak password. Base-image HTTP health dapat tetap tidak sehat karena
target sengaja tidak memuat application-specific WAR; kondisi itu tidak dipakai
sebagai bukti metrics readiness.

### Back up active Prometheus material

Backup hanya mencakup active configuration dan public CA trust. Data tetap pada
`prometheus_data` dan tidak disalin atau dimodifikasi pada tahap ini.

```bash
install -d -m 0700 "${TM_ROLLBACK_DIR}.partial"
podman create \
  --name prometheus-volume-backup \
  --user 0 \
  --entrypoint /bin/sh \
  --volume prometheus_config:/source/config:ro \
  --volume prometheus_truststore:/source/truststore:ro \
  localhost/prometheus:1.0.0 -c true
podman cp prometheus-volume-backup:/source/config/prometheus.yml \
  "${TM_ROLLBACK_DIR}.partial/prometheus.yml"
podman cp prometheus-volume-backup:/source/truststore/jmx-exporter-ca.crt \
  "${TM_ROLLBACK_DIR}.partial/jmx-exporter-ca.crt"
podman rm prometheus-volume-backup
chmod 0444 "${TM_ROLLBACK_DIR}.partial/prometheus.yml" \
  "${TM_ROLLBACK_DIR}.partial/jmx-exporter-ca.crt"
mv "${TM_ROLLBACK_DIR}.partial" "${TM_ROLLBACK_DIR}"
sha256sum "${TM_ROLLBACK_DIR}/prometheus.yml" \
  "${TM_ROLLBACK_DIR}/jmx-exporter-ca.crt"
```

Expected result: atomic rollback directory berisi readable snapshot dari kedua
active files dan backup helper sudah dihapus. Missing source file atau copy
failure menghentikan cutover sebelum persistent Prometheus mutation.

### Update volumes and replace Prometheus

Initializer project menyalin current configuration dan new public certificate,
mempertahankan data volume, lalu menghapus helper miliknya. Existing collector
dipertahankan dengan nama rollback sampai verification dan stability gate
selesai.

```bash
cd "${TM_MONITORING_REPO}"
./scripts/initialize-prometheus-volumes.sh "${TM_TLS_DIR}/server.crt"
podman stop prometheus
podman rename prometheus prometheus-rollback
cd "${TM_PROMETHEUS_REPO}"
./scripts/run.sh \
  prometheus_config \
  prometheus_truststore \
  prometheus_data \
  prometheus \
  9090
```

Expected result: new `prometheus` menggunakan exact existing volumes dan port,
sedangkan previous container tersedia dalam keadaan stopped sebagai rollback
target. Jika run command gagal, jalankan Rollback Plan segera tanpa melanjutkan
verification.

## ✅ Verification Plan

### Verify collector and strict TLS integration

```bash
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://edkas-pc1:9090/-/ready
podman inspect prometheus
podman exec prometheus grep -F 'insecure_skip_verify: false' \
  /etc/prometheus/prometheus.yml
podman exec prometheus sha256sum \
  /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt
sha256sum "${TM_TLS_DIR}/server.crt"
curl --fail --silent --show-error --get \
  --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' \
  http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get \
  --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' \
  http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get \
  --data-urlencode 'query=count(tomcat_server)' \
  http://localhost:9090/api/v1/query
```

Expected result:

- readiness sukses dan dashboard tetap tersedia pada accepted lab access path;
- `prometheus` tetap menggunakan `devops-lab`, port `9090`, read-only
  configuration/truststore, dan read-write `prometheus_data` yang sama;
- deployed configuration mempertahankan `insecure_skip_verify: false`;
- deployed CA digest sama dengan `server.crt`;
- query JMX target menghasilkan `up=1`; serta
- kedua baseline metric memiliki series count lebih besar dari nol.

Target `telegraf-health` boleh tetap down sesuai explicit JMX-only exception
TN-018. Verification tidak boleh menyimpulkan end-to-end monitoring sehat.

### Verify continuity boundary

Catat exact pre-cutover dan post-cutover volume identity dari `podman inspect`,
readiness recovery time, query result, dan stopped rollback-container state.
Historical-data preservation dibatasi pada penggunaan named volume
`prometheus_data` yang sama; TN-020 tidak mengklaim backup, retention policy,
atau recovery data yang belum diuji.

## ↩️ Rollback Plan

Rollback mendapatkan authorization bersama deployment karena failure handling
tidak boleh menunggu destructive approval baru. Targetnya terbatas pada failed
new container, exact active configuration/truststore files, dan renamed
previous container. TLS material tetap dipertahankan.

```bash
if podman container exists prometheus-rollback; then
  if podman container exists prometheus; then
    podman stop prometheus
    podman rm prometheus
  fi
else
  podman stop prometheus
fi
podman create \
  --name prometheus-volume-restore \
  --user 0 \
  --entrypoint /bin/sh \
  --volume prometheus_config:/staging/config \
  --volume prometheus_truststore:/staging/truststore \
  localhost/prometheus:1.0.0 \
  -c 'chmod 0444 /staging/config/prometheus.yml /staging/truststore/jmx-exporter-ca.crt'
podman cp "${TM_ROLLBACK_DIR}/prometheus.yml" \
  prometheus-volume-restore:/staging/config/prometheus.yml
podman cp "${TM_ROLLBACK_DIR}/jmx-exporter-ca.crt" \
  prometheus-volume-restore:/staging/truststore/jmx-exporter-ca.crt
podman start --attach prometheus-volume-restore
podman rm prometheus-volume-restore
if podman container exists prometheus-rollback; then
  podman rename prometheus-rollback prometheus
fi
podman start prometheus
curl --fail --silent --show-error http://localhost:9090/-/ready
podman stop tomcat-jmx-exporter
podman rm tomcat-jmx-exporter
```

Expected result: previous Prometheus configuration, CA trust, container name,
host port, data-volume attachment, dan readiness dipulihkan. Failed JMX target
dihapus, tetapi TLS directory dan rollback snapshot tidak dihapus agar evidence
dan retry material tetap tersedia. Rollback deviation atau failure menghentikan
aktivitas dengan status `Blocked` dan exact residual state dicatat.

## 🚀 Deployment

### Authorize and verify preflight

Project owner menyetujui Implementation Gate TN-020 pada 2026-08-25. Scope
approval mencakup certificate generation, persistent JMX container creation,
Prometheus configuration/truststore update, controlled container replacement,
verification, dan exact failure rollback. Successful-cutover cleanup tidak
disetujui.

| Element | Result |
| --- | --- |
| Expected | Source identities cocok, creation targets tidak tersedia, persistent Prometheus ready, accepted resources tersedia, dan collision helpers tidak tersedia. |
| Actual | Source `9975139`, `231cb91`, dan `0e3d1f4` bersih; TLS serta rollback paths tidak tersedia; `prometheus` ready pada `devops-lab`; port `9090`, tiga named volumes, dua local images, dan required tools tersedia; seluruh collision targets tidak tersedia. |
| Evidence | Concise `git`, `test`, `podman`, image-inspect, mount-inspect, dan readiness output pada Commands Executed. |

Podman preflight pertama di dalam sandbox gagal sebelum runtime dapat dibaca
karena `/run/user/1000/libpod` read-only. Hasil existence dari percobaan itu
diabaikan. Command yang sama diulang melalui approved host-runtime access dan
menjadi evidence preflight aktual.

### Generate and validate TLS material

| Element | Result |
| --- | --- |
| Expected | Initial material terbentuk tanpa overwrite, SAN dan usage benar, validity 365 hari, remaining validity lebih dari 30 hari, alias PKCS12 benar, dan permissions sesuai TN-019. |
| Actual | Certificate berlaku `2026-08-25` sampai `2027-08-25`, memiliki SAN `DNS:tomcat-jmx-exporter`, `CA:FALSE`, TLS server-auth usage, serta PKCS12 alias `tomcat-jmx-exporter`. Directory mode `0700`; private key, password, dan keystore `0600`; public certificate `0444`. |
| Evidence | OpenSSL metadata, `keytool -list`, dan `stat`; tidak ada password atau private-key content pada output. |

### Start the persistent JMX target

| Element | Result |
| --- | --- |
| Expected | `tomcat-jmx-exporter` berjalan pada `devops-lab` dengan correct alias, read-only mounts, HTTPS `9404`, dan tanpa host-published port. |
| Actual | Container `a5e42f2719d7` berjalan pada `devops-lab`, memiliki alias `tomcat-jmx-exporter`, port bindings `{}`, dan tiga mounts `rw=false`. Startup log menunjukkan Java Agent HTTPS pada `0.0.0.0:9404/metrics`. |
| Evidence | Exact `podman run`, concise inspect, empty `podman port`, dan startup log. |

Base-image HTTP health bukan completion criterion karena generic target tidak
memuat application-specific WAR. Application-health claim tidak dibuat.

### Back up active Prometheus material

| Element | Result |
| --- | --- |
| Expected | Active configuration dan public CA tersalin ke atomic rollback directory sebelum mutation; helper dihapus dan data volume tidak disentuh. |
| Actual | Rollback directory mode `0700` berisi `prometheus.yml` dan `jmx-exporter-ca.crt` mode `0444`; helper tidak lagi tersedia. Pre-cutover digests masing-masing `de88d040...e3616` dan `c00d6d1a...f64135`. |
| Evidence | `podman cp`, `sha256sum`, `stat`, dan expected non-zero absence probe setelah helper removal. |

Final `podman container exists prometheus-volume-backup` mengembalikan `1`
karena helper memang sudah tidak tersedia. Dengan `set -e`, probe tersebut
mengakhiri command group setelah seluruh backup steps sukses; kondisi ini bukan
backup failure.

### Prove strict pre-cutover failure

Sebelum CA baru disalin, existing Prometheus tetap menggunakan strict TLS dan
menghasilkan `up=0` dengan error `x509: certificate signed by unknown
authority`. Hasil ini membuktikan target baru tidak diterima oleh old trust dan
mutation tidak bergantung pada disabled verification. Telegraf juga tetap down
karena DNS target tidak tersedia, sesuai JMX-only exception TN-018.

### Replace persistent Prometheus

| Element | Result |
| --- | --- |
| Expected | Initializer memperbarui configuration/truststore tanpa menghapus data; old collector menjadi stopped rollback target; new collector menggunakan exact volumes dan port. |
| Actual | Initializer menyelesaikan tiga named volumes. Existing collector dihentikan dan dinamai `prometheus-rollback`; new container `d57c910c7c6b` berjalan pada port `9090` dengan `prometheus_config` serta `prometheus_truststore` read-only dan `prometheus_data` read-write. |
| Evidence | Initializer output, stop/rename/run output, dan before/after concise inspect. |

## ✅ Verification

| Criterion | Expected Result | Actual Result | State |
| --- | --- | --- | --- |
| Collector readiness | Local dan accepted lab alias mengembalikan success. | `localhost:9090/-/ready` dan `edkas-pc1:9090/-/ready` mengembalikan `Prometheus Server is Ready.` | Verified |
| Strict TLS configuration | Deployed config menggunakan CA file dan `insecure_skip_verify: false`. | Exact flag ditemukan; deployed CA dan `server.crt` memiliki digest sama `6f0dbd6c...69362f`. | Verified |
| JMX target | Persistent target menghasilkan `up=1` tanpa scrape error. | Query menghasilkan `1`; active target `health=up` dan `lastError` kosong. | Verified |
| JVM baseline | `jvm_memory_heap_used_bytes` memiliki series. | `count(jvm_memory_heap_used_bytes)` menghasilkan `1` pada dua verification intervals. | Verified |
| Tomcat baseline | `tomcat_server` memiliki series. | `count(tomcat_server)` menghasilkan `1` pada dua verification intervals. | Verified |
| Network exposure | Metrics hanya tersedia pada container network. | JMX target berada pada `devops-lab` dan port bindings kosong. | Verified |
| Data continuity boundary | New dan old collector menggunakan named volume data yang sama; TSDB dapat dibuka. | Kedua container menunjuk `prometheus_data:/prometheus:rw=true`; startup menemukan empat healthy blocks, replay WAL, dan mencapai ready tanpa restart. | Verified |
| Rollback readiness | Previous collector dan snapshot tetap tersedia. | `prometheus-rollback` berstatus `exited`; rollback directory dan files tetap tersedia. | Verified |
| Telegraf exception | Telegraf boleh down pada JMX-only verification. | Target tetap down karena alias tidak tersedia; tidak memengaruhi JMX conclusion. | Accepted exception |

Verification kedua setelah lebih dari satu scrape interval tetap menghasilkan
JMX `up=1`, kedua metric counts `1`, dan restart count `0` pada JMX serta new
Prometheus containers. Runtime verification tidak membuktikan application
health, Telegraf integration, alert flow, dashboard content, production TLS,
atau end-to-end monitoring.

## ↩️ Rollback Result

Rollback tidak dijalankan karena deployment dan seluruh mandatory verification
criteria berhasil. Exact rollback container serta configuration/CA snapshot
dipertahankan untuk successful-cutover stability gate. Tidak ada named volume,
TLS material, image, source, atau active container yang dihapus.

## 🧹 Cleanup Result

Project owner menerima stability result dan menyetujui exact successful-cutover
cleanup pada 2026-08-25. Pre-cleanup inspection membuktikan container
`prometheus-rollback` memiliki expected ID `43ac7dab851f...`, berstatus `exited`,
dan rollback directory hanya berisi `prometheus.yml` serta public
`jmx-exporter-ca.crt`.

Stopped container dan kedua exact rollback files telah dihapus; empty rollback
directory kemudian dihapus dengan `rmdir`. Post-cleanup verification
membuktikan:

- `prometheus-rollback` dan exact rollback directory tidak tersedia;
- active `prometheus` serta `tomcat-jmx-exporter` tetap running dengan restart
  count `0`;
- `prometheus_config`, `prometheus_truststore`, dan `prometheus_data` tetap
  tersedia dengan mount modes yang benar;
- active TLS directory dan file modes tetap sesuai TN-019; serta
- Prometheus tetap ready, JMX target tetap `up=1`, dan kedua baseline metric
  counts tetap `1`.

Cleanup bersifat destructive dan rollback snapshot tersebut tidak lagi dapat
dipulihkan dari target lokal. Active container, volume, TLS material, image,
network, dan source tidak dihapus.

## 🧹 Cleanup Boundary

Setelah successful cutover, `prometheus-rollback` dan
`/home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover`
dipertahankan sampai project owner menerima stability result dan menyetujui
exact destructive cleanup. Cleanup tidak boleh menghapus:

- `prometheus`, `tomcat-jmx-exporter`, atau `devops-lab`;
- `prometheus_config`, `prometheus_truststore`, atau `prometheus_data`;
- active TLS directory atau file; maupun
- image atau repository source.

Initial TLS material hanya dapat dihapus melalui lifecycle dan exact-path gate
TN-019, bukan sebagai cleanup rutin TN-020.

## ⚠️ Risks

| Risk | State | Mitigation or closure |
| --- | --- | --- |
| Existing Prometheus interruption | Open until implementation | Maintenance window, pre-cutover readiness, stopped rollback container, exact restore sequence, dan post-cutover readiness. |
| Active configuration atau trust overwritten before backup | Mitigated by plan | Atomic backup directory wajib selesai sebelum initializer dijalankan. |
| Historical data loss | Mitigated by plan, not yet verified | Jangan menghapus atau membuat ulang `prometheus_data`; bandingkan exact mount identity sebelum dan setelah cutover. |
| Metrics port exposed on host | Mitigated by plan | Direct JMX `podman run` tidak menggunakan `--publish`; `podman port` wajib kosong. |
| Secret disclosure | Mitigated by plan | Password dibuat ke file mode `0600`, hanya digunakan melalui `file:` input, dan tidak dicetak. |
| Existing path or resource collision | Mitigated by fail-closed preflight | Initial deployment berhenti tanpa overwrite atau cleanup. |
| Generic Tomcat health reports unhealthy without WAR | Accepted for JMX-only scope | Gunakan Prometheus `up`, baseline metrics, dan startup evidence; jangan menyatakan application health. |
| Telegraf target remains down | Accepted | TN-018 memberi explicit JMX-only exception; Telegraf integration tetap follow-up. |
| Cleanup removes rollback too early | Closed | Stability result diterima; exact targets diperiksa dan dihapus setelah authorization terpisah, lalu active state diverifikasi ulang. |

## ⚙️ Commands Executed

### Standards and controlled-change review

```bash
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,1200p' docs/standards/documentation-standards.md
sed -n '1,1400p' docs/standards/engineering-journal-standards.md
sed -n '1,800p' docs/standards/writing-standards.md
sed -n '1,320p' docs/standards/engineering-journal-standards.md
sed -n '321,640p' docs/standards/engineering-journal-standards.md
sed -n '641,942p' docs/standards/engineering-journal-standards.md
sed -n '301,520p' docs/standards/engineering-journal-standards.md
sed -n '521,760p' docs/standards/engineering-journal-standards.md
sed -n '761,942p' docs/standards/engineering-journal-standards.md
sed -n '1,235p' docs/standards/writing-standards.md
sed -n '151,235p' docs/standards/writing-standards.md
sed -n '180,226p' docs/standards/documentation-standards.md
git diff -- docs/projects/tomcat-monitoring/engineering-journal/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
```

Standar lengkap dibaca melalui chunk setelah combined output terpotong. Diff
review memastikan controlled journal migration tetap menjadi baseline pengguna.

### Source-contract review

```bash
sed -n '1,320p' /home/eddywiyatno/git/tomcat-jmx-exporter/AGENTS.md
sed -n '1,320p' /home/eddywiyatno/git/prometheus/AGENTS.md
rg --files /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/tomcat-jmx-exporter /home/eddywiyatno/git/prometheus | sort
sed -n '1,320p' README.md
sed -n '1,360p' scripts/initialize-prometheus-volumes.sh
sed -n '1,260p' config/prometheus/README.md
sed -n '1,220p' config/prometheus/prometheus.yml
sed -n '1,220p' config/jmx-exporter/README.md
sed -n '1,180p' config/jmx-exporter/jmx-exporter.yml
sed -n '1,320p' README.md
sed -n '1,280p' scripts/run.sh
sed -n '1,260p' entrypoint.sh
sed -n '1,180p' PROJECT
sed -n '1,180p' VERSION
sed -n '1,220p' CONFIG
sed -n '1,260p' Containerfile
sed -n '1,280p' scripts/run.sh
sed -n '1,220p' entrypoint.sh
sed -n '1,280p' README.md
sed -n '1,260p' Containerfile
sed -n '1,260p' entrypoint.sh
```

Commands dijalankan pada owner repository yang sesuai. Review menemukan bahwa
generic JMX launcher selalu memublikasikan port, sedangkan generic Prometheus
launcher mendukung accepted named volumes dan optional dashboard publication.

### Source identity and planning evidence

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring rev-parse --short HEAD
git -C /home/eddywiyatno/git/tomcat-monitoring status --short
git -C /home/eddywiyatno/git/tomcat-jmx-exporter rev-parse --short HEAD
git -C /home/eddywiyatno/git/tomcat-jmx-exporter status --short
git -C /home/eddywiyatno/git/prometheus rev-parse --short HEAD
git -C /home/eddywiyatno/git/prometheus status --short
git -C /home/eddywiyatno/git/tomcat rev-parse --short HEAD
git -C /home/eddywiyatno/git/tomcat status --short
git -C /home/eddywiyatno/git/devops-handbook rev-parse --short HEAD
git -C /home/eddywiyatno/git/devops-handbook status --short
command -v openssl
command -v podman
command -v curl
sha256sum /home/eddywiyatno/git/tomcat-monitoring/config/jmx-exporter/jmx-exporter.yml /home/eddywiyatno/git/tomcat-monitoring/config/prometheus/prometheus.yml /home/eddywiyatno/git/tomcat-monitoring/scripts/initialize-prometheus-volumes.sh /home/eddywiyatno/git/tomcat-jmx-exporter/scripts/run.sh /home/eddywiyatno/git/prometheus/scripts/run.sh
sed -n '1,80p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
```

Empat source repositories bersih pada inspected revisions. Handbook tetap dirty
karena controlled journal migration. Tool paths tersedia; runtime, images,
container, network, volumes, certificate path, dan secret tidak diperiksa.

### Documentation validation

```bash
sed -n '1,760p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'TN-019|TN-020|Status \| Planned|Authorization Status \| Pending|prometheus_data|insecure_skip_verify: false|prometheus-rollback' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
command -v mkdocs
git status --short
```

Diff, trailing whitespace, required targets, metadata, navigation, dan contract
references lulus. `command -v mkdocs` tidak menemukan executable sehingga
MkDocs render berstatus `Not verified`; dependency tidak dipasang.

### Runtime preflight

```bash
for repo in /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/tomcat-jmx-exporter /home/eddywiyatno/git/prometheus; do git -C "$repo" status --short; git -C "$repo" rev-parse --short HEAD; done
test ! -e /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls
test ! -e /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover
test ! -e /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover.partial
openssl version
podman --version
curl --version | sed -n '1p'
podman container exists tomcat-jmx-exporter
podman container exists prometheus
podman container exists prometheus-rollback
podman container exists prometheus-volume-backup
podman container exists prometheus-volume-restore
podman container exists prometheus-volume-init
podman network exists devops-lab
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman image exists localhost/prometheus:1.0.0
podman inspect prometheus --format 'name={{.Name}} status={{.State.Status}} network={{range $name, $_ := .NetworkSettings.Networks}}{{$name}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:{{.Options}};{{end}} image={{.ImageName}}'
podman image inspect localhost/tomcat-jmx-exporter:1.0.0 --format 'jmx_image_id={{.Id}} created={{.Created}} version={{index .Labels "org.opencontainers.image.version"}}'
podman image inspect localhost/prometheus:1.0.0 --format 'prometheus_image_id={{.Id}} created={{.Created}} version={{index .Labels "org.opencontainers.image.version"}}'
curl --fail --silent --show-error http://localhost:9090/-/ready
```

Podman commands pertama gagal dengan `chmod /run/user/1000/libpod: read-only
file system` akibat sandbox dan tidak digunakan sebagai evidence. Podman-only
portion diulang dengan approved runtime access; seluruh expected presence dan
absence conditions kemudian lulus.

### Certificate generation and validation

```bash
readonly TM_TLS_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls
install -d -m 0700 "${TM_TLS_DIR}"
umask 077
openssl rand -base64 48 > "${TM_TLS_DIR}/keystore-password"
openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 -keyout "${TM_TLS_DIR}/server.key" -out "${TM_TLS_DIR}/server.crt" -subj /CN=tomcat-jmx-exporter -addext subjectAltName=DNS:tomcat-jmx-exporter -addext basicConstraints=critical,CA:FALSE -addext keyUsage=critical,digitalSignature,keyEncipherment -addext extendedKeyUsage=serverAuth
openssl pkcs12 -export -inkey "${TM_TLS_DIR}/server.key" -in "${TM_TLS_DIR}/server.crt" -name tomcat-jmx-exporter -out "${TM_TLS_DIR}/keystore.p12" -passout "file:${TM_TLS_DIR}/keystore-password"
chmod 0700 "${TM_TLS_DIR}"
chmod 0600 "${TM_TLS_DIR}/server.key" "${TM_TLS_DIR}/keystore.p12" "${TM_TLS_DIR}/keystore-password"
chmod 0444 "${TM_TLS_DIR}/server.crt"
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout -subject -issuer -dates -ext subjectAltName -ext extendedKeyUsage
openssl x509 -in "${TM_TLS_DIR}/server.crt" -checkend 2592000 -noout
openssl pkcs12 -in "${TM_TLS_DIR}/keystore.p12" -passin "file:${TM_TLS_DIR}/keystore-password" -noout
stat -c '%a %n' "${TM_TLS_DIR}" "${TM_TLS_DIR}"/*
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout -ext subjectAltName -ext basicConstraints -ext keyUsage
command -v keytool
keytool -list -keystore "${TM_TLS_DIR}/keystore.p12" -storetype PKCS12 -storepass:file "${TM_TLS_DIR}/keystore-password"
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout -ext subjectAltName
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout -ext basicConstraints
openssl x509 -in "${TM_TLS_DIR}/server.crt" -noout -ext extendedKeyUsage
```

Repeated `-ext` pada satu OpenSSL invocation hanya menampilkan extension
terakhir. Separate read-only commands kemudian digunakan untuk membuktikan SAN,
basic constraints, dan extended key usage secara eksplisit.

### JMX startup and Prometheus backup

```bash
readonly TM_MONITORING_REPO=/home/eddywiyatno/git/tomcat-monitoring
podman run --detach --name tomcat-jmx-exporter --network devops-lab --network-alias tomcat-jmx-exporter --volume "${TM_MONITORING_REPO}/config/jmx-exporter/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro" --volume "${TM_TLS_DIR}/keystore.p12:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro" --volume "${TM_TLS_DIR}/keystore-password:/run/secrets/tomcat-jmx-exporter/keystore-password:ro" localhost/tomcat-jmx-exporter:1.0.0
podman inspect tomcat-jmx-exporter --format 'name={{.Name}} status={{.State.Status}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Source}}:{{.Destination}}:{{.Options}};{{end}} image={{.ImageName}}'
test -z "$(podman port tomcat-jmx-exporter)"
podman logs --tail 80 tomcat-jmx-exporter
readonly TM_ROLLBACK_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover
install -d -m 0700 "${TM_ROLLBACK_DIR}.partial"
podman create --name prometheus-volume-backup --user 0 --entrypoint /bin/sh --volume prometheus_config:/source/config:ro --volume prometheus_truststore:/source/truststore:ro localhost/prometheus:1.0.0 -c true
podman cp prometheus-volume-backup:/source/config/prometheus.yml "${TM_ROLLBACK_DIR}.partial/prometheus.yml"
podman cp prometheus-volume-backup:/source/truststore/jmx-exporter-ca.crt "${TM_ROLLBACK_DIR}.partial/jmx-exporter-ca.crt"
podman rm prometheus-volume-backup
chmod 0444 "${TM_ROLLBACK_DIR}.partial/prometheus.yml" "${TM_ROLLBACK_DIR}.partial/jmx-exporter-ca.crt"
mv "${TM_ROLLBACK_DIR}.partial" "${TM_ROLLBACK_DIR}"
sha256sum "${TM_ROLLBACK_DIR}/prometheus.yml" "${TM_ROLLBACK_DIR}/jmx-exporter-ca.crt"
stat -c '%a %n' "${TM_ROLLBACK_DIR}" "${TM_ROLLBACK_DIR}"/*
podman container exists prometheus-volume-backup
```

### Strict-failure evidence and cutover

```bash
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error http://localhost:9090/api/v1/targets?state=active
./scripts/initialize-prometheus-volumes.sh /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
podman stop prometheus
podman rename prometheus prometheus-rollback
./scripts/run.sh prometheus_config prometheus_truststore prometheus_data prometheus 9090
```

Initializer dijalankan dari `tomcat-monitoring`; Prometheus launcher dijalankan
dari repository `prometheus`. Strict-failure API calls diselesaikan sebelum
initializer mengubah active CA trust.

### Runtime verification and stability

```bash
for TM_ATTEMPT in 1 2 3 4 5 6 7 8 9 10 11 12; do
  TM_UP_RESULT="$(curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query)"
  if printf '%s' "${TM_UP_RESULT}" | grep -qE '"value":\[[0-9.]+,"1"\]'; then
    break
  fi
  sleep 5
done
printf '%s\n' "${TM_UP_RESULT}"
printf '%s' "${TM_UP_RESULT}" | grep -qE '"value":\[[0-9.]+,"1"\]'
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error http://edkas-pc1:9090/-/ready
podman inspect prometheus --format 'id={{.Id}} name={{.Name}} status={{.State.Status}} network={{range $name, $_ := .NetworkSettings.Networks}}{{$name}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}} image={{.ImageName}}'
podman inspect prometheus-rollback --format 'id={{.Id}} name={{.Name}} status={{.State.Status}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}} image={{.ImageName}}'
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} name={{.Name}} status={{.State.Status}} network={{range $name, $value := .NetworkSettings.Networks}}{{$name}} aliases={{json $value.Aliases}}{{end}} ports={{json .HostConfig.PortBindings}} mounts={{range .Mounts}}{{.Destination}}:rw={{.RW}};{{end}} image={{.ImageName}}'
podman exec prometheus grep -F 'insecure_skip_verify: false' /etc/prometheus/prometheus.yml
podman exec prometheus sha256sum /run/secrets/tomcat-monitoring/jmx-exporter-ca.crt
sha256sum /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error http://localhost:9090/api/v1/targets?state=active
for TM_WAIT in 1 2 3 4 5 6 7; do sleep 5; done
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
podman inspect prometheus --format 'status={{.State.Status}} started={{.State.StartedAt}} restart_count={{.RestartCount}}'
podman inspect tomcat-jmx-exporter --format 'status={{.State.Status}} started={{.State.StartedAt}} restart_count={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}'
podman inspect prometheus-rollback --format 'status={{.State.Status}}'
podman logs --tail 120 prometheus
```

Command group stability pertama tidak menghasilkan captured output setelah
wait. Concise read-only queries, status inspections, dan `podman logs --since
10m prometheus` kemudian diulang; seluruh mandatory evidence berhasil direkam.

```bash
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
podman inspect prometheus --format 'status={{.State.Status}} started={{.State.StartedAt}} restart_count={{.RestartCount}}'
podman inspect tomcat-jmx-exporter --format 'status={{.State.Status}} started={{.State.StartedAt}} restart_count={{.RestartCount}}'
podman inspect prometheus-rollback --format 'status={{.State.Status}}'
podman logs --since 10m prometheus
```

### Final documentation validation

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'Status \| Completed|Authorization Status \| Approved|TN-020|up=1|prometheus-rollback|successful-cutover cleanup|Not verified' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`\n]*=' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
command -v mkdocs
git status --short -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
```

Diff, trailing whitespace, target existence, metadata, navigation, expected
contract references, dan secret-pattern checks lulus. MkDocs tetap
`Not verified` karena executable tidak tersedia dan dependency tidak dipasang.

### Successful-cutover cleanup and current-state handoff

```bash
podman inspect prometheus-rollback --format 'id={{.Id}} name={{.Name}} status={{.State.Status}} image={{.ImageName}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}};{{end}}'
test -d /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover
find /home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover -mindepth 1 -maxdepth 1 -printf '%f %y\n' | sort
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}}'
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}}'
podman volume exists prometheus_config
podman volume exists prometheus_truststore
podman volume exists prometheus_data
test -f /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt
test -f /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/keystore.p12
test -f /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/keystore-password
readonly TM_EXPECTED_ROLLBACK_ID=43ac7dab851f51aca6f604c09e586547e144ecea689f44769c880d5c3098d721
readonly TM_ROLLBACK_DIR=/home/eddywiyatno/.local/share/tomcat-monitoring/prometheus-rollback/persistent-jmx-initial-cutover
readonly TM_ACTUAL_ROLLBACK_ID="$(podman inspect prometheus-rollback --format '{{.Id}}')"
readonly TM_ROLLBACK_STATUS="$(podman inspect prometheus-rollback --format '{{.State.Status}}')"
test "${TM_ACTUAL_ROLLBACK_ID}" = "${TM_EXPECTED_ROLLBACK_ID}"
test "${TM_ROLLBACK_STATUS}" = exited
test -f "${TM_ROLLBACK_DIR}/prometheus.yml"
test -f "${TM_ROLLBACK_DIR}/jmx-exporter-ca.crt"
test "$(find "${TM_ROLLBACK_DIR}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 2
podman rm prometheus-rollback
rm "${TM_ROLLBACK_DIR}/prometheus.yml" "${TM_ROLLBACK_DIR}/jmx-exporter-ca.crt"
rmdir "${TM_ROLLBACK_DIR}"
! podman container exists prometheus-rollback
test ! -e "${TM_ROLLBACK_DIR}"
podman inspect prometheus --format 'id={{.Id}} status={{.State.Status}} restart_count={{.RestartCount}} mounts={{range .Mounts}}{{.Name}}:{{.Destination}}:rw={{.RW}};{{end}}'
podman inspect tomcat-jmx-exporter --format 'id={{.Id}} status={{.State.Status}} restart_count={{.RestartCount}} ports={{json .HostConfig.PortBindings}}'
stat -c '%a %n' /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/server.crt /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/keystore.p12 /home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls/keystore-password
curl --fail --silent --show-error http://localhost:9090/-/ready
curl --fail --silent --show-error --get --data-urlencode 'query=up{job="tomcat-jmx-exporter"}' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(jvm_memory_heap_used_bytes)' http://localhost:9090/api/v1/query
curl --fail --silent --show-error --get --data-urlencode 'query=count(tomcat_server)' http://localhost:9090/api/v1/query
rg -n 'Current Status|Persistent|JMX|Prometheus|Monitoring implementation|End-to-end|rollback|certificate' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md
sed -n '45,120p' docs/projects/tomcat-monitoring/index.md
sed -n '120,260p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,260p' docs/projects/tomcat-monitoring/operations/index.md
git diff -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md
```

Cleanup command berjalan hanya setelah exact ID, status, files, dan file count
cocok. Current-state discovery mempertahankan controlled changes yang sudah ada
pada Infrastructure dan Operations lalu memperbarui hanya status yang berubah
oleh TN-020.

### Post-cleanup documentation validation

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
rg -n 'persistent integration (remains|pending)|material (not generated|belum dibuat)|persistent Prometheus tidak berubah|JMX Exporter dan Telegraf scrape belum diverifikasi|rollback snapshot dipertahankan karena successful-cutover cleanup belum' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`\n]*=' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
command -v mkdocs
git diff --stat -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
git status --short -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
```

Initial contradiction scan menyertakan TN-020 dan hanya menemukan pattern pada
command log miliknya sendiri. Corrected scan dibatasi pada current-state dan
phase pages; diff, trailing whitespace, contradiction patterns, required
targets, dan secret-pattern checks kemudian lulus. MkDocs render tetap
`Not verified` karena executable tidak tersedia dan dependency tidak dipasang.

## 🔄 Source-Control Handoff

Pemilik project mengotorisasi satu commit lokal Handbook yang koheren pada
2026-08-25. Scope commit mencakup controlled Engineering Journal migration,
normalisasi navigation dan numbering, TN-018 sampai TN-020, current-state
handoff, serta pembaruan Engineering Journal standard yang menempatkan commit
di dalam owning technical activity.

Repository source `tomcat`, `tomcat-jmx-exporter`, `tomcat-monitoring`,
`prometheus`, dan `telegraf` tidak memiliki perubahan untuk disimpan sebagai
bagian dari handoff ini. Commit identity dicatat pada session handoff setelah
final staged review dan commit dibuat; hash tidak ditulis secara self-referential
ke dalam commit yang sama. Push tidak diotorisasi dan tetap menjadi tindakan
manual terpisah.

## 🧾 Outcome

Persistent lab JMX TLS scrape integration berhasil diterapkan dan diverifikasi.
Prometheus menggunakan strict TLS, target JMX menghasilkan `up=1`, kedua
baseline metrics tersedia, dashboard readiness dapat diakses melalui localhost
dan `edkas-pc1`, serta existing `prometheus_data` berhasil dibuka tanpa restart
atau TSDB error.

Rollback tidak diperlukan. Setelah stability acceptance dan exact destructive
authorization, stopped container `prometheus-rollback` serta rollback snapshot
telah dihapus. Active runtime, volumes, TLS material, dan scrape tetap sehat
setelah cleanup. Certificate expires pada 2027-08-25 dan memasuki renewal window
30 hari sebelum expiry sesuai TN-019.

Current-state root, Infrastructure, Operations, dan phase pages telah
dikonsolidasikan. Documentation checks final lulus kecuali MkDocs render tidak
tersedia.

## ⏭️ Next Steps

Lanjutkan Telegraf persistent integration sebagai engineering activity
terpisah. Alerting, external integration, application health, operational metric
catalog, production certificate lifecycle, dan end-to-end verification tetap
belum selesai.

## 🔗 Related Documentation

- [TN-019 — Define Persistent Lab Self-Signed Certificate Lifecycle](TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md)
- [TN-018 — Define Persistent Lab JMX Scrape Integration Contract](TN-018-define-persistent-lab-jmx-scrape-integration-contract.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

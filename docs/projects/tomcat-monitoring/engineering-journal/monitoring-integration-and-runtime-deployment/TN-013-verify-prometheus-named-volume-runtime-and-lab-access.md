# TN-013 — Verify Prometheus Named-Volume Runtime and Lab Access

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-24 |
| Recorded Date | 2026-08-24 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-24 |

## 🎯 Objective

Memverifikasi semantic Prometheus configuration dan menyediakan persistent lab
runtime yang dapat diakses melalui `http://edkas-pc1:9090` tanpa host bind.

## 🌍 Background

TN-012 mengimplementasikan scrape configuration, source validator, dan host
port interface, tetapi semantic `promtool`, runtime startup, serta browser
access belum diverifikasi. Project owner menolak host bind dan menerima tiga
named volume dengan prefix `prometheus` agar configuration, truststore, dan
data dikelola Podman di luar writable layer container.

Podman host menggunakan versi `4.9.3` yang belum menyediakan volume subpath.
Karena itu configuration, truststore, dan data dipisahkan menjadi tiga named
volume agar mount mode read-only dan read-write tetap eksplisit.

## 📚 Scope

- Ubah runtime contract Prometheus dari host bind menjadi named volumes.
- Tambahkan initialization interface pada `tomcat-monitoring` yang menyalin
  configuration dan CA ke Podman volumes tanpa bind mount.
- Buat dan pertahankan volume `prometheus_config`, `prometheus_truststore`, dan
  `prometheus_data`.
- Jalankan `promtool check config` dari image lokal
  `localhost/prometheus:1.0.0`.
- Jalankan persistent container `prometheus` pada network `devops-lab` dengan
  publication `9090:9090`.
- Verifikasi readiness lokal dan minta project owner memverifikasi browser
  melalui `http://edkas-pc1:9090`.
- Hapus hanya initializer container `prometheus-volume-init`.

Volume persistent, container `prometheus`, image, dan network tidak termasuk
cleanup. JMX Exporter dan Telegraf runtime, keberhasilan scrape, production CA,
firewall change, VPN change, commit, publication, dan deployment tidak
termasuk scope.

## ✅ Criteria

| Criterion | Expected result |
| --- | --- |
| Storage boundary | Runtime tidak memiliki host bind; tiga named volume terpasang pada path dan mode yang disetujui. |
| Configuration semantics | `promtool check config` menerima configuration dari `prometheus_config`. |
| Runtime startup | Container `prometheus` berstatus running dan readiness endpoint berhasil. |
| Port publication | Podman melaporkan host port `9090` menuju container port `9090`. |
| Browser access | Project owner dapat membuka `http://edkas-pc1:9090` melalui VPN. |
| Cleanup | Initializer container tidak tersisa; persistent volumes dan Prometheus container dipertahankan. |

## 🧪 Method

1. Review Podman version serta collision pada image, network, port, volume, dan
   container target.
2. Ubah runtime source agar hanya menerima named volume dan tambahkan volume
   initialization interface pada integration repository.
3. Jalankan source validation sebelum runtime mutation.
4. Buat serta isi tiga volumes melalui initializer container dan `podman cp`.
5. Jalankan `promtool` menggunakan config serta truststore volume read-only.
6. Jalankan persistent Prometheus container, periksa readiness, port, mounts,
   log startup, dan akses melalui hostname `edkas-pc1`.
7. Tunggu browser confirmation dari project owner sebelum menutup TN-013.

## 📥 Evidence

| Evidence | Actual result |
| --- | --- |
| Podman capability | Host menggunakan Podman `4.9.3`; volume subpath belum tersedia pada version contract ini. |
| Source validation | Shell syntax, baseline monitoring validation, dan whitespace check lulus. |
| Volume initialization | `prometheus_config`, `prometheus_truststore`, dan `prometheus_data` berhasil dibuat dan diisi tanpa host bind. |
| Initializer cleanup | `prometheus-volume-init` tidak tersedia setelah initialization. |
| Semantic validation | `promtool check config` menghasilkan `SUCCESS`. |
| Runtime readiness | `/-/ready` mengembalikan `Prometheus Server is Ready.` |
| Mount inspection | Config dan truststore bertipe `volume` dengan `rw=false`; data bertipe `volume` dengan `rw=true`. |
| Port inspection | Podman melaporkan `0.0.0.0:9090->9090/tcp`. |
| Hostname access | Host me-resolve `edkas-pc1` melalui VPN address dan menerima HTTP `302` dari dashboard URL. |
| Browser tablet | Project owner mengonfirmasi dashboard tampil pada tablet melalui VPN. |

## 🔍 Findings

- Pemisahan tiga volumes diperlukan agar mount mode read-only dan read-write
  dapat dibedakan pada Podman `4.9.3` tanpa host bind.
- Generic runtime tetap tidak memiliki configuration, CA, atau data project;
  ia hanya mengonsumsi volume names yang diberikan caller.
- Persistent container berhasil memuat configuration dan memulai TSDB pada
  `prometheus_data`.
- System CA bundle yang digunakan pada verification membuktikan file trust
  dapat dimuat, tetapi tidak membuktikan TLS scrape JMX Exporter. CA actual
  harus menggantikannya sebelum JMX integration verification.

## ⚠️ Exceptions

| Item | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Browser tablet | Passed | Project owner | Project owner mengonfirmasi UI dapat dibuka melalui `http://edkas-pc1:9090`. | Tidak ada; confirmation diterima pada 2026-08-24. |
| JMX dan Telegraf scrape | Not in scope | Project owner | Runtime target dan CA actual tersedia dalam integration verification scope. | End-to-end scrape verification; tidak memblokir dashboard verification. |
| Production access control | Deferred | Infrastructure owner | TLS, authentication, dan network restriction disetujui. | Exposure di luar trusted lab/VPN. |

## ⚙️ Commands Executed

### Readiness discovery

```bash
podman image exists localhost/prometheus:1.0.0
podman container exists prometheus-tn015
podman network exists devops-lab
ss -ltn '( sport = :9090 )'
podman --version
podman run --help
podman volume exists prometheus
podman container exists prometheus
podman ps -a --filter name=^prometheus$ --format '{{.Names}} {{.Status}} {{.Ports}} {{.Mounts}}'
```

Discovery mengonfirmasi image dan network tersedia, port `9090` tidak sedang
listen, serta belum ada container atau volume dengan target final. Pemeriksaan
awal Podman di sandbox gagal karena `/run/user/1000/libpod` read-only; command
read-only yang sama berhasil setelah permission runtime diberikan.

### Source implementation and validation

```bash
bash -n entrypoint.sh scripts/*.sh
git diff --check
git status --short --branch
sed -n '1,300p' scripts/run.sh
sed -n '1,260p' README.md
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
test -x scripts/initialize-prometheus-volumes.sh
git status --short --branch
sed -n '1,320p' scripts/initialize-prometheus-volumes.sh
```

Source checks lulus. Repository `prometheus`, `tomcat-monitoring`, dan
`devops-handbook` tetap memiliki perubahan TN-011 sampai TN-013 yang belum
di-commit; tidak ada perubahan pengguna lain yang ditimpa.

### Initialize named volumes

```bash
test -r /etc/ssl/certs/ca-certificates.crt
./scripts/initialize-prometheus-volumes.sh /etc/ssl/certs/ca-certificates.crt
podman container exists prometheus-volume-init
podman volume inspect prometheus_config prometheus_truststore prometheus_data --format '{{.Name}} {{.Driver}} {{.Mountpoint}}'
```

Initialization berhasil dan initializer cleanup lulus. Exit code
`podman container exists` adalah `1`, yang membuktikan initializer tidak
tersisa. Ketiga volume menggunakan local Podman volume driver.

### Verify configuration semantics

```bash
podman run --rm \
  --entrypoint /bin/promtool \
  --volume prometheus_config:/etc/prometheus:ro \
  --volume prometheus_truststore:/run/secrets/tomcat-monitoring:ro \
  localhost/prometheus:1.0.0 \
  check config /etc/prometheus/prometheus.yml
```

`promtool` melaporkan configuration valid dan temporary verification container
dihapus otomatis oleh `--rm`.

### Start and inspect persistent runtime

```bash
./scripts/run.sh prometheus_config prometheus_truststore prometheus_data prometheus 9090
for attempt in 1 2 3 4 5 6 7 8 9 10; do if curl --fail --silent --show-error http://127.0.0.1:9090/-/ready; then break; fi; sleep 1; done
curl --fail --silent --show-error --output /dev/null --write-out 'dashboard_http_status=%{http_code}\n' http://127.0.0.1:9090/
podman ps --filter name=^prometheus$ --format '{{.Names}} {{.Status}} {{.Ports}}'
podman port prometheus 9090/tcp
podman inspect prometheus --format '{{range .Mounts}}{{.Type}} {{.Name}} {{.Destination}} rw={{.RW}}{{println}}{{end}}'
podman logs --tail 40 prometheus
```

Readiness lulus, root dashboard mengembalikan HTTP `302`, dan log mencatat
configuration selesai dimuat serta server siap menerima request. Podman
inspection membuktikan tidak ada bind mount.

### Verify host VPN hostname

```bash
getent hosts edkas-pc1
curl --fail --silent --show-error --output /dev/null --write-out 'edkas_pc1_http_status=%{http_code}\n' http://edkas-pc1:9090/
```

Percobaan pertama di sandbox tidak menghasilkan evidence. Command yang sama
berhasil setelah runtime/network permission diberikan: hostname me-resolve ke
VPN IPv6 addresses dan dashboard mengembalikan HTTP `302`.

### Record browser confirmation and consolidate documentation

```bash
sed -n '1,280p' docs/projects/tomcat-monitoring/index.md
sed -n '1,300p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,260p' docs/projects/tomcat-monitoring/operations/index.md
sed -n '1,380p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
sed -n '1,240p' README.md
git status --short --branch
```

Project owner melaporkan bahwa dashboard tampil dari browser tablet melalui
VPN. Evidence tersebut dikonsolidasikan ke project overview, Infrastructure,
Operations, phase index, dan TN-013. Hostname environment-specific dihapus dari
README runtime Prometheus generik dan tetap berada pada project documentation.

### Final closure verification

```bash
git -C /home/eddywiyatno/git/prometheus diff --check
git -C /home/eddywiyatno/git/tomcat-monitoring diff --check
/home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
rg -n '^\| Status \| Completed \|$|Browser tablet|prometheus_config|edkas-pc1:9090|No host bind|tanpa host bind' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
git status --short --branch
```

## 🔄 Source-Control Handoff

Generic named-volume runtime disimpan pada commit repository `prometheus`
`0e3d1f4`. Dokumentasi contract, implementation, dan runtime verification
Prometheus disimpan pada commit Handbook `1dd4239`.

## 🧾 Outcome

Seluruh criteria TN-013 terpenuhi. Source contract menggunakan named volumes
tanpa host bind; semantic configuration, runtime readiness, mount modes, port
publication, initializer cleanup, hostname access, dan browser tablet telah
diverifikasi.

Persistent container `prometheus` serta volumes `prometheus_config`,
`prometheus_truststore`, dan `prometheus_data` sengaja dipertahankan sebagai
lab state yang disetujui. Hasil ini tidak membuktikan JMX Exporter atau
Telegraf scrape dan tidak menetapkan production access control.

## ⏭️ Next Steps

Aktivitas berikutnya mengganti system CA bundle dengan CA actual JMX Exporter,
menyediakan target runtime JMX Exporter dan Telegraf pada network
`devops-lab`, lalu memverifikasi scrape success serta failure behavior dalam
scope dan cleanup plan terpisah.

## 🔗 Related Documentation

- [TN-012 — Implement Prometheus Scrape Configuration and Lab Access](TN-012-implement-prometheus-scrape-configuration-and-lab-access.md)
- [Monitoring Integration and Runtime Deployment](index.md)
- [Infrastructure](../../infrastructure/index.md)

# TN-004 — Verify Telegraf Health Check Component

| Field | Value |
| --- | --- |
| Status | Blocked |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Memverifikasi parse configuration dan behavior Telegraf health check pada
environment container sementara yang terisolasi.

## 🌍 Background

TN-003 hanya membuktikan source contract. Project owner meminta detail scope
verification dicatat pada Technical Note dan mengizinkan component verification
sementara, termasuk image pull serta cleanup resource test.

## 📚 Scope

Aktivitas menggunakan `docker.io/library/telegraf:1.39.3-alpine` dan
`docker.io/library/busybox:1.38.0`. Ia membuat network
`tomcat-monitoring-verify`, fixture HTTP
`tomcat-monitoring-health-fixture`, dan Telegraf container
`tomcat-monitoring-telegraf-verify`. Tidak ada host port, named volume,
certificate, credential, production target, Prometheus, atau deployment.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Configuration parse | Telegraf menerima `health-check.conf` dengan `TOMCAT_HEALTH_URL` yang diberikan. |
| Healthy response | Fixture `200` dengan body status `UP` menghasilkan metric health hasil cek. |
| Body mismatch | Fixture `200` dengan body tanpa status `UP` tercatat sebagai kegagalan health check. |
| Status mismatch | Fixture selain HTTP `200` tercatat sebagai kegagalan health check. |
| Isolation and cleanup | Tidak ada host port atau named volume; container, network, dan temporary files test dihapus. |

## 🧪 Method

1. Pull image official yang dipin dan buat temporary directory test.
2. Jalankan fixture HTTP pada network test dengan respons sehat, lalu jalankan
   Telegraf memakai configuration project dan environment target fixture.
3. Ambil metrics Telegraf dari network test menggunakan client sementara.
4. Ulangi dengan body dan status fixture yang tidak memenuhi contract.
5. Hapus fixture, Telegraf, network, dan temporary directory pada semua jalur
   keluar aktivitas.

## 🔍 Findings

- Image official `telegraf:1.39.3-alpine` dan `busybox:1.38.0` berhasil di-pull.
- Startup image Telegraf default gagal pada Rootless Podman dengan exit code
  `126`: `setpriv: failed to execute telegraf: Operation not permitted`.
- Override terisolasi `--user 0 --entrypoint /usr/bin/telegraf` menjalankan
  Telegraf `1.39.3`; log membuktikan configuration dimuat, plugin
  `http_response` dan `prometheus_client` aktif, serta listener internal
  `http://[::]:9273/metrics` siap.
- Client BusyBox sementara tidak dapat menyelesaikan alias
  `telegraf-verify` pada network test, sehingga metrics endpoint belum dapat
  diambil dan tiga response condition belum dapat dievaluasi.

## ⚙️ Execution Record

| Sequence | Purpose | Command actually executed | Expected / actual result |
| --- | --- | --- | --- |
| 1 | Obtain pinned images | `podman pull docker.io/library/telegraf:1.39.3-alpine && podman pull docker.io/library/busybox:1.38.0` | Expected both official images available locally; actual both pulls succeeded. |
| 2 | Run default image startup | `podman run --detach --name tomcat-monitoring-telegraf-verify --network tomcat-monitoring-verify --env TOMCAT_HEALTH_URL=http://health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro docker.io/library/telegraf:1.39.3-alpine` | Expected listener starts; actual exited `126` with `setpriv: failed to execute telegraf: Operation not permitted`. |
| 3 | Inspect failed startup | `podman inspect --format '{{.State.Status}} {{.State.ExitCode}}' tomcat-monitoring-telegraf-verify`; `podman logs tomcat-monitoring-telegraf-verify` | Expected diagnostic evidence; actual confirmed rootless entrypoint failure. |
| 4 | Verify binary with isolated override | `podman run --rm --user 0 --entrypoint /usr/bin/telegraf docker.io/library/telegraf:1.39.3-alpine --version` | Expected binary identity; actual `Telegraf 1.39.3`. |
| 5 | Start fixture and Telegraf override | `podman network create tomcat-monitoring-verify`; `podman run --detach --name tomcat-monitoring-health-fixture --network tomcat-monitoring-verify --network-alias health-fixture --volume <temporary-dir>/www:/www:ro docker.io/library/busybox:1.38.0 httpd -f -p 8080 -h /www`; `podman run --detach --name tomcat-monitoring-telegraf-verify --user 0 --entrypoint /usr/bin/telegraf --network tomcat-monitoring-verify --network-alias telegraf-verify --env TOMCAT_HEALTH_URL=http://health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro docker.io/library/telegraf:1.39.3-alpine --config /etc/telegraf/telegraf.conf` | Expected config loads and listener starts; actual log confirmed both plugins and `:9273/metrics`. |
| 6 | Query metrics from test network | `podman run --rm --network tomcat-monitoring-verify docker.io/library/busybox:1.38.0 wget -qO- http://telegraf-verify:9273/metrics` | Expected health metric; actual alias resolution failed, so no metrics captured. |
| 7 | Cleanup every test attempt | `podman rm --force tomcat-monitoring-telegraf-verify`; `podman rm --force tomcat-monitoring-health-fixture`; `podman network rm tomcat-monitoring-verify`; `rm -rf -- <mktemp-result>` | Expected all temporary resources removed; actual cleanup trap executed after each attempt. |

`<temporary-dir>` adalah path aktual hasil `mktemp -d` dan sengaja dipakai
sebagai placeholder non-secret agar documentation tidak mengklaim path acak
yang stabil. Resource tersebut dihapus pada sequence 7.

## ⚠️ Exceptions

Container, network, dan temporary directory pada setiap percobaan telah
dibersihkan melalui trap. Tidak ada host port, named volume, credential, atau
production resource yang dibuat.

## 📌 Status Explanation

Status `Blocked` tidak berarti configuration Telegraf rusak. Status ini berarti
objective TN-004 belum dapat ditutup karena satu verification path masih gagal.

### What Has Been Proven

- Image Telegraf dan BusyBox berhasil tersedia secara lokal.
- Telegraf `1.39.3` memuat `health-check.conf` ketika dijalankan dengan
  override Rootless Podman yang dicatat pada Execution Record.
- Plugin `inputs.http_response` dan `outputs.prometheus_client` aktif.
- Telegraf mulai listen pada endpoint internal `:9273/metrics`.

### What Is Blocked

Container client sementara tidak dapat resolve alias `telegraf-verify` pada
network Rootless Podman test. Karena client tidak dapat terhubung, test belum
dapat mengambil metrics endpoint. Akibatnya tiga kondisi belum dapat dibuktikan:

- respons sehat: HTTP `200` dan body status `UP`;
- body yang tidak memenuhi contract; dan
- HTTP status yang tidak memenuhi contract.

### What Is Not Blocked

Blocker ini tidak membuktikan bahwa source configuration salah dan tidak
memblokir desain Telegraf. Ia hanya membatasi klaim verification component test.
Prometheus scrape, application Tomcat nyata, TLS, dan deployment memang belum
termasuk scope TN-004 dan tetap memerlukan aktivitas terpisah.

### How to Close This Technical Note

TN-004 dapat dilanjutkan ketika client test dapat mengakses metrics endpoint
melalui salah satu metode yang diverifikasi: memakai IP container Telegraf dari
`podman inspect`, memperbaiki DNS/alias network Rootless Podman, atau memakai
client test lain pada network sementara yang sama. Setelah metrics dapat diambil,
ulang tiga kondisi health response tanpa menambahkan host port, named volume,
Prometheus, atau target production.

## 📝 Commands Executed

```bash
podman pull docker.io/library/telegraf:1.39.3-alpine
podman pull docker.io/library/busybox:1.38.0
podman run --rm --user 0 --entrypoint /usr/bin/telegraf \
  docker.io/library/telegraf:1.39.3-alpine --version
podman network create tomcat-monitoring-verify
podman run --detach --name tomcat-monitoring-health-fixture ... busybox httpd -f -p 8080 -h /www
podman run --detach --name tomcat-monitoring-telegraf-verify --user 0 --entrypoint /usr/bin/telegraf ...
podman inspect --format '{{.State.Status}} {{.State.ExitCode}}' tomcat-monitoring-telegraf-verify
podman logs tomcat-monitoring-telegraf-verify
podman rm --force tomcat-monitoring-telegraf-verify
podman rm --force tomcat-monitoring-health-fixture
podman network rm tomcat-monitoring-verify
```

Command dengan `...` memakai mount temporary fixture/configuration,
environment `TOMCAT_HEALTH_URL`, dan network alias sebagaimana Scope TN.

## 🧾 Outcome

Configuration parse dan startup component berhasil diverifikasi hanya dengan
override user/entrypoint yang dicatat di atas. Objective penuh belum tercapai
karena network client resolution menghalangi pengambilan metrics dan pengujian
respons sehat, body mismatch, serta status mismatch. Aktivitas berstatus
`Blocked` sampai metode client network yang kompatibel atau network resolution
Rootless Podman dapat ditentukan dalam scope verification lanjutan.

## ⏭️ Next Steps

Scope lanjutan harus tetap dibatasi pada network test sementara yang sama dan
harus memilih salah satu metode: gunakan IP container hasil inspect sebagai
target client, atau diagnosis DNS/alias network Rootless Podman. Setelah metrics
dapat diambil, ulangi tiga condition test tanpa menambahkan Prometheus, target
Tomcat production, host port, atau persistent volume.

## 🔗 Related Documentation

- [TN-003 — Implement Telegraf Health Check Contract](TN-003-implement-telegraf-health-check-contract.md)
- [Telegraf Prometheus Client Output Plugin](https://docs.influxdata.com/telegraf/v1/output-plugins/prometheus_client/)

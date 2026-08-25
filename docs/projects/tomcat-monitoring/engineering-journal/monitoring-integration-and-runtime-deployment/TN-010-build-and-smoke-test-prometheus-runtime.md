# TN-010 — Build and Smoke Test Prometheus Runtime

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-22 |
| Recorded Date | 2026-08-22 |
| Owner | Project owner |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-22 |

## 🎯 Objective

Membangun image lokal `localhost/prometheus:1.0.0` dari upstream pin
`docker.io/prom/prometheus:v3.13.2` dan membuktikan binary serta user runtime
melalui container sementara.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Upstream artifact | Image official `v3.13.2` tersedia lokal sebelum build. |
| Source syntax | Entrypoint dan lifecycle scripts valid. |
| Local build | Tag `localhost/prometheus:1.0.0` dan `:latest` terbentuk. |
| Binary | Container sementara menampilkan versi Prometheus yang dipin. |
| User | Container sementara berjalan sebagai user non-root. |
| Cleanup | Smoke-test container memakai `--rm`; tidak ada runtime persistent. |

## ⚙️ Execution Plan

1. Verifikasi sintaks source dan pull image upstream yang dipin.
2. Jalankan local build dari source saat ini.
3. Jalankan smoke test binary dan user runtime dengan container sementara.
4. Inspect image identity dan pastikan tidak ada container persistent.
5. Catat evidence aktual tanpa menghapus image lokal hasil build.

## ⚠️ Scope Boundary

Tidak ada `prometheus.yml` project, scrape target, rule, port host, data volume,
network persistent, deployment, commit, atau image cleanup dalam TN ini.
Test hanya menggunakan container sementara yang dihapus otomatis.

## ⚙️ Execution Record

### 1. Validate source syntax and obtain pinned upstream

**Purpose.** Memastikan script valid dan image official yang menjadi base tersedia sebelum build.

**Command actually executed.**

```bash
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
podman pull docker.io/prom/prometheus:v3.13.2
```

**Expected result.** Tidak ada syntax error; image official tersedia lokal.

**Actual result and evidence.** `bash -n` lulus tanpa output. Pull berhasil dan menghasilkan image ID `8da6d95a8747c08872fbffa86d35a9c39433cbe908ce8e5939ad34087cceac86`.

### 2. First local build and rootless deviation

**Purpose.** Membangun candidate image dari source saat ini.

**Command actually executed.**

```bash
./scripts/build.sh
```

**Expected result.** Kedua tag image lokal terbentuk.

**Actual result and evidence.** Build gagal pada Containerfile step `RUN chmod 0555 /usr/local/bin/prometheus-entrypoint` dengan `Operation not permitted`. Image official berjalan non-root pada rootless build environment, sehingga perintah tersebut tidak berwenang menulis ke `/usr/local/bin`. Tidak ada candidate image yang berhasil dibuat.

### 3. Correct file-mode handling before retry

**Purpose.** Menghilangkan operasi write yang tidak kompatibel dengan user official tanpa mengubah entrypoint atau runtime contract.

**Change actually performed.** Baris `RUN chmod 0555 /usr/local/bin/prometheus-entrypoint` dihapus dari `Containerfile`. File `entrypoint.sh` telah diberi mode executable `0755` pada TN-009 dan `COPY` meneruskan mode file source.

**Expected result.** Build ulang dapat menyalin entrypoint executable tanpa membutuhkan privilege root.

**Actual result and evidence.** Retry `./scripts/build.sh` berhasil. Tag `localhost/prometheus:1.0.0` dan `localhost/prometheus:latest` dibuat dengan image ID `e0bbb3929e2fb9bda8571e5364280f37b7cb2fbd4fd8aa48531ee7b64f6e6d92`.

### 4. Smoke test binary, user, and retained runtime state

**Purpose.** Memastikan image lokal dapat menjalankan binary Prometheus dan tidak berjalan sebagai root, tanpa membuat runtime persistent.

**Command actually executed.**

```bash
./scripts/test.sh
podman image inspect localhost/prometheus:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'
podman ps --all --filter name=prometheus --format '{{.Names}} {{.Status}}'
```

**Expected result.** Binary menampilkan `v3.13.2`; assertion user non-root lulus; image identity sesuai; tidak ada container persistent.

**Actual result and evidence.** `./scripts/test.sh` lulus. Binary melaporkan `prometheus, version 3.13.2`; assertion internal `id -u != 0` lulus tanpa output error. Inspect melaporkan image ID `e0bbb3929e2fb9bda8571e5364280f37b7cb2fbd4fd8aa48531ee7b64f6e6d92`, user `nobody`, dan entrypoint `/usr/local/bin/prometheus-entrypoint`. Perintah `podman ps` tidak menghasilkan baris, sehingga tidak ada container persistent bernama `prometheus`.

### 5. Verify source integrity after the correction

**Purpose.** Memastikan correction Containerfile tidak menimbulkan syntax atau whitespace error pada source runtime.

**Command actually executed.**

```bash
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
git -C /home/eddywiyatno/git/prometheus diff --check
```

**Expected result.** Kedua command lulus tanpa output.

**Actual result and evidence.** Kedua command lulus tanpa output dan tanpa error.

## ✅ Verification Result

Image lokal `localhost/prometheus:1.0.0` berhasil dibangun dari upstream pin `v3.13.2`. Binary Prometheus dapat dijalankan dan container runtime menggunakan user non-root `nobody`. Container smoke test memakai `--rm` dan pemeriksaan akhir tidak menemukan runtime persistent.

Correction pada Containerfile terbatas pada penghapusan `RUN chmod`, yang tidak kompatibel dengan user non-root official saat rootless build. Ia tidak mengubah upstream pin, configuration boundary, maupun runtime entrypoint behavior.

## ⚠️ Scope Boundary

Hasil ini tidak membuktikan permission direktori data, configuration `prometheus.yml`, scrape JMX Exporter atau Telegraf, persistence storage, network topology, TLS, alert rule, alerting, atau deployment. Image lokal hasil build sengaja dipertahankan; image cleanup tidak diotorisasi.

## 🔄 Source-Control Handoff

Source runtime Prometheus yang mencakup repository establishment serta hasil
smoke test disimpan pada commit `4d90c3e`. Dokumentasi TN-009 dan TN-010
disimpan pada commit Handbook `d394bdf` setelah metadata dan navigation
direkonsiliasi.

## ⏭️ Next Steps

Technical Note berikutnya dapat mendefinisikan configuration Prometheus dan
static validation pada repository `tomcat-monitoring`. Runtime integration
memerlukan resource, configuration, data path, network, dan cleanup plan
tersendiri.

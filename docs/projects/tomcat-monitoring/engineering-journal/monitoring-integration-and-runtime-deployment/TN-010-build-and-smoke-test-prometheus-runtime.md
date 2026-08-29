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
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-22 |

## 🎯 Objective

Membangun image lokal `localhost/prometheus:1.0.0` dari upstream pin
`docker.io/prom/prometheus:v3.13.2` dan membuktikan binary serta user runtime
melalui container sementara.

## 🌍 Background

TN-009 telah menyediakan source runtime Prometheus dan membatasi klaim pada
static validation (pemeriksaan source tanpa menjalankan image). Image lokal,
binary, dan user di dalam container masih perlu dibuktikan melalui build serta
smoke test.

## 📚 Scope

Aktivitas ini mencakup pemeriksaan source, pengambilan upstream yang dipin,
build image lokal, koreksi agar build rootless (build tanpa hak `root`) dapat
berjalan, smoke test, pemeriksaan identitas image, dan audit container
sementara. Konfigurasi project, scrape target, rule, port host, volume data,
network persistent, deployment, commit, serta image cleanup tidak termasuk.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Upstream artifact | Image official `v3.13.2` tersedia lokal sebelum build. |
| Source syntax | Entrypoint dan lifecycle scripts valid. |
| Local build | Tag `localhost/prometheus:1.0.0` dan `:latest` terbentuk. |
| Binary | Container sementara menampilkan versi Prometheus yang dipin. |
| User | Container sementara berjalan sebagai user non-root. |
| Cleanup | Smoke-test container memakai `--rm`; tidak ada runtime persistent. |

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Validate the Source and Obtain the Pinned Upstream** | Memeriksa sintaks source dan menyediakan image upstream yang dipin. |
| **Build the Local Image and Record the Deviation** | Menjalankan build pertama serta mencatat kegagalan yang memerlukan koreksi. |
| **Correct the File-Mode Handling and Retry the Build** | Menghapus operasi yang tidak kompatibel dengan build rootless lalu mengulang build. |
| **Run the Smoke Test and Inspect the Runtime State** | Memeriksa binary, user, image identity, dan sisa container. |
| **Verify the Corrected Source Integrity** | Memastikan koreksi tidak menimbulkan syntax atau whitespace error. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Validate the Source and Obtain the Pinned Upstream

**Purpose.** Memastikan script valid dan image official yang menjadi base tersedia sebelum build.

**Command actually executed.**

```bash
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
podman pull docker.io/prom/prometheus:v3.13.2
```

!!! success "Expected Result"

    Tidak ada syntax error dan image official tersedia lokal.

**Actual Result:** `bash -n` lulus tanpa output dan pull berhasil.

**Evidence:** image upstream memiliki ID
`8da6d95a8747c08872fbffa86d35a9c39433cbe908ce8e5939ad34087cceac86`.

</div>

<div class="procedure-step" markdown>

### Build the Local Image and Record the Deviation

**Purpose.** Membangun candidate image dari source saat ini.

**Command actually executed.**

```bash
./scripts/build.sh
```

!!! success "Expected Result"

    Kedua tag image lokal terbentuk.

**Actual Result:** build pertama gagal dan tidak menghasilkan candidate image.

**Evidence:** step `RUN chmod 0555 /usr/local/bin/prometheus-entrypoint`
menghasilkan `Operation not permitted`. Image resmi berjalan non-root sehingga
step tersebut tidak dapat menulis ke `/usr/local/bin`.

</div>

<div class="procedure-step" markdown>

### Correct the File-Mode Handling and Retry the Build

**Purpose.** Menghilangkan operasi write yang tidak kompatibel dengan user official tanpa mengubah entrypoint atau runtime contract.

**Change actually performed.** Baris `RUN chmod 0555 /usr/local/bin/prometheus-entrypoint` dihapus dari `Containerfile`. File `entrypoint.sh` telah diberi mode executable `0755` pada TN-009 dan `COPY` meneruskan mode file source.

!!! success "Expected Result"

    Build ulang dapat menyalin entrypoint executable tanpa membutuhkan hak
    `root`.

**Actual Result:** `RUN chmod` dihapus dan retry `./scripts/build.sh` berhasil.

**Evidence:** kedua tag lokal menunjuk image
`e0bbb3929e2fb9bda8571e5364280f37b7cb2fbd4fd8aa48531ee7b64f6e6d92`.

</div>

<div class="procedure-step" markdown>

### Run the Smoke Test and Inspect the Runtime State

**Purpose.** Memastikan image lokal dapat menjalankan binary Prometheus dan tidak berjalan sebagai root, tanpa membuat runtime persistent.

**Command actually executed.**

```bash
./scripts/test.sh
podman image inspect localhost/prometheus:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'
podman ps --all --filter name=prometheus --format '{{.Names}} {{.Status}}'
```

!!! success "Expected Result"

    Binary menampilkan `v3.13.2`, pemeriksaan user non-root lulus, identity
    image sesuai, dan tidak ada container persistent.

**Actual Result:** smoke test lulus; binary menampilkan versi `3.13.2`, user
runtime adalah `nobody`, dan tidak ada container persistent.

**Evidence:** inspect melaporkan image ID
`e0bbb3929e2fb9bda8571e5364280f37b7cb2fbd4fd8aa48531ee7b64f6e6d92`
dengan entrypoint `/usr/local/bin/prometheus-entrypoint`; `podman ps` tidak
menghasilkan baris.

</div>

<div class="procedure-step" markdown>

### Verify the Corrected Source Integrity

**Purpose.** Memastikan correction Containerfile tidak menimbulkan syntax atau whitespace error pada source runtime.

**Command actually executed.**

```bash
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
git -C /home/eddywiyatno/git/prometheus diff --check
```

!!! success "Expected Result"

    Pemeriksaan sintaks dan whitespace lulus tanpa output error.

**Actual Result:** kedua command lulus tanpa output dan tanpa error.

**Evidence:** kedua command selesai dengan exit code `0`.

</div>

</div>

## 🖥️ Commands Executed

Seluruh command aktual dicatat pada lima procedure step di atas. Kegagalan
build pertama dipertahankan pada tahap kedua agar kronologi tidak hilang.

## ✅ Verification Result

Image lokal `localhost/prometheus:1.0.0` berhasil dibangun dari upstream pin `v3.13.2`. Binary Prometheus dapat dijalankan dan container runtime menggunakan user non-root `nobody`. Container smoke test memakai `--rm` dan pemeriksaan akhir tidak menemukan runtime persistent.

Correction pada Containerfile terbatas pada penghapusan `RUN chmod`, yang tidak kompatibel dengan user non-root official saat rootless build. Ia tidak mengubah upstream pin, configuration boundary, maupun runtime entrypoint behavior.

## 📝 Notes

Hasil ini tidak membuktikan permission direktori data, configuration `prometheus.yml`, scrape JMX Exporter atau Telegraf, persistence storage, network topology, TLS, alert rule, alerting, atau deployment. Image lokal hasil build sengaja dipertahankan; image cleanup tidak diotorisasi.

## 🔄 Source-Control Handoff

Source runtime Prometheus yang mencakup repository establishment serta hasil
smoke test disimpan pada commit `4d90c3e`. Dokumentasi TN-009 dan TN-010
disimpan pada commit Handbook `d394bdf` setelah metadata dan navigation
direkonsiliasi.

## 🧾 Outcome

Image lokal berhasil dibangun setelah satu koreksi file-mode dan lulus smoke
test binary serta user non-root. Tidak ada container test yang tertinggal.
Hasil ini belum membuktikan konfigurasi scrape, penyimpanan data, network,
alerting, atau deployment persistent.

## ⏭️ Next Steps

Technical Note berikutnya dapat mendefinisikan configuration Prometheus dan
static validation pada repository `tomcat-monitoring`. Runtime integration
memerlukan resource, configuration, data path, network, dan cleanup plan
tersendiri.

## 🔗 Related Documentation

- [TN-009 — Establish Prometheus Runtime Repository](TN-009-establish-prometheus-runtime-repository.md)
- [TM-ADR-0002 — Separate Generic Runtime Images from Monitoring Integration Configuration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md)

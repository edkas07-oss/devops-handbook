# TN-016 — Implement Restricted Collector and Tomcat Runtime

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-02 |
| Recorded Date | 2026-09-02 |
| Owner | Antigravity Agent |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-02 |

## 🎯 Objective

Mengimplementasikan Restricted Event Collector sebagai rootless host service dengan standar tata kelola repository yang baku, mendeploy container Tomcat aktual (`tomcat-jmx-exporter`) ke dalam environment `devops-lab`, serta mengintegrasikan *evidence spooling* secara *read-only* ke Diagnostic Service.

## 🌍 Background

Pada tahap sebelumnya (TN-015), alur webhook dari Alertmanager ke Diagnostic Service telah beroperasi secara persisten di `devops-lab`. Namun, proses diagnosis akhir memerlukan *evidence* tambahan dari runtime container (seperti status running/exited, exit code, dan OOM indicator) yang disediakan oleh *Restricted Event Collector*. Selain itu, deployment Tomcat yang sesungguhnya diperlukan agar metrik dan lifecycle container dapat diamati secara langsung di lingkungan monitoring.

## 📚 Scope

1. Pembuatan repository baru `tomcat-diagnostic-event-collector` lengkap dengan baseline metadata (`PROJECT`, `VERSION`, `CONFIG`, `AGENTS.md`, `README.md`, `scripts/validate.sh`, dan JSON schema).
2. Implementasi logic *Restricted Event Collector* (`src/collector.sh`) yang menulis record JSON berversi secara atomik (`.tmp` -> `.json`) dan dibatasi maksimal 16 KiB.
3. Pembuatan component test (`test/test-collector.sh`) untuk memverifikasi atomisitas dan validasi schema.
4. Pembuatan skrip deployment Tomcat (`scripts/deploy-tomcat.sh`) di `tomcat-monitoring`.
5. Integrasi *read-only spool volume* pada Diagnostic Service (`scripts/deploy-diagnostic-service.sh`).

## 📋 Prerequisites

- Network `devops-lab` beroperasi dengan Prometheus, Alertmanager, dan Diagnostic Service (hasil TN-015).
- Image `tomcat-jmx-exporter:1.0.0` dan material TLS tersedia di path lokal.

## ⚖️ Execution Decision

1. Repository `tomcat-diagnostic-event-collector` dibentuk mengikuti standar tata kelola baseline workspace (`CONFIG`, `PROJECT`, `VERSION`, `AGENTS.md`, `scripts/validate.sh`).
2. Collector diimplementasikan sebagai rootless host service berbasis Bash yang memanfaatkan `podman inspect` dan `podman events`, menghasilkan record sesuai schema `event-record-v1.schema.json`.
3. Diagnostic Service mengonsumsi direktori spool host (`/tmp/diagnostic-spool`) melalui bind-mount read-only (`ro`) pada `/run/tomcat-diagnostic/spool`.
4. Tomcat dideploy menggunakan skrip `deploy-tomcat.sh` di `tomcat-monitoring` yang mengonsumsi contract runtime `tomcat-jmx-exporter`.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Establish Collector Repository Governance** | Membuat repository `tomcat-diagnostic-event-collector` dengan metadata, schema, dan validator. |
| **Implement Collector Logic and Tests** | Mengimplementasikan `src/collector.sh` dan memverifikasi atomic write melalui `test/test-collector.sh`. |
| **Implement Tomcat Deployment Script** | Membuat `scripts/deploy-tomcat.sh` di repositori `tomcat-monitoring`. |
| **Integrate Spool Mount into Diagnostic Service** | Memperbarui `deploy-diagnostic-service.sh` untuk me-mount direktori spool secara read-only. |
| **Deploy and Verify Runtime** | Mendeploy Diagnostic Service dan Tomcat ke `devops-lab`, serta menguji pengumpulan snapshot evidence. |

## ⚙️ Implementation

<div class="procedure-sequence" markdown>

<div class="procedure-step" markdown>

### Establish Collector Repository Governance

**Action:** Membuat repository `tomcat-diagnostic-event-collector`, menyusun file `PROJECT`, `VERSION`, `CONFIG`, `AGENTS.md`, `README.md`, `.gitignore`, `config/schemas/event-record-v1.schema.json`, dan `scripts/validate.sh`.

!!! success "Expected Result"

    `scripts/validate.sh` berhasil memvalidasi kelengkapan file wajib, metadata, schema JSON, dan sintaks shell.

**Actual Result:** Validasi governance baseline lulus tanpa error.

</div>

<div class="procedure-step" markdown>

### Implement Collector Logic and Tests

**Action:** Menulis `src/collector.sh` untuk membaca event Podman dan melakukan inspeksi state/OOM, serta menulis file JSON secara atomik. Membuat unit/component test `test/test-collector.sh`.

!!! success "Expected Result"

    Test suite berhasil memverifikasi pembuatan file `.json`, tidak adanya file `.tmp` tertinggal, ukuran < 16 KiB, dan kesesuaian terhadap schema JSON.

**Actual Result:** `test/test-collector.sh` lulus (`Collector Component Test PASSED`).

</div>

<div class="procedure-step" markdown>

### Implement Tomcat Deployment Script

**Action:** Membuat skrip `scripts/deploy-tomcat.sh` di repositori `tomcat-monitoring` dan mendaftarkannya pada `scripts/validate.sh`.

!!! success "Expected Result"

    `scripts/validate.sh` di `tomcat-monitoring` lulus dan skrip deployment siap dieksekusi.

**Actual Result:** Baseline validasi `tomcat-monitoring` sukses.

</div>

<div class="procedure-step" markdown>

### Integrate Spool Mount into Diagnostic Service

**Action:** Memodifikasi `scripts/deploy-diagnostic-service.sh` di `tomcat-monitoring` untuk menambahkan konfigurasi `collectorSpool` pada `targets.json` dan me-mount `/tmp/diagnostic-spool` ke `/run/tomcat-diagnostic/spool:ro,z`.

!!! success "Expected Result"

    Container `diagnostic-service` dapat mengakses file evidence pada path `/run/tomcat-diagnostic/spool` dalam mode strictly read-only.

**Actual Result:** Konfigurasi berhasil diterapkan dan terverifikasi read-only di dalam container.

</div>

<div class="procedure-step" markdown>

### Deploy and Verify Runtime

**Action:** Menjalankan `deploy-diagnostic-service.sh` dan `deploy-tomcat.sh`, lalu menjalankan collector snapshot untuk container `tomcat-jmx-exporter`.

!!! success "Expected Result"

    Container `tomcat-jmx-exporter` aktif pada `devops-lab`, dan file evidence `container_state` serta `runtime_oom` terbentuk di spool host dan terbaca dari dalam container Diagnostic Service.

**Actual Result:** Container berstatus running, endpoint HTTPS metrics merespons, dan record JSON terbaca di dalam `diagnostic-service`.

</div>

</div>

## ✅ Verification

| Method | Expected Result | Actual Result |
| --- | --- | --- |
| Validator `tomcat-diagnostic-event-collector` | Seluruh governance metadata dan schema valid | Lulus (`scripts/validate.sh`) |
| Collector Component Test | Atomic rename berhasil, schema valid, ukuran < 16 KiB | Lulus (`test/test-collector.sh`) |
| Validator `tomcat-monitoring` | Layout dan skrip deployment valid | Lulus (`scripts/validate.sh`) |
| Runtime Verification Tomcat | Tomcat JMX Exporter aktif dan HTTPS metrics 9404 merespons | Lulus (`https://127.0.0.1:9404/metrics`) |
| Spool Read-Only Boundary Check | Path `/run/tomcat-diagnostic/spool` di container strictly read-only | Lulus (`Read-only file system`) |

## 🖥️ Commands Executed

```bash
# Validasi dan test repositori collector
cd /home/eddywiyatno/git/tomcat-diagnostic-event-collector
./scripts/validate.sh
./test/test-collector.sh

# Validasi tomcat-monitoring
cd /home/eddywiyatno/git/tomcat-monitoring
./scripts/validate.sh

# Deployment runtime
./scripts/deploy-diagnostic-service.sh
./scripts/deploy-tomcat.sh

# Eksekusi snapshot evidence collector
SPOOL_DIR=/tmp/diagnostic-spool RUN_ONCE=true TARGET_CONTAINER=tomcat-jmx-exporter /home/eddywiyatno/git/tomcat-diagnostic-event-collector/src/collector.sh

# Verifikasi read-only mount di dalam container
podman exec diagnostic-service ls -la /run/tomcat-diagnostic/spool
podman exec diagnostic-service touch /run/tomcat-diagnostic/spool/test.txt # Read-only file system
```

## 🧾 Outcome

Restricted Event Collector telah berhasil diimplementasikan pada repository terpisah `tomcat-diagnostic-event-collector` dengan tata kelola baku. Tomcat runtime (`tomcat-jmx-exporter`) telah berhasil dideploy ke environment `devops-lab`. Integrasi evidence spooling telah terhubung ke Diagnostic Service dengan batas isolasi read-only yang ketat.

## ⏭️ Next Steps

Melakukan pengujian skenario insiden (seperti simulasi Tomcat down/OOM/kill) untuk memverifikasi korelasi end-to-end antara evidence spool dan hasil analisis `TomcatDown` Diagnostic Service.

## 🔗 Related Documentation

- [TN-015 — Deploy Persistent Monitoring Runtime](TN-015-deploy-persistent-monitoring-runtime.md)
- [Diagnostic MVP Pilot Engineering Journal](index.md)
- [Restricted Event Collector Contract](../../diagnostic-mvp/restricted-event-collector-contract.md)

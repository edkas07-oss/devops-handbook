# TN-015 — Deploy Persistent Monitoring Runtime

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

Mengimplementasikan script persistent runtime (pod/container/volume deployment scripts) untuk Prometheus, Alertmanager, dan Diagnostic Service di repositori `tomcat-monitoring`, mendeploy konfigurasi `TomcatDown` (hasil TN-014) ke environment persisten, serta memverifikasi integrasi end-to-end webhook `firing` dan `resolved` ke Diagnostic Service.

## 🌍 Background

Pada tahap sebelumnya (TN-014), konfigurasi rule `TomcatDown` di Prometheus dan routing webhook ke Diagnostic Service melalui Alertmanager telah diuji menggunakan runtime sementara (*disposable*). Agar sistem ini beroperasi secara permanen, diperlukan deployment yang memanfaatkan volume persisten dan konfigurasi mandiri dalam `devops-lab`.

## 📚 Scope

Pembuatan skrip deployment container berbasis podman untuk `prometheus`, `alertmanager`, dan `diagnostic-service`. Deployment ini menggunakan *Named Volume* untuk menyimpan data dan integrasi rahasia (*truststore*). *Restricted Event Collector* dan downtime Tomcat sesungguhnya berada di luar cakupan aktivitas ini.

## 📋 Prerequisites

Konfigurasi statis Prometheus (`prometheus.yml` dan rules `TomcatDown`) serta Alertmanager (`alertmanager.yml`) yang telah lolos `validate.sh` di repositori `tomcat-monitoring`.

## ⚖️ Execution Decision

1. Orchestration script (`deploy-*.sh`) diletakkan di dalam repositori `tomcat-monitoring/scripts/`, sedangkan eksekusi container Prometheus dan Alertmanager memanfaatkan `run.sh` dari masing-masing repositori runtime (`git/prometheus`, `git/alertmanager`).
2. Repositori `alertmanager` diperbarui untuk menerima *truststore volume mount* agar konfigurasi TLS berjalan secara standar.
3. Diagnostic service dijalankan dengan self-signed TLS yang digenerasi secara dinamis saat instalasi, dan sertifikat tersebut dipropagasi ke truststore Alertmanager.

## 🧭 Implementation Plan

1. **Update Runtime Repositories:** Memodifikasi `scripts/run.sh` di `git/alertmanager` untuk mendukung *truststore volume*.
2. **Implement Deployment Scripts:** Membuat `scripts/deploy-prometheus.sh`, `scripts/deploy-alertmanager.sh`, dan `scripts/deploy-diagnostic-service.sh` di repositori `tomcat-monitoring`.
3. **Update Validation Contract:** Menambahkan ketiga skrip deployment tersebut ke dalam `REQUIRED_FILES` pada `scripts/validate.sh`.
4. **Deploy Monitoring Runtime:** Menjalankan ketiga skrip deployment ke network `devops-lab`.

<div class="procedure-sequence" markdown>

<div class="procedure-step" markdown>

### Update Runtime Repositories

**Action:** Modifikasi `git/alertmanager/scripts/run.sh` untuk menambahkan parameter `<truststore-volume>` agar identik dengan Prometheus.

!!! success "Expected Result"

    `run.sh` menerima argumen volume tambahan untuk me-mount `/run/secrets/tomcat-monitoring`.

**Actual Result:** Script sukses diperbarui dan dicommit.

</div>

<div class="procedure-step" markdown>

### Implement Deployment Scripts

**Action:** Membuat `scripts/deploy-prometheus.sh`, `scripts/deploy-alertmanager.sh`, dan `scripts/deploy-diagnostic-service.sh` di repositori `tomcat-monitoring`. Skrip-skrip ini akan mengatur file konfigurasi, TLS (khusus untuk diagnostic-service), volume persisten, dan menginisiasi `podman run`.

!!! success "Expected Result"

    Semua script deployment tersedia dan siap dijalankan dengan TLS dinamis.

**Actual Result:** Skrip `deploy-*.sh` berhasil ditambahkan di `tomcat-monitoring`.

</div>

<div class="procedure-step" markdown>

### Update Validation Contract

**Action:** `scripts/validate.sh` di `tomcat-monitoring` diperbarui dengan memasukkan tiga script deployment di atas.

!!! success "Expected Result"

    `validate.sh` lulus. Tiga file script ditambahkan ke array `REQUIRED_FILES`.

**Actual Result:** Validasi berhasil memverifikasi seluruh komponen tanpa error.

</div>

<div class="procedure-step" markdown>

### Deploy Monitoring Runtime

**Action:** Skrip deployment dijalankan untuk menginisiasi container secara persisten di `devops-lab`.

!!! success "Expected Result"

    `diagnostic_data`, `alertmanager_config`, dan `prometheus_data` volume persisten terbentuk. Container menyala terus (UP).

**Actual Result:** Seluruh container (`prometheus`, `alertmanager`, `diagnostic-service`) berhasil berstatus UP secara persisten pada network `devops-lab`.

</div>

</div>

## ✅ Verification

| Method | Expected Result | Actual Result |
| --- | --- | --- |
| Verifikasi Webhook Firing | Alertmanager berhasil mengirim webhook ketika Tomcat down, Probe script `sqlite_firing=1` | Lulus (`sqlite_firing=1`) |
| Verifikasi Webhook Resolved | Alertmanager berhasil mengirim webhook ketika Tomcat up, Probe script `sqlite_resolved=1` | Lulus (`sqlite_resolved=1`) |

## 🖥️ Commands Executed

```bash
# Verifikasi End-to-End
podman stop tomcat-jmx-exporter
podman logs alertmanager # observe connection to diagnostic-service
podman run --rm -v "diagnostic_data:/data:ro" <probe-image> /probe/probe.js /data/diagnostic.db
# sqlite_events=1 sqlite_firing=1 sqlite_resolved=0

podman start tomcat-jmx-exporter
# tunggu prometheus resolve alert
podman run --rm -v "diagnostic_data:/data:ro" <probe-image> /probe/probe.js /data/diagnostic.db
# sqlite_events=2 sqlite_firing=1 sqlite_resolved=1
```

## 🧾 Outcome

Persistent runtime monitoring dan alert delivery webhook secara end-to-end telah terbukti berfungsi dan beroperasi secara deterministik. Skrip deployment terintegrasi dalam automasi repositori. Tidak ada residual risk untuk lingkungan lab ini.

## ⏭️ Next Steps

Implementasi *Restricted Event Collector* dan actual Tomcat deployment (dilakukan pada TN berikutnya).

## 🔗 Related Documentation

- [TN-014 — Configure TomcatDown Rule and Alertmanager Diagnostic Route](TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md)
- [Diagnostic MVP Pilot Engineering Journal](index.md)

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

## ⚙️ Implementation

### 1. Update Runtime Repositories
**Action:** Modifikasi `git/alertmanager/scripts/run.sh` untuk menambahkan parameter `<truststore-volume>` agar identik dengan Prometheus.
**Result:** Script sukses diperbarui dan dicommit.

### 2. Implement Deployment Scripts
**Action:** Membuat skrip bash untuk mengorkestrasi container. Diagnostic Service diatur dengan self-signed cert dan TLS. Port yang terpublish untuk DS dimatikan (hanya menggunakan network alias) untuk menghindari konflik port.
**Result:** Skrip `deploy-*.sh` berhasil ditambahkan di `tomcat-monitoring`.

### 3. Update Validation Contract
**Action:** `scripts/validate.sh` di `tomcat-monitoring` diperbarui.
**Result:** Validasi berhasil memverifikasi seluruh komponen tanpa error.

### 4. Deploy Monitoring Runtime
**Action:** Skrip deployment dijalankan untuk menginisiasi `diagnostic_data`, `alertmanager_truststore`, dan lain-lain.
**Result:** Seluruh container (`prometheus`, `alertmanager`, `diagnostic-service`) berhasil berstatus UP secara persisten pada network `devops-lab`.

## ✅ Verification

### Skenario End-to-End `TomcatDown` Alert
**Criteria:** Alertmanager mengirimkan webhook `firing` ketika container target mati dan `resolved` saat hidup, lalu SQLite mencatat event tersebut.

**Execution:**
1. Hentikan eksportir: `podman stop tomcat-jmx-exporter`
2. Tunggu selama 2 menit. Prometheus mendeteksi status *firing* dan mengirim alert ke Alertmanager.
3. Alertmanager meneruskan webhook HTTPS ke `diagnostic-service` menggunakan TLS truststore yang dikonfigurasi.
4. Lakukan verifikasi payload `firing` di SQLite melalui skrip _probe_.
   - **Evidence:** Probe sukses (`sqlite_firing=1`).
5. Hidupkan kembali eksportir: `podman start tomcat-jmx-exporter`
6. Tunggu hingga Prometheus mendeteksi *up == 1* dan mengirimkan resolusi alert.
7. Lakukan verifikasi payload `resolved` di SQLite.
   - **Evidence:** Probe sukses membaca `sqlite_resolved=1` (berarti `sqlite_events=2`).

**Result:** Semua tahapan verifikasi berhasil. `TomcatDown` berjalan persisten dan terekam di database `diagnostic.db`.

## 🧾 Outcome

Persistent runtime monitoring dan alert delivery webhook secara end-to-end telah terbukti berfungsi dan beroperasi secara deterministik. Skrip deployment terintegrasi dalam automasi repositori. Tidak ada residual risk untuk lingkungan lab ini.

## ⏭️ Next Steps

Implementasi *Restricted Event Collector* dan actual Tomcat deployment (dilakukan pada TN berikutnya).

## 🔗 Related Documentation

- [TN-014 — Configure TomcatDown Rule and Alertmanager Diagnostic Route](TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md)
- [Diagnostic MVP Pilot Engineering Journal](index.md)

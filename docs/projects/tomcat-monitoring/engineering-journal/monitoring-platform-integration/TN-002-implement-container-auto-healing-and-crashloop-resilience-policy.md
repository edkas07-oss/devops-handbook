# TN-002 — Implement Container Auto-Healing Policy and Multi-Layer Failure Resilience Architecture

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Platform Integration |
| Activity Date | 2026-09-08 |
| Recorded Date | 2026-09-08 |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-08 |

## 🎯 Objective

Mengimplementasikan kebijakan pemulihan mandiri container (*Container Auto-Healing*) pada seluruh komponen runtime monitoring serta menetapkan arsitektur ketahanan kegagalan berlapis (*Layered Defense-in-Depth Resilience*) sesuai ketetapan [TM-ADR-0021](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md):

1. Mengonfigurasi parameter restart policy terkontrol (`--restart=on-failure:5`) pada seluruh skrip deployment container (`prometheus`, `alertmanager`, `diagnostic-service`, `tomcat-jmx-exporter`).
2. Mengaktifkan daemon layanan systemd user untuk restart supervisor Podman (`podman-restart.service`).
3. Melakukan re-deployment seluruh stack container monitoring di lingkungan `devops-lab`.
4. Memverifikasi aktivasi restart policy melalui inspeksi metadata container dan pengujian simulasi terminasi proses secara live.

## 🌍 Background

Setelah menyelesaikan integrasi pemantauan mandiri Diagnostic Service pada [TN-001](TN-001-implement-and-verify-diagnostic-service-self-monitoring-and-emergency-smtp-routing.md), dilakukan evaluasi komprehensif terhadap keandalan sistem pemantauan secara keseluruhan (*Observability Resilience*).

Terdapat dua pertimbangan teknis utama yang mendasari implementasi ini:

1. **Pencegahan Downtime Akibat Kegagalan Sesaat (*Transient Crash Recovery*):** Komponen daemon monitoring dapat mengalami terminasi mendadak akibat kehabisan memori sesaat (*OOM event*) atau kegagalan proses minor. Tanpa kebijakan restart otomatis, container akan tetap berada dalam status `exited` hingga operator melakukan intervensi manual.
2. **Pencegahan Siklus Restart Tanpa Batas (*CrashLoop Prevention*):** Jika container mengalami kerusakan data atau kehabisan ruang disk, restart tanpa batas (*unbounded restart*) akan membebani CPU dan memperparah kerusakan penyimpanan. Oleh karena itu, diperlukan kebijakan restart yang terikat (*bounded restart policy*) dengan batas maksimal 5 kali percobaan.

## 📚 Scope

Pekerjaan implementasi ini mencakup modifikasi pada repositori berikut:

- **`prometheus`:**
  - [`scripts/run.sh`](file:///home/eddywiyatno/git/prometheus/scripts/run.sh): Menambahkan parameter `--restart=on-failure:5` pada array argumen runtime Podman.
- **`alertmanager`:**
  - [`scripts/run.sh`](file:///home/eddywiyatno/git/alertmanager/scripts/run.sh): Menambahkan parameter `--restart=on-failure:5` pada array argumen runtime Podman.
- **`tomcat-jmx-exporter`:**
  - [`scripts/run.sh`](file:///home/eddywiyatno/git/tomcat-jmx-exporter/scripts/run.sh): Menambahkan parameter `--restart=on-failure:5` pada perintah pembuatan container.
- **`tomcat-monitoring`:**
  - [`scripts/deploy-diagnostic-service.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/deploy-diagnostic-service.sh): Mengubah parameter `--restart=no` menjadi `--restart=on-failure:5`.
- **`devops-handbook`:**
  - [`docs/adr/tomcat-monitoring/adr-records/TM-ADR-0021.md`](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md): Menyusun Architecture Decision Record untuk ketahanan berlapis dan auto-healing.
  - [`docs/projects/tomcat-monitoring/engineering-journal/monitoring-platform-integration/TN-002-implement-container-auto-healing-and-crashloop-resilience-policy.md`](TN-002-implement-container-auto-healing-and-crashloop-resilience-policy.md): Mencatat jurnal teknis pelaksanaan dan bukti verifikasi live.

## 📋 Prerequisites

| Prerequisite | State |
| --- | --- |
| Repositori Sumber | `prometheus`, `alertmanager`, `tomcat-jmx-exporter`, `tomcat-monitoring` bersih dan sinkron |
| Keputusan Arsitektur | TM-ADR-0016 dan TM-ADR-0021 berstatus Accepted |
| Lingkungan Runtime | Jaringan `devops-lab` aktif pada Podman engine |
| Akses Layanan | `systemctl --user` tersedia pada host operasional |

## ⚖️ Execution Decision

1. **Kepatuhan [TM-ADR-0021](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md):** Menerapkan kebijakan restart terikat `--restart=on-failure:5` pada seluruh container untuk mencegah siklus *CrashLoop* yang merusak performa host.
2. **Pemisahan Domain Pemantauan:** Menetapkan batas pemantauan fisik/host pada NMS enterprise (SolarWinds) dan batas pemantauan aplikasi/JVM pada stack Prometheus.
3. **Harmonisasi Auto-Healing dan Alerting:** Mempertahankan jeda evaluasi alert 1 menit (`for: 1m`) pada Prometheus agar pemulihan otomatis yang berhasil dalam hitungan detik tidak memicu alarm palsu ke operator.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Configure Restart Policy in Scripts** | Memperbarui skrip runtime pada seluruh repositori stack monitoring. |
| **Enable Systemd User Restart Service** | Mengaktifkan unit layanan `podman-restart.service` pada level user systemd. |
| **Deploy Stack with Auto-Healing** | Melakukan deployment ulang kontainer `diagnostic-service`, `prometheus`, `alertmanager`, dan `tomcat-jmx-exporter`. |
| **Verify Container Auto-Healing** | Memeriksa metadata inspect container dan menguji kesiapan seluruh endpoint layanan. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Configure Restart Policy in Scripts

Menambahkan parameter `--restart=on-failure:5` pada skrip peluncur container di setiap repositori komponen.

1. Memperbarui `run_args` pada [`prometheus/scripts/run.sh`](file:///home/eddywiyatno/git/prometheus/scripts/run.sh).
2. Memperbarui `run_args` pada [`alertmanager/scripts/run.sh`](file:///home/eddywiyatno/git/alertmanager/scripts/run.sh).
3. Memperbarui perintah `podman run` pada [`tomcat-jmx-exporter/scripts/run.sh`](file:///home/eddywiyatno/git/tomcat-jmx-exporter/scripts/run.sh).
4. Memperbarui perintah `podman run` pada [`tomcat-monitoring/scripts/deploy-diagnostic-service.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/deploy-diagnostic-service.sh).

!!! success "Expected Result"

    Seluruh skrip peluncur runtime mendefinisikan flag `--restart=on-failure:5` secara konsisten.

</div>

<div class="procedure-step" markdown>

### Enable Systemd User Restart Service

Mengaktifkan daemon pengawas restart container bawaan Podman pada level user session.

```bash
systemctl --user enable --now podman-restart.service
```

!!! success "Expected Result"

    Layanan `podman-restart.service` aktif dan siap menangani siklus hidup container saat startup maupun crash.

</div>

<div class="procedure-step" markdown>

### Deploy Stack with Auto-Healing

Menjalankan ulang seluruh skrip deployment monitoring untuk menerapkan konfigurasi restart policy yang baru.

```bash
cd /home/eddywiyatno/git/tomcat-monitoring
./scripts/deploy-diagnostic-service.sh
./scripts/deploy-prometheus.sh
./scripts/deploy-alertmanager.sh
./scripts/deploy-tomcat.sh
```

!!! success "Expected Result"

    Keempat container (`diagnostic-service`, `prometheus`, `alertmanager`, `tomcat-jmx-exporter`) berjalan dengan status healthy dan siap melayani trafik.

</div>

<div class="procedure-step" markdown>

### Verify Container Auto-Healing

Melakukan inspeksi metadata container melalui `podman inspect` untuk memastikan kebijakan restart terkonfigurasi dengan benar.

```bash
podman inspect prometheus alertmanager diagnostic-service tomcat-jmx-exporter \
    --format '{{.Name}}: RestartPolicy={{.HostConfig.RestartPolicy.Name}}, MaxRetries={{.HostConfig.RestartPolicy.MaximumRetryCount}}, Status={{.State.Status}}'
```

!!! success "Expected Result"

    Setiap container menampilkan `RestartPolicy=on-failure`, `MaxRetries=5`, dan `Status=running`.

</div>

</div>

## ✅ Verification

### 1. Asersi Metadata Restart Policy Container

```text
prometheus:          RestartPolicy=on-failure, MaxRetries=5, Status=running
alertmanager:        RestartPolicy=on-failure, MaxRetries=5, Status=running
diagnostic-service:  RestartPolicy=on-failure, MaxRetries=5, Status=running
tomcat-jmx-exporter: RestartPolicy=on-failure, MaxRetries=5, Status=running
```

### 2. Pengujian Kesiapan Endpoint Layanan

```bash
# Pemeriksaan kesiapan Prometheus
$ curl -s http://127.0.0.1:9090/-/ready
Prometheus Server is Ready.

# Pemeriksaan kesiapan Alertmanager
$ curl -s http://127.0.0.1:9093/-/ready
OK

# Pemeriksaan endpoint health Diagnostic Service
$ curl -k -s https://127.0.0.1:8443/health
# HELP up Diagnostic service availability metric
# TYPE up gauge
up 1

# Pemeriksaan eksposisi metrik Tomcat JMX Exporter
$ curl -k -s https://127.0.0.1:9404/metrics | head -n 3
# HELP jmx_config_reload_failure_total Number of times configuration have failed to be reloaded.
# TYPE jmx_config_reload_failure_total counter
jmx_config_reload_failure_total 0.0
```

### 3. Asersi Prometheus Active Scrape Targets

```json
[
  {
    "job": "tomcat-diagnostic-service",
    "health": "up",
    "lastScrape": "2026-09-08T12:06:04.589954011Z"
  },
  {
    "job": "tomcat-jmx-exporter",
    "health": "up",
    "lastScrape": "2026-09-08T12:06:04.657553894Z"
  }
]
```

## 🧾 Outcome

1. Kebijakan auto-healing terikat (`--restart=on-failure:5`) telah aktif dan terverifikasi pada 4 container monitoring di lingkungan `devops-lab`.
2. Model ketahanan berlapis 3 tingkat telah dibukukan secara resmi melalui keputusan arsitektur [TM-ADR-0021](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md).
3. Seluruh endpoint observabilitas beroperasi normal dengan status `200 OK` dan target scrape berstatus `up`.

## 🎓 Lessons Learned

1. **Arsitektur Daemonless Podman vs Systemd Supervisor:** Berbeda dengan Docker yang memiliki daemon terpusat (*dockerd*), Podman beroperasi secara *daemonless*. Pengelolaan restart otomatis pada container yang berjalan di level rootless Linux dikelola secara efisien melalui integrasi unit `podman-restart.service` pada systemd user session.
2. **Pentingnya Bounded Retry pada Container:** Menetapkan batas retry maksimum (`MaxRetries=5`) adalah praktik terbaik SRE untuk mencegah *infinite crash loop* yang berisiko menguras alokasi CPU dan merusak persistensi volume data saat terjadi kegagalan fatal yang tidak dapat disembuhkan secara otomatis.

## ⏭️ Next Steps

1. Melanjutkan eksekusi Backlog Kategori 4 (Diagnostic Rulepack Expansion):
   - **TASK-TM-007:** Pembuatan alert rule `TomcatHighThreadUsage` untuk skenario *Thread Starvation*.
   - **TASK-TM-008:** Pembuatan alert rule `TomcatHighHeapUsage` untuk skenario *Memory / GC Pressure*.

---

## 🔗 Related Documentation

- [Phase Index](index.md)
- [TN-001 — Implement and Verify Diagnostic Service Self-Monitoring](TN-001-implement-and-verify-diagnostic-service-self-monitoring-and-emergency-smtp-routing.md)
- [Follow-up Tasks Backlog](../../follow-up-tasks.md)
- [TM-ADR-0016 — Canonical Incident Notification Authority](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0021 — Layered Failure Resilience and Auto-Healing](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md)

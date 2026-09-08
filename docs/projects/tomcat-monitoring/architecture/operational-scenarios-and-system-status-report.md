# Operational Scenarios and System Status Report

## 📋 Executive Summary

Laporan ini menyajikan status operasional komprehensif dari platform **Tomcat Monitoring & Autonomous Diagnostics** pada lingkungan persisten `devops-lab`. Dokumen ini merangkum seluruh komponen aktif, konfigurasi alert rules di Prometheus, taksonomi perutean insiden (*Diagnostic vs. Non-Diagnostic*), serta detail 6 skenario operasional yang telah terverifikasi secara *live*.

---

## 🏛️ 1. Runtime Components Status (`devops-lab`)

Seluruh komponen berjalan di atas **Rootless Podman**, terhubung pada dedicated container network `devops-lab`, dan disupervisi oleh systemd user service `podman-restart.service` dengan kebijakan auto-healing berbatas `--restart=on-failure:5` ([TM-ADR-0021](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md)):

| Komponen Container | Base Image / Versi | Port & Interface | Tanggung Jawab Utama | Status Runtime |
| :--- | :--- | :--- | :--- | :---: |
| **`tomcat-jmx-exporter`** | `localhost/tomcat-jmx-exporter:1.0.0` | `https://:9404/metrics`<br/>`http://:8080/health` | * Menjalankan Tomcat 9 JVM + Java Agent JMX Exporter.<br/>* Menyajikan metrik internal JVM & Tomcat via server-side TLS.<br/>* Menyajikan endpoint aplikasi untuk health probe. | 🟢 **Running (`up=1`)** |
| **`telegraf`** | `docker.io/library/telegraf:1.30.0` | `http://:9273/metrics` | * Melakukan active polling HTTP health probe ke Tomcat `:8080/health`.<br/>* Mengevaluasi HTTP status `200` dan JSON body `{"status":"UP"}`.<br/>* Menyajikan metrik kesehatan aplikasi ke Prometheus. | 🟢 **Running (`up=1`)** |
| **`prometheus`** | `localhost/prometheus:v3.13.2` | `http://:9090` | * Scrape targets JMX (:9404), Telegraf (:9273), dan Diagnostic Service (:8443).<br/>* Evaluasi alert rules time-series secara periodik.<br/>* Mengirim state alert *firing / resolved* ke Alertmanager. | 🟢 **Running (`up=1`)** |
| **`alertmanager`** | `localhost/alertmanager:v0.34.0` | `http://:9093` | * Deduplikasi, grouping, dan routing alert.<br/>* Merutekan `TomcatDown` ke Diagnostic Service (Webhook HTTPS).<br/>* Direct emergency SMTP ke Mailpit saat Diagnostic Service down.<br/>* Mengirim email alert monitoring standar ke Mailpit. | 🟢 **Running (`up=1`)** |
| **`diagnostic-service`** | `localhost/tomcat-diagnostic-service:0.1.4` | `https://:8443` | * **Autonomous Diagnostic Engine & Decision Authority**.<br/>* Evaluasi 18 cabang pohon keputusan (`TD-01`..`TD-18`) & 8 Failure Domains.<br/>* Single worker queue (50 capacity), SQLite persisten (`diagnostic_data`).<br/>* Menerbitkan laporan investigasi 7-seksi via SMTP ke Mailpit. | 🟢 **Running (`up=1`)** |
| **`mailpit`** | `docker.io/axllent/mailpit:v1.31.0` | `http://:8025` (UI)<br/>`mailpit:1025` (SMTP) | * Target penangkap email notifikasi (alert standar & laporan diagnosis SRE). | 🟢 **Running (`up=1`)** |

---

## 🚨 2. Active Alert Rules Catalog

Prometheus mengevaluasi 5 alert rules aktif pada berkas konfigurasi `application-health.yml`:

```mermaid
flowchart TD
    subgraph PROMETHEUS_ALERTS["🔥 5 Alert Rules Aktif di Prometheus"]
        direction TB
        A1["1. <b>TomcatDown</b><br/><i>up{job='tomcat-jmx-exporter'} == 0 (for: 2m)</i><br/>Severity: Critical"]
        A2["2. <b>TomcatApplicationHealthFailed</b><br/><i>http_response_result_code != 0 (for: 2m)</i><br/>Severity: Critical"]
        A3["3. <b>TomcatApplicationHealthMetricsMissing</b><br/><i>Series telegraf-health hilang (for: 2m)</i><br/>Severity: Warning"]
        A4["4. <b>TelegrafHealthScrapeUnavailable</b><br/><i>up{job='telegraf-health'} == 0 (for: 2m)</i><br/>Severity: Critical"]
        A5["5. <b>DiagnosticServiceDown</b><br/><i>up{job='tomcat-diagnostic-service'} == 0 (for: 1m)</i><br/>Severity: Critical"]
    end

    subgraph ROUTING["Perutean Alertmanager"]
        direction TB
        R_DIAG["<b>Rute A: Diagnostic Webhook</b><br/>(HTTPS Webhook ke Diagnostic Service)"]
        R_STD["<b>Rute B: Standard Alert Email</b><br/>(Email Notifikasi Standar SRE ke Mailpit)"]
        R_EMERG["<b>Rute C: Emergency Direct Route</b><br/>(Bypass Langsung ke Mailpit)"]
    end

    A1 -->|"Trigger Investigasi Mendalam"| R_DIAG
    A2 -->|"Notifikasi Langsung Tim Aplikasi"| R_STD
    A3 -->|"Notifikasi Monitoring Issue"| R_STD
    A4 -->|"Notifikasi Monitoring Issue"| R_STD
    A5 -->|"Zero Silent Failure Bypass"| R_EMERG
```

---

## 🔀 3. Dual-Track Incident & Scenario Classification Matrix

Sistem membedakan secara tegas skenario yang **memerlukan analisis diagnostik otonom** dari skenario yang **cukup ditangani oleh notifikasi langsung / auto-healing**:

| Kategori Skenario | Alert Rule Terkait | Karakteristik Masalah | Jalur Penanganan (*Handling Path*) | Alasan Desain Arsitektural |
| :--- | :--- | :--- | :--- | :--- |
| **Track 1: Autonomous Diagnostic Required** | `TomcatDown` | Kegagalan komposit ketersediaan JVM/container yang memiliki banyak kemungkinan akar masalah. | Alertmanager $\rightarrow$ Diagnostic Service $\rightarrow$ Multi-source Evidence $\rightarrow$ 18 Decision Branches $\rightarrow$ 7-Section Report. | Akar masalah tidak dapat ditentukan hanya dari satu metrik. Memerlukan korelasi log `catalina.out`, spool collector Podman, exit code, cgroup OOM, dan rekomendasi SOP operator. |
| **Track 2: Standard Direct Alerting (Non-Diagnostic)** | `TomcatApplicationHealthFailed`<br/>`TomcatApplicationHealthMetricsMissing`<br/>`TelegrafHealthScrapeUnavailable` | Gejala kegagalan deterministik tunggal pada layer HTTP aplikasi atau sinyal monitoring. | Alertmanager $\rightarrow$ Direct Standard Email Template (Mailpit). | Gejala sudah jelas (misal HTTP status bukan 200 / probe timeout / agent mati). Tidak memerlukan analisis log/spool yang membebani resource. Cukup alert operasional standar. |
| **Track 3: Self-Monitoring Emergency Fallback** | `DiagnosticServiceDown` | Kegagalan pada engine diagnostik itu sendiri. | Alertmanager $\rightarrow$ Direct Emergency SMTP Bypass (Mailpit). | Menjamin prinsip **Zero Silent Failure** ([TM-ADR-0020](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0020.md)). Mencegah perutean sirkular ke service yang sedang mati. |
| **Track 4: Container Auto-Healing** | Transient crash / exit non-zero | Kegagalan proses transien (glitch / spike memori sesaat). | `systemd --user podman-restart.service` $\rightarrow$ restart otomatis (`--restart=on-failure:5`). | Menyembuhkan insiden transien tanpa intervensi manusia, tetapi membatasi restart (maks 5x) untuk mencegah *unbounded CrashLoop*. |

---

## 🔬 4. Detail 6 Skenario Operasional Live

### 🔴 Skenario 1: Tomcat Runtime / Container Mati (`TomcatDown`)
* **Pemicu:** Proses Tomcat mati, container crash, OOMKilled oleh kernel Linux, fatal JVM crash (`hs_err`), port bind conflict, atau shutdown bersih.
* **Deteksi:** Prometheus mendeteksi target JMX Exporter tidak merespons (`up{job="tomcat-jmx-exporter"} == 0` selama 2 menit).
* **Alur Eksekusi:**
  1. Prometheus mengirim alert `TomcatDown` ke Alertmanager.
  2. Alertmanager mengirimkan webhook HTTPS ke `https://diagnostic-service:8443/api/v1/alerts/alertmanager`.
  3. Diagnostic Service menyimpan event secara persisten ke SQLite dan mengembalikan `HTTP 202 Accepted` ([TM-ADR-0015](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)).
  4. Worker mengambil antrean, mengumpulkan evidence terbatas (`catalina.out`, spool collector Podman, Prometheus metrics).
  5. Evaluasi pohon keputusan 18 cabang (`TD-01` s/d `TD-18`) dan pengelompokan ke salah satu dari 8 Failure Domain.
  6. Mengirimkan **Laporan Investigasi Diagnostik Terstruktur 7-Seksi** ke Mailpit.
  7. Saat Tomcat pulih, mengirimkan notifikasi pemulihan (*RESOLVED*) otomatis.

### 🟠 Skenario 2: HTTP Application Health Check Gagal (`TomcatApplicationHealthFailed`)
* **Pemicu:** Aplikasi Tomcat mengalami servlet error, internal context crash, mengembalikan HTTP `500`/`503`, body bukan `{"status":"UP"}`, atau response timeout $> 5\text{s}$, sementara JVM Tomcat masih berjalan normal.
* **Deteksi:** Telegraf probe gagal (`http_response_result_code != 0` selama 2 menit).
* **Alur Eksekusi:**
  1. Prometheus mendeteksi kegagalan health check dan mengirimkan alert ke Alertmanager.
  2. Alertmanager langsung merutekan email alert standar berformat Enterprise SRE ke Mailpit.
  3. Saat aplikasi kembali normal (HTTP `200 OK` `{"status":"UP"}`), Alertmanager mengirimkan email *RESOLVED*.

### 🟡 Skenario 3: Kehilangan Sinyal Monitoring Telegraf (`TelegrafHealthScrapeUnavailable` / `MetricsMissing`)
* **Pemicu:** Container Telegraf mati, konfigurasi network terputus, atau plugin Telegraf tidak menghasilkan metrik.
* **Deteksi:** Prometheus mendeteksi target Telegraf tidak dapat di-scrape (`up{job="telegraf-health"} == 0` selama 2 menit).
* **Alur Eksekusi:**
  * Alertmanager mengirimkan email peringatan bahwa **sinyal monitoring aplikasi terputus** (membedakan antara "aplikasi rusak" vs "alat monitor yang mati" sesuai [TM-ADR-0004](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md)).

### 🚨 Skenario 4: Diagnostic Service Mati / Self-Monitoring Outage (`DiagnosticServiceDown`)
* **Pemicu:** Container Diagnostic Service mati, crash, atau SQLite terkunci.
* **Deteksi:** Prometheus mendeteksi endpoint `/health` Diagnostic Service mati (`up{job="tomcat-diagnostic-service"} == 0` selama 1 menit).
* **Alur Eksekusi (*Zero Silent Failure*):**
  * Alertmanager mengeksekusi **Direct Emergency Email** ke Mailpit untuk memberi tahu operator bahwa engine diagnosis otomatis sedang tidak aktif.

### 🛡️ Skenario 5: Auto-Healing Kontainer dari Transient Crash
* **Pemicu:** Glitch transien (misal kill sinyal acak atau lonjakan memori sementara).
* **Alur Eksekusi:**
  * `systemd --user podman-restart.service` otomatis me-restart kontainer (`--restart=on-failure:5`) hingga maksimal 5 kali tanpa intervensi manusia.
  * Jika kegagalan bersifat permanen (misal kerusakan berkas/storage), container akan berhenti di restart ke-5 untuk mencegah pemborosan CPU / *unbounded CrashLoop*.

### 🧠 Skenario 6: Safe Hot-Reloading Aturan Diagnosis Baru (AI / SRE)
* **Pemicu:** SRE atau AI meng-ingest rulepack baru via `POST /api/v1/rules`.
* **Alur Eksekusi:**
  * Dipagari oleh **5-Layer Ingestion Defense** (Auth, Schema, Collision, Size Limit 64 KiB, Immutability Guard).
  * Aturan langsung aktif secara *zero-downtime* tanpa perlu restart container.

---

## 🎯 5. Roadmap Observabilitas Selanjutnya (JVM Golden Signals)

Berdasarkan kesepakatan arsitektur untuk menghindari *false positive* dari *static raw threshold* (seperti `Heap > 80%` atau `Threads > 80%`), pengembangan alert rules berbasis JMX Exporter berikutnya akan difokuskan pada:

1. **`TomcatGCPauseHigh` / `TomcatGCOverheadHigh`:** Memantau durasi Stop-The-World (STW > 1.5s) atau inefisiensi CPU akibat GC thrashing (> 15% waktu CPU habis untuk GC).
2. **`TomcatOldGenMemoryPressure`:** Memantau retensi memori di Old Generation yang tidak turun setelah Full GC (indikasi kuat *memory leak* sebelum terjadinya crash OOM).
3. **`TomcatThreadPoolExhausted`:** Memantau kondisi thread pool 100% penuh selama durasi tertentu (`for: 5m`) atau terjadinya task rejection (`RejectedExecutionException`).

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

Prometheus mengevaluasi alert rules aktif pada berkas konfigurasi `application-health.yml` dan `jvm-workload-performance.yml`:

```mermaid
flowchart TD
    subgraph PROMETHEUS_ALERTS["🔥 Alert Rules Aktif di Prometheus"]
        direction TB
        A1["1. <b>TomcatDown</b><br/><i>up{job='tomcat-jmx-exporter'} == 0 (for: 2m)</i><br/>Severity: Critical"]
        A2["2. <b>TomcatApplicationHealthFailed</b><br/><i>http_response_result_code != 0 (for: 2m)</i><br/>Severity: Critical"]
        A3["3. <b>TomcatApplicationHealthMetricsMissing</b><br/><i>Series telegraf-health hilang (for: 2m)</i><br/>Severity: Warning"]
        A4["4. <b>TelegrafHealthScrapeUnavailable</b><br/><i>up{job='telegraf-health'} == 0 (for: 2m)</i><br/>Severity: Critical"]
        A5["5. <b>TomcatGCPauseHigh / Overhead / OldGen / ThreadSat</b><br/><i>Sinyal Emas GC & Konkurensi JVM (TN-004)</i><br/>Severity: Warning"]
        A6["6. <b>DiagnosticServiceDown</b><br/><i>up{job='tomcat-diagnostic-service'} == 0 (for: 1m)</i><br/>Severity: Critical"]
    end

    subgraph ROUTING["Perutean Alertmanager"]
        direction TB
        R_DIAG["<b>Rute Utama: Universal Diagnostic Webhook</b><br/>(HTTPS Webhook ke Diagnostic Service)"]
        R_EMERG["<b>Rute Darurat: Emergency Direct SMTP</b><br/>(Bypass Langsung ke Mailpit)"]
    end

    A1 -->|"Trigger Analisis Komposit"| R_DIAG
    A2 -->|"Ingestion Bukti HTTP & Log"| R_DIAG
    A3 -->|"Ingestion Bukti Telemetri"| R_DIAG
    A4 -->|"Ingestion Sinyal Monitoring"| R_DIAG
    A5 -->|"Ingestion Metrik Beban Kerja"| R_DIAG
    A6 -->|"Zero Silent Failure Emergency Bypass"| R_EMERG
```

---

## 🔀 3. Incident & Scenario Classification Matrix

Sistem menegakkan prinsip **Universal Diagnostic Ingestion** ([TM-ADR-0016](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)), di mana seluruh alert monitoring aplikasi dialirkan ke Diagnostic Service untuk standarisasi format laporan 7-seksi SRE:

| Kategori Skenario | Alert Rule Terkait | Karakteristik Masalah | Jalur Penanganan (*Handling Path*) | Alasan Desain Arsitektural |
| :--- | :--- | :--- | :--- | :--- |
| **Track 1: Universal Diagnostic Pipeline (Canonical Authority)** | `TomcatDown`<br/>`TomcatApplicationHealthFailed`<br/>`TomcatApplicationHealthMetricsMissing`<br/>`TelegrafHealthScrapeUnavailable`<br/>`TomcatGCPauseHigh`<br/>`TomcatThreadPoolSaturated`<br/>`TomcatGCOverheadHigh`<br/>`TomcatOldGenMemoryPressure` | Seluruh spektrum anomali ketersediaan runtime, degradasi performa JVM GC/Thread, dan kegagalan servlet aplikasi. | Alertmanager $\rightarrow$ Diagnostic Service $\rightarrow$ Multi-source Evidence $\rightarrow$ Evaluasi Aturan $\rightarrow$ Format Kanonikal 7-Seksi SRE. | Menegakkan otoritas tunggal notifikasi insiden (TM-ADR-0016) dan menjamin laporan investigasi yang konsisten bagi tim SRE tanpa email mentah Alertmanager. |
| **Track 2: Self-Monitoring Emergency Fallback** | `DiagnosticServiceDown` | Kegagalan pada engine diagnostik itu sendiri. | Alertmanager $\rightarrow$ Direct Emergency SMTP Bypass (Mailpit). | Menjamin prinsip **Zero Silent Failure** ([TM-ADR-0016](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md) / [TM-ADR-0020](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0020.md)). Mencegah perutean sirkular ke service yang sedang mati. |
| **Track 3: Container Auto-Healing** | Transient crash / exit non-zero | Kegagalan proses transien (glitch / spike memori sesaat). | `systemd --user podman-restart.service` $\rightarrow$ restart otomatis (`--restart=on-failure:5`). | Menyembuhkan insiden transien tanpa intervensi manusia, tetapi membatasi restart (maks 5x) untuk mencegah *unbounded CrashLoop*. |

---

## 🔬 4. Detail Skenario Operasional Live

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
  2. Alertmanager meneruskan webhook HTTPS ke Diagnostic Service (TM-ADR-0016).
  3. Diagnostic Service mengumpulkan bukti respon Telegraf dan cuplikan log `catalina.out`, lalu menerbitkan laporan investigasi 7-seksi ke Mailpit.
  4. Saat aplikasi kembali normal (HTTP `200 OK` `{"status":"UP"}`), Diagnostic Service mengirimkan email pemulihan *RESOLVED*.

### 🟡 Skenario 3: Kehilangan Sinyal Monitoring Telegraf (`TelegrafHealthScrapeUnavailable` / `MetricsMissing`)
* **Pemicu:** Container Telegraf mati, konfigurasi network terputus, atau plugin Telegraf tidak menghasilkan metrik.
* **Deteksi:** Prometheus mendeteksi target Telegraf tidak dapat di-scrape (`up{job="telegraf-health"} == 0` selama 2 menit).
* **Alur Eksekusi:**
  1. Prometheus mengirimkan alert `TelegrafHealthScrapeUnavailable` ke Alertmanager.
  2. Alertmanager meneruskan webhook ke Diagnostic Service.
  3. Diagnostic Service menerbitkan laporan diagnostik bahwa **sinyal observabilitas kesehatan aplikasi terputus** (membedakan antara "aplikasi rusak" vs "alat monitor yang mati" sesuai [TM-ADR-0004](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md)).

### 🚨 Skenario 4: Diagnostic Service Mati / Self-Monitoring Outage (`DiagnosticServiceDown`)
* **Pemicu:** Container Diagnostic Service mati, crash, atau SQLite terkunci.
* **Deteksi:** Prometheus mendeteksi endpoint `/health` Diagnostic Service mati (`up{job="tomcat-diagnostic-service"} == 0` selama 1 menit).
* **Alur Eksekusi (*Zero Silent Failure*):**
  * Alertmanager mengeksekusi **Direct Emergency Email** ke Mailpit untuk memberi tahu operator bahwa engine diagnosis otomatis sedang tidak aktif ([TM-ADR-0016](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md) / [TM-ADR-0020](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0020.md)).

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

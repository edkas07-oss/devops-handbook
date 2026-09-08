# TM-ADR-0021

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0021 |
| **Title** | Adopt Layered Failure Resilience, Container Auto-Healing, and Monitoring Domain Separation |
| **Project** | Tomcat Monitoring |
| **Section** | Infrastructure Resilience and Fault-Tolerance Architecture |
| **Status** | Accepted |
| **Date** | 2026-09-08 |

---

## 🔍 Overview

Menetapkan arsitektur ketahanan sistem berlapis (*Layered Defense-in-Depth Resilience*), pemisahan tegas domain pemantauan (*Monitoring Domain Separation*) antara infrastruktur host (SolarWinds/NOC) dan observabilitas aplikasi (Prometheus/SRE), kebijakan pemulihan otomatis container (*Container Auto-Healing* via `--restart=on-failure:5`), serta panduan mitigasi pencegahan kegagalan berulang (*CrashLoop Guardrails*).

## 🌍 Context

Dalam perancangan platform observabilitas enterprise, muncul pertanyaan arsitektural krusial:
1. **"Who monitors the monitoring system?"**: Jika daemon pemantau (Prometheus / Diagnostic Service) mengalami *crash* atau *downtime*, bagaimana tim operasional mengetahuinya tanpa adanya sinyal alert aktif?
2. **Keterbatasan Auto-Healing Murni**: Mengandalkan *restart policy* container semata tidak menjamin pemulihan sistem jika kegagalan disebabkan oleh masalah logis atau sistemik (seperti korupsi database, disk penuh, port bentrok, atau kesalahan konfigurasi). Auto-healing tanpa observabilitas berisiko menjebak sistem dalam *CrashLoopBackOff* atau *silent flapping*.
3. **Tumpang Tindih Peran Monitoring**: Tanpa pemisahan domain yang jelas antara pemantauan fisik/host (OS, hardware, jaringan) dan pemantauan aplikasi (JVM, servlet, diagnostik), tim SRE dan NOC sering kali menerima notifikasi yang bertabrakan (*split alerting*) saat terjadi gangguan skala server.

## ⚖️ Decision

Ditetapkan 4 pilar keputusan arsitektur ketahanan dan pemulihan sistem:

### 1. Pemisahan Domain Pemantauan (*Separation of Monitoring Concerns*)
* **Layer Host & Network (Infrastruktur Fisik/VM)**: Dikelola secara terpusat oleh sistem NMS enterprise eksternal (seperti **SolarWinds / Network NMS**). Bertanggung jawab memantau ketersediaan node (ICMP Ping, SNMP, OS health, hardware disk/memory, network interfaces). Jika seluruh host/VM mati, SolarWinds menjadi otoritas tunggal yang memperingatkan tim NOC/Infrastruktur.
* **Layer Application & Workload (JVM & Observabilitas)**: Dikelola oleh **Prometheus + Alertmanager + Diagnostic Service**. Bertanggung jawab mendeteksi degradasi performa internal Tomcat (thread pool exhaustion, GC/Heap pressure, slow request latency) serta melakukan otomatisasi triage snapshot.

### 2. Model Ketahanan Berlapis (*3-Layer Defense-in-Depth Model*)

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'edgeLabelBackground': 'transparent',
    'fontSize': '12px'
  }
}}%%
flowchart LR
    %% Layer 1: Instant Auto-Healing
    subgraph L1["Layer 1: Instant Auto-Healing<br/>(Container Runtime)"]
        direction TB
        Crash["Container Failure /<br/>Process Crash"]
        Podman["Podman Engine<br/>(--restart=on-failure:5)"]
        Healed["Container Pulih Instan<br/>(Zero Alert Noise)"]

        Crash -->|"Exit code != 0"| Podman
        Podman -->|"Auto-restart < 2s"| Healed
    end

    %% Layer 2: Logical & Persistent Failure
    subgraph L2["Layer 2: Application Observability<br/>(Prometheus & Alertmanager)"]
        direction TB
        Probe["Prometheus Health Probe<br/>(up == 0 for: 1m)"]
        AM["Alertmanager Emergency Route<br/>(Bypass Webhook)"]
        SRE["Mailpit / Emergency SMTP<br/>(On-Call SRE Notified)"]

        Probe -->|"State: FIRING"| AM
        AM -->|"Direct Email"| SRE
    end

    %% Layer 3: External Infrastructure
    subgraph L3["Layer 3: External Infrastructure<br/>(Enterprise NMS)"]
        direction TB
        HostOutage["Host / VM Crash /<br/>Network Partition"]
        SolarWinds["SolarWinds NMS<br/>(ICMP / SNMP / Agent)"]
        NOC["NOC & Infra Team<br/>(Hardware / OS Escalation)"]

        HostOutage -->|"Heartbeat / Ping Loss"| SolarWinds
        SolarWinds -->|"Host Down Alarm"| NOC
    end

    %% Cross-layer escalation flows
    Crash -.->|"Persistent Failure /<br/>CrashLoop > 1m"| Probe
    Healed -.->|"Host Down /<br/>Kernel Panic"| HostOutage
```

1. **Layer 1 (Instant Recovery / Auto-Healing)**: Container engine (Podman) merestart container secara otomatis saat terjadi transient crash.
2. **Layer 2 (Logical & Persistent Failure Alerting)**: Jika auto-healing gagal atau service hang $> 1$ menit, Prometheus menembakkan alert `DiagnosticServiceDown` via rute darurat Alertmanager.
3. **Layer 3 (Watchdog / Dead Man's Switch & Host NMS)**: Untuk memantau keaktifan Prometheus itu sendiri dan integritas host fisik dari luar jaringan lokal.

### 3. Kebijakan Auto-Restart Terbatas (*Bounded Auto-Restart Policy*)
* Seluruh container stack monitoring (`prometheus`, `alertmanager`, `diagnostic-service`, `tomcat-jmx-exporter`) dikonfigurasi dengan kebijakan restart terkontrol:
  ```bash
  --restart=on-failure:5
  ```
* Kebijakan ini membatasi percobaan restart maksimum 5 kali, mencegah pemborosan CPU/IO secara liar jika container mengalami kegagalan fatal yang tidak dapat dipulihkan otomatis.

### 4. Mitigasi 5 Vektor Kegagalan Startup (*CrashLoop Guardrails*)

| Vektor Kegagalan | Penyebab Utama | Langkah Mitigasi / Guardrail |
| :--- | :--- | :--- |
| **1. Storage Depletion (ENOSPC)** | Disk penuh akibat pertumbuhan WAL / data TSDB / log tak terkendali. | Pengaturan kuota retensi ketat (`--storage.tsdb.retention.time=15d`), volume terisolasi, dan housekeeping pruning SQLite. |
| **2. Corrupted Lock / WAL File** | Matinya proses secara kasar saat flush chunk data ke disk. | Engine SQLite menggunakan mode WAL transaksional; isolasi volume persistent; recovery lock check saat startup. |
| **3. Port Conflict / TIME_WAIT** | Socket TCP tertahan di OS setelah proses mati mendadak. | Penggunaan network bridge terisolasi (`devops-lab`) dan grace-period shutdown (`--time 10`). |
| **4. Permission / Volume Drift** | Perubahan kepemilikan file host oleh operasi di luar container. | Standarisasi kepemilikan volume non-root (`nobody` / UID terdefinisi) dan inisialisasi volume otomatis via script. |
| **5. Memory Replay OOM** | Lonjakan konsumsi RAM saat Prometheus me-replay WAL besar saat boot. | Alokasi memory limit yang memadai dengan buffer headroom 2x lipat dari footprint normal. |

## 🏛️ Architecture

```text
+-------------------------------------------------------------------------+
| Enterprise Infrastructure (SolarWinds / NOC)                           |
|  - Host Hardware, VM Uptime, Network Ping                               |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| Host OS (Podman Engine Runtime)                                         |
|  - Container Restart Policy: --restart=on-failure:5                      |
|                                                                         |
|  +---------------------+   +---------------------+   +----------------+ |
|  | prometheus          |   | alertmanager        |   | diagnostic-svc | |
|  | (Metrics Scrape)    |-->| (Routing & Dispatch)|-->| (Triage Engine)| |
|  +----------+----------+   +----------+----------+   +--------+-------+ |
|             |                         |                       |         |
|             +---- Scrape /health -----+-- Direct Emergency ---+         |
|                   (up == 0)              (Bypass Webhook)               |
+-------------------------------------------------------------------------+
```

## 💡 Rationale

- **Kombinasi Sempurna antara Kecepatan dan Ketertelusuran**: Auto-healing memberikan pemulihan cepat dalam hitungan detik untuk gangguan transient tanpa mengganggu manusia, sedangkan alerting memastikan kegagalan persisten tetap tercatat dan dieskalasikan.
- **Mencegah False Alarm dan Alarm Fatigue**: Jeda toleransi 1 menit (`for: 1m`) pada alert rule memastikan bahwa restart singkat yang berhasil tidak memicu kepanikan operator.
- **Batas Tanggung Jawab Operasional yang Bersih**: Tim NOC fokus pada keandalan infrastruktur fisik/VM via SolarWinds, sementara tim SRE/DevOps fokus pada kestabilan aplikasi dan logika diagnostik.

## ⚠️ Consequences

- **Kelebihan:**
  - Platform observabilitas memiliki ketahanan mandiri yang tinggi (*high self-resilience*).
  - Mengeliminasi skenario *silent failure* pada seluruh siklus hidup monitoring.
  - Menghindari loop tak terbatas (*infinite crash-loop*) yang dapat merusak disk atau membebani CPU.
- **Keterbatasan:**
  - Memerlukan standarisasi parameter `--restart` pada seluruh skrip deployment container.
  - Kegagalan sistemik akibat disk 100% penuh tetap membutuhkan intervensi manual tim SRE untuk pembersihan media penyimpanan.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-09-08**

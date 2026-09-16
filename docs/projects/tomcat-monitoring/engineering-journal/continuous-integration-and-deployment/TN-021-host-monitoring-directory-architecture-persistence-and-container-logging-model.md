# TN-021 — Host Monitoring Directory Architecture, Volume Persistence Strategy, and Container Logging Model

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Architecture Documentation, Volume Persistence & Container Logging |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Continuous Integration and Deployment |
| Activity Date | 2026-09-16 |
| Recorded Date | 2026-09-16 |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-16 |

---

## 🎯 Objective

Mendokumentasikan secara komprehensif arsitektur direktori host monitoring (`C:\monitoring` pada Windows dan `/opt/monitoring` atau `$project_root` pada Linux), pemisahan tanggung jawab (*separation of concerns*) antara kontainer *stateless* dan persistensi host, serta model tata kelola logging kontainer *cloud-native*.

Dokumen ini menjadi rujukan teknis baku bagi DevOps, SRE, dan Platform Engineer mengenai peran fungsional setiap subfolder, interaksi *volume bind-mount*, serta lokasi dan penanganan log pada platform Tomcat Monitoring.

---

## 🏗️ Architectural Foundations

### 1. Prinsip Pemisahan Tanggung Jawab (Stateless Containers vs Stateful Host)

Platform Tomcat Monitoring mengadopsi prinsip **12-Factor App** dan standar **OCI Containerization**:

```mermaid
flowchart TD
    subgraph Host_Filesystem["Host Filesystem (C:\\monitoring | /opt/monitoring)"]
        CONF["config/<br/>(Declarative Configurations)"]
        DATA["data/<br/>(Persistent TSDB & SQLite DBs)"]
        SPOOL["spool/<br/>(Inter-Container Evidence Buffer)"]
        SEC["tls/ & secrets/<br/>(Injected Credentials & Certs)"]
        LOGS["logs/<br/>(Tomcat Catalina Log Intake)"]
        BIN["bin/ & scripts/<br/>(Operator CLI & Test Scripts)"]
    end

    subgraph Container_Stack["Ephemeral Container Runtime (Docker / Podman)"]
        PROM["prometheus"]
        AM["alertmanager"]
        DS["diagnostic-service"]
        AGENT["tm-agent"]
        MAIL["mailpit"]
    end

    CONF -.->|Bind Mount (ro)| PROM
    CONF -.->|Bind Mount (ro)| AM
    CONF -.->|Bind Mount (ro)| DS
    DATA <-->|Bind Mount (rw)| PROM
    DATA <-->|Bind Mount (rw)| AM
    DATA <-->|Bind Mount (rw)| MAIL
    DATA <-->|Bind Mount (rw)| DS
    AGENT -->|Writes Snapshots| SPOOL
    DS -->|Reads Evidence| SPOOL
    SEC -.->|Bind Mount (ro)| PROM
    SEC -.->|Bind Mount (ro)| AM
    SEC -.->|Bind Mount (ro)| DS
    LOGS -.->|Bind Mount (ro)| DS
```

* **Kontainer Bersifat Ephemeral**: Kontainer dapat di-stop, di-recreate, atau di-upgrade versinya sewaktu-waktu tanpa menyebabkan kehilangan data historis metrik, database insiden, maupun perubahan konfigurasi.
* **Host Bersifat Stateful & Sovereign**: Semua data persisten, konfigurasi deklaratif, dan sertifikat TLS berada di bawah kontrol filesystem host target.

---

## 📂 Rincian Fungsi Direktori Host

Berikut adalah matriks fungsi dan siklus hidup seluruh subfolder di dalam direktori `C:\monitoring` (Windows) / `${project_root}` (Linux):

| Direktori | Status | Mounted ke Kontainer | Peran & Fungsi Utama |
| :--- | :--- | :---: | :--- |
| **`config/`** | Aktif | **Ya** (Read-Only) | Menyimpan konfigurasi deklaratif (`prometheus.yml`, `alertmanager.yml`, `targets.win.json`, `rules`). Memungkinkan operator mengubah konfigurasi/rulepack tanpa harus mem-build ulang image kontainer. |
| **`data/`** | Aktif | **Ya** (Read-Write) | Menyimpan database fisik persisten: <br/>• `data/prometheus/`: TSDB WAL & time-series chunks.<br/>• `data/alertmanager/`: Silence states & notification logs.<br/>• `data/mailpit/`: `mailpit.db` SQLite store.<br/>• `data/diagnostic/`: Database riwayat triase SQLite. |
| **`spool/`** | Aktif | **Ya** (Read-Write) | Buffer pertukaran bukti (*evidence buffer*). Kontainer `tm-agent` menulis snapshot kondisi host (`*_collector_status.json`), yang kemudian dibaca oleh `diagnostic-service` saat menganalisa insiden. |
| **`tls/` & `jmx-tls/`** | Aktif | **Ya** (Read-Only) | Menyimpan pasangan sertifikat publik (`server.crt`) dan private key (`server.key`) serta PKCS12 keystore. Mendukung *Zero-Secret in Image* dan auto-renewal. |
| **`secrets/`** | Aktif | **Ya** (Read-Only) | Menyimpan token autentikasi (`bearer-token`) dan kredensial SMTP. Diinjeksi ke kontainer saat runtime. |
| **`logs/`** | Aktif | **Ya** (Read-Only) | **Mount Point / Intake Directory** untuk file log runtime Tomcat (`catalina.out`, access logs). Diagnostic Service membaca direktori ini untuk analisis akar masalah otomatis. *(Secara default kosong sampai instance Tomcat mengarahkan lognya ke folder ini)*. |
| **`bin/`** | Aktif | **Tidak** (Host Only) | Menyimpan binary perkakas CLI operator (`tmctl.exe` / `tmctl`) untuk administrasi lokal dari shell host. |
| **`scripts/`** | Aktif | **Tidak** (Host Only) | Menyimpan skrip operasional host (`test-alert-pipeline.ps1` pada Windows atau skrip shell `.sh` pada Linux) untuk verifikasi pipeline alert end-to-end. |
| **`docker/`** | Cache | **Tidak** (Host Only) | *Build context staging* tempat penyimpanan `Dockerfile` dan source dependencies saat Ansible mem-build image kontainer lokal. |

---

## 📋 Model Logging Kontainer (Container Logging Engine)

### 1. Kenapa Log Komponen Tidak Ditulis ke File Teks di `logs/`?

Sesuai standar arsitektur Cloud-Native (12-Factor App - Factor XI: *Logs as Event Streams*), aplikasi di dalam kontainer tidak mengelola file log lokal sendiri, melainkan menuliskan seluruh log aplikasi, akses, dan error ke **`stdout` dan `stderr`**.

Container Engine (Docker di Windows/Linux, Podman di Linux) menangkap aliran tersebut secara otomatis ke dalam subsystem logging engine host.

### 2. Panduan Mengakses Log Komponen

Operator/SRE dapat memantau log setiap komponen secara langsung menggunakan perintah CLI:

```powershell
# Memeriksa log Diagnostic Service (Analisis & Webhook Ingest)
docker logs diagnostic-service --tail 50
docker logs -f diagnostic-service           # Live real-time stream

# Memeriksa log Alertmanager (Routing & Notifikasi Email)
docker logs alertmanager --tail 50

# Memeriksa log Prometheus (Scraping & Rule Evaluation)
docker logs prometheus --tail 50

# Memeriksa log Mailpit (SMTP Server & Mail Intake)
docker logs mailpit --tail 50

# Memeriksa log TM Agent (Kolektor Metrik Host)
docker logs tm-agent --tail 50
```

*(Pada sistem Linux berbasis Podman, ganti `docker` dengan `podman`)*.

### 3. Lokasi Fisik Log Driver pada Filesystem Host

Docker Engine mengelola file log kontainer pada path internal:
* **Windows**: `C:\ProgramData\Docker\containers\<Container_ID>\<Container_ID>-json.log`
* **Linux**: `/var/lib/docker/containers/<Container_ID>/<Container_ID>-json.log` (atau `journald` untuk Podman).

---

## 📌 Kesimpulan

1. Direktori host `C:\monitoring` / `/opt/monitoring` memegang peranan krusial sebagai fondasi persistensi, konfigurasi dinamis, dan keamanan tanpa rahasia (*zero-secret*).
2. Direktori `logs/` disiapkan khusus sebagai titik temu (*intake*) data log Tomcat target dengan mesin diagnosa.
3. Seluruh komponen monitoring mengalirkan log ke subsystem container logging standard, menjamin performa I/O tinggi dan kemudahan observabilitas terpusat.

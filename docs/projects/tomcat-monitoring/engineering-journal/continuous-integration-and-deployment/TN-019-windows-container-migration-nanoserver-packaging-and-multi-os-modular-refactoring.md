# TN-019 — Windows Container Migration (Docker NanoServer), All-in-One Diagnostic Packaging, Multi-OS Modular Refactoring, and AWS Live Verification

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Windows Container Migration, Docker NanoServer Packaging, Multi-OS Modular Refactoring & Live Verification |
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

Mengeksekusi migrasi menyeluruh dari arsitektur eksekusi background proses `.exe` pada Windows Server host ke arsitektur **Windows Container berbasis Docker NanoServer (`mcr.microsoft.com/windows/nanoserver:1809` / `ltsc2022`) dengan Process Isolation**, merefaktor struktur Ansible roles dan Dockerfile menjadi tata letak modular multi-OS (`tasks/linux/` vs `tasks/windows/` dan `docker/linux/` vs `docker/windows/`), mengemas **Node.js Tomcat Diagnostic Service** ke dalam container Windows NanoServer untuk mewujudkan konsep **All-in-One Monitoring & Diagnostic Stack**, serta memverifikasi kelaikan seluruh stack secara live pada instans target **AWS EC2 Windows Server 2022 (`aws-ec2-win-01`)**.

Aktivitas ini menuntaskan **TASK-TM-034** dan memperluas implementasi arsitektur [TM-ADR-0026](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md), [TM-ADR-0027](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), dan [TM-ADR-0028](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md).

---

## 🌍 Background & Problem Statement

Pada penggelaran sebelumnya (TN-018), instans target Windows Server 2022 di AWS (`aws-ec2-win-01`) berhasil di-bootstrap dengan OpenSSH dan diintegrasikan ke dalam inventori multi-OS (`inventories/aws-staging.ini`). Namun, implementasi awal stack monitoring Windows mengalami inkonsistensi arsitektur (*hybrid flaw*):
- Pada Linux (`aws-ec2-mon-01`), stack berjalan 100% di dalam kontainer terisolasi via Podman/Docker.
- Pada Windows (`aws-ec2-win-01`), `tm-agent.exe`, `prometheus.exe`, `alertmanager.exe`, dan `mailpit.exe` masih dijalankan secara legacy langsung di background host Windows (`Start-Process`).
- `tomcat-diagnostic-service` awalnya belum memiliki kemasan container untuk Windows sehingga stack Windows belum sepenuhnya *self-contained / all-in-one*.

Tantangan teknis utama yang dihadapi selama migrasi kontainer Windows:
1. **Kegagalan Runtime Go pada NanoServer (`panic: Failed to load netapi32.dll`):**
   Biner terkompilasi Go (`mailpit.exe`, `prometheus.exe`, `alertmanager.exe`, `tm-agent.exe`) memanggil `os/user.Current()` saat inisialisasi awal modul (misal `k8s.io/klog` dan `sendmail/cmd`). Pada Windows, fungsi ini memanggil API `syscall.NetGetJoinInformation` dari `netapi32.dll`. Karena base image `mcr.microsoft.com/windows/nanoserver` adalah varian ultra-minimalis, `netapi32.dll` tidak tersedia secara default di `C:\Windows\System32\`, memicu fatal panic saat kontainer dijalankan.
2. **Hak Akses File Sistem NanoServer (`Access is denied` saat Build):**
   Upaya menyalin serangkaian DLL sistem (`netutils.dll`, `srvcli.dll`, `wkscli.dll`) ke `C:/Windows/System32/` gagal dengan error `Access is denied` karena DLL tersebut sudah merupakan bagian dari image NanoServer yang terproteksi. Hanya `netapi32.dll` yang benar-benar absen dan dapat disalin ke direktori sistem.
3. **Porting Node.js & Built-in SQLite (`node:sqlite`) ke Windows NanoServer:**
   `tomcat-diagnostic-service` dibangun di atas Node.js dan memanfaatkan modul bawaan `node:sqlite` (`DatabaseSync`) dengan mode WAL. Memastikan runtime Node.js v22+ portabel dapat berjalan stabil di dalam Windows NanoServer tanpa instalasi MSI atau visual C++ redistributables berat adalah kunci kelangsungan All-in-One stack.
4. **Normalisasi Path Multi-OS pada Node.js Windows:**
   Validator path aplikasi `config-loader.js` dan `target-registry.js` memeriksa `path.isAbsolute(p)` dan `path.normalize(p) === p`. Pada runtime Windows, path bergaya POSIX (`/run/...`, `/var/...`) menghasilkan `\run\...` saat dinormalisasi sehingga gagal validasi identitas strict. Konfigurasi `application.win.json` dan `targets.win.json` harus menggunakan normalized Windows path (misal `C:\monitoring\...`).
5. **Keterbatasan Loopback WinNAT (Windows Server Build 17763):**
   Host Windows Server tidak dapat mengakses port yang dipublikasikan container melalui `127.0.0.1:<published_port>` karena limitasi driver WinNAT. Probing kesiapan kontainer dari host harus menargetkan internal IP kontainer (`http://<container_ip>:<port>`), sedangkan antar kontainer berkomunikasi melalui Docker DNS internal (`tm-net`).

---

## 🏗️ Architecture & Implementation Strategy

### 1. Modularitas Direktori Multi-OS

Struktur proyek direfaktor secara modular untuk memisahkan logika Linux dan Windows secara tegas tanpa redundansi:

```
tomcat-monitoring/
├── docker/
│   ├── linux/
│   │   ├── prometheus.Dockerfile
│   │   ├── alertmanager.Dockerfile
│   │   ├── mailpit.Dockerfile
│   │   ├── tm-agent.Dockerfile
│   │   ├── diagnostic-service.Dockerfile
│   │   ├── tomcat-jmx-exporter.Dockerfile
│   │   └── postfix-relay.Dockerfile
│   └── windows/
│       ├── prometheus.Dockerfile
│       ├── alertmanager.Dockerfile
│       ├── mailpit.Dockerfile
│       ├── tm-agent.Dockerfile
│       └── diagnostic-service.Dockerfile
├── playbooks/
│   ├── deploy-all.yml
│   ├── deploy-linux.yml
│   └── deploy-windows.yml
└── roles/
    ├── role_host_prep/
    │   └── tasks/
    │       ├── linux/
    │       └── windows/
    ├── role_container_stack/
    │   └── tasks/
    │       ├── linux/
    │       └── windows/
    └── role_event_collector/
        └── tasks/
            ├── linux/
            └── windows/
```

### 2. Standarisasi Windows Container Dockerfile (NanoServer 1809 / LTSC2022)

Setiap Dockerfile Windows mengadopsi base image NanoServer, mengekstrak helper DLL yang diperlukan, dan mengekspos port serta volume kanonikal:

```dockerfile
# Contoh: docker/windows/diagnostic-service.Dockerfile
ARG BASE_IMAGE=mcr.microsoft.com/windows/nanoserver:ltsc2022
FROM ${BASE_IMAGE}

LABEL maintainer="Eddy Wiyatno" \
      description="Windows Container for Tomcat Diagnostic Service"

# Copy networking helper DLL required on NanoServer
COPY netapi32.dll C:/Windows/System32/

# Copy Node.js runtime
WORKDIR C:/node
COPY node.exe C:/node/node.exe

# Copy Diagnostic Service codebase
WORKDIR C:/app
COPY package.json package-lock.json C:/app/
COPY node_modules C:/app/node_modules/
COPY src C:/app/src/
COPY config C:/app/config/
COPY migrations C:/app/migrations/

ENV NODE_ENV=production
EXPOSE 8443

ENTRYPOINT ["C:/node/node.exe", "C:/app/src/main.js", "--config", "C:/monitoring/config/diagnostic-service/application.json"]
```

### 3. Komunikasi Lintas Kontainer via Docker NAT Network (`tm-net`)

Seluruh 5 kontainer terhubung pada bridge NAT `tm-net`:
- `prometheus`: Mengikis metrik JMX dan memantau status target.
- `alertmanager`: Menerima alert dari Prometheus dan meroute via webhook HTTPS ke `https://diagnostic-service:8443/api/v1/alerts/alertmanager` atau direct fallback ke `mailpit:1025`.
- `diagnostic-service`: Menerima payload webhook Alertmanager, mengevaluasi bukti runtime via rule engine, dan mengirim laporan diagnosis via SMTP ke `mailpit:1025`.
- `mailpit`: Menangani penerimaan email SMTP di port 1025 dan menyajikan Web UI di port 8025.
- `tm-agent`: Mengumpulkan log/spool Tomcat lokal ke direktori persisten volume `C:\monitoring\spool`.

---

## 🔬 Live AWS Verification & Results

### 1. Eksekusi Playbook Ansible Windows

Playbook [`playbooks/deploy-windows.yml`](file:///home/eddywiyatno/git/tomcat-monitoring/playbooks/deploy-windows.yml) dieksekusi secara otomatis dari controller:

```bash
./scripts/run-ansible-playbook.sh -i inventories/aws-staging.ini playbooks/deploy-windows.yml
```

**Hasil Eksekusi Ansible:**
```text
PLAY RECAP *********************************************************************
aws-ec2-win-01             : ok=69   changed=12   unreachable=0    failed=0    skipped=26   rescued=0    ignored=0
```

### 2. Status Kontainer Live di AWS Windows Host

```text
NAMES                IMAGE                           STATUS          PORTS
diagnostic-service   diagnostic-service-win:latest   Up 34 seconds   0.0.0.0:8443->8443/tcp
prometheus           prometheus-win:latest           Up 4 minutes    0.0.0.0:9090->9090/tcp
mailpit              mailpit-win:latest              Up 4 minutes    0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
alertmanager         alertmanager-win:latest         Up 4 minutes    0.0.0.0:9093->9093/tcp, 9094/tcp
tm-agent             tm-agent-win:latest             Up 4 minutes
```

### 3. Pengujian Pipeline Alerting & Diagnostik End-to-End

Skrip verifikasi [`scripts/test-alert-pipeline.ps1`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/test-alert-pipeline.ps1) dijalankan langsung di target host:
- Health check `GET https://<ds-ip>:8443/health/ready` menghasilkan `{"live":true,"ready":true}` (HTTP 200).
- Dispatch alert firing `TomcatDown` ke Alertmanager API `POST http://<am-ip>:9093/api/v2/alerts`.
- Alertmanager meroute notifikasi darurat dan webhook ke Diagnostic Service.
- Mailpit menerima email notifikasi diagnosis secara instan.

**Output Verifikasi:**
```text
Discovered Container IPs:
  Alertmanager       : 172.22.181.20
  Mailpit            : 172.22.188.84
  Diagnostic Service : 172.22.181.188
Diagnostic Service Health Check: {"live":true,"ready":true}
Posting alert to Alertmanager (http://172.22.181.20:9093/api/v2/alerts)...
Alert dispatched. Waiting for Alertmanager routing and Diagnostic Service triage (15s)...
=== Mailpit Inbox Status ===
Total Messages Received: 3
--------------------------------------------------
Subject : [RESOLVED] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown (Instance: diagnostic-service:8443)
From    : alertmanager@tomcat-monitoring.invalid
To      : operator@tomcat-monitoring.invalid
--------------------------------------------------
VERIFICATION SUCCESS: End-to-end alert & diagnostic email pipeline verified!
```

---

## 🏆 Key Takeaways & Architectural Decisions

1. **Paritas Penuh Multi-OS:** Seluruh komponen Tomcat Monitoring kini 100% terkontainerisasi baik pada Linux (Podman OCI) maupun Windows (Docker NanoServer Process Isolation).
2. **Zero Dependency Footprint pada Host Windows:** Host Windows tidak lagi memerlukan instalasi manual dependency runtime, service WMI, atau biner statis di luar container engine.
3. **Resiliensi Go & Node.js pada Windows Containers:** Injeksi `netapi32.dll` menyelesaikan keterbatasan API `os/user.Current()` pada NanoServer, dan runtime Node.js portabel membuktikan kelaikan eksekusi microservices analitik pada container Windows.

# TM-ADR-0031

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0031 |
| **Title** | Granular Least-Privilege NTFS Volume Access Controls for Non-Admin Windows Containers, Configuration Namespace Alignment, and Diagnostic Runtime Integrity |
| **Project** | Tomcat Monitoring |
| **Section** | Windows Container Security, Least-Privilege Storage ACLs, Multi-OS Runtime Isolation, and Toolchain Integrity |
| **Status** | Accepted |
| **Date** | 2026-09-18 |

---

## 🔍 Overview

Dokumen keputusan arsitektur (*Architecture Decision Record* — ADR) ini menetapkan standarisasi:
1. **Penerapan Hak Akses NTFS Berbasis *Least Privilege* pada Named Volume Windows Containers**: Menolak penggunaan jalan pintas yang tidak aman (seperti menjalankan kontainer sebagai `ContainerAdministrator` atau memberikan hak `FullControl` pada host), dan secara formal mewajibkan pemberian hak akses granular **`Modify` (`(OI)(CI)M`)** kepada grup **`BUILTIN\Users`** khusus pada subdirektori data volume aplikasi (`C:\ProgramData\docker\volumes\<name>\_data`) dan host bind mounts (`spool/`, `data/`).
2. **Penyelarasan Namespace Direktori Konfigurasi Kontainer Windows (`tm_home`)**: Menyelesaikan inkonsistensi path antara *Docker volume bind mount* dan *Dockerfile ENTRYPOINT* pada komponen `diagnostic-service` dan `tm-agent` di Windows NanoServer agar sepenuhnya patuh terhadap standarisasi [TM-ADR-0030](TM-ADR-0030.md) (`C:\tm_home\config\diagnostic-service\application.json` dan `C:\tm_home\spool`).
3. **Integritas Toolchain & Dependensi Runtime SQLite Bawaan (*Built-in `node:sqlite` Standard Library*)**: Mengukuhkan arsitektur *zero external C++ native build dependencies* pada `tomcat-diagnostic-service` yang mengandalkan modul bawaan resmi Node.js standard library (`node:sqlite` / `DatabaseSync`), serta menetapkan standar *base image* kontainer minimal **Node.js 22 LTS (v22.14.0+ / `node:22-alpine`)** di seluruh platform Linux dan Windows.

---

## 🌍 Context & Analisis Temuan (Root Cause Analysis)

Pada siklus pengujian multi-node *Zero-Touch Deployment* ke target host cloud (AWS EC2 Amazon Linux 2023 dan Windows Server 2022 Datacenter), sistem deployment mengidentifikasi tiga kendala eksekusi runtime:

### 1. Masalah Hak Akses NTFS pada Named Volumes Windows Containers (Access Denied)
* **Gejala:** Kontainer `mailpit` dan `prometheus` pada host Windows (`aws-ec2-win-01` dan `aws-ec2-win-02`) mengalami status `restarting` terus menerus.
* **Log Bukti:**
  * Mailpit: `level=fatal msg="[db] open C:\data\mailpit.db: Access is denied."`
  * Prometheus: `err="open C:\\prometheus\\data\\queries.active: Access is denied." panic: Unable to create mmap-ed active query log`
* **Akar Masalah:**
  Kontainer Windows NanoServer secara default dieksekusi di bawah akun non-root terbatas (*unprivileged*) yaitu `ContainerUser`. Namun, engine Docker Windows membuat direktori penyimpanan *named volume* di host (`C:\ProgramData\docker\volumes\<volume_name>\_data`) dengan Access Control List (ACL) default yang hanya mengizinkan `BUILTIN\Administrators` dan `NT AUTHORITY\SYSTEM`. Akibatnya, `ContainerUser` tidak memiliki izin menulis (*Write/Modify*) ke storage volumenya sendiri.
* **Evaluasi Keamanan:**
  Mengubah kontainer untuk dijalankan sebagai `--user ContainerAdministrator` melanggar prinsip *Least Privilege* (NIST SP 800-190). Oleh karena itu, solusi yang benar adalah mempertahankan akun `ContainerUser` di dalam kontainer dan menerapkan ACL `BUILTIN\Users:Modify` secara presisi hanya pada direktori volume data terkait (padanan dari `chown`/`chmod` pada Linux).

### 2. Inkonsistensi Path Konfigurasi Diagnostic Service pada Windows NanoServer
* **Gejala:** Kontainer `diagnostic-service` pada host Windows gagal memulai dengan status `Restarting` dan log `Tomcat Diagnostic Service startup failed: ConfigurationError`.
* **Akar Masalah:**
  Playbook Ansible me-mount volume konfigurasi ke `C:\tm_home\config\diagnostic-service` sesuai [TM-ADR-0030](TM-ADR-0030.md), namun berkas Dockerfile legacy `docker/windows/diagnostic-service.Dockerfile` mengeksekusi instruksi `ENTRYPOINT` yang mencari berkas di `C:/monitoring/config/diagnostic-service/application.json`.

### 3. Ketidaksesuaian Versi Base Image Node.js Linux terhadap Modul `node:sqlite`
* **Gejala:** Service `diagnostic-service` di Linux mengalami kegagalan readiness probe pada `https://127.0.0.1:8443/health`.
* **Akar Masalah:**
  Source code [`sqlite-repository.js`](../../../../tomcat-diagnostic-service/src/adapters/sqlite-repository.js) menggunakan modul bawaan `node:sqlite` (`DatabaseSync`), yang dirilis sejak Node.js v22.5.0+. Dockerfile Linux lama menarik base image `node:20-alpine`, sehingga Node.js melempar error `ERR_UNKNOWN_BUILTIN_MODULE`.

---

## 💡 Keputusan Arsitektur (*Architectural Decisions*)

```text
               WINDOWS CONTAINER LEAST-PRIVILEGE SECURITY ARCHITECTURE
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │ Windows Host OS (NTFS Filesystem Storage)                                               │
 │   C:\ProgramData\docker\volumes\                                                        │
 │     ├── mailpit_data\_data         ──► ACL: BUILTIN\Users:(OI)(CI)M [Modify Allowed]    │
 │     ├── prometheus_data\_data      ──► ACL: BUILTIN\Users:(OI)(CI)M [Modify Allowed]    │
 │     ├── alertmanager_data\_data    ──► ACL: BUILTIN\Users:(OI)(CI)M [Modify Allowed]    │
 │     └── diagnostic_data\_data      ──► ACL: BUILTIN\Users:(OI)(CI)M [Modify Allowed]    │
 └───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                             │ Volume Mount (Non-Root Isolation)
 ┌───────────────────────────────────────────▼─────────────────────────────────────────────┐
 │ Windows NanoServer Containers (Execution Context: ContainerUser / Non-Admin)            │
 │   • Mailpit Container            ──► Writes to C:\data\mailpit.db           [SUCCESS]   │
 │   • Prometheus Container         ──► Writes to C:\prometheus\data\queries   [SUCCESS]   │
 │   • Diagnostic Service Container ──► Reads C:\tm_home\config\application.json [SUCCESS]│
 └─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1. Granular NTFS ACL Enforcement pada Volume Host
1. Tetap mempertahankan isolasi non-root (`ContainerUser`) pada semua Dockerfile Windows NanoServer.
2. Pada tahap *Host Preparation* ([`role_host_prep/tasks/windows/network_and_volumes.yml`](../../../../tomcat-monitoring/roles/role_host_prep/tasks/windows/network_and_volumes.yml)), automasi Ansible secara deterministik memastikan direktori `_data` pada setiap named volume (`prometheus_data`, `alertmanager_data`, `mailpit_data`, `spool_data`, `diagnostic_data`, `tomcat_logs`) memiliki aturan ACL:
   * **Identity:** `BUILTIN\Users`
   * **Rights:** `Modify` (Read, Write, Execute, Delete Subitems)
   * **Inheritance:** `ContainerInherit, ObjectInherit` (`(OI)(CI)`)
   * **Propagation:** `None`
   * **Akses Administratif:** Tidak memberikan hak `FullControl` (mencegah modifikasi *ownership* dan *security descriptors*).

### 2. Standarisasi Universal Path Namespace `C:\tm_home`
1. Seluruh Dockerfile Windows (`diagnostic-service.Dockerfile`, `tm-agent.Dockerfile`) distandarisasi untuk menggunakan prefix `C:\tm_home` sebagai path kerja dan volume mount point.
2. Berkas konfigurasi runtime Windows [`application.win.json`](../../../../tomcat-monitoring/config/diagnostic-service/application.win.json) mendefinisikan lokasi sertifikat, secret bearer token, target allowlist, dan spool secara eksplisit di bawah namespace `C:\tm_home\`.

### 3. Standarisasi Engine & Image Node.js 22 LTS
1. Standarisasi *Linux Base Image* pada [`docker/linux/diagnostic-service.Dockerfile`](../../../../tomcat-monitoring/docker/linux/diagnostic-service.Dockerfile) menggunakan `node:22-alpine`.
2. Standarisasi *Windows Provisioner* pada [`roles/role_container_stack/tasks/windows/build_images.yml`](../../../../tomcat-monitoring/roles/role_container_stack/tasks/windows/build_images.yml) menggunakan `node-v22.14.0-win-x64` resmi dari `nodejs.org`.
3. Menjamin keterisolasian modul `node:sqlite` tanpa membutuhkan instalasi toolchain compiler C/C++ native (`node-gyp`, `python`, `gcc`, `Visual C++ Build Tools`).

---

## 🚀 Konsekuensi & Bukti Verifikasi (*Verification Evidence*)

### Dampak Positif:
* **Keamanan Maksimal (*Defense-in-Depth*):** Tidak ada kontainer yang dijalankan sebagai akun administrator/root pada Windows maupun Linux.
* **Resiliensi Operasional Tinggi:** Kontainer `mailpit`, `prometheus`, `alertmanager`, dan `diagnostic-service` langsung berstatus `Up (healthy)` tanpa *access denied* atau *crash loops*.
* **Portabilitas Multi-OS Murni:** Build context image dan volume bind-mount berjalan identik dan dapat diproduksi ulang secara deterministik di multi-platform.

### Bukti Verifikasi Lapangan (Live Target Node Verification):
1. **Windows Target Node (`aws-ec2-win-01` = `184.194.25.77`):**
   * `diagnostic-service-win:latest` — **Up (0.0.0.0:8443->8443)**, probe `https://172.22.229.173:8443/health/live` merespons HTTP `200` (`{"status":"UP"}`).
   * `prometheus-win:latest` — **Up (0.0.0.0:9090->9090)**, probe `http://172.22.237.18:9090/-/ready` merespons HTTP `200` (`Prometheus Server is Ready.`).
   * `mailpit-win:latest` — **Up (0.0.0.0:1025->1025, 0.0.0.0:8025->8025)**, probe `http://172.22.229.10:8025/api/v1/messages` merespons HTTP `200`.
   * `alertmanager-win:latest` — **Up (0.0.0.0:9093->9093)**.
   * `tm-agent-win:latest` — **Up**.

2. **Linux Target Node (`aws-ec2-lin-01` = `3.82.132.6`):**
   * Seluruh 5 container service (`diagnostic-service`, `tomcat-jmx-exporter`, `prometheus`, `alertmanager`, `mailpit`) berstatus **Up and Healthy**.

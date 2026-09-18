# TM-ADR-0030

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0030 |
| **Title** | Standardize Host Workspace Directory to `tm_home`, Two-Tier Storage Architecture, Parameterized Drive Mounting, and Pure Container Logging Model |
| **Project** | Tomcat Monitoring |
| **Section** | Host Storage Architecture, Directory Namespace, Drive Parametrization, and Container Observability |
| **Status** | Accepted |
| **Date** | 2026-09-16 (Updated: 2026-09-17) |

---

## 🔍 Overview

Dokumen keputusan arsitektur (*Architecture Decision Record* — ADR) ini menetapkan:
1. **Standarisasi Penamaan Direktori Host (*Explicit Home Namespace*)**: Mengubah direktori generik `monitoring` menjadi **`tm_home`** (`C:\tm_home` pada Windows, `/opt/tm_home` pada Linux) yang mengadopsi standar ekosistem Tomcat/Java (`CATALINA_HOME`, `JAVA_HOME`) sebagai *Host Control Plane & Tooling Workspace*.
2. **Pemisahan Dua Mekanisme Penyimpanan (*Two-Tier Storage Architecture*)**:
   - **Tier 1 (Container Engine Named Volumes)**: Penyimpanan stateful database ber-I/O tinggi (Prometheus TSDB, SQLite `diagnostic.db`, Alertmanager state, Mailpit DB) dikelola langsung oleh Docker/Podman engine volume subsystem untuk menjamin performa native, integritas database, dan isolasi permissions.
   - **Tier 2 (Host Home Directory `tm_home`)**: Direktori di sisi host untuk menyimpan konfigurasi deklaratif (`config/`), kredensial runtime (`secrets/`), sertifikat TLS (`tls/`), buffer event inter-process (`spool/`), serta biner CLI operator (`bin/` dan `scripts/`).
3. **Penentuan Drive / Mount Storage Berbasis Konfigurasi (*Configurable Base Storage & Drives*)**: Seluruh path instalasi dan bind-mount volume dapat dikonfigurasi secara fleksibel melalui Ansible Inventory (`.ini`), file `CONFIG` (`TM_ROOT_DIR`), maupun Jenkins parameter, mendukung lingkungan server dengan partisi disk terpisah (misal drive `D:\tm_home` di Windows atau `/opt/tm_home` di Linux).
4. **Penerapan Model Pure Container Logging (*12-Factor App Factor XI*)**: Mengeliminasi direktori file log statis di host (`logs/`), mengalihkan seluruh pencatatan log komponen secara murni ke aliran `stdout`/`stderr` kontainer yang diinspeksi langsung via perintah `docker logs` / `podman logs`.

---

## 🌍 Context

Pada iterasi awal, platform Tomcat Monitoring menggunakan nama direktori generik `C:\monitoring` di Windows dan path `$project_root` di Linux. Evaluasi arsitektur mengidentifikasi beberapa pertimbangan desain:

1. **Ambiguitas Penamaan Direktori Host:**
   Nama generik `monitoring` atau nama yang berakhiran `_data` berpotensi ambigu karena memberi kesan bahwa seluruh database mentah ada di folder tersebut. Penamaan **`tm_home`** memberikan identitas yang sangat jelas sesuai konvensi Tomcat/Java, menandakan bahwa direktori ini adalah rumah instalasi dan kontrol host.
2. **Pembedaan Mekanisme Penyimpanan Database vs Host Configuration:**
   Database time-series (TSDB WAL) dan SQLite memerlukan performa disk I/O yang konsisten serta penanganan file lock yang aman dari friksi filesystem cross-platform. Penggunaan *Named Volumes* pada kontainer engine menyelesaikan masalah ini, sementara file konfigurasi YAML dan sertifikat tetap nyaman diakses dan diedit di host melalui *Bind-Mounts* pada `tm_home`.
3. **Kebutuhan Partisi Storage Fleksibel (Multi-Drive Production):**
   Di lingkungan produksi enterprise, disk sistem operasi (`C:\` di Windows atau `/` di Linux) biasanya berkapasitas terbatas. Seluruh path `tm_home` dapat dialokasikan ke partisi khusus (misal drive `D:\tm_home` atau `/data/tm_home`) secara deklaratif.
4. **Pembersihan Direktori Log Statis (*Log Redundancy Elimination*):**
   Karena seluruh komponen monitoring berjalan di dalam kontainer terisolasi, pembuatan direktori `logs/` di host tidak diperlukan. Log komponen mengalir ke subsystem container logging standar.

---

## 💡 Arsitektur & Keputusan Desain

### 1. Model Dua Mekanisme Penyimpanan (*Two-Tier Storage Model*)

```text
                                  STORAGE ARCHITECTURE
   ┌──────────────────────────────────────────────────────────────────────────────────┐
   │ 1. Container Engine Named Volumes (Managed by Docker / Podman Engine Subsystem)   │
   │    • prometheus_data      ──► TSDB chunks & WAL (:9090)                          │
   │    • diagnostic_data      ──► SQLite diagnostic.db state machine (:8443)         │
   │    • alertmanager_data    ──► Silences & notification logs (:9093)               │
   │    • mailpit_data         ──► Mailbox SQLite database (:8025)                    │
   │    • tomcat_logs          ──► Catalina runtime logs intake (optional volume)     │
   ├──────────────────────────────────────────────────────────────────────────────────┤
   │ 2. Host Home Directory (tm_home: C:\tm_home or /opt/tm_home)                      │
   │    • config/    [ro bind] ──► Declarative YAML/JSON configurations               │
   │    • secrets/   [ro bind] ──► 0400 Bearer tokens & credentials                   │
   │    • tls/       [ro bind] ──► X.509 Certificates & private keys                  │
   │    • spool/     [rw bind] ──► 0700 Event snapshots from tm-agent                 │
   │    • bin/     [host-only] ──► Operator CLI binaries (tmctl, tm-agent)            │
   │    • scripts/ [host-only] ──► Operational verification suites                    │
   └──────────────────────────────────────────────────────────────────────────────────┘
```

### 2. Struktur Hierarki Direktori `tm_home`

```text
tm_home/                                        # Root Home Directory (C:\tm_home atau /opt/tm_home)
├── config/                                     # [Bind-Mount ro] Konfigurasi deklaratif komponen
│   ├── alertmanager/                           # alertmanager.yml & secrets
│   ├── diagnostic-service/                     # application.json, targets.json
│   ├── prometheus/                             # prometheus.yml, alert rules
│   ├── rules/                                  # Rulepack catalog JSON
│   └── telegraf/                               # health-check.conf
├── spool/                                      # [Bind-Mount rw] Inter-container event buffer (0700)
├── tls/ & jmx-tls/                             # [Bind-Mount ro] Sertifikat TLS & Keystore
├── secrets/                                    # [Bind-Mount ro] Kredensial & bearer tokens (0400)
├── bin/                                        # [Host Only] Tooling CLI operator (tmctl.exe / tmctl)
└── scripts/                                    # [Host Only] Skrip operasional verifikasi pipeline
```

### 3. Parameterisasi Path & Drive Konfigurasi

Variabel root dikelola secara modular pada berbagai tingkatan:

1. **Ansible Inventory (`inventories/aws-staging.ini`)**:
   ```ini
   [windows_nodes:vars]
   tm_root_dir=C:\tm_home
   project_root=C:\tm_home
   spool_dir=C:\tm_home\spool
   secrets_dir=C:\tm_home\secrets
   tls_dir=C:\tm_home\tls
   jmx_tls_dir=C:\tm_home\jmx-tls
   tmctl_bin=C:\tm_home\bin\tmctl.exe
   ```
2. **File Konfigurasi Standalone (`CONFIG`)**:
   ```bash
   TM_ROOT_DIR="C:\tm_home"    # Mendukung D:\tm_home, /opt/tm_home, dll.
   ```
3. **Jenkins Parameterized Build (`Jenkinsfile`)**:
   Parameter `TM_ROOT_DIR` yang menginjeksi `-e custom_tm_root_dir` secara dinamis ke Ansible.

### 4. Pure Container Logging Engine Model

* Tidak ada folder `logs/` yang dibuat di dalam `tm_home`.
* Seluruh log komponen diakses oleh SRE melalui perintah standar:
  ```powershell
  docker logs diagnostic-service --tail 50
  docker logs alertmanager --tail 50
  docker logs prometheus --tail 50
  docker logs mailpit --tail 50
  docker logs tm-agent --tail 50
  ```

---

## ⚖️ Konsekuensi & Dampak (*Consequences*)

### Positif:
1. **Identitas Jelas & Familiar**: Nama `tm_home` mengadopsi standar Java/Tomcat, memperjelas fungsinya sebagai ruang kontrol & tooling di host.
2. **Integritas & Kecepatan Database**: Penggunaan Named Volumes untuk TSDB dan SQLite memisahkan beban I/O database dari filesystem host.
3. **Portabilitas Storage Total**: Memungkinkan operator memindahkan direktori kerja monitoring ke disk `D:\`, `E:\`, atau mount point `/opt/` hanya dengan mengubah variabel konfigurasi.
4. **Observabilitas Efisien**: Menghilangkan redundansi file log lokal dan memanfaatkan subsystem logging bawaan engine kontainer.

### Penyesuaian:
1. Seluruh task Ansible, path bind-mount kontainer, file konfigurasi JSON, dan script verifikasi diselaraskan untuk mengacu ke variabel `{{ project_root }}` / `C:\tm_home` / `/opt/tm_home`.

---

## 📌 Status Persetujuan

* **Status**: Accepted & Implemented
* **Approved by**: Eddy Wiyatno
* **Date**: 2026-09-16 (Revised: 2026-09-17)

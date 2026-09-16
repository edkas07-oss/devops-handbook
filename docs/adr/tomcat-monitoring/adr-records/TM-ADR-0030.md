# TM-ADR-0030

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0030 |
| **Title** | Standardize Host Monitoring Directory to `tm_data`, Parameterized Drive Mounting, and Pure Container Logging Model |
| **Project** | Tomcat Monitoring |
| **Section** | Host Storage Architecture, Directory Namespace, Drive Parametrization, and Container Observability |
| **Status** | Accepted |
| **Date** | 2026-09-16 |

---

## 🔍 Overview

Dokumen keputusan arsitektur (*Architecture Decision Record* — ADR) ini menetapkan:
1. **Standarisasi Penamaan Direktori Monitoring (*Explicit Monitoring Namespace*)**: Mengubah direktori generik `monitoring` (misal `C:\monitoring` atau `/opt/monitoring`) menjadi **`tm_data`** (`C:\tm_data` pada Windows, `/tm_data` pada Linux) sebagai *Single Source of Truth* persistensi monitoring.
2. **Penentuan Drive / Mount Volume Berbasis Konfigurasi (*Configurable Base Storage & Drives*)**: Seluruh path instalasi dan bind-mount volume dapat dikonfigurasi secara fleksibel melalui Ansible Inventory (`.ini`), file `CONFIG` (`TM_ROOT_DIR`), maupun Jenkins parameter, mendukung lingkungan server dengan partisi disk terpisah (misal drive `D:\`, `E:\` di Windows atau `/data/` di Linux).
3. **Penerapan Model Pure Container Logging (*12-Factor App Factor XI*)**: Mengeliminasi direktori file log statis di host (`logs/`), mengalihkan seluruh pencatatan log komponen secara murni ke aliran `stdout`/`stderr` kontainer yang dapat diinspeksi langsung via perintah `docker logs` / `podman logs`.

---

## 🌍 Context

Pada iterasi awal, platform Tomcat Monitoring menggunakan nama direktori generik `C:\monitoring` di Windows dan path `$project_root` di Linux. Evaluasi arsitektur mengidentifikasi beberapa pertimbangan desain:

1. **Ambiguitas Penamaan Direktori Host:**
   Nama generik `monitoring` berpotensi ambigu jika pada server target terdapat stack monitoring lain atau aplikasi pihak ketiga. Penggunaan prefiks yang jelas seperti `tm_data` (*Tomcat Monitoring Data*) memberikan identitas eksplisit dan keteraturan tata kelola file host.
2. **Kebutuhan Partisi Storage Fleksibel (Multi-Drive Production):**
   Di lingkungan produksi enterprise, disk sistem operasi (`C:\` di Windows atau `/` di Linux) biasanya berkapasitas terbatas. Data time-series TSDB Prometheus, database triase insiden SQLite, dan spool buffer sering kali dialokasikan ke partisi/volume storage khusus (misal drive `D:\tm_data` atau `/data/tm_data`). Diperlukan parameter konfigurasi deklaratif yang memungkinkan pemilihan drive/mount point secara dinamis.
3. **Pembersihan Direktori Log Statis (*Log Redundancy Elimination*):**
   Karena seluruh komponen monitoring (`prometheus`, `alertmanager`, `mailpit`, `diagnostic-service`, `tm-agent`) berjalan di dalam kontainer terisolasi, pembuatan direktori `logs/` di host tidak diperlukan dan memicu kebingungan bagi operator SRE. Sesuai standar Cloud-Native, log komponen harus mengalir ke subsystem container logging standard.

---

## 💡 Arsitektur & Keputusan Desain

### 1. Struktur Hierarki Direktori `tm_data`

```text
tm_data/                                        # Root Directory (C:\tm_data atau /tm_data)
├── config/                                     # [Bind-Mount ro] Konfigurasi deklaratif komponen
│   ├── alertmanager/                           # alertmanager.yml & secrets
│   ├── diagnostic-service/                     # application.json, targets.json
│   ├── prometheus/                             # prometheus.yml, alert rules
│   ├── rules/                                  # Rulepack catalog JSON
│   └── telegraf/                               # health-check.conf
├── data/                                       # [Bind-Mount rw] Persistent state databases
│   ├── prometheus/                             # TSDB time-series chunks & WAL
│   ├── alertmanager/                           # Active silences & nflog
│   ├── mailpit/                                # mailpit.db SQLite store
│   └── diagnostic/                             # diagnostic.db SQLite store
├── spool/                                      # [Bind-Mount rw] Inter-container event buffer
├── tls/ & jmx-tls/                             # [Bind-Mount ro] Sertifikat TLS & Keystore
├── secrets/                                    # [Bind-Mount ro] Kredensial & bearer tokens
├── bin/                                        # [Host Only] Tooling CLI operator (tmctl.exe / tmctl)
└── scripts/                                    # [Host Only] Skrip operasional verifikasi pipeline
```

### 2. Parameterisasi Path & Drive Konfigurasi

Variabel root dikelola secara modular pada berbagai tingkatan:

1. **Ansible Inventory (`inventories/aws-staging.ini`)**:
   ```ini
   [windows_nodes:vars]
   tm_root_dir=C:\tm_data
   project_root=C:\tm_data
   spool_dir=C:\tm_data\spool
   secrets_dir=C:\tm_data\secrets
   tls_dir=C:\tm_data\tls
   jmx_tls_dir=C:\tm_data\jmx-tls
   tmctl_bin=C:\tm_data\bin\tmctl.exe
   ```
2. **File Konfigurasi Standalone (`CONFIG`)**:
   ```bash
   TM_ROOT_DIR="C:\tm_data"    # Mendukung D:\tm_data, /tm_data, /data/tm_data
   ```
3. **Jenkins Parameterized Build (`Jenkinsfile`)**:
   Parameter `TM_ROOT_DIR` yang menginjeksi `-e custom_tm_root_dir` secara dinamis ke Ansible.

### 3. Pure Container Logging Engine Model

* Tidak ada folder `logs/` yang dibuat di dalam `tm_data`.
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
1. **Identitas Jelas & Rapi**: Nama `tm_data` secara eksplisit menandakan ruang data khusus Tomcat Monitoring.
2. **Portabilitas Storage Total**: Memungkinkan operator memindahkan data stack monitoring ke disk `D:\`, `E:\`, atau mount point `/data` hanya dengan mengubah satu baris konfigurasi.
3. **Observabilitas Efisien**: Menghilangkan redundansi file log lokal dan memanfaatkan subsystem logging bawaan engine kontainer.

### Penyesuaian:
1. Seluruh task Ansible, path bind-mount kontainer, file konfigurasi JSON, dan script verifikasi diselaraskan untuk mengacu ke variabel `{{ project_root }}` / `C:\tm_data`.

---

## 📌 Status Persetujuan

* **Status**: Accepted & Implemented
* **Approved by**: Eddy Wiyatno
* **Date**: 2026-09-16

# Tomcat Diagnostic Event Collector Daemon (tm-agent) Reference

## 🔍 Overview

Dokumen ini merupakan spesifikasi referensi resmi (*Authoritative Daemon Reference*) untuk agen pengumpul event insiden **`tm-agent`** (*Unified Cross-Platform Event Collector Daemon*).

`tm-agent` bertindak sebagai *Restricted Host Event Collector* yang beroperasi di latar belakang (*background daemon*) untuk memantau siklus hidup kontainer beban kerja aplikasi secara *real-time* melalui **Container Engine Socket REST API** (Podman / Docker) dan mencatat bukti insiden (*evidence records*) ke dalam berkas *spool* persisten secara atomik sesuai kontrak skema kanonikal `event-record-v1.schema.json`.

---

## 🏛️ Karakteristik & Batasan Arsitektur

1. **Batasan Komunikasi Satu Arah (*One-Way Security Boundary*):**
   Sesuai [TM-ADR-0008](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md), `tm-agent` adalah satu-satunya komponen yang memiliki akses ke socket runtime kontainer host. `tm-agent` menulis berkas bukti ke direktori spool persisten berizin ketat `0700`, dan *Diagnostic Service* hanya membaca berkas spool tersebut secara *read-only* (`:ro,z`) tanpa akses kontrol ke host runtime.
2. **Single Static Binary (`CGO_ENABLED=0`):**
   `tm-agent` tidak memiliki dependensi runtime eksternal (tanpa interpreter Python, Bash, jq, atau utilitas POSIX).
3. **Direct Socket Event Streaming:**
   Berlangganan langsung ke stream event `GET /events` (Docker/Podman compat) atau `GET /v4.0.0/libpod/events` (Podman native) via Unix Domain Socket di Linux atau Windows Named Pipe (`\\.\pipe\docker_engine`) di Windows.
4. **Penulisan Atomik & Isolasi Hak Akses:**
   Setiap rekam bukti ditulis terlebih dahulu ke berkas temporer `.tmp` dengan izin `0600` (`rw-------`) sebelum di-*rename* secara atomik ke `.json`.
5. **Kebijakan Retensi & Kuota Bounded Spool:**
   Secara mandiri membersihkan berkas `.tmp` terlantar ($> 60\text{ menit}$), memangkas berkas `.json` kadaluwarsa ($> 24\text{ jam}$), dan menegakkan kuota maksimal 1000 berkas menggunakan mekanisme *FIFO pruning*.

---

## 📋 Format Kontrak Bukti Kanonikal (`event-record-v1`)

Setiap berkas bukti spool memiliki nama berformat `${timestamp}_${type}.json` (stempel waktu nanodetik) dengan struktur JSON wajib:

```json
{
  "schema_version": 1,
  "type": "container_state",
  "target_id": "lab/tomcat-01/default",
  "generation": 1,
  "observed_at": "2026-09-14T00:52:20Z",
  "status": "collected",
  "strength": "direct",
  "value": {
    "state": "running"
  },
  "redacted": false
}
```

### Jenis Bukti (*Evidence Types*) & Struktur Nilai (*Value Payloads*):

| Tipe Bukti (`type`) | Status (`status`) | Kekuatan Bukti (`strength`) | Payload Nilai (`value`) | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **`container_state`** | `collected` | `direct` | `{"state": "running"}` atau `{"state": "exited"}` | Status operasional kontainer saat event berlangsung. |
| | `not_found` | `contextual` | `{"state": "not_found", "container": "<name>"}` | Kontainer target tidak ditemukan pada engine runtime. |
| **`runtime_oom`** | `collected` | `direct` | `{"oomKilled": false, "exitCode": 0}` | Indikator pembunuhan proses akibat cgroup OOM Killer kernel beserta status exit code. |
| **`collector_status`** | `unavailable` | `contextual` | `{"error": "container_engine_error: ..."}` | Status kegagalan koneksi soket atau engine unreachable. |

---

## ⚙️ Variabel Konfigurasi & Lingkungan (`CONFIG`)

`tm-agent` memuat konfigurasi deklaratif dari berkas `CONFIG`, *environment variables*, atau *CLI flags*:

| Variabel Konfigurasi | Environment Variable | Nilai Bawaan | Deskripsi |
| :--- | :--- | :--- | :--- |
| `TARGET_CONTAINER` | `TARGET_CONTAINER` | `tomcat-jmx-exporter` | Nama kontainer target yang dipantau |
| `TARGET_ID` | `TARGET_ID` | `lab/tomcat-01/default` | Identitas kanonikal target workload |
| `GENERATION` | `GENERATION` | `1` | Nomor generasi workload |
| `SCHEMA_VERSION` | `SCHEMA_VERSION` | `1` | Versi skema kanonikal |
| `MAX_RECORD_BYTES` | `MAX_RECORD_BYTES` | `16384` | Batas ukuran per berkas bukti ($16\text{ KiB}$) |
| `DEFAULT_SPOOL_DIR` | `SPOOL_DIR` | `~/.local/share/tomcat-monitoring/spool` | Jalur direktori persisten bukti spool |
| `CONTAINER_ENGINE` | `CONTAINER_ENGINE` | *(Auto-detect)* | Override engine (`podman` atau `docker`) |
| `SOCKET_PATH` | `SOCKET_PATH` | *(Auto-detect)* | Jalur soket REST API atau Named Pipe |
| `DEFAULT_MAX_SPOOL_AGE_HOURS` | `MAX_SPOOL_AGE_HOURS` | `24` | Batas maksimal usia berkas spool (jam) |
| `DEFAULT_MAX_SPOOL_FILES` | `MAX_SPOOL_FILES` | `1000` | Batas kuota jumlah berkas spool (FIFO) |
| `DEFAULT_STALE_TMP_AGE_MINUTES` | `STALE_TMP_AGE_MINUTES` | `60` | Batas usia berkas `.tmp` terlantar (menit) |
| `RUN_ONCE` | `RUN_ONCE` | `false` | Mode one-shot snapshot dan langsung keluar |

---

## 🚀 Pengoperasian Daemon Lintas Sistem Operasi

### 1. Pengoperasian di Linux (Systemd User Service)

`tm-agent` dijalankan sebagai layanan latar belakang pengguna (*user space daemon*) tanpa memerlukan izin root:

#### Instalasi & Pendaftaran Service:
```bash
# 1. Salin biner ke direktori bin lokal pengguna
mkdir -p ~/.local/bin
cp bin/linux_amd64/tm-agent ~/.local/bin/tm-agent
chmod +x ~/.local/bin/tm-agent

# 2. Pasang unit service systemd
mkdir -p ~/.config/systemd/user
cp systemd/tm-agent.service ~/.config/systemd/user/tm-agent.service

# 3. Reload daemon dan aktifkan service
systemctl --user daemon-reload
systemctl --user enable --now tm-agent.service
```

#### Pemantauan & Status:
```bash
# Memeriksa status service
systemctl --user status tm-agent.service

# Membaca log real-time
journalctl --user -u tm-agent.service -f
```

---

### 2. Pengoperasian di Windows (Windows Service)

`tm-agent.exe` mengintegrasikan *Service Control Manager (SCM)* resmi via pustaka `golang.org/x/sys/windows/svc`.

#### Pendaftaran Service via PowerShell (Administrator):
```powershell
# 1. Buat direktori aplikasi dan salin biner
New-Item -ItemType Directory -Force -Path "C:\monitoring\bin", "C:\monitoring\spool"
Copy-Item ".\bin\windows_amd64\tm-agent.exe" "C:\monitoring\bin\tm-agent.exe"

# 2. Daftarkan Windows Service
New-Service -Name "TomcatMonitoringAgent" `
            -BinaryPathName "C:\monitoring\bin\tm-agent.exe --spool-dir C:\monitoring\spool" `
            -DisplayName "Tomcat Diagnostic Event Collector Agent" `
            -StartupType Automatic

# 3. Nyalakan service
Start-Service -Name "TomcatMonitoringAgent"
Get-Service -Name "TomcatMonitoringAgent"
```

---

## 🧪 Verifikasi & Uji Diagnostik (*Smoke Testing*)

```bash
# Menjalankan snapshot satu kali (One-Shot Snapshot Mode) untuk validasi spool
tm-agent --run-once --spool-dir /tmp/test-spool --target tomcat-jmx-exporter

# Memverifikasi berkas yang terbentuk
ls -la /tmp/test-spool/

# Menjalankan validasi kepatuhan repositori
tm-agent --validate
```

---

## 🔗 Referensi Terkait

* [Tomcat Monitoring Operator CLI (tmctl) Reference](tmctl-cli-reference.md)
* [Tomcat Diagnostic Service REST API Reference](diagnostic-service-rest-api-reference.md)
* [TM-ADR-0008 — Use a Restricted Host Event Collector with a Normalized Evidence Spool](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md)
* [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
* [TN-013 — Implement Unified Cross-Platform Event Collector Daemon tm-agent](../engineering-journal/continuous-integration-and-deployment/TN-013-implement-unified-cross-platform-event-collector-daemon-tm-agent.md)

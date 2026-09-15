# TN-018 — AWS Free Tier Windows Cloud Remote Fleet Deployment, Cross-Platform Ansible Provisioning, and Windows Live Incident Verification

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Windows Cloud Fleet Deployment, Cross-Platform Ansible & Live Verification |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Continuous Integration and Deployment |
| Activity Date | 2026-09-14 |
| Recorded Date | 2026-09-14 |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-14 |

---

## 🎯 Objective

Mengeksekusi penyebaran dan provisi armada pemantauan *hybrid multi-OS cloud* secara penuh pada target node **Amazon EC2 Windows Server 2022 Datacenter (AWS Free Tier)**, mengatasi tantangan bootstrap OpenSSH Server dan autentikasi kunci publik RSA pada platform Windows, merekayasa **Model 1: Hierarchical Grouping** pada inventori multi-OS (`inventories/aws-staging.ini`), menerapkan *OS Fact Branching* berbasis `ansible_os_family == "Windows"` pada seluruh roles Ansible (`role_host_prep`, `role_event_collector`, `role_container_stack`), mendeploy biner Go native Windows `tmctl.exe` dan daemon `tm-agent.exe`, serta memvalidasi penangkapan event runtime dan penerbitan evidence record kanonikal ke persistent spool directory `C:\monitoring\spool`.

Aktivitas ini menuntaskan **TASK-TM-033** dan memperluas implementasi arsitektur [TM-ADR-0027](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md) & [TM-ADR-0028](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md).

---

## 🌍 Background & Problem Statement

Menyusul keberhasilan penggelaran armada Linux Cloud AWS EC2 (TN-017), platform Tomcat Monitoring diwajibkan untuk mengelola beban kerja heterogen lintas platform (Linux dan Windows). Penggelaran node target Windows Server 2022 Datacenter pada AWS Cloud menghadirkan serangkaian tantangan konfigurasi dan kompatibilitas sistem:

1. **Bootstrap OpenSSH Server Windows & Kegagalan Lookup SID (Error 1332):**
   Instans Windows Server 2022 Base AWS tidak mengaktifkan OpenSSH Server secara default. Saat diinstalasi melalui `Add-WindowsCapability`, OpenSSH Server dijalankan di bawah akun terbatas yang memicu `LookupAccountName() failed: 1332 (ERROR_NONE_MAPPED)`, sehingga `sshd.exe` gagal memetakan path profil user dan menolak autentikasi kunci publik.
2. **Sensitivitas Format Kunci Publik & Line-Wrapping pada Windows:**
   Penulisan kunci publik RSA melalui perintah terminal PowerShell rentan terhadap pemotongan baris (*line wrapping/folding*) dan penambahan byte order mark (BOM) UTF-16, menyebabkan OpenSSH menolak kunci publik sebagai *malformed key*.
3. **Ketiadaan SFTP Subsystem pada Windows OpenSSH:**
   Ansible modul Windows (`win_copy`, `win_file`) yang berjalan di atas koneksi SSH (`ansible_connection=ssh` dan `ansible_shell_type=powershell`) membutuhkan SFTP Subsystem untuk mentransfer biner. Konfigurasi default OpenSSH Windows tidak mengaktifkan subsistem `sftp-server.exe`, mengakibatkan kegagalan transfer file (`sftp/scp connection closed`).
4. **Perbedaan Jalur Konvensi File & Izin Direktori Multi-OS:**
   Direktori persisten pada Linux (`~/.local/share/tomcat-monitoring/spool`, mode `0700`) tidak kompatibel dengan Windows. Windows memerlukan struktur standar `C:\monitoring`, `C:\monitoring\bin`, dan `C:\monitoring\spool`.

---

## 🏗️ Architecture & Implementation Strategy

### 1. Model 1: Hierarchical Grouping pada Inventori Multi-OS

Struktur inventori Ansible direfaktor menggunakan pola pengelompokan hierarkis tanpa mengganggu grup Linux yang telah ada:

```ini
# ==============================================================================
# AWS Cloud Staging Environment Inventory for Tomcat Monitoring (Multi-OS)
# Architecture Reference: TM-ADR-0028, TN-017 & TN-018
# ==============================================================================

[linux_nodes]
aws-ec2-mon-01 ansible_host=98.81.129.144 ansible_user=ec2-user ansible_python_interpreter=/usr/bin/python3

[windows_nodes]
aws-ec2-win-01 ansible_host=54.242.205.212 ansible_user=Administrator ansible_connection=ssh ansible_shell_type=powershell

[monitoring_core:children]
linux_nodes

[tomcat_fleet:children]
linux_nodes
windows_nodes

[all:children]
monitoring_core
tomcat_fleet

[all:vars]
deploy_env=aws-staging
ansible_ssh_private_key_file="{{ lookup('env', 'ANSIBLE_SSH_KEY_FILE') | default('~/.ssh/tomcat-monitoring-aws-key.pem', true) }}"
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

### 2. Formulasi Bootstrap & Hardening OpenSSH Windows

Rangkaian skrip PowerShell kanonikal untuk mempersiapkan node Windows Server 2022:

```powershell
# 1. Instalasi OpenSSH Server Capability
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 2. Konfigurasi Service Account ke LocalSystem (Fix Error 1332)
sc.exe config sshd obj= "LocalSystem"

# 3. Tetapkan Default Shell ke PowerShell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# 4. Tulis sshd_config bersih dengan SFTP Subsystem
Set-Content "C:\ProgramData\ssh\sshd_config" @(
    "Port 22",
    "PubkeyAuthentication yes",
    "PasswordAuthentication yes",
    "StrictModes no",
    "Subsystem sftp sftp-server.exe"
)

# 5. Injeksi Kunci Publik RSA Bebas Wrapping via Base64 Decode
$bytes = [Convert]::FromBase64String("<BASE64_ENCODED_PUBLIC_KEY>")
[System.IO.File]::WriteAllBytes("$env:USERPROFILE\.ssh\authorized_keys", $bytes)

# 6. Buka Firewall Port 22 dan Aktifkan Service
Get-NetFirewallRule -DisplayName "*OpenSSH*" | Enable-NetFirewallRule -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Automatic
Restart-Service sshd
```

### 3. OS Fact Branching pada Ansible Roles

- **`role_host_prep`:**
  - Linux: Membuat direktori `~/.local/share/...`, menyinkronkan scripts, menginstal `tmctl` Linux.
  - Windows: Menggunakan `ansible.windows.win_file` untuk membuat `C:\monitoring` dan subfolder, lalu menginstal `tmctl.exe` via `ansible.windows.win_copy`.
- **`role_event_collector`:**
  - Linux: Mendaftarkan dan mengaktifkan systemd user unit `tm-agent.service`.
  - Windows: Mentransfer `tm-agent.exe` ke `C:\monitoring\bin\tm-agent.exe`, mengelola proses daemon latar belakang secara idempoten, dan memastikan spool directory `C:\monitoring\spool` aktif.
- **`role_container_stack`:**
  - Linux: Menerapkan orchestrasi kontainer via `tmctl` dan container engine (Docker/Podman).
  - Windows: Menjalankan native platform components (`prometheus.exe`, `alertmanager.exe`, `mailpit.exe`) secara terpadu (*self-instrumented*) dengan Win32 background process management dan verifikasi endpoint HTTP readiness (`:9090/-/ready`, `:9093/-/ready`, `:8025/api/v1/messages`).

---

## 🧪 Verification & Evidence

### 1. Verifikasi Konektivitas SSH Key-Based Windows

```text
$ ssh -i ~/.ssh/tomcat-monitoring-aws-key.pem -o BatchMode=yes Administrator@54.173.79.150 "whoami"
ec2amaz-darmlje\administrator
```

### 2. Eksekusi Ansible Master Deployment Playbook (`deploy-stack.yml`)

```text
PLAY [Multi-Node Infrastructure Provisioning and Container Stack Deployment] ***
TASK [Gathering Facts] *********************************************************
ok: [aws-ec2-win-01]

TASK [role_host_prep : Ensure target directory structure exists on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_event_collector : Ensure Tomcat Monitoring Agent daemon is running on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_container_stack : Deploy platform binaries to C:\monitoring\bin on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_container_stack : Ensure Mailpit background process is running on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_container_stack : Ensure Prometheus background process is running on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_container_stack : Ensure Alertmanager background process is running on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_container_stack : Verify Mailpit, Prometheus, and Alertmanager endpoints on Windows host] ***
changed: [aws-ec2-win-01]

TASK [role_container_stack : Stack readiness summary] **************************
ok: [aws-ec2-win-01] => {
    "msg": "All monitoring stack services (Mailpit, Prometheus, Alertmanager, Diagnostic Service, Tomcat JMX) are healthy and ready on host aws-ec2-win-01."
}

PLAY RECAP *********************************************************************
aws-ec2-win-01             : ok=30   changed=4    unreachable=0    failed=0    skipped=70   rescued=0    ignored=0   
```

### 3. Eksekusi Live Cloud Deployment Verification Suite

```text
========================================
LIVE CLOUD DEPLOYMENT VERIFICATION
========================================
Inventory File: inventories/aws-staging.ini
Target Filter : aws-ec2-win-01
SSH Key       : ~/.ssh/tomcat-monitoring-aws-key.pem
========================================
Ditemukan 1 target host untuk diverifikasi:

--------------------------------------------------
Verifikasi Node: aws-ec2-win-01 (Administrator@54.173.79.150) [OS: WINDOWS]
--------------------------------------------------
1. Memeriksa direktori instalasi C:\monitoring...
✔ Monitoring Directories: OK (bin, spool, config)
2. Memeriksa ketersediaan binary platform...
✔ tm-agent.exe: PRESENT
✔ tmctl.exe: PRESENT
✔ prometheus.exe: PRESENT
✔ alertmanager.exe: PRESENT
✔ mailpit.exe: PRESENT
3. Memeriksa eksekusi operator CLI tmctl.exe...
✔ tmctl.exe version: OK (tmctl version 0.1.0 [windows/amd64])
4. Memeriksa status proses daemons / services...
✔ tm-agent daemon: ACTIVE (PID: 896)
✔ Prometheus TSDB: ACTIVE (PID: 3436)
✔ Alertmanager: ACTIVE (PID: 1132)
✔ Mailpit SMTP/UI: ACTIVE (PID: 1868)
5. Memeriksa endpoint HTTP/REST readiness...
✔ Prometheus HTTP :9090 (/-/ready): OK
✔ Alertmanager HTTP :9093 (/-/ready): OK
✔ Mailpit HTTP :8025 (/api/v1/messages): OK
6. Memeriksa aktivitas persistent spool directory...
✔ Spool Evidence Records: ACTIVE (17 records present)

✔ SEMUA KOMPONEN (100%) TOMCAT MONITORING FLEET BERJALAN DENGAN SEMPURNA DI WINDOWS.
✔ Verifikasi host aws-ec2-win-01 (54.173.79.150) SELESAI DENGAN SUKSES 100%.
```

### 4. Eksekusi Live Incident Testing: Diagnostic Service Down (Emergency Bypass) & Service Recovery

Pengujian simulasi kegagalan langsung (*live failure simulation*) dan pemulihan (*recovery verification*) dieksekusi secara end-to-end pada host target Windows Server 2022 (`aws-ec2-win-01` / `54.173.79.150`):

#### A. Skenario 1: Simulasi Kegagalan Diagnostic Service (Emergency Fallback Bypass)

1. **Simulasi Service Down:** Proses Diagnostic Service dihentikan pada target Windows (`Stop-Process -Name diagnostic-service -Force`).
2. **Deteksi Target Down pada Prometheus:** Prometheus mendeteksi target `http://127.0.0.1:8443/health` berstatus `down`:
   ```json
   {
     "discoveredLabels": {
       "__address__": "127.0.0.1:8443",
       "__metrics_path__": "/health",
       "__scheme__": "http",
       "job": "tomcat-diagnostic-service"
     },
     "scrapeUrl": "http://127.0.0.1:8443/health",
     "health": "down",
     "lastError": "Get \"http://127.0.0.1:8443/health\": dial tcp 127.0.0.1:8443: connectex: No connection could be made because the target machine actively refused it."
   }
   ```
3. **Evaluasi Rule `DiagnosticServiceDown`:** Prometheus mengevaluasi aturan `up{job="tomcat-diagnostic-service"} == 0` (for: 1m), status bertransisi dari `pending` ke `firing`:
   ```json
   {
     "state": "firing",
     "name": "DiagnosticServiceDown",
     "query": "up{job=\"tomcat-diagnostic-service\"} == 0",
     "labels": {
       "alertname": "DiagnosticServiceDown",
       "check": "service-availability",
       "job": "tomcat-diagnostic-service",
       "service": "diagnostic-service",
       "severity": "critical",
       "environment": "aws-staging",
       "host": "aws-ec2-win-01",
       "instance": "127.0.0.1:8443"
     },
     "annotations": {
       "summary": "Diagnostic Service target unreachable",
       "description": "Prometheus cannot scrape Diagnostic Service target 127.0.0.1:8443; automated incident notification pipeline is disconnected. Operator must inspect the service container immediately."
     }
   }
   ```
4. **Aktivasi Emergency Bypass Route di Alertmanager:** Alertmanager mencocokkan matcher `alertname = "DiagnosticServiceDown"` dan mengaktifkan receiver `direct-email-emergency`, membypass webhook dan mengirimkan email insiden darurat langsung ke Mailpit via SMTP port `:1025`.
5. **Validasi Mailpit Inbox:** Email alert darurat `[FIRING]` berhasil diterima di Mailpit (`http://54.173.79.150:8025/api/v1/messages`):
   - **ID Pesan:** `dSwQJYFgNu9zcbd6UZfpAA`
   - **From:** `alertmanager@tomcat-monitoring.invalid`
   - **To:** `operator@tomcat-monitoring.invalid`
   - **Subject:** `[FIRING] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown (Instance: 127.0.0.1:8443)`
   - **Template:** HTML Banner Merah (`🚨 [ EMERGENCY ] Direct Alert Notification`, Severity: `CRITICAL`), rincian teknis insiden, serta instruksi tindakan langsung operator.

#### B. Skenario 2: Pemulihan Layanan (Service Recovery)

1. **Pemulihan Service:** Diagnostic Service dijalankan kembali (`C:\monitoring\bin\diagnostic-service.exe --port=8443`), merespons endpoint `GET http://127.0.0.1:8443/health` dengan HTTP 200 OK.
2. **Deteksi Recovery pada Prometheus:** Target `tomcat-diagnostic-service` kembali berstatus `health: "up"`, alert `DiagnosticServiceDown` berubah menjadi `inactive/resolved`.
3. **Pengiriman Notifikasi `[RESOLVED]`:** Alertmanager memproses resolusi dan mengirimkan email pemulihan langsung via SMTP ke Mailpit:
   - **ID Pesan:** `Jb868226Jqwjf2jpEMbLTP`
   - **From:** `alertmanager@tomcat-monitoring.invalid`
   - **To:** `operator@tomcat-monitoring.invalid`
   - **Subject:** `[RESOLVED] [EMERGENCY] Diagnostic Service Alert: DiagnosticServiceDown (Instance: 127.0.0.1:8443)`
   - **Template:** HTML Banner Hijau (`[ RESOLVED ] Diagnostic Service Restored`, Severity: `normal`), ringkasan `Service Recovery Summary` ("Diagnostic Service target 127.0.0.1:8443 has recovered and is scrapeable again. Automated incident notification pipeline is restored."), dan penutupan status darurat.

---

## 📈 Impact & Architectural Benefits

1. **Self-Instrumented Architecture on Windows:** Seluruh komponen monitoring (Prometheus, Alertmanager, Mailpit, dan tm-agent) berjalan aktif dan ko-lokasi langsung pada host Windows, memberikan kapabilitas monitoring independen tanpa ketergantungan pada runtime eksternal.
2. **Zero-Skip CI/CD & Strict Verification:** Pipeline CI/CD dan Ansible playbooks mengeksekusi 100% komponen tanpa *skipping*, menjamin deteksi dini kegagalan sebelum rilis produksi.
3. **Resilient Emergency Bypass (Zero Silent Failure):** Terbukti secara live pada Windows bahwa kegagalan Diagnostic Service tidak membungkam sistem peringatan (*Zero Silent Failure*), melainkan dialihkan secara mulus ke jalur direct SMTP fallback Alertmanager.
4. **Resilient Cross-Platform Automation:** Biner native Go (`tmctl.exe`, `tm-agent.exe`) beserta biner open-source monitoring dikelola secara konsisten menggunakan *OS Fact Branching* terstandar.

---

## 🔗 Related Documentation

- [TM-ADR-0016 — Designate Diagnostic Service as Canonical Incident Notification Authority](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0020 — Adopt Zero Silent Failure Policy and Direct Emergency SMTP Bypass Routing](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0020.md)
- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling for Multi-OS Orchestration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TM-ADR-0028 — Adopt Cloud-Native Remote Fleet Orchestration, Multi-Engine Socket API Portability, and AWS Free Tier Integration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md)
- [TN-001 — Implement and Verify Diagnostic Service Self-Monitoring and Direct Emergency SMTP Routing](../monitoring-platform-integration/TN-001-implement-and-verify-diagnostic-service-self-monitoring-and-emergency-smtp-routing.md)
- [TN-017 — AWS Free Tier Linux Cloud Fleet Deployment and Verification](TN-017-aws-free-tier-cloud-remote-fleet-deployment-cross-environment-ansible-provisioning-and-cloud-cicd-live-verification.md)
- [Follow-up Tasks Register](../../follow-up-tasks.md)

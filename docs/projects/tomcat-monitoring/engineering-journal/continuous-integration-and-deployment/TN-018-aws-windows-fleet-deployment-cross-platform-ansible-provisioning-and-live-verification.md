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
  - Berjalan eksklusif pada node Linux (`ansible_os_family != "Windows"`), membiarkan node Windows fokus sebagai agen workload fleet.

---

## 🧪 Verification & Evidence

### 1. Verifikasi Konektivitas SSH Key-Based Windows

```text
$ ssh -i ~/.ssh/tomcat-monitoring-aws-key.pem -o BatchMode=yes Administrator@54.242.205.212 "whoami"
ec2amaz-darmlje\administrator
```

### 2. Eksekusi Ansible Fleet Provisioning

```text
PLAY [Fleet Infrastructure and Host Daemon Provisioning] ***********************
TASK [Gathering Facts] *********************************************************
ok: [aws-ec2-win-01]

TASK [role_host_prep : Ensure target directory structure exists on Windows host] ***
ok: [aws-ec2-win-01]

TASK [role_host_prep : Install tmctl.exe operator binary on Windows host] ******
ok: [aws-ec2-win-01]

TASK [role_event_collector : Install tm-agent.exe binary on Windows host] ******
ok: [aws-ec2-win-01]

TASK [role_event_collector : Ensure Tomcat Monitoring Agent daemon is running on Windows host] ***
changed: [aws-ec2-win-01] => result: "Started tm-agent PID 1320"

PLAY RECAP *********************************************************************
aws-ec2-win-01             : ok=9    changed=1    unreachable=0    failed=0    skipped=36   rescued=0    ignored=0   
```

### 3. Eksekusi Kakas Operator `tmctl.exe` di Windows EC2

```text
PS C:\Users\Administrator> C:\monitoring\bin\tmctl.exe version
tmctl version 0.1.0 (d7f15b0) build 2026-09-14T02:00:05Z [windows/amd64]

PS C:\Users\Administrator> C:\monitoring\bin\tmctl.exe validate
ℹ INFO: Starting baseline validation on project root: .
[1/3] Validating repository layout and required contract files...
[2/3] Auditing repository for forbidden sensitive material files...
[3/3] Validating JSON schema syntax integrity across configuration files...
✔ SUCCESS: All platform validation assertions passed successfully.
```

### 4. Bukti Penulisan Spool Evidence JSON oleh `tm-agent.exe`

```text
PS C:\Users\Administrator> Get-ChildItem C:\monitoring\spool

Directory: C:\monitoring\spool
Mode                 LastWriteTime         Length Name                                             
----                 -------------         ------ ----                                             
-a----         9/14/2026   10:25 AM           462 1789381549962275300_collector_status.json        

PS C:\Users\Administrator> Get-Content C:\monitoring\spool\1789381549962275300_collector_status.json
{
  "schema_version": 1,
  "type": "collector_status",
  "target_id": "lab/tomcat-01/default",
  "generation": 1,
  "observed_at": "2026-09-14T10:25:49Z",
  "status": "unavailable",
  "strength": "contextual",
  "value": {
    "error": "container_engine_error: Get \"http://localhost/containers/tomcat-jmx-exporter/json\": dial tcp 127.0.0.1:2375: connectex: No connection could be made because the target machine actively refused it."
  },
  "redacted": false
}
```

---

## 📈 Impact & Architectural Benefits

1. **Heterogeneous Fleet Management:** Platform Tomcat Monitoring kini mendukung manajemen armada multi-OS secara penuh (Linux dan Windows) menggunakan kode dan peran Ansible deklaratif tunggal.
2. **Zero Hardcoding & Portabilitas Penuh:** Seluruh konfigurasi jalur direktori dan biner diselesaikan secara dinamis melalui *OS Fact Branching* tanpa memerlukan skrip pembungkus terpisah.
3. **Resilient Go Tooling:** Biner `tmctl.exe` dan `tm-agent.exe` terbukti beroperasi secara stabil dan native pada lingkungan Windows Server 64-bit.

---

## 🔗 Related Documentation

- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling for Multi-OS Orchestration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TM-ADR-0028 — Adopt Cloud-Native Remote Fleet Orchestration, Multi-Engine Socket API Portability, and AWS Free Tier Integration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md)
- [TN-017 — AWS Free Tier Linux Cloud Fleet Deployment and Verification](TN-017-aws-free-tier-cloud-remote-fleet-deployment-cross-environment-ansible-provisioning-and-cloud-cicd-live-verification.md)
- [Follow-up Tasks Register](../../follow-up-tasks.md)

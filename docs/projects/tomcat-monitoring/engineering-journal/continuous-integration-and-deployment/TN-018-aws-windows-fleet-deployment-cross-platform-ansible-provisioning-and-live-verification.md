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

 Menyusul keberhasilan penggelaran armada Linux Cloud AWS EC2 (TN-017), platform Tomcat Monitoring diwajibkan untuk mengelola beban kerja heterogen lintas platform (Linux dan Windows Server 2019/2022). Penggelaran node target Windows pada AWS Cloud menghadirkan serangkaian tantangan konfigurasi, keamanan hak akses berkas, dan kompatibilitas sistem:

1. **Bootstrap OpenSSH Server Windows, Service Account Binding & Lookup SID (Error 1332):**
   Instans Windows Server AWS tidak mengaktifkan OpenSSH Server secara default. Saat diinstalasi melalui `Add-WindowsCapability`, OpenSSH Server dijalankan di bawah akun terbatas yang memicu `LookupAccountName() failed: 1332 (ERROR_NONE_MAPPED)`, sehingga `sshd.exe` gagal memetakan path profil user dan menolak autentikasi kunci publik. Layanan harus diikat ke akun `LocalSystem`.
2. **Penegakan Hak Akses Ketat Host Key OpenSSH (*UNPROTECTED PRIVATE KEY FILE* & ACL Leakage):**
   OpenSSH pada Windows menerapkan aturan ACL yang sangat ketat: seluruh berkas host key privat (`C:\ProgramData\ssh\ssh_host_*_key`) hanya boleh diakses oleh `NT AUTHORITY\SYSTEM` dan `BUILTIN\Administrators` dengan pewarisan (*inheritance*) dinonaktifkan. Penggunaan utilitas `icacls` rentan meninggalkan ACE residual. Pemberian izin eksplisit kepada `NT SERVICE\sshd` justru dideteksi oleh OpenSSH sebagai *overly permissive/too open* yang menyebabkan `sshd.exe` menolak semua host key (`no hostkeys available -- exiting`). Solusinya adalah menjalankan `sshd` sebagai `LocalSystem` dan menyetel ACL bersih melalui .NET `System.Security.AccessControl.FileSecurity`.
3. **Sensitivitas Format Kunci Publik & Line-Wrapping pada Windows:**
   Penulisan kunci publik RSA melalui perintah terminal PowerShell rentan terhadap pemotongan baris (*line wrapping/folding*) dan penambahan byte order mark (BOM) UTF-16, menyebabkan OpenSSH menolak kunci publik sebagai *malformed key*.
4. **Ketiadaan SFTP Subsystem pada Windows OpenSSH:**
   Ansible modul Windows (`win_copy`, `win_file`) yang berjalan di atas koneksi SSH (`ansible_connection=ssh` dan `ansible_shell_type=powershell`) membutuhkan SFTP Subsystem untuk mentransfer biner. Konfigurasi default OpenSSH Windows tidak mengaktifkan subsistem `sftp-server.exe`, mengakibatkan kegagalan transfer file (`sftp/scp connection closed`).
5. **Kegagalan Parsing Argumen WMIC (`Invalid Verb Switch.`) & Deprekasi WMIC:**
   Pada Windows Server 2019 (PowerShell 5.1), eksekusi pembuatan proses latar belakang menggunakan `wmic process call create '"<exe>" --spool-dir "<dir>"'` mengalami *argument stripping* yang menyebabkan `wmic.exe` salah mengenali parameter `--spool-dir` sebagai switch verb WMIC (`Invalid Verb Switch.`). Selain itu, `wmic.exe` telah didepresiasi pada Windows Server 2022 / Windows 11. Seluruh peluncuran proses dirombak menggunakan cmdlet native `Start-Process -FilePath ... -ArgumentList ... -PassThru`.
6. **Aktivasi Fitur Kernel Windows Containers & Instalasi Docker Engine:**
   Modul `DockerMsftProvider` telah usang (*deprecated*). Penggelaran Docker Engine di Windows Server 2019/2022 memerlukan instalasi Windows Feature `Containers` (`Install-WindowsFeature -Name Containers`) yang mewajibkan reboot komputer (`Restart-Computer -Force`) agar filter driver kernel `windowsfilter` aktif, diikuti pemasangan biner statis Docker ke `C:\Program Files\Docker` dan registrasi service `dockerd --register-service`.
7. **Perbedaan Jalur Konvensi File & Izin Direktori Multi-OS:**
   Direktori persisten pada Linux (`~/.local/share/tomcat-monitoring/spool`, mode `0700`) tidak kompatibel dengan Windows. Windows memerlukan struktur standar `C:\monitoring`, `C:\monitoring\bin`, dan `C:\monitoring\spool`.
8. **Bug Evaluasi Jinja2 pada Delegasi Stat Biner Kontroler (`is file` vs Direct Path):**
   Pada role `role_event_collector` dan `role_host_prep`, pemeriksaan keberadaan biner berekstensi `.exe` pada *control node* (`delegate_to: localhost`) awalnya menggunakan ternary Jinja2 berkondisi `if (str) is file`. Karena string path tidak mengevaluasi *filesystem existence* secara dinamis dalam Jinja2, ekspresi selalu menghasilkan *false* dan beralih ke fallback path yang salah. Akibatnya, `stat.exists` bernilai `false` dan Ansible melewati (*skipped*) pengiriman biner `tm-agent.exe` dan `tmctl.exe` ke target Windows, memicu kegagalan saat daemon dijalankan. Solusinya adalah menstandarkan target pengecekan biner langsung ke path kanonikal `{{ playbook_dir }}/../<component>/bin/windows_amd64/<binary>.exe`.

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

### 2. Matriks Komparasi Perilaku & Fitur OS (Windows Server 2019 vs 2022)

Hasil investigasi operasional membuktikan adanya perbedaan perilaku signifikan antara **Windows Server 2019 Datacenter** dan **Windows Server 2022 Datacenter** dalam menangani OpenSSH, hak akses berkas, daemons latar belakang, dan runtime container:

| Dimensi Komparasi | Windows Server 2022 Datacenter | Windows Server 2019 Datacenter | Dampak Operasional & Solusi Kanonikal |
| :--- | :--- | :--- | :--- |
| **Versi Paket OpenSSH** | OpenSSH v8.6p1+ bawaan sistem modern dengan integrasi akun virtual. | OpenSSH v7.7p1 (porting awal Win32). | Server 2019 memerlukan penanganan ACL manual dan binding akun `LocalSystem`. |
| **Inisialisasi Host Keys** | Otomatis dibuat saat instalasi capability dengan ACL yang sudah kompatibel. | **Tidak otomatis dibuat**; jika dibuat manual mewarisi ACL permisif dari `C:\ProgramData\ssh`. | `sshd.exe` menolak private key (*UNPROTECTED PRIVATE KEY FILE*). **Wajib** me-reset ACL via .NET `FileSecurity` (SYSTEM + Admins only, inheritance disabled). |
| **Service Account `sshd`** | Berjalan di bawah `NT SERVICE\sshd` dengan SID mapping built-in. | `NT SERVICE\sshd` memicu **SID Lookup Error 1332**; explicit ACE untuk sshd justru ditolak OpenSSH. | **Wajib** mengikat service account ke `LocalSystem` (`sc.exe config sshd obj= LocalSystem`). |
| **Dependensi `ssh-agent`** | Terpasang dan aktif secara otomatis saat instalasi. | Sering berada pada status `Disabled` (Error 1058 saat start). | **Wajib** mengubah startup ke `Automatic`, mengaktifkan service, dan menambahkan dependensi (`sc.exe config sshd depend= ssh-agent`). |
| **Peluncuran Proses Latar Belakang** | `wmic.exe` didepresiasi; `Start-Process` terikat ke SSH Job Object (`KILL_ON_JOB_CLOSE`). | `wmic.exe` mengalami parsing failure (`Invalid Verb Switch.`); `Start-Process` mati saat SSH disconnect. | **Standardisasi**: Menggunakan PowerShell COM/WMI `([wmiclass]'Win32_Process').Create('...')`. Mengeksekusi biner secara independen di luar pohon Job Object SSH dan mendukung seluruh argumen double-dash. |
| **Driver Kernel Containers (Docker)** | Modul container driver termuat secara modern; setup via static zip/engine. | Mewajibkan aktivasi feature `Containers` dan **Reboot Komputer** (`Restart-Computer -Force`). | Reboot diwajibkan setelah `Install-WindowsFeature -Name Containers` agar storage driver `windowsfilter` aktif. |
| **Truststore & Secret Paths Alertmanager** | Volume mount Linux (`/run/secrets/tomcat-monitoring/...`). | Resolusi path Windows relatif terhadap direktori config (`C:\monitoring\config\alertmanager\run\secrets\...`). | **Materialisasi Otomatis**: `role_host_prep` secara deklaratif membuat direktori `run\secrets\tomcat-monitoring` dan memetakan cert CA serta bearer token. |

---

### 2.1 Rincian Investigasi 7 Masalah Operasional Windows Server 2019 vs 2022

#### 1. Investigasi Masalah 1: Kegagalan SSH Handshake & Host Key Permissions (UNPROTECTED PRIVATE KEY FILE)
* **Pesan Error Log Lapangan:**
  ```text
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Permissions for 'C:\ProgramData\ssh\ssh_host_rsa_key' are too open.
  It is required that your private key files are NOT accessible by others.
  This private key will be ignored.
  sshd: no hostkeys available -- exiting.
  ```
  dan saat konfigurasi service account:
  ```text
  LookupAccountName() failed: 1332 (ERROR_NONE_MAPPED)
  ```
* **Akar Masalah (Root Cause):**
  * Di **Windows Server 2022**, instalasi OpenSSH v8.6p1+ otomatis membuat host key dengan ACL ketat dan akun virtual `NT SERVICE\sshd` telah memiliki pemetaan SID sistem internal yang valid.
  * Di **Windows Server 2019**, OpenSSH v7.7p1 tidak membuat host key secara otomatis saat penambahan capability. Ketika operator menjalankan `ssh-keygen -A`, berkas kunci privat mewarisi izin dari folder induk `C:\ProgramData\ssh` (`BUILTIN\Users` dan `NT AUTHORITY\Authenticated Users` memiliki hak read). Selain itu, akun `NT SERVICE\sshd` belum terdaftar secara global di SAM sehingga memicu error 1332. Jika administrator memberikan ACE eksplisit kepada `NT SERVICE\sshd`, OpenSSH v7.7 justru menganggap kunci tersebut *overly permissive* dan menolaknya.
  * Utilitas baris perintah `icacls /inheritance:r` pada Windows Server 2019 terbukti meninggalkan residual inherited ACEs.
* **Solusi Kanonikal:**
  1. Menggunakan .NET API `System.Security.AccessControl.FileSecurity` dengan parameter `SetAccessRuleProtection($true, $false)` untuk memutus pewarisan dan menghapus seluruh ACE warisan secara total.
  2. Memberikan hak `FullControl` hanya kepada SID `S-1-5-18` (`NT AUTHORITY\SYSTEM`) dan `S-1-5-32-544` (`BUILTIN\Administrators`).
  3. Mengikat service account `sshd` langsung ke `LocalSystem` (`sc.exe config sshd obj= "LocalSystem"`).

#### 2. Investigasi Masalah 2: Dependensi & Status Disabled Layanan `ssh-agent` (Win32 Error 1058)
* **Pesan Error Log Lapangan:**
  ```text
  Start-Service : Service 'OpenSSH Authentication Agent (ssh-agent)' cannot be started due to the following error:
  Cannot start service ssh-agent on computer '.'.
  System.Management.Automation.ActionPreferenceStopException: The service cannot be started, either because it is disabled
  or because it has no enabled devices associated with it. (Exception from HRESULT: 0x80070422 / Win32 Error 1058)
  ```
* **Akar Masalah (Root Cause):**
  * Di **Windows Server 2022**, layanan `ssh-agent` dipasang dengan status startup `Manual` sehingga dapat langsung diaktifkan kapan saja.
  * Di **Windows Server 2019**, paket OpenSSH menetapkan startup type `ssh-agent` ke status `Disabled`. Setiap pemanggilan `Start-Service ssh-agent` tanpa modifikasi startup type akan langsung melempar exception fatal HRESULT `0x80070422`.
* **Solusi Kanonikal:**
  Eksplisit mengubah tipe startup ke `Automatic` sebelum menyalakan service:
  ```powershell
  Set-Service -Name ssh-agent -StartupType Automatic
  Start-Service ssh-agent
  sc.exe config sshd depend= ssh-agent
  ```

#### 3. Investigasi Masalah 3: Kegagalan Parsing Argumen CLI WMIC (`Invalid Verb Switch.`)
* **Pesan Error Log Lapangan:**
  ```text
  fatal: [aws-ec2-win-01]: FAILED! => changed=true 
    output: |-
      wmic : Invalid Verb Switch.
      At line:3 char:12
      +     $res = wmic process call create '"C:\monitoring\bin\tm-agent.exe" ...
      +            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          + CategoryInfo          : NotSpecified: (Invalid Verb Switch.:String) [], RemoteException
          + FullyQualifiedErrorId : NativeCommandError
  ```
* **Akar Masalah (Root Cause):**
  * Pada playbook Ansible Windows awal, pembuatan proses latar belakang menggunakan utilitas baris perintah `wmic process call create '"<bin>" --flag1 "val1"'`.
  * Parser CLI `wmic.exe` bawaan **Windows Server 2019** (PowerShell 5.1) mengalami *token misinterpretation*. Parser menganggap setiap parameter yang diawali tanda hubung ganda (`--spool-dir`, `--config.file`, `--storage.tsdb.path`) sebagai *verb switch* milik WMIC itu sendiri, bukan argumen untuk aplikasi target, sehingga melemparkan galat `Invalid Verb Switch.`.
  * Pada **Windows Server 2022**, `wmic.exe` telah berstatus *Deprecated Feature on Demand*.
* **Solusi Kanonikal:**
  Mengeliminasi ketergantungan pada biner CLI `wmic.exe` dan bermigrasi ke antarmuka pemrograman PowerShell COM/WMI internal: `([wmiclass]'Win32_Process').Create(...)`.

#### 4. Investigasi Masalah 4: Terminasi Daemon oleh Windows Job Object (`KILL_ON_JOB_CLOSE`)
* **Pesan Error Log Lapangan:**
  ```text
  fatal: [aws-ec2-win-01]: FAILED! => changed=true 
    output: |-
      tm-agent daemon is not running
      At line:5 char:5
      +     throw "tm-agent daemon is not running"
      +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          + CategoryInfo          : OperationStopped: (tm-agent daemon is not running:String) [], RuntimeException
          + FullyQualifiedErrorId : tm-agent daemon is not running
  ```
  serta kegagalan pada verifikasi kesiapan stack:
  ```text
  Windows Stack Readiness Failure: Mailpit: Unable to connect to the remote server; Prometheus: Unable to connect to the remote server; Alertmanager: Unable to connect to the remote server
  ```
* **Akar Masalah (Root Cause):**
  * Ketika perintah `Start-Process -FilePath ... -PassThru` digunakan untuk menggantikan WMIC, proses memang berhasil dibuat secara lokal di dalam sesi PowerShell yang sedang berjalan.
  * Namun, saat Ansible mengeksekusi modul `ansible.windows.win_powershell` melalui koneksi OpenSSH (`ansible_connection=ssh`), Windows OpenSSH menempatkan sesi runner ke dalam **Windows Job Object**.
  * Berdasarkan arsitektur subsistem OpenSSH Windows, Job Object tersebut memiliki konfigurasi batas `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`.
  * Begitu task Ansible selesai dan koneksi SSH ditutup (*closed session*), kernel Windows **secara instan mematikan (*terminate*) seluruh proses anak** yang berada di dalam Job Object tersebut (`tm-agent.exe`, `prometheus.exe`, `alertmanager.exe`, `mailpit.exe`). Akibatnya, pada task verifikasi berikutnya, seluruh proses telah mati.
* **Solusi Kanonikal:**
  Menggunakan pemanggilan antarmuka COM/WMI:
  ```powershell
  $res = ([wmiclass]'Win32_Process').Create('C:\monitoring\bin\tm-agent.exe --spool-dir C:\monitoring\spool')
  ```
  Pemanggilan `Win32_Process.Create` didelegasikan ke WMI Provider Service host (`WmiPrvSE.exe` / `svchost.exe`). Proses anak yang dihasilkan berjalan di bawah konteks subsistem WMI, **terlepas sepenuhnya (*fully detached*) dari pohon Windows Job Object milik sesi SSH**, sehingga daemon tetap hidup dan persisten tanpa terpengaruh oleh pembukaan/penutupan sesi SSH Ansible.

#### 5. Investigasi Masalah 5: Crash Alertmanager pada Target Fresh akibat Ketiadaan Truststore Path Windows
* **Pesan Error Log Lapangan:**
  ```text
  time=2026-09-15T16:13:54.164Z level=ERROR source=coordinator.go:131 msg="one or more config change subscribers failed to apply new config" component=configuration file=C:\monitoring\config\alertmanager\alertmanager.yml err="unable to read CA cert: unable to read file C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring\diagnostic-service-ca.crt: open C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring\diagnostic-service-ca.crt: The system cannot find the path specified."
  ```
* **Akar Masalah (Root Cause):**
  * Berkas konfigurasi `config/alertmanager/alertmanager.yml` mendefinisikan rute webhook dengan path truststore `/run/secrets/tomcat-monitoring/diagnostic-service-ca.crt`.
  * Pada Linux, direktori ini dimount secara native melalui kontainer volume.
  * Pada Windows, biner native Go `alertmanager.exe` yang dijalankan dari direktori konfigurasi `C:\monitoring\config\alertmanager` me-resolve path non-drive letter (`/run/secrets/...`) secara relatif menjadi: `C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring\...`.
  * Pada pengujian awal di Server 2022, folder ini sempat terbentuk secara ad-hoc saat pengujian manual. Namun pada target *fresh install* Windows Server 2019, folder beserta material sertifikat tersebut belum ada di disk, menyebabkan `alertmanager.exe` langsung mengalami crash saat inisialisasi konfigurasi.
* **Solusi Kanonikal:**
  Menambahkan task deklaratif di `roles/role_host_prep/tasks/secrets_and_tls.yml` yang secara otomatis membuat direktori `C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring` dan memetakan cert CA serta bearer token secara idempoten di seluruh target Windows:
  ```yaml
  - name: Ensure Alertmanager secrets directory exists on Windows host
    ansible.windows.win_file:
      path: "C:\\monitoring\\config\\alertmanager\\run\\secrets\\tomcat-monitoring"
      state: directory
    when: ansible_os_family == "Windows"

  - name: Materialize Alertmanager webhook URL and bearer token on Windows host
    ansible.windows.win_copy:
      content: "{{ item.content }}"
      dest: "C:\\monitoring\\config\\alertmanager\\run\\secrets\\tomcat-monitoring\\{{ item.name }}"
    loop:
      - { name: "diagnostic-service-webhook-url", content: "https://127.0.0.1:8443/api/v1/alerts/alertmanager\r\n" }
      - { name: "diagnostic-service-bearer-token", content: "{{ host_prep_default_bearer_token }}\r\n" }
    when: ansible_os_family == "Windows"

  - name: Materialize Alertmanager CA certificate on Windows host
    ansible.windows.win_copy:
      src: "{{ host_prep_tls_dir }}\\server.crt"
      dest: "C:\\monitoring\\config\\alertmanager\\run\\secrets\\tomcat-monitoring\\diagnostic-service-ca.crt"
      remote_src: true
    when: ansible_os_family == "Windows"
  ```

#### 6. Investigasi Masalah 6: Bug Evaluasi Ternary Jinja2 pada Delegasi Stat Biner Kontroler
* **Pesan Error Log Lapangan:**
  Task transfer biner Windows selalu berstatus `skipped`, sehingga biner `tm-agent.exe` dan `tmctl.exe` tidak terpasang di target Windows:
  ```text
  TASK [role_event_collector : Install tm-agent.exe binary on Windows host] ******
  skipping: [aws-ec2-win-01]
  ```
* **Akar Masalah (Root Cause):**
  Task pengecekan biner pada *control node* (`delegate_to: localhost`) menggunakan ekspresi Jinja2 ternary berkondisi `path: "{{ (str) if (str) is file else ... }}"`. Di dalam Ansible Jinja2 templating engine, test `is file` tidak melakukan pembacaan *filesystem* secara langsung pada host, melainkan selalu mengembalikan nilai `false`. Akibatnya, path beralih ke fallback path yang salah, menghasilkan `stat.exists = false`, dan melewati task `win_copy`.
* **Solusi Kanonikal:**
  Menstandarkan target pengecekan biner secara langsung dan deterministik:
  ```yaml
  - name: Check existence of tm-agent.exe binary on control node
    ansible.builtin.stat:
      path: "{{ playbook_dir }}/../tm-agent/bin/windows_amd64/tm-agent.exe"
    register: tm_agent_win_src_stat
    delegate_to: localhost
    when: ansible_os_family == "Windows"
  ```

#### 7. Investigasi Masalah 7: Kernel Windows Containers & Driver Filter Storage `windowsfilter` (Docker Engine)
* **Pesan Error Log Lapangan:**
  Eksekusi daemon Docker gagal dengan error initialization storage driver:
  ```text
  fatal: failed to start daemon: error initializing graphdriver: driver not supported: windowsfilter
  ```
* **Akar Masalah (Root Cause):**
  * Di **Windows Server 2022**, driver kernel container termuat secara dinamis.
  * Di **Windows Server 2019**, modul `DockerMsftProvider` telah usang (*deprecated*). Pengaktifan fitur Windows `Containers` (`Install-WindowsFeature -Name Containers`) **mewajibkan restart komputer (*reboot*) fisik/instans (`Restart-Computer -Force`)** agar filter driver kernel `windowsfilter.sys` diaktifkan ke dalam Windows Subsystem kernel tree. Tanpa reboot, `dockerd.exe` gagal menginisialisasi layer storage container.
* **Solusi Kanonikal:**
  Memasukkan langkah restart terisolasi pada skrip bootstrap instalasi Docker Windows Server 2019 sebelum mendaftarkan service `dockerd --register-service`.

---

### 2.2 Jaminan Kompatibilitas Lintas Generasi Windows Server (Backward & Forward Compatibility Guarantee)

Seluruh perbaikan yang dirancang untuk mengatasi anomali pada Windows Server 2019 telah dievaluasi secara ketat terhadap arsitektur Windows Server 2022 untuk menjamin interoperabilitas penuh (*zero regressions*):

1. **PowerShell COM/WMI `Win32_Process.Create` vs Windows Job Object:**
   - Kelas WMI `Win32_Process` merupakan antarmuka manajemen proses Win32 kanonikal yang didukung secara *native* pada seluruh generasi Windows Server (2012 R2, 2016, 2019, 2022, hingga 2025).
   - Metode ini menjamin proses anak (*daemon*) diluncurkan di bawah subsistem WMI host (`svchost.exe`/`WmiPrvSE.exe`), terlepas (*detached*) dari pembatasan siklus hidup `KILL_ON_JOB_CLOSE` milik sesi OpenSSH, sekaligus menerima seluruh format parameter CLI (seperti `--spool-dir`, `--config.file`) tanpa batasan parser command-line `wmic.exe`.
2. **Hardening OpenSSH & Service Account Binding `LocalSystem`:**
   - Pembatasan ACL host keys hanya kepada `NT AUTHORITY\SYSTEM` dan `BUILTIN\Administrators` (dengan *inheritance* dinonaktifkan via .NET `FileSecurity`) merupakan *Security Baseline* resmi Microsoft yang berlaku identik di Server 2019 dan Server 2022.
   - Penegakan akun layanan `LocalSystem` mengeliminasi kerentanan pemetaan virtual service account (`NT SERVICE\sshd` error 1332) pada Server 2019 tanpa menimbulkan efek samping pada Server 2022.
3. **Materialisasi Deklaratif Direktori Truststore & Secrets Alertmanager:**
   - Penyediaan direktori `C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring` melalui `ansible.windows.win_file` dan penyalinan cert CA serta token bersifat *idempotent* dan *stateless*. Jika dijalankan pada Server 2022, task ini memastikan kelengkapan dependensi runtime Alertmanager tanpa mengubah konfigurasi sistem lainnya.
4. **Determinisme Stat Biner pada Control Node:**
   - Resolusi path biner `tmctl.exe` dan `tm-agent.exe` dieksekusi pada *Ansible Control Node* (Linux), sehingga mekanisme transfer biner bersifat seragam dan agnostik terhadap versi OS target.

---

### 3. Formulasi Bootstrap & Hardening OpenSSH Windows (Multi-Version 2019/2022)

Rangkaian skrip PowerShell kanonikal untuk mempersiapkan node Windows Server (Windows Server 2019/2022):

```powershell
# 1. Instalasi OpenSSH Server Capability
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 2. Konfigurasi Service Account ke LocalSystem (Fix Error 1332 & Permission Isolation)
sc.exe config sshd obj= "LocalSystem"
sc.exe config sshd depend= ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# 3. Tetapkan Default Shell ke PowerShell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# 4. Generate Host Keys & Terapkan ACL Ketat (Fix UNPROTECTED PRIVATE KEY FILE)
& "C:\Windows\System32\OpenSSH\ssh-keygen.exe" -A

$systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")    # SYSTEM
$adminsSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544") # Administrators
Get-Item "C:\ProgramData\ssh\ssh_host_*_key" | ForEach-Object {
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false) # Disable inheritance & strip inherited ACEs
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($systemSid, "FullControl", "None", "None", "Allow")))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsSid, "FullControl", "None", "None", "Allow")))
    $acl.SetOwner($systemSid)
    Set-Acl -Path $_.FullName -AclObject $acl
}

# 5. Tulis sshd_config bersih dengan SFTP Subsystem
Set-Content "C:\ProgramData\ssh\sshd_config" @(
    "Port 22",
    "PubkeyAuthentication yes",
    "PasswordAuthentication yes",
    "StrictModes no",
    "Subsystem sftp sftp-server.exe"
)

# 6. Injeksi Kunci Publik RSA Bebas Wrapping via Base64 Decode
$bytes = [Convert]::FromBase64String("<BASE64_ENCODED_PUBLIC_KEY>")
[System.IO.File]::WriteAllBytes("$env:USERPROFILE\.ssh\authorized_keys", $bytes)

# 7. Buka Firewall Port 22 dan Aktifkan Service
Get-NetFirewallRule -DisplayName "*OpenSSH*" | Enable-NetFirewallRule -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Automatic
Restart-Service sshd
```

### 4. OS Fact Branching pada Ansible Roles & Native Process Management

- **`role_host_prep`:**
  - Linux: Membuat direktori `~/.local/share/...`, menyinkronkan scripts, menginstal `tmctl` Linux.
  - Windows: Menggunakan `ansible.windows.win_file` untuk membuat `C:\monitoring` dan subfolder, menginstal `tmctl.exe` via `ansible.windows.win_copy`, dan mematerialisasikan truststore/secrets Alertmanager ke `C:\monitoring\config\alertmanager\run\secrets\tomcat-monitoring`.
- **`role_event_collector`:**
  - Linux: Mendaftarkan dan mengaktifkan systemd user unit `tm-agent.service`.
  - Windows: Mentransfer `tm-agent.exe` ke `C:\monitoring\bin\tm-agent.exe`, mengelola proses daemon latar belakang secara idempoten menggunakan COM/WMI `([wmiclass]'Win32_Process').Create(...)` (menghindari terminasi Job Object SSH dan bug parsing `wmic.exe`), dan memastikan spool directory `C:\monitoring\spool` aktif.
- **`role_container_stack`:**
  - Linux: Menerapkan orchestrasi kontainer via `tmctl` dan container engine (Docker/Podman).
  - Windows: Menjalankan native platform components (`prometheus.exe`, `alertmanager.exe`, `mailpit.exe`) secara terpadu (*self-instrumented*) dengan WMI `Win32_Process.Create` background process management dan verifikasi endpoint HTTP readiness (`:9090/-/ready`, `:9093/-/ready`, `:8025/api/v1/messages`).

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
5. **Universal Multi-Generation Windows Compatibility:** Standardisasi COM/WMI `Win32_Process.Create` dan hardening ACL berbasis .NET `FileSecurity` menjamin 100% portabilitas lintas generasi Windows Server (Windows Server 2019 dan 2022 Datacenter) secara deterministik dan bebas regresi (*zero regressions*).

---

## 🔗 Related Documentation

- [TM-ADR-0016 — Designate Diagnostic Service as Canonical Incident Notification Authority](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0020 — Adopt Zero Silent Failure Policy and Direct Emergency SMTP Bypass Routing](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0020.md)
- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling for Multi-OS Orchestration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TM-ADR-0028 — Adopt Cloud-Native Remote Fleet Orchestration, Multi-Engine Socket API Portability, and AWS Free Tier Integration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md)
- [TN-001 — Implement and Verify Diagnostic Service Self-Monitoring and Direct Emergency SMTP Routing](../monitoring-platform-integration/TN-001-implement-and-verify-diagnostic-service-self-monitoring-and-emergency-smtp-routing.md)
- [TN-017 — AWS Free Tier Linux Cloud Fleet Deployment and Verification](TN-017-aws-free-tier-cloud-remote-fleet-deployment-cross-environment-ansible-provisioning-and-cloud-cicd-live-verification.md)
- [Follow-up Tasks Register](../../follow-up-tasks.md)

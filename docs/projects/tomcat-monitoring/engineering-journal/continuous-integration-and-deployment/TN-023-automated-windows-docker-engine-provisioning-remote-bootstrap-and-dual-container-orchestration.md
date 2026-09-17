# TN-023 — Automated Windows Docker Engine Provisioning, Remote SSH Bootstrap, and Dual-Container Mode Orchestration

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Automated Windows Docker Provisioning, Remote SSH Bootstrap & Dual-Container Mode |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Continuous Integration and Deployment |
| Activity Date | 2026-09-17 |
| Recorded Date | 2026-09-17 |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-17 |

---

## 🎯 Objective

Membangun dan membakukan otomatisasi menyeluruh untuk **provisi Docker Engine (Windows Containers) secara zero-touch pada node Windows Server (2019/2022/2025)** dari jarak jauh (*remote via SSH*), mengatasi tantangan inisialisasi driver kernel storage `windowsfilter` dan *reboot loop*, mengeliminasi kegagalan eksekusi biner non-interaktif SSH melalui *System32 placement*, serta mengintegrasikan **Dual-Container Mode (`WINDOWS_CONTAINER_MODE`: `auto`, `windows`, `linux`)** pada Ansible playbooks dan Jenkins CD Pipeline untuk fleksibilitas arsitektur kontainer multi-OS.

Aktivitas ini menuntaskan **TASK-TM-036** dan memperluas implementasi arsitektur [TM-ADR-0026](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md), [TM-ADR-0027](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), dan [TM-ADR-0028](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md).

---

## 🌍 Background & Problem Statement

Pada arsitektur Tomcat Monitoring multi-OS (TN-018 dan TN-019), target node Windows Server diwajibkan untuk menjalankan tumpukan pemantauan (*monitoring stack*) berbasis kontainer. Namun, proses provisi Docker Engine pada Windows Server menghadirkan serangkaian tantangan teknis operasional:

1. **Deprekasi Provider Tradisional (`DockerMsftProvider`):**
   Metode instalasi lama menggunakan modul PowerShell `DockerMsftProvider` telah usang (*deprecated*) dan tidak lagi dapat diandalkan pada Windows Server modern. Instalasi harus menggunakan biner statis resmi Docker CE (v26.1.4+).
2. **Inisialisasi Filter Driver Kernel `windowsfilter` & Exit Code 3010:**
   Pada instalasi baru (*fresh instance*), aktivasi Windows Feature `Containers` mewajibkan satu kali *reboot* sistem (`Restart-Computer -Force`) agar kernel driver `windowsfilter.sys` dimuat ke dalam Windows kernel tree. Jika Docker daemon dijalankan sebelum reboot, `dockerd.exe` gagal dengan error `fatal: failed to start daemon: error initializing graphdriver: driver not supported: windowsfilter`.
3. **Keterbatasan Environment PATH pada Sesi Non-Interaktif OpenSSH Windows:**
   Layanan OpenSSH Server (`sshd`) membaca variabel lingkungan sistem saat servis pertama kali dinyalakan. Penambahan `C:\Program Files\docker` ke *Machine PATH* tidak secara otomatis terbaca pada sesi SSH non-interaktif yang sedang berjalan atau sesi baru sebelum servis `sshd` di-restart. Pemanggilan `docker version` via SSH menghasilkan `CommandNotFoundException`.
4. **Sensitivitas Line-Wrapping & Quote Escaping pada Terminal SSH:**
   Eksekusi perintah PowerShell yang panjang dan memuat argumen ber-quote (misal `Copy-Item 'C:\Program Files\docker\*.exe' ...`) secara langsung di terminal SSH rentan mengalami pemotongan baris (*line wrap*) dan *parsing error* (`Unexpected token in expression or statement`).
5. **Kebutuhan Fleksibilitas Arsitektur Dual-Container (Windows Native vs Linux on Windows):**
   Operator membutuhkan fleksibilitas untuk memilih apakah node Windows menjalankan kontainer native Windows (NanoServer via Process Isolation) atau kontainer Linux (WSL2/LCOW) tanpa merombak logika deployment.

---

## 🏗️ Architecture & Implementation Strategy

### 1. Skrip Installer Docker Windows Idempoten (`scripts/install-docker-windows.ps1`)

Skrip PowerShell kanonikal untuk memasang, mengonfigurasi, dan memvalidasi Docker Engine pada Windows Server:

```powershell
param (
    [string]$DockerVersion = "26.1.4"
)

Write-Host "=== Starting Docker Engine Installation for Windows Containers ===" -ForegroundColor Cyan

# 1. Check and Install Windows Feature 'Containers'
Write-Host "[1/5] Checking Windows Feature: Containers..."
$feature = Get-WindowsFeature -Name Containers
if (-not $feature.Installed) {
    Write-Host "      Installing Windows Feature: Containers..." -ForegroundColor Yellow
    $res = Install-WindowsFeature -Name Containers
    if ($res.RestartNeeded -eq "Yes") {
        Write-Warning "System requires a reboot to initialize the 'windowsfilter' container storage driver."
        Write-Warning "Please reboot the server (Restart-Computer -Force) and re-run this script after reboot."
        exit 3010
    }
} else {
    Write-Host "      Windows Feature: Containers is already installed." -ForegroundColor Green
}

# 2. Download Official Docker Static Binaries (Windows x86_64)
$downloadUrl = "https://download.docker.com/win/static/stable/x86_64/docker-$DockerVersion.zip"
$zipPath = "$env:TEMP\docker-$DockerVersion.zip"
$targetDir = "C:\Program Files\docker"

# Stop docker service if running to avoid file lock during copy/update
if (Get-Service -Name docker -ErrorAction SilentlyContinue) {
    Write-Host "      Stopping existing Docker service for update..."
    Stop-Service docker -Force -ErrorAction SilentlyContinue
}

Write-Host "[2/5] Downloading Docker Engine v$DockerVersion static binaries..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $zipPath

Write-Host "[3/5] Extracting Docker binaries to $targetDir..."
if (-not (Test-Path "C:\Program Files")) { New-Item -Path "C:\Program Files" -ItemType Directory | Out-Null }
Expand-Archive -Path $zipPath -DestinationPath "C:\Program Files" -Force
Remove-Item -Path $zipPath -Force

# Copy docker binaries directly to System32 for guaranteed global availability in all SSH/WinRM sessions
Copy-Item "$targetDir\*.exe" "C:\Windows\System32\" -Force -ErrorAction SilentlyContinue

# 3. Add Docker to Machine PATH if not present
Write-Host "[4/5] Configuring System PATH..."
$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($machinePath -notlike "*$targetDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$targetDir", [EnvironmentVariableTarget]::Machine)
    $env:Path += ";$targetDir"
}

# 4. Register Docker Daemon Service & Start
Write-Host "[5/5] Registering and starting Docker daemon service..."
if (-not (Get-Service -Name docker -ErrorAction SilentlyContinue)) {
    & "$targetDir\dockerd.exe" --register-service
}

Set-Service -Name docker -StartupType Automatic
Start-Service docker -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 5. Verify Installation and Refresh OpenSSH Daemon Environment
$dockerService = Get-Service -Name docker -ErrorAction SilentlyContinue
if ($dockerService -and $dockerService.Status -eq "Running") {
    Write-Host "=== Docker Windows Engine Installed Successfully! ===" -ForegroundColor Green
    & "$targetDir\docker.exe" version
    Restart-Service sshd -ErrorAction SilentlyContinue
} else {
    Write-Error "Docker service failed to start. Check Windows Event Viewer or run dockerd manually."
}
```

### 2. Remote SSH Provisioner Otomatis (`scripts/install-docker-windows-remote.sh`)

Skrip wrapper Bash yang mengeksekusi installer via SSH/SCP dari mesin Linux kontroler, menangani deteksi reboot otomatis (Exit Code 3010), melakukan polling pemulihan SSH, dan melanjutkan eksekusi post-reboot:

```bash
# Ringkasan Alur Eksekusi:
# 1. SCP installer ke target: C:\Windows\Temp\install-docker-windows.ps1
# 2. Eksekusi via powershell.exe -ExecutionPolicy Bypass -NoProfile -File C:\Windows\Temp\...
# 3. Jika Exit Code == 3010 (Reboot Required):
#    - Kirim 'Restart-Computer -Force'
#    - Tunggu host shutdown (20s)
#    - Polling SSH connectivity hingga node online kembali (maks 180s)
#    - Re-run installer secara otomatis pasca-reboot
# 4. Verifikasi final: 'docker version'
```

### 3. Integrasi Dual-Container Mode pada Ansible & Jenkins

1. **Parameter Jenkinsfile:**
   Menambahkan pilihan `WINDOWS_CONTAINER_MODE` (`auto`, `windows`, `linux`).
2. **Auto-Detection pada `role_host_prep`:**
   Mengeksekusi `docker info --format '{{.OSType}}'` pada host Windows.
   - Jika `windows`: membuat network driver `nat`.
   - Jika `linux`: membuat network driver `bridge`.
3. **Modular Task Runners:**
   Menyediakan runner kontainer `linux_*.yml` di samping `nanoserver_*.yml` pada `roles/role_container_stack/tasks/windows/`.
4. **Dual-IP Probing pada `verify_readiness.yml`:**
   Secara cerdas mem-probe IP internal kontainer (melewati limitasi WinNAT) pada mode Windows Containers, atau `127.0.0.1` pada mode Linux Containers on Windows.

---

## 🧪 Verification & Evidence

### 1. Eksekusi Provisi Remote Docker via SSH (`184.194.25.77`)

Eksekusi nyata pada instans target AWS EC2 Windows Server:

```text
eddywiyatno@edkas-pc1:~/git/tomcat-monitoring$ ./scripts/install-docker-windows-remote.sh 184.194.25.77 -i ~/Downloads/tomcat-monitoring-aws-key.pem
==================================================================
🚀 Remote Docker Windows Container Provisioner via SSH
==================================================================
Target Host : 184.194.25.77
SSH User    : Administrator
SSH Key     : /home/eddywiyatno/Downloads/tomcat-monitoring-aws-key.pem
Installer   : install-docker-windows.ps1
==================================================================
[1/4] Testing SSH connectivity to Administrator@184.194.25.77...
      SSH Authentication OK.
[2/4] Uploading installer script to remote host (C:\Windows\Temp\install-docker-windows.ps1)...
install-docker-windows.ps1                                                         100% 3860    13.9KB/s   00:00    
      Upload completed.
[3/4] Executing Docker installation script on Windows target...
=== Starting Docker Engine Installation for Windows Containers ===
[1/5] Checking Windows Feature: Containers...
      Windows Feature: Containers is already installed.
      Stopping existing Docker service for update...
[2/5] Downloading Docker Engine v26.1.4 static binaries...
[3/5] Extracting Docker binaries to C:\Program Files\docker...
[4/5] Configuring System PATH...
[5/5] Registering and starting Docker daemon service...
=== Docker Windows Engine Installed Successfully! ===
Client:
 Version:           26.1.4
 API version:       1.45
 Go version:        go1.21.11
 Git commit:        5650f9b
 Built:             Wed Jun  5 11:29:54 2024
 OS/Arch:           windows/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          26.1.4
  API version:      1.45 (minimum version 1.24)
  Go version:       go1.21.11
  Git commit:       de5c9cf
  Built:            Wed Jun  5 11:28:43 2024
  OS/Arch:          windows/amd64
  Experimental:     false
[4/4] Verifying Docker Engine on remote Windows host...
Client:
 Version:           26.1.4
 API version:       1.45
 Go version:        go1.21.11
 Git commit:        5650f9b
 Built:             Wed Jun  5 11:29:54 2024
 OS/Arch:           windows/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          26.1.4
  API version:      1.45 (minimum version 1.24)
  Go version:       go1.21.11
  Git commit:       de5c9cf
  Built:            Wed Jun  5 11:28:43 2024
  OS/Arch:          windows/amd64
  Experimental:     false
==================================================================
✔ Docker Windows Containers successfully installed and active on 184.194.25.77!
==================================================================
```

---

## 📈 Impact & Architectural Benefits

1. **Zero-Touch Remote Fleet Provisioning:** Operator dapat memprovisi engine Docker Windows dari terminal Linux/CI/CD secara penuh tanpa perlu login RDP manual.
2. **Resilient Reboot Management:** Alur deteksi `exit 3010` dan auto-resume post-reboot mengotomasi fase krusial inisialisasi kernel `windowsfilter`.
3. **Guaranteed Global Binary Execution:** Penempatan biner di `C:\Windows\System32\` dan restart otomatis OpenSSH memastikan seluruh session SSH non-interaktif dan runner Ansible dapat memanggil `docker` secara langsung tanpa kegagalan PATH.
4. **Dual-Container Mode Flexibility:** Memberikan kebebasan penuh bagi tim operasional untuk menjalankan Windows Containers (NanoServer) maupun Linux Containers pada host Windows secara otomatis dan transparan.

---

## 🔗 Related Documentation

- [TM-ADR-0026 — Adopt Adaptive Multi-Engine Container Runtime Portability](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md)
- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TM-ADR-0028 — Adopt Cloud-Native Remote Fleet Orchestration and AWS Free Tier Integration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md)
- [TN-018 — AWS Windows Fleet Deployment and Cross-Platform Provisioning](TN-018-aws-windows-fleet-deployment-cross-platform-ansible-provisioning-and-live-verification.md)
- [TN-019 — Windows Container Migration (Docker NanoServer) and Multi-OS Modular Refactoring](TN-019-windows-container-migration-nanoserver-packaging-and-multi-os-modular-refactoring.md)
- [TN-020 — Implement Flexible Multi-OS Deployment Topology and TLS Governance](TN-020-implement-flexible-multi-os-deployment-topology-and-ssl-lifecycle-governance.md)
- [TN-022 — Standardize Host Monitoring Directory to TM Data and Pure Container Logging](TN-022-standardize-host-monitoring-directory-to-tm-data-and-pure-container-logging.md)

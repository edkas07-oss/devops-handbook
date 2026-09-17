# TN-024 — Automated Linux Host Bootstrap, Container Runtime Detection, and Multi-Distro Provisioning

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Automated Linux Host Bootstrap, Container Runtime Detection & Multi-Distro Provisioning |
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

Membangun dan membakukan kakas otomasi **Zero-Touch Linux Host Bootstrap & Runtime Provisioner** dari jarak jauh (*remote via SSH*) untuk seluruh armada node Linux (Amazon Linux 2023, Ubuntu, Debian, RHEL, Rocky, AlmaLinux), menerapkan logika **Runtime Inspection & Verification** (memeriksa keberadaan engine yang ada; jika sehat maka *skip installation*; jika kosong maka menginstal **Podman** sebagai runtime default), menangani disparitas paket distribusi (seperti ketiadaan paket Podman di repositori default Amazon Linux 2023 dengan fallback otomatis ke Docker Engine), serta mengotomasi penguatan memori swap 2GB dan *systemd user lingering*.

Aktivitas ini menuntaskan **TASK-TM-037** dan memperluas implementasi arsitektur [TM-ADR-0026](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md), [TM-ADR-0027](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), dan [TM-ADR-0028](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md).

---

## 🌍 Background & Problem Statement

Menyusul standarisasi otomasi provisi Windows Server (TN-023), penyiapan node target Linux untuk platform Tomcat Monitoring menghadapi sejumlah tantangan heterogenitas lingkungan:

1. **Disparitas Repositori Paket Antar Distro Linux:**
   - Pada distro keluarga RHEL, Fedora, Rocky, AlmaLinux, Ubuntu, dan Debian, paket **Podman** tersedia secara native di repositori default.
   - Pada **Amazon Linux 2023 (AL2023)**, AWS menetapkan **Docker Engine** sebagai satu-satunya runtime resmi bawaan repositori `dnf`, dan tidak menyertakan paket `podman`. Upaya eksekusi `dnf install -y podman` menghasilkan `No match for argument: podman`. Skrip harus memiliki mekanisme adaptif fallback ke Docker saat Podman tidak tersedia.
2. **Prinsip Efisiensi: *Inspect -> Verify -> Skip Install*:**
   Jika sebuah server Linux sudah memiliki runtime kontainer aktif (misalnya Docker yang sudah dikonfigurasi atau Podman), skrip tidak boleh menimpa atau menginstal ulang runtime lain secara redundan. Skrip cukup memvalidasi kesiapan socket/daemon, memastikan izin user, dan menyelesaikan proses (*done*).
3. **Kerentanan Kernel OOM Killer pada Node Cloud Murah (1GB RAM):**
   Instans cloud publik seperti AWS Free Tier `t2.micro` (1GB RAM) rentan mengalami *Kernel Out-of-Memory (OOM) Killer* ketika 6 kontainer pemantauan (Tomcat JMX, Prometheus, Alertmanager, Diagnostic Service, Postfix, Mailpit) dijalankan bersamaan jika partisi Swap tidak dikonfigurasi.
4. **Ketergantungan Prasyarat Ansible & Daemon Background:**
   Ansible membutuhkan runtime `python3` pada target host, sementara daemon `tm-agent` membutuhkan pengaktifan *systemd user session lingering* (`loginctl enable-linger`) agar background process tetap hidup setelah sesi SSH ditutup.

---

## 🏗️ Architecture & Implementation Strategy

### 1. Skrip Host Bootstrap Idempoten (`scripts/bootstrap-linux-host.sh`)

Skrip bash idempoten yang dieksekusi pada target host dengan hak akses sudo:

```bash
# Ringkasan Logika Inti:
# 1. Pastikan Python 3 terpasang (dnf / apt-get / yum / zypper / pacman).
# 2. Periksa RAM: Jika RAM <= 2GB dan Swap < 1GB -> Buat 2GB /swapfile (vm.swappiness=10).
# 3. Aktifkan systemd user lingering: loginctl enable-linger <target_user>.
# 4. Deteksi Runtime Kontainer:
#    a. Cek Docker: Jika ada & aktif -> validasi docker info, tambahkan user ke grup docker -> SELESAI (Skip Install).
#    b. Cek Podman: Jika ada & aktif -> validasi podman info -> SELESAI (Skip Install).
#    c. Jika TIDAK ADA runtime:
#       - Coba instal Podman via package manager.
#       - Jika paket Podman tidak ada (misal AL2023) -> Fallback instal Docker Engine & aktifkan service.
```

### 2. Remote SSH Bootstrap Wrapper (`scripts/bootstrap-linux-host-remote.sh`)

Skrip otomasi remote yang menghubungkan mesin kontroler ke server Linux target via SSH/SCP:

```bash
# Penggunaan:
./scripts/bootstrap-linux-host-remote.sh <TARGET_IP_OR_HOST> [-i /path/to/key.pem] [-u ec2-user/ubuntu]
```

Skrip ini secara otomatis:
1. Melakukan deteksi username SSH (`ec2-user`, `ubuntu`, `rocky`, `almalinux`, `root`).
2. Meng-upload `bootstrap-linux-host.sh` ke `/tmp/bootstrap-linux-host.sh`.
3. Menjalankan skrip dengan `sudo bash`.
4. Menguji eksekusi non-sudo dari sudut pandang user biasa (`docker info` atau `podman info`).

---

## 🧪 Verification & Evidence

### 1. Eksekusi Nyata pada Node AWS EC2 Amazon Linux 2023 (`3.82.132.6`)

```text
eddywiyatno@edkas-pc1:~/git/tomcat-monitoring$ ./scripts/bootstrap-linux-host-remote.sh 3.82.132.6 -i ~/Downloads/tomcat-monitoring-aws-key.pem
🔍 Auto-detecting SSH username for 3.82.132.6...
==================================================================
🚀 Remote Linux Host Bootstrap & Runtime Provisioner via SSH
==================================================================
Target Host : 3.82.132.6
SSH User    : ec2-user
SSH Key     : /home/eddywiyatno/Downloads/tomcat-monitoring-aws-key.pem
==================================================================

[1/4] Testing SSH connectivity to ec2-user@3.82.132.6...
      SSH Authentication OK (ec2-user@3.82.132.6).

[2/4] Uploading bootstrap script to remote host (/tmp/bootstrap-linux-host.sh)...
bootstrap-linux-host.sh                                                            100% 8271    29.9KB/s   00:00    
      Upload completed.

[3/4] Executing bootstrap script with sudo on remote Linux target...
==================================================================
🚀 Tomcat Monitoring — Linux Host Runtime Verifier & Provisioner
==================================================================
Target User     : ec2-user
OS Distribution : Amazon Linux 2023.12.20260914
==================================================================

[1/4] Checking Python 3 Runtime (Ansible Prerequisite)...
      ✔ Python 3 is present: Python 3.9.25

[2/4] Checking Memory & Swap Space Allocation...
      ✔ Memory is healthy: 7779 MB RAM, 0 MB Swap.

[3/4] Checking Systemd User Session Lingering...
      ✔ Systemd user lingering enabled for user 'ec2-user'.

[4/4] Checking Container Runtime Status...
      ⚠️ No operational container runtime found on this server.
      Attempting to install default runtime: Podman...
      Note: Podman package is not available in dnf repos for this OS (e.g. Amazon Linux 2023).
      Installing Docker Engine instead...
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
      Configured user 'ec2-user' into 'docker' group.
      ✔ Docker Engine successfully installed and verified: Docker version 25.0.14, build 0bab007

==================================================================
✔ Linux Target Host verification complete! Ready for Ansible deployment.
  Active Container Runtime : docker
  Python 3 Version         : Python 3.9.25
  Memory & Swap Status     : 7779 MB RAM / 0 MB Swap
==================================================================

[4/4] Verifying Non-Sudo Container & Python Execution for 'ec2-user'...
--- Remote Host Verification ---
Host OS   : Amazon Linux 2023.12.20260914
Python 3  : Python 3.9.25
Container : Docker version 25.0.14, build 0bab007 [OPERATIONAL]
Memory    : RAM 7.6Gi
Swap 0B
--------------------------------

==================================================================
✔ Linux host 3.82.132.6 is fully bootstrapped and ready for Ansible!
==================================================================
```

---

## 📈 Impact & Architectural Benefits

1. **Zero-Touch Multi-Distro Provisioning:** Seluruh armada Linux (Amazon Linux 2023, Ubuntu, RHEL, Rocky, Debian) dapat di-bootstrap secara otomatis via satu perintah remote SSH.
2. **Adaptive Runtime Portability:** Menghormati prioritas runtime operator (Podman first) dengan fallback cerdas ke Docker Engine saat package distro tidak menyediakannya.
3. **Resilient Memory Management:** Perlindungan otomatis OOM melalui provisi 2GB Swap pada node berkapasitas memori terbatas.
4. **Ansible & CI/CD Readiness:** Menjamin ketersediaan Python 3, hak akses grup non-sudo, dan persistensi daemon systemd lingering sebelum eksekusi deployment playbook.

---

## 🔗 Related Documentation

- [TM-ADR-0026 — Adopt Adaptive Multi-Engine Container Runtime Portability](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md)
- [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
- [TM-ADR-0028 — Adopt Cloud-Native Remote Fleet Orchestration and AWS Free Tier Integration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0028.md)
- [TN-008 — Implement and Standardize Multi-Engine Container Runtime Portability](TN-008-implement-and-standardize-multi-engine-container-runtime-portability.md)
- [TN-017 — AWS Free Tier Linux Cloud Fleet Deployment and Verification](TN-017-aws-free-tier-cloud-remote-fleet-deployment-cross-environment-ansible-provisioning-and-cloud-cicd-live-verification.md)
- [TN-023 — Automated Windows Docker Engine Provisioning and Dual-Container Mode](TN-023-automated-windows-docker-engine-provisioning-remote-bootstrap-and-dual-container-orchestration.md)

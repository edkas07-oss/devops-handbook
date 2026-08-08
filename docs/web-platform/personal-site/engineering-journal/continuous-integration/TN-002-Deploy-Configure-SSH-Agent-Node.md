# TN-002 — Deploy & Configure SSH Agent Node

## Objective

Mendefinisikan, mengonfigurasi, dan menghubungkan *dedicated build agent* (`build-agent-01`) ke Jenkins Controller menggunakan koneksi SSH. Tujuannya adalah memindahkan eksekusi pipeline dari Controller ke node agen yang terpisah.

## Background

Agar Jenkins Controller tetap ringan dan lebih aman, eksekusi build dipisahkan ke node agen khusus. Jenkins Controller akan menggunakan **SSH Launcher** untuk menghubungkan dan mengontrol `build-agent-01`.

Agent `build-agent-01` berfungsi sebagai runner untuk stage pipeline, sedangkan Controller hanya bertindak sebagai orkestrator. Koneksi SSH menggunakan autentikasi kunci publik memastikan akses aman tanpa password.

## Prerequisites

- TN-001 telah berhasil diselesaikan.
- Repository Gitea telah tersedia.
- Jenkins dapat diakses menggunakan akun administrator.
- Host `build-agent-01` tersedia dan dapat dijangkau melalui SSH dari Jenkins Controller.
- User target pada agen adalah `<agent-user>`.
- Port SSH (`22`) terbuka dan daemon SSH berjalan di node agen.

## Engineering Decision

Refer to:

- **PS-ADR-0002 — Containerized Ephemeral Build Environment (DooD with Rootless Podman)**

> Architecture Decision Record (ADR) ini menjadi referensi utama (Single Source of Truth) untuk penggunaan Jenkins Agent terpisah yang menjalankan build container ephemeral melalui Rootless Podman pada host agent.

## Implementation

### 1. Siapkan SSH Key Pair pada Jenkins Controller

Buat pasangan kunci SSH di Jenkins Controller atau mesin yang mengelola Jenkins.

```bash
ssh-keygen -t ed25519 -C "jenkins-agent" -f ~/.ssh/id_ed25519_jenkins_agent
```

### 2. Salin public key ke node agen (`build-agent-01`)

Pada `build-agent-01`, pastikan direktori `~/.ssh` ada dan memiliki permission yang benar.

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Tambahkan public key ke `authorized_keys`.

```bash
cat <<'EOF' >> ~/.ssh/authorized_keys
<ISI_PUBLIC_KEY_id_ed25519_jenkins_agent.pub>
EOF
chmod 600 ~/.ssh/authorized_keys
```

> Tips: Jika `ssh-copy-id` tersedia, gunakan `ssh-copy-id -i ~/.ssh/id_ed25519_jenkins_agent.pub <agent-user>@build-agent-01` untuk mempermudah instalasi kunci.

### 3. Verifikasi koneksi SSH dari Controller ke agen

```bash
ssh -i ~/.ssh/id_ed25519_jenkins_agent <agent-user>@build-agent-01 hostname
```

Jika koneksi berhasil, node agen akan merespon tanpa meminta password.

### 4. Tambahkan Credential SSH di Jenkins

1. Login ke Jenkins dengan akun administrator.
2. Buka **Manage Jenkins → Credentials**.
3. Pilih **System → Global credentials (unrestricted)**.
4. Klik **Add Credentials**.
5. Pada **Kind**, pilih **SSH Username with private key**.
6. Isi detail berikut:
    - **Scope**: `Global`
    - **ID**: `builder01-ssh`
    - **Description**: `SSH Private Key for Builder Host`
    - **Username**: `eddywiyatno`
    - **Private Key**: Pilih **Enter directly** dan tempel isi berkas `~/.ssh/id_ed25519_builder01`
    - **Passphrase**: kosongkan
7. Klik **Create**.

### 5. Buat Node Agent `builder-01` di Jenkins

1. Buka **Manage Jenkins → Nodes → New Node**.
2. Beri nama node: `builder-01`.
3. Pilih **Permanent Agent**, lalu klik **Create**.
4. Isi parameter utama:
    - **Number of executors**: `1`
    - **Remote root directory**: `/home/[username]/jenkins-agent`
    - **Labels**: `builder linux podman`
    - **Usage**: `Only build jobs with label expressions matching this node`
5. Pada **Launch method**, pilih **Launch agents via SSH**.
6. Isi detail SSH:
    - **Host**: `host.containers.internal`
    - **Credentials**: pilih `eddywiyatno (SSH Private Key for Builder Host)`
    - **Host Key Verification Strategy**: `Non verifying Verification Strategy`
7. Klik **Save**.

### 6. Uji koneksi agen

Setelah node dibuat, klik **Launch agent** atau **Connect**. Pastikan status berubah menjadi **Online**.

### 7. Verifikasi environment agen

Pastikan agen dapat menjalankan perintah shell sederhana dan memiliki akses ke binary yang dibutuhkan.

Contoh pengujian di Jenkins:

- Buat Jenkins freestyle job atau pipeline
- Jalankan `sh 'whoami && pwd && id && podman version'`

Jika perintah berhasil, agen siap menjalankan pipeline.

## Verification

| Item | Status | Notes |
|------|--------|-------|
| SSH key authentication berhasil | ✅ | Login ke `build-agent-01` tanpa password menggunakan kunci publik. |
| Node `build-agent-01` online di Jenkins | ✅ | Jenkins node status menjadi **Online**. |
| Remote root directory dapat diakses | ✅ | Jenkins dapat membuat workspace di node agen. |
| Agent dapat menjalankan perintah shell | ✅ | `whoami`, `pwd`, dan `podman version` berhasil. |
| Build Pipeline tidak lagi dijalankan di Controller | ✅ | Eksekusi pipeline diarahkan ke `build-agent-01`. |

## Notes

- Pastikan `build-agent-01` memiliki paket SSH server aktif dan user `<agent-user>` memiliki hak akses yang tepat.
- Untuk keamanan produksi, gunakan `Host Key Verification Strategy` yang lebih ketat setelah pengujian awal selesai.
- Jika menggunakan SELinux, pastikan permission volume dan home directory sudah sesuai.

# TN-002 — Deploy & Configure SSH Agent Node

## Objective

Mendefinisikan, mengonfigurasi, dan menghubungkan *dedicated build agent* (`builder-01`) ke Jenkins Controller menggunakan koneksi SSH. Tujuannya adalah memindahkan eksekusi pipeline dari Controller ke node agen yang terpisah.

## Background

Agar Jenkins Controller tetap ringan dan lebih aman, eksekusi build dipisahkan ke node agen khusus. Jenkins Controller akan menggunakan **SSH Launcher** untuk menghubungkan dan mengontrol `builder-01`.

Agent `builder-01` berfungsi sebagai runner untuk stage pipeline, sedangkan Controller hanya bertindak sebagai orkestrator. Koneksi SSH menggunakan autentikasi kunci publik memastikan akses aman tanpa password.

## Scope

Mencakup SSH access, Jenkins credential, dan node `builder-01` sebagai execution
agent. Implementasi Jenkinsfile dan pipeline job berada di luar scope.

## Prerequisites

- TN-001 telah berhasil diselesaikan.
- Repository Gitea telah tersedia.
- Jenkins dapat diakses menggunakan akun administrator.
- Host `builder-01` tersedia dan dapat dijangkau melalui SSH dari Jenkins Controller.
- User target pada agen adalah `<agent-user>`.
- Port SSH (`22`) terbuka dan daemon SSH berjalan di node agen.

## Execution Decision

### PS-ADR-0002 — Containerized Ephemeral Build Environment

Refer to:

- **[PS-ADR-0002 — Containerized Ephemeral Build Environment (DooD with Rootless Podman)](../../../../adr/personal-site/adr-records/PS-ADR-0002.md){ target="_blank" rel="noopener" }**

**Decision**

Jenkins SSH Agent `builder-01` menjalankan build melalui ephemeral container
yang dibuat oleh Rootless Podman pada host agent.

**Reason**

- Menjaga tool build dan dependensinya di luar Jenkins Controller serta OS host.
- Menghasilkan build environment yang konsisten dan mudah direproduksi.
- Menghindari privileged nested container dengan tetap menjalankan Podman secara
  rootless.

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Prepare SSH Key Pair on Jenkins Controller

Buat pasangan kunci SSH di Jenkins Controller atau mesin yang mengelola Jenkins.

```bash
ssh-keygen -t ed25519 -C "jenkins-agent" -f ~/.ssh/id_ed25519_jenkins_agent
```

!!! success "Expected Result"

    Private key dan public key Jenkins agent berhasil dibuat. Pelajari perbedaan,
    penempatan, serta cara melindungi keduanya pada
    [Private Key and Public Key](../../../../how-to/cheats/ssh.md#private-key-and-public-key).

</div>

<div class="procedure-step" markdown>

### Copy Public Key to Agent Node (`builder-01`)

Pada `builder-01`, pastikan direktori `~/.ssh` ada dan memiliki permission yang benar.

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

> Tips: Jika `ssh-copy-id` tersedia, gunakan `ssh-copy-id -i ~/.ssh/id_ed25519_jenkins_agent.pub <agent-user>@builder-01` untuk mempermudah instalasi kunci.

!!! success "Expected Result"

    Public key tersedia dalam `authorized_keys` milik user agent.

</div>

<div class="procedure-step" markdown>

### Verify SSH Connection from Controller to Agent

```bash
ssh -i ~/.ssh/id_ed25519_jenkins_agent <agent-user>@builder-01 hostname
```

Jika koneksi berhasil, node agen akan merespon tanpa meminta password.

!!! success "Expected Result"

    Controller dapat terhubung ke `builder-01` melalui SSH tanpa password interaktif.

</div>

<div class="procedure-step" markdown>

### Add SSH Credential to Jenkins

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

!!! success "Expected Result"

    Credential `builder01-ssh` tersedia pada Jenkins Global credentials.

</div>

<div class="procedure-step" markdown>

### Create the `builder-01` Agent Node in Jenkins

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

!!! success "Expected Result"

    Node `builder-01` tersimpan dengan konfigurasi SSH dan label yang ditentukan.

</div>

<div class="procedure-step" markdown>

### Test Agent Connection

Setelah node dibuat, klik **Launch agent** atau **Connect**. Pastikan status berubah menjadi **Online**.

!!! success "Expected Result"

    Node `builder-01` berstatus **Online**.

</div>

<div class="procedure-step" markdown>

### Verify Agent Environment

Pastikan agen dapat menjalankan perintah shell sederhana dan memiliki akses ke binary yang dibutuhkan.

Contoh pengujian di Jenkins:

1. Buat Jenkins freestyle job atau pipeline.
2. Jalankan `sh 'whoami && pwd && id && podman version'`.

Jika perintah berhasil, agen siap menjalankan pipeline.

!!! success "Expected Result"

    Agent dapat menjalankan shell dan rootless Podman dari Jenkins.

</div>

</div>

## Verification

| Item | Status | Notes |
|------|--------|-------|
| SSH key authentication berhasil | ✅ | Login ke `builder-01` tanpa password menggunakan kunci publik. |
| Node `builder-01` online di Jenkins | ✅ | Jenkins node status menjadi **Online**. |
| Remote root directory dapat diakses | ✅ | Jenkins dapat membuat workspace di node agen. |
| Agent dapat menjalankan perintah shell | ✅ | `whoami`, `pwd`, dan `podman version` berhasil. |
| Build Pipeline tidak lagi dijalankan di Controller | ✅ | Eksekusi pipeline diarahkan ke `builder-01`. |

## Notes

- Pastikan `builder-01` memiliki paket SSH server aktif dan user `<agent-user>` memiliki hak akses yang tepat.
- Untuk keamanan produksi, gunakan `Host Key Verification Strategy` yang lebih ketat setelah pengujian awal selesai.
- Jika menggunakan SELinux, pastikan permission volume dan home directory sudah sesuai.

## Related Documentation

- [TN-001 — Initialize Jenkins Controller & Environment](TN-001-initialize-jenkins-controller-environment.md)
- [TN-003 — Configure Gitea Repository Access](TN-003-configure-gitea-repository-access.md)
- [Continuous Integration Engineering Journal](index.md)

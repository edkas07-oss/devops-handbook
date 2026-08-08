# SSH Cheat Sheet

## Generate SSH Key

```bash
ssh-keygen -t ed25519
```

---

## Generate RSA 4096

```bash
ssh-keygen -t rsa -b 4096
```

---

## List SSH Keys

```bash
ls -ltr ~/.ssh
```

---

## Show Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

---

## Show Private Key

```bash
cat ~/.ssh/id_ed25519
```

---

## SSH Directory

```text
~/.ssh/
```

---

## Common Files

| File | Description |
|------|-------------|
| id_ed25519 | Private Key |
| id_ed25519.pub | Public Key |
| known_hosts | Known SSH Hosts |
| authorized_keys | Authorized Public Keys |

---

## SSH Authentication Concept

SSH Authentication menggunakan pasangan **Private Key** dan **Public Key** (*Key Pair*) untuk melakukan autentikasi tanpa menggunakan password.

Kedua key tersebut selalu digunakan sebagai pasangan.

| Component | Location | Purpose |
|----------|----------|---------|
| **Private Key** | SSH Client | Digunakan untuk membuktikan identitas SSH Client. |
| **Public Key** | SSH Server | Digunakan oleh SSH Server untuk memverifikasi identitas SSH Client. |

---

## SSH Client and SSH Server

Dalam komunikasi SSH selalu terdapat dua peran.

| Role | Description |
|------|-------------|
| **SSH Client** | Sistem yang memulai koneksi SSH. |
| **SSH Server** | Sistem yang menerima koneksi SSH. |

Komunikasi SSH selalu dimulai oleh **SSH Client** menuju **SSH Server**.

```text
SSH Client  ----------------------->  SSH Server
             SSH Connection
```

---

## SSH Key Placement

Setelah pasangan SSH Key dibuat, masing-masing key ditempatkan pada lokasi yang berbeda.

```text
SSH Client                     SSH Server

Private Key  ───────────────►  Public Key
   (Stored)                    (Registered)
```

- **Private Key** tetap disimpan pada SSH Client.
- **Public Key** didaftarkan pada SSH Server.
- **Private Key tidak pernah dipindahkan ke SSH Server.**

---

## SSH Authentication Flow

```text
Generate SSH Key Pair
         │
         ├── Private Key ───────────────► SSH Client
         │
         └── Public Key ────────────────► SSH Server
                                           │
                                           ▼
                              Registered for Authentication

SSH Client
     │
     │ 1. Initiate SSH Connection
     ▼
SSH Server
     │
     │ 2. Verify Registered Public Key
     ▼
Authentication Successful
```

---

## Authentication Process

1. Generate pasangan **SSH Key** pada SSH Client.
2. Simpan **Private Key** pada SSH Client.
3. Daftarkan **Public Key** pada SSH Server.
4. SSH Client memulai koneksi ke SSH Server.
5. SSH Server memverifikasi Public Key yang telah didaftarkan.
6. Apabila proses verifikasi berhasil, koneksi SSH diizinkan.

---

## Common Misconception

Sering muncul anggapan bahwa Public Key berasal dari SSH Server.

Sebenarnya:

- Public Key merupakan pasangan dari Private Key yang dibuat pada SSH Client.
- Public Key kemudian didaftarkan pada SSH Server.
- SSH Server hanya menyimpan Public Key untuk keperluan verifikasi identitas SSH Client.

Dengan kata lain:

```text
Generate SSH Key Pair
        │
        ├── Private Key ──► Disimpan pada SSH Client
        │
        └── Public Key ───► Didaftarkan pada SSH Server
```

---

---

## First SSH Connection

Pada saat SSH Client melakukan koneksi ke SSH Server untuk pertama kalinya, SSH akan memverifikasi identitas SSH Server menggunakan **Host Key Fingerprint**.

Apabila SSH Server belum pernah dikenal sebelumnya, akan muncul konfirmasi seperti berikut:

```text
The authenticity of host '<hostname>' can't be established.
ED25519 key fingerprint is SHA256:<fingerprint>.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Ketik:

```text
yes
```

Apabila fingerprint diterima, SSH akan menyimpan informasi tersebut ke file:

```text
~/.ssh/known_hosts
```

Contoh output:

```text
Warning: Permanently added '<hostname>' (ED25519) to the list of known hosts.
```

Pada koneksi berikutnya, konfirmasi tersebut tidak akan muncul kembali selama Host Key SSH Server tidak berubah.

---

## Successful Authentication

Apabila autentikasi SSH berhasil, SSH Server akan mengembalikan pesan yang menunjukkan bahwa SSH Client telah berhasil diidentifikasi.

Contoh:

```text
Hi there, <username>!
You've successfully authenticated with the key named <key-name>, but the server does not provide shell access.
```

Keterangan:

- **`<username>`** menunjukkan akun yang berhasil diautentikasi.
- **`<key-name>`** merupakan nama (title) SSH Key yang terdaftar pada SSH Server.
- Pesan **"does not provide shell access"** bersifat normal pada layanan yang hanya menggunakan SSH sebagai media autentikasi, seperti Git Repository. Autentikasi telah berhasil meskipun shell tidak diberikan.

---

## Host Key Verification

SSH menggunakan file berikut untuk menyimpan fingerprint SSH Server yang telah dipercaya.

```text
~/.ssh/known_hosts
```

Apabila fingerprint SSH Server berubah, SSH akan menampilkan peringatan untuk mencegah kemungkinan serangan **Man-in-the-Middle (MITM)**.

Oleh karena itu, perubahan Host Key harus selalu diverifikasi sebelum memperbarui entri pada `known_hosts`.
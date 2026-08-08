# Troubleshooting

## 🚀 Get Started

Halaman ini berisi beberapa permasalahan umum yang sering ditemui saat menggunakan Git beserta solusi yang dapat dilakukan.

Panduan ini dapat digunakan sebagai referensi ketika proses pengelolaan source code mengalami kendala.

---

## 📚 Common Issues

### Authentication Failed

#### Symptoms

```text
fatal: Authentication failed
```

#### Possible Causes

- Username atau password salah.
- Personal Access Token (PAT) tidak valid.
- Credential yang tersimpan sudah tidak berlaku.

#### Resolution

Periksa konfigurasi remote repository.

```bash
git remote -v
```

Hapus credential lama apabila diperlukan, kemudian lakukan autentikasi kembali menggunakan credential yang benar.

---

### Permission Denied

#### Symptoms

```text
remote: Permission denied
fatal: unable to access repository
```

#### Possible Causes

- Tidak memiliki hak akses ke repository.
- Repository bersifat private.
- SSH Key belum dikonfigurasi.

#### Resolution

Pastikan akun memiliki hak akses ke repository.

Apabila menggunakan SSH, pastikan SSH Key telah dikonfigurasi dengan benar.

---

### Remote Repository Already Exists

#### Symptoms

```text
error: remote origin already exists.
```

#### Possible Causes

Remote repository dengan nama `origin` telah dikonfigurasi sebelumnya.

#### Resolution

Tampilkan remote repository.

```bash
git remote -v
```

Perbarui URL repository.

```bash
git remote set-url origin <repository-url>
```

Atau hapus remote repository.

```bash
git remote remove origin
```

Kemudian tambahkan kembali.

```bash
git remote add origin <repository-url>
```

---

### Rejected Push

#### Symptoms

```text
! [rejected] main -> main (non-fast-forward)
```

#### Possible Causes

Remote repository memiliki commit yang belum tersedia pada local repository.

#### Resolution

Ambil perubahan terbaru.

```bash
git pull
```

Kemudian lakukan push kembali.

```bash
git push
```

---

### Merge Conflict

#### Symptoms

```text
CONFLICT (content)
Automatic merge failed
```

#### Possible Causes

Perubahan yang sama dilakukan pada file yang sama.

#### Resolution

Buka file yang mengalami konflik.

Cari bagian berikut.

```text
<<<<<<< HEAD
...
=======
...
>>>>>>> feature
```

Perbaiki konflik secara manual.

Setelah selesai.

```bash
git add .
git commit
```

---

### Detached HEAD

#### Symptoms

```text
HEAD detached at <commit>
```

#### Possible Causes

Checkout dilakukan langsung ke commit tertentu.

#### Resolution

Kembali ke branch.

```bash
git switch main
```

Atau buat branch baru.

```bash
git switch -c new-branch
```

---

## 💡 Best Practices

Untuk mengurangi kemungkinan terjadinya masalah, lakukan beberapa praktik berikut.

- Commit perubahan secara berkala.
- Gunakan branch untuk setiap fitur baru.
- Lakukan `git pull` sebelum memulai pekerjaan.
- Gunakan pesan commit yang jelas.
- Hindari melakukan force push kecuali benar-benar diperlukan.

---

## 🔗 Related Documents

| Document | Description |
|----------|-------------|
| **Publish Project to Git Repository** | Mempublikasikan project ke Git repository. |
| **Clone Git Repository** | Mengambil project dari Git repository. |
| **Manage Branches** | Mengelola branch selama proses pengembangan. |

---

## 📝 Summary

Pada halaman ini telah dijelaskan beberapa permasalahan umum yang sering ditemui saat menggunakan Git, penyebabnya, serta langkah penyelesaiannya.

Apabila masalah yang dihadapi belum tercakup pada halaman ini, gunakan dokumentasi resmi Git atau dokumentasi dari layanan Git repository yang digunakan.
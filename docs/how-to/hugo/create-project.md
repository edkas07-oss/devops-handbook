# Create Hugo Project

## 🚀 Get Started

Panduan ini menjelaskan cara membuat project baru menggunakan Hugo.

Project yang dihasilkan merupakan struktur standar Hugo dan menjadi fondasi untuk membangun website statis menggunakan Hugo.

Setelah menyelesaikan panduan ini, project Hugo siap digunakan untuk instalasi theme dan pengembangan website.

---

## 📋 Prerequisites

Pastikan Hugo telah berhasil diinstal.

Verifikasi instalasi Hugo.

```bash
hugo version
```

Contoh output.

```text
hugo v0.164.0+extended linux/amd64 BuildDate=...
```

Apabila Hugo belum terinstal, ikuti panduan berikut.

- [Install Hugo](installation.md)

---

## ▶️ Procedure

### Create New Project

Masuk ke direktori kerja.

```bash
cd ~/git
```

Buat project Hugo baru.

```bash
hugo new project personal-site
```

Contoh output.

```text
Congratulations! Your new Hugo project was created in

/home/eddywiyatno/git/personal-site
```

---

### Initialize Existing Repository

Apabila repository Git telah dibuat sebelumnya, masuk ke direktori repository.

```bash
cd ~/git/personal-site
```

Jalankan perintah berikut.

```bash
hugo new project . --force
```

Contoh output.

```text
Congratulations! Your new Hugo project was created in

/home/eddywiyatno/git/personal-site
```

!!! note "Engineering Notes"

    Parameter `--force` memungkinkan Hugo melakukan inisialisasi pada direktori yang telah berisi repository Git.

    Pendekatan ini umumnya digunakan apabila repository dibuat terlebih dahulu menggunakan GitHub, Gitea, atau layanan Git lainnya.

---

## ✅ Verification

Masuk ke direktori project.

```bash
cd ~/git/personal-site
```

Tampilkan struktur project.

```bash
tree -L 2
```

Contoh output.

```text
.
├── archetypes
│   └── default.md
├── assets
├── content
├── data
├── hugo.toml
├── i18n
├── layouts
├── static
└── themes
```

Pastikan struktur direktori berhasil dibuat tanpa pesan kesalahan.

!!! success "Verification"

    Project Hugo berhasil dibuat dan siap digunakan.

---

## 💡 Engineering Notes

Hugo menyediakan dua metode untuk membuat project.

**Membuat project baru**

```bash
hugo new project personal-site
```

Digunakan ketika direktori project belum tersedia.

**Menginisialisasi project pada repository yang sudah ada**

```bash
hugo new project . --force
```

Digunakan ketika repository Git telah dibuat terlebih dahulu dan ingin diisi dengan struktur project Hugo.

---

## 🔗 Related Documents

- [Get Started](index.md)
- [Install Hugo](installation.md)
- [Project Structure](project-structure.md)
- [Install Theme](install-theme.md)
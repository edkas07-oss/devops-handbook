# Install Theme

## 🚀 Get Started

Panduan ini menjelaskan cara menginstal Hugo Theme pada project Hugo.

Hugo menyediakan berbagai pilihan theme yang dapat digunakan untuk mempercepat proses pengembangan website tanpa harus membuat tampilan dari awal.

Pada panduan ini digunakan **Ananke**, yaitu theme bawaan yang direkomendasikan oleh dokumentasi resmi Hugo.

Setelah menyelesaikan panduan ini, project Hugo siap dijalankan menggunakan theme Ananke.

---

## 📋 Prerequisites

Pastikan project Hugo telah berhasil dibuat.

Apabila belum, ikuti panduan berikut.

- [Create Hugo Project](create-project.md)

Pastikan Git telah terinstal.

```bash
git --version
```

Contoh output.

```text
git version 2.x.x
```

---

## ▶️ Procedure

### Change to Project Directory

Masuk ke direktori project.

```bash
cd ~/git/personal-site
```

---

### Clone Theme Repository

Klik [Hugo Themes](https://themes.gohugo.io/) untuk melihat list theme yang tersedia. Contoh misalnya `ananke`.

Clone repository Ananke ke direktori `themes`.

```bash
git clone https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
```

Contoh output.

```text
Cloning into 'themes/ananke'...
remote: Enumerating objects...
Receiving objects: 100%
Resolving deltas: 100%
```

---

### Configure Hugo Theme

Buka file konfigurasi Hugo.

```bash
vim hugo.toml
```

Perbarui konfigurasi berikut.

```toml
baseURL = 'https://example.org/'
languageCode = 'en-us'
title = 'My Personal Site'
theme = 'ananke'
```

!!! note "Engineering Notes"

    Parameter `theme` menentukan Hugo Theme yang digunakan saat proses build maupun saat menjalankan Development Server.

    Apabila menggunakan theme yang berbeda, ubah nilai parameter tersebut sesuai nama direktori theme pada folder `themes`.

---

### Review Theme Directory

Tampilkan struktur direktori `themes`.

```bash
tree themes -L 2
```

Contoh output.

```text
themes/
└── ananke
    ├── archetypes
    ├── assets
    ├── layouts
    ├── static
    └── theme.toml
```

Pastikan repository Ananke berhasil diunduh.

---

## ✅ Verification

Pastikan theme berhasil dikloning.

```bash
ls themes
```

Contoh output.

```text
ananke
```

Periksa konfigurasi Hugo.

```bash
grep "^theme" hugo.toml
```

Contoh output.

```text
theme = "ananke"
```

!!! success "Verification"

    Hugo Theme berhasil diinstal dan siap digunakan.

---

## 💡 Engineering Notes

Hugo Theme dapat diinstal dengan beberapa metode, seperti Git Clone, Git Submodule, maupun mengunduh source code secara manual.

Pada panduan ini digunakan **Git Clone** karena lebih sederhana dan mudah dipahami.

Untuk kebutuhan production, penggunaan **Git Submodule** lebih disarankan karena memudahkan proses update theme tanpa mencampurkan source code project dengan source code theme.

Panduan penggunaan Git Submodule akan dibahas pada dokumen terpisah.

---

## 🔗 Related Documents

- [Create Hugo Project](create-project.md)
- [Project Structure](project-structure.md)
- [Run Development Server](run-development-server.md)
- [Update Theme](update-theme.md)
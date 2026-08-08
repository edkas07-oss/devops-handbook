# Project Structure

## 🚀 Get Started

Pada panduan sebelumnya, Anda telah berhasil membuat project Hugo.

Saat project dibuat, Hugo secara otomatis menghasilkan struktur direktori standar yang akan digunakan selama proses pengembangan website.

Panduan ini menjelaskan fungsi setiap file dan direktori sehingga Anda memahami peran masing-masing komponen sebelum mulai menginstal theme, membuat konten, maupun melakukan kustomisasi website.

---

## 📋 Prerequisites

Pastikan project Hugo telah berhasil dibuat.

Apabila belum, ikuti panduan berikut.

- [Create Hugo Project](create-project.md)

---

## ▶️ Procedure

### Review Project Structure

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

Struktur di atas merupakan struktur standar yang dihasilkan oleh Hugo.

---

### Review Project Components

Berikut fungsi masing-masing file dan direktori.

| File / Directory | Description |
|------------------|-------------|
| `archetypes/` | Menyimpan template default yang digunakan saat membuat konten baru menggunakan perintah `hugo new`. |
| `assets/` | Menyimpan aset yang diproses oleh Hugo Pipes, seperti SCSS, JavaScript, dan image processing. |
| `content/` | Menyimpan seluruh konten website, seperti halaman, artikel, maupun dokumentasi. |
| `data/` | Menyimpan data tambahan dalam format YAML, TOML, atau JSON yang dapat digunakan oleh template Hugo. |
| `hugo.toml` | File konfigurasi utama yang digunakan untuk mengatur website. |
| `i18n/` | Menyimpan file terjemahan untuk website yang mendukung banyak bahasa. |
| `layouts/` | Menyimpan template HTML yang digunakan untuk mengatur tampilan website. |
| `static/` | Menyimpan file statis seperti gambar, favicon, CSS, JavaScript, maupun file lain yang akan disalin langsung ke direktori hasil build. |
| `themes/` | Menyimpan Hugo Theme yang digunakan oleh project. |

---

### Review Development Workflow

Selama proses pengembangan website, setiap direktori memiliki fungsi yang berbeda.

| Directory | Digunakan Untuk |
|-----------|-----------------|
| `content/` | Membuat halaman dan artikel. |
| `themes/` | Menambahkan atau memperbarui Hugo Theme. |
| `layouts/` | Melakukan kustomisasi template website. |
| `assets/` | Mengelola SCSS, JavaScript, dan Hugo Pipes. |
| `static/` | Menambahkan gambar, favicon, font, dan file statis lainnya. |
| `data/` | Menyediakan data tambahan untuk template Hugo. |
| `i18n/` | Mengembangkan website multibahasa. |
| `archetypes/` | Membuat template standar untuk konten baru. |
| `hugo.toml` | Mengelola konfigurasi website. |

---

## ✅ Verification

Pastikan struktur project masih sesuai dengan struktur standar Hugo.

```bash
tree -L 2
```

Pastikan direktori berikut tersedia.

- `archetypes`
- `assets`
- `content`
- `data`
- `i18n`
- `layouts`
- `static`
- `themes`

Pastikan file berikut tersedia.

- `hugo.toml`

!!! success "Verification"

    Struktur project Hugo berhasil dibuat dan siap digunakan untuk proses pengembangan website.

---

## 💡 Engineering Notes

Tidak semua direktori akan langsung digunakan pada tahap awal pengembangan website.

Untuk project sederhana, direktori yang paling sering digunakan adalah:

| Directory | Keterangan |
|-----------|------------|
| `content/` | Menyimpan halaman dan artikel website. |
| `themes/` | Menyimpan Hugo Theme yang digunakan. |
| `static/` | Menyimpan gambar, favicon, dan file statis lainnya. |
| `hugo.toml` | Mengelola konfigurasi website. |

Direktori seperti `layouts`, `assets`, `data`, `archetypes`, dan `i18n` umumnya mulai digunakan ketika website membutuhkan kustomisasi atau fitur yang lebih kompleks.

---

## 🔗 Related Documents

- [Create Hugo Project](create-project.md)
- [Install Theme](install-theme.md)
- [Run Development Server](run-development-server.md)
- [Create Home Page](create-home-page.md)
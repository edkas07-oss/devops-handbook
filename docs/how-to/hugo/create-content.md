# Create Content

## 🚀 Get Started

Panduan ini menjelaskan cara membuat konten baru pada project Hugo
menggunakan perintah `hugo new content`.

Setelah menyelesaikan panduan ini, Anda dapat membuat, mengubah, dan
menampilkan konten melalui Hugo Development Server.

---

## 📋 Prerequisites

Pastikan:

- Hugo telah terinstal.
- Project Hugo telah berhasil dibuat.
- Development Server telah berjalan.

Apabila belum, lihat dokumen berikut.

- [Install Hugo](installation.md)
- [Create Hugo Project](create-project.md)
- [Run Development Server](run-development-server.md)

---

## ▶️ Procedure

### Create New Content

Masuk ke direktori project.

```bash
cd ~/git/personal-site
```
Buat konten baru.

```bash
hugo new content articles/my-first-post.md
```

Contoh output.

```text
Content "/home/eddywiyatno/git/personal-site/content/articles/my-first-post.md" created
```

Isi kontek akan terlihat seperti dibawah ini"

```bash
vim content/articles/my-first-post.md
```

output.

```toml
+++
title = "My First Post"
date = 2026-07-17T00:00:00+07:00
draft = true
+++

# Introduction

Ini adalah artikel pertama pada Personal Site.
```

---

### Preview Content

``` text
http://localhost:1313/articles/my-first-post/
```

Apabila menggunakan status `draft = true`, jalankan:

``` bash
hugo server -D
```

---

## ✅ Verification

``` text
content/articles/my-first-post.md
```

``` text
http://localhost:1313/articles/my-first-post/
```

!!! success "Verification"

    Konten berhasil dibuat dan dapat ditampilkan.

---

## 💡 Engineering Notes

Perintah:

``` bash
hugo new content articles/my-first-post.md
```

akan membuat file Markdown beserta Front Matter secara otomatis.

Secara default:

``` toml
draft = true
```

Status tersebut mencegah konten dipublikasikan sebelum siap.

Untuk mempublikasikan konten:

``` toml
draft = false
```

atau gunakan:

``` bash
hugo server -D
```

selama proses pengembangan.

---

## 🔗 Related Documents

- [Run Development Server](run-development-server.md)
- [Build Website](build-website.md)
- [Deploy Static Website](deploy-static-website.md)

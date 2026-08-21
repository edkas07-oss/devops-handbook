# Create Home Page

## 🚀 Get Started

Panduan ini menjelaskan cara membuat halaman utama (Home Page) pada website Hugo.

Home Page merupakan halaman pertama yang ditampilkan ketika pengunjung mengakses website. Pada tahap awal, halaman ini digunakan untuk memperkenalkan website sebelum konten lain seperti artikel, project, maupun curriculum vitae ditambahkan.

Setelah menyelesaikan panduan ini, website akan memiliki halaman utama yang dapat ditampilkan melalui Hugo Development Server.

---

## 📋 Prerequisites

Pastikan Development Server telah berhasil dijalankan.

Apabila belum, ikuti panduan berikut.

- [Run Development Server](run-development-server.md)

Masuk ke direktori project.

```bash
cd ~/git/personal-site
```

---

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Create Home Page

Buat file berikut.

```bash
hugo new content _index.md
```
Tambahkan konten berikut.

```bash
vim content/_index.md
```
Contoh isi file.

```toml
+++
title = "Home"
date = 2026-07-23T00:00:00+07:00
draft = false
+++

# Welcome

Selamat datang di Personal Site saya.

Website ini berisi artikel, dokumentasi project, dan pengalaman yang saya bagikan selama mempelajari berbagai teknologi.
```

Simpan perubahan.

</div>

<div class="procedure-step" markdown>

### Review Home Page

Apabila Development Server masih berjalan, browser akan memperbarui halaman secara otomatis.

Apabila Development Server belum dijalankan, jalankan perintah berikut.

```bash
hugo server
```

Buka browser.

```text
http://localhost:1313
```

Home Page akan menampilkan konten yang baru dibuat.

---


</div>

</div>

## ✅ Verification

Pastikan file berikut berhasil dibuat.

```text
content/_index.md
```

Pastikan Home Page dapat diakses melalui browser.

```text
http://localhost:1313
```

Periksa bahwa halaman menampilkan judul dan isi yang telah ditambahkan.

!!! success "Verification"

    Home Page berhasil dibuat dan dapat ditampilkan menggunakan Hugo Development Server.

---

## 💡 Engineering Notes

Hugo menggunakan file khusus bernama `_index.md` sebagai halaman utama pada sebuah section.

Untuk Home Page website, file tersebut berada pada direktori:

```text
content/_index.md
```

Apabila file ini tidak tersedia, Hugo akan menggunakan template bawaan dari theme yang digunakan.

Dengan membuat `content/_index.md`, Anda dapat menyesuaikan isi halaman utama tanpa perlu mengubah source code theme.

---

## 🔗 Related Documents

- [Run Development Server](run-development-server.md)
- [Create Content](create-content.md)
- [Build Website](build-site.md)
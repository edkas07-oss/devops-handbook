# Run Development Server

## 🚀 Get Started

Panduan ini menjelaskan cara menjalankan Hugo Development Server untuk melihat website secara lokal.

Development Server memungkinkan setiap perubahan pada konten maupun konfigurasi website ditampilkan secara otomatis tanpa perlu melakukan proses build secara manual.

Setelah menyelesaikan panduan ini, website dapat diakses melalui browser menggunakan Development Server.

---

## 📋 Prerequisites

Pastikan Hugo Theme telah berhasil diinstal.

Apabila belum, ikuti panduan berikut.

- [Install Theme](install-theme.md)

Pastikan berada pada direktori project Hugo.

```bash
cd ~/git/personal-site
```

---

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Start Development Server

Jalankan Development Server.

```bash
hugo server
```

Contoh output.

```text
Watching for changes in ...

Environment: "development"

Web Server is available at http://localhost:1313/

Press Ctrl+C to stop
```

Development Server akan terus berjalan hingga dihentikan secara manual.

</div>

<div class="procedure-step" markdown>

### Start Development Server for Remote Access

Secara default, Development Server hanya dapat diakses melalui `localhost`. Untuk mengakses website dari perangkat lain pada jaringan yang sama, jalankan Development Server dengan menentukan **bind address** dan **base URL**.

```bash
hugo server \
  --bind 0.0.0.0 \
  --baseURL http://192.168.1.50:1313
```

Ganti `192.168.1.50` dengan alamat IP komputer yang menjalankan Hugo.

Setelah server berhasil dijalankan, website dapat diakses melalui browser menggunakan alamat berikut.

```text
http://192.168.1.50:1313
```

!!! tip "When to Use"

    Gunakan opsi ini ketika ingin mengakses Development Server dari perangkat lain, seperti laptop, tablet, atau smartphone yang berada pada jaringan yang sama.

!!! note "Implementation Notes"

    Pastikan firewall mengizinkan koneksi ke port **1313** dan seluruh perangkat berada pada jaringan yang sama.

</div>

<div class="procedure-step" markdown>

### Open Website

Buka browser.

Akses alamat berikut.

```text
http://localhost:1313
```

Apabila berhasil, halaman utama website akan ditampilkan menggunakan theme **Ananke**.

</div>

<div class="procedure-step" markdown>

### Enable Draft Content

Secara default, Hugo tidak menampilkan konten yang masih berstatus **draft**.

Status draft ditentukan oleh parameter `draft` pada front matter setiap file konten.

Contoh.

```toml
+++
title = "My First Post"
draft = true
+++
```

Apabila bernilai `true`, halaman hanya akan ditampilkan ketika Development Server dijalankan menggunakan parameter `-D`.

Untuk melihat seluruh konten yang masih berstatus draft, jalankan perintah berikut.

```bash
grep -R "draft = true" content/
```

Untuk menampilkan seluruh konten termasuk draft di browser, jalankan perintah berikut.

```bash
hugo server -D
```

!!! note "Engineering Notes"

    Parameter `-D` merupakan singkatan dari `--buildDrafts`.

    Parameter ini digunakan selama proses pengembangan agar halaman yang masih berstatus draft tetap dapat ditampilkan pada Development Server.

</div>

<div class="procedure-step" markdown>

### Stop Development Server

Untuk menghentikan Development Server, tekan:

```text
Ctrl + C
```

Server akan berhenti dan terminal kembali ke shell.

---


</div>

</div>

## ✅ Verification

Pastikan Development Server berhasil dijalankan.

Verifikasi menggunakan browser.

```text
http://localhost:1313
```

Pastikan halaman website berhasil ditampilkan.

Verifikasi menggunakan terminal.

```text
Web Server is available at http://localhost:1313/
```

!!! success "Verification"

    Hugo Development Server berhasil dijalankan.

---

## 💡 Engineering Notes

Development Server digunakan selama proses pengembangan website.

Setiap perubahan pada file seperti:

- Content
- Theme
- Configuration
- Layout

akan dideteksi secara otomatis sehingga browser dapat menampilkan perubahan tanpa perlu menjalankan kembali perintah `hugo server`.

Untuk deployment ke production, gunakan perintah `hugo` untuk menghasilkan static website pada direktori `public/`.

---

## 🔗 Related Documents

- [Install Theme](install-theme.md)
- [Create Home Page](create-home-page.md)
- [Create Content](create-content.md)
- [Build Website](build-site.md)
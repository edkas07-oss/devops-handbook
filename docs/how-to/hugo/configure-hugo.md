# Configure Hugo

## 🚀 Get Started

Panduan ini menjelaskan cara mengonfigurasi project Hugo melalui file
`hugo.toml`.

Konfigurasi ini digunakan untuk menentukan identitas website, bahasa,
URL, serta theme yang digunakan.

Setelah menyelesaikan panduan ini, project Hugo telah memiliki
konfigurasi dasar dan siap untuk proses build maupun deployment.

------------------------------------------------------------------------

## 📋 Prerequisites

Pastikan:

-   Project Hugo telah berhasil dibuat.
-   Hugo Theme telah berhasil diinstal.
-   Development Server telah berhasil dijalankan.

Apabila belum, lihat dokumen berikut.

-   [Create Hugo Project](create-project.md)
-   [Install Theme](install-theme.md)
-   [Run Development Server](run-development-server.md)

------------------------------------------------------------------------

## ▶️ Procedure

### Review Current Configuration

Masuk ke direktori project.

``` bash
cd ~/git/personal-site
```

Tampilkan konfigurasi saat ini.

``` bash
cat hugo.toml
```

Contoh output.

``` toml
baseURL = 'https://example.org/'
languageCode = 'en-us'
title = 'My New Hugo Project'
theme = 'ananke'
```

------------------------------------------------------------------------

### Update Site Configuration

Edit file konfigurasi.

``` bash
vim hugo.toml
```

Perbarui konfigurasi berikut.

``` toml
baseURL = "https://example.com/"
languageCode = "id"
title = "Personal Site"
theme = "ananke"
```

------------------------------------------------------------------------

### Review Changes

Apabila Development Server masih berjalan, buka browser.

``` text
http://localhost:1313
```

Pastikan judul website telah berubah sesuai konfigurasi.

------------------------------------------------------------------------

## ✅ Verification

Periksa kembali konfigurasi.

``` bash
cat hugo.toml
```

Pastikan parameter berikut telah diperbarui:

-   `baseURL`
-   `languageCode`
-   `title`
-   `theme`

!!! success "Verification"

    Konfigurasi dasar Hugo berhasil diperbarui.

------------------------------------------------------------------------

## 💡 Engineering Notes

Parameter yang paling sering diubah pada project Hugo adalah:

  Parameter        Description
  ---------------- --------------------------------------------
  `baseURL`        URL utama website saat deployment.
  `languageCode`   Bahasa utama website.
  `title`          Judul website yang ditampilkan oleh theme.
  `theme`          Nama theme yang digunakan oleh project.

Selama proses pengembangan lokal, nilai `baseURL` tidak memengaruhi
akses melalui `http://localhost:1313`. Sebelum website dipublikasikan,
ubah `baseURL` agar sesuai dengan alamat website yang sebenarnya.

------------------------------------------------------------------------

## 🔗 Related Documents

-   [Run Development Server](run-development-server.md)
-   [Create Content](create-content.md)
-   [Build Website](build-website.md)

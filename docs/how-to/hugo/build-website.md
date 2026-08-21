# Build Website

## 🚀 Get Started

Panduan ini menjelaskan cara membangun (build) project Hugo menjadi
static website.

Proses build akan menghasilkan seluruh file website yang siap
dipublikasikan ke web server.

Setelah menyelesaikan panduan ini, seluruh hasil build akan tersedia
pada direktori `public/`.

------------------------------------------------------------------------

## 📋 Prerequisites

Pastikan:

-   Project Hugo telah dikonfigurasi.
-   Seluruh konten telah selesai dibuat.
-   Tidak terdapat kesalahan pada Hugo Development Server.

Apabila belum, lihat dokumen berikut.

-   [Configure Hugo](configure-hugo.md)
-   [Create Content](create-content.md)

------------------------------------------------------------------------

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Build Website

Masuk ke direktori project.

``` bash
cd ~/git/personal-site
```

Jalankan proses build.

``` bash
hugo
```

Contoh output.

``` text
Start building sites ...
...
Total in 120 ms
```

------------------------------------------------------------------------

</div>

<div class="procedure-step" markdown>

### Review Build Result

Tampilkan struktur direktori hasil build.

``` bash
tree public -L 2
```

Contoh output.

``` text
public
├── 404.html
├── articles
├── categories
├── images
├── index.html
├── index.xml
├── sitemap.xml
└── tags
```

------------------------------------------------------------------------

</div>

<div class="procedure-step" markdown>

### Review Home Page

Buka file hasil build.

``` bash
xdg-open public/index.html
```

Atau gunakan browser untuk membuka file `public/index.html`.

------------------------------------------------------------------------


</div>

</div>

## ✅ Verification

Pastikan direktori `public` berhasil dibuat.

``` bash
ls public
```

Pastikan file berikut tersedia.

-   index.html
-   sitemap.xml
-   index.xml

!!! success "Verification"

    Static website berhasil dibangun dan siap untuk proses deployment.

------------------------------------------------------------------------

## 💡 Engineering Notes

Perintah:

``` bash
hugo
```

akan menghasilkan static website pada direktori `public/`.

Direktori tersebut merupakan artefak hasil build dan dapat langsung
dipublikasikan menggunakan web server seperti NGINX, Apache HTTP Server,
atau layanan object storage.

Karena direktori `public/` dapat dibuat kembali kapan saja, direktori
ini umumnya tidak disimpan ke dalam Git repository.

Tambahkan aturan berikut ke file `.gitignore`.

``` text
/public/
```

------------------------------------------------------------------------

## 🔗 Related Documents

-   [Configure Hugo](configure-hugo.md)
-   [Create Content](create-content.md)
-   [Deploy Static Website](deploy-static-website.md)

# Deployment

## Overview

Setelah dokumentasi selesai ditulis, langkah berikutnya adalah mempublikasikan website agar dapat diakses oleh pengguna.

Pada panduan ini, website dijalankan menggunakan **NGINX Container**. Image `nginx-image` hanya berperan sebagai **runtime**, sedangkan konten website disediakan secara terpisah. Dengan pendekatan ini, image tetap bersifat generik dan dapat digunakan untuk berbagai jenis static website tanpa perlu membangun ulang image setiap kali konten berubah.

```text
                Static Website
        (MkDocs / Hugo / React / HTML)
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   Local Disk      Object Storage     NFS
        │             │             │
        └─────────────┼─────────────┘
                      │
                      ▼
                 nginx-image
                      │
                      ▼
                   Browser
```

Pada implementasi dalam handbook ini, static website berasal dari hasil build MkDocs (`site/`) yang disimpan pada **Local Disk** dan di-*mount* ke dalam container menggunakan **bind mount**. Namun pendekatan yang sama dapat diterapkan apabila konten website disimpan pada NFS, NAS, maupun Object Storage.

!!! tip "Best Practice"

    Pisahkan runtime dan content. Image bertanggung jawab menyediakan web server, sedangkan website dikelola secara terpisah sehingga perubahan konten tidak memerlukan proses build image kembali.

---

## Deployment Architecture

Implementasi deployment pada panduan ini menggunakan hasil build MkDocs sebagai sumber static website.

```text
          DevOps Handbook
          (MkDocs Project)
                  │
          mkdocs build
                  │
                  ▼
               site/
                  │
                  │ Bind Mount
                  ▼
          /var/www/html
                  │
                  ▼
     localhost/nginx-image:1.0
                  │
                  ▼
          Podman Container
                  │
                  ▼
              Web Browser
```

---

## Deployment Workflow

Secara umum proses deployment terdiri dari beberapa tahapan.

```text
Markdown Files
       │
       ▼
 mkdocs build
       │
       ▼
site/
       │
       ▼
Run Container
       │
       ▼
NGINX
       │
       ▼
Browser
```

---

## Build the Website

Bangun website statis menggunakan perintah berikut.

```bash
mkdocs build
```

Apabila berhasil, MkDocs akan membuat direktori `site/`.

```text
devops-handbook/
├── docs/
├── mkdocs.yml
└── site/
```

Direktori `site/` berisi seluruh file HTML, CSS, JavaScript, gambar, dan aset lain yang dihasilkan oleh MkDocs.

Sebelum melakukan deployment, sinkronkan seluruh isi direktori `site/` ke lokasi yang akan digunakan sebagai sumber static website.

Sebagai contoh, pada implementasi ini hasil build disalin ke repository deployment.

```bash
rsync -av --delete site/ ~/git/devops-handbook-site/site/
```

Setelah proses sinkronisasi selesai, struktur repository deployment akan menjadi seperti berikut.

```text
devops-handbook-site/
├── CONFIG
├── PROJECT
├── VERSION
├── run.sh
├── stop.sh
├── README.md
└── site/
    ├── index.html
    ├── assets/
    ├── css/
    ├── images/
    ├── js/
    └── search/
```

Direktori `site/` pada repository deployment inilah yang nantinya di-*mount* ke dalam container sebagai document root NGINX.

!!! note "Engineering Notes"

    Pada panduan ini, hasil build MkDocs disimpan pada repository deployment untuk memudahkan proses deployment menggunakan bind mount. Namun pendekatan yang sama dapat diterapkan pada media penyimpanan lain seperti NFS, NAS, maupun Object Storage. Yang terpenting adalah runtime (`nginx-image`) memiliki akses ke direktori yang berisi static website.

!!! tip "Best Practice"

    Pisahkan source dokumentasi dan hasil build. Repository MkDocs digunakan untuk menyimpan source dokumentasi, sedangkan lokasi deployment hanya menyimpan static website hasil proses build. Pendekatan ini membuat proses deployment lebih fleksibel dan memudahkan integrasi dengan media penyimpanan lain maupun pipeline CI/CD.

---

## Deployment Project

Deployment dilakukan menggunakan repository terpisah yang bertugas menjalankan container.

```text
devops-handbook-site/
├── CONFIG
├── PROJECT
├── VERSION
├── run.sh
├── stop.sh
└── README.md
```

Repository ini **tidak membangun container image**.

Sebaliknya, deployment menggunakan image runtime yang telah dibuat sebelumnya.

```text
localhost/nginx-image:1.0
```

---

## Configure Deployment

Lokasi static website dikonfigurasi melalui file `CONFIG`.

```bash
IMAGE_NAME=localhost/nginx-image:1.0

WEB_ROOT="$HOME/git/devops-handbook-site/site"
```

Keterangan.

| Parameter | Description |
|-----------|-------------|
| `IMAGE_NAME` | Runtime image yang digunakan untuk menjalankan website. |
| `WEB_ROOT` | Lokasi static website pada host yang akan di-mount ke container. |

Pada implementasi ini, `WEB_ROOT` menunjuk ke direktori hasil build MkDocs.

---

## Run the Container

Jalankan deployment.

```bash
./run.sh
```

Container akan melakukan bind mount.

```text
Host
-------------------------------------
~/git/devops-handbook-site/site
            │
            ▼
Container
-------------------------------------
/var/www/html
```

NGINX kemudian menyajikan seluruh file yang berada pada direktori tersebut.

---

## Verification

Pastikan container berhasil dijalankan.

```bash
podman ps
```

Pastikan volume berhasil di-mount.

```bash
podman inspect devops-handbook-site
```

Pastikan document root berisi static website.

```bash
podman exec -it devops-handbook-site ls -lah /var/www/html
```

Contoh output.

```text
index.html
404.html
assets/
css/
images/
js/
search/
```

Selanjutnya akses website menggunakan browser.

```text
http://localhost:8080
```

!!! success "Verification"

    Deployment dinyatakan berhasil apabila:

    - Container berhasil dijalankan.
    - Direktori `site/` berhasil di-mount ke `/var/www/html`.
    - File `index.html` tersedia pada document root.
    - Website dapat diakses melalui browser.

---

## References

Dokumentasi resmi.

- [MkDocs - Deploying Your Docs](https://www.mkdocs.org/user-guide/deploying-your-docs/){: target="_blank" rel="noopener noreferrer" }
- [Podman Run](https://docs.podman.io/en/latest/markdown/podman-run.1.html){: target="_blank" rel="noopener noreferrer" }
- [NGINX Documentation](https://nginx.org/en/docs/){: target="_blank" rel="noopener noreferrer" }

---

## Summary

Pada bab ini kita telah mempelajari:

- Konsep pemisahan antara runtime dan content.
- Arsitektur deployment menggunakan NGINX Container.
- Membangun static website menggunakan `mkdocs build`.
- Menjalankan website menggunakan bind mount.
- Memverifikasi hasil deployment.

---

## Next Steps

Pada bab berikutnya kita akan membahas berbagai praktik terbaik dalam mengelola dokumentasi menggunakan MkDocs, mulai dari struktur direktori, penamaan halaman, pengelolaan repository, hingga standar penulisan dokumentasi.
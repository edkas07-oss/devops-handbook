# Deploy Static Website

## 🚀 Get Started

Panduan ini menjelaskan cara mempublikasikan hasil build Hugo menggunakan **NGINX Container**.

Website hasil build akan dijalankan secara langsung menggunakan Podman dengan me-mount direktori `public/` sebagai document root NGINX.

Setelah menyelesaikan panduan ini, website dapat diakses menggunakan web browser.

---

## 📋 Prerequisites

Pastikan:

- Website telah berhasil di-build.
- NGINX Image telah tersedia.

Apabila belum, lihat dokumen berikut.

- [Build Website](build-website.md)

---

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Review Build Output

Pastikan direktori `public/` telah berhasil dihasilkan.

```bash
tree public -L 2
```

Contoh output.

```text
public
├── 404.html
├── assets
├── css
├── images
├── index.html
├── sitemap.xml
└── ...
```

Pastikan file `index.html` tersedia.

</div>

<div class="procedure-step" markdown>

### Run NGINX Container

Jalankan NGINX Container dengan me-mount direktori `public/`.

```bash
podman run -d \
  --name hugo-site \
  -p 8080:80 \
  -v $(pwd)/public:/usr/share/nginx/html:ro \
  nginx:latest
```

Keterangan:

| Parameter | Description |
|-----------|-------------|
| `-d` | Menjalankan container di background. |
| `--name` | Memberikan nama container. |
| `-p 8080:80` | Memetakan port host ke container. |
| `-v` | Me-mount direktori `public/` sebagai document root NGINX. |
| `:ro` | Mount dalam mode read-only. |

</div>

<div class="procedure-step" markdown>

### Verify Running Container

Pastikan container berhasil dijalankan.

```bash
podman ps
```

Contoh output.

```text
CONTAINER ID  IMAGE           STATUS         PORTS
xxxxxxx       nginx:latest    Up 10 seconds  0.0.0.0:8080->80/tcp
```

</div>

<div class="procedure-step" markdown>

### Access Website

Buka browser.

```text
http://localhost:8080
```

Sesuaikan alamat host dan port apabila menggunakan konfigurasi yang berbeda.

---


</div>

</div>

## ✅ Verification

Pastikan:

- Container NGINX berstatus **Running**.
- Website dapat diakses melalui browser.
- Halaman utama berhasil ditampilkan.
- Tidak terdapat broken link.

!!! success "Verification"

    Static website berhasil dipublikasikan menggunakan NGINX Container.

---

## 💡 Engineering Notes

Pada panduan ini, hasil build Hugo tidak disalin ke direktori deployment lain.

NGINX Container secara langsung menggunakan direktori `public/` sebagai document root melalui mekanisme **bind mount**, sehingga setiap perubahan hasil build dapat segera dipublikasikan tanpa perlu melakukan proses penyalinan file.

Pendekatan ini sederhana, mudah dipahami, dan sesuai untuk proses development maupun pengujian lokal.

---

## 🔗 Related Documents

- [Build Website](build-website.md)
- Deploy to Object Storage
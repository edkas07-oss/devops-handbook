# PS-ADR-0012

| Property | Value |
|----------|-------|
| **ADR ID** | PS-ADR-0012 |
| **Title** | Store Static Content in Podman Named Volume |
| **Project** | Personal Site |
| **Section** | Continuous Deployment |
| **Status** | Accepted |
| **Date** | 2026-08-08 |

---

## 🔍 Overview

Project **Personal Site** memisahkan static content hasil build Hugo dari image runtime NGINX.

Pipeline CD menyimpan static content pada Podman named volume `www-personal-site`, kemudian memasang volume tersebut secara read-only ke `/var/www/html` pada container NGINX.

## 🌍 Context

Repository `nginx-image` menyediakan generic NGINX runtime. Konfigurasi saat ini menggunakan `/var/www/html` sebagai document root dan menyertakan placeholder `index.html` di dalam image.

Jika setiap perubahan website dimasukkan dengan membangun ulang image NGINX, lifecycle runtime dan lifecycle konten aplikasi menjadi saling terikat. Pendekatan tersebut juga menambahkan image build ke proses CD meskipun artefak Hugo sudah tersedia di MinIO.

## ⚖️ Decision

Static content tidak dimasukkan ke image NGINX pada setiap deployment.

Pipeline CD akan:

1. memastikan Podman named volume `www-personal-site` tersedia;
2. mengisi volume tersebut dengan konten dari direktori `public/` melalui ephemeral helper container;
3. menjalankan NGINX menggunakan generic image dari repository `nginx-image`;
4. memasang volume `www-personal-site` ke `/var/www/html` sebagai read-only; dan
5. mencatat identitas artefak aktif dan artefak sebelumnya untuk mendukung rollback.

## 🏛️ Architecture

```mermaid
flowchart LR
    Artifact["Hugo Artifact"] --> Populate["Ephemeral Helper Container"]
    Populate --> Release["Podman Named Volume<br/>www-personal-site"]
    Image["Generic NGINX Image"] --> Container["NGINX Container"]
    Release -->|Volume mount: /var/www/html:ro| Container
    Container --> Website["Personal Site"]
```

Image menyediakan NGINX dan konfigurasi web server. Podman volume `www-personal-site` menyediakan static content aplikasi. Keduanya digabungkan hanya pada saat container dijalankan.

## 💡 Rationale

- Memisahkan lifecycle runtime NGINX dan static content.
- Menghindari pembangunan ulang image untuk setiap versi website.
- Mempercepat deployment artefak baru.
- Memberikan nama volume runtime yang tetap dan mudah dikenali.
- Membatasi akses container terhadap konten melalui mount read-only.

## ⚠️ Consequences

### Positive

- Generic NGINX image dapat digunakan kembali.
- Deployment konten tidak memerlukan image build.
- Rollback dapat dilakukan dengan mengisi ulang volume dari artefak sebelumnya.
- Static content tidak dapat ditulis oleh container.

### Trade-offs

- Target runtime harus mengelola Podman volume `www-personal-site`.
- Script runtime harus mendukung Podman named volume pada `/var/www/html`.
- Pembaruan konten harus diatur agar NGINX tidak menyajikan kondisi volume yang sedang diisi sebagian.
- Proses pengisian volume membutuhkan ephemeral helper container.

## 🔗 Related Decisions

- **PS-ADR-0003 — Externalized Static Content Storage**
- **PS-ADR-0004 — Generic Runtime Container**
- **PS-ADR-0005 — Separate Source Code and Deployment Artifacts**
- **PS-ADR-0011 — Deploy Immutable CI Artifact**

## 📌 Status

**Accepted**

## 📅 Date

**2026-08-08**

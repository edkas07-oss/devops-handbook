# PS-ADR-0003

| Property | Value |
| -------- | ----- |
| **ADR ID** | PS-ADR-0003 |
| **Title** | Externalized Static Content Storage |
| **Project** | Personal Site |
| **Section** | Architecture |
| **Status** | Accepted |
| **Date** | 2026-07-21 |
| **Supersedes** | PS-ADR-0010 |

---

## 🔍 Overview

Project **Personal Site** menempatkan static content dan build artifact di luar runtime container sehingga media penyimpanan dapat dikelola secara independen dari image container maupun Jenkins Workspace.

Pendekatan ini memungkinkan runtime container tetap bersifat generic dan mempermudah perpindahan media penyimpanan tanpa memerlukan perubahan pada image maupun proses deployment.

---

## 🌍 Context

Static website yang dihasilkan oleh Hugo merupakan deployment artifact yang akan dipublikasikan menggunakan **nginx-image**.

Terdapat dua pendekatan umum untuk menyediakan static content kepada runtime container.

1. Menyimpan static content di dalam image container.
2. Menempatkan static content di luar image container dan mengaksesnya melalui media penyimpanan eksternal.

Pendekatan pertama menghasilkan image yang bergantung pada isi website. Setiap perubahan konten memerlukan proses build ulang image, pengujian, dan distribusi image baru.

Karena konten website diperkirakan akan berubah lebih sering dibandingkan runtime container, diperlukan pendekatan yang memisahkan media penyimpanan dari image container.

Build artifact juga harus tersedia secara independen setelah proses CI selesai agar Deployment Pipeline dapat menggunakan artifact yang sama tanpa melakukan build ulang. Penyimpanan hanya di Jenkins Workspace tidak memadai untuk retensi, rollback, dan penggunaan lintas pipeline.

---

## ⚖️ Decision

Static content ditempatkan di luar runtime container. Hasil build Hugo dipaketkan menjadi build artifact, dipublikasikan ke **Object Storage**, lalu digunakan oleh proses deployment sebagai sumber static content.

Pada implementasi project **Personal Site**, Object Storage menggunakan **MinIO** yang menyediakan API kompatibel dengan Amazon S3. Deployment mengambil artifact dari storage, mengekstraknya ke media penyimpanan deployment, lalu menyediakannya kepada runtime container melalui **Podman Volume**.

Build artifact tidak lagi bergantung pada Jenkins Workspace setelah berhasil dipublikasikan. Pendekatan ini mendukung prinsip **Build Once, Deploy Many** dan memungkinkan media penyimpanan deployment diganti tanpa mengubah runtime container.

---

## 🏛️ Architecture

```text
 Git Repository
       │
       ▼
 Build Pipeline
       │
       ▼
 Package public/ as artifact
       │
       ▼
 Object Storage (MinIO)
       │
       ▼
 Deployment Pipeline
       │
       ▼
 Deployment Storage / Podman Volume
       │
       ▼
 Generic Runtime Container
```

Build Pipeline memublikasikan artifact ke MinIO sebagai output resmi proses CI. Deployment Pipeline menggunakan artifact tersebut dan menyediakan static content kepada runtime container tanpa melakukan build ulang.

## 🧩 Artifact Lifecycle

| Stage | Description |
| ----- | ----------- |
| Build | Hugo menghasilkan static website pada direktori `public/`. |
| Package | Static content dikemas menjadi satu build artifact. |
| Publish | Build artifact dipublikasikan ke MinIO Object Storage. |
| Deploy | Deployment mengambil artifact tanpa melakukan build ulang. |
| Serve | Static content disediakan kepada runtime container melalui volume. |

---

## 💡 Rationale

Pendekatan ini dipilih karena memberikan beberapa keuntungan.

- Memisahkan media penyimpanan dari runtime container.
- Memisahkan Build Pipeline dari Deployment Pipeline.
- Membuat build artifact independen dari Jenkins Workspace.
- Mendukung prinsip **Build Once, Deploy Many**.
- Mempermudah rollback dan retensi artifact.
- Memungkinkan penggunaan berbagai jenis storage.
- Mengurangi kebutuhan rebuild image saat konten berubah.
- Mempermudah proses deployment.
- Mendukung penggunaan runtime container yang generic.
- Mempermudah migrasi media penyimpanan di masa mendatang.

---

## ⚠️ Consequences

### Positive

- Runtime container tetap independen terhadap media penyimpanan.
- Static content dapat diperbarui tanpa membangun ulang image.
- Deployment menjadi lebih fleksibel.
- Mendukung penggunaan Local Disk, NFS, maupun Object Storage.
- Build artifact tersimpan secara terpusat dan dapat digunakan kembali.
- Deployment tidak perlu melakukan build ulang source code.
- Konsisten dengan prinsip **Separation of Concerns**.

### Trade-offs

- Deployment memerlukan media penyimpanan yang tersedia saat runtime.
- Pengelolaan storage menjadi bagian dari proses deployment.
- Diperlukan mekanisme sinkronisasi static content ke media penyimpanan yang digunakan.
- Membutuhkan pengelolaan kapasitas, retensi, dan autentikasi Object Storage.

---

## 📌 Status

**Accepted**

---

## 📅 Date

2026-07-21 (updated 2026-08-08 after merging PS-ADR-0010)

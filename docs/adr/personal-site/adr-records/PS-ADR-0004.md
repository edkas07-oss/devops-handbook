# PS-ADR-0004

| Property | Value |
| -------- | ----- |
| **ADR ID** | PS-ADR-0004 |
| **Title** | Generic Runtime Container |
| **Project** | Personal Site |
| **Section** | Architecture |
| **Status** | Accepted |
| **Date** | 2026-07-21 |

---

## 🔍 Overview

Project **Personal Site** menggunakan runtime container yang bersifat **generic** untuk menyajikan static website.

Runtime container hanya bertanggung jawab menjalankan web server dan menyajikan static content. Seluruh konten website ditempatkan di luar image container sehingga image yang sama dapat digunakan kembali pada berbagai deployment.

---

## 🌍 Context

Terdapat dua pendekatan umum dalam melakukan deployment static website menggunakan container.

1. Menyalin seluruh static content ke dalam image pada saat proses build.
2. Menempatkan static content di luar image dan menyediakannya melalui media penyimpanan yang dapat diakses oleh container.

Pendekatan pertama menghasilkan image yang bergantung pada konten website. Setiap perubahan konten memerlukan proses build image baru, pengujian ulang, dan distribusi image ke registry.

Untuk project **Personal Site**, perubahan konten diperkirakan akan terjadi lebih sering dibandingkan perubahan runtime environment. Oleh karena itu diperlukan pendekatan yang memisahkan runtime container dari konten website.

---

## ⚖️ Decision

Project menggunakan **generic runtime container** yang hanya menyediakan runtime environment untuk menyajikan static website.

Static content tidak menjadi bagian dari image container, tetapi disediakan melalui **Podman Volume** yang dipasang (*mounted*) ke dalam container saat deployment.

Dengan pendekatan ini, image container dapat digunakan kembali tanpa perubahan meskipun konten website terus berkembang.

---

## 🏛️ Architecture

```text
           Static Website
              (public/)
                   │
                   ▼
            Podman Volume
                   │
                   ▼
             nginx-image
                   │
                   ▼
         Podman Container
                   │
                   ▼
             Web Browser
```

Runtime container hanya bertanggung jawab menyajikan static website.

Seluruh perubahan konten dilakukan di luar image container.

---

## 💡 Rationale

Pendekatan ini dipilih berdasarkan beberapa pertimbangan berikut.

- Runtime container dapat digunakan kembali pada berbagai project.
- Perubahan konten tidak memerlukan rebuild image.
- Deployment menjadi lebih sederhana.
- Image container lebih kecil dan stabil.
- Tanggung jawab runtime container dan static content dipisahkan dengan jelas.
- Mempermudah otomatisasi deployment.
- Mendukung penggunaan image container yang bersifat generic dan reusable.

---

## ⚠️ Consequences

### Positive

- Image container bersifat reusable.
- Deployment menjadi lebih cepat.
- Update static content tidak memerlukan build image baru.
- Maintenance runtime container menjadi lebih sederhana.
- Konsisten dengan prinsip **Separation of Concerns**.

### Trade-offs

- Deployment memerlukan media penyimpanan eksternal.
- Runtime container bergantung pada volume yang tersedia saat deployment.
- Manajemen storage menjadi bagian dari proses deployment.

---

## 📌 Status

**Accepted**

---

## 📅 Date

2026-07-21
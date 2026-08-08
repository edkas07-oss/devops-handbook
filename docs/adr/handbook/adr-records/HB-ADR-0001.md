# HB-ADR-0001

| Property | Value |
| -------- | ----- |
| **ADR ID** | HB-ADR-0001 |
| **Title** | Knowledge Organization Model |
| **Project** | DevOps Engineering Handbook |
| **Section** | Foundation |
| **Status** | Accepted |
| **Date** | 2026-07-20 |

---

## 🔍 Overview

DevOps Engineering Handbook dirancang sebagai platform dokumentasi yang tidak hanya berisi panduan penggunaan teknologi, tetapi juga dokumentasi implementasi berbagai project engineering.

Untuk menjaga dokumentasi tetap konsisten, mudah dipelihara, dan meminimalkan duplikasi pengetahuan, handbook ini mengadopsi **Knowledge Organization Model** yang memisahkan standar engineering, panduan penggunaan teknologi, keputusan arsitektur, serta implementasi project ke dalam domain yang memiliki tanggung jawab berbeda.

Model ini menerapkan prinsip utama:

> **Write Knowledge Once, Reuse Everywhere.**

---

## 🌍 Context

Pada tahap awal pengembangan handbook, dokumentasi tutorial dan dokumentasi project ditulis dalam satu struktur yang sama.

Pendekatan tersebut menyebabkan beberapa informasi mulai berulang. Langkah instalasi, konfigurasi, deployment, maupun penggunaan teknologi yang sama harus ditulis kembali pada setiap project yang menggunakannya.

Seiring bertambahnya jumlah teknologi dan project, pendekatan tersebut akan meningkatkan kompleksitas dokumentasi serta menyulitkan proses pemeliharaan karena setiap perubahan harus dilakukan pada banyak dokumen.

Oleh karena itu diperlukan model organisasi pengetahuan yang mampu:

- Mengurangi duplikasi dokumentasi.
- Memisahkan dokumentasi pembelajaran dari dokumentasi implementasi.
- Mendukung penggunaan kembali (*Knowledge Reuse*).
- Mempermudah pengembangan handbook dalam jangka panjang.
- Menjaga konsistensi struktur dokumentasi.

---

## ⚖️ Decision

DevOps Engineering Handbook mengadopsi **Knowledge Organization Model** yang memisahkan dokumentasi ke dalam dua domain utama.

- **Communication Platform**
- **Technical Knowledge Repository**

Kedua domain tersebut memiliki tujuan yang berbeda namun saling melengkapi.

### Communication Platform

**Personal Site** berfungsi sebagai media komunikasi yang ditujukan untuk publik.

Fokus utama Personal Site meliputi:

- About Me
- Technical Articles
- Curriculum Vitae (CV)

Platform ini digunakan untuk membangun personal branding, membagikan artikel teknis, serta memperkenalkan profil profesional.

---

### Technical Knowledge Repository

**DevOps Engineering Handbook** berfungsi sebagai repositori pengetahuan engineering yang digunakan untuk menyimpan seluruh dokumentasi teknis.

Knowledge Repository diorganisasikan ke dalam empat kategori utama.

| Category | Purpose |
| -------- | ------- |
| Standards | Mendefinisikan standar, prinsip, dan konvensi engineering. |
| How To | Menjelaskan penggunaan teknologi secara umum. |
| Architecture Decision Records | Mendokumentasikan keputusan arsitektur. |
| Projects | Mendokumentasikan implementasi nyata berdasarkan How To dan ADR. |

Setiap kategori memiliki tanggung jawab yang berbeda dan saling melengkapi.

---

## 🏛️ Architecture

Hubungan antar domain digambarkan sebagai berikut.

```text
Knowledge
│
├── Communication Platform
│   └── Personal Site
│
└── Technical Knowledge Repository
    └── DevOps Engineering Handbook
        ├── Standards
        ├── How To
        ├── Architecture Decision Records
        └── Projects
```

Hubungan antara **How To** dan **Projects** digambarkan sebagai berikut.

```text
                 DevOps Engineering Handbook
                              │
      ┌───────────────────────┴────────────────────────┐
      │                                                │
      ▼                                                ▼
  How To                                           Projects
      │                                                │
      ├── Hugo ───────────────────────────────┐         │
      ├── Git ───────────────────────────────┐│         │
      ├── Podman ──────────────────────────┐ ││         │
      ├── NGINX ─────────────────────────┐ │ ││         │
      └── ...                           │ │ ││         │
                                        ▼ ▼ ▼▼         ▼
                                   Personal Site
```

Project menggunakan satu atau lebih teknologi yang telah didokumentasikan pada bagian **How To**.

Dokumentasi project tidak mengulang pembahasan teknis yang telah tersedia pada **How To**, melainkan memberikan referensi menuju dokumentasi yang relevan.

Keputusan arsitektur yang memengaruhi implementasi project didokumentasikan secara terpisah pada **Architecture Decision Records (ADR)** sehingga alasan di balik setiap keputusan tetap terdokumentasi dengan baik.

---

## 💡 Rationale

Model ini dipilih berdasarkan pertimbangan berikut.

- Pengetahuan hanya ditulis satu kali (*Write Knowledge Once*).
- Dokumentasi lebih mudah dipelihara.
- Setiap project dapat menggunakan dokumentasi yang sama.
- Dokumentasi How To tetap bersifat umum (*generic*).
- Dokumentasi project tetap berfokus pada implementasi nyata.
- Architecture Decision Record mendokumentasikan alasan di balik setiap keputusan arsitektur.
- Hubungan antara Standards, How To, ADR, dan Projects menjadi lebih jelas.
- Struktur handbook dapat berkembang tanpa meningkatkan kompleksitas dokumentasi secara signifikan.

---

## ⚠️ Consequences

### Positive

- Mengurangi duplikasi dokumentasi.
- Mempermudah proses maintenance.
- Struktur handbook menjadi lebih konsisten.
- Pengetahuan dapat digunakan kembali pada berbagai project.
- Dokumentasi project menjadi lebih ringkas.
- Architecture Decision Record menjadi pusat dokumentasi keputusan arsitektur.
- Mempermudah penambahan teknologi maupun project baru.

### Trade-offs

- Pembaca mungkin perlu berpindah antara dokumentasi Project, How To, dan ADR.
- Setiap project harus memberikan referensi yang jelas terhadap dokumentasi terkait.
- Struktur handbook terdiri dari lebih banyak kategori, namun menjadi lebih terorganisasi dan mudah dikembangkan.

---

## 📌 Status

**Accepted**

Knowledge Organization Model menjadi fondasi utama dalam penyusunan seluruh dokumentasi pada DevOps Engineering Handbook.

Seluruh standar, How To, Architecture Decision Records, maupun dokumentasi project mengikuti model organisasi pengetahuan yang ditetapkan pada ADR ini.

---

## 📅 Date

2026-07-20
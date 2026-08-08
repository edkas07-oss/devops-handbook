# PS-ADR-0005

| Property | Value |
| -------- | ----- |
| **ADR ID** | PS-ADR-0005 |
| **Title** | Separate Source Code and Deployment Artifacts |
| **Project** | Personal Site |
| **Section** | Repository Structure |
| **Status** | Accepted |
| **Date** | 2026-07-21 |

---

## 🔍 Overview

Project **Personal Site** memisahkan source code dan deployment artifact ke dalam Git repository yang berbeda.

Pendekatan ini memungkinkan proses pengembangan, build, dan deployment dilakukan secara independen sehingga masing-masing repository memiliki tanggung jawab yang jelas.

---

## 🌍 Context

Static website yang dihasilkan oleh Hugo merupakan deployment artifact yang berbeda karakteristiknya dengan source code project.

Apabila source code dan deployment artifact disimpan pada repository yang sama, histori perubahan akan bercampur antara perubahan implementasi dan hasil proses build.

Selain itu, deployment artifact memiliki lifecycle yang berbeda dibandingkan source code sehingga pengelolaannya memerlukan pendekatan tersendiri.

Oleh karena itu diperlukan struktur repository yang mampu memisahkan kedua jenis artefak tersebut.

---

## ⚖️ Decision

Project menggunakan dua Git repository yang memiliki tanggung jawab berbeda.

- **personal-site** digunakan untuk menyimpan source code Hugo, konfigurasi, theme, serta seluruh konten website.
- **personal-site-site** digunakan untuk menyimpan deployment artifact berupa static website hasil proses build.

Repository deployment tidak digunakan untuk proses pengembangan source code.

---

## 🏛️ Architecture

```text
Git

├── personal-site
│
│   Hugo Source Code
│   Configuration
│   Content
│   Theme
│
└── personal-site-site

    Static Website
    (Deployment Artifact)
```

Repository **personal-site** menjadi sumber utama pengembangan project.

Repository **personal-site-site** hanya berisi static website yang siap dipublikasikan.

---

## 💡 Rationale

Pendekatan ini dipilih berdasarkan beberapa pertimbangan berikut.

- Source code dan deployment artifact memiliki lifecycle yang berbeda.
- Repository source tetap bersih dari hasil proses build.
- Deployment dapat dilakukan tanpa bergantung pada source code.
- Build dan deployment dapat diotomatisasi secara independen.
- Histori perubahan source code dan deployment artifact dipisahkan dengan jelas.
- Mendukung workflow CI/CD yang lebih sederhana.

---

## ⚠️ Consequences

### Positive

- Repository source lebih mudah dipelihara.
- Deployment artifact dikelola secara terpisah.
- Histori Git menjadi lebih bersih.
- Build dan deployment dapat berkembang secara independen.
- Mendukung otomatisasi deployment yang lebih fleksibel.

### Trade-offs

- Jumlah repository bertambah.
- Diperlukan mekanisme sinkronisasi deployment artifact ke repository deployment.
- Workflow release menjadi sedikit lebih kompleks dibandingkan menggunakan satu repository.

---

## 📌 Status

**Accepted**

---

## 📅 Date

2026-07-21
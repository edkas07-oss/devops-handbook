# ADR-0001 - Knowledge Organization Model for DevOps Engineering Handbook

> **Status:** Accepted  
> **Date:** 2026-07-20

---

## Overview

DevOps Engineering Handbook dirancang sebagai platform dokumentasi yang tidak hanya berisi tutorial penggunaan teknologi, tetapi juga implementasi nyata dari berbagai project engineering.

Untuk menjaga dokumentasi tetap konsisten, mudah dipelihara, dan meminimalkan duplikasi pengetahuan, handbook ini mengadopsi model organisasi pengetahuan yang memisahkan standar, panduan penggunaan teknologi, keputusan arsitektur, serta implementasi project.

---

## Context

Pada tahap awal pengembangan handbook, dokumentasi tutorial dan dokumentasi project ditulis dalam satu struktur yang sama.

Pendekatan tersebut menyebabkan beberapa informasi mulai berulang, misalnya langkah instalasi, konfigurasi, maupun deployment suatu teknologi ditulis kembali pada setiap project yang menggunakannya.

Seiring bertambahnya jumlah teknologi dan project, pendekatan tersebut akan menyulitkan proses pemeliharaan karena setiap perubahan harus dilakukan pada banyak dokumen.

Oleh karena itu diperlukan struktur dokumentasi yang mampu:

- Mengurangi duplikasi informasi.
- Memisahkan dokumentasi pembelajaran dengan dokumentasi implementasi.
- Mendukung penggunaan kembali (*knowledge reuse*).
- Memudahkan pengembangan handbook dalam jangka panjang.

---

## Decision

DevOps Engineering Handbook dibagi menjadi empat kelompok utama.

- **Standards**
- **How To**
- **Architecture Decision Records**
- **Projects**

Masing-masing kelompok memiliki tanggung jawab yang berbeda dan saling melengkapi.

---

## Architecture

```text
                     📖 DevOps Engineering Handbook
                                  │
     ┌──────────────┬─────────────┬──────────────┬──────────────┐
     │              │             │              │
     ▼              ▼             ▼              ▼
 📏 Standards   📘 How To      📑 ADRs       📁 Projects
```

Hubungan antara **How To** dan **Projects** digambarkan sebagai berikut.

```text
                    📖 DevOps Engineering Handbook
                                │
        ┌───────────────────────┴───────────────────────┐
        │                                               │
        ▼                                               ▼
    📘 How To                                      📁 Projects
        │                                               │
        ├── MkDocs ───────────────┐                     │
        ├── Hugo ───────────────┐ │                     │
        ├── Git ──────────────┐ │ │                     │
        ├── Podman ─────────┐ │ │ │                     │
        ├── NGINX ────────┐ │ │ │ │                     │
        └── ...           │ │ │ │ │                     │
                           ▼ ▼ ▼ ▼ ▼                     ▼
                  🌐 Personal Site          📚 DevOps Handbook
```

Setiap project dapat menggunakan satu atau lebih teknologi yang telah didokumentasikan pada bagian **How To**.

Project tidak mengulang penjelasan teknis yang telah tersedia pada How To, melainkan memberikan referensi ke dokumentasi yang relevan.

---

## Rationale

Model ini dipilih berdasarkan prinsip:

> **Write Knowledge Once, Reuse Everywhere.**

Dengan pendekatan tersebut:

- Pengetahuan hanya ditulis satu kali.
- Dokumentasi lebih mudah dipelihara.
- Setiap project dapat memanfaatkan dokumentasi yang sama.
- Tutorial tetap bersifat umum (*generic*).
- Dokumentasi project tetap fokus pada implementasi nyata.

---

## Consequences

### Positive

- Mengurangi duplikasi dokumentasi.
- Mempermudah proses maintenance.
- Struktur handbook menjadi lebih konsisten.
- Pengetahuan dapat digunakan kembali pada berbagai project.
- Project menjadi lebih ringkas dan mudah dipahami.

### Trade-offs

- Pembaca mungkin perlu berpindah antara dokumentasi Project dan How To.
- Setiap Project harus memberikan referensi yang jelas terhadap How To yang digunakan.
- Struktur handbook menjadi lebih banyak, namun lebih terorganisasi.

---

## Status

**Accepted**

Model organisasi pengetahuan ini menjadi standar utama dalam penyusunan seluruh dokumentasi pada DevOps Engineering Handbook.

---

## Date

2026-07-20
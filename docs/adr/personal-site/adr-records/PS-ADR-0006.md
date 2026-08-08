# PS-ADR-0006

| Property | Value |
|----------|-------|
| **ADR ID** | PS-ADR-0006 |
| **Title** | Use Personal Access Token for Gitea Repository |
| **Project** | Personal Site |
| **Section** | Security |
| **Status** | Accepted |
| **Date** | 2026-08-01 |

---

## 🔍 Overview

Project **Personal Site** menggunakan **Personal Access Token (PAT)** melalui HTTP/HTTPS sebagai metode autentikasi antara Jenkins dan repository Gitea.

Token disimpan di Jenkins Credentials dan diberi scope minimum yang diperlukan agar Build Pipeline dapat mengakses source code tanpa menyimpan password pengguna maupun credential di dalam repository.

---

## 🌍 Context

Build Pipeline memerlukan akses ke source code yang tersimpan pada repository Gitea.

Terdapat beberapa metode autentikasi yang dapat digunakan untuk menghubungkan Jenkins dengan Git Repository, antara lain:

- Username dan Password
- Personal Access Token (PAT)
- SSH Key Authentication

Setiap metode memiliki karakteristik yang berbeda dari sisi keamanan, kemudahan pemeliharaan, serta kesesuaian terhadap implementasi Enterprise DevOps.

Karena autentikasi ini menjadi fondasi Delivery Pipeline, diperlukan mekanisme yang aman, mudah dikelola pada lingkungan containerized, dan mendukung prinsip least privilege.

---

## ⚖️ Decision

Project **Personal Site** menggunakan **Personal Access Token (PAT)** melalui HTTP/HTTPS sebagai metode autentikasi antara Jenkins dan Gitea Repository.

Token dibuat pada Gitea dengan scope minimum untuk membaca repository dan disimpan menggunakan **Jenkins Credentials** dengan ID `gitea-access-token`.

Seluruh proses checkout source code menggunakan credential tersebut tanpa menyimpan token di dalam Jenkinsfile atau source code.

---

## 🏛️ Architecture

```text
            Jenkins
               │
               │
      Jenkins Credentials
      (Personal Access Token)
               │
               ▼
       HTTPS Authentication
               │
               ▼
      Gitea Repository
     (Scoped Access Token)
               │
               ▼
          Source Code
```

Jenkins mengirimkan Personal Access Token melalui HTTPS saat mengakses repository Gitea untuk proses checkout source code.

---

## 💡 Rationale

Keputusan menggunakan **Personal Access Token** diambil setelah mengevaluasi metode autentikasi yang tersedia pada Gitea.

### Authentication Comparison

| Method | Security | Maintenance | Enterprise | Recommendation |
|---------|----------|-------------|------------|----------------|
| Username & Password | Rendah; menggunakan credential utama pengguna | Mudah, tetapi berisiko digunakan ulang | Kurang sesuai untuk automation | ❌ Tidak disarankan |
| Personal Access Token (PAT) | Baik; scope dapat dibatasi | Mudah disimpan dan dirotasi melalui Jenkins Credentials | Cocok untuk HTTPS dan environment containerized | ✅ Dipilih |
| SSH Key | Sangat baik; tidak mengirim password | Memerlukan pengelolaan key dan `known_hosts` | Cocok untuk automation berbasis SSH | ⚠️ Alternatif |

Berdasarkan hasil evaluasi tersebut, Personal Access Token dipilih dengan pertimbangan berikut.

### 1. Mendukung Least Privilege

Token dapat dibuat dengan scope minimum yang hanya memberikan akses baca terhadap repository.

Build Pipeline tidak menggunakan password utama akun sehingga dampak kebocoran credential dapat dibatasi.

---

### 2. Mudah Dikelola oleh Jenkins

Token disimpan di Jenkins Credential Store dan direferensikan menggunakan credential ID.

Token tidak ditulis di source code maupun Jenkinsfile, dan rotasi dapat dilakukan tanpa mengubah definisi pipeline selama credential ID tetap sama.

---

### 3. Sesuai untuk Environment Containerized

HTTPS + PAT tidak memerlukan private key, SSH agent, atau pengelolaan `known_hosts` di dalam container dan Jenkins Agent. Hal ini mengurangi konfigurasi tambahan pada lingkungan build ephemeral.

---

### 4. Mendukung Rotasi dan Pencabutan Akses

Token dapat dicabut atau dibuat ulang melalui Gitea tanpa mengganti password pengguna. Rotasi dilakukan secara terencana dengan memperbarui nilai credential di Jenkins.

---

## ⚠️ Consequences

### Positive

- Tidak menggunakan password utama pengguna pada Build Pipeline.
- Scope akses dapat dibatasi berdasarkan kebutuhan pipeline.
- Credential dikelola secara terpusat melalui Jenkins.
- Mudah digunakan pada environment containerized dan ephemeral.
- Token dapat dicabut dan dirotasi tanpa mengubah Jenkinsfile.

### Trade-offs

- Token memiliki lifecycle dan perlu dirotasi secara berkala.
- Pipeline akan gagal mengakses repository jika token kedaluwarsa atau dicabut sebelum credential diperbarui.
- Token tetap harus diperlakukan sebagai secret dan tidak boleh ditulis ke log maupun source code.

---

## 📌 Status

**Accepted**

---

## 📅 Date

**2026-08-01**

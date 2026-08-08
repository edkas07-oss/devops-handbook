# PS-ADR-0001

| Property | Value |
| -------- | ----- |
| **ADR ID** | PS-ADR-0001 |
| **Title** | Use Jenkins as Automation Server |
| **Project** | Personal Site |
| **Section** | CI/CD |
| **Status** | Accepted |
| **Date** | 2026-08-06 |

---

## 🔍 Overview

Project **Personal Site** menggunakan **Jenkins sebagai automation server** untuk mengelola alur **Continuous Integration (CI)** dan orkestrasi **Build Pipeline**. Jenkins menyediakan platform yang stabil untuk menjalankan pipeline, melakukan integrasi dengan Gitea, dan mengelola artefak hasil build.

Keputusan ini memungkinkan Personal Site menggunakan:

- **Pipeline as Code** melalui Jenkinsfile.
- **Integrasi SCM** dengan Gitea.
- **Orkestrasi containerized build environment** menggunakan Podman.
- **Automasi ulang** proses build yang konsisten dan dapat direproduksi.

## 🌍 Context

Project memerlukan layanan orkestrasi yang dapat:

- Mengambil kode sumber dari repository Gitea.
- Menjalankan tahap build, paket, dan publikasi artefak.
- Mendukung definisi pipeline yang dapat dikomit sebagai kode.
- Menyediakan otentikasi dan manajemen akses untuk CI/CD.
- Terintegrasi dengan lingkungan build containerized.

Jenkins dipilih karena:

- Dukungan luas untuk pipeline deklaratif dan Scripted Pipeline.
- Ekosistem plugin yang kaya.
- Kemampuan untuk mengintegrasikan dengan SCM, S3-compatible storage, dan kontainer.
- Umur penggunaan yang cocok untuk otomatisasi CI/CD bertahap.

## ⚖️ Decision

Project **Personal Site** akan menggunakan **Jenkins** sebagai **Automation Server** utama.

Keputusan ini mencakup:

1. Menjalankan Jenkins sebagai service untuk orkestrasi pipeline.
2. Mengelola pipeline menggunakan Jenkinsfile yang disimpan di repository.
3. Mengintegrasikan Jenkins dengan Gitea untuk checkout source code.
4. Menjalankan tahapan build dalam container ephemeral menggunakan Podman.

## 🏛️ Consequences

- Jenkins menjadi pusat operasi CI/CD untuk project Personal Site.
- Konfigurasi pipeline bersifat kode dan dapat direview bersama source code.
- Jenkins perlu dikelola sebagai service dan dijaga konsistensinya.
- Dependensi pada ekosistem plugin Jenkins perlu dipantau.
- Artifact pipeline dapat dikirim ke MinIO dan sistem deployment lain.

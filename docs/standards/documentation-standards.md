# Documentation Standards

## 🔍 Overview

Documentation Standards mendefinisikan aturan umum yang digunakan dalam penyusunan seluruh dokumentasi pada DevOps Engineering Handbook.

Standar ini bertujuan menjaga konsistensi struktur, penamaan, organisasi, serta hubungan antar dokumentasi sehingga seluruh project memiliki format yang seragam, mudah dipelihara, dan mudah dipahami.

## 🎯 Objectives

Documentation Standards memiliki beberapa tujuan utama.

- Menjaga konsistensi struktur dokumentasi.
- Mempermudah navigasi handbook.
- Menentukan aturan penamaan file dan folder.
- Menstandarkan hubungan antar dokumentasi.
- Menjadi pedoman sebelum membuat dokumentasi baru.

## 📂 Documentation Structure

Seluruh dokumentasi mengikuti struktur berikut.

```text
docs/
│
├── foundation/
├── standards/
├── container-projects/
├── web-platform-projects/
├── automation-projects/
├── openshift-projects/
├── architecture-decision-records/
└── troubleshooting/
```

Setiap kategori berisi dokumentasi yang memiliki ruang lingkup yang sama.

## 📁 Project Documentation Structure

Setiap project menggunakan struktur dokumentasi yang konsisten.

Struktur berikut digunakan sebagai referensi.

```text
Personal Site
│
├── Overview
├── Objectives
├── Requirements
├── Architecture
├── Repository Structure
├── Technology Stack
├── Implementation
├── Deployment
├── Backup and Recovery
├── Lessons Learned
└── References
```

Struktur dapat disesuaikan apabila diperlukan, namun urutan pembahasan harus tetap logis dan konsisten.

## 📄 Document Templates

Setiap jenis dokumentasi memiliki template standar.

| Documentation | Standard Structure |
| ------------- | ------------------ |
| **How To** | Overview → Prerequisites → Implementation → Verification → Troubleshooting → Best Practices → References → Summary |
| **Project** | Overview → Objectives → Requirements → Architecture → Repository Structure → Technology Stack → Implementation → Deployment → Backup and Recovery → Lessons Learned → References |
| **Engineering Journal** | Project Journal Index → Phase Index → Technical Notes |
| **Architecture Decision Record (ADR)** | Overview → Context → Decision → Architecture → Rationale → Consequences → Status → Date |

Struktur, penomoran, lifecycle, dan template Technical Note dijelaskan pada
[Engineering Journal Standards](engineering-journal-standards.md).

## 📝 File Naming Convention

Gunakan huruf kecil dan tanda minus (`-`) sebagai pemisah kata.

Contoh nama file.

```text
repository-structure.md
technology-stack.md
backup-and-recovery.md
```

Hindari penggunaan format berikut.

```text
RepositoryStructure.md
repository_structure.md
```

## 📁 Directory Naming Convention

Gunakan nama folder yang secara jelas menjelaskan kategori dokumentasi.

Contoh struktur direktori.

```text
container-projects
web-platform-projects
automation-projects
architecture-decision-records
```

Hindari penggunaan singkatan yang tidak umum.

## 🏛️ ADR Numbering Convention

Nomor Architecture Decision Record (ADR) mengikuti urutan kemunculan keputusan arsitektur pada dokumentasi project, bukan berdasarkan urutan waktu keputusan dibuat atau didokumentasikan.

Sebagai contoh.

```text
Personal Site

Overview
Objectives
Requirements

Architecture
├── PS-ADR-0003
└── PS-ADR-0004

Repository Structure

Technology Stack
└── PS-ADR-0005

Implementation
Deployment
Backup and Recovery
Lessons Learned
References
```

Pendekatan ini menjaga hubungan antara dokumentasi project dan Architecture Decision Record sehingga pembaca dapat mengikuti keputusan arsitektur sesuai dengan urutan pembahasan.

Nomor ADR yang telah diterbitkan tidak diubah, meskipun kemudian ditemukan keputusan arsitektur baru.

Apabila terdapat keputusan baru, gunakan nomor ADR berikutnya.

## 🔗 Architecture Decision References

Apabila suatu implementasi merupakan hasil dari keputusan arsitektur, dokumentasi project dapat memberikan referensi menuju Architecture Decision Record (ADR).

Referensi tersebut bertujuan memberikan ringkasan keputusan yang diterapkan pada implementasi tanpa menduplikasi isi ADR.

## 🎨 Documentation Icons

Untuk menjaga konsistensi visual di seluruh DevOps Engineering Handbook, gunakan ikon berikut pada heading dokumentasi.

| Section | Icon | Description |
| -------- | ---- | ----------- |
| Welcome | 👋 | Halaman pembuka suatu bagian dokumentasi. |
| Overview | 🔍 | Gambaran umum topik, project, atau teknologi. |
| Background | 🌍 | Kondisi awal dan alasan suatu aktivitas dilakukan. |
| Why | ❓ | Alasan atau latar belakang suatu bagian dibuat. |
| Objectives | 🎯 | Tujuan yang ingin dicapai. |
| Scope | 📚 | Ruang lingkup pembahasan. |
| Requirements | 📋 | Persyaratan implementasi. |
| Target Audience | 👥 | Sasaran pembaca dokumentasi. |
| Architecture | 🏛️ | Arsitektur atau desain sistem. |
| High-Level Architecture | 🗺️ | Gambaran arsitektur tingkat tinggi. |
| Architecture Components | 🧩 | Komponen utama beserta tanggung jawabnya. |
| Build Flow | 🔨 | Alur proses build. |
| Deployment Flow | 🚀 | Alur deployment. |
| Storage Architecture | 💾 | Arsitektur penyimpanan. |
| Design Principles | 🧭 | Prinsip desain yang diterapkan. |
| How to Use This Journal | 🧭 | Panduan membaca dan menggunakan Engineering Journal. |
| Engineering Phases | 🛠️ | Fase atau workstream dalam Engineering Journal. |
| Document Types | 📄 | Jenis dokumen dan tanggung jawabnya. |
| Technical Notes | 📄 | Daftar aktivitas engineering dalam suatu fase. |
| Implementation Result | 🛠️ | Hasil implementasi yang telah dicapai. |
| Repository Structure | 📁 | Struktur repository project. |
| Repository Organization | 🗂️ | Organisasi repository. |
| Repository Responsibilities | 📌 | Tanggung jawab masing-masing repository. |
| Repository Workflow | 🔄 | Workflow pengelolaan repository. |
| Technology Stack | 🧰 | Teknologi yang digunakan. |
| Implementation | ⚙️ | Langkah implementasi. |
| Deployment | 🚀 | Deployment ke environment target. |
| Backup and Recovery | 💾 | Backup dan pemulihan. |
| Verification | ✅ | Verifikasi hasil implementasi. |
| Operator Validation | ✅ | Instruksi pemeriksaan dan acceptance oleh operator atau project owner. |
| Troubleshooting | 🛠️ | Pemecahan masalah umum. |
| Best Practices | ⭐ | Rekomendasi implementasi. |
| Release History | 📦 | Riwayat perubahan atau rilis. |
| Lessons Learned | 🎓 | Pengalaman dan pembelajaran. |
| Related Documentation | 🔗 | Dokumentasi yang berkaitan. |
| References | 📖 | Referensi internal maupun eksternal. |
| Summary | 📝 | Ringkasan isi dokumen. |
| Next Step | ⏭️ | Langkah berikutnya yang disarankan. |
| Recommended Reading Order | 🧭 | Urutan membaca dokumentasi. |
| Context | 🌍 | Latar belakang keputusan arsitektur (ADR). |
| Decision | ⚖️ | Keputusan arsitektur yang dipilih. |
| Execution Decision | ⚖️ | Keputusan yang diterapkan pada suatu aktivitas dan referensi ADR-nya. |
| Rationale | 💡 | Alasan pemilihan keputusan. |
| Consequences | ⚠️ | Dampak atau konsekuensi keputusan. |
| Status | 📌 | Status Architecture Decision Record (ADR). |
| Date | 📅 | Tanggal keputusan dibuat atau disetujui. |
| ADR Identifier Convention | 🆔 | Aturan penamaan Architecture Decision Record. |
| Project Identifier | 📁 | Namespace yang digunakan oleh setiap project. |
| ADR Lifecycle | 🔄 | Siklus pengambilan keputusan arsitektur. |
| ADR Template | 📋 | Struktur standar Architecture Decision Record. |
| ADR Status | 📌 | Status yang digunakan pada Architecture Decision Record. |
| Appendix | 📎 | Informasi tambahan. |
| Review Checklist | 📋 | Daftar pemeriksaan sebelum dokumentasi diterbitkan. |

Gunakan ikon secara konsisten pada heading dokumentasi untuk membantu pembaca mengenali jenis informasi dengan cepat serta menjaga konsistensi visual di seluruh handbook.

### 📄 Template

!!!! note "Related Architecture Decision"

    #### Reference

    Implementasi pada bagian ini mengacu pada **{{ ADR-ID }} – {{ ADR Title }}**.

    #### Decision Summary

    {{ Decision Summary }}

    #### Further Reading

    Untuk pembahasan mengenai alternatif yang dipertimbangkan, alasan pemilihan solusi, serta konsekuensi dari keputusan ini, lihat **{{ ADR-ID }}**.

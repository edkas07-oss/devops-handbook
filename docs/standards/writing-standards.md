# Writing Standards

## 🔍 Overview

Writing Standards mendefinisikan gaya penulisan yang digunakan pada seluruh dokumentasi di DevOps Engineering Handbook.

Standar ini bertujuan menjaga konsistensi bahasa, struktur heading, penggunaan ikon, tabel, diagram, admonition, code block, serta elemen visual lainnya sehingga dokumentasi memiliki tampilan yang seragam dan mudah dipahami.

---

## 🎯 Objectives

Writing Standards bertujuan untuk:

- Menjaga konsistensi gaya penulisan dokumentasi.
- Meningkatkan keterbacaan dokumentasi.
- Menstandarkan penggunaan elemen visual.
- Mempermudah proses review dokumentasi.
- Memberikan pengalaman membaca yang konsisten.

---

## ✍️ Writing Style

Gunakan bahasa yang jelas, ringkas, dan mudah dipahami.

Gunakan kalimat aktif apabila memungkinkan.

Hindari penggunaan istilah yang ambigu atau tidak konsisten.

Gunakan istilah teknis yang umum digunakan dalam industri.

---

## 📝 Headings

Gunakan struktur heading secara berurutan.

```text
#
##
###
####
```

Jangan melompati level heading.

Contoh:

```markdown
# Architecture

## 🔍 Overview

### Build Process
```

Gunakan heading yang singkat namun mampu menjelaskan isi pembahasan.

Gunakan ikon hanya pada heading level dua (`##`) sesuai standar yang telah ditetapkan.

---

## 🎨 Icons

Ikon digunakan untuk membantu pembaca mengenali jenis informasi serta menjaga konsistensi visual di seluruh DevOps Engineering Handbook.

### Navigation

Ikon hanya digunakan pada **section utama** di sidebar.

Contoh:

- 🏠 Home
- 📏 Standards
- 🛠️ How To
- 🏛️ Architecture Decision Records
- 🚨 Troubleshooting

Ikon **tidak digunakan** pada sub navigasi seperti:

- Project
- Kategori
- Dokumen
- Architecture Decision Record (ADR)

Contoh:

```text
🏛️ Architecture Decision Records

Getting Started

Handbook

Personal Site

Ubuntu Base

Ubuntu SSH

NGINX Image
```

### Document Headings

Gunakan ikon pada heading level dua (`##`) sesuai dengan jenis informasi yang disajikan.

| Heading | Icon |
| -------- | ---- |
| Welcome | 👋 |
| Overview | 🔍 |
| Why | ❓ |
| Objectives | 🎯 |
| Scope | 📚 |
| Requirements | 📋 |
| Target Audience | 👥 |
| Architecture | 🏛️ |
| High-Level Architecture | 🗺️ |
| Architecture Components | 🧩 |
| Build Flow | 🔨 |
| Deployment Flow | 🚀 |
| Storage Architecture | 💾 |
| Design Principles | 🧭 |
| Repository Structure | 📁 |
| Repository Organization | 🗂️ |
| Repository Responsibilities | 📌 |
| Repository Workflow | 🔄 |
| Technology Stack | 🧰 |
| Implementation | ⚙️ |
| Deployment | 🚀 |
| Backup and Recovery | 💾 |
| Verification | ✅ |
| Troubleshooting | 🛠️ |
| Best Practices | ⭐ |
| Release History | 📦 |
| Lessons Learned | 🎓 |
| Related Documentation | 🔗 |
| References | 📖 |
| Summary | 📝 |
| Next Step | ⏭️ |
| Recommended Reading Order | 🧭 |
| Documentation Structure | 📂 |
| Project Documentation Structure | 📁 |
| Document Templates | 📄 |
| File Naming Convention | 🏷️ |
| Directory Naming Convention | 📁 |
| ADR Numbering Convention | 🔢 |
| Architecture Decision References | 🏛️ |
| Visual Style | 🎨 |
| Context | 🌍 |
| Decision | ⚖️ |
| Rationale | 💡 |
| Consequences | ⚠️ |
| Status | 📌 |
| Date | 📅 |
| ADR Identifier Convention | 🆔 |
| Project Identifier | 📁 |
| ADR Lifecycle | 🔄 |
| ADR Template | 📋 |
| ADR Status | 📌 |
| Appendix | 📎 |

Gunakan ikon secara konsisten.

Hindari penggunaan ikon yang berbeda untuk heading dengan makna yang sama.

---

## 📊 Tables

Gunakan tabel untuk menyajikan informasi yang bersifat terstruktur.

Contoh:

| Component | Description |
| --------- | ----------- |
| Hugo | Static Site Generator |
| Git | Version Control |

Gunakan alignment bawaan Markdown.

---

## 🗺️ Diagrams

Gunakan diagram text apabila sudah cukup menjelaskan hubungan antar komponen.

Contoh:

```text
Developer
     │
     ▼
Git
     │
     ▼
Jenkins
     │
     ▼
NGINX
```

Gunakan diagram gambar apabila diagram text tidak lagi memadai.

---

## 📢 Admonitions

Gunakan admonition untuk memberikan informasi penting.

Jenis admonition yang direkomendasikan:

- note
- info
- warning
- tip

Contoh:

````markdown
!!! note "Related Architecture Decision"

    #### Reference

    Implementasi pada bagian ini mengacu pada **PS-ADR-0003**.
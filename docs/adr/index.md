# Introduction

## ❓ What is an Architecture Decision Record?

Architecture Decision Record (ADR) adalah dokumen yang digunakan untuk mencatat keputusan arsitektur penting yang diambil selama proses perancangan dan pengembangan suatu sistem.

Selain mencatat keputusan yang diambil, ADR juga menjelaskan latar belakang, alasan pemilihan solusi, serta konsekuensi dari keputusan tersebut. Dengan demikian, setiap keputusan dapat dipahami kembali di masa mendatang tanpa harus bergantung pada ingatan atau diskusi sebelumnya.

## 🎯 Why Use ADR?

Selama proses pengembangan, berbagai keputusan arsitektur akan terus muncul. Sebagian keputusan mungkin terlihat sederhana saat dibuat, namun alasan di balik keputusan tersebut sering kali terlupakan seiring berjalannya waktu.

Dengan menggunakan ADR, setiap keputusan penting dapat didokumentasikan sehingga lebih mudah dipahami, dievaluasi, maupun dikembangkan di kemudian hari.

Beberapa manfaat penggunaan ADR antara lain:

- Mendokumentasikan alasan di balik setiap keputusan arsitektur.
- Mengurangi ketergantungan pada diskusi atau pengetahuan individual.
- Mempermudah proses maintenance dan pengembangan sistem.
- Menjadi referensi ketika melakukan perubahan arsitektur.
- Membantu anggota tim baru memahami desain sistem.

## 📚 ADR in DevOps Engineering Handbook

Pada DevOps Engineering Handbook, ADR digunakan untuk mendokumentasikan keputusan arsitektur yang memengaruhi desain handbook maupun implementasi setiap project.

Keputusan yang berlaku untuk seluruh handbook disimpan sebagai **Handbook ADR**, sedangkan keputusan yang hanya berlaku untuk project tertentu didokumentasikan sebagai **Project ADR**.

Pendekatan ini memungkinkan setiap project berkembang secara independen tanpa mengganggu dokumentasi project lainnya.

## 🆔 ADR Identifier Convention

Setiap Architecture Decision Record (ADR) menggunakan identifier yang terdiri dari **Project Identifier**, **ADR**, dan **Nomor Urut**.

Format umum yang digunakan adalah:

```text
<Project Identifier>-ADR-<Sequence Number>
```

Contoh:

```text
HB-ADR-0001
PS-ADR-0003
UB-ADR-0001
```

Nomor ADR bersifat unik di dalam masing-masing project dan **tidak digunakan kembali**, meskipun suatu ADR telah digantikan (*Superseded*) atau tidak lagi digunakan (*Deprecated*).

## 📁 Project Identifier

Setiap project memiliki **Project Identifier** yang digunakan sebagai namespace untuk Architecture Decision Record.

| Identifier | Project | Description |
| ---------- | ------- | ----------- |
| **HB** | DevOps Engineering Handbook | Technical Knowledge Repository yang berisi standards, How To, ADR, dan dokumentasi project. |
| **PS** | Personal Site | Website publik untuk personal branding, technical articles, dan Curriculum Vitae (CV). |
| **UB** | Ubuntu Base | Base container image yang menjadi fondasi image lainnya. |
| **US** | Ubuntu SSH | Container image yang menyediakan layanan OpenSSH Server. |
| **NI** | NGINX Image | Generic runtime container untuk menyajikan static website. |
| **LA** | Linux Automation | Project automation untuk monitoring dan operational workflow pada sistem Linux. |

Contoh penggunaan identifier:

```text
HB-ADR-0001
PS-ADR-0003
UB-ADR-0001
US-ADR-0001
NI-ADR-0001
LA-ADR-0001
```

!!! note "ADR Scope"

    Prefix ADR ditentukan berdasarkan **ruang lingkup keputusan**, bukan berdasarkan lokasi dokumen.

    - **HB-ADR** digunakan untuk keputusan yang berlaku pada seluruh DevOps Engineering Handbook.
    - **Project ADR** digunakan untuk keputusan yang hanya berlaku pada project tertentu, seperti **PS-ADR**, **UB-ADR**, **US-ADR**, **NI-ADR**, atau **LA-ADR**.

    Sebagai contoh:

    - **HB-ADR-0001** mendokumentasikan keputusan **Knowledge Organization Model** yang berlaku untuk seluruh DevOps Engineering Handbook.
    - **PS-ADR-0003** mendokumentasikan keputusan yang hanya berlaku pada project Personal Site.

## 🔄 ADR Lifecycle

Setiap keputusan arsitektur mengikuti siklus sederhana berikut.

```text
Identify Problem
        │
        ▼
Evaluate Options
        │
        ▼
Make Decision
        │
        ▼
Document as ADR
        │
        ▼
Implement
        │
        ▼
Review if Needed
```

ADR bukan merupakan dokumen yang bersifat statis. Apabila terdapat perubahan kebutuhan atau pendekatan yang lebih baik, keputusan dapat diperbarui melalui ADR baru sehingga histori keputusan tetap terjaga.

## 📋 ADR Template

Seluruh ADR pada handbook ini menggunakan struktur yang konsisten.

```text
Overview
│
├── Context
├── Decision
├── Architecture
├── Rationale
├── Consequences
├── Status
└── Date
```

| Section | Description |
| ------- | ----------- |
| Overview | Ringkasan keputusan yang diambil. |
| Context | Latar belakang dan permasalahan yang dihadapi. |
| Decision | Keputusan yang dipilih. |
| Architecture | Diagram atau ilustrasi yang menjelaskan keputusan arsitektur. |
| Rationale | Alasan pemilihan keputusan tersebut. |
| Consequences | Dampak atau konsekuensi dari keputusan. |
| Status | Status keputusan, misalnya Proposed, Accepted, Superseded, atau Deprecated. |
| Date | Tanggal keputusan dibuat atau disetujui. |

## 📌 ADR Status

Status digunakan untuk menunjukkan kondisi suatu keputusan.

| Status | Description |
| ------ | ----------- |
| Proposed | Keputusan masih dalam tahap pembahasan. |
| Accepted | Keputusan telah disetujui dan digunakan. |
| Superseded | Keputusan telah digantikan oleh ADR yang lebih baru. |
| Deprecated | Keputusan tidak lagi direkomendasikan untuk digunakan. |

## 📖 References

Dokumentasi resmi.

- [Architecture Decision Records](https://adr.github.io/){: target="_blank" rel="noopener noreferrer" }
- [Documenting Architecture Decisions - Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions){: target="_blank" rel="noopener noreferrer" }

## 📝 Summary

Pada bab ini telah dijelaskan:

- Pengertian Architecture Decision Record (ADR).
- Tujuan penggunaan ADR.
- Peran ADR dalam DevOps Engineering Handbook.
- Konvensi penamaan ADR.
- Project Identifier yang digunakan sebagai namespace ADR.
- Aturan penentuan scope ADR.
- Siklus pengambilan keputusan arsitektur.
- Template standar yang digunakan pada seluruh ADR.
- Status yang digunakan dalam lifecycle ADR.
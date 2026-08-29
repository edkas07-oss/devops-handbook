# Engineering Principles

## 🔍 Overview

Engineering Principles mendefinisikan prinsip-prinsip yang menjadi dasar penyusunan seluruh dokumentasi pada DevOps Engineering Handbook.

Prinsip-prinsip ini membantu menjaga konsistensi dokumentasi, meningkatkan keterbacaan, serta memberikan pengalaman belajar yang lebih baik bagi pembaca.

Seluruh dokumentasi, baik berupa How-To, Project Documentation, Architecture Decision Record (ADR), maupun Troubleshooting, mengacu pada prinsip-prinsip yang dijelaskan dalam dokumen ini.

---

## 🎯 Objectives

Engineering Principles bertujuan untuk:

- Menjaga konsistensi dokumentasi.
- Meningkatkan kualitas penyajian informasi.
- Mempermudah proses pemeliharaan dokumentasi.
- Memberikan pengalaman belajar yang lebih baik.
- Menjadi pedoman sebelum membuat dokumentasi baru.

---

## 📚 Scope

Dokumen ini membahas prinsip-prinsip umum yang digunakan dalam penyusunan dokumentasi, meliputi:

- Menulis untuk pembaca.
- Mengutamakan implementasi sebelum teori.
- Menggunakan komunikasi visual secara tepat.
- Menghindari duplikasi dokumentasi.
- Menjaga konsistensi penyajian informasi.

---

## 📖 Engineering Principles

Setiap dokumen akan menerapkan prinsip yang sudah kita tetapkan.

### 👥 Write for Readers

Dokumentasi ditulis untuk membantu pembaca memahami suatu topik atau menyelesaikan suatu pekerjaan.

Gunakan bahasa yang sederhana, jelas, dan mudah dipahami. Selalu pertimbangkan kebutuhan pembaca dibandingkan preferensi penulis.

---

### ⚙️ Practical Before Theory

Prioritaskan langkah implementasi sebelum menjelaskan teori.

Apabila penjelasan teori diperlukan, jelaskan secara ringkas dan tetap relevan dengan topik yang sedang dibahas.

Dokumentasi sebaiknya memberikan hasil yang dapat langsung dipraktikkan oleh pembaca.

---

### 🧱 Single Source of Truth

Setiap informasi sebaiknya memiliki satu sumber dokumentasi utama.

Apabila suatu topik telah dijelaskan pada dokumen lain, gunakan hyperlink menuju dokumentasi tersebut daripada menduplikasi isi dokumentasi.

Pendekatan ini menjaga konsistensi serta mempermudah proses pemeliharaan dokumentasi.

---

### 📐 Be Consistent

Gunakan struktur dokumen, heading, ikon, istilah, dan gaya penulisan yang konsisten di seluruh handbook.

Konsistensi membantu pembaca memahami dokumentasi dengan lebih cepat dan mempermudah proses review maupun pemeliharaan.

Jika dokumentasi memiliki rencana dan catatan pelaksanaan, gunakan nama,
istilah, serta urutan tahap yang sama agar pembaca dapat memetakan rencana ke
hasil aktual secara langsung. Perbedaan antara rencana dan pelaksanaan tidak
boleh disamarkan dengan mengganti nama tahap; catat perbedaannya sebagai
perubahan scope atau penyimpangan dari rencana (`deviation`).

---

## 💬 Communication Principles

Selain mengikuti prinsip engineering, setiap dokumentasi juga harus memperhatikan cara penyampaian informasi. Tujuannya adalah agar dokumentasi mudah dipahami, mudah dinavigasi, dan memberikan pengalaman membaca yang konsisten.

### 👀 Use Visual Communication

Pilih media penyampaian informasi yang paling efektif sesuai dengan jenis informasi yang disampaikan.

Sebagai contoh:

- Gunakan bullet list untuk daftar informasi.
- Gunakan numbered list untuk langkah implementasi.
- Gunakan tabel untuk data yang terstruktur.
- Gunakan code block untuk command dan konfigurasi.
- Gunakan Mermaid untuk menjelaskan workflow atau hubungan antar komponen.
- Gunakan gambar apabila media lain tidak lagi memadai.

---

### 📖 Keep Information Scannable

Dokumentasi sebaiknya mudah dipindai (*scannable*) sehingga pembaca dapat menemukan informasi yang dibutuhkan dengan cepat.

Untuk meningkatkan keterbacaan:

- Gunakan heading yang jelas.
- Gunakan paragraf yang singkat.
- Gunakan bullet list untuk daftar informasi.
- Pisahkan topik yang berbeda menggunakan sub-heading.
- Hindari paragraf yang terlalu panjang.

---

### 📝 Prefer Native Markdown

Gunakan elemen Markdown bawaan apabila sudah mampu menyajikan informasi dengan baik.

Prioritaskan penggunaan:

- Heading
- Bullet list
- Numbered list
- Table
- Code block
- Hyperlink

Gunakan HTML atau Custom CSS hanya apabila benar-benar diperlukan.

Pendekatan ini menjaga dokumentasi tetap sederhana, mudah dipelihara, dan kompatibel dengan berbagai Markdown renderer.

---

### 🧠 Minimize Cognitive Load

Susun dokumentasi agar pembaca dapat memahami informasi dengan usaha seminimal mungkin.

Untuk mencapai tujuan tersebut:

- Jelaskan satu konsep dalam satu bagian.
- Hindari informasi yang tidak relevan.
- Gunakan istilah yang konsisten.
- Hindari pengulangan informasi.
- Susun informasi dari konsep sederhana menuju konsep yang lebih kompleks.

---

## 🛠️ Implementation Guidelines

Prinsip-prinsip engineering perlu diterapkan secara konsisten dalam penyusunan dokumentasi. Panduan berikut memberikan rekomendasi penggunaan elemen-elemen dokumentasi yang umum digunakan pada DevOps Engineering Handbook.

Gunakan elemen dokumentasi sesuai dengan jenis informasi yang ingin disampaikan.

| Element | Digunakan untuk |
| -------- | ---------------- |
| Bullet List | Menyajikan daftar informasi yang tidak bergantung pada urutan. |
| Numbered List | Menjelaskan langkah implementasi yang harus dilakukan secara berurutan. |
| Table | Menyajikan informasi yang memiliki hubungan antar kolom atau data yang terstruktur. |
| Code Block | Menampilkan command, konfigurasi, source code, terminal output, atau struktur direktori. |
| Mermaid | Menggambarkan workflow, relationship, architecture, atau diagram lainnya. |
| Admonition | Menyoroti informasi penting, rekomendasi, atau peringatan. |
| Hyperlink | Menghubungkan dokumentasi yang saling berkaitan dan mendukung prinsip **Single Source of Truth**. |
| Image | Menampilkan antarmuka aplikasi, hasil implementasi, atau visualisasi yang tidak dapat dijelaskan secara efektif menggunakan elemen Markdown lainnya. |

---

### 📢 Admonitions

Gunakan admonition untuk menyoroti informasi yang memerlukan perhatian khusus dari pembaca.

Jenis admonition yang direkomendasikan:

- `note` untuk informasi tambahan.
- `info` untuk penjelasan penting.
- `tip` untuk rekomendasi implementasi.
- `warning` untuk risiko atau potensi kesalahan.
- `success` untuk menunjukkan hasil implementasi yang berhasil.

Gunakan admonition secara seperlunya agar tidak mengurangi fokus pembaca.

---

### 📋 Bullet Lists

Gunakan bullet list untuk menyajikan informasi yang tidak bergantung pada urutan.

Bullet list membantu pembaca melakukan scanning isi dokumentasi dengan lebih cepat dibandingkan paragraf yang panjang.

Contoh penggunaan:

- Requirements
- Feature List
- Best Practices
- References

---

### 🔢 Numbered Lists

Gunakan numbered list apabila langkah-langkah harus dilakukan secara berurutan.

Contoh penggunaan:

1. Install package.
2. Konfigurasi aplikasi.
3. Verifikasi hasil implementasi.

---

### 📊 Tables

Gunakan tabel untuk menyajikan informasi yang memiliki hubungan antar kolom.

Contoh penggunaan:

- Perbandingan fitur.
- Parameter konfigurasi.
- Compatibility Matrix.
- Mapping komponen.

Hindari menggunakan tabel untuk menjelaskan prosedur implementasi.

---

### 💻 Code Blocks

Gunakan code block untuk menyajikan:

- Command.
- Source code.
- Configuration.
- Terminal output.
- Struktur direktori.

Selalu gunakan syntax highlighting yang sesuai agar dokumentasi lebih mudah dibaca.

---

### 🗺️ Mermaid Diagrams

Gunakan Mermaid untuk menjelaskan hubungan antar komponen atau workflow yang sulit dipahami hanya menggunakan teks.

Mermaid direkomendasikan untuk:

- Flowchart
- Sequence Diagram
- Git Graph
- Architecture Diagram
- State Diagram

Gunakan diagram yang sederhana dan mudah dipahami.

---

### 🖼️ Images

Gunakan gambar apabila informasi tidak dapat dijelaskan secara efektif menggunakan teks, tabel, atau diagram Mermaid.

Contoh penggunaan:

- Screenshot antarmuka aplikasi.
- Hasil implementasi.
- Diagram arsitektur yang kompleks.

Hindari penggunaan screenshot apabila informasi dapat dijelaskan menggunakan elemen Markdown lainnya.

---

### 🔗 Hyperlinks

Gunakan hyperlink untuk menghubungkan dokumentasi yang saling berkaitan.

Hyperlink merupakan implementasi dari prinsip **Single Source of Truth**, sehingga informasi yang telah dijelaskan pada dokumen lain tidak perlu diduplikasi.

Gunakan:

- Hyperlink relatif untuk dokumentasi internal.
- Hyperlink absolut untuk referensi eksternal.

Pastikan hyperlink selalu mengarah ke dokumentasi yang relevan dan masih dipelihara.

!!! tip "Engineering Guideline"

    Pilih elemen dokumentasi yang paling sederhana namun tetap mampu menyampaikan informasi secara efektif. Hindari penggunaan elemen visual secara berlebihan apabila teks atau tabel sudah cukup menjelaskan informasi.

---

## ⭐ Best Practices

Dalam menyusun dokumentasi:

- Tulis untuk membantu pembaca, bukan untuk menunjukkan kemampuan teknis.
- Prioritaskan implementasi sebelum teori.
- Sajikan informasi menggunakan format yang paling mudah dipahami.
- Gunakan elemen Markdown bawaan apabila memungkinkan.
- Gunakan heading, istilah, dan struktur yang konsisten.
- Hindari duplikasi dokumentasi.
- Hubungkan dokumentasi yang saling berkaitan menggunakan hyperlink.
- Review dokumentasi secara berkala agar tetap relevan.

---

## 📖 References

- Documentation Standards
- Project Standards
- Writing Standards
- Workflow Standards

---

## 📝 Summary

Engineering Principles menjadi fondasi penyusunan seluruh dokumentasi pada DevOps Engineering Handbook.

Dengan mengikuti prinsip-prinsip ini, setiap dokumentasi akan memiliki struktur yang konsisten, mudah dipahami, mudah dipelihara, serta memberikan pengalaman belajar yang lebih baik bagi seluruh pembaca.

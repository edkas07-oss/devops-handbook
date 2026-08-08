# Installation

## Pendahuluan

Pada bagian ini kita akan melakukan instalasi seluruh komponen yang diperlukan untuk membangun website dokumentasi menggunakan MkDocs.

Panduan ini menggunakan sistem operasi Linux. Contoh pada dokumentasi ini menggunakan **Rocky Linux 9**, namun langkah-langkahnya dapat dengan mudah disesuaikan untuk distribusi Linux lainnya seperti RHEL, AlmaLinux, Ubuntu, Debian, maupun Fedora.

---

## Arsitektur

MkDocs merupakan aplikasi berbasis Python yang akan membaca file Markdown (`.md`) kemudian mengubahnya menjadi website statis (Static Site).

```text
                +----------------------+
                |  Markdown Files      |
                | (*.md)               |
                +----------+-----------+
                           |
                           |
                    mkdocs build
                           |
                           v
                +----------------------+
                |   Static Website     |
                |      HTML/CSS/JS     |
                +----------+-----------+
                           |
                           |
                    Web Browser
```

Seluruh konfigurasi website disimpan pada file `mkdocs.yml`, sedangkan seluruh halaman dokumentasi berada di dalam direktori `docs/`.

---

## Prasyarat

Pastikan sistem telah memenuhi beberapa kebutuhan berikut.

| Komponen | Keterangan |
|----------|------------|
| Operating System | Linux |
| Python | Versi 3.9 atau lebih baru |
| pip | Python Package Manager |
| Internet | Untuk mengunduh package |
| Terminal | Bash atau shell lainnya |
| Text Editor | Visual Studio Code (Direkomendasikan) |

---

- Verifikasi Python

Pastikan Python telah terpasang.

```bash
python3 --version
```

Contoh output:

```text
Python 3.12.3
```

Selanjutnya pastikan `pip` juga tersedia.

```bash
pip3 --version
```

Contoh output:

```text
pip 24.0
```
Apabila kedua perintah di atas berhasil dijalankan, maka sistem telah siap untuk menginstal MkDocs. Jika belum jalankan perintah berikut ini.

```bash
sudo apt update
sudo apt install python3-pip -y
```

!!! note "Engineering Notes"
    
    Sebelum menginstal package lainnya dan pip sudah terpasang, disarankan memperbarui `pip`.

    ```bash
    pip install --upgrade pip
    ```
    Verifikasi versinya.

    ```bash
    pip --version
    ```
    
- Membuat Python Virtual Environment

Sangat disarankan menggunakan **Python Virtual Environment (venv)** agar package MkDocs hanya digunakan oleh project ini dan tidak mengganggu package Python sistem.

Buat direktori project.

```bash
mkdir mkdocs-project
cd mkdocs-project
```

Buat virtual environment.

```bash
python3 -m venv .venv
```

Aktifkan virtual environment.

```bash
source .venv/bin/activate
```

Apabila berhasil, prompt terminal akan berubah menjadi seperti berikut.

```text
(.venv) user@server:~/mkdocs-project$
```

> **Catatan**
>
> Seluruh proses instalasi berikutnya dilakukan di dalam virtual environment.

---

## Instalasi MkDocs

Instal MkDocs menggunakan `pip`.

```bash
pip install mkdocs
```

Verifikasi instalasi.

```bash
mkdocs --version
```

Contoh output.

```text
mkdocs, version 1.6.x
```

---

# Instalasi Material for MkDocs

Material for MkDocs merupakan theme yang paling populer karena menyediakan tampilan modern, fitur navigasi yang lengkap, serta mendukung berbagai ekstensi Markdown.

Instal menggunakan perintah berikut.

```bash
pip install mkdocs-material
```

Verifikasi instalasi.

```bash
pip show mkdocs-material
```

---

# Instalasi Plugin Tambahan (Opsional)

Selain MkDocs dan Material Theme, beberapa plugin berikut sangat direkomendasikan.

## pymdown-extensions

Plugin ini menyediakan berbagai fitur Markdown tambahan seperti:

- Mermaid Diagram
- Task List
- Emoji
- Highlight
- SuperFences
- Tab
- Keyboard Keys

Instalasi:

```bash
pip install pymdown-extensions
```

---

## Git Revision Date Plugin

Plugin ini digunakan untuk menampilkan tanggal terakhir perubahan halaman berdasarkan riwayat Git.

```bash
pip install mkdocs-git-revision-date-localized-plugin
```

---

## Minify Plugin

Plugin ini akan memperkecil ukuran file HTML hasil proses build sehingga website menjadi lebih ringan.

```bash
pip install mkdocs-minify-plugin
```

---

# Verifikasi Package

Pastikan seluruh package telah berhasil terinstal.

```bash
pip list
```

Minimal akan terlihat package seperti berikut.

```text
mkdocs
mkdocs-material
Markdown
Pygments
PyYAML
pymdown-extensions
```

---

# Struktur Environment

Setelah seluruh proses instalasi selesai, struktur project sementara akan menjadi seperti berikut.

```text
mkdocs-project/
└── .venv/
```

Pada tahap ini project MkDocs belum dibuat. Kita baru menyiapkan environment Python yang akan digunakan.

---

# Ringkasan

Pada bab ini kita telah mempelajari:

- Verifikasi Python dan pip.
- Membuat Python Virtual Environment.
- Upgrade pip.
- Instalasi MkDocs.
- Instalasi Material for MkDocs.
- Instalasi plugin pendukung.
- Verifikasi package yang telah diinstal.

Environment sekarang telah siap digunakan untuk membuat project MkDocs.

---

# Langkah Selanjutnya

Pada bab berikutnya kita akan membuat project MkDocs pertama menggunakan perintah `mkdocs new`, kemudian mempelajari struktur folder serta fungsi setiap file yang dihasilkan.
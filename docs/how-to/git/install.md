# Install Git

## 🚀 Get Started

Panduan ini menjelaskan cara menginstal Git pada sistem operasi yang didukung.

Setelah Git berhasil diinstal, Anda dapat mulai mengelola source code, melakukan version control, dan berkolaborasi menggunakan Git repository.

---

## 🎯 Learning Objectives

Setelah mengikuti panduan ini, Anda diharapkan mampu:

- Menginstal Git.
- Memverifikasi instalasi Git.
- Memastikan Git siap digunakan.

---

## 🔄 Workflow

```mermaid
flowchart LR

    A["📥 Install Git"]
        --> B["✅ Verify Installation"]

    B --> C["🚀 Git Ready"]
```

---

## 📋 Prerequisites

Pastikan:

- Memiliki hak akses untuk menginstal software.
- Terhubung ke Internet (apabila menggunakan package repository).

---

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Install Git

=== "Ubuntu / Debian"

    Perbarui package repository.

    ```bash
    sudo apt update
    ```

    Instal Git.

    ```bash
    sudo apt install git -y
    ```

=== "RHEL / Rocky Linux"

    Instal Git.

    ```bash
    sudo dnf install git -y
    ```

=== "Fedora"

    Instal Git.

    ```bash
    sudo dnf install git -y
    ```

=== "Windows"

    Unduh installer Git dari website resmi.

    https://git-scm.com/downloads

    Jalankan installer kemudian ikuti wizard instalasi hingga selesai.

</div>

<div class="procedure-step" markdown>

### Verify Installation

Periksa versi Git.

```bash
git --version
```

Contoh output.

```text
git version 2.50.1
```

Pastikan Git dapat dijalankan tanpa error.

---


</div>

</div>

## ✅ Verification

Pastikan:

- Git berhasil diinstal.
- Perintah `git --version` menampilkan versi Git.
- Git dapat dijalankan dari terminal.

!!! success "Verification"

    Git berhasil diinstal dan siap digunakan.

---

## 💡 Technology Notes

Git merupakan Distributed Version Control System (DVCS) yang berjalan secara lokal pada komputer pengguna.

Setelah Git berhasil diinstal, lakukan konfigurasi awal seperti username dan email sebelum mulai membuat repository atau melakukan commit.

---

## ▶️ Next Steps

Setelah Git berhasil diinstal, tahap berikutnya adalah **Configure Git** untuk melakukan konfigurasi awal.

---

## 🔗 Related Documents

| Document | Description |
|----------|-------------|
| **Overview** | Pengenalan Git. |
| **Configure Git** | Melakukan konfigurasi awal Git. |

---

## 📝 Summary

Pada halaman ini telah dijelaskan:

- Cara menginstal Git.
- Cara memverifikasi instalasi.
- Persyaratan sebelum menggunakan Git.

Selanjutnya Anda akan mempelajari cara **mengonfigurasi Git** sebelum mulai mengelola source code.
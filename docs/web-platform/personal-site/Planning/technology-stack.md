# 🧰 Technology Stack

## 🔍 Overview

Halaman ini menjelaskan **teknologi** yang dipilih untuk memenuhi kebutuhan **Personal Site**.

Setiap teknologi dipilih berdasarkan perannya dalam proses **Development**, **Build**, dan **Deployment**, serta kemudahan implementasi, pemeliharaan, dan penerapan praktik **DevOps**.

---

## 📌 Technology at a Glance

Project **Personal Site** menggunakan teknologi berikut.

| Category | Technology |
|----------|------------|
| 📝 Static Site Generator | **Hugo (Extended)** |
| 🌿 Version Control | **Git** |
| 💻 Development Tool | **Visual Studio Code** |
| 📦 Container Runtime | **Podman** |
| 🌐 Web Server | **NGINX Image** |

!!! info "Technology Selection"

    Seluruh teknologi dipilih berdasarkan kebutuhan yang telah didefinisikan pada halaman **Requirements**, dengan mempertimbangkan performa, keamanan, maintainability, dan kemudahan implementasi.

---

## 🧩 Technology Mapping

| Technology | Category | Purpose |
|------------|----------|---------|
| **Hugo (Extended)** | Static Site Generator | Build static website |
| **Git** | Version Control | Manage source code |
| **Visual Studio Code** | Development Tool | Develop project |
| **Podman** | Container Runtime | Build and run containers |
| **NGINX Image** | Web Server | Serve static website |

---

## 📖 Technology Selection

### 📝 Hugo (Extended)

**Category:** Static Site Generator

**Reason for Selection**

- **High Performance** – Memiliki waktu *build* yang sangat cepat sehingga meningkatkan produktivitas pengembangan.
- **Static Website** – Menghasilkan website statis tanpa memerlukan *application server* pada lingkungan produksi.
- **Extended Features** – Mendukung pemrosesan SCSS/Sass secara *native* sehingga tidak memerlukan *build pipeline* tambahan.
- **DevOps Friendly** – Mudah diintegrasikan dengan proses *Container Build* maupun *CI/CD Pipeline*.

---

### 🌿 Git

**Category:** Version Control

**Reason for Selection**

- Mengelola histori perubahan *source code* dan dokumentasi secara terstruktur.
- Mendukung *traceability* serta proses *rollback* apabila terjadi kesalahan.
- Menjadi standar industri untuk **Version Control System (VCS)**.
- Mudah diintegrasikan dengan platform Git Hosting maupun proses otomatisasi seperti **GitOps** dan **CI/CD**.

---

### 💻 Visual Studio Code

**Category:** Development Tool

**Reason for Selection**

- Editor yang ringan dan tersedia pada berbagai sistem operasi.
- Mendukung Markdown, Git, serta berbagai bahasa pemrograman melalui *extension*.
- Memiliki ekosistem *extension* yang lengkap untuk meningkatkan produktivitas pengembangan.
- Menyediakan terminal terintegrasi untuk mendukung aktivitas pengembangan dan pengujian.

---

### 📦 Podman

**Category:** Container Runtime

**Reason for Selection**

- **Rootless Container** – Mendukung keamanan yang lebih baik melalui eksekusi tanpa hak akses *root*.
- **Daemonless Architecture** – Tidak memerlukan *daemon* sehingga lebih ringan dan sederhana.
- **OCI Compliant** – Sepenuhnya kompatibel dengan standar **Open Container Initiative (OCI)**.
- **Developer Friendly** – Mendukung workflow container modern dan mudah diintegrasikan dengan proses otomatisasi.

---

### 🌐 NGINX Image

**Category:** Web Server

**Reason for Selection**

- **Lightweight** – Menghasilkan container image yang ringan dan efisien.
- **High Performance** – Dioptimalkan untuk menyajikan static website dengan performa tinggi.
- **Easy Configuration** – Mendukung konfigurasi *caching*, *compression*, *security headers*, dan *routing* secara sederhana.
- **Container Ready** – Sangat sesuai untuk deployment menggunakan container runtime.

---

## 🔗 Related Documentation

Dokumen berikut berkaitan dengan halaman ini.

| Documentation | Description |
|---------------|-------------|
| **Requirements** | Menjelaskan kebutuhan yang menjadi dasar pemilihan teknologi. |
| **Architecture** | Mendeskripsikan bagaimana teknologi tersebut diintegrasikan menjadi sebuah solusi. |

### 🛠️ How-To Guides

Panduan instalasi dan penggunaan masing-masing teknologi tersedia pada bagian **How-To**.

| Technology | Documentation |
|------------|---------------|
| Hugo | How-To → Hugo |
| Git | How-To → Git |
| Podman | How-To → Podman |
| NGINX | How-To → NGINX |

---

## 📝 Summary

Pada halaman ini telah dijelaskan:

- Technology Stack yang digunakan pada project.
- Peran masing-masing teknologi dalam proses **Development**, **Build**, dan **Deployment**.
- Alasan pemilihan setiap teknologi.
- Hubungan antara kebutuhan project dan teknologi yang dipilih.

Selanjutnya akan dibahas bagaimana teknologi tersebut diintegrasikan ke dalam **Architecture** sebagai solusi untuk memenuhi kebutuhan project.
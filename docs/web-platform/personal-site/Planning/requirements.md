# 📋 Requirements

## 🔍 Overview

Halaman ini mendefinisikan **kebutuhan** yang harus dipenuhi untuk membangun **Personal Site**.

Dokumen ini menjadi acuan dalam pemilihan teknologi, perancangan arsitektur, dan implementasi solusi.

---

## 📌 Requirements at a Glance

Kebutuhan project dikelompokkan ke dalam beberapa kategori berikut.

| Category | Purpose |
|----------|---------|
| 📌 **Functional** | Menjelaskan fitur dan kemampuan yang harus disediakan oleh website. |
| ⚙️ **Non-Functional** | Mendefinisikan karakteristik kualitas sistem seperti performa, maintainability, dan runtime. |
| 🧰 **Software** | Menentukan perangkat lunak yang diperlukan untuk pengembangan dan deployment. |
| 🖥️ **Hardware** | Menentukan spesifikasi minimum lingkungan pengembangan. |
| 💻 **Development** | Menjelaskan komponen yang diperlukan untuk membangun project secara lokal. |
| 🚀 **Runtime** | Menjelaskan komponen yang digunakan untuk mempublikasikan website. |
| 🌐 **Network** | Menjelaskan kebutuhan jaringan agar website dapat diakses pengguna. |

!!! info "Requirement Classification"

    Seluruh requirement pada halaman ini menjadi dasar dalam pemilihan teknologi (**Technology Stack**), perancangan arsitektur (**Architecture**), serta implementasi (**Implementation**) project.

---

## 📌 Functional Requirements

Website harus memenuhi kebutuhan fungsional berikut.

| ID | Requirement | Description |
|----|-------------|-------------|
| FR-001 | Personal Profile | Website harus menyediakan halaman **About Me** yang menampilkan profil profesional. |
| FR-002 | Article Publishing | Website harus menyediakan halaman **Articles** untuk mempublikasikan artikel teknis berbasis Markdown. |
| FR-003 | Curriculum Vitae | Website harus menyediakan halaman **Curriculum Vitae (CV)** yang dapat diakses dan diunduh oleh pengunjung. |
| FR-004 | Site Navigation | Website harus menyediakan navigasi yang konsisten dan mudah digunakan. |
| FR-005 | Content Extensibility | Website harus memungkinkan penambahan konten baru tanpa mengubah struktur maupun layout website. |

---

## ⚙️ Non-Functional Requirements

Website juga harus memenuhi kebutuhan non-fungsional berikut.

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-001 | Performance | Website harus memiliki performa yang baik. Target implementasi menggunakan Google Lighthouse minimal **90** untuk kategori *Performance*, *SEO*, dan *Accessibility*. |
| NFR-002 | Maintainability | Website harus mudah dipelihara dan dikembangkan melalui konfigurasi berbasis file (*Configuration as Code*). |
| NFR-003 | Version Control | Seluruh source code dan histori perubahan harus dikelola menggunakan Git. |
| NFR-004 | Container Ready | Website harus dapat dipublikasikan menggunakan container runtime. |
| NFR-005 | Stateless Runtime | Runtime hanya bertugas menyajikan static website tanpa melakukan proses build maupun menyimpan source code. |

---

## 🧰 Software Requirements

Perangkat lunak berikut diperlukan untuk mendukung proses pengembangan dan deployment project.

| Software | Minimum Version | Purpose |
|----------|-----------------|---------|
| Linux | Rocky Linux 9 / Ubuntu 24.04 LTS | Development Environment |
| Git | 2.x | Version Control |
| Hugo (Extended) | Latest Stable | Static Site Generator |
| Visual Studio Code | Latest Stable | Development Tool |
| Podman | 5.x | Container Runtime |
| NGINX Image | Latest Stable | Web Server |

---

## 🖥️ Hardware Requirements

Spesifikasi perangkat keras minimum untuk proses pengembangan.

| Component | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 Core | 4 Core |
| Memory | 4 GB | 8 GB |
| Storage | 20 GB | 50 GB SSD |
| Network | Internet Connection | Broadband |

---

## 💻 Development Requirements

Lingkungan pengembangan minimal harus menyediakan komponen berikut.

| Component | Purpose |
|-----------|---------|
| Linux Workstation | Lingkungan utama pengembangan. |
| Git | Mengelola source code dan histori perubahan. |
| Visual Studio Code | Editor untuk pengembangan project. |
| Hugo (Extended) | Membangun static website secara lokal. |
| Podman atau Docker | Menjalankan dan menguji container image. |

---

## 🚀 Runtime Requirements

Runtime bertugas mempublikasikan **static website** kepada pengguna.

Runtime hanya berfungsi sebagai lingkungan eksekusi (*runtime environment*). Seluruh proses *build*, pengelolaan source code, dan pengembangan dilakukan pada lingkungan **Development**.

| Component | Description |
|-----------|-------------|
| Container Runtime | Menjalankan container website (misalnya Podman atau Docker). |
| NGINX Image | Menyajikan static website kepada pengguna. |
| Static Website | Hasil proses build Hugo (`public/`) yang dipublikasikan oleh web server. |

!!! tip "Runtime Responsibility"

    Runtime hanya bertanggung jawab menjalankan website yang telah dibangun. Runtime **tidak melakukan proses build**, **tidak menyimpan source code**, dan **tidak digunakan sebagai lingkungan pengembangan**.

---

## 🌐 Network Requirements

Website harus dapat diakses melalui jaringan menggunakan protokol standar HTTP maupun HTTPS.

| Component | Description |
|-----------|-------------|
| HTTP (TCP/80) | Menyediakan akses HTTP. |
| HTTPS (TCP/443) | Menyediakan akses HTTPS menggunakan sertifikat SSL/TLS. |
| DNS (Optional) | Memetakan nama domain ke server deployment. |
| Reverse Proxy (Optional) | Digunakan apabila website dipublikasikan di belakang reverse proxy. |

Konfigurasi jaringan dapat disesuaikan dengan kebutuhan lingkungan deployment.

---

## 🔗 Related Documentation

Dokumen berikut berkaitan dengan halaman ini.

| Documentation | Description |
|---------------|-------------|
| **Technology Stack** | Menjelaskan teknologi yang dipilih untuk memenuhi kebutuhan project. |
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

- Functional Requirements
- Non-Functional Requirements
- Software Requirements
- Hardware Requirements
- Development Requirements
- Runtime Requirements
- Network Requirements

Selanjutnya akan dibahas teknologi yang dipilih untuk memenuhi kebutuhan tersebut pada halaman **Technology Stack**.
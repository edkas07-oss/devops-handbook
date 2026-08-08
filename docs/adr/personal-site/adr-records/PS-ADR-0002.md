# PS-ADR-0002

| Property | Value |
| -------- | ----- |
| **ADR ID** | PS-ADR-0002 |
| **Title** | Containerized Ephemeral Build Environment (DooD with Rootless Podman) |
| **Project** | Personal Site |
| **Section** | Infrastructure & CI/CD Pipeline |
| **Status** | Accepted |
| **Date** | 2026-08-01 |

---

## 🔍 Overview

Project **Personal Site** mengadopsi pendekatan **Containerized Ephemeral Build Environment** menggunakan Rootless Podman pada CI/CD Pipeline. 

Seluruh proses kompilasi kode (Hugo) dan eksekusi instruksi build tidak dijalankan secara langsung di OS host Jenkins Agent, melainkan di dalam *ephemeral container* (container sementara) yang lahir dan mati sesuai dengan siklus hidup perintah build (*Podman-outside-of-Podman*).

---

## 🌍 Context

Untuk menyediakan lingkungan kompilasi dan pembuatan artefak pada CI Engine (Jenkins Agent), dilakukan riset dan evaluasi terhadap 3 (tiga) pendekatan arsitektur:

### Option 1: Host-Based Tooling (Native Execution)
Seluruh SDK, CLI, dan binary (`hugo`, `mc`, `node`, dll.) diinstal secara langsung di dalam OS Host / lingkungan runtime Jenkins Agent.

- **Kelebihan:**
  - Waktu eksekusi sangat cepat karena tidak ada *overhead* pembuatan container.
  - Konfigurasi sederhana tanpa perlu manajemen izin volume/socket container.
- **Kekurangan:**
  - **Host Pollution:** OS Agent dipenuhi oleh sisa-sisa dependensi dan binary kompilasi.
  - **Dependency Drift & Version Lock:** Sangat sulit mengelola beberapa project yang membutuhkan versi compiler/tooling yang berbeda pada satu Agent.
  - **Maintenance Overhead:** Pembaruan versi Hugo membutuhkan akses manual dan repositori paket di OS Host Agent.

### Option 2: DinD / Nested Containerization (Docker-in-Docker / Podman-in-Podman)
Container Jenkins Agent menjalankan daemon Container terpisah di dalam dirinya sendiri, sehingga container Hugo lahir benar-benar di dalam (*nested*) container Jenkins Agent.

- **Kelebihan:**
  - Isolasi total di tingkat filesystem container utama.
  - Jenkins Agent sepenuhnya mandiri tanpa bergantung pada socket daemon host.
- **Kekurangan:**
  - **Security Risk High:** Membutuhkan mode `--privileged` yang memberikan akses root berbahaya ke OS Host.
  - **Performance & Storage Overhead:** Menjalankan daemon di dalam daemon memakan konsumsi memori/CPU lebih besar serta masalah pada *storage driver* bertingkat (OverlayFS on OverlayFS).

### Option 3: Ephemeral DooD (Docker/Podman-outside-of-Docker/Podman)
Jenkins Agent bertindak sebagai orchestrator yang memicu perintah `podman run --rm` ke daemon Podman host. Container build lahir di tingkat yang **sejajar (*sibling*)** dengan Agent dan bersifat **ephemeral (sementara)**.

- **Kelebihan:**
  - **Stateless & Hermetic Build:** Setiap build menggunakan container bersih yang langsung dihapus (`--rm`) setelah tugas selesai, mencegah polusi workspace.
  - **Zero Host Pollution:** Tidak ada binary `hugo` yang perlu diinstal di OS Host Agent.
  - **Secure (Rootless):** Dapat dijalankan tanpa mode `--privileged` dengan memanfaatkan Rootless Podman dan opsi `--userns=keep-id`.
  - **Fleksibel:** Versi tooling diatur secara deklaratif di `Jenkinsfile` melalui tag image (contoh: `klakegg/hugo:ext-alpine`).
- **Kekurangan:**
  - Membutuhkan penanganan khusus untuk izin volume mounting (`-v "$WORKSPACE:/src:Z"`) dan SELinux/User Namespace mapping.
  - Membutuhkan waktu *initial pull* image saat pertama kali dijalankan.

---

## ⚖️ Decision

Keputusan ini menetapkan bahwa build pipeline tidak dijalankan langsung di host Jenkins Agent. Sebagai gantinya, Jenkins SSH Agent akan memicu Podman di host untuk membuat container sementara yang menjalankan proses build.

Prinsipnya:

- Build dilakukan melalui `podman run --rm` di host menggunakan Rootless Podman.
- Setiap build menggunakan image container spesifik seperti `klakegg/hugo:ext-alpine` dan `quay.io/minio/mc:latest` untuk isolasi dependensi.
- Workspace di-mount ke dalam container dengan `-v "$WORKSPACE:/src:Z"` dan `--userns=keep-id` agar hak akses file tetap sesuai dengan user non-root host.
- Container bersifat ephemeral: dibuat saat diperlukan dan dihapus otomatis setelah build selesai.

Dengan cara ini, lingkungan build menjadi lebih konsisten, bebas dari polusi host, dan mudah direproduksi.

---

## 🏛️ Architecture

```text
               Jenkins Controller
                       │
                       │ (SSH Task Execution)
                       ▼
         Jenkins SSH Agent (builder-01)
             (Host User: eddywiyatno)
                       │
                       │ (Podman Socket / CLI)
                       ▼
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────┐              ┌──────────────┐
│  Hugo Image  │              │  MinIO MC    │
│ (Ephemeral)  │              │  (Ephemeral) │
└──────┬───────┘              └──────┬───────┘
       │                             │
       │ (Mount Workspace)           │ (Upload Artifact)
       ▼                             ▼
Agent Workspace               MinIO Object
 ($WORKSPACE)                    Storage
```

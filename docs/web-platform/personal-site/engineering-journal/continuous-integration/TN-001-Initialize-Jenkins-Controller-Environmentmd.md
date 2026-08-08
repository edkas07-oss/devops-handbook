# TN-001 — Initialize Jenkins Controller & Environment

## Objective

Menjalankan container Jenkins, memverifikasi lingkungan Jenkins, dan menginstal plugin yang diperlukan untuk mendukung Build Pipeline.

## Background

Jenkins dijalankan sebagai container Podman. Sebelum pipeline dibuat, lingkungan Jenkins harus siap dengan startup container, verifikasi service, dan instalasi plugin yang diperlukan.

## Prerequisites

N/A

## Engineering Decision

Refer to:

- **PS-ADR-0001 — Use Jenkins as Automation Server**

> Architecture Decision Record (ADR) ini menjadi referensi utama (Single Source of Truth) untuk keputusan penggunaan Jenkins sebagai Automation Server pada Project Personal Site.

## Implementation

### 1. Start Jenkins Container

Jalankan kembali container Jenkins jika sudah tersedia.

```bash
podman ps -a
podman start jenkins
podman ps
podman logs --tail 20 jenkins
```

### 2. Verify Jenkins Environment

1. Akses Jenkins melalui web browser.
2. Login menggunakan akun administrator.
3. Pastikan Dashboard Jenkins dapat ditampilkan tanpa error.
4. Buka menu **Manage Jenkins**.
5. Verifikasi informasi instalasi Jenkins.
6. Pastikan tidak terdapat peringatan atau konfigurasi yang bermasalah.
7. Verifikasi direktori `JENKINS_HOME`.
8. Pastikan Jenkins siap digunakan untuk membuat Pipeline.

### 3. Install Required Plugins

1. Login ke Jenkins menggunakan akun administrator.
2. Buka menu **Manage Jenkins → Plugins**.
3. Instal plugin berikut:
    - Git
    - Pipeline
    - GitHub Branch Source
    - Credentials
    - SSH Agent
4. Restart Jenkins apabila diminta.
5. Setelah restart, jalankan kembali container jika status berubah menjadi **Exited**:

```bash
podman start jenkins
```

1. Login kembali ke Jenkins.
2. Verifikasi seluruh plugin berhasil diinstal dan aktif.

## Verification

- Container Jenkins berhasil dijalankan.
- Jenkins Web UI dapat diakses.
- Login administrator berhasil.
- Dashboard tampil normal tanpa error.
- `JENKINS_HOME` terinisialisasi.
- Plugin Git, Pipeline, GitHub Branch Source, Credentials, dan SSH Agent berhasil diinstal.
- Jenkins dapat diakses kembali setelah restart.

## Notes

Technical Note ini menggabungkan startup Jenkins, verifikasi environment, dan instalasi plugin dalam satu catatan ringkas.

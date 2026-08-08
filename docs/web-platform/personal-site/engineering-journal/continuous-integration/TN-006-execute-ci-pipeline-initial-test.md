# TN-006 — Execute CI Pipeline Initial Test

## Objective

Melakukan eksekusi awal pipeline Jenkins untuk memvalidasi konfigurasi job, akses repository, agen build, dan definisi `Jenkinsfile`.

## Background

Setelah pipeline dibuat dan Jenkinsfile tersedia, eksekusi awal memastikan seluruh alur CI berjalan end-to-end. Pengujian ini membantu mendeteksi isu SCM, agen, build container, atau konfigurasi artefak sejak dini.

## Prerequisites

- TN-001 hingga TN-007 telah berhasil diselesaikan.
- Jenkins Pipeline item sudah dibuat dan terhubung ke repository.
- Credential SCM dan MinIO sudah tersedia di Jenkins.

## Engineering Decision

Refer to:

- **PS-ADR-0007 — Use Pipeline as Code**

> Architecture Decision Record (ADR) ini menjadi referensi utama (Single Source of Truth) untuk mengeksekusi dan memvalidasi definisi pipeline yang dikelola melalui Jenkinsfile pada source repository.

## Implementation

### 1. Jalankan build pertama

1. Buka item pipeline Jenkins (`personal-site-ci` atau nama setara).
2. Klik **Build Now**.
3. Pantau **Console Output**.

### 2. Verifikasi tahapan pipeline

Periksa bahwa pipeline berhasil melewati semua stage berikut:

- **Checkout** — SCM berhasil di-download dari Gitea.
- **Verify Agent** — agen build tersedia dan dapat menjalankan perintah shell.
- **Build Static Site** — Hugo berhasil membangun situs ke folder `public`.
- **Package Artifact** — artefak `.tar.gz` dihasilkan.
- **Publish Artifact** — artefak dikirim ke storage atau siap untuk pengiriman.

### 3. Identifikasi masalah umum

- **Authentication failed** saat checkout: periksa scope dan nilai credential `gitea-access-token`.
- **Podman tidak ditemukan** pada agent: pastikan rootless Podman terpasang dan agen memiliki akses ke binary.
- **Build container gagal**: periksa apakah image `klakegg/hugo:ext-alpine` dapat di-pull dan workspace sudah terpasang dengan benar.
- **Publikasi artefak gagal**: periksa kredensial MinIO, alias `mc`, dan endpoint object storage.

### 4. Ambil keputusan berikutnya

Jika build awal berhasil, pipeline dasar sudah valid dan dapat dilanjutkan ke optimasi selanjutnya.

Jika build gagal karena lingkungan build atau akses container, lanjutkan dengan menyempurnakan **configure containerized build environment** dan agen build.

## Verification

| Item | Status | Notes |
|------|--------|-------|
| Pipeline job berhasil dijalankan | ✅ | Build pertama selesai tanpa error kritis. |
| Checkout repository berhasil | ✅ | SCM checkout berhasil. |
| Build Hugo berhasil | ✅ | Folder `public/` berisi halaman hasil kompilasi. |
| Artefak `.tar.gz` dibuat | ✅ | File artefak hadir di workspace build. |
| Kondisi agen terverifikasi | ✅ | Agen build dapat menjalankan `whoami`, `pwd`, dan `podman --version`. |

## Notes

- Simpan log console output untuk analisis jika ada kegagalan.
- Jika pipeline memerlukan penyesuaian lebih lanjut, perbaiki `Jenkinsfile` dan ulangi build.
- Setelah initial test sukses, siapkan trigger otomatisasi berikutnya seperti webhook Gitea atau multi-branch pipeline.

# TN-005 — Create Build Pipeline & Execute Initial Test

## Objective

Membuat item Jenkins Pipeline bertipe *Pipeline as Code*, menghubungkannya dengan repository Gitea, dan menjalankan build awal untuk memverifikasi pipeline.

## Background

Pipeline sebagai kode memudahkan versioning dan kolaborasi. Jenkins dapat diatur untuk menarik definisi pipeline langsung dari repository agar perubahan workflow tercatat bersama source code.

## Prerequisites

- TN-001 hingga TN-005 telah berhasil diselesaikan.
- Repository Gitea sudah dapat diakses oleh Jenkins.
- Credential `gitea-access-token` tersedia di Jenkins.
- File `Jenkinsfile` sudah ditambahkan ke repository `personal-site`.

## Engineering Decision

Refer to:

- **PS-ADR-0007 — Use Pipeline as Code**

> Architecture Decision Record (ADR) ini menjadi referensi utama (Single Source of Truth) untuk penggunaan Pipeline script from SCM dan Jenkinsfile yang disimpan bersama source code sebagai definisi pipeline.

## Implementation

### 1. Buat item pipeline baru

1. Login ke Jenkins.
2. Pilih **New Item**.
3. Masukkan nama item misalnya `personal-site-ci`.
4. Pilih **Pipeline**.
5. Klik **OK**.

### 2. Konfigurasi Source Code Management

1. Pada bagian **Pipeline**, pilih **Pipeline script from SCM**.
2. Pada **SCM**, pilih **Git**.
3. Isi **Repository URL**:

```text
https://<gitea-host>/<org>/personal-site.git
```

1. Pilih credential **gitea-access-token**.
2. Atur **Branch Specifier** ke `*/main` atau cabang target yang relevan.
3. Biarkan **Repository browser** kosong jika tidak diperlukan.

### 3. Tentukan Jenkinsfile path

1. Pada **Script Path**, masukkan `Jenkinsfile`.
2. Pastikan path ini sesuai dengan lokasi file di repository.

### 4. Atur trigger build awal

1. Pilih **Build Triggers** sesuai kebutuhan.
2. Untuk pengujian awal, cukup jalankan manual.
3. Untuk integrasi lebih lanjut, gunakan webhook Gitea atau polling SCM.

### 5. Simpan dan jalankan job

1. Klik **Save**.
2. Pilih **Build Now**.
3. Buka **Build History** dan periksa console output.

### 6. Jalankan initial test

1. Pastikan item pipeline `personal-site-ci` sudah tersimpan.
2. Pilih **Build Now** untuk memulai eksekusi.
3. Pantau **Console Output** hingga build selesai.
4. Buka **Stages** atau **Build History** untuk memverifikasi setiap tahapan.
5. Periksa bahwa semua stage berikut berhasil:
   - **Checkout** — repository Gitea berhasil diambil.
   - **Verify Agent** — agen build `builder` dapat menjalankan perintah shell.
   - **Build Static Website** — Hugo membangun situs ke folder `public`.
   - **Package Artifact** — artefak `.tar.gz` dibuat.
   - **Publish Artifact** — artefak diunggah ke MinIO.
   - **Verify Artifact** — artefak dapat ditemukan di bucket `personal-site` pada MinIO.
6. Jika build gagal, periksa kembali:
   - URL repository dan credential `gitea-access-token`.
   - ketersediaan `podman` pada agen build.
   - credential `minio-root` dan endpoint MinIO.
   - lokasi bucket `personal-site` dan isi file pada MinIO.

## Verification

| Item | Status | Notes |
| ------ | -------- | ------- |
| Pipeline item dibuat | ✅ | Item dibuat dengan nama `personal-site-ci` atau setara. |
| SCM Git menggunakan `gitea-access-token` | ✅ | Credential terpilih di konfigurasi pipeline. |
| Jenkinsfile path valid | ✅ | `Jenkinsfile` di repository ditemukan. |
| Build awal dapat dijalankan | ✅ | Job dapat dieksekusi dari Jenkins UI. |
| Initial pipeline run berhasil | ✅ | Job berhasil mengeksekusi `Jenkinsfile` dari repository. |
| Artifact terverifikasi di MinIO | ✅ | File tarball ditemukan di bucket `personal-site`. |

## Notes

- Jika checkout gagal, periksa kembali URL repository, scope token, dan credential Jenkins.
- Pantau **Console Output** untuk menemukan penyebab kegagalan build.
- Gunakan nama item pipeline yang konsisten dengan naming convention proyek.
- Jika ingin mengaktifkan otomatisasi, tambahkan webhook Gitea atau SCM polling setelah initial test berhasil.

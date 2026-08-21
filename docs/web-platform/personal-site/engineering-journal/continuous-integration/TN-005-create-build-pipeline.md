# TN-005 — Create Build Pipeline & Execute Initial Test

## Objective

Membuat item Jenkins Pipeline bertipe *Pipeline as Code*, menghubungkannya dengan repository Gitea, dan menjalankan build awal untuk memverifikasi pipeline.

## Background

Pipeline sebagai kode memudahkan versioning dan kolaborasi. Jenkins dapat diatur untuk menarik definisi pipeline langsung dari repository agar perubahan workflow tercatat bersama source code.

## Scope

Mencakup pembuatan Jenkins Pipeline job dari SCM dan initial test untuk membaca
Jenkinsfile. Verifikasi lengkap setiap stage dicatat pada TN-006.

## Prerequisites

- TN-001 hingga TN-004 telah berhasil diselesaikan.
- Repository Gitea sudah dapat diakses oleh Jenkins.
- Credential `gitea-access-token` tersedia di Jenkins.
- File `Jenkinsfile` sudah ditambahkan ke repository `personal-site`.

## Execution Decision

### PS-ADR-0007 — Use Pipeline as Code

Refer to:

- **[PS-ADR-0007 — Use Pipeline as Code](../../../../adr/personal-site/adr-records/PS-ADR-0007.md){ target="_blank" rel="noopener" }**

**Decision**

Jenkins job menggunakan `Pipeline script from SCM` dan membaca Jenkinsfile dari
repository Personal Site.

**Reason**

- Menjadikan definisi pipeline bagian dari version control.
- Memungkinkan pipeline direview dan direproduksi dari repository.
- Mengurangi konfigurasi script pipeline manual pada Jenkins Web UI.

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Create a New Pipeline Item

1. Login ke Jenkins.
2. Pilih **New Item**.
3. Masukkan nama item misalnya `personal-site-ci`.
4. Pilih **Pipeline**.
5. Klik **OK**.

!!! success "Expected Result"

    Item Pipeline `personal-site-ci` berhasil dibuat.

</div>

<div class="procedure-step" markdown>

### Configure Source Code Management

1. Pada bagian **Pipeline**, pilih **Pipeline script from SCM**.
2. Pada **SCM**, pilih **Git**.
3. Isi **Repository URL**:

    ```text
    https://<gitea-host>/<org>/personal-site.git
    ```

4. Pilih credential **gitea-access-token**.
5. Atur **Branch Specifier** ke `*/main` atau cabang target yang relevan.
6. Biarkan **Repository browser** kosong jika tidak diperlukan.

!!! success "Expected Result"

    Pipeline terhubung ke repository Gitea menggunakan credential yang ditentukan.

</div>

<div class="procedure-step" markdown>

### Set the Jenkinsfile Path

1. Pada **Script Path**, masukkan `Jenkinsfile`.
2. Pastikan path ini sesuai dengan lokasi file di repository.

!!! success "Expected Result"

    Jenkins dapat menemukan `Jenkinsfile` pada root repository.

</div>

<div class="procedure-step" markdown>

### Configure the Initial Build Trigger

1. Pilih **Build Triggers** sesuai kebutuhan.
2. Untuk pengujian awal, cukup jalankan manual.
3. Untuk integrasi lebih lanjut, gunakan webhook Gitea atau polling SCM.

!!! success "Expected Result"

    Trigger awal menggunakan mekanisme manual untuk pengujian terkontrol.

</div>

<div class="procedure-step" markdown>

### Save and Run the Job

1. Klik **Save**.
2. Pilih **Build Now**.
3. Buka **Build History** dan periksa console output.

!!! success "Expected Result"

    Jenkins membuat build baru dan mulai mengeksekusi pipeline.

</div>

<div class="procedure-step" markdown>

### Run the Initial Test

1. Pastikan item pipeline `personal-site-ci` sudah tersimpan.
2. Pilih **Build Now** untuk memulai eksekusi.
3. Pantau **Console Output** hingga build selesai.
4. Buka **Stages** atau **Build History** untuk memverifikasi setiap tahapan.
5. Periksa bahwa semua stage berikut berhasil:
    - **Checkout** — repository Gitea berhasil diambil.
    - **Verify Agent** — agen `builder-01` dapat menjalankan perintah shell.
    - **Build Static Website** — Hugo membangun situs ke folder `public`.
    - **Package Artifact** — artefak `.tar.gz` dibuat.
    - **Publish Artifact** — artefak diunggah ke MinIO.
    - **Verify Artifact** — artefak dapat ditemukan di bucket `personal-site` pada MinIO.
6. Jika build gagal, periksa kembali:
    - URL repository dan credential `gitea-access-token`.
    - ketersediaan `podman` pada agen build.
    - credential `minio-root` dan endpoint MinIO.
    - lokasi bucket `personal-site` dan isi file pada MinIO.

!!! success "Expected Result"

    Seluruh stage selesai sukses dan artefak tersedia pada bucket `personal-site`.

</div>

</div>

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

## Related Documentation

- [TN-004 — Create Jenkinsfile](TN-004-create-jenkinsfile.md)
- [TN-006 — Execute CI Pipeline Initial Test](TN-006-execute-ci-pipeline-initial-test.md)
- [Continuous Integration Engineering Journal](index.md)

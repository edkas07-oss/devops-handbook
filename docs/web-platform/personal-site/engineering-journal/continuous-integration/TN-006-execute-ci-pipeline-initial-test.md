# TN-006 — Execute CI Pipeline Initial Test

## Objective

Melakukan eksekusi awal pipeline Jenkins untuk memvalidasi konfigurasi job, akses repository, agen build, dan definisi `Jenkinsfile`.

## Background

Setelah pipeline dibuat dan Jenkinsfile tersedia, eksekusi awal memastikan seluruh alur CI berjalan end-to-end. Pengujian ini membantu mendeteksi isu SCM, agen, build container, atau konfigurasi artefak sejak dini.

## Scope

Mencakup validasi end-to-end checkout, build Hugo, packaging, dan upload artefak
ke MinIO. Deployment artefak berada di luar scope fase CI.

## Prerequisites

- TN-001 hingga TN-005 telah berhasil diselesaikan.
- Jenkins Pipeline item sudah dibuat dan terhubung ke repository.
- Credential SCM dan MinIO sudah tersedia di Jenkins.

## Execution Decision

### PS-ADR-0007 — Use Pipeline as Code

Refer to:

- **[PS-ADR-0007 — Use Pipeline as Code](../../../../adr/personal-site/adr-records/PS-ADR-0007.md){ target="_blank" rel="noopener" }**

**Decision**

Pengujian awal mengeksekusi definisi pipeline langsung dari Jenkinsfile yang
tersimpan di source repository.

**Reason**

- Memastikan Jenkins menjalankan versi pipeline yang tercatat pada Git.
- Memvalidasi bahwa definisi Pipeline as Code dapat direproduksi tanpa script
  manual pada Jenkins.
- Menghubungkan hasil pengujian dengan revisi source dan Jenkinsfile yang diuji.

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Run the First Build

1. Buka item pipeline Jenkins (`personal-site-ci` atau nama setara).
2. Klik **Build Now**.
3. Pantau **Console Output**.

!!! success "Expected Result"

    Jenkins menjalankan build awal dan menampilkan seluruh stage pada Console Output.

</div>

<div class="procedure-step" markdown>

### Verify the Pipeline Stages

Periksa bahwa pipeline berhasil melewati semua stage berikut:

1. **Checkout** — SCM berhasil diambil dari Gitea.
2. **Verify Agent** — agen build tersedia dan dapat menjalankan perintah shell.
3. **Build Static Site** — Hugo berhasil membangun situs ke folder `public`.
4. **Package Artifact** — artefak `.tar.gz` dihasilkan.
5. **Publish Artifact** — artefak diunggah ke MinIO.
6. **Verify Artifact** — artefak ditemukan pada bucket `personal-site`.

!!! success "Expected Result"

    Semua stage pipeline berstatus sukses tanpa ada stage yang dilewati karena error.

</div>

<div class="procedure-step" markdown>

### Identify Common Issues

1. **Authentication failed** saat checkout: periksa scope dan nilai credential `gitea-access-token`.
2. **Podman tidak ditemukan** pada agent: pastikan rootless Podman terpasang dan agen memiliki akses ke binary.
3. **Build container gagal**: periksa apakah image `ghcr.io/gohugoio/hugo:v0.160.1` dapat diunduh dan workspace sudah terpasang dengan benar.
4. **Publikasi artefak gagal**: periksa kredensial MinIO, alias `mc`, dan endpoint object storage.

!!! success "Expected Result"

    Penyebab kegagalan dapat dipetakan ke SCM, agent, build container, atau object storage.

</div>

<div class="procedure-step" markdown>

### Determine the Next Action

1. Jika build awal berhasil, pipeline dasar sudah valid dan dapat dilanjutkan ke optimasi selanjutnya.
2. Jika build gagal karena lingkungan build atau akses container, lanjutkan dengan menyempurnakan **configure containerized build environment** dan agen build.

!!! success "Expected Result"

    Tindak lanjut ditentukan berdasarkan hasil aktual build awal.

</div>

</div>

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

## Related Documentation

- [TN-005 — Create Build Pipeline](TN-005-create-build-pipeline.md)
- [Continuous Deployment Engineering Journal](../continuous-deployment/index.md)
- [Continuous Integration Engineering Journal](index.md)

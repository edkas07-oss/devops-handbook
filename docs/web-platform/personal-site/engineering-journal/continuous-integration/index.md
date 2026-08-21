# Continuous Integration Engineering Journal

## Overview

Bagian ini mencatat perjalanan engineering fase Continuous Integration (CI)
Personal Site, mulai dari persiapan Jenkins hingga pipeline berhasil membangun
static site Hugo dan menyimpan artifact ke MinIO.

Technical Note disusun menurut urutan implementasi. Dokumen di bagian ini
mempertahankan konteks historis, termasuk kondisi awal, keputusan implementasi,
hasil pengujian, dan masalah yang ditemukan selama pembangunan pipeline.

## Objective

Membangun pipeline CI yang dapat:

- mengambil source code Personal Site dari Gitea;
- menjalankan build Hugo di dalam ephemeral Podman container;
- memvalidasi hasil static site;
- mengemas direktori `public/` sebagai immutable artifact; dan
- mengunggah artifact ke bucket `personal-site` pada MinIO.

## Final Pipeline Flow

![Personal Site CI Pipeline](../../assets/images/personal-site-ci-pipeline.svg)

```text
Gitea
  ↓
Jenkins Controller
  ↓
builder-01
  ↓
Hugo container → public/
  ↓
personal-site-<BUILD_NUMBER>.tar.gz
  ↓
MinIO bucket: personal-site
```

## Implementation Result

| Component | Implementation | Status |
| --- | --- | --- |
| Source control | Gitea repository `personal-site` | Completed |
| Pipeline definition | `personal-site/Jenkinsfile` | Completed |
| Jenkins execution node | SSH agent `builder-01` | Completed |
| Build environment | Rootless Podman and Hugo container | Completed |
| Static-site validation | Require `public/index.html` | Completed |
| Artifact format | `personal-site-<BUILD_NUMBER>.tar.gz` | Completed |
| Artifact storage | MinIO bucket `personal-site` | Completed |

## Technical Notes

Technical Note sebaiknya dibaca secara berurutan:

1. **[TN-001 — Initialize Jenkins Controller & Environment](TN-001-initialize-jenkins-controller-environment.md)**

    Menyiapkan Jenkins Controller, environment, dan plugin yang diperlukan.

2. **[TN-002 — Deploy & Configure SSH Agent Node](TN-002-deploy-configure-ssh-agent-node.md)**

    Menyiapkan `builder-01` sebagai execution node untuk pipeline.

3. **[TN-003 — Configure Gitea Repository Access](TN-003-configure-gitea-repository-access.md)**

    Menghubungkan Jenkins dengan repository Personal Site pada Gitea.

4. **[TN-004 — Create Jenkinsfile](TN-004-create-jenkinsfile.md)**

    Membuat definisi stage CI sebagai Pipeline as Code.

5. **[TN-005 — Create Build Pipeline & Execute Initial Test](TN-005-create-build-pipeline.md)**

    Membuat Jenkins job dari SCM dan menjalankan pengujian awal.

6. **[TN-006 — Execute CI Pipeline Initial Test](TN-006-execute-ci-pipeline-initial-test.md)**

    Memverifikasi build Hugo, artifact packaging, dan publish ke MinIO.

!!! note "Output of This Phase"

    Fase CI menghasilkan artifact dengan kontrak berikut:

    ```text
    Object name : personal-site-<BUILD_NUMBER>.tar.gz
    Content     : public/
    Storage     : MinIO
    Bucket      : personal-site
    ```

    Artifact tersebut menjadi satu-satunya input release bagi pipeline CD.
    Hugo tidak melakukan build ulang pada fase deployment.

## Lessons Learned

- Hugo theme yang dikelola sebagai Git submodule harus diinisialisasi sebelum
  build dijalankan.
- Exit code Hugo saja belum cukup membuktikan artifact layak digunakan;
  pipeline harus memastikan `public/index.html` tersedia dan tidak kosong.
- Variable yang diteruskan ke ephemeral container harus diekspor secara
  eksplisit agar nilainya tersedia di dalam container.
- Artifact CI harus memiliki identitas build yang dapat ditelusuri dan menjadi
  satu-satunya input release untuk pipeline CD.

## Related Documentation

- [Continuous Deployment Engineering Journal](../continuous-deployment/index.md)
- [Personal Site Engineering Journal](../index.md)
- [Personal Site CI/CD Artifact Pipeline](../../assets/images/personal-site-ci-pipeline.svg)

Untuk alur yang berlaku saat ini, gunakan dokumentasi
[CI/CD](../../ci-cd/index.md). Engineering Journal ini digunakan ketika konteks
perjalanan implementasi atau riwayat troubleshooting diperlukan.

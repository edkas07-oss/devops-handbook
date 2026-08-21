# TN-004 — Create Jenkinsfile

## Objective

Menulis `Jenkinsfile` deklaratif awal untuk mendefinisikan alur Build Pipeline pada Jenkins, termasuk checkout, verifikasi agen, build Hugo, dan pembuatan artefak.

## Background

Pipeline sebagai kode memastikan definisi job disimpan dalam repository dan dapat berubah seiring evolusi aplikasi. Jenkinsfile memungkinkan pipeline dijalankan secara konsisten pada setiap commit.

## Scope

Mencakup definisi stage CI, ephemeral container, validasi static site,
packaging, dan publikasi artefak. Pembuatan job dan hasil eksekusi dicatat
terpisah.

## Prerequisites

- TN-001 hingga TN-003 telah berhasil diselesaikan.
- Repository `personal-site` sudah dapat diakses.
- Jenkins Pipeline item sudah dikonfigurasi untuk menarik `Jenkinsfile` dari repository.

## Execution Decision

### PS-ADR-0003 — Externalized Static Content Storage

Refer to:

- **[PS-ADR-0003 — Externalized Static Content Storage](../../../../adr/personal-site/adr-records/PS-ADR-0003.md){ target="_blank" rel="noopener" }**

**Decision**

Hasil build Hugo dipaketkan sebagai artefak dan dipublikasikan ke MinIO di luar
runtime container serta Jenkins Workspace.

**Reason**

- Membuat artefak independen dari workspace dan runtime container.
- Mendukung prinsip Build Once, Deploy Many.
- Memungkinkan artefak digunakan kembali untuk deployment dan rollback.

### PS-ADR-0005 — Separate Source Code and Deployment Artifacts

Refer to:

- **[PS-ADR-0005 — Separate Source Code and Deployment Artifacts](../../../../adr/personal-site/adr-records/PS-ADR-0005.md){ target="_blank" rel="noopener" }**

**Decision**

Source code dan deployment artifact dikelola sebagai output dengan lifecycle dan
tanggung jawab yang berbeda.

**Reason**

- Menjaga source repository bebas dari hasil build.
- Memisahkan histori perubahan source code dari lifecycle artifact.
- Memungkinkan proses build dan deployment berkembang secara independen.

### PS-ADR-0009 — Use Containerized Pipeline Environment

Refer to:

- **[PS-ADR-0009 — Use Containerized Pipeline Environment](../../../../adr/personal-site/adr-records/PS-ADR-0009.md){ target="_blank" rel="noopener" }**

**Decision**

Jenkinsfile menjalankan Hugo dan MinIO Client sebagai ephemeral container
menggunakan Podman.

**Reason**

- Menjaga build environment konsisten pada setiap eksekusi.
- Mengisolasi dependency Hugo dan MinIO Client dari Jenkins Controller.
- Memungkinkan versi tool dikelola melalui container image.

### PS-ADR-0007 — Use Pipeline as Code

Refer to:

- **[PS-ADR-0007 — Use Pipeline as Code](../../../../adr/personal-site/adr-records/PS-ADR-0007.md){ target="_blank" rel="noopener" }**

**Decision**

Seluruh definisi pipeline CI disimpan sebagai Jenkinsfile di dalam source
repository Personal Site.

**Reason**

- Memberikan histori perubahan pipeline melalui Git.
- Memungkinkan perubahan pipeline direview bersama source code.
- Mengurangi konfigurasi pipeline manual pada Jenkins.

## Implementation

Tambahkan file `Jenkinsfile` pada root repository `personal-site` dengan isi berikut:

```groovy
pipeline {

    /**************************************************************************
     * Menentukan Build Agent
     *
     * Seluruh proses build dijalankan pada Jenkins SSH Build Agent
     * dengan label "builder-01".
     **************************************************************************/

    agent {
        label 'builder-01'
    }

    /**************************************************************************
     * Environment Variables
     **************************************************************************/

    environment {

        HUGO_IMAGE   = 'ghcr.io/gohugoio/hugo:v0.160.1'
        MC_IMAGE     = 'quay.io/minio/mc:latest'

        ARTIFACT_NAME = "personal-site-${BUILD_NUMBER}.tar.gz"

        MINIO_ALIAS  = 'artifact_storage'
        MINIO_BUCKET = 'personal-site'

        MINIO_URL = 'http://host.containers.internal:9000'

    }

    stages {

        /**********************************************************************
         * Checkout Source Code
         *
         * Jenkins melakukan checkout source code ke Workspace
         * pada Build Agent.
         **********************************************************************/

        stage('Checkout Source Code') {

            steps {

                checkout scm

            }

        }

        /**********************************************************************
         * Verify Build Agent
         *
         * Memastikan Build Agent siap digunakan.
         **********************************************************************/

        stage('Verify Build Agent') {
            steps {
                sh """
                    set -eu

                    echo "========================================"
                    echo "VERIFY BUILD AGENT"
                    echo "========================================"

                    echo "Hostname : $(hostname)"
                    echo "User     : $(whoami)"
                    echo "Home     : $HOME"
                    echo "Workspace: $WORKSPACE"

                    podman info --format "Rootless={{.Host.Security.Rootless}}"
                """
            }
        }

        /**********************************************************************
         * Build Static Website
         *
         * Menjalankan Hugo di dalam Container menggunakan Workspace
         * Jenkins sebagai source code.
         **********************************************************************/

        stage('Build Static Website') {

            steps {

                sh """
                    set -eu

                    podman run \
                        --userns=keep-id \
                        --rm \
                        --pull=missing \
                        -v "$WORKSPACE:/src:Z" \
                        -w /src \
                        ${HUGO_IMAGE} \
                        --minify --destination public
                """

            }

        }

        /**********************************************************************
         * Package Artifact
         *
         * Mengemas hasil build menjadi satu file artifact.
         **********************************************************************/

        stage('Package Artifact') {

            steps {

                sh """
                    set -eu

                    tar czf "${ARTIFACT_NAME}" public

                    echo
                    echo "========================================"
                    echo "Artifact"
                    echo "========================================"

                    ls -lh "${ARTIFACT_NAME}"
                """

            }

        }

        /**********************************************************************
         * Publish Artifact
         *
         * Mengunggah Build Artifact ke MinIO menggunakan
         * MinIO Client Container.
         **********************************************************************/

        stage('Publish Artifact') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'minio-root',
                        usernameVariable: 'MINIO_USER',
                        passwordVariable: 'MINIO_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu

                        podman run \
                            --rm \
                            -v "$WORKSPACE:/workspace:Z" \
                            -w /workspace \
                            --env ARTIFACT_NAME \
                            --env MINIO_ALIAS \
                            --env MINIO_BUCKET \
                            --env MINIO_URL \
                            --env MINIO_USER \
                            --env MINIO_PASSWORD \
                            --entrypoint /bin/sh \
                            "${MC_IMAGE}" \
                            -ec '
                                mc alias set "${MINIO_ALIAS}" "${MINIO_URL}" "$MINIO_USER" "$MINIO_PASSWORD"
                                mc mb --ignore-existing "${MINIO_ALIAS}/${MINIO_BUCKET}"
                                mc cp "${ARTIFACT_NAME}" "${MINIO_ALIAS}/${MINIO_BUCKET}/${ARTIFACT_NAME}"
                                mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}/${ARTIFACT_NAME}"
                            '
                    '''
                }
            }
        }

    }

    /**************************************************************************
     * Post Actions
     **************************************************************************/

    post {

        always {

            archiveArtifacts artifacts: '*.tar.gz'

        }

    }

}
```

Catatan:

- `agent { label 'builder-01' }` mengarahkan Jenkins untuk menjalankan pipeline pada Jenkins SSH Build Agent `builder-01`.
- Variabel environment yang digunakan meliputi `HUGO_IMAGE`, `MC_IMAGE`, `ARTIFACT_NAME`, `MINIO_ALIAS`, `MINIO_BUCKET`, dan `MINIO_URL`.
- Stage `Publish Artifact` menggunakan `withCredentials` dan MinIO Client container untuk mengunggah tarball ke MinIO.
- Jika MinIO endpoint atau host berbeda, sesuaikan nilai `MINIO_URL` dan konfigurasi credential.

## Verification

| Item | Status | Notes |
|------|--------|-------|
| Jenkinsfile tersedia di repository | ✅ | `Jenkinsfile` berada di root repository `personal-site`. |
| Pipeline deklaratif sudah terdefinisi | ✅ | Jenis pipeline `declarative` dipakai. |
| Stage dasar terdefinisi | ✅ | Checkout, Verify Agent, Build Static Site, Package Artifact, Publish Artifact ada. |
| Artefak dapat diarsipkan | ✅ | `archiveArtifacts` disiapkan untuk menyimpan tarball. |

## Notes

- Sesuaikan `podman` command dengan environment agent jika daemon atau image registry berbeda.
- Untuk tahap publikasi, sertakan `MINIO_USER` dan `MINIO_PASSWORD` sebagai credential Jenkins yang benar.
- Jika `mc alias set` perlu host certificate custom, tambahkan opsi `--insecure` atau tambahkan trust config sesuai dokumentasi MinIO.

## Related Documentation

- [TN-003 — Configure Gitea Repository Access](TN-003-configure-gitea-repository-access.md)
- [TN-005 — Create Build Pipeline](TN-005-create-build-pipeline.md)
- [Continuous Integration Engineering Journal](index.md)

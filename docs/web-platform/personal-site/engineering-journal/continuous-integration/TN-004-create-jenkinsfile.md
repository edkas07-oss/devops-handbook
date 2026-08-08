# TN-004 — Create Jenkinsfile

## Objective

Menulis `Jenkinsfile` deklaratif awal untuk mendefinisikan alur Build Pipeline pada Jenkins, termasuk checkout, verifikasi agen, build Hugo, dan pembuatan artefak.

## Background

Pipeline sebagai kode memastikan definisi job disimpan dalam repository dan dapat berubah seiring evolusi aplikasi. Jenkinsfile memungkinkan pipeline dijalankan secara konsisten pada setiap commit.

## Prerequisites

- TN-001 hingga TN-005 telah berhasil diselesaikan.
- Repository `personal-site` sudah dapat diakses.
- Jenkins Pipeline item sudah dikonfigurasi untuk menarik `Jenkinsfile` dari repository.

## Engineering Decision

Refer to:

- **PS-ADR-0003 — Externalized Static Content Storage**
- **PS-ADR-0005 — Separate Source Code and Deployment Artifacts**
- **PS-ADR-0009 — Use Containerized Pipeline Environment**
- **PS-ADR-0007 — Use Pipeline as Code**

> Architecture Decision Records (ADR) tersebut menjadi referensi utama (Single Source of Truth) untuk menghasilkan static content sebagai artifact terpisah dari source code, menjalankan proses build dan publikasi melalui container, serta menyimpan artifact secara eksternal di MinIO.

## Implementation

Tambahkan file `Jenkinsfile` pada root repository `personal-site` dengan isi berikut:

```groovy
pipeline {

    /**************************************************************************
     * Menentukan Build Agent
     *
     * Seluruh proses build dijalankan pada Jenkins SSH Build Agent
     * dengan label "builder".
     **************************************************************************/

    agent {
        label 'builder'
    }

    /**************************************************************************
     * Environment Variables
     **************************************************************************/

    environment {

        HUGO_IMAGE   = 'docker.io/klakegg/hugo:ext-alpine'
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

- `agent { label 'builder' }` mengarahkan Jenkins untuk menjalankan pipeline pada Jenkins SSH Build Agent dengan label `builder`.
- Variabel environment yang digunakan meliputi `HUGO_IMAGE`, `MC_IMAGE`, `ARTIFACT_NAME`, `MINIO_ALIAS`, `MINIO_BUCKET`, dan `MINIO_URL`.
- Stage `Publish Artifact` menggunakan `withCredentials` dan MinIO Client container untuk mengunggah tarball ke MinIO.
- Jika MinIO endpoint atau host berbeda, sesuaikan nilai `MINIO_URL` dan konfigurasi credential.

## Verification

| Item | Status | Notes |
|------|--------|-------|
| Jenkinsfile tersedia di repository | ✅ | `Jenkinsfile` berada di root repository `personal-site`. |
| Pipeline deklaratif sudah terdefinisi | ✅ | Jenis pipeline `declarative` dipakai. |
| Stage dasar terdefinisi | ✅ | Checkout, Verify Agent, Build Static Site, Package Artifact, Publish Artifact ada. |
| Artifak dapat di-archive | ✅ | `archiveArtifacts` disiapkan untuk menyimpan tarball. |

## Notes

- Sesuaikan `podman` command dengan environment agent jika daemon atau image registry berbeda.
- Untuk tahap publikasi, sertakan `MINIO_USER` dan `MINIO_PASSWORD` sebagai credential Jenkins yang benar.
- Jika `mc alias set` perlu host certificate custom, tambahkan opsi `--insecure` atau tambahkan trust config sesuai dokumentasi MinIO.

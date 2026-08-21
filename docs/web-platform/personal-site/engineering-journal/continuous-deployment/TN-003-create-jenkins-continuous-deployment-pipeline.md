# TN-003 — Create Jenkins Continuous Deployment Pipeline

## Objective

Mengimplementasikan Jenkins Continuous Deployment pipeline untuk mengambil artefak Hugo dari MinIO, mengisi Podman volume `www-personal-site`, menjalankan container NGINX, dan memvalidasi website melalui HTTP.

## Background

Pipeline CI pada repository `personal-site` menggunakan file `Jenkinsfile` untuk menghasilkan artefak `personal-site-<BUILD_NUMBER>.tar.gz` dan mengunggahnya ke bucket `personal-site` pada MinIO.

Pipeline CD dikelola pada repository yang sama menggunakan file terpisah bernama `Jenkinsfile.cd`. Pemisahan file menjaga tanggung jawab pipeline tetap jelas:

| Pipeline | Definition | Responsibility |
| --- | --- | --- |
| Continuous Integration | `Jenkinsfile` | Build Hugo, package artifact, dan publish ke MinIO. |
| Continuous Deployment | `Jenkinsfile.cd` | Download artifact, deploy ke NGINX, dan validate deployment. |

Kedua Jenkinsfile membaca konfigurasi non-secret yang sama dari `deployment/CONFIG`. `Jenkinsfile.cd` juga dilengkapi komentar terstruktur pada agent, parameter, shared configuration, setiap stage, rollback, dan cleanup agar pipeline bersifat self-documented.

## Scope

Technical Note ini mencakup:

- lokasi dan nama pipeline definition;
- parameter dan environment variable pipeline CD;
- penggunaan Jenkins deployment agent `builder-01`;
- akses artefak pada MinIO;
- rancangan stage Jenkins CD;
- pengelolaan Podman volume `www-personal-site`;
- deployment container NGINX;
- validasi dan rollback dasar.

Technical Note ini belum mencakup trigger otomatis dari pipeline CI, approval untuk environment production, maupun strategi zero-downtime deployment.

## Prerequisites

- Desain TN-001 telah disetujui.
- Persiapan runtime pada TN-002 harus diimplementasikan sebelum pipeline CD dieksekusi.
- Jenkins deployment agent dengan label `builder-01` tersedia pada host runtime NGINX.
- Agent berjalan sebagai user yang sama dengan pemilik rootless Podman runtime.
- Agent dapat menjalankan `podman info` tanpa privilege escalation.
- Image `localhost/nginx-image:1.0` tersedia pada agent.
- Podman network `web` tersedia.
- Jenkins credential `minio-root` tersedia.
- MinIO dapat diakses dari agent melalui `http://host.containers.internal:9000`.
- Bucket MinIO `personal-site` berisi artefak hasil CI.

## Execution Decision

### PS-ADR-0007 — Use Pipeline as Code

Refer to:

- **[PS-ADR-0007 — Use Pipeline as Code](../../../../adr/personal-site/adr-records/PS-ADR-0007.md){ target="_blank" rel="noopener" }**

**Decision**

Pipeline CD didefinisikan pada `Jenkinsfile.cd` di source repository.

**Reason**

- Memberikan version control dan review untuk definisi deployment.
- Mengurangi konfigurasi script manual pada Jenkins.

### PS-ADR-0008 — Adopt Stage-Based CI Pipeline

Refer to:

- **[PS-ADR-0008 — Adopt Stage-Based CI Pipeline](../../../../adr/personal-site/adr-records/PS-ADR-0008.md){ target="_blank" rel="noopener" }**

**Decision**

Pipeline CD memisahkan download, validation, staging, deployment, dan runtime
validation menjadi stage yang dapat diverifikasi.

**Reason**

- Setiap tanggung jawab dapat diaudit dan ditroubleshoot secara independen.
- Pipeline dapat berhenti sebelum runtime berubah jika validasi awal gagal.

### PS-ADR-0009 — Use Containerized Pipeline Environment

Refer to:

- **[PS-ADR-0009 — Use Containerized Pipeline Environment](../../../../adr/personal-site/adr-records/PS-ADR-0009.md){ target="_blank" rel="noopener" }**

**Decision**

MinIO Client dan helper deployment dijalankan sebagai ephemeral container.

**Reason**

- Mengisolasi dependency tool dari Jenkins agent.
- Menjaga execution environment konsisten dan mudah dibersihkan.

### PS-ADR-0011 — Deploy Immutable CI Artifact

Refer to:

- **[PS-ADR-0011 — Deploy Immutable CI Artifact](../../../../adr/personal-site/adr-records/PS-ADR-0011.md){ target="_blank" rel="noopener" }**

**Decision**

Pipeline menerima nama artefak CI secara eksplisit dan tidak menjalankan build
Hugo ulang.

**Reason**

- Menjaga kesetaraan hasil build dengan release yang dideploy.
- Mendukung traceability dan rollback berdasarkan nama artefak.

### PS-ADR-0012 — Store Static Content in Podman Named Volume

Refer to:

- **[PS-ADR-0012 — Store Static Content in Podman Named Volume](../../../../adr/personal-site/adr-records/PS-ADR-0012.md){ target="_blank" rel="noopener" }**

**Decision**

Pipeline mengisi volume `www-personal-site`, lalu memasangnya read-only pada
container NGINX.

**Reason**

- Memisahkan lifecycle konten dari runtime image.
- Memungkinkan penggantian konten dan rollback tanpa rebuild image.

### PS-ADR-0013 — Execute Deployment through Dedicated Jenkins Agent

Refer to:

- **[PS-ADR-0013 — Execute Deployment through Dedicated Jenkins Agent](../../../../adr/personal-site/adr-records/PS-ADR-0013.md){ target="_blank" rel="noopener" }**

**Decision**

Job CD hanya dijalankan pada agent `builder-01` di host runtime NGINX.

**Reason**

- Agent dapat mengelola Rootless Podman runtime secara lokal.
- Podman socket tidak perlu diekspos melalui network.

### PS-ADR-0014 — Keep Application Deployment Configuration Outside Generic Runtime Image

Refer to:

- **[PS-ADR-0014 — Keep Application Deployment Configuration Outside Generic Runtime Image](../../../../adr/personal-site/adr-records/PS-ADR-0014.md){ target="_blank" rel="noopener" }**

**Decision**

Pipeline membaca application deployment contract dari `deployment/CONFIG` dan
menjalankan `deployment/deploy.sh`.

**Reason**

- Menjaga konfigurasi Personal Site di luar generic NGINX image.
- Memusatkan nilai deployment non-secret pada source repository aplikasi.

## Architecture

![Personal Site Continuous Deployment Pipeline](../../assets/images/personal-site-cd-pipeline.svg)

Diagram menunjukkan alur utama secara vertikal sesuai urutan stage pada `Jenkinsfile.cd`. Cabang merah menggambarkan rollback bersyarat ketika validasi gagal setelah volume aktif mulai diperbarui.

## Implementation

### Pipeline Configuration

#### Agent

```groovy
agent {
    label 'builder-01'
}
```

Pipeline harus berhenti jika agent `builder-01` tidak tersedia. Job deployment tidak boleh dialihkan ke build agent lain yang tidak memiliki runtime NGINX dan Podman volume terkait.

#### Parameters

| Parameter | Type | Required | Purpose |
| --- | --- | --- | --- |
| `ARTIFACT_NAME` | String | Yes | Nama lengkap artefak, misalnya `personal-site-42.tar.gz`. |

Pipeline hanya menerima pola berikut:

```text
personal-site-<BUILD_NUMBER>.tar.gz
```

Validasi nama mencegah penggunaan path atau object key di luar format artefak yang disetujui.

#### Environment Variables

| Variable | Value |
| --- | --- |
| `MC_IMAGE` | `quay.io/minio/mc:latest` |
| `MINIO_ALIAS` | `artifact_storage` |
| `MINIO_BUCKET` | `personal-site` |
| `MINIO_URL` | `http://host.containers.internal:9000` |
| Application deployment config | `personal-site/deployment/CONFIG` |
| Application deployment script | `personal-site/deployment/deploy.sh` |

`deployment/CONFIG` juga menyimpan konfigurasi bersama untuk pipeline CI dan CD:

| Configuration Group | Variables |
| --- | --- |
| Artifact | `PROJECT_NAME`, `ARTIFACT_PREFIX` |
| Build | `HUGO_IMAGE` |
| Object storage | `MC_IMAGE`, `MINIO_ALIAS`, `MINIO_BUCKET`, `MINIO_URL` |
| Runtime | `CONTAINER_NAME`, `NGINX_IMAGE`, `CONTENT_VOLUME`, `PODMAN_NETWORK`, `LOADER_CONTAINER` |
| Published ports | `SSH_HOST_PORT`, `HTTP_HOST_PORT`, `HTTPS_HOST_PORT` |

Secret seperti username dan password MinIO tetap disimpan pada Jenkins Credentials.

### Implemented Pipeline Stages

| Stage | Responsibility |
| --- | --- |
| Checkout Pipeline Source | Mengambil `Jenkinsfile.cd` dan metadata repository. |
| Verify Deployment Agent | Memastikan agent dan rootless Podman runtime siap. |
| Validate Parameters | Memvalidasi pola `ARTIFACT_NAME`. |
| Download Artifact | Mengambil artefak terpilih dari MinIO. |
| Verify Artifact | Memvalidasi file, archive structure, dan `public/index.html`. |
| Prepare Staging | Mengekstrak konten ke staging directory. |
| Prepare Rollback Metadata | Mencatat artefak aktif sebelum volume diperbarui. |
| Populate Content Volume | Mengganti isi `www-personal-site` melalui ephemeral loader. |
| Deploy NGINX | Menjalankan NGINX dengan volume read-only. |
| Validate Deployment | Memeriksa health container dan respons HTTP. |

### Pipeline Implementation

Implementasi dilakukan secara berurutan oleh Jenkins deployment agent `builder-01`. MinIO hanya menjadi artifact storage dan tidak dipasang langsung ke container NGINX.

<div class="procedure" markdown>

<div class="procedure-step" markdown>

#### Receive Artifact Name

Operator menjalankan job `personal-site-cd` dengan parameter:

```text
ARTIFACT_NAME=personal-site-<BUILD_NUMBER>.tar.gz
```

Pipeline memvalidasi nama menggunakan pola berikut:

```text
^personal-site-[0-9]+\.tar\.gz$
```

Pipeline berhenti sebelum mengakses MinIO jika parameter kosong atau tidak sesuai pola.

!!! success "Expected Result"

    Pipeline menerima hanya nama artefak yang sesuai kontrak penamaan.

</div>

<div class="procedure-step" markdown>

#### Obtain MinIO Credentials

Jenkins membuka credential `minio-root` hanya selama stage download:

```groovy
withCredentials([
    usernamePassword(
        credentialsId: 'minio-root',
        usernameVariable: 'MINIO_USER',
        passwordVariable: 'MINIO_PASSWORD'
    )
]) {
    // Download artifact from MinIO.
}
```

Credential tidak disimpan di repository, artifact, atau Podman volume.

!!! success "Expected Result"

    Credential MinIO tersedia hanya selama stage download.

</div>

<div class="procedure-step" markdown>

#### Download Artifact from MinIO

Agent menjalankan MinIO Client sebagai ephemeral container:

```bash
mc alias set \
    artifact_storage \
    http://host.containers.internal:9000 \
    "$MINIO_USER" \
    "$MINIO_PASSWORD"

mc cp \
    "artifact_storage/personal-site/$ARTIFACT_NAME" \
    "/workspace/$ARTIFACT_NAME"
```

Workspace Jenkins dipasang pada MinIO Client container hanya selama proses download. Setelah container selesai, artefak tersedia pada:

```text
$WORKSPACE/personal-site-<BUILD_NUMBER>.tar.gz
```

!!! success "Expected Result"

    Artefak terpilih tersedia pada Jenkins workspace.

</div>

<div class="procedure-step" markdown>

#### Validate Artifact

Pipeline memeriksa artefak sebelum mengubah runtime:

1. File tersedia dan tidak kosong.
2. Archive dapat dibaca menggunakan `tar`.
3. Seluruh entry berada di bawah direktori `public/`.
4. Archive tidak memiliki absolute path.
5. Archive tidak memiliki path traversal `../`.
6. `public/index.html` tersedia dan tidak kosong.

Jika salah satu pemeriksaan gagal, pipeline berhenti dan volume aktif tidak diubah.

!!! success "Expected Result"

    Hanya archive yang aman dan memiliki `public/index.html` yang lolos validasi.

</div>

<div class="procedure-step" markdown>

#### Extract Artifact to Staging

Artifact yang valid diekstrak ke staging directory:

```bash
rm -rf deploy-staging
mkdir -p deploy-staging
tar -xzf "$ARTIFACT_NAME" -C deploy-staging
test -s deploy-staging/public/index.html
```

Direktori staging merupakan area sementara pada Jenkins workspace dan bukan document root NGINX.

!!! success "Expected Result"

    Konten artefak tersedia pada `deploy-staging/public` dan siap dipindahkan ke volume.

</div>

<div class="procedure-step" markdown>

#### Back Up Current Volume Content

Pipeline memastikan `www-personal-site` tersedia, kemudian menyimpan isi saat ini sebelum deployment:

```bash
if ! podman volume exists www-personal-site; then
    podman volume create www-personal-site
fi
```

Backup disimpan sementara pada Jenkins workspace sebagai `deployment-state/previous-content.tar.gz`. Backup ini digunakan hanya jika proses setelah pembaruan volume gagal.

!!! success "Expected Result"

    Konten aktif sebelumnya tersedia sebagai backup untuk rollback.

</div>

<div class="procedure-step" markdown>

#### Populate `www-personal-site`

Pipeline menghentikan container NGINX sebelum mengganti konten agar NGINX tidak menyajikan volume yang sedang diperbarui sebagian.

Urutan pengisian volume:

1. Hentikan container `personal-site-web`.
2. Bersihkan isi lama `www-personal-site` melalui ephemeral helper container.
3. Buat container loader dengan volume terpasang read-write.
4. Salin `deploy-staging/public/.` ke `/var/www/html/` menggunakan `podman cp`.
5. Simpan nama artefak aktif pada `.artifact-name` di dalam volume.
6. Hapus container loader.

Volume hanya dipasang read-write pada helper container. Container NGINX selalu memasangnya sebagai read-only.

!!! success "Expected Result"

    Volume `www-personal-site` berisi release baru beserta identitas artefaknya.

</div>

<div class="procedure-step" markdown>

#### Run NGINX Container

Pipeline menjalankan NGINX dengan konfigurasi:

```bash
podman run --detach \
    --name personal-site-web \
    --network web \
    --publish 2224:22 \
    --publish 8091:80 \
    --publish 8443:443 \
    --volume www-personal-site:/var/www/html:ro \
    localhost/nginx-image:1.0
```

Perintah aktual dikelola oleh `deployment/deploy.sh`. Container NGINX tidak menerima credential MinIO dan tidak berkomunikasi langsung dengan bucket MinIO.

!!! success "Expected Result"

    Container `personal-site-web` berjalan menggunakan konfigurasi aplikasi dan named volume read-only.

</div>

<div class="procedure-step" markdown>

#### Validate Deployment

Pipeline memverifikasi:

```bash
curl --fail --silent --show-error http://127.0.0.1:8091/
```

Selain respons HTTP, pipeline memeriksa bahwa `/var/www/html` berasal dari `www-personal-site` dan memiliki `RW=false`.

!!! success "Expected Result"

    Website merespons melalui published HTTP port dan content volume terpasang read-only.

</div>

<div class="procedure-step" markdown>

#### Roll Back on Failure

Jika container gagal dijalankan atau validasi HTTP gagal:

1. Hentikan container deployment baru.
2. Bersihkan isi `www-personal-site`.
3. Pulihkan `deployment-state/previous-content.tar.gz` ke volume.
4. Jalankan kembali NGINX menggunakan volume yang telah dipulihkan.
5. Tandai Jenkins build sebagai failed.

Jika kegagalan terjadi sebelum volume diperbarui, rollback tidak dijalankan karena runtime lama belum berubah.

!!! success "Expected Result"

    Runtime sebelumnya dipulihkan ketika deployment baru gagal setelah volume diperbarui.

</div>

</div>

#### Implementation Source

File berikut telah dibuat pada repository `personal-site`:

```text
Jenkinsfile.cd
```

Struktur deklaratif berikut merupakan ringkasan implementasi. Source of truth berada pada `personal-site/Jenkinsfile.cd`:

```groovy
pipeline {
    agent {
        label 'builder-01'
    }

    parameters {
        string(
            name: 'ARTIFACT_NAME',
            defaultValue: '',
            description: 'Artifact from MinIO, for example personal-site-42.tar.gz'
        )
    }

    environment {
        MC_IMAGE         = 'quay.io/minio/mc:latest'
        MINIO_ALIAS      = 'artifact_storage'
        MINIO_BUCKET     = 'personal-site'
        MINIO_URL        = 'http://host.containers.internal:9000'
    }

    stages {
        stage('Verify Deployment Agent') {
            steps {
                sh '''
                    set -eu
                    . deployment/CONFIG
                    test "$(id -u)" -ne 0
                    podman info --format 'Rootless={{.Host.Security.Rootless}}'
                    podman image exists "$NGINX_IMAGE"
                    podman network exists "$PODMAN_NETWORK"
                '''
            }
        }

        stage('Validate Parameters') {
            steps {
                sh '''
                    set -eu
                    printf '%s\n' "$ARTIFACT_NAME" \
                        | grep -Eq '^personal-site-[0-9]+\.tar\.gz$' \
                        || { echo "Invalid artifact name: $ARTIFACT_NAME" >&2; exit 1; }
                '''
            }
        }

        stage('Download Artifact') {
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
                        podman run --rm \
                            --volume "$WORKSPACE:/workspace:Z" \
                            --workdir /workspace \
                            --env ARTIFACT_NAME \
                            --env MINIO_ALIAS \
                            --env MINIO_BUCKET \
                            --env MINIO_URL \
                            --env MINIO_USER \
                            --env MINIO_PASSWORD \
                            --entrypoint /bin/sh \
                            "$MC_IMAGE" \
                            -ec '\
                                mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_USER" "$MINIO_PASSWORD"; \
                                mc cp "$MINIO_ALIAS/$MINIO_BUCKET/$ARTIFACT_NAME" "/workspace/$ARTIFACT_NAME"\
                            '
                    '''
                }
            }
        }

        stage('Verify and Stage Artifact') {
            steps {
                sh '''
                    set -eu
                    rm -rf deploy-staging
                    mkdir -p deploy-staging
                    tar -tzf "$ARTIFACT_NAME" >/dev/null
                    tar -xzf "$ARTIFACT_NAME" -C deploy-staging
                    test -s deploy-staging/public/index.html
                '''
            }
        }

        stage('Populate Content Volume') {
            steps {
                sh '''
                    set -eu
                    . deployment/CONFIG
                    if ! podman volume exists "$CONTENT_VOLUME"; then
                        podman volume create "$CONTENT_VOLUME"
                    fi
                    podman rm -f personal-site-volume-loader 2>/dev/null || true

                    podman run --rm \
                        --volume "$CONTENT_VOLUME:/var/www/html" \
                        --entrypoint /bin/sh \
                        "$NGINX_IMAGE" \
                        -c 'find /var/www/html -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +'

                    podman create \
                        --name personal-site-volume-loader \
                        --volume "$CONTENT_VOLUME:/var/www/html" \
                        --entrypoint /bin/sh \
                        "$NGINX_IMAGE" \
                        -c 'true'

                    podman cp deploy-staging/public/. personal-site-volume-loader:/var/www/html/
                    podman rm personal-site-volume-loader
                '''
            }
        }

        stage('Deploy NGINX') {
            steps {
                sh '''
                    set -eu
                    ./deployment/deploy.sh
                '''
            }
        }

        stage('Validate Deployment') {
            steps {
                sh '''
                    set -eu
                    . deployment/CONFIG
                    podman container exists "$CONTAINER_NAME"
                    curl --fail --silent --show-error \
                        "http://127.0.0.1:$HTTP_HOST_PORT/" >/dev/null
                '''
            }
        }
    }

    post {
        always {
            sh '''
                podman rm -f personal-site-volume-loader 2>/dev/null || true
                rm -rf deploy-staging
            '''
        }
    }
}
```

Implementasi aktual juga menyimpan backup isi volume sebelum pembaruan dan memulihkannya melalui blok `post.failure` apabila deployment gagal.

### Artifact Validation Requirements

Sebelum ekstraksi, pipeline harus memastikan:

- nama file sesuai pola yang diizinkan;
- object tersedia pada bucket `personal-site`;
- file tidak kosong;
- archive dapat dibaca oleh `tar`;
- seluruh konten archive berada di bawah direktori `public/`;
- archive tidak memiliki absolute path atau path traversal `../`; dan
- `public/index.html` tersedia dan tidak kosong.

Validasi archive path telah diterapkan menggunakan pemeriksaan daftar isi archive sebelum ekstraksi.

## Troubleshooting

### Issue — Groovy Compilation Error in AWK Expression

#### Symptom

Initial build gagal sebelum pipeline dijalankan:

```text
WorkflowScript: 162: unexpected char: '\\'
```

#### Root Cause

Ekspresi AWK menggunakan escape `\/` di dalam Groovy triple-quoted string. Groovy memproses backslash sebelum script diteruskan ke shell dan menolak escape tersebut saat compilation.

#### Resolution

Ekspresi diganti menggunakan character class dan `substr()` sehingga tidak membutuhkan slash escape:

```awk
substr($0, 1, 1) == "/" { invalid = 1 }
/(^|[/])[.][.]($|[/])/ { invalid = 1 }
$0 != "public" && $0 != "public/" && $0 !~ /^public[/]/ { invalid = 1 }
```

Pemeriksaan source memastikan tidak ada single slash escape lain pada `Jenkinsfile.cd`.

### Issue — ARTIFACT_NAME Parameter Not Set

#### Symptom

Pipeline berhasil dikompilasi, tetapi berhenti pada stage parameter validation:

```text
ARTIFACT_NAME: parameter not set
```

#### Root Cause

Initial build dijalankan tanpa parameter. Karena shell menggunakan `set -u`, pembacaan variabel yang belum tersedia menghentikan script sebelum pesan validasi ditampilkan.

#### Resolution

Validasi menggunakan nilai default kosong yang aman:

```bash
SELECTED_ARTIFACT="${ARTIFACT_NAME:-}"
```

Jika parameter tidak tersedia atau tidak valid, pipeline memberikan instruksi untuk menjalankan job melalui **Build with Parameters**. Deployment tetap tidak dilanjutkan tanpa identitas artifact yang eksplisit.

### Issue — MinIO Client Receives Empty Alias

#### Symptom

Stage download gagal ketika MinIO Client mengonfigurasi alias:

```text
mc: <ERROR> Invalid alias. Alias `` should have alphanumeric characters
```

#### Root Cause

`deployment/CONFIG` awalnya membuat shell variables tanpa mengekspornya. Opsi `podman run --env MINIO_ALIAS` hanya meneruskan exported environment variable sehingga nilai `MINIO_ALIAS`, `MINIO_BUCKET`, dan `MINIO_URL` kosong di dalam MinIO Client container.

#### Resolution

Seluruh konfigurasi non-secret pada `deployment/CONFIG` dideklarasikan menggunakan `export`:

```bash
export MINIO_ALIAS=artifact_storage
export MINIO_BUCKET=personal-site
export MINIO_URL=http://host.containers.internal:9000
```

Dengan demikian, Jenkins shell dan child container menerima nilai konfigurasi yang sama. Secret MinIO tetap berasal dari Jenkins Credentials.

### Issue — Artifact Does Not Contain public/index.html

#### Symptom

Stage artifact verification berhasil membaca dan mengekstrak archive, kemudian gagal pada:

```bash
test -s deploy-staging/public/index.html
```

#### Investigation

Artifact `personal-site-59.tar.gz` hanya berisi output XML seperti:

```text
public/sitemap.xml
public/index.xml
public/articles/index.xml
public/categories/index.xml
public/tags/index.xml
```

Log CI build 59 menunjukkan Hugo tidak menemukan layout HTML. Workspace CI juga menunjukkan submodule `themes/ananke` belum diinisialisasi. Selain itu, build image menggunakan Hugo `0.111.3`, sedangkan Ananke yang dipin pada repository mensyaratkan Hugo minimal `0.160.0`.

#### Root Cause

Pipeline CI membangun source tanpa theme submodule dan menggunakan versi Hugo yang tidak kompatibel dengan requirement theme. Hugo tetap menghasilkan output XML sehingga build tampak berhasil, tetapi artifact tidak layak di-deploy.

#### Resolution

Pipeline CI diperbarui untuk:

1. menyinkronkan dan menginisialisasi `themes/ananke`;
2. menggunakan official image `ghcr.io/gohugoio/hugo:v0.160.1`; dan
3. menjalankan `test -s public/index.html` segera setelah Hugo build.

Dengan validasi tersebut, pipeline CI gagal sebelum packaging dan publish jika static HTML tidak terbentuk. Artifact build 59 tidak digunakan kembali; deployment harus memakai artifact dari CI build baru yang berhasil.

### Issue — CI MinIO Client Receives Empty Artifact Path

#### Symptom

CI build mencapai stage Publish Artifact, tetapi `mc cp` gagal:

```text
mc: <ERROR> Unable to prepare URL for copying. Invalid path, path cannot be empty
```

#### Root Cause

`ARTIFACT_NAME` dihitung di dalam shell stage tetapi tidak diekspor. Opsi `podman run --env ARTIFACT_NAME` kemudian meneruskan nilai kosong ke MinIO Client container.

#### Resolution

CI mendeklarasikan nama artifact sebagai exported variable sebelum packaging dan publish:

```bash
export ARTIFACT_NAME="${ARTIFACT_PREFIX}-${BUILD_NUMBER}.tar.gz"
```

MinIO Client sekarang menerima source dan destination object path yang lengkap.

### Issue — Existing Podman Volume Returns Exit Code 125

#### Symptom

Stage Prepare Rollback gagal ketika volume sudah tersedia:

```text
Error: volume with name www-personal-site already exists
script returned exit code 125
```

#### Root Cause

Implementasi menganggap `podman volume create` idempotent. Versi Podman pada deployment agent mengembalikan error ketika named volume sudah ada.

#### Resolution

`Jenkinsfile.cd` dan `deployment/deploy.sh` memeriksa volume sebelum membuatnya:

```bash
if ! podman volume exists "$CONTENT_VOLUME"; then
    podman volume create "$CONTENT_VOLUME" >/dev/null
fi
```

Volume yang sudah tersedia dipertahankan dan hanya dibuat pada deployment pertama.

### Issue — Container Health Status Remains Empty

#### Symptom

HTTP validation berhasil, tetapi health status selalu kosong hingga pipeline timeout:

```text
health_status=
```

#### Investigation

Runtime inspection menunjukkan image dan container tidak membawa healthcheck metadata:

```text
Image Healthcheck: null
Container Healthcheck: null
```

NGINX sendiri berhasil start dan HTTP port `8091` sempat memberikan respons sukses. Kegagalan berasal dari pipeline yang menunggu status health yang tidak pernah dikonfigurasi.

#### Resolution

`deployment/deploy.sh` menetapkan healthcheck pada saat container instance dibuat:

```bash
--health-cmd 'curl -fsS http://localhost/ || exit 1' \
--health-interval 10s \
--health-timeout 5s \
--health-start-period 10s \
--health-retries 3
```

Pipeline juga memverifikasi keberadaan healthcheck configuration sebelum menunggu status `healthy`, sehingga konfigurasi yang hilang menghasilkan error langsung dan bukan penantian 90 detik.

### Issue — Container Stops After Successful Deployment

#### Symptom

Pipeline dan health validation berhasil, tetapi website tidak dapat diakses melalui port `8091`. Pemeriksaan runtime menunjukkan container sudah berhenti:

```text
personal-site-web  Exited (0)
```

Port mapping tetap tercatat sebagai `0.0.0.0:8091->80/tcp`, tetapi tidak ada proses container yang mendengarkan port tersebut.

#### Root Cause

Container dibuat sebagai proses turunan dari Jenkins shell step. Setelah step selesai, Jenkins ProcessTreeKiller dapat menganggap proses runtime Podman sebagai bagian dari proses build yang harus dihentikan. Container berhenti secara normal dengan exit code `0` meskipun deployment dan healthcheck sebelumnya berhasil.

#### Resolution

`deployment/deploy.sh` memberi cookie khusus ketika membuat detached container:

```bash
JENKINS_NODE_COOKIE=dontKillMe podman run --detach ...
```

Cookie tersebut memisahkan proses runtime dari process tree build Jenkins sehingga container tetap berjalan setelah pipeline selesai.

## Jenkins Job Configuration

| Setting | Value |
| --- | --- |
| Item type | Pipeline |
| Suggested item name | `personal-site-cd` |
| Definition | Pipeline script from SCM |
| SCM | Git repository `personal-site` |
| Branch | `*/main` |
| Script Path | `Jenkinsfile.cd` |
| Agent label | `builder-01` |
| Initial trigger | Manual |

Trigger awal dibuat manual agar operator dapat memilih `ARTIFACT_NAME` secara eksplisit. Trigger otomatis dari CI ditambahkan setelah deployment manual berhasil diverifikasi.

## Credential Handling

- Credential MinIO menggunakan Jenkins credential ID `minio-root`.
- Username dan password hanya tersedia selama stage download.
- Credential diteruskan sebagai environment variable ke ephemeral MinIO Client container.
- Pipeline tidak menulis credential ke `Jenkinsfile.cd`, artifact, metadata, atau log.

## Failure and Rollback Behaviour

| Failure Point | Pipeline Behaviour |
| --- | --- |
| Parameter invalid | Gagal sebelum MinIO diakses. |
| Download gagal | Gagal tanpa mengubah volume atau container. |
| Artifact invalid | Gagal sebelum volume diubah. |
| Volume population gagal | Gagal dan tidak menjalankan deployment baru. |
| Container gagal start | Gagal dan tampilkan log container. |
| HTTP validation gagal | Gagal dan tandai deployment untuk rollback. |

Rollback menggunakan backup isi volume sebelumnya untuk mengisi ulang `www-personal-site`, kemudian menjalankan kembali NGINX melalui `deployment/deploy.sh`.

## Verification

| Item | Expected Result | Status |
| --- | --- | --- |
| `Jenkinsfile.cd` tersedia | File tersimpan pada repository `personal-site`. | ✅ Verified |
| Job menggunakan agent yang benar | Job berjalan pada label `builder-01`. | ✅ Verified |
| Parameter artefak tervalidasi | Hanya pola `personal-site-<BUILD_NUMBER>.tar.gz` diterima. | ✅ Verified |
| MinIO dapat diakses | Agent dapat mengunduh artefak melalui configured endpoint. | ✅ Verified |
| Artifact valid | `public/index.html` tersedia di staging. | ✅ Verified |
| Volume terisi | `www-personal-site` berisi static website hasil Hugo. | ✅ Verified |
| NGINX menggunakan volume read-only | `/var/www/html` berasal dari `www-personal-site` dengan `RW=false`. | ✅ Verified |
| Container sehat | Healthcheck container mencapai status `healthy`. | ✅ Verified |
| Website dapat diakses | HTTP port `8091` memberikan respons sukses. | ✅ Verified |

## Next Steps

1. Menentukan apakah pipeline CI akan memicu job CD secara otomatis atau deployment tetap dijalankan manual.
2. Melakukan deployment artifact berikutnya untuk memverifikasi mekanisme penggantian konten dan backup versi sebelumnya.
3. Melakukan controlled failure test untuk memverifikasi jalur rollback secara end-to-end.

## Notes

- `Jenkinsfile` yang sudah ada tetap digunakan khusus untuk CI dan tidak diubah menjadi pipeline gabungan.
- Nama agent `builder-01` pada dokumen ini diperlakukan sebagai Jenkins label sesuai informasi environment.
- Endpoint MinIO `http://host.containers.internal:9000` harus dipertahankan selama dapat diakses dari agent `builder-01`.
- Pipeline pertama dijalankan manual untuk mencegah deployment otomatis sebelum seluruh validasi dan rollback siap.
- Initial deployment telah berhasil. Container `personal-site-web` berjalan menggunakan volume `www-personal-site`, healthcheck berhasil, dan website dapat diakses melalui HTTP port `8091`.

## Related Documentation

- [TN-002 — Prepare NGINX Runtime](TN-002-prepare-nginx-runtime-for-podman-volume-deployment.md)
- [Continuous Deployment Engineering Journal](index.md)
- [Personal Site Operations](../../operations/index.md)

# WK-001 — Build Pipeline

## Objective

Mengimplementasikan **Build Stage** pertama pada **Delivery Pipeline** menggunakan Jenkins.

---

## Scope

Worklog ini berfokus pada implementasi **Build Stage**.

Tahap **Deployment** dan **Validation** akan didokumentasikan pada worklog berikutnya.

---

## Current Environment

Kondisi lingkungan implementasi saat memulai pekerjaan.

| Component | Status | Notes |
|-----------|--------|-------|
| Personal Site | ✅ Ready | Source code tersedia pada Gitea Repository. |
| Gitea | ✅ Ready | Repository dapat diakses oleh Jenkins. |
| Jenkins | ✅ Ready | Jenkins Controller telah berhasil di-deploy dan dapat diakses. |
| Container Runtime | ✅ Ready | Podman tersedia pada Jenkins Controller melalui image `jenkins-podman`. |
| Build Pipeline | 🚧 In Progress | Pipeline pertama akan dibuat pada worklog ini. |

---

## Planned Activities

- [ ] Merancang workflow Build Pipeline.
- [ ] Membuat Jenkins Pipeline (*Pipeline as Code*).
- [ ] Checkout source code dari Gitea Repository.
- [ ] Mengonfigurasi **Containerized Build Environment**.
- [ ] Menjalankan proses Hugo Build menggunakan **Build Container**.
- [ ] Memverifikasi hasil Build Pipeline.
- [ ] Menyimpan Build Artifact.

---

## Architecture & Pipeline Flow

### Architecture Workflow

```text
                        +----------------------+
                        |      Developer       |
                        +----------+-----------+
                                   |
                                   | Git Push
                                   |
                                   v
                        +----------------------+
                        |   Gitea Repository   |
                        +----------+-----------+
                                   |
                                   | HTTPS + Personal Access Token
                                   |
                                   v
                     +---------------------------+
                     |      Jenkins Controller   |
                     |---------------------------|
                     | Pipeline Orchestration    |
                     +------------+--------------+
                                  |
                                  | Jenkins Remoting (SSH Agent)
                                  |
                                  v
                  +-------------------------------+
                  |      Builder01 (Agent)        |
                  |-------------------------------|
                  | Workspace                     |
                  | Podman                        |
                  | Hugo Container                |
                  | MinIO Client Container        |
                  +---------------+---------------+
                                  |
                     Build Artifact (.tar.gz)
                                  |
                                  v
                        +----------------------+
                        |   MinIO Object Store |
                        +----------------------+
```

### Detailed Pipeline Flow Diagram

![Detailed Pipeline Flow Diagram](../assets/images/personal-site-ci-pipeline.svg)

---

## Technical Notes

### TN-001 — Start Jenkins Container

#### Objective

Menjalankan kembali container Jenkins yang telah dibuat sebelumnya sehingga siap digunakan untuk implementasi Build Pipeline.

#### Background

Jenkins telah di-deploy sebagai container Podman pada implementasi sebelumnya. Oleh karena itu, tidak diperlukan pembuatan container baru. Cukup menjalankan container yang sudah tersedia.

#### Prerequisites

N/A

#### Engineering Decision

**ED-001 — Menggunakan Jenkins sebagai Automation Server**

**Decision**

Menggunakan Jenkins sebagai automation server.

**Reason**

- Pipeline as Code.
- Mudah diintegrasikan dengan Gitea.
- Menjadi fondasi Delivery Pipeline.
- Mendukung pengembangan pipeline pada tahap berikutnya.

#### Implementation

Container Jenkins dijalankan kembali menggunakan Podman. Setelah container berhasil dijalankan, dilakukan verifikasi untuk memastikan proses startup berjalan dengan normal dan Jenkins siap digunakan untuk implementasi Build Pipeline.

#### Commands

```bash
podman ps -a
podman start jenkins
podman ps
podman logs --tail 20 jenkins
```

#### Verification

- Container Jenkins berhasil dijalankan.
- Status container berubah menjadi **running**.
- Tidak ditemukan error pada proses startup.
- Jenkins siap diakses melalui web browser.

#### Issue

None.

#### Root Cause

None.

#### Resolution

None.

#### Conclusion

Container Jenkins berhasil dijalankan kembali dan dinyatakan siap untuk implementasi Build Pipeline.

#### Notes

Technical Note ini hanya mencakup proses menjalankan kembali container Jenkins yang telah ada. Konfigurasi Jenkins dan pembuatan Build Pipeline akan didokumentasikan pada Technical Note berikutnya.

---

### TN-002 — Verify Jenkins Environment

#### Objective

Memastikan Jenkins telah berjalan dengan baik dan siap digunakan untuk implementasi Build Pipeline.

#### Background

Sebelum membuat Build Pipeline, perlu dilakukan verifikasi terhadap lingkungan Jenkins untuk memastikan seluruh komponen berfungsi dengan normal. Verifikasi ini bertujuan mengurangi risiko kegagalan yang disebabkan oleh masalah konfigurasi atau environment.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- Container Jenkins dalam kondisi **running**.
- Jenkins dapat diakses melalui web browser.

#### Implementation

Verifikasi dilakukan menggunakan **Jenkins Web UI** dengan langkah-langkah berikut:

1. Akses Jenkins melalui web browser.
2. Login menggunakan akun administrator.
3. Pastikan Dashboard Jenkins dapat ditampilkan tanpa error.
4. Buka menu **Manage Jenkins**.
5. Verifikasi informasi instalasi Jenkins.
6. Pastikan tidak terdapat peringatan atau konfigurasi yang bermasalah.
7. Verifikasi direktori `JENKINS_HOME`.
8. Pastikan Jenkins siap digunakan untuk membuat Pipeline.

#### Verification

| Item | Status | Notes |
|------|--------|-------|
| Jenkins Web UI dapat diakses | ✅ | Berhasil diakses melalui web browser. |
| Login Administrator berhasil | ✅ | Login berhasil menggunakan akun administrator. |
| Dashboard tampil normal | ✅ | Tidak ditemukan error pada dashboard. |
| Manage Jenkins dapat diakses | ✅ | Menu dapat diakses tanpa kendala. |
| Tidak terdapat startup error | ✅ | Tidak ditemukan error yang memengaruhi operasional Jenkins. |
| JENKINS_HOME terinisialisasi | ✅ | Direktori berhasil terinisialisasi dengan baik. |
| Jenkins siap membuat Pipeline | ✅ | Environment siap untuk implementasi Build Pipeline. |

#### Engineering Decision

None.

#### Environment Information

| Item | Value |
|------|-------|
| Jenkins URL | |
| Jenkins Version | |
| Java Version | |
| Jenkins Home | |
| Deployment Method | Podman Container |
| Jenkins Image | `jenkins-podman` |
| Container Runtime | Podman |

#### Issue

None.

#### Root Cause

None.

#### Resolution

None.

#### Conclusion

Verifikasi lingkungan Jenkins berhasil diselesaikan. Seluruh komponen utama berfungsi dengan baik dan tidak ditemukan kendala yang dapat menghambat implementasi Build Pipeline. Jenkins dinyatakan siap untuk digunakan pada tahap implementasi berikutnya.

#### Notes

Informasi detail mengenai konfigurasi Jenkins, seperti URL, versi Jenkins, versi Java, dan lokasi `JENKINS_HOME`, akan didokumentasikan apabila diperlukan pada Technical Note berikutnya.

---

### TN-003 — Install Required Plugins

#### Objective

Menginstal plugin yang diperlukan untuk mendukung implementasi Build Pipeline pada Jenkins.

#### Background

Jenkins menyediakan berbagai plugin untuk memperluas fungsionalitasnya. Sebelum Build Pipeline dibuat, perlu dipastikan bahwa plugin yang dibutuhkan telah terpasang sehingga Jenkins dapat berintegrasi dengan Git repository dan menjalankan Pipeline.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- Jenkins dapat diakses menggunakan akun administrator.

#### Implementation

Plugin diinstal menggunakan **Jenkins Plugin Manager** dengan langkah-langkah berikut:

1. Login ke Jenkins menggunakan akun administrator.
2. Buka menu **Manage Jenkins**.
3. Pilih **Plugins**.
4. Instal plugin berikut:
    - Git
    - Pipeline
    - GitHub Branch Source
    - Credentials
    - SSH Agent
5. Restart Jenkins apabila diminta.
6. Setelah proses restart, Jenkins tidak dapat diakses karena container berubah menjadi status **Exited**.
7. Jalankan kembali container menggunakan:

```bash
podman start jenkins
```

8. Login kembali ke Jenkins.
9. Verifikasi seluruh plugin berhasil diinstal dan aktif.

#### Verification

| Item | Status | Notes |
|------|--------|-------|
| Seluruh plugin berhasil diinstal | ✅ | Git, Pipeline, GitHub Branch Source, Credentials, dan SSH Agent berhasil diinstal. |
| Tidak terdapat dependency error | ✅ | Seluruh dependency berhasil dipenuhi. |
| Jenkins dapat diakses kembali | ✅ | Jenkins kembali dapat diakses setelah container dijalankan. |
| Plugin siap digunakan | ✅ | Seluruh plugin aktif dan siap digunakan. |

#### Enginering Decision

None.

#### Issue

Restart Jenkins melalui Web UI menyebabkan container berubah menjadi status **Exited**, sehingga Jenkins tidak dapat diakses.

#### Root Cause

Jenkins dijalankan sebagai proses utama (PID 1) di dalam container Podman. Ketika proses restart dilakukan melalui Jenkins Web UI, proses utama berhenti sehingga container ikut berhenti.

#### Resolution

Jalankan kembali container Jenkins menggunakan Podman.

```bash
podman start jenkins
```

#### Conclusion

Seluruh plugin yang diperlukan berhasil diinstal dan aktif. Jenkins kembali dapat digunakan setelah container dijalankan kembali menggunakan Podman.

#### Notes

- Hanya plugin yang diperlukan untuk implementasi Build Pipeline yang diinstal. Plugin tambahan akan dipertimbangkan pada tahap implementasi berikutnya apabila diperlukan.
- Restart Jenkins pada deployment berbasis container dikelola menggunakan Podman sebagai container runtime.

---

### TN-004 — Configure Gitea Repository Access

#### Objective

Mengonfigurasi Jenkins agar dapat mengakses repository Gitea yang digunakan sebagai source code Build Pipeline.

#### Background

Build Pipeline memerlukan akses ke source code yang tersimpan pada repository Gitea. Oleh karena itu, Jenkins harus dikonfigurasi agar dapat melakukan autentikasi dan mengakses repository tersebut sebelum Pipeline dibuat.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- Repository Gitea telah tersedia.
- Jenkins dapat diakses menggunakan akun administrator.

#### Implementation

Konfigurasi akses repository dilakukan menggunakan **SSH Key Authentication** sesuai dengan **PS-ADR-0006**.

Langkah-langkah implementasi sebagai berikut:

1. Pastikan pasangan **SSH Key** telah tersedia pada environment Jenkins.
2. Apabila SSH Key belum tersedia, buat pasangan SSH Key sesuai prosedur yang berlaku.
3. Salin **Public Key** (`id_*.pub`).
4. Daftarkan **Public Key** pada akun Gitea.
    1. Login ke Gitea menggunakan akun yang akan digunakan oleh Build Pipeline.
    2. Buka **Settings → SSH / GPG Keys**.
    3. Pada bagian **Manage SSH Keys**, pilih **Add Key**.
    4. Masukkan **Title** sesuai kebutuhan.
    5. Tempel (*paste*) **Public Key** pada field **Content**.
    6. Klik **Add Key** untuk menyimpan konfigurasi.
5. Tambahkan **SSH Credential** pada Jenkins.
    1. Login ke Jenkins menggunakan akun administrator.
    2. Buka **Manage Jenkins → Credentials**.
    3. Pilih **Add Credentials**.
    4. Pada **Select a type of credential**, pilih **SSH Username with private key**.
    5. Klik **Next**.
    6. Isi informasi credential:
    - **Scope**: `Global`
    - **ID**: `gitea-ssh` *(standar `credentialsId` yang digunakan pada Build Pipeline)*
    - **Description**: `SSH Key for Gitea Repository`
    - **Username**: Masukkan SSH Username yang digunakan pada **SSH Clone URL** repository.
        Contoh:
        ```text
        git@localhost:gitadm/personal-site.git
        ```
        Pada contoh di atas, SSH Username yang digunakan adalah `git`.
    - **Treat username as secret**: Aktifkan (*checked*).
    - **Private Key**: Pilih **Enter directly**, kemudian masukkan **Private Key** yang berpasangan dengan Public Key yang telah didaftarkan pada Gitea.
    - **Passphrase**: Isi apabila Private Key menggunakan passphrase.
    7. Klik **Create**.
6. Verifikasi credential berhasil dibuat dan dapat digunakan.
7. Lakukan pengujian autentikasi SSH ke repository Gitea.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| Public Key berhasil didaftarkan pada Gitea | ✅ | Public Key berhasil ditambahkan pada akun Gitea. |
| SSH Credential berhasil dibuat | ✅ | Credential bertipe **SSH Username with private key** berhasil dibuat. |
| Private Key berhasil dikonfigurasi | ✅ | Private Key berhasil disimpan pada Jenkins Credentials. |
| Autentikasi SSH berhasil | ✅ | Berhasil melakukan autentikasi menggunakan `ssh -T git@gitea`. |
| Credential siap digunakan | ✅ | Credential berhasil diverifikasi dan siap digunakan pada implementasi Build Pipeline. |

#### Engineering Decision

Technical Note ini mengimplementasikan keputusan arsitektur berikut:

- **PS-ADR-0006** — Use SSH Key Authentication for Gitea Repository

#### Issue

None.

#### Root Cause

None.

#### Resolution

None.

#### Conclusion

Konfigurasi **SSH Authentication** berhasil diselesaikan.

Jenkins berhasil melakukan autentikasi ke repository Gitea menggunakan **SSH Key Authentication** tanpa menggunakan password. Credential telah berhasil dibuat dan diverifikasi sehingga siap digunakan pada implementasi Build Pipeline.

#### Notes

Pembuatan pasangan SSH Key mengikuti prosedur pada dokumen berikut:

- **How-To — Create SSH Key for Jenkins**

---

### TN-007 — Create Build Pipeline

#### Objective

Membuat Jenkins Build Pipeline menggunakan konsep **Pipeline as Code** untuk mendukung proses Build pada Delivery Pipeline.

#### Background

Setelah Jenkins berhasil dikonfigurasi dan koneksi ke repository Gitea telah diverifikasi menggunakan SSH Authentication, langkah berikutnya adalah membuat Build Pipeline.

Pipeline akan menggunakan file **Jenkinsfile** yang tersimpan pada repository sehingga konfigurasi pipeline menjadi bagian dari source code dan dapat dikelola menggunakan version control.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- TN-004 telah berhasil diselesaikan.
- Repository Gitea telah dapat diakses menggunakan SSH Authentication.

#### Implementation

Langkah-langkah implementasi sebagai berikut.

① Login ke Jenkins menggunakan akun administrator.

---

② Pilih **New Item**.

---

③ Masukkan nama **Build Pipeline**.

Contoh:

```text
personal-site-ci
```

---

④ Pilih tipe **Pipeline**.

---

⑤ Klik **OK**.

---

⑥ Konfigurasikan **Pipeline**.

1. Pada **Definition**, pilih **Pipeline script from SCM**.
2. Pada **SCM**, pilih **Git**.
3. Pada **Repository URL**, masukkan URL repository Gitea menggunakan protokol SSH.

    Contoh:

    ```text
    git@gitea:gitadm/personal-site.git
    ```

4. Pada **Credentials**, pilih credential SSH yang telah dibuat pada **TN-004**.

    Contoh:

    ```text
    SSH Key for Gitea Repository
    ```

5. Pada **Branch Specifier**, masukkan branch yang akan digunakan.

    Contoh:

    ```text
    */main
    ```

6. Pada **Script Path**, masukkan lokasi file **Jenkinsfile** pada repository.

    Contoh:

    ```text
    Jenkinsfile
    ```

7. Biarkan konfigurasi lainnya menggunakan nilai bawaan (*default*).

---

⑦ Klik **Save**.

---

⑧ Verifikasi Build Pipeline berhasil dibuat.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| Build Pipeline berhasil dibuat | ✅ | Pipeline `personal-site-build` berhasil dibuat. |
| Pipeline bertipe **Pipeline** | ✅ | Menggunakan tipe **Pipeline**. |
| Konfigurasi Pipeline berhasil disimpan | ✅ | Konfigurasi berhasil disimpan tanpa error. |
| Pipeline dapat diakses kembali | ✅ | Halaman konfigurasi Pipeline dapat diakses kembali. |
| Pipeline siap dikonfigurasi lebih lanjut | ✅ | Siap digunakan pada implementasi Technical Note berikutnya. |

#### Conclusion

Belum dilakukan.

#### Notes

Technical Note ini hanya mencakup proses pembuatan Build Pipeline. Konfigurasi repository, Jenkinsfile, dan proses Build akan dibahas pada Technical Note berikutnya.

---

### TN-006 — Create Jenkinsfile

#### Objective

Membuat file **Jenkinsfile** sebagai definisi Build Pipeline menggunakan konsep **Pipeline as Code**.

#### Background

Build Pipeline akan didefinisikan menggunakan file **Jenkinsfile** yang disimpan pada repository.

Dengan pendekatan ini, konfigurasi Pipeline menjadi bagian dari source code sehingga dapat dikelola menggunakan version control.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- TN-004 telah berhasil diselesaikan.
- TN-005 telah berhasil diselesaikan.

#### Engineering Decision

Technical Note ini mengimplementasikan keputusan arsitektur berikut:

- **PS-ADR-0008** — Adopt Stage-Based CI Pipeline

#### Implementation

Langkah-langkah implementasi sebagai berikut:

① Buka repository `personal-site` pada local workspace.

```bash
cd ~/git/personal-site
```

---

② Buat file `Jenkinsfile` pada root repository.

```bash
touch Jenkinsfile
```

---

③ Buka file `Jenkinsfile` menggunakan editor yang digunakan.

Contoh menggunakan Visual Studio Code:

```bash
code Jenkinsfile
```

---

④ Implementasikan definisi CI Pipeline pada file `Jenkinsfile`.

```groovy
pipeline {

    agent any

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Verify Build Environment') {
            steps {
                sh 'hugo version'
            }
        }

        stage('Build Static Website') {
            steps {
                sh 'hugo'
            }
        }

        stage('Archive Build Artifact') {
            steps {
                archiveArtifacts artifacts: 'public/**', fingerprint: true
            }
        }

    }

}
```

!!! note "Pipeline Implementation Roadmap"

    Jenkinsfile di atas merupakan implementasi awal dari **Stage-Based CI Pipeline** sesuai dengan **PS-ADR-0008 — Adopt Stage-Based CI Pipeline**.

    Implementasi setiap stage akan dijelaskan secara bertahap pada Technical Note berikut.

    | Stage | Technical Note |
    |-------|----------------|
    | Checkout Source Code | TN-007 |
    | Verify Build Environment | TN-007 |
    | Configure Containerized Build Environment | TN-008 |
    | Build Static Website | TN-009 |
    | Archive Build Artifact | TN-010 |

    Pendekatan ini memungkinkan setiap stage diimplementasikan, diverifikasi, dan dikembangkan secara bertahap tanpa mengubah struktur utama CI Pipeline.

---

⑤ Simpan perubahan pada file `Jenkinsfile`.

---

⑥ Tambahkan file `Jenkinsfile` ke Git staging area.

```bash
git add Jenkinsfile
```

Verifikasi status repository.

```bash
git status
```

---

⑦ Commit perubahan.

```bash
git commit -m "Add Jenkinsfile"
```

---

⑧ Push perubahan ke repository Gitea.

```bash
git push origin main
```

---

⑨ Verifikasi file `Jenkinsfile` berhasil tersimpan pada repository Gitea.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| File `Jenkinsfile` berhasil dibuat | ✅ | Tersimpan pada root repository. |
| Definisi CI Pipeline berhasil diimplementasikan | ✅ | Jenkinsfile berisi struktur CI Pipeline sesuai **PS-ADR-0008**. |
| File `Jenkinsfile` berhasil dikomit | ✅ | Perubahan berhasil dikomit ke Git. |
| File `Jenkinsfile` berhasil dipush | ✅ | Perubahan berhasil dipush ke repository Gitea. |
| File `Jenkinsfile` tersedia pada repository | ✅ | Jenkinsfile tersedia pada root repository dan siap digunakan oleh Jenkins Pipeline. |

#### Conclusion

File **Jenkinsfile** berhasil dibuat sebagai implementasi **Pipeline as Code** dan disimpan pada root repository `personal-site`.

Definisi awal **CI Pipeline** telah berhasil diimplementasikan sesuai dengan **PS-ADR-0008 — Adopt Stage-Based CI Pipeline**. Jenkinsfile telah dikomit, dipush ke repository Gitea, dan siap digunakan pada proses eksekusi CI Pipeline yang akan dibahas pada Technical Note berikutnya.

#### Notes

Technical Note ini hanya mencakup proses pembuatan **Jenkinsfile**. Eksekusi Build Pipeline akan dibahas pada Technical Note berikutnya.

---

### TN-007 — Execute CI Pipeline

#### Objective

Menjalankan **CI Pipeline** untuk memverifikasi bahwa **Jenkinsfile** dapat dieksekusi oleh Jenkins sesuai dengan konfigurasi yang telah dibuat.

#### Background

Pada Technical Note sebelumnya, file **Jenkinsfile** telah berhasil dibuat dan disimpan pada repository sebagai implementasi **Pipeline as Code**.

Technical Note ini berfokus pada proses eksekusi **CI Pipeline** serta verifikasi bahwa Jenkins berhasil membaca dan menjalankan definisi pipeline yang terdapat pada file **Jenkinsfile**.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- TN-004 telah berhasil diselesaikan.
- TN-005 telah berhasil diselesaikan.
- TN-006 telah berhasil diselesaikan.

#### Engineering Decision

Technical Note ini mengimplementasikan keputusan arsitektur berikut:

- **PS-ADR-0008** — Adopt Stage-Based CI Pipeline

#### Implementation

Langkah-langkah implementasi sebagai berikut.

##### Execute CI Pipeline

① Login ke Jenkins menggunakan akun administrator.

---

② Buka Build Pipeline **`personal-site-ci`**.

---

③ Pilih **Build Now** untuk menjalankan CI Pipeline.

---

④ Tunggu hingga proses build selesai.

---

⑤ Buka **Stages** untuk melihat hasil eksekusi setiap stage.

---

⑥ Buka **Console Output** untuk melihat detail hasil eksekusi Build Pipeline.

---

##### Analyze Pipeline Execution

⑦ Verifikasi Jenkins berhasil melakukan proses **Checkout Source Code**.

---

⑧ Verifikasi Jenkins berhasil membaca dan menjalankan file **Jenkinsfile**.

---

⑨ Analisis hasil eksekusi setiap stage pada CI Pipeline.

---

⑩ Identifikasi apabila terdapat stage yang gagal dan catat penyebab kegagalannya berdasarkan **Console Output**.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| CI Pipeline berhasil dijalankan | ✅ | Build Pipeline berhasil dieksekusi. |
| Jenkins berhasil melakukan proses checkout source code | ✅ | Source code berhasil diambil dari repository Gitea. |
| Jenkins berhasil membaca file `Jenkinsfile` | ✅ | Pipeline berhasil dijalankan menggunakan Jenkinsfile dari repository. |
| Hasil eksekusi setiap stage berhasil dianalisis | ✅ | Stage **Verify Build Environment** gagal karena perintah `hugo` tidak ditemukan pada Build Environment. |
| Console Output berhasil ditampilkan | ✅ | Console Output berhasil digunakan untuk analisis hasil build. |

#### Conclusion

CI Pipeline berhasil dijalankan dan Jenkins berhasil mengeksekusi file **Jenkinsfile** yang tersimpan pada repository.

Hasil eksekusi menunjukkan bahwa proses **Checkout Source Code** berhasil dilakukan. Namun, stage **Verify Build Environment** mendeteksi bahwa perintah `hugo` belum tersedia pada Build Environment sehingga proses build tidak dapat dilanjutkan.

Hasil tersebut menjadi dasar untuk mengimplementasikan **Containerized Pipeline Environment** menggunakan **Podman** sesuai dengan **PS-ADR-0009 — Use Containerized Pipeline Environment**.

#### Notes  

Technical Note ini hanya membahas proses eksekusi awal **CI Pipeline** dan analisis hasil build.

Persiapan Build Environment agar memenuhi kebutuhan CI Pipeline akan dibahas pada **TN-008 — Prepare Build Environment**.

---

### TN-008 — Configure Jenkins SSH Build Agent

#### Objective

Membangun Remote Build Agent yang akan digunakan Jenkins untuk menjalankan proses build di luar Jenkins Controller.

Dengan memisahkan Build Agent dari Jenkins Controller, proses build menjadi lebih aman, lebih mudah diskalakan, dan mengikuti praktik CI/CD yang umum digunakan pada lingkungan enterprise.

#### Background

Pada implementasi awal, Jenkins Controller menjalankan seluruh proses build secara langsung menggunakan Podman yang berada di dalam container Jenkins.

Pendekatan tersebut menimbulkan beberapa keterbatasan, di antaranya:

- Rootless Podman di dalam container Jenkins memerlukan nested user namespace.
- Terjadi error `newuidmap` saat menjalankan container Hugo.
- Jenkins Controller menjadi memiliki tanggung jawab ganda sebagai Pipeline Orchestrator sekaligus Build Executor.

Untuk mengatasi permasalahan tersebut, arsitektur pipeline diubah dengan menambahkan Remote Build Agent.

Pada arsitektur baru:

- Jenkins Controller hanya bertugas mengelola pipeline.
- Seluruh proses build dijalankan pada Build Agent.
- Build Agent menjalankan Podman secara native (rootless).
- Hugo dijalankan menggunakan Container sehingga tidak perlu di-install pada host.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- TN-004 telah berhasil diselesaikan.
- TN-005 telah berhasil diselesaikan.
- TN-006 telah berhasil diselesaikan.
- TN-007 telah berhasil diselesaikan.

#### Engineering Decision

Technical Note ini mengimplementasikan keputusan arsitektur berikut:

- **PS-ADR-0009** — Use Containerized Pipeline Environment

#### Implementation

Langkah-langkah implementasi sebagai berikut.

① Buka repository **personal-site** pada local workspace.

Contoh:

```bash
cd ~/git/personal-site
```

---

② Buka file **Jenkinsfile**.

Contoh:

```bash
code Jenkinsfile
```

---

③ Perbarui stage **Build Static Website** agar menggunakan **Containerized Build Environment**.

Contoh:

```groovy
stage('Build Static Website') {
    steps {
        sh '''
        podman run \
            --rm \
            --name "hugo-build-${BUILD_NUMBER}" \
            --pull=missing \
            -u "$(id -u):$(id -g)" \
            -e HUGO_CACHEDIR=/tmp \
            -v "$WORKSPACE:/src" \
            -w /src \
            klakegg/hugo:ext-alpine \
            hugo \
                --minify \
                --destination public
        '''
    }
}
```

!!! info "Why this configuration?"

    Parameter yang digunakan pada perintah di atas memiliki tujuan sebagai berikut.

    - **`--rm`**
        - Menghapus Build Container secara otomatis setelah proses build selesai.
        - Menjaga Build Environment tetap bersifat **ephemeral** sehingga tidak meninggalkan container yang tidak digunakan.

    - **`--name "hugo-build-${BUILD_NUMBER}"`**
        - Memberikan nama container yang unik berdasarkan **Jenkins Build Number**.
        - Mendukung eksekusi Build Pipeline secara paralel tanpa konflik nama container.

    - **`--pull=missing`**
        - Mengunduh image hanya apabila image belum tersedia pada Jenkins Controller.
        - Mengurangi waktu build dan penggunaan bandwidth.

    - **`-u "$(id -u):$(id -g)"`**
        - Menjalankan proses build menggunakan **UID** dan **GID** Jenkins.
        - Memastikan file hasil build memiliki ownership yang benar pada Jenkins Workspace.

    - **`-e HUGO_CACHEDIR=/tmp`**
        - Menyimpan cache Hugo pada direktori sementara di dalam container.
        - Menghindari cache tersimpan pada Jenkins Workspace.

    - **`-v "$WORKSPACE:/src"`**
        - Melakukan **bind mount** Jenkins Workspace ke dalam Build Container.
        - Source code dapat diakses secara langsung tanpa proses penyalinan (*copy*).
        - Hasil build otomatis tersedia pada Jenkins Workspace.

    - **`-w /src`**
        - Menjadikan `/src` sebagai **working directory**.
        - Hugo dijalankan dari root project sehingga dapat menemukan file `hugo.toml`, direktori `content`, `themes`, serta komponen project lainnya.

    - **`klakegg/hugo:ext-alpine`**
        - Menggunakan image **Hugo Extended** yang telah menyediakan seluruh dependency yang diperlukan untuk proses build.

    - **`hugo --minify --destination public`**
        - Membangun static website menggunakan Hugo.
        - Mengaktifkan optimasi menggunakan `--minify`.
        - Menghasilkan Build Artifact pada direktori `public`.

---

④ Simpan perubahan **Jenkinsfile**.

---

⑤ Tambahkan perubahan ke Git staging area.

```bash
git add Jenkinsfile
```

---

⑥ Commit perubahan ke repository.

Contoh:

```bash
git commit -m "Configure containerized build environment"
```

---

⑦ Push perubahan ke repository Gitea.

Contoh:

```bash
git push origin main
```

---

##### Verification

⑧ Verifikasi perubahan **Jenkinsfile** berhasil dipush.

Contoh:

```bash
git status
```

Pastikan hasilnya:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

⑨ Verifikasi repository Gitea telah menampilkan perubahan **Jenkinsfile**.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| Stage **Build Static Website** berhasil diperbarui | ✅ | Stage berhasil diperbarui untuk menjalankan Build Container menggunakan Podman. |
| Jenkinsfile berhasil diperbarui | ✅ | Jenkinsfile berhasil dikonfigurasi menggunakan **Containerized Build Environment**. |
| Jenkinsfile berhasil dikomit | ✅ | Perubahan berhasil dikomit ke repository Git. |
| Jenkinsfile berhasil dipush | ✅ | Perubahan berhasil dipush ke repository Gitea. |
| Jenkinsfile telah menggunakan **Containerized Build Environment** | ✅ | Proses build dijalankan menggunakan Build Container melalui Podman sesuai **PS-ADR-0009**. |
| CI Pipeline siap dijalankan menggunakan Build Container | ✅ | Build Infrastructure telah siap menggunakan **jenkins-podman** sebagai Jenkins Controller dan Podman sebagai Container Runtime. |

#### Conclusion

Konfigurasi **Containerized Build Environment** berhasil diterapkan pada **CI Pipeline**.

Stage **Build Static Website** pada **Jenkinsfile** telah diperbarui sehingga proses build tidak lagi dijalankan secara langsung pada Jenkins Controller, melainkan menggunakan **Build Container** melalui **Podman** sebagai Container Runtime sesuai dengan **PS-ADR-0009 — Use Containerized Pipeline Environment**.

Seluruh perubahan berhasil dikomit dan dipush ke repository Gitea. CI Pipeline kini siap untuk menjalankan proses build menggunakan Build Container pada Technical Note berikutnya.

#### Notes

Technical Note ini hanya membahas konfigurasi **Containerized Build Environment** pada **CI Pipeline**.

Eksekusi Build Pipeline menggunakan Build Container akan dibahas pada **TN-009**.

---

### TN-009 — Execute Containerized Build

#### Objective

Menjalankan **CI Pipeline** menggunakan **Containerized Build Environment** serta memverifikasi bahwa proses build berhasil menghasilkan **Build Artifact** pada Jenkins Workspace.

#### Background

Pada Technical Note sebelumnya, stage **Build Static Website** telah diperbarui agar menggunakan **Build Container** melalui **Podman** sesuai dengan **PS-ADR-0009 — Use Containerized Pipeline Environment**.

Technical Note ini berfokus pada eksekusi Build Pipeline untuk memastikan Build Container berhasil dijalankan, Hugo berhasil membangun static website, serta Build Artifact berhasil dihasilkan pada Jenkins Workspace.

#### Prerequisites

- TN-001 telah berhasil diselesaikan.
- TN-002 telah berhasil diselesaikan.
- TN-003 telah berhasil diselesaikan.
- TN-004 telah berhasil diselesaikan.
- TN-005 telah berhasil diselesaikan.
- TN-006 telah berhasil diselesaikan.
- TN-007 telah berhasil diselesaikan.
- TN-008 telah berhasil diselesaikan.

#### Engineering Decision

Technical Note ini mengimplementasikan keputusan arsitektur berikut:

- **PS-ADR-0009** — Use Containerized Pipeline Environment

#### Implementation

Langkah-langkah implementasi sebagai berikut.

① Login ke Jenkins.

Contoh:

```text
http://jenkins:8080
```

---

② Buka Build Pipeline **personal-site-ci**.

---

③ Klik **Build Now** untuk menjalankan Build Pipeline.

---

④ Pantau proses Build Pipeline.

Pastikan seluruh stage berhasil dijalankan.

```text
Checkout Source Code
Verify Build Environment
Build Static Website
```

---

⑤ Buka **Console Output**.

---

⑥ Verifikasi stage **Build Static Website** berhasil dijalankan.

Pastikan Console Output menampilkan proses berikut.

- Build Container dijalankan menggunakan Podman.
- Image `klakegg/hugo:ext-alpine` digunakan sebagai Build Environment.
- Hugo berhasil membangun static website.

!!! success "Verification"

    Build berhasil dijalankan menggunakan **Build Container** dan bukan secara langsung pada Jenkins Controller.

    Hal ini dibuktikan dengan munculnya proses eksekusi `podman run` pada Console Output.

---

⑦ Verifikasi Build Artifact berhasil dihasilkan pada Jenkins Workspace.

Contoh:

```bash
ls -l public
```

Contoh keluaran:

```text
public/
├── index.html
├── 404.html
├── sitemap.xml
├── css/
├── js/
└── images/
```

!!! info "Build Artifact"

    Direktori `public` merupakan **Build Artifact** yang dihasilkan oleh Hugo.

    Pada Technical Note ini Build Artifact masih berada pada Jenkins Workspace.

    Build Artifact akan dipublikasikan ke **Artifact Storage** pada Technical Note berikutnya.

---

⑧ Pastikan Build Pipeline selesai dengan status berikut.

```text
SUCCESS
```

---

⑨ Verifikasi tidak terdapat container Build yang masih berjalan.

Contoh:

```bash
podman ps
```

Pastikan tidak terdapat container dengan nama:

```text
hugo-build-*
```

!!! info "Why no build container?"

    Build Container dijalankan menggunakan parameter `--rm`.

    Setelah proses build selesai, container akan dihapus secara otomatis sehingga Build Environment tetap bersifat **ephemeral** sesuai dengan **PS-ADR-0009**.

#### Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| Build Pipeline berhasil dijalankan | ⬜ | |
| Seluruh stage berhasil dieksekusi | ⬜ | |
| Build Container berhasil dijalankan menggunakan Podman | ⬜ | |
| Hugo berhasil membangun static website | ⬜ | |
| Build Artifact berhasil dihasilkan pada Jenkins Workspace | ⬜ | |
| Build Container dihapus secara otomatis setelah build selesai | ⬜ | |
| Build Pipeline selesai dengan status **SUCCESS** | ⬜ | |

#### Conclusion

Belum dilakukan.

#### Notes

Technical Note ini hanya membahas eksekusi **Containerized Build Environment** dan verifikasi bahwa Build Artifact berhasil dihasilkan pada Jenkins Workspace.

Publikasi **Build Artifact** ke **Artifact Storage** menggunakan **MinIO** akan dibahas pada **TN-010**.

---


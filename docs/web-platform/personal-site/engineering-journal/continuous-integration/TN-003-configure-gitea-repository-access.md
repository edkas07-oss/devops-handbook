# TN-003 — Configure Gitea Repository Access

## Objective

Mengonfigurasi Jenkins agar dapat mengakses repository Gitea yang berisi source code `personal-site` menggunakan mekanisme autentikasi yang aman.

## Background

Build Pipeline tergantung pada kemampuan Jenkins untuk mengambil kode sumber dari Gitea. Autentikasi yang tepat diperlukan agar Jenkins dapat melakukan checkout tanpa intervensi manual dan tanpa mengekspos kredensial secara publik.

## Scope

Mencakup pemilihan autentikasi, pembuatan Personal Access Token, penyimpanan
credential pada Jenkins, dan verifikasi akses Gitea.

## Prerequisites

- TN-001 telah berhasil diselesaikan.
- Jenkins Controller dan SSH Agent sudah tersedia.
- Repository Gitea `personal-site` sudah dibuat dan dapat dijangkau.
- User atau deployment key Gitea siap untuk konfigurasi.

## Execution Decision

### PS-ADR-0001 — Use Jenkins as Automation Server

Refer to:

- **[PS-ADR-0001 — Use Jenkins as Automation Server](../../../../adr/personal-site/adr-records/PS-ADR-0001.md){ target="_blank" rel="noopener" }**

**Decision**

Jenkins menjadi automation server yang mengambil source code Personal Site dari
repository Gitea.

**Reason**

- Jenkins mendukung integrasi SCM sebagai bagian dari pipeline.
- Checkout source code dapat diorkestrasi bersama tahap build dan publikasi
  artefak.

### PS-ADR-0006 — Use Personal Access Token for Gitea Repository

Refer to:

- **[PS-ADR-0006 — Use Personal Access Token for Gitea Repository](../../../../adr/personal-site/adr-records/PS-ADR-0006.md){ target="_blank" rel="noopener" }**

**Decision**

Jenkins mengakses repository Gitea melalui HTTPS menggunakan Personal Access
Token yang disimpan pada Jenkins Credentials.

**Reason**

- Token dapat dibatasi dengan scope minimum sesuai prinsip least privilege.
- Credential dapat dirotasi tanpa mengubah Jenkinsfile.
- Token tidak perlu disimpan di source code atau output pipeline.

### PS-ADR-0009 — Use Containerized Pipeline Environment

Refer to:

- **[PS-ADR-0009 — Use Containerized Pipeline Environment](../../../../adr/personal-site/adr-records/PS-ADR-0009.md){ target="_blank" rel="noopener" }**

**Decision**

Tool pipeline dijalankan melalui ephemeral container, sedangkan credential SCM
tetap dikelola dan diberikan oleh Jenkins hanya ketika dibutuhkan.

**Reason**

- Menjaga Jenkins Controller tetap ringan dan bebas dari dependency tool build.
- Mengisolasi tool serta menjaga environment pipeline tetap konsisten.
- Memisahkan pengelolaan secret dari lifecycle container.

Menggunakan Personal Access Token (HTTP/HTTPS) yang dikelola di Jenkins Credentials untuk autentikasi SCM (Gitea).

### Perbandingan Metode Autentikasi

| Metode | Kelebihan | Kekurangan | Rekomendasi |
| ------ | --------- | ---------- | ---------- |
| Username & Password | Umum dan mudah disiapkan | Rentan terhadap reuse, phishing, dan pengelolaan password yang berat | ❌ Tidak direkomendasikan |
| Personal Access Token (PAT) | Scope terbatas, mudah dikelola di Jenkins, cocok untuk HTTPS/container | Perlu rotasi terencana dan penyimpanan aman | ✅ Dipilih |
| SSH Key Authentication | Sangat aman dan tidak menggunakan password | Memerlukan manajemen key, konfigurasi `known_hosts`, dan dapat rumit di environment containerized | ⚠️ Alternatif |

### Alasan Memilih Token

- Personal Access Token mendukung prinsip **least privilege** tanpa perlu akses SSH penuh.
- Token dikelola aman di dalam **Jenkins Credential Store** dan tidak tersimpan di kode sumber.
- HTTPS + PAT lebih mudah bekerja pada lingkungan **containerized / ephemeral build** yang digunakan pada Personal Site.
- Rotasi token dapat dilakukan sebagai proses terencana tanpa memengaruhi credential pengguna lain.

Dengan pertimbangan ini, metode yang dipilih adalah **Personal Access Token (PAT)** untuk autentikasi Jenkins ke repository Gitea.

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Create a Personal Access Token in Gitea

1. Login ke Gitea.
2. Buka **Settings → Applications → Access Tokens** (atau menu sejenis).
3. Buat token baru dengan nama `jenkins-gitea-access`.
4. Berikan scope minimum yang diperlukan (misalnya `read:repository`).
5. **Salin dan simpan token tersebut sekarang, karena token ini hanya ditampilkan sekali dan tidak bisa dilihat lagi setelah halaman ditutup.**

!!! success "Expected Result"

    Personal Access Token dengan scope minimum berhasil dibuat dan disimpan secara aman.

</div>

<div class="procedure-step" markdown>

### Add Token Credential to Jenkins

1. Login ke Jenkins sebagai administrator.
2. Buka **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**.
3. Klik **Add Credentials**.
4. Pilih **Kind**: `Username with password`.
5. Isi detail credential:

    - **Scope**: `Global`
    - **ID**: `gitea-access-token`
    - **Description**: `Gitea access token for personal-site repository`
    - **Username**: `git` atau nama user Gitea jika diperlukan oleh URL HTTPS.
    - **Password**: *[Tempelkan Access Token yang didapat dari Gitea]*

6. Klik **Create**.

!!! note "Engineering Notes"

    - Pastikan akses token Gitea dibuat dengan scope minimum untuk `read` atau `pull` repository.
    - Jika Jenkins plugin Git memerlukan username, gunakan `git` atau nama akun yang sah, tergantung konfigurasi Gitea.
    - Jangan menyimpan token dalam kode sumber; selalu kelola melalui Jenkins Credentials.

!!! success "Expected Result"

    Credential `gitea-access-token` tersedia pada Jenkins tanpa mengekspos token di repository.

</div>

</div>

### Pipeline Configuration

Detail konfigurasi pipeline (SCM, credentials, branch specifier, dan trigger)
dibahas pada
[TN-005 — Create Build Pipeline & Execute Initial Test](TN-005-create-build-pipeline.md).

## Verification

| Item | Status | Notes |
| ------ | -------- | ------- |
| Gitea access token dibuat | ✅ | Token dibuat dan memiliki scope `read`/`pull` yang sesuai. |
| Credential `gitea-access-token` tersedia di Jenkins | ✅ | Credential muncul di Jenkins Global store. |
| Jenkins dapat mengakses repository lewat HTTPS | ✅ | `git ls-remote` berhasil ketika menggunakan credential yang tepat. |
| Repository URL sudah sesuai untuk pipeline | ✅ | Gunakan `https://<gitea-host>/<org>/personal-site.git` untuk konfigurasi pipeline. |

## Related Documentation

- [TN-002 — Deploy & Configure SSH Agent Node](TN-002-deploy-configure-ssh-agent-node.md)
- [TN-004 — Create Jenkinsfile](TN-004-create-jenkinsfile.md)
- [Continuous Integration Engineering Journal](index.md)

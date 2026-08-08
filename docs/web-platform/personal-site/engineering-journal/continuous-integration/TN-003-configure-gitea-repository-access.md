# TN-003 — Configure Gitea Repository Access

## Objective

Mengonfigurasi Jenkins agar dapat mengakses repository Gitea yang berisi source code `personal-site` menggunakan mekanisme otentikasi yang aman.

## Background

Build Pipeline tergantung pada kemampuan Jenkins untuk mengambil kode sumber dari Gitea. Otentikasi yang tepat diperlukan agar Jenkins dapat melakukan checkout tanpa intervensi manual dan tanpa mengekspos kredensial secara publik.

## Prerequisites

- TN-001 telah berhasil diselesaikan.
- Jenkins Controller dan SSH Agent sudah tersedia.
- Repository Gitea `personal-site` sudah dibuat dan dapat dijangkau.
- User atau deployment key Gitea siap untuk konfigurasi.

## Engineering Decision

Refer to:

- **PS-ADR-0001 — Use Jenkins as Automation Server**
- **PS-ADR-0006 — Use Personal Access Token for Gitea Repository**
- **PS-ADR-0009 — Use Containerized Pipeline Environment**

> Architecture Decision Records (ADR) tersebut menjadi referensi utama (Single Source of Truth) untuk penggunaan Jenkins, pemilihan Personal Access Token sebagai autentikasi Gitea, serta pengelolaan credential pada lingkungan pipeline yang tercontainerisasi.

Menggunakan Personal Access Token (HTTP/HTTPS) yang dikelola di Jenkins Credentials untuk Otentikasi SCM (Gitea).

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

Dengan pertimbangan ini, metode yang dipilih adalah **Personal Access Token (PAT)** untuk otentikasi Jenkins ke repository Gitea.
  
## Implementation

### Buat Personal Access Token di Gitea

1. Login ke Gitea.
2. Buka **Settings → Applications → Access Tokens** (atau menu sejenis).
3. Buat token baru dengan nama `jenkins-gitea-access`.
4. Berikan scope minimum yang diperlukan (misalnya `read:repository`).
5. **Salin dan simpan token tersebut sekarang, karena token ini hanya ditampilkan sekali dan tidak bisa dilihat lagi setelah halaman ditutup.**

### Tambahkan credential token di Jenkins

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

1. Klik **Create**.

!!! note "Engineering Notes"

    - Pastikan akses token Gitea dibuat dengan scope minimum untuk `read` atau `pull` repository.
    - Jika Jenkins plugin Git memerlukan username, gunakan `git` atau nama akun yang sah, tergantung konfigurasi Gitea.
    - Jangan menyimpan token dalam kode sumber; selalu kelola melalui Jenkins Credentials.
  
### Pipeline Configuration

Detail konfigurasi pipeline (SCM, credentials, branch specifier, dan trigger) dibahas pada `TN-007: Create Build Pipeline`. Silakan rujuk file tersebut untuk langkah-langkah konfigurasi job dan validasi checkout.

## Verification

| Item | Status | Notes |
| ------ | -------- | ------- |
| Gitea access token dibuat | ✅ | Token dibuat dan memiliki scope `read`/`pull` yang sesuai. |
| Credential `gitea-access-token` tersedia di Jenkins | ✅ | Credential muncul di Jenkins Global store. |
| Jenkins dapat mengakses repository lewat HTTPS | ✅ | `git ls-remote` berhasil ketika menggunakan credential yang tepat. |
| Repository URL sudah sesuai untuk pipeline | ✅ | Gunakan `https://<gitea-host>/<org>/personal-site.git` untuk konfigurasi pipeline. |

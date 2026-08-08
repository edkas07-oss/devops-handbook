# Install Hugo

## 🚀 Get Started

Panduan ini menjelaskan cara menginstal **Hugo Extended** pada Linux menggunakan binary resmi yang disediakan oleh proyek Hugo.

Metode instalasi ini dipilih karena tidak bergantung pada package manager sistem operasi sehingga memudahkan proses upgrade ke versi terbaru.

Setelah menyelesaikan panduan ini, Hugo siap digunakan untuk membuat dan membangun website statis.

---

## 📋 Prerequisites

Pastikan software berikut telah tersedia pada workstation.

| Component | Description |
|-----------|-------------|
| curl | Mengunduh informasi release Hugo dari GitHub API. |
| jq | Memproses output JSON dari GitHub API. |
| tar | Mengekstrak file hasil download. |
| tree (Optional) | Menampilkan struktur direktori. |

Apabila package belum tersedia, lakukan instalasi sesuai sistem operasi yang digunakan.

=== "Ubuntu / Debian"

```bash
sudo apt update
sudo apt install -y curl jq tar tree
```

=== "Rocky Linux / RHEL"

```bash
sudo dnf install -y curl jq tar tree
```

---

## ▶️ Procedure

### Verify Hugo Installation

Sebelum melakukan instalasi, pastikan Hugo belum tersedia pada workstation.

```bash
hugo version
```

Apabila Hugo belum terinstal, akan muncul pesan seperti berikut.

```text
command 'hugo' not found
```

Apabila Hugo telah terinstal, informasi versi akan ditampilkan.

```text
hugo v0.xxx.x
```

---

### Create Download Directory

Buat direktori untuk menyimpan file hasil download.

```bash
mkdir -p ~/Downloads/hugo
cd ~/Downloads/hugo
```

---

### Get Latest Hugo Version

Dapatkan versi Hugo Extended terbaru.

```bash
LATEST_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
| jq -r '.tag_name')

echo "$LATEST_VERSION"
```

Contoh output.

```text
v0.164.0
```

---

### Get Download URL

Dapatkan URL download Hugo Extended.

```bash
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
| jq -r '.assets[]
| select(.name | test("^hugo_extended_[0-9].*_linux-amd64.tar.gz$"))
| .browser_download_url')

echo "$DOWNLOAD_URL"
```

Contoh output.

```text
https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_extended_0.164.0_linux-amd64.tar.gz
```

!!! note "Engineering Notes"

    URL download tidak ditulis secara manual, tetapi diperoleh langsung dari **GitHub Releases API**.

    Pendekatan ini memberikan beberapa keuntungan:

    - Selalu menggunakan versi Hugo Extended terbaru.
    - Tidak perlu memperbarui dokumentasi setiap kali Hugo merilis versi baru. sehingga dokumentasi tetap dapat digunakan pada versi Hugo berikutnya
    - Mengurangi risiko menggunakan URL download yang sudah tidak valid.

---

### Download Hugo

Unduh Hugo Extended.

```bash
wget "$DOWNLOAD_URL"
```

---

### Extract Archive

Ekstrak file hasil download.

```bash
tar -xzf "$(basename "$DOWNLOAD_URL")"
```

Tampilkan struktur direktori.

```bash
tree
```

Contoh output.

```text
.
├── hugo
├── LICENSE
└── README.md
```

---

### Install Hugo

Salin binary Hugo ke direktori `/usr/local/bin`.

```bash
sudo install hugo /usr/local/bin/
```

---

## ✅ Verification

Pastikan Hugo berhasil diinstal.

Verifikasi lokasi binary.

```bash
which hugo
```

Contoh output.

```text
/usr/local/bin/hugo
```

Verifikasi versi Hugo.

```bash
hugo version
```

Contoh output.

```text
hugo v0.164.0+extended linux/amd64 BuildDate=...
```

Pastikan Hugo yang digunakan merupakan **Hugo Extended**.

!!! success "Verification"

    Hugo berhasil diinstal dan siap digunakan.


---

## 🧹 Cleanup

Setelah instalasi selesai, hapus file hasil download.

```bash
rm -f hugo
rm -f LICENSE
rm -f README.md
rm -f hugo_extended_*.tar.gz
```

---

## 💡 Engineering Notes

Dokumentasi ini menggunakan **Hugo Extended** karena mendukung fitur SCSS/SASS yang digunakan oleh banyak Hugo Theme modern.

Binary Hugo ditempatkan pada `/usr/local/bin` karena direktori tersebut diperuntukkan bagi aplikasi yang diinstal secara manual oleh administrator.

Keuntungan pendekatan ini:

- Tidak bergantung pada package manager sistem operasi.
- Proses upgrade cukup mengganti file binary.
- Selalu dapat menggunakan versi Hugo terbaru.
- Mudah direproduksi pada workstation lain.

---

## 🔗 Related Documents

- [Get Started](index.md)
- [Create Hugo Project](create-project.md)
- [Project Structure](project-structure.md)
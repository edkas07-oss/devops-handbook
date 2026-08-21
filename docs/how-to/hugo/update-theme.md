# Update Theme

## 🚀 Get Started

Panduan ini menjelaskan cara memperbarui Hugo Theme yang telah diinstal
pada project.

Dengan melakukan update secara berkala, Anda dapat memperoleh perbaikan
bug, peningkatan performa, dan fitur baru dari theme.

------------------------------------------------------------------------

## 📋 Prerequisites

Pastikan:

-   Theme telah diinstal menggunakan Git.
-   Project Hugo tersedia.

Apabila belum, lihat dokumen berikut.

-   [Install Theme](install-theme.md)

------------------------------------------------------------------------

## ▶️ Procedure


<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Change to Theme Directory

``` bash
cd ~/git/personal-site/themes/ananke
```

</div>

<div class="procedure-step" markdown>

### Review Current Status

``` bash
git status
```

Pastikan tidak terdapat perubahan lokal yang belum di-commit.

</div>

<div class="procedure-step" markdown>

### Update Theme

``` bash
git pull
```

Contoh output:

``` text
Already up to date.
```

atau

``` text
Updating ...
Fast-forward
```

</div>

<div class="procedure-step" markdown>

### Review Latest Commit

``` bash
git log --oneline -5
```

------------------------------------------------------------------------


</div>

</div>

## ✅ Verification

``` bash
cd ~/git/personal-site
hugo server
```

Buka:

``` text
http://localhost:1313
```

!!! success "Verification"

    Hugo Theme berhasil diperbarui.

------------------------------------------------------------------------

## 💡 Engineering Notes

Karena theme diinstal menggunakan Git Clone, proses update cukup
dilakukan menggunakan:

``` bash
git pull
```

Sebelum melakukan update, lakukan commit terhadap perubahan lokal
apabila Anda pernah memodifikasi source code theme.

------------------------------------------------------------------------

## 🔗 Related Documents

-   [Install Theme](install-theme.md)
-   [Run Development Server](run-development-server.md)
-   [Troubleshooting](troubleshooting.md)

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
| Jenkins | ✅ Ready | Jenkins telah berhasil di-deploy dan dapat diakses. |
| Build Pipeline | 🚧 In Progress | Pipeline pertama akan dibuat pada worklog ini. |

---

## Planned Activities

- [ ] Merancang workflow Build Pipeline.
- [ ] Membuat Jenkins Pipeline (*Pipeline as Code*).
- [ ] Checkout source code dari Gitea Repository.
- [ ] Menjalankan proses Hugo Build.
- [ ] Memverifikasi hasil build.
- [ ] Menyimpan artefak hasil build.

---

## Architecture

```text
Developer
      │
      ▼
Gitea Repository
      │
      ▼
Jenkins
      │
Checkout
      │
Build
      │
Static Website
```

---

## Engineering Decisions

### ED-001

**Decision**

Menggunakan Jenkins sebagai automation server.

**Reason**

- Pipeline as Code.
- Mudah diintegrasikan dengan Gitea.
- Menjadi fondasi Delivery Pipeline.
- Mendukung pengembangan pipeline pada tahap berikutnya.

---

## Technical Notes

### TN-001 — Start Jenkins Container

#### Objective

Menjalankan kembali container Jenkins yang telah dibuat sebelumnya sehingga siap digunakan untuk implementasi Build Pipeline.

#### Background

Jenkins telah di-deploy sebagai container Podman pada implementasi sebelumnya. Oleh karena itu, tidak diperlukan pembuatan container baru. Cukup menjalankan container yang sudah tersedia.

#### Implementation

Container Jenkins berhasil dijalankan menggunakan Podman dan diverifikasi dalam kondisi **running**. Selanjutnya dilakukan pengecekan log untuk memastikan proses startup berjalan tanpa error.

#### Commands

```bash
podman ps -a
podman start jenkins
podman ps
podman logs --tail 20 jenkins
```

#### Result

- Container Jenkins berhasil dijalankan.
- Status container berubah menjadi **running**.
- Tidak ditemukan error pada proses startup.
- Jenkins siap diakses melalui web browser untuk proses konfigurasi selanjutnya.

#### Notes

Technical Note ini hanya mencakup proses menjalankan kembali container Jenkins yang telah ada. Konfigurasi Jenkins dan pembuatan Build Pipeline akan dibahas pada Technical Note berikutnya.
---

### TN-002 — Verify Jenkins Environment

#### Objective

Memastikan Jenkins telah berjalan dengan baik dan siap digunakan untuk implementasi Build Pipeline.

#### Background

Sebelum membuat Build Pipeline, perlu dilakukan verifikasi terhadap lingkungan Jenkins untuk memastikan seluruh komponen berfungsi dengan normal. Verifikasi ini bertujuan mengurangi risiko kegagalan yang disebabkan oleh masalah konfigurasi atau environment.

#### Implementation

Verifikasi dilakukan melalui Jenkins Web UI dengan langkah-langkah berikut:

1. Mengakses Jenkins menggunakan web browser.
2. Login menggunakan akun administrator.
3. Memastikan Dashboard Jenkins dapat ditampilkan tanpa error.
4. Membuka menu **Manage Jenkins** untuk memastikan tidak terdapat konfigurasi yang bermasalah.
5. Memverifikasi informasi instalasi Jenkins, seperti versi Jenkins, versi Java, dan lokasi `JENKINS_HOME`.
6. Memastikan workspace Jenkins dapat digunakan untuk proses build.

#### Verification Result

| Item | Status | Notes |
|------|--------|-------|
| Jenkins Web UI dapat diakses | ⬜ | |
| Login Administrator berhasil | ⬜ | |
| Dashboard Jenkins tampil normal | ⬜ | |
| Manage Jenkins tanpa error | ⬜ | |
| Workspace dapat digunakan | ⬜ | |
| JENKINS_HOME terinisialisasi | ⬜ | |

#### Environment Information

| Item | Value |
|------|-------|
| Jenkins URL | |
| Jenkins Version | |
| Java Version | |
| Jenkins Home | |
| Deployment Method | Podman Container |

#### Result

Belum dilakukan.

#### Notes

Environment Jenkins dinyatakan siap apabila seluruh proses verifikasi berhasil diselesaikan.

---

## Issues

Belum ada.

---

## Resolutions

Belum ada.

---

## Deliverables

Belum ada.

---

## Lessons Learned

Belum ada.

---

## Next Actions

- Membuat Build Pipeline pertama.
- Mengimplementasikan Jenkinsfile.
# Personal Site Engineering Journal

## 🔍 Overview

Engineering Journal mencatat perjalanan engineering Personal Site secara
kronologis, termasuk perencanaan, implementasi, pengujian, masalah yang
ditemukan, dan penyelesaiannya.

Dokumen ini mempertahankan konteks historis. Kondisi dan prosedur yang berlaku
saat ini tersedia pada dokumentasi utama Personal Site, terutama bagian
Architecture, Development, Infrastructure, CI/CD, Operations, dan
Troubleshooting.

## 🧭 How to Use This Journal

- Baca berdasarkan fase untuk mengikuti proses implementasi.
- Gunakan Technical Note untuk melihat langkah dan hasil pekerjaan.
- Gunakan [CI/CD](../ci-cd/index.md) dan [Operations](../operations/index.md)
  untuk prosedur yang berlaku saat ini.
- Gunakan [Architecture](../architecture/index.md) untuk memahami desain sistem.
- Gunakan [Personal Site ADR Catalog](../../../adr/personal-site/index.md)
  untuk memahami alasan keputusan arsitektur.

## 🛠️ Engineering Phases

| Phase | Scope | Status |
| --- | --- | --- |
| [Continuous Integration](continuous-integration/index.md) | Build Hugo dan publish artifact ke MinIO | Implemented and verified |
| [Continuous Deployment](continuous-deployment/index.md) | Deploy artifact ke NGINX melalui Jenkins | Implemented and verified |

!!! note "Planned Ansible Phase"

    Tabel hanya memuat fase yang sudah memiliki Engineering Journal dan
    Technical Note. Infrastructure provisioning menggunakan Ansible masih
    berstatus planned pada dokumentasi current-state dan belum menjadi bagian
    Engineering Journal. Fase tersebut baru ditambahkan ke index setelah
    aktivitas engineering dan Technical Note-nya dimulai.

## 📄 Document Types

| Document | Purpose |
| --- | --- |
| Technical Note | Mencatat aktivitas engineering dan hasil implementasi |
| ADR | Mencatat keputusan serta konsekuensinya |
| Current-state documentation | Menjelaskan arsitektur dan prosedur yang berlaku saat ini |

## 🔗 Related Documentation

- [Continuous Integration Engineering Journal](continuous-integration/index.md)
- [Continuous Deployment Engineering Journal](continuous-deployment/index.md)
- [Personal Site Architecture](../architecture/index.md)
- [Personal Site CI/CD](../ci-cd/index.md)
- [Personal Site Operations](../operations/index.md)
- [Personal Site Troubleshooting](../troubleshooting/index.md)
- [Personal Site ADR Catalog](../../../adr/personal-site/index.md)

# Web Platform Projects

## Overview

Web Platform Projects adalah katalog dokumentasi untuk project berbasis web
application. Setiap project memiliki dokumentasi current-state, catatan
engineering, dan referensi yang terpisah agar dapat berkembang secara mandiri
tanpa kehilangan standar struktur yang konsisten.

## Documentation Structure

Setiap project menggunakan struktur dasar berikut dan dapat menambahkan
subhalaman sesuai kompleksitasnya:

```text
Project
├── Overview
├── Architecture
├── Development
├── Infrastructure
├── CI/CD
├── Operations
├── Troubleshooting
├── Engineering Journal
└── References
```

| Section | Responsibility |
| --- | --- |
| Overview | Tujuan, scope, technology stack, dan status project |
| Architecture | Desain current-state dan hubungan antarkomponen |
| Development | Workflow source code dan local development |
| Infrastructure | Platform prerequisites dan ownership boundary |
| CI/CD | Build, artifact, deployment, validation, dan rollback |
| Operations | Runbook untuk runtime yang sedang digunakan |
| Troubleshooting | Diagnosis dan solusi masalah yang telah dikonsolidasikan |
| Engineering Journal | Histori aktivitas, eksperimen, dan implementasi |
| References | ADR, repository, internal link, dan vendor documentation |

## Projects

| Project | Type | Status | Documentation |
| --- | --- | --- | --- |
| Personal Site | Hugo static website | Active | [Open project documentation](personal-site/index.md) |

## Documentation Principle

Engineering Journal menjadi salah satu sumber penyusunan project
documentation, tetapi bukan pengganti dokumentasi current-state. Setelah sebuah
implementasi stabil, hasilnya dikonsolidasikan ke Architecture, CI/CD,
Operations, atau Troubleshooting. Riwayat Technical Note tetap dipertahankan
untuk traceability.

Architecture Decision Record tetap dikelola pada koleksi ADR di root handbook
dan direferensikan oleh project sesuai scope keputusan.

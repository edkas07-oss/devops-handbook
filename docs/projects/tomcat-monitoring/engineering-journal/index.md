# Tomcat Monitoring Engineering Journal

## Overview

Engineering Journal mencatat perjalanan engineering Tomcat Monitoring
secara kronologis, termasuk perencanaan, implementasi, pengujian, masalah yang
ditemukan, dan penyelesaiannya.

Jurnal ini menjadi rekaman inti project sejak perumusan kebutuhan, penentuan
arsitektur, persiapan development dan infrastructure, implementasi, pengujian,
CI/CD, deployment, sampai evaluasi operasional. Aktivitas nonteknis yang
memengaruhi arah atau pelaksanaan project juga dicatat pada fase yang relevan.

Dokumentasi utama project merupakan hasil konsolidasi dari perjalanan tersebut.
Halaman utama digunakan untuk menyampaikan ringkasan desain, kemampuan, dan
kondisi terkini kepada pembaca portfolio tanpa menggantikan histori pada
Engineering Journal.

## How to Use This Journal

- Baca fase dan Technical Note berdasarkan nomor untuk mengikuti perjalanan
  project sejak perencanaan.
- Gunakan Technical Note untuk memahami konteks, langkah, masalah, keputusan,
  dan bukti hasil pekerjaan.
- Gunakan dokumentasi utama project untuk melihat ringkasan portfolio dan
  kondisi implementasi terkini.
- Gunakan ADR untuk memahami alasan dan konsekuensi keputusan arsitektur.

Runtime Monitoring Foundation TN-001 sampai TN-003 merupakan reconstructed
records yang dinormalisasi setelah aktivitas awal berlangsung. TN-004 mencatat
proses normalisasi tersebut secara
live agar pembaca dapat membedakan histori awal dari perbaikan dokumentasi.

## Engineering Phases

| Phase | Scope | Status |
| --- | --- | --- |
| [Runtime Monitoring Foundation](runtime-monitoring-foundation/index.md) | Menentukan arsitektur awal, menyiapkan area kerja, dan memverifikasi komponen monitoring pertama | Completed |
| [Monitoring Integration and Runtime Deployment](monitoring-integration-and-runtime-deployment/index.md) | Menetapkan contract konfigurasi, validator, dan readiness sebelum integrasi komponen serta deployment runtime | Completed |
| [Diagnostic MVP Pilot](diagnostic-mvp-pilot/index.md) | Menetapkan dan membuktikan diagnosis deterministik `TomcatDown`, 5-layer Knowledge Base, Declarative Rulepack Engine, dan alur pengayaan AI | Completed |
| [Monitoring Platform Integration](monitoring-platform-integration/index.md) | Mengintegrasikan pemantauan mandiri (Zero Silent Failure), ketahanan status SQLite, dashboard observabilitas, dan kesiapan platform produksi | Completed |
| [Continuous Integration and Deployment](continuous-integration-and-deployment/index.md) | Membangun otomasi pengiriman kontainer skala produksi (CI/CD) berbasis Jenkins, quality gates bertingkat, zero secret leakage, dan automated rollback | In Progress |

!!! note "Phase Lifecycle"

    Katalog hanya menampilkan fase yang sudah memiliki aktivitas dan Technical
    Note. Fase integrasi monitoring platform, CI, CD, dan operational validation
    ditambahkan ketika pekerjaannya benar-benar dimulai agar jurnal tetap
    mencerminkan perjalanan aktual, bukan rencana yang belum dijalankan.

## Document Types

| Document | Purpose |
| --- | --- |
| Technical Note | Mencatat discovery, keputusan, implementasi, verification, troubleshooting, atau documentation consolidation sesuai activity type |
| ADR | Mencatat keputusan arsitektur serta konsekuensinya |
| Project documentation | Menyajikan ringkasan portfolio, arsitektur, kemampuan, dan kondisi terkini |

## Related Documentation

- [Runtime Monitoring Foundation](runtime-monitoring-foundation/index.md)
- [Monitoring Integration and Runtime Deployment](monitoring-integration-and-runtime-deployment/index.md)
- [Diagnostic MVP Pilot](diagnostic-mvp-pilot/index.md)
- [Monitoring Platform Integration](monitoring-platform-integration/index.md)
- [Continuous Integration and Deployment](continuous-integration-and-deployment/index.md)
- [Tomcat Monitoring](../index.md)
- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [CI/CD](../ci-cd/index.md)
- [Operations](../operations/index.md)
- [Troubleshooting](../troubleshooting/index.md)
- [References](../references/index.md)

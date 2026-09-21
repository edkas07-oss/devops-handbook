# Apache Tomcat Enterprise Engineering Journal

## 🔍 Overview

Engineering Journal mencatat perjalanan engineering project **Apache Tomcat Enterprise** secara kronologis, terstruktur, dan dapat diverifikasi. Jurnal ini merekam seluruh proses mulai dari identifikasi kebutuhan enterprise, evaluasi arsitektur (VM legacy vs greenfield container), investigasi kepatuhan CIS Benchmark, rancang bangun operator CLI multi-platform (`tcctl`), integrasi Engine Runtime Named Volumes, hingga pengujian keamanan dan observabilitas.

Dokumentasi utama project menyajikan ringkasan desain dan kondisi terkini (*current-state*), sedangkan Engineering Journal berfungsi sebagai rekaman historis dan bukti verifikasi (*historical record & verification evidence*).

## 🧭 How to Use This Journal

- Baca fase dan Technical Note secara berurutan berdasarkan nomor (`TN-001`, `TN-002`, dst.) untuk memahami kronologi dan konteks keputusan teknis.
- Gunakan Technical Note untuk menelusuri latar belakang, asumsi, alternatif yang ditolak, perintah yang dieksekusi, serta bukti hasil uji (*actual verification evidence*).
- Gunakan [Architecture Decision Records (ADR)](../../../adr/tomcat/index.md) untuk memahami keputusan arsitektur tingkat tinggi beserta alasan dan konsekuensinya.
- Gunakan [Dokumentasi Utama Tomcat](../index.md) untuk referensi operasional dan panduan implementasi yang berlaku saat ini.

## 🛠️ Engineering Phases

| Phase | Scope | Status |
| --- | --- | --- |
| [Platform Foundation & Hardening](platform-foundation-and-hardening/index.md) | Membangun fondasi Greenfield OCI Container, mengimplementasikan 9 aturan CIS XML hardening, mengembangkan multi-platform operator `tcctl` berbasis Go, dan memvalidasi Engine Runtime Named Volumes. | Completed |

## 📄 Document Types

| Document | Purpose |
| --- | --- |
| **Technical Note (TN)** | Merekam aktivitas spesifik (discovery, implementasi, verifikasi, atau troubleshooting) dengan bukti faktual. |
| **Architecture Decision Record (ADR)** | Mencatat keputusan arsitektur strategis dengan namespace identifier `TC-ADR-xxxx`. |
| **Project Documentation** | Panduan operasional terkini, standar konfigurasi, dan arsitektur sistem yang sedang aktif. |

## 🔗 Related Documentation

- [Phase 1 — Platform Foundation & Hardening](platform-foundation-and-hardening/index.md)
- [Apache Tomcat Enterprise Overview](../index.md)
- [Tomcat Architecture & Security Boundary](../architecture/index.md)
- [Security Hardening Guide](../security-hardening/index.md)
- [Vulnerability Assessment Guide](../vulnerability-assessment/index.md)
- [Update Management & Zero-Downtime](../update-management/index.md)
- [SSL/TLS Management](../ssl-management/index.md)
- [Apache Tomcat Enterprise ADR Catalog](../../../adr/tomcat/index.md)

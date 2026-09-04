# Diagnostic MVP Requirements Traceability

## 🔍 Overview

Matriks ini memetakan seluruh persyaratan (*requirements*) fase Diagnostic MVP Pilot ke dokumen kontrak arsitektur dan bukti verifikasi (*verification evidence*). Seluruh persyaratan inti telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan persisten `devops-lab`.

---

## 📋 Matriks Keterlacakan Persyaratan (*Traceability Matrix*)

| ID | Kebutuhan (*Requirement*) | Kontrak Terkait | Status & Bukti Verifikasi (*Evidence State*) |
| :--- | :--- | :--- | :--- |
| **PILOT-001** | Hanya alert `TomcatDown` yang masuk ke rute diagnostik | Scope; Rule Specification | **Verified Live:** Konfigurasi sub-route Alertmanager dan filter receiver terverifikasi di TN-014 & TN-017. |
| **ING-001** | Webhook firing/resolved terotentikasi | Webhook Contract | **Verified Live:** Integrasi HTTPS TLS dan otentikasi Bearer token Alertmanager ke Diagnostic Service terverifikasi di TN-008 & TN-015. |
| **ING-002** | Commit SQLite terjadi sebelum respons `202 Accepted` | Webhook; SQLite Contract | **Verified Live:** Transaksi atomik database sebelum respons HTTP terbukti di TN-005 & TN-017. |
| **ING-003** | Event duplikat bersifat idempoten melewati restart container | Webhook; SQLite Contract | **Verified Live:** Deduplikasi berbasis `event_key` pada database persisten teruji di TN-005 & TN-015. |
| **ID-001** | Hanya target kanonikal dalam allowlist yang diterima | Target Contract | **Verified Live:** Validasi `targets.json` dan isolasi target Tomcat terbukti di TN-006 & TN-017. |
| **RULE-001** | `up=0` adalah pemicu (*trigger*), bukan bukti Tomcat mati | Rule Specification | **Verified Live:** Evaluasi multi-branch (TD-01 s/d TD-08) membuktikan akar masalah sesungguhnya di TN-006 & TN-017. |
| **RULE-002** | Bukti dibatasi (*bounded*) dan dikorelasikan temporal | Rule; Evidence Contracts | **Verified Live:** Adapter bukti terbatas (15 mnt sebelum s/d 2 mnt setelah) terverifikasi di TN-006 & TN-017. |
| **RULE-003** | Ketiadaan bukti dinyatakan secara eksplisit (*no negative proof*) | Result Contract | **Verified Live:** Penanda *unavailable* / *timeout* tercatat di canonical result dan laporan email di TN-006 & TN-007. |
| **RULE-004** | Bukti kontradiktif dievaluasi sebelum bukti pendukung | Rule Specification | **Verified Live:** Logika penanganan multi-error dan pencegahan tebakan salah teruji di TN-006 & TN-018. |
| **RULE-005** | Tingkat keyakinan (*confidence*) mengikuti tabel keputusan | Result Contract; ADR | **Verified Live:** Penentuan confidence deterministik (`high`, `medium`, `null`) terverifikasi di TN-006, TN-018, & TN-019. |
| **RULE-006** | Input dan versi aturan yang sama menghasilkan hash deterministik | Result Contract | **Verified Live:** SHA-256 result hashing terverifikasi di unit tests dan laporan audit di TN-007 & TN-017. |
| **RULE-007** | Adapter Prometheus memiliki deadline 5 detik tanpa in-run retry | Rule Specification | **Verified Live:** Timeout fallback Prometheus teruji di unit test dan disposable runtime di TN-006 & TN-013. |
| **RES-001** | Canonical result memvalidasi kombinasi semantik | Result Contract | **Verified Live:** Skema canonical result v1 tervalidasi dan tersimpan di database SQLite di TN-007 & TN-017. |
| **MSG-001** | Format Plain Text dan HTML menjaga makna kanonikal | Notification Contract | **Verified Live:** Render ganda 7-seksi tersinkronisasi dan lolos uji rendering di TN-007 & TN-013. |
| **MSG-002** | Penanganan siklus firing, update material, partial, dan resolved | Notification Contract | **Verified Live:** Notifikasi firing, proteksi 1 material update, dan resolved terkirim ke Mailpit di TN-012 & TN-017. |
| **MSG-003** | Email merender 7 seksi terurut dengan rekomendasi SOP | Notification Contract | **Verified Live:** Laporan 7-seksi dengan sanitasi rahasia dan SOP Bahasa Indonesia terverifikasi di TN-007 & TN-017. |
| **DEL-001** | Mailpit adalah satu-satunya target pengiriman aktif pilot | Notification Contract | **Verified Live:** Pengiriman email via internal SMTP `mailpit:1025` terverifikasi secara persisten di TN-013 & TN-015. |
| **DEL-002** | Bridge dan TrueSight dinonaktifkan tanpa aktivitas jaringan | Notification Contract | **Verified Live:** Tidak ada koneksi, antrean, atau thread eksternal yang aktif di TN-008 & TN-015. |
| **DB-001** | Inisialisasi skema dan migrasi database berjalan otomatis | SQLite Contract | **Verified Live:** Migrasi maju skema 001–004 otomatis saat startup container terverifikasi di TN-005 & TN-018. |
| **DB-002** | Data insiden dan status deduplikasi bertahan saat restart | SQLite Contract | **Verified Live:** Named volume persisten `diagnostic_data` teruji bertahan melewati restart di TN-015 & TN-017. |
| **DB-003** | Retensi 30 hari dan proteksi kapasitas berjalan otomatis | SQLite Contract | **Verified Live:** Logika housekeeping berkala dan proteksi batas 100/250 MiB terverifikasi di TN-005 & TN-007. |
| **NFR-001** | Service terisolasi mengelola target lokal secara aman | NFR Contract | **Verified Live:** Pengujian target allowlist tunggal dan isolasi bukti lolos di TN-006 & TN-017. |
| **NFR-002** | Batasan worker, antrean, timeout, dan sumber bukti ditegakkan | NFR Contract | **Verified Live:** Single worker, antrean 50, dan global deadline 60 detik terverifikasi di TN-007 & TN-017. |
| **SEC-001** | Service tidak memiliki akses kontrol container atau host | Security Contract | **Verified Live:** Rootless execution, isolasi filesystem, dan ketiadaan podman socket terverifikasi di TN-010 & TN-016. |
| **SEC-002** | Collector hanya mengekspos rekaman spool yang masuk allowlist | Collector Contract | **Verified Live:** Atomic spooling dan sanitasi allowlist terverifikasi di TN-016 & TN-017. |
| **OPS-001** | Endpoint health check dan metrik Prometheus terekspos | NFR Contract | **Verified Live:** Endpoint `/livez`, `/readyz`, dan `/metrics` terverifikasi di TN-009 & TN-015. |

---

## ⏳ Kebutuhan yang Ditunda (*Deferred Requirements*)

| ID | Kebutuhan (*Requirement*) | Syarat Promosi ke Fase Berikutnya |
| :--- | :--- | :--- |
| **DEF-APP-001** | Aturan diagnostik `ApplicationHealthCheckFailed` | Evaluasi baseline dan persetujuan spesifikasi aturan baru. |
| **DEF-HEAP-001** | Aturan diagnostik `TomcatHighHeapUsage` | Evaluasi pola heap memory dan persetujuan spesifikasi aturan baru. |
| **DEF-TS-001** | Aktivasi Integration Bridge dan TrueSight | Persetujuan kontrak target, pemetaan slot, dan arsitektur enterprise delivery. |

Item yang ditunda merupakan keputusan arsitektur sadar untuk menjaga batasan fokus pilot dan bukan merupakan kegagalan fungsional.

---

## 📌 Status

**Completed & Live Verified (100%).**
Seluruh 26 persyaratan inti Diagnostic MVP Pilot telah diimplementasikan dan diverifikasi secara live pada lingkungan persisten `devops-lab` melalui rangkaian Technical Notes [TN-001](../engineering-journal/diagnostic-mvp-pilot/TN-001-define-diagnostic-mvp-architecture-and-contract.md) hingga [TN-020](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Gap Register](gap-register.md)
- [Diagnostic MVP Pilot Engineering Journal](../engineering-journal/diagnostic-mvp-pilot/index.md)
- [TN-020 — Consolidate Diagnostic MVP Portfolio and Plan Next Phase](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md)

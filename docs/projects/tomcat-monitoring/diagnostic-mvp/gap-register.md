# Diagnostic MVP Gap Register

## 🔍 Overview

Daftar kesenjangan (*Gap Register*) ini mencatat seluruh item terbuka teknis, persyaratan penutupan (*closure evidence*), gerbang persetujuan (*gate*), dan pemilik (*owner*) selama fase Diagnostic MVP Pilot berlangsung.

---

## 📋 Matriks Kesenjangan Terbuka (*Open Items*)

| ID | Item Kesenjangan (*Open Item*) | Bukti Penutupan (*Closure Evidence*) | Gerbang (*Gate*) | Pemilik (*Owner*) | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **GAP-001** | Pembentukan repositori dan tata kelola `tomcat-diagnostic-service` | Rencana repositori disetujui, kontrak source, dan antarmuka validasi | Sebelum implementasi service | Project owner / engineer | **Closed** (TN-003) |
| **GAP-002** | Pembentukan repositori `tomcat-diagnostic-event-collector` | Rencana host-runtime disetujui dan asesmen privilege | Sebelum implementasi collector | Platform owner / engineer | **Closed** (TN-016) |
| **GAP-003** | Skema fisik SQLite dan mekanisme migrasi otomatis | Desain implementasi direview dan pengujian migrasi lulus | Sebelum freeze skema | Service owner | **Closed** (TN-005) |
| **GAP-004** | Format fisik allowlist target (`targets.json`) | Skema konfigurasi tervalidasi untuk `lab + edkas-pc1 + tomcat-jmx-exporter` | Sebelum pengujian webhook | Integration owner | **Closed** (TN-006) |
| **GAP-005** | Sumber generasi container yang stabil | Bukti Podman rootless dan semantik rekreasi container | Sebelum pengujian korelasi | Platform owner | **Closed** (TN-016) |
| **GAP-006** | Lokasi log otoritatif dan kebijakan rotasi | Mount direktori log Tomcat dan pembuktian retensi | Sebelum adapter log | Tomcat owner | **Closed** (TN-016) |
| **GAP-007** | Lokasi artefak crash JVM fatal (`hs_err_pid*.log`) | Argumen JVM efektif dan direktori mount crash dump | Sebelum adapter crash | Tomcat owner | **Closed** (TN-016) |
| **GAP-008** | Izin pengumpulan bukti collector rootless | Matriks akses cgroup, user-service, journal, dan Podman | Sebelum pengujian collector | Platform owner | **Closed** (TN-016) |
| **GAP-009** | Siklus hidup secret TLS dan bearer token | Path non-Git, izin `0400`, distribusi CA, dan prosedur reload | Sebelum deployment webhook | Security / platform owner | **Closed** (TN-015) |
| **GAP-010** | Kebijakan retry pengiriman SMTP | Jumlah percobaan, jeda backoff, batas usia, dan kapasitas antrean | Sebelum implementasi pengiriman | Service owner | **Closed** (TN-012) |
| **GAP-011** | Batasan ukuran dan retensi spool collector | Durasi retensi, batas berkas, total ukuran, dan pembersihan atomik | Sebelum freeze skema collector | Collector owner | **Closed** (TN-016) |
| **GAP-012** | Baseline resource host | CPU, memori, filesystem, dan beban kerja representatif | Sebelum penerimaan NFR | Lab owner | **Closed** (TN-015) |
| **GAP-013** | Prosedur injeksi kegagalan aman (*failure injection*) | Metode simulasi OOM, JMX loss, stop, crash, dan pemulihan | Sebelum pengujian end-to-end | Project owner / engineer | **Closed** (TN-017) |
| **GAP-014** | Konfigurasi TLS produksi, HA, backup, dan DR | Keputusan arsitektur fase produksi | Fase Produksi | Security / platform owner | **Deferred** |
| **GAP-015** | Integrasi kelas TrueSight, slot mapping, dan `msend` | Kontrak integrasi terpisah yang disetujui | Fase Enterprise Integration | Integration owner | **Deferred** |
| **GAP-016** | Orkestrasi rendering canonical result, SMTP, dan worker | Implementasi source dan pengujian komponen/disposable | Sebelum verifikasi Mailpit | Service owner | **Closed** (TN-012) |

---

## ✅ Catatan Penutupan (*Closure Records*)

Setiap item ditutup secara *append-oriented* dengan mencatat bukti observasi, artefak yang terdampak, tanggal penyelesaian, dan konsekuensi verifikasinya:

1. **GAP-001 (Closed - TN-003):** Node.js 24 ESM, SQLite built-in terisolasi, layout repositori, dan baseline validasi statis diterima (TM-ADR-0013).
2. **GAP-002 (Closed - TN-016):** Repositori `tomcat-diagnostic-event-collector` dibentuk dengan arsitektur rootless dan atomic spooling (TM-ADR-0012).
3. **GAP-003 (Closed - TN-005):** Migrasi maju database SQLite (`001` s/d `004`), transaksi atomik, dan tabel `custom_rules` teruji 100%.
4. **GAP-004 (Closed - TN-006 & TN-011):** Berkas `targets.json` tervalidasi dengan pemetaan target kanonikal ke spool dan log mount.
5. **GAP-005, GAP-006, GAP-007, GAP-008, GAP-011 (Closed - TN-016):** Integrasi runtime Tomcat, isolasi spool rootless, cgroup OOM listener, dan mount log read-only terbukti live.
6. **GAP-009 & GAP-012 (Closed - TN-015):** Deployment persisten Prometheus, Alertmanager, dan Diagnostic Service dengan TLS ketat dan baseline resource stabil.
7. **GAP-010 & GAP-016 (Closed - TN-012 & TN-013):** Worker queue terhubung ke renderer 7-seksi, SMTP delivery attempt persistence, dan retry terverifikasi di Mailpit.
8. **GAP-013 (Closed - TN-017 & TN-019):** Pengujian skenario kegagalan live (OOM, graceful stop, database connection pool exhausted) terverifikasi end-to-end.

---

## 📌 Status

**All Pilot Blocking Gaps Closed (100%).**
Seluruh item kesenjangan yang menghalangi fase pilot (GAP-001 s/d GAP-013 dan GAP-016) telah ditutup dan diverifikasi secara live. GAP-014 (Produksi) dan GAP-015 (TrueSight) ditunda secara sadar ke fase lanjutan (*Monitoring Platform Integration*).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Requirements Traceability](requirements-traceability.md)
- [Diagnostic MVP Pilot Engineering Journal](../engineering-journal/diagnostic-mvp-pilot/index.md)
- [TN-020 — Consolidate Diagnostic MVP Portfolio and Plan Next Phase](../engineering-journal/diagnostic-mvp-pilot/TN-020-consolidate-diagnostic-mvp-portfolio-and-plan-next-phase.md)

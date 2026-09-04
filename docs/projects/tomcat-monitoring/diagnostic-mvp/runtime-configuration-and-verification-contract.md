# Runtime Configuration and Verification Contract

## 🔍 Overview

Kontrak ini menetapkan tata kelola konfigurasi runtime, pemisahan kepemilikan artefak, batas izin (*mount & permission boundaries*), serta prosedur verifikasi runtime agar image aplikasi Diagnostic Service dapat dikonsumsi tanpa menanamkan konfigurasi spesifik environment, target, sertifikat, atau secret ke dalam image.

---

## 📌 Batas Kepemilikan (*Ownership Boundary*)

| Artefak atau Siklus Hidup | Pemilik (*Owner*) | Tanggung Jawab |
| :--- | :--- | :--- |
| **Source Service & Image** | `tomcat-diagnostic-service` | Kode aplikasi, skema database, migrasi, siklus hidup image, dan component test. |
| **Konfigurasi Non-Secret** | `tomcat-monitoring` | Berkas `application.json`, allowlist target `targets.json`, routing, deklarasi volume mount, dan pengujian integrasi. |
| **Kredensial & Sertifikat** | Non-Git Storage | Kunci privat TLS, token bearer, sertifikat CA/server, dan rotasi secret. |
| **Runtime Base Image** | `nodejs` | Base image Node.js 24 ter-pin yang disematkan ke dalam image aplikasi. |
| **Persistensi SQLite** | `tomcat-diagnostic-service` & Platform | Skema, migrasi, dan transaksi (Service); alokasi named volume `diagnostic_data` dan kapasitas fisik (Platform). |
| **Mailpit Runtime** | `axllent/mailpit` & `tomcat-monitoring` | Image upstream Mailpit dan orkestrasi pengujian penerimaan email diagnostik. |

`tomcat-diagnostic-service` tidak memuat berkas konfigurasi spesifik environment. `tomcat-monitoring` hanya menyimpan konfigurasi non-secret dan referensi; seluruh nilai rahasia dan sertifikat yang dihasilkan tetap berada di luar repositori Git.

---

## 📋 Konfigurasi Aplikasi (`application.json`)

Konfigurasi aplikasi dikelola oleh modul integrasi menggunakan skema versi `1` dengan parameter berikut:

| Parameter | Nilai Konfigurasi Lab | Deskripsi & Batasan |
| :--- | :--- | :--- |
| `listen.host` | `0.0.0.0` | Antarmuka jaringan internal container |
| `listen.port` | `8443` | Port HTTPS internal |
| `databasePath` | `/var/lib/tomcat-diagnostic/diagnostic.db` | Lokasi berkas database SQLite pada volume persisten |
| `tls.certificateFile` | `/run/tomcat-diagnostic/tls/server.crt` | Path berkas sertifikat server TLS (mount read-only) |
| `tls.privateKeyFile` | `/run/tomcat-diagnostic/tls/server.key` | Path berkas private key TLS (mount read-only `0400`) |
| `bearerTokenFile` | `/run/tomcat-diagnostic/secrets/bearer-token` | Path berkas secret token autentikasi webhook & API |
| `targetAllowlistFile` | `/run/tomcat-diagnostic/config/targets.json` | Path allowlist target Tomcat yang diizinkan |
| `smtp.host` | `mailpit` | Hostname container Mailpit pada jaringan lab |
| `smtp.port` | `1025` | Port SMTP Mailpit |
| `smtp.secure` | `false` | TLS dinonaktifkan khusus pada jaringan internal terisolasi Mailpit |
| `smtp.from` | `diagnostic@tomcat-monitoring.invalid` | Identitas pengirim laporan diagnostik |
| `smtp.to` | `operator@tomcat-monitoring.invalid` | Identitas penerima laporan diagnostik |
| `queue.capacity` | `50` | Batas maksimum antrean pekerjaan diagnostik |
| `queue.pollIntervalMs` | `250` | Interval polling worker (milidetik) |
| `timeouts.diagnosticMs` | `60000` | Batas waktu global evaluasi satu insiden (60 detik) |
| `timeouts.smtpMs` | `10000` | Batas waktu koneksi dan pengiriman SMTP (10 detik) |
| `timeouts.shutdownMs` | `10000` | Batas waktu graceful shutdown SIGTERM (10 detik) |
| `requestLimitBytes` | `262144` | Batas ukuran payload request HTTP (256 KiB) |

Berkas `application.json` tidak boleh memuat token, password, private key, konten sertifikat mentah, kredensial environment, atau daftar target dinamis dari payload webhook.

Kebijakan retry notifikasi ditetapkan secara tetap di source code: maksimum 3 percobaan (*attempts*), jeda backoff 1 dan 5 detik, usia maksimum event 60 detik, menggunakan antrean berkapasitas 50 tanpa antrean sekunder.

---

## 💾 Kontrak Mount dan Hak Akses (*Permissions*)

| Artefak Host | Target Container | Tipe Mount | Mode Izin (*Permissions*) |
| :--- | :--- | :--- | ---: |
| `application.json` | `/run/tomcat-diagnostic/application.json` | File, read-only | `0444` |
| `targets.json` | `/run/tomcat-diagnostic/config/targets.json` | File, read-only | `0444` |
| Sertifikat TLS Server | `/run/tomcat-diagnostic/tls/server.crt` | File, read-only | `0444` |
| Private Key TLS Server | `/run/tomcat-diagnostic/tls/server.key` | File, read-only | `0400` |
| Bearer Token Secret | `/run/tomcat-diagnostic/secrets/bearer-token` | File, read-only | `0400` |
| Direktori Storage SQLite | `/var/lib/tomcat-diagnostic` | Direktori, read-write | `0700` |
| Direktori Spool Event | `/run/tomcat-diagnostic/spool` | Direktori, read-only | `0555` |

Container aplikasi berjalan di bawah pengguna non-root (`node`, UID/GID `1000:1000`). Seluruh mount konfigurasi, sertifikat, allowlist, dan direktori spool collector bersifat hanya-baca (*read-only*). Hanya direktori database SQLite yang bersifat *read-write*.

---

## ✅ Kontrak Verifikasi (*Verification Contract*)

Verifikasi dibagi ke dalam beberapa lapisan:

1. **Static Configuration:** Skema JSON valid, path absolut presisi, pemindaian non-secret bersih, digest image terverifikasi, dan izin mount sesuai standar.
2. **Image Static:** Pengguna non-root, working directory aman, tidak ada artefak runtime yang bocor ke layer image.
3. **Component & Integration Test:** Kepercayaan TLS HTTPS, endpoint live/ready/metrics merespons, penolakan bearer tidak valid, penerimaan webhook, eksekusi antrean worker, persistensi state SQLite, dan penanganan sinyal SIGTERM keluar dengan kode `0`.
4. **Notification Boundary:** Percobaan SMTP tercatat di database dan pesan Plain Text/HTML 7-seksi tertangkap dengan benar oleh Mailpit.
5. **Persistent Deployment:** Orkestrasi multi-container persisten di lingkungan `devops-lab` dengan integrasi Prometheus, Alertmanager, dan Restricted Event Collector.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Seluruh kontrak konfigurasi runtime, hak akses file, isolasi mount non-root, persistensi named volume `diagnostic_data`, integrasi route webhook Alertmanager, dan Restricted Collector telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan persisten `devops-lab` ([TN-009](../engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md), [TN-010](../engineering-journal/diagnostic-mvp-pilot/TN-010-build-and-verify-diagnostic-service-image.md), [TN-011](../engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md), [TN-013](../engineering-journal/diagnostic-mvp-pilot/TN-013-rebuild-and-verify-diagnostic-service-mailpit-runtime.md), [TN-015](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md), [TN-016](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md), dan [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Target and Evidence Contract](target-and-evidence-contract.md)
- [SQLite Lifecycle Contract](sqlite-lifecycle-contract.md)
- [Non-Functional and Security Contract](non-functional-and-security-contract.md)
- [TN-011 — Define Diagnostic Service Runtime Configuration Contract](../engineering-journal/diagnostic-mvp-pilot/TN-011-define-diagnostic-service-runtime-configuration-contract.md)
- [TN-015 — Deploy Persistent Monitoring Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md)
- [TN-016 — Implement Restricted Collector and Tomcat Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md)
- [TM-ADR-0011 — Service Image Immutability and Runtime Configuration Boundary](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0011.md)

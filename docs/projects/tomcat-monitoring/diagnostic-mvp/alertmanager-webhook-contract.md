# Alertmanager Webhook Contract

## 🔍 Overview

Alertmanager mengirimkan event webhook standar berskema versi `4` ke Diagnostic Service. Setiap item alert divalidasi, dinormalisasi, disimpan secara persisten, dan diproses secara independen.

---

## 🔗 Endpoint

```http
POST /api/v1/alerts/alertmanager
Content-Type: application/json
Authorization: Bearer <token>
```

URL service yang disetujui pada environment lab adalah:

```text
https://diagnostic-service:8443/api/v1/alerts/alertmanager
```

Endpoint ini hanya tersedia pada container network internal khusus dan tidak memiliki port yang diekspos ke host (*no host-published port*). Alertmanager memvalidasi sertifikat CA service. Token bearer dan sertifikat CA di-mount secara hanya-baca (*read-only*) dari penyimpanan non-Git.

---

## 📥 Data yang Diperlukan

Field tingkat atas (*top-level fields*) yang wajib ada meliputi `version`, `groupKey`, `status`, `receiver`, dan array `alerts` yang tidak kosong. Field wajib per-alert meliputi:

- `status`, bernilai `firing` atau `resolved`;
- `labels` dan `annotations`;
- `startsAt` dan `endsAt`;
- Alertmanager `fingerprint`.

Label wajib untuk alert `TomcatDown` adalah `alertname`, `severity`, `environment`, `host`, `tomcat_instance`, `job`, `instance`, `service`, dan `check`. Label `application` bersifat sebagai konteks pendukung opsional.

Service akan menolak identitas yang tidak terdaftar dalam allowlist target lokal (`targets.json`). Anotasi dianggap sebagai data presentasi yang tidak tepercaya (*untrusted data*) dan tidak dapat digunakan untuk memilih path, mengeksekusi command, memilih container, menentukan sumber bukti, maupun mengubah konfigurasi.

---

## 🆔 Identitas Event

Fingerprint alert memasangkan status firing dan resolved. Idempotensi menggunakan formula:

```text
event_key = fingerprint + status + event_time
```

`event_time` adalah `startsAt` untuk event firing dan `endsAt` untuk event resolved. `groupKey` disimpan untuk observabilitas tetapi bukan identitas unik insiden.

---

## 🔄 Pemrosesan

1. Otentikasi request dan tegakkan header `application/json` serta batas ukuran request maksimum 256 KiB.
2. Validasi versi skema, field wajib, format timestamp, label, dan allowlist target.
3. Normalisasi setiap alert secara independen dan hitung `event_key`.
4. Simpan event yang diterima ke SQLite dengan *uniqueness constraint* (idempotent).
5. Kembalikan respons `202 Accepted` hanya setelah transaksi database berhasil di-commit.
6. Masukkan pekerjaan diagnostik ke dalam antrean (*queue*) untuk dieksekusi oleh worker tunggal.

Kueri metrik, pengumpulan bukti, dan pengiriman notifikasi berjalan secara asinkron di latar belakang (*background worker*) dan tidak menahan koneksi webhook tetap terbuka.

---

## 🌐 Kontrak Respons

| Status | Makna |
| ---: | --- |
| `202` | Event terotentikasi dan berhasil disimpan secara tahan-uji (*durably accepted*) |
| `400` | Format JSON tidak valid, skema salah, timestamp salah, atau identitas wajib tidak lengkap |
| `401` | Token bearer tidak ada atau tidak valid |
| `413` | Ukuran payload request melebihi batas 256 KiB |
| `415` | Format Content-Type bukan `application/json` |
| `429` | Kapasitas antrean penuh sehingga penambahan pekerjaan baru ditolak demi keamanan |
| `503` | Service atau database SQLite tidak dapat menerima pekerjaan secara tahan-uji |

Pengiriman duplikat (*duplicate delivery*) menghasilkan respons terkontrol (202 Accepted / duplicate acknowledged) dan tidak mengulang pekerjaan diagnosis maupun pengiriman notifikasi.

---

## 🔐 Keamanan

- Verifikasi sertifikat TLS dan otentikasi bearer token wajib ditegakkan.
- Nilai secret, token, dan raw authorization header tidak pernah dicatat dalam log maupun database SQLite.
- Data request tidak dapat digunakan untuk memanipulasi filesystem path atau tindakan eksekusi command.
- Seluruh operasi request, parsing, SQLite, antrean, dan downstream menggunakan batas waktu terbatas (*bounded timeouts*).
- Nama alert yang tidak didukung dicatat sebagai *unsupported* dan tidak memicu eksekusi aturan diagnostik yang ditunda.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Penanganan webhook Alertmanager, autentikasi bearer TLS ketat, deduplikasi event, penerimaan antrean SQLite, serta routing otomatis dari Alertmanager telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-005](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md), [TN-008](../engineering-journal/diagnostic-mvp-pilot/TN-008-implement-secure-service-and-smtp-delivery-boundaries.md), [TN-014](../engineering-journal/diagnostic-mvp-pilot/TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md), dan [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [TomcatDown Rule Specification](tomcat-down-rule-specification.md)
- [Target and Evidence Contract](target-and-evidence-contract.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [SQLite Lifecycle Contract](sqlite-lifecycle-contract.md)
- [Notification and Integration Contract](notification-and-integration-contract.md)
- [TN-005 — Implement Durable Diagnostic Ingestion and Queue](../engineering-journal/diagnostic-mvp-pilot/TN-005-implement-durable-diagnostic-ingestion-and-queue.md)
- [TN-014 — Configure TomcatDown Rule and Alertmanager Diagnostic Route](../engineering-journal/diagnostic-mvp-pilot/TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md)
- [TM-ADR-0006 — Alertmanager Webhook Ingestion Boundary](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0006.md)

# Target and Evidence Contract

## 🔍 Overview

Bukti diagnostik (*diagnostic evidence*) hanya diterima jika dapat diresolusikan ke tepat satu target Tomcat yang terdaftar secara eksplisit. Hal ini mencegah bukti saling silang (*cross-evidence*) antar-container, host, environment, atau generasi runtime yang telah dibuat ulang.

---

## 🆔 Identitas Kanonikal

Identitas kanonikal target didefinisikan sebagai:

```text
environment + host + tomcat_instance
```

Identitas pertama pada lingkungan lab adalah:

```text
lab + edkas-pc1 + tomcat-jmx-exporter
```

Label `job` dan `instance` merupakan label teknis endpoint scrape dan tidak menggantikan identitas logis. Identitas aplikasi dan lokasi probe *health check* merupakan konfigurasi pendukung opsional yang digunakan sebagai bukti sekunder.

Daftar izin lokal (*local allowlist* `targets.json`) memetakan identitas kanonikal ke nilai-nilai tepercaya seperti selektor Prometheus, identitas container, penanda generasi runtime, direktori sumber log, direktori artefak crash JVM, endpoint health check aplikasi, dan partisi spool restricted event collector. Webhook tidak dapat mengubah atau menimpa pemetaan ini.

---

## 📦 Objek Bukti (*Evidence Object*)

Setiap item bukti memuat:

- `evidence_id` yang stabil, `source`, dan `type` ternormalisasi;
- `target_id` kanonikal dan penanda generasi runtime bila tersedia;
- Format waktu UTC `observed_at` dan timestamp pengumpulan;
- Status pengumpulan: `collected`, `not_found`, `no_data`, `unavailable`, `timeout`, `unauthorized`, `not_configured`, atau `invalid_response`;
- Tingkat kekuatan bukti: `direct`, `supporting`, atau `contextual`;
- Nilai typed terbatas (*bounded typed value*) dan status sanitasi/redaksi.

Status `not_found` menandakan bahwa sumber bukti berhasil diperiksa tetapi tidak ditemukan indikasi kegagalan; status ini berbeda dari `unavailable` (tidak dapat diakses) dan `not_configured` (tidak dikonfigurasi).

---

## 🔎 Isolasi Bukti (*Evidence Isolation*)

- Kueri Prometheus wajib menyertakan selektor target yang masuk allowlist.
- Pembacaan log dan crash dump menggunakan direktori absolut terkonfigurasi serta menolak *symlink escape*, *directory traversal*, dan path dinamis yang dikirimkan melalui payload event.
- Rekaman *restricted collector* wajib membawa identitas target dan generasi runtime yang sama.
- Jendela waktu bukti dibatasi secara ketat (*bounded window*) dan dievaluasi dalam format waktu UTC.
- Ketidakcocokan container ID atau waktu start mencegah korelasi dengan generasi container sebelumnya, kecuali ada event siklus hidup eksplisit yang menghubungkannya.
- Bukti di luar identitas atau jendela waktu yang ditentukan akan ditolak dan dicatat pada metrik isolasi (*isolation rejection metric*).

---

## 🧹 Sanitasi dan Batasan Ukuran (*Bounds*)

Kredensial, token, cookie, identifier sesi, body request HTTP, dan *unbounded stack trace* disaring atau disanitasi sebelum disimpan ke database. Satu insiden diagnosis dibatasi membaca maksimum **500 baris log** dan **512 KiB input log mentah**, serta menyimpan maksimum **256 KiB ringkasan bukti**.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Registri target tepercaya, isolasi bukti multi-sumber, sanitasi data, pembacaan spool hanya-baca (*read-only*), serta pencegahan kontaminasi silang bukti telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TN-006](../engineering-journal/diagnostic-mvp-pilot/TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md), [TN-016](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md), dan [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [TomcatDown Rule Specification](tomcat-down-rule-specification.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Restricted Event Collector Contract](restricted-event-collector-contract.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [TN-006 — Implement Target Isolation, Evidence Adapters, and TomcatDown Engine](../engineering-journal/diagnostic-mvp-pilot/TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md)
- [TN-016 — Implement Restricted Collector and Tomcat Runtime](../engineering-journal/diagnostic-mvp-pilot/TN-016-implement-restricted-collector-and-tomcat-runtime.md)
- [TM-ADR-0007 — Target Isolation and Bounded Evidence Collection](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0007.md)

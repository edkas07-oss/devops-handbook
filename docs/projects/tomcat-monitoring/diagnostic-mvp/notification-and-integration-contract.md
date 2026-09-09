# Notification and Integration Contract

## 🔍 Overview

Mailpit merupakan satu-satunya target pengiriman notifikasi aktif pada fase Diagnostic MVP. Integration Bridge dan TrueSight tetap direpresentasikan sebagai batas integrasi masa depan tetapi dalam status nonaktif (*disabled*).

---

## ✉️ Pengiriman Notifikasi Mailpit

Alertmanager mengarahkan **seluruh alert monitoring Tomcat** (termasuk `TomcatDown`, degradasi JVM GC & Concurrency, serta Application Health) secara eksklusif ke Diagnostic Service melalui webhook HTTPS internal dengan pengiriman status resolved aktif. Alertmanager tidak lagi mengirimkan alert mentah secara langsung ke Mailpit. 

Diagnostic Service bertindak sebagai otoritas tunggal yang memproses, mengevaluasi bukti, dan menerbitkan email laporan berformat 7-seksi SRE (Plain Text dan HTML) yang telah disanitasi melalui koneksi internal `mailpit:1025` menggunakan identitas pengirim dan penerima domain `.invalid`. Jalur direct email dari Alertmanager murni direservasi sebagai *Emergency Bypass* ketika container Diagnostic Service sendiri tidak dapat dihubungi (`DiagnosticServiceDown`).

---

## 📋 Kontrak Format Pesan Laporan (7-Section Report)

Setiap pesan mempertahankan makna kanonikal dan memuat siklus hidup, environment, target, waktu insiden, status pemrosesan, asesmen, tingkat keyakinan (*confidence* bila diizinkan), ringkasan bukti pendukung/tidak tersedia, rekomendasi SOP operator, identitas aturan, dan identifier diagnosis.

Format Plain Text dan HTML menggunakan urutan 7 seksi semantik yang sama:

| Nomor | Seksi Laporan | Isi Konten Wajib |
| ---: | :--- | :--- |
| **1** | **Alert Summary** | Judul alert, status siklus hidup (*firing/resolved*), keparahan (*severity*), environment, target, dan waktu insiden. |
| **2** | **Diagnostic Assessment** | Status pemrosesan, klasifikasi taksonomi, asesmen primer, dan tingkat keyakinan (*confidence*) jika klasifikasi mengizinkannya. |
| **3** | **Key Metrics Snapshot** | Snapshot metrik primer terbatas dengan waktu observasi dan status kueri, atau penanda eksplisit *unavailable/timeout*. |
| **4** | **Correlated Log Evidence** | Kutipan log terbatas dan tersanitasi yang dipilih berdasarkan target, generasi runtime, jendela waktu bukti, dan aturan diagnostik. |
| **5** | **Unavailable or Contradicting Evidence** | Sumber bukti yang mengalami timeout, tidak tersedia, belum dikonfigurasi, atau bertentangan dengan asesmen primer. |
| **6** | **Recommended Operator Actions** | Langkah investigasi dan SOP mitigasi yang aman bagi operator; tidak pernah berupa eksekusi remediasi otomatis. |
| **7** | **Rule and Diagnostic Traceability** | ID dan versi aturan, ID diagnostik, hash hasil SHA-256, dan timestamp bukti yang diperlukan untuk korelasi. |

Seksi keempat bukan sekadar ekor (*tail*) log acak. Seksi tersebut hanya memuat kutipan log berkorelasi yang telah lolos verifikasi identitas target, jendela waktu, batas ukuran, dan sanitasi rahasia. Kata-kata "akar masalah" (*root cause*) hanya digunakan untuk klasifikasi yang mengizinkan klaim tersebut (`confirmed_cause` / `probable_cause`). Hasil *partial*, *possible*, *symptom-only*, atau *undetermined* menyatakan batasannya secara eksplisit. Ketiadaan metrik atau log ditampilkan beserta status pengumpulannya dan tidak pernah dihilangkan secara diam-diam.

Perilaku siklus hidup pengiriman:
- Tepat satu laporan diagnostik firing awal per insiden;
- Tidak ada pesan baru untuk pengiriman firing duplikat yang identik;
- Maksimum satu pesan pembaruan untuk perubahan material (*material update*) pada hasil kanonikal;
- Pesan status partial, evidence-only, atau failed wajib menyatakan batasannya secara jelas;
- Tepat satu pesan pemulihan (*resolved message*), yang menggunakan kembali ringkasan firing tanpa mengklaim remediasi permanen.

Status pengiriman bersifat independen dari status klasifikasi dan confidence. Kegagalan SMTP dicatat di database dan diulang (*retry*) dengan kebijakan terbatas; kegagalan SMTP tidak dapat mengubah hasil diagnostik yang telah diputuskan.

---

## 🚫 Integrasi Nonaktif (*Disabled Integration*)

Selama dinonaktifkan, Integration Bridge dan TrueSight tidak memiliki endpoint aktif, kredensial, upaya koneksi, retry, item antrean, maupun worker pengiriman. Rencana aktivasi di masa depan hanya akan menerima proyeksi canonical result JSON terbatas. Integration Bridge secara mandiri yang akan mengelola pemetaan slot TrueSight dan eksekusi `msend` atau SNMP trap.

Diagnostic Service tidak memiliki dependensi runtime `msend`, pustaka SNMP umum, maupun alur remediasi otomatis.

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.5 / `devops-lab`).**
Perenderan laporan 7-seksi (HTML dan Plain Text) dengan rekomendasi SOP Bahasa Indonesia, penanganan siklus hidup firing/resolved, deduplikasi pesan, preservasi identitas alert dinamis (*Rule ID Fidelity*), serta pengiriman email terstruktur ke Mailpit telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan `devops-lab` ([TM-ADR-0016](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md), [TM-ADR-0023](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0023.md), [TN-007](../engineering-journal/diagnostic-mvp-pilot/TN-007-implement-worker-canonical-result-and-renderers.md), [TN-008](../engineering-journal/diagnostic-mvp-pilot/TN-008-implement-secure-service-and-smtp-delivery-boundaries.md), [TN-012](../engineering-journal/diagnostic-mvp-pilot/TN-012-implement-bounded-notification-delivery-orchestration.md), [TN-013](../engineering-journal/diagnostic-mvp-pilot/TN-013-rebuild-and-verify-diagnostic-service-mailpit-runtime.md), [TN-015](../engineering-journal/diagnostic-mvp-pilot/TN-015-deploy-persistent-monitoring-runtime.md), [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md), dan [TN-006](../engineering-journal/monitoring-platform-integration/TN-006-implement-multi-domain-diagnostic-dispatcher-and-decision-engines.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [TomcatDown Rule Specification](tomcat-down-rule-specification.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [SQLite Lifecycle Contract](sqlite-lifecycle-contract.md)
- [TN-007 — Implement Worker, Canonical Result, and Renderers](../engineering-journal/diagnostic-mvp-pilot/TN-007-implement-worker-canonical-result-and-renderers.md)
- [TN-012 — Implement Bounded Notification Delivery Orchestration](../engineering-journal/diagnostic-mvp-pilot/TN-012-implement-bounded-notification-delivery-orchestration.md)
- [TN-017 — Verify End-to-End Incident Diagnostic Flow](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)
- [TM-ADR-0009 — Seven-Section Structured Notification Delivery](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0009.md)

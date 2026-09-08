# TM-ADR-0012

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0012 |
| **Title** | Decouple TrueSight Through a Disabled Integration Bridge |
| **Project** | Tomcat Monitoring |
| **Section** | External Integration Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Mailpit merupakan satu-satunya target pengiriman notifikasi yang aktif pada Diagnostic MVP. Pengiriman masa depan ke TrueSight diisolasi di balik komponen Integration Bridge yang statusnya dinonaktifkan (*disabled*).

## 🌍 Context

Spesifikasi kontrak, kredensial, mekanisme keamanan, kelas event (*event classes*), slot atribut, dan semantik penutupan alert (*closure semantics*) untuk TrueSight belum tersedia. Menambahkan CLI `msend` atau dependensi SNMP generik ke dalam container Diagnostic Service akan mengikat erat sistem diagnostik ke satu platform vendor eksternal tertentu.

## ⚖️ Decision

Diagnostic Service menyusun dan mengirimkan email ke Mailpit berdasarkan laporan *canonical result*.

Selama dinonaktifkan, Integration Bridge dan TrueSight tidak memiliki endpoint aktif, kredensial, koneksi jaringan, mekanisme retry, antrean, maupun aktivitas background worker. Pengaktifan di masa depan akan mengirimkan proyeksi payload JSON kanonikal dengan batasan ukuran tertentu; hanya komponen bridge yang bertanggung jawab memetakan atribut dan menangani transport ke TrueSight.

Keputusan ini memperjelas status aktivasi yang telah disebutkan pada TM-ADR-0001 tanpa mengubah arsitektur instrumentasi tertanamnya (*embedded instrumentation*): integrasi TrueSight adalah target masa depan, bukan implementasi lab saat ini.

## 🏛️ Architecture

Alur aktif: `Canonical result -> Mailpit`.

Alur nonaktif: `Canonical result -.-> Integration Bridge -.-> TrueSight` (tetap disabled).

## 💡 Rationale

Batasan isolasi ini menjaga agar semantik diagnostik tetap independen dari platform eksternal tertentu, serta mencegah kendala pada sistem eksternal yang belum siap memengaruhi proses klasifikasi atau pengiriman notifikasi ke Mailpit.

## ⚠️ Consequences

- Fase pilot tidak membuktikan pengiriman event ke TrueSight secara nyata.
- Pengaktifan integrasi di masa mendatang memerlukan kontrak terpisah, pengelolaan secret/kredensial, pemetaan skema, pengelolaan siklus hidup, serta verifikasi skenario kegagalan dan penutupan status (*resolved state*).

## 📌 Status

**Accepted — verified with disabled integration bridge in devops-lab.**

## 📅 Date

**2026-08-30**

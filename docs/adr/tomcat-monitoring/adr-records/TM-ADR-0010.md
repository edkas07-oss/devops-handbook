# TM-ADR-0010

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0010 |
| **Title** | Deploy One Bounded Diagnostic Service per Tomcat Host |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Deployment Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Satu instans Diagnostic Service yang ringan dideploy per host Tomcat untuk menangani satu atau lebih target Tomcat lokal yang terdaftar dalam allowlist secara eksplisit, dengan menggunakan satu worker.

## 🌍 Context

Bukti diagnostik bersifat lokal pada host dan dilarang bercampur lintas target. Beban kerja monitoring tidak boleh bersaing secara material dalam konsumsi CPU dan memori dengan runtime aplikasi Tomcat. Layanan ini juga memiliki kode sumber yang reusable dan siklus hidup image yang terpisah dari konfigurasi integrasi spesifik lingkungan.

## ⚖️ Decision

Repositori `tomcat-diagnostic-service` bertanggung jawab atas kode sumber aplikasi, penguncian dependensi (*dependency lock*), siklus hidup image, migrasi skema database, dan pengujian komponen.

Repositori `tomcat-monitoring` mengelola konfigurasi target, alur perutean (*routing*), referensi secret, deployment, validasi integrasi, dan orkestrasi lab.

Batasan sumber daya awal yang ditetapkan adalah:
- 1 background worker.
- Kapasitas antrean maksimum 50 event.
- Batas waktu diagnostik 60 detik (*diagnostic timeout*).
- Batas memori 256 MiB.
- Batas CPU 500m (0,5 core).

## 🏛️ Architecture

Setiap host mendeploy satu container Diagnostic Service dan satu volume penyimpanan state lokal. Identitas kanonikal dan daftar allowlist mengisolasi beberapa instans Tomcat yang berjalan pada host yang sama.

## 💡 Rationale

Menjalankan layanan diagnostik terpisah untuk setiap container Tomcat akan menggandakan *overhead* konsumsi resource; sebaliknya, satu layanan terpusat untuk multi-host akan melemahkan prinsip lokalitas bukti serta memperluas kebutuhan kredensial akses jaringan. Penempatan satu layanan per host dengan batasan sumber daya ketat memberikan keseimbangan yang optimal antara isolasi keamanan, lokalitas bukti, dan efisiensi sumber daya.

## ⚠️ Consequences

- Diperlukan dua repositori runtime baru untuk service dan collector.
- Operasi *active-active* horizontal pada host yang sama tidak didukung.
- Kapasitas beban host memerlukan pengujian yang representatif.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-30**

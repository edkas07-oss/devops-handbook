# TM-ADR-0014

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0014 |
| **Title** | Enforce Zero Automatic Remediation for Diagnostic Service |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Safety and Operational Governance Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-31 |

---

## 🔍 Overview

Diagnostic Service dirancang murni sebagai sistem analisis dan penasihat (*read-only advisory engine*). Layanan ini tidak memiliki wewenang untuk mengeksekusi perbaikan otomatis (*zero automatic remediation*) terhadap proses Tomcat, container, maupun sistem operasi host.

## 🌍 Context

Ketika insiden ketersediaan (`TomcatDown`) terdeteksi, sering kali muncul dorongan operasional untuk langsung memicu tindakan perbaikan otomatis (*self-healing / auto-remediation*), seperti menjalankan `systemctl restart tomcat`, me-restart container Podman, mematikan proses yang macet (*process kill*), atau menghapus file sementara.

Namun, tindakan pemulihan aktif yang dijalankan oleh sistem otomatis pada fase awal pemantauan mengandung risiko operasional yang sangat berbahaya:

1. **Kegagalan Berulang (*Reboot Loop & Action Flapping*):** Jika akar masalah insiden adalah file konfigurasi XML yang rusak, sertifikat TLS yang kedaluwarsa, atau kapasitas disk penuh (*storage full*), me-restart Tomcat secara otomatis hanya akan gagal berulang kali dan membebani server.
2. **Hilangnya Bukti Diagnostik (*Artifact Destruction*):** Restart otomatis dapat menghapus kondisi memori, me-reset file crash dump (`hs_err_pid`), dan menimpa baris log sebelum tim sempat memeriksanya.
3. **Risiko Keamanan Akses (*Privilege Escalation*):** Memberikan izin bagi container diagnostik untuk menjalankan perintah sistem operasi akan memaksa pembukaan akses root/sudo atau mengekspos socket Podman/Docker ke dalam container, yang bertentangan dengan prinsip keamanan hak akses minimal (*least-privilege isolation*).

## ⚖️ Decision

Ditetapkan kebijakan arsitektur **Zero Automatic Remediation**:

1. Diagnostic Service dan Restricted Event Collector dilarang memiliki fungsi, script, antarmuka, maupun hak akses untuk memodifikasi state proses Tomcat, container, volume penyimpanan, network namespace, maupun konfigurasi host.
2. Output dari layanan diagnostik dibatasi hanya pada:
    - Pengumpulan dan korelasi bukti deterministik secara hanya-baca (*read-only evidence*).
    - Klasifikasi kategori masalah dan penentuan tingkat keyakinan (*confidence level*).
    - Penyusunan rekomendasi langkah penanganan yang jelas bagi operator melalui laporan *canonical result*.
3. Tindakan korektif aktif di lapangan tetap menjadi wewenang dan tanggung jawab penuh operator manusia (*human-in-the-loop triage*).

## 🏛️ Architecture

```text
Alertmanager Webhook
        |
        v
Diagnostic Service (Read-Only Engine)
        |
        +---> Baca Metrik Prometheus (Pull HTTPS)
        +---> Baca Log Tomcat (:ro)
        +---> Baca Event Spool (:ro)
        |
        v
Evaluasi Rule Engine Deterministik
        |
        v
Canonical Result + Rekomendasi Tindakan
        |
        v
Notifikasi Mailpit (Laporan kepada Operator)
        |
        x  [BLOCKED] Eksekusi Perintah Host / Restart (Zero Remediation)
        |
        v
Operator Manusia (Verifikasi & Tindakan Korektif Manual)
```

Diagnostic Service beroperasi dalam batasan hanya-baca (*read-only boundary*) yang ketat: direktori log dan spool dipasang dengan opsi `:ro,z`, container berjalan sebagai non-root (*rootless*), serta tanpa akses ke socket container runtime host (`podman.sock`).

## 💡 Rationale

Kebijakan **Zero Automatic Remediation** ditetapkan sebagai **keputusan arsitektur tingkat tinggi (*high-level architectural decision*)** karena secara fundamental menentukan batasan peran sistem, arsitektur keamanan, dan postur operasional. Keputusan untuk tidak melakukan perbaikan otomatis ini didasari oleh pertimbangan strategis berikut:

1. **Menetapkan Batasan Peran Sistem yang Tegas (*System Boundaries*):**
   Keputusan ini memposisikan Diagnostic Service murni sebagai **pengamat dan penasihat independen (*advisory engine*)**, bukan eksekutor. Memisahkan fungsi analisis dari fungsi eksekusi menjaga objektivitas hasil diagnosis dan memastikan sistem tidak mengambil tindakan berbahaya saat data bukti belum sepenuhnya lengkap.

2. **Mencegah Kerusakan Sistem yang Lebih Fatal (*Cascading Failure & Flapping*):**
   Dalam operasional nyata, me-restart aplikasi secara otomatis sering kali justru memperparah keadaan jika akar masalahnya bersifat persisten (misalnya konfigurasi XML salah, sertifikat kedaluwarsa, atau kapasitas disk penuh). Siklus restart berulang (*reboot loop*) yang dipicu oleh bot otomatis dapat merusak integritas basis data aplikasi dan memperpanjang masa downtime.

3. **Menjaga Keamanan dengan Prinsip Hak Akses Minimal (*Least Privilege*):**
   Jika layanan diagnostik diberi wewenang untuk memperbaiki proses atau me-restart Tomcat, container tersebut harus diberi hak istimewa (*root access* atau akses ke socket Podman/Docker host). Menolak perbaikan otomatis memungkinkan container dikunci secara ketat dalam mode *rootless* dan *read-only*, sehingga membatasi dampak bahaya (*blast radius*) jika container mengalami celah keamanan.

4. **Biaya dan Risiko Perubahan Terlalu Besar Jika Diizinkan Sejak Awal:**
   Menerapkan perbaikan otomatis menuntut arsitektur yang sangat rumit sejak hari pertama (seperti manajemen kredensial host, mekanisme pencegah loop, penanganan deadlock, dan audit trail aksi). Sangat sulit dan mahal untuk membatalkan atau mencabut hak eksekusi tersebut di kemudian hari jika komponen sistem lain sudah terlanjur bergantung padanya.

5. **Trade-off Sadar: Mengutamakan Keselamatan Sistem Dibandingkan Kecepatan Instan:**
   Arsitektur ini secara sadar memilih **keselamatan sistem, integritas data, dan akurasi bukti** daripada mengejar pemulihan instan tanpa manusia (*zero-touch recovery*). Dalam lingkungan produksi, tindakan otomatis yang salah sasaran (*false action*) jauh lebih berbahaya daripada waktu henti (*downtime*) terukur yang disertai rekomendasi perbaikan akurat bagi operator manusia.

## ⚠️ Consequences

- **Kelebihan:**
  - Keamanan sistem terlindungi maksimal karena container tidak membutuhkan hak akses root host atau socket runtime Podman.
  - Mencegah bahaya gangguan berantai (*incident cascade*) seperti looping restart.
  - Bukti insiden (log dan crash dump) tetap utuh untuk dianalisis oleh tim SRE.
- **Keterbatasan:**
  - Waktu pemulihan layanan (*MTTR*) masih bergantung pada kecepatan respons operator yang menerima notifikasi.
  - Laporan diagnosis harus menyajikan rekomendasi langkah penanganan (*recommended actions*) yang sangat jelas agar operator dapat mengambil tindakan dengan cepat dan tepat.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-31**

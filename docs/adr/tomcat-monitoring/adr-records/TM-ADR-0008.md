# TM-ADR-0008

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0008 |
| **Title** | Use a Restricted Host Event Collector with a Normalized Evidence Spool |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Security Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Bukti dari host dan container diekspos melalui komponen kolektor non-root (*rootless collector*) yang menulis berkas spool ternormalisasi dengan ukuran terbatas, yang hanya dapat dibaca (*read-only*) oleh Diagnostic Service.

## 🌍 Context

Melakukan mount socket Podman secara luas (`podman.sock`) atau memberikan izin eksekusi perintah host ke container diagnostik akan mengubah komponen pembaca bukti menjadi celah kontrol runtime (*runtime-control surface*) yang berbahaya. Sebagian bukti host juga memiliki kebutuhan hak akses (*privilege*) dan siklus hidup yang berbeda dari container Diagnostic Service.

## ⚖️ Decision

Runtime host `tomcat-diagnostic-event-collector` yang dikelola secara terpisah hanya membaca identitas proses/container dan tipe bukti yang telah terdaftar dalam allowlist, kemudian menulis record berversi dengan batas ukuran tertentu secara atomik.

Diagnostic Service dilarang mengirimkan kueri acak maupun memicu perintah kontrol ke host. Bukti yang tidak dapat diakses melalui mode rootless yang disetujui dibiarkan tetap tidak tersedia (*remains unavailable*).

## 🏛️ Architecture

`Bukti host -> Restricted collector -> Spool ternormalisasi -> Adapter read-only Diagnostic Service` merupakan batasan komunikasi satu arah (*one-way boundary*).

## 💡 Rationale

Format berkas spool menghilangkan kebutuhan akan antarmuka API kueri/kontrol, memungkinkan validasi skema dan ukuran berkas secara ketat, serta mengisolasi hak akses level host dari container layanan diagnostik.

## ⚠️ Consequences

- Membutuhkan repositori dan siklus hidup terpisah untuk komponen collector.
- Kebijakan retensi, penulisan atomik, hak akses berkas (*file permissions*), dan kebaruan data (*freshness*) memerlukan pengujian eksplisit.
- Sebagian bukti level kernel atau root mungkin tidak tersedia dalam mode operasi rootless.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-30**

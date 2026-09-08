# TM-ADR-0011

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0011 |
| **Title** | Use Per-Rule Decision Tables for Diagnostic Confidence |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Rule Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Klasifikasi diagnostik dan tingkat keyakinan (*confidence level*) ditentukan melalui cabang aturan (*rule branches*) yang eksplisit dan berversi, bukan menggunakan sistem skor aditif/kumulatif yang generik.

## 🌍 Context

Berbagai sumber bukti memiliki tingkat otoritas yang berbeda dan dapat saling bertolak belakang (*contradictory*). Penilaian berbasis skor numerik atau persentase generik dapat memberikan kesan kepastian semu yang belum tervalidasi pada tahap pilot.

## ⚖️ Decision

Setiap aturan diagnostik mendefinisikan urutan kondisi bukti, kondisi kontradiksi, klasifikasi kategori, tingkat keyakinan yang diizinkan, serta bukti langsung yang wajib dipenuhi.

Penyebab yang terkonfirmasi (*confirmed cause*) wajib didukung oleh bukti langsung berkeyakinan tinggi (*high-confidence direct evidence*) dengan korelasi waktu kejadian yang sesuai. Hasil klasifikasi `undetermined` (tidak dapat dipastikan) dan `not_supported` (tidak didukung) tidak diberikan nilai tingkat keyakinan (*no confidence value*).

## 🏛️ Architecture

Bukti yang telah dinormalisasi dievaluasi ke dalam versi aturan yang dipilih; cabang aturan pertama yang cocok dan disetujui (*first matching approved branch*) akan menghasilkan field asesmen pada laporan *canonical result* versi `1`.

## 💡 Rationale

Tabel keputusan (*decision tables*) dapat diuji secara komprehensif, mudah dipahami dan dijelaskan kepada operator (*explainable*), serta bersifat deterministik. Penggunaan skor generik, nilai persentase, dan interpretasi bebas di sisi renderer notifikasi ditolak.

## ⚠️ Consequences

- Setiap aturan diagnostik yang dipromosikan memerlukan peninjauan tabel keputusan dan dataset pengujian (*test fixtures*) tersendiri.
- Setiap modifikasi aturan memerlukan penomoran versi baru dan pengujian regresi deterministik.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-30**

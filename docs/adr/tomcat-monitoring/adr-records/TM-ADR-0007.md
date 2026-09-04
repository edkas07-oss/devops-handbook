# TM-ADR-0007

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0007 |
| **Title** | Treat TomcatDown as a Composite Diagnostic Trigger |
| **Project** | Tomcat Monitoring |
| **Section** | Alert and Diagnostic Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-30 |

---

## 🔍 Overview

Kondisi `up{job="tomcat-jmx-exporter"} == 0` selama dua menit berfungsi sebagai pemicu (*trigger*) investigasi diagnostik; kondisi tersebut tidak membuktikan bahwa proses Apache Tomcat benar-benar mati (*down*).

## 🌍 Context

Kegagalan pengambilan metrik (*scrape failure*) oleh Prometheus dapat disebabkan oleh berbagai faktor: penghentian proses Tomcat, kegagalan internal pada JMX Exporter Java Agent, masalah sertifikat TLS, kesalahan konfigurasi, kendala jaringan, atau kegagalan pada alur internal Prometheus itu sendiri. Sering kali endpoint health aplikasi masih aktif dan melayani lalu lintas pengguna meskipun proses scrape JMX mengalami kegagalan.

## ⚖️ Decision

Pilot tahap pertama hanya mengaktifkan aturan diagnostik untuk `TomcatDown`. Aturan ini mengorelasikan metrik Prometheus, status health aplikasi (opsional), file log, artefak crash dump, status runtime container, dan event host melalui tabel keputusan (*decision table*) berversi.

Aturan diagnostik untuk kegagalan health aplikasi (`ApplicationDown`) dan penggunaan memori tinggi (`HighHeapUsage`) tetap dinonaktifkan pada tahap pilot ini.

## 🏛️ Architecture

Prometheus mendeteksi kondisi tidak responsif yang bertahan selama batas evaluasi, Alertmanager mengirimkan webhook event *firing* dan *resolved*, dan Diagnostic Service menentukan apakah Tomcat terbukti tidak tersedia (*proven unavailable*) atau kegagalan tersebut sebenarnya berada pada alur monitoring lain (*monitoring-path failure*).

## 💡 Rationale

Pendekatan ini mempertahankan kecepatan deteksi berbasis metrik tanpa mengubah kegagalan pada alur monitoring menjadi klaim akar masalah palsu (*false root-cause claim*).

## ⚠️ Consequences

- Hasil evaluasi diagnostik dapat berstatus sah sebagai tidak dapat dipastikan (*undetermined*) atau hanya terbukti sebagian (*partial*).
- Memerlukan adapter pengumpul bukti (*evidence adapters*) dan pengujian isolasi kegagalan yang lebih banyak dibandingkan pengiriman email alert konvensional secara langsung.

## 📌 Status

**Accepted — implementasi rule dan diagnostik ditunda (rule and diagnostic implementation pending).**

## 📅 Date

**2026-08-30**

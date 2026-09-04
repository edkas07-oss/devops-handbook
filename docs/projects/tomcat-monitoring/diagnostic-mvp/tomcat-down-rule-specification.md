# TomcatDown Rule Specification

## 🔍 Overview

Alert `TomcatDown` dipicu ketika Prometheus mengalami kegagalan beruntun saat mengambil metrik (*scrape*) dari endpoint Tomcat JMX Exporter. Pemicuan alert ini menjadi titik awal bagi Diagnostic Service untuk mengumpulkan dan mengorelasikan bukti-bukti operasional dalam rentang waktu terbatas (*bounded evidence correlation*).

Perlu ditekankan bahwa status alert ini menunjukkan hilangnya keterjangkauan metrik JMX dan tidak secara otomatis membuktikan bahwa proses JVM Tomcat telah mati total.

---

## 📋 Alert Contract

| Parameter | Pilot Value |
| :--- | :--- |
| Alert Name | `TomcatDown` |
| PromQL Expression | `up{job="tomcat-jmx-exporter"} == 0` |
| Duration (*For*) | `2m` |
| Severity | `critical` |
| Applied Scrape Interval | `30s` |
| Service Label | `tomcat` |
| Check Label | `runtime-availability` |

Klausul Durasi (`for: 2m`) mewajibkan kondisi evaluasi (`up == 0`) bernilai benar (*true*) secara terus-menerus tanpa putus selama minimal 2 menit sebelum status alert berubah dari `Pending` menjadi `Firing` (mengirimkan alert).

Dengan interval *scrape* 30 detik, durasi 2 menit setara dengan 4 kali *scrape* berturut-turut:

| Timestamp | Scrape Cycle | Tomcat Status | Evaluation (`up == 0`) | Alert State |
| :---: | :--- | :---: | :---: | :--- |
| `00:00` | Interval 1 | `Down` | `True` | `Pending` (timer started) |
| `00:30` | Interval 2 | `Down` | `True` | `Pending` (elapsed: 30s) |
| `01:00` | Interval 3 | `Up` | `False` | `Reset` (recovered, timer aborted) |
| `01:30` | Interval 4 | `Up` | `False` | `Inactive` |

Karena pada interval 3 (menit ke-1) Tomcat sudah kembali aktif (`up == 1`), kondisi alert langsung batal terpenuhi. Ambang batas durasi 2 menit tidak tercapai, sehingga tidak ada alert yang ditembakkan atau terkirim ke Alertmanager.

Durasi evaluasi `2m` setara dengan empat siklus *scrape* berturut-turut (interval `30s`). Oleh karena itu, setiap modifikasi pada interval *scrape*, nama target, ekspresi PromQL, maupun durasi alert wajib ditinjau ulang terhadap kontrak arsitektur serta divalidasi melalui pengujian aturan.

Identitas unik sebuah instance Tomcat ditentukan secara kanonikal melalui gabungan label: `environment`, `host`, dan `tomcat_instance`. Sementara itu, label `job` dan `instance` hanya digunakan untuk identifikasi teknis koneksi Prometheus, dan label `application` bersifat opsional sebagai metadata pelengkap.

---

## 🧩 Time Window and Evidence Sources

Diagnostic Engine mengevaluasi bukti telemetri dalam rentang waktu terbatas (*bounded time window*) dengan batas eksekusi global (*global timeout*) maksimal **60 detik**.

### Bounded Time Window

Rentang waktu pengumpulan data dibatasi secara presisi di sekitar waktu insiden:

```text
startsAt - 15 Menit              startsAt (Waktu Insiden)          Diagnosis + 2 Menit
        ├─── Konteks Historis ─────────────┼─── Bukti Pasca-Insiden ──────┤
        ◄── Log aplikasi, scrape sampel ───►◄── Exit event, crash dump ───►
        └─────────────── Total Jendela Evaluasi Bukti ────────────────────┘
```

1. **Batas Awal (*Lookback Window*):** Menarik log dan sampel metrik hingga **15 menit sebelum insiden terjadi (`startsAt`)** untuk menangkap anomali awal sebelum layanan down.
2. **Batas Akhir (*Lookahead Window*):** Mengumpulkan bukti hingga **2 menit setelah proses diagnosis dimulai** untuk menangkap status akhir kontainer atau event terminasi.
3. **Batas Eksekusi Global (*Global Timeout*):** Seluruh proses pengumpulan bukti oleh Diagnostic Engine wajib selesai dalam waktu maksimal **60 detik**.

### Evidence Sources Matrix

Diagnostic Engine mengorelasikan bukti dari lima sumber data independen:

| Evidence Source | Data Collected & Purpose | Requirement Policy |
| :--- | :--- | :--- |
| **Prometheus** | Status scrape JMX, sampel metrik sukses terakhir, dan error koneksi TLS. | Required Attempt |
| **Application Health** | Status HTTP `/health` untuk membedakan proses yang masih melayani traffic dari kegagalan jalur monitoring. | Supporting (Optional) |
| **Tomcat Logs** | Riwayat siklus hidup, kegagalan startup, shutdown normal, error port binding (`BindException`), dan anomali JVM. | Required Attempt (if configured) |
| **JVM Crash Artifacts** | Bukti fatal crash JVM pada host (misalnya berkas dump `hs_err_pid*.log` atau fatal SIGSEGV). | Bounded (Optional) |
| **Restricted Event Collector** | Bukti status kontainer runtime, kernel cgroup OOM kill, exit code, dan event stop/restart host. | Required Attempt (if configured) |

### Evidence Governance & Timeout Rules

1. **Prinsip Tanpa Bukti Negatif (*No Negative Proof*):**
   Sumber bukti yang tidak dapat diakses atau berkas yang tidak ditemukan dicatat dengan status `unavailable`. Ketiadaan data telemetri tidak boleh dianggap sebagai bukti bahwa suatu kejadian (misalnya fatal crash atau OOM kill) tidak terjadi.
2. **Batas Waktu Per-Adapter (*Per-Adapter Timeout*):**
   Adapter Prometheus memiliki batas waktu maksimal **5 detik** per sesi diagnosis (mencakup pembentukan koneksi TLS dan penerimaan respons). Jika batas waktu 5 detik terlampaui:
   - Adapter Prometheus mengembalikan status `timeout`.
   - Proses diagnostik **tidak dibatalkan**, dan Diagnostic Engine tetap melanjutkan analisis dengan bukti dari sumber lain.
   - Pada hasil kanonikal (*canonical result*) dan laporan email, status Prometheus dilaporkan secara transparan sebagai `unavailable`.

---

## ⚖️ Deterministic Decision Table

Evaluasi aturan dijalankan secara berurutan dari atas ke bawah. Cabang aturan pertama yang seluruh kondisinya terpenuhi (*first matching branch*) langsung ditetapkan sebagai kesimpulan utama (*primary assessment*).

| Cabang | Korelasi Bukti Terkait | Asesmen (*Primary Assessment*) | Klasifikasi | Tingkat Keyakinan |
| :---: | :--- | :--- | :---: | :---: |
| **TD-01** | Scrape JMX gagal; health check aplikasi sukses; container dalam status berjalan (*running*). | Tomcat tidak terbukti down; JMX Exporter, TLS, atau jalur scrape mengalami kegagalan. | `probable_cause` | `medium` |
| **TD-02** | Scrape JMX dan health check aplikasi gagal; runtime mencatat terminasi OOM kill atau kenaikan cgroup `oom_kill` sebelum container keluar. | Container dihentikan paksa oleh mekanisme Linux kernel OOM killer. | `confirmed_cause` | `high` |
| **TD-03** | Penanda fatal JVM pada log, crash artifact yang cocok, dan event terminasi runtime saling berkorelasi. | Terjadi fatal crash pada JVM (misal SIGSEGV/core dump). | `confirmed_cause` | `high` |
| **TD-04** | Sekuen startup, log `BindException` pada connector, dan startup yang tidak tuntas saling berkorelasi. | Startup connector Tomcat gagal karena port yang dikonfigurasi tidak dapat di-bind. | `confirmed_cause` | `high` |
| **TD-05** | Log shutdown normal (*orderly shutdown*) dan event stop eksplisit saling berkorelasi. | Shutdown terkontrol atau dihentikan secara sengaja dari luar. | `confirmed_cause` | `high` |
| **TD-06** | Container telah keluar (*exited*), tetapi tidak ditemukan bukti penyebab yang disetujui dalam aturan. | Container keluar (*exited*); penyebab spesifik belum dapat ditentukan. | `undetermined` | *None* (`null`) |
| **TD-07** | Container berjalan, sementara JMX dan health check timeout disertai bukti jeda panjang (*long-pause* JVM/GC). | Tomcat berpotensi tidak responsif (*freeze*); proses tidak terbukti mati. | `possible_cause` | `medium` |
| **TD-08** | Sumber bukti wajib tidak tersedia atau bukti telemetri saling bertentangan tanpa cabang penentu yang cocok. | Penyebab tidak dapat ditentukan dari bukti yang tersedia. | `undetermined` | *None* (`null`) |

!!! note "Ekstensibilitas Dynamic Rulepack (TD-09+)"
    Selain aturan inti TD-01 s/d TD-08, Diagnostic Service dilengkapi dengan **Declarative Rulepack Engine** (`rulepack-v1.schema.json`). Aturan deklaratif kustom (seperti `TD-09` *DatabaseConnectionPoolExhausted*) dievaluasi setelah pemeriksaan kontradiksi dan sebelum fallback TD-08 tanpa memerlukan modifikasi kode inti engine.

Logika evaluasi menerapkan aturan ketat: bukti langsung yang saling bertentangan selalu diprioritaskan sebelum bukti pendukung dianalisis. Potongan teks log yang bersifat umum tidak dapat digunakan sebagai dasar konfirmasi tanpa dukungan korelasi runtime yang sah. Seluruh proses pengambilan keputusan bersifat deterministik mutlak untuk masukan bukti dan `rule_version` yang sama.

---

## 🔄 Alert Lifecycle

- **Notifikasi Pemicuan Awal (*Initial Firing*):** Menjalankan siklus diagnosis menyeluruh, menyimpan status insiden ke database SQLite, dan menerbitkan satu laporan hasil kanonikal awal ke Mailpit.
- **Pemicuan Duplikat (*Duplicate Firing*):** Webhook firing berulang dari Alertmanager akan diakui dengan respons `202 Accepted` tanpa menjalankan ulang proses diagnosis atau mengirim notifikasi ganda.
- **Pembaruan Material (*Material Update*):** Jika bukti baru yang masuk mengubah klasifikasi diagnosis secara signifikan, engine diizinkan mengirimkan maksimal 1 kali notifikasi pembaruan selama insiden aktif berlangsung.
- **Pemulihan Insiden (*Resolved*):** Saat menerima sinyal *resolved*, engine mengambil riwayat insiden dari SQLite untuk menyusun dan mengirimkan notifikasi pemulihan tanpa mengulang proses diagnosis dari awal.
- **Pemulihan Tanpa Insiden Sebelumnya (*Resolved without Prior Firing*):** Event dicatat dengan status `resolved_without_previous_firing` tanpa menghasilkan data diagnostik buatan.

---

## ✅ Acceptance and Verification Scenarios

Seluruh skenario pengujian otomatis dan verifikasi deterministik distandarkan ke dalam dua kelompok pengujian berikut:

### Evidence Correlation and Rule Decision Scenarios

| No | ID Skenario | Kondisi / Bukti Input | Asesmen / Cabang Aturan | Hasil yang Diharapkan |
| :---: | :---: | :--- | :---: | :--- |
| 1 | **TC-01** | Scrape JMX gagal, health check aplikasi sukses, container status *running*. | `TD-01` (`probable_cause`) | JMX/TLS failure; Tomcat tidak terbukti mati. |
| 2 | **TC-02** | Scrape JMX dan health check gagal, log/cgroup mencatat Linux OOM kill. | `TD-02` (`confirmed_cause`) | Terminasi oleh kernel OOM killer terkonfirmasi. |
| 3 | **TC-03** | JVM crash fatal log / core dump (`hs_err_pid*.log`) berkorelasi dengan event runtime. | `TD-03` (`confirmed_cause`) | Fatal crash JVM terkonfirmasi. |
| 4 | **TC-04** | Sekuen startup mendeteksi `BindException` pada connector port. | `TD-04` (`confirmed_cause`) | Kegagalan startup port binding terkonfirmasi. |
| 5 | **TC-05** | Log shutdown normal (*orderly shutdown*) berkorelasi dengan stop event. | `TD-05` (`confirmed_cause`) | Penghentian terkontrol/sengaja terkonfirmasi. |
| 6 | **TC-06** | Container berstatus *exited* tanpa bukti penyebab spesifik yang valid. | `TD-06` (`undetermined`) | Container exited; penyebab belum teridentifikasi. |
| 7 | **TC-07** | Container *running*, JMX/health check timeout, bukti *long-pause* GC/JVM. | `TD-07` (`possible_cause`) | Proses Tomcat berpotensi *freeze* / tidak responsif. |
| 8 | **TC-08** | Bukti telemetri saling bertentangan atau sumber wajib tidak tersedia. | `TD-08` (`undetermined`) | Fallback deterministik tanpa spekulasi fiktif. |
| 9 | **TC-09** | Aturan dinamis `TD-09` (*DatabaseConnectionPoolExhausted*) dimuat via Rulepack API. | `TD-09` (`confirmed_cause`) | Remapping firing otomatis ke rulepack deklaratif. |

### Engine Resilience, Lifecycle, and Integration Scenarios

| No | ID Skenario | Aspek Verifikasi | Perilaku yang Divalidasi |
| :---: | :---: | :--- | :--- |
| 10 | **TC-10** | *Prometheus Adapter Timeout* | Batas waktu 5 detik diterapkan; ketiadaan metrik tidak membatalkan alur diagnostik. |
| 11 | **TC-11** | *Deduplikasi Firing* | Event webhook firing berulang diabaikan tanpa re-evaluasi atau notifikasi duplikat. |
| 12 | **TC-12** | *Material Update Protection* | Maksimum 1 kali pembaruan notifikasi jika klasifikasi hasil kanonikal berubah. |
| 13 | **TC-13** | *SQLite Restart Persistence* | Database SQLite dan antrean event bertahan utuh saat service di-restart. |
| 14 | **TC-14** | *Mailpit Retry & Delivery* | Retensi pengiriman SMTP tahan terhadap downtime Mailpit dan mengirimkan alert resolved. |

---

## 📌 Status

**Implemented & Verified in Runtime (`tomcat-diagnostic-service` v0.1.4 / `devops-lab`).**
Seluruh spesifikasi aturan deterministik, korelasi bukti multi-sumber, siklus hidup firing/resolved, serta integrasi Declarative Rulepack Engine (`TD-01` s/d `TD-09`) telah diimplementasikan 100% dan terverifikasi secara live pada lingkungan persisten `devops-lab` ([TN-006](../engineering-journal/diagnostic-mvp-pilot/TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md), [TN-014](../engineering-journal/diagnostic-mvp-pilot/TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md), [TN-017](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md), [TN-018](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md), dan [TN-019](../engineering-journal/diagnostic-mvp-pilot/TN-019-verify-ai-enrichment-and-incident-remapping.md)).

---

## 🔗 Related Documentation

- [Diagnostic MVP Index](index.md)
- [Alertmanager Webhook Contract](alertmanager-webhook-contract.md)
- [Target and Evidence Contract](target-and-evidence-contract.md)
- [Diagnostic Result and Confidence Contract](diagnostic-result-and-confidence-contract.md)
- [Restricted Event Collector Contract](restricted-event-collector-contract.md)
- [Knowledge Base and AI Enrichment Architecture](knowledge-base-and-ai-enrichment-architecture.md)
- [TN-006 — Implement Target Isolation, Evidence Adapters, and TomcatDown Engine](../engineering-journal/diagnostic-mvp-pilot/TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md)
- [TN-014 — Configure TomcatDown Rule and Alertmanager Diagnostic Route](../engineering-journal/diagnostic-mvp-pilot/TN-014-configure-tomcatdown-rule-and-alertmanager-diagnostic-route.md)
- [TN-017 — Verify End-to-End Incident Diagnostic Flow](../engineering-journal/diagnostic-mvp-pilot/TN-017-verify-end-to-end-incident-diagnostic-flow.md)
- [TN-018 — Implement Strict Declarative Rulepack Engine](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)
- [TM-ADR-0004 — Deterministic Alert Rule Specification](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md)

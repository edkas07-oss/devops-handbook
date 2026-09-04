# Frequently Asked Questions (FAQ)

## 🔍 Overview

Halaman ini mendokumentasikan pertanyaan yang sering diajukan (*Frequently Asked Questions*), prinsip arsitektur, dan panduan teknis mendalam mengenai platform **Tomcat Monitoring & Autonomous Diagnostic Platform**.

Dokumentasi ini ditujukan bagi Operator SRE, System Administrator, dan Engineer yang ingin memahami mekanisme internal pengambilan keputusan diagnosis, alur pengayaan pengetahuan (*AI Knowledge Enrichment*), serta standar keamanan dan keandalan sistem.

---

## 🧭 Decision Engine & Root Cause Analysis

### Diagnosis Multi-Error & Kegagalan Beruntun

**Pertanyaan:** Bagaimana cara sistem mendiagnosis akar masalah (*root cause*) saat terjadi situasi *multi-error* atau kegagalan beruntun (*cascading failure*)?

**Penjelasan:**
Dalam insiden produksi, satu kegagalan hulu sering kali memicu serangkaian error turunan secara berantai (misalnya: *Database Backend Down* ➔ *Connection Pool Habis* ➔ *Thread Pool Habis* ➔ *Health Endpoint Timeout* ➔ *Prometheus Scrape Gagal*).

Sistem **tidak mengambil kesimpulan hanya dari satu log** atau melakukan tebakan spekulatif. Sebaliknya, sistem menjalankan **alur evaluasi berbasis bukti bertingkat (*multi-source deterministic pipeline*)**:

```mermaid
flowchart TD
    ALERT["Alertmanager Webhook<br/>(TomcatDown firing)"] --> COLL["Multi-Source Collector<br/>(JMX, Health, cgroup, Logs)"]
    
    COLL --> CG{"Bukti Kontradiktif?"}
    CG -- "Ya" --> UNDET["TD-08 (Undetermined)<br/><i>Hindari Spekulasi</i>"]
    
    CG -- "Tidak" --> CR{"Cocok Custom Rule?<br/>(TD-09 s/d TD-18+)"}
    CR -- "Ya" --> CUST["Branch Kustom Terdaftar<br/>(confirmed / probable)"]
    
    CR -- "Tidak" --> BI{"Cocok Core Rule?<br/>(TD-02 s/d TD-06)"}
    BI -- "Ya" --> CORE["Branch Inti Terpilih<br/>(confirmed_cause)"]
    BI -- "Tidak" --> UNDET
```

Tahapan evaluasi keputusan:

1. **Pengumpulan Bukti Multi-Dimensi (*Multi-Source Collection*):** Engine secara paralel mengumpulkan telemetri dari 5 adapter independen (`jmx_scrape`, `application_health`, `container_state`, `runtime_oom`, dan `local_file`).
2. **Penyaringan Kontradiksi (*Contradiction Guard*):** Memeriksa konsistensi sensor untuk memastikan tidak ada anomali telemetri (misalnya kontainer dilaporkan *running* sekaligus *exited*).
3. **Pencocokan Pola Spesifik (*Enriched Rules Specificity*):** Aturan yang menargetkan tanda tangan error spesifik pada berkas log aplikasi (`local_file`) didahulukan daripada metrik hilir umum.
4. **Evaluasi Prioritas Inti (*Built-in Precedence Cascade*):** Jika tidak ada custom rule yang cocok, engine mengevaluasi kegagalan tingkat OS (OOM Kill), JVM (Fatal Crash), dan Container (Port Conflict, Orderly Shutdown) secara berurutan.

---

### Pembedaan Akar Masalah vs Gejala Turunan

**Pertanyaan:** Bagaimana sistem membedakan akar masalah (*root cause*) dari gejala turunan (*symptoms / contributing factors*)?

**Penjelasan:**
Sistem menggunakan **Taksonomi Klasifikasi Formal** pada model data [Diagnostic Result Contract](diagnostic-mvp/diagnostic-result-and-confidence-contract.md):

* **`confirmed_cause` (Keyakinan: `high`):** Bukti langsung dan tak terbantahkan bahwa peristiwa inilah yang mematikan atau melumpuhkan proses Tomcat (misal: *Linux cgroup OOM Killer*, *Fatal JVM Crash SIGSEGV*, *Java Thread Deadlock*).
* **`probable_cause` (Keyakinan: `medium` / `high`):** Bukti kuat menunjukkan peristiwa ini sebagai pemicu utama kegagalan hulu (misal: *Database Connection Pool Exhausted*, *SSL Handshake Failure*).
* **`possible_cause` (Keyakinan: `low` / `medium`):** Anomali terdeteksi (misal: *long pause GC* atau jeda waktu respon), namun belum cukup bukti definitif bahwa Tomcat mati.
* **`contributing_factor` / `symptom`:** Gejala turunan atau efek domino yang muncul akibat akar masalah utama. Seluruh gejala ini **tetap dicatat dalam larik bukti (*evidence array*)** sebagai konteks forensik pelengkap tanpa mengaburkan kesimpulan utama (*primary assessment*).
* **`undetermined` (Keyakinan: *None*):** Bukti tidak cukup atau pola belum dikenali. Sistem menolak berspekulasi demi menjaga keandalan diagnosis (*no false diagnosis*).

---

### Penanganan Bukti Telemetri yang Kontradiktif

**Pertanyaan:** Bagaimana jika bukti telemetri saling bertentangan (*contradicting telemetry*)?

**Penjelasan:**
Jika sistem mendeteksi kondisi yang secara fisik mustahil terjadi bersamaan (misalnya adapter `container_state` mendeteksi kontainer berstatus `running`, namun secara simultan terdeteksi `exited`; atau HTTP `/health` merespons `UP` tetapi koneksi TCP dinyatakan terputus):

* **Keputusan Aman (*Fail-Safe Decision*):** Sistem tidak memilih salah satu secara acak, melainkan menetapkan cabang **`TD-08 (Contradicting State / Undetermined)`** dengan klasifikasi `undetermined`.
* **Pencatatan Anomali:** Anomali dicatat secara eksplisit pada blok `contradictions` di dalam Canonical Result.
* **Tindakan Operator:** Notifikasi email meminta operator melakukan verifikasi manual langsung ke host target tanpa memberikan rekomendasi remediasi yang berpotensi keliru.

---

### Alasan Adopsi Engine Deterministik Tanpa Black-Box ML

**Pertanyaan:** Mengapa engine tidak menggunakan *machine learning black-box* atau skor probabilitas angka acak untuk menentukan akar masalah?

**Penjelasan:**
Platform mengadopsi prinsip **Deterministic & Explainable SRE Operations**:

1. **Auditabilitas & Akuntabilitas:** Tim SRE wajib mengetahui dengan pasti *mengapa* sistem mengambil keputusan tertentu berdasarkan bukti fisik yang dapat diverifikasi (file log, baris error, exit code).
2. **Keterulangan (*Reproducibility*):** Bukti yang sama dievaluasi dengan versi aturan yang sama dijamin 100% selalu menghasilkan kesimpulan yang identik (*deterministic idempotency*).
3. **Pencegahan Halusinasi (*Anti-Hallucination*):** Model *black-box* berisiko menghasilkan rekomendasi mitigasi yang salah (*false positive/negative*) saat menghadapi pola log yang ambigu di level produksi.

---

## 🤖 AI Knowledge Enrichment & Rule Governance

### Prinsip Human-in-the-Loop Governance

**Pertanyaan:** Mengapa sistem mengadopsi prinsip *Human-in-the-Loop Governance* alih-alih membiarkan AI mengubah kode runtime secara langsung?

**Penjelasan:**
Arsitektur tata kelola pengetahuan (*Knowledge Governance*) dirancang dengan memisahkan peran secara tegas:

```mermaid
flowchart TD
    AI["External AI Engine<br/>(Sintesis Log Forensik)"] -->|"Draft Rulepack JSON"| SRE["Operator SRE<br/>(Gatekeeper Mutu)"]
    SRE -->|"REST API / curl"| DS["Diagnostic Service<br/>(5-Layer Guard)"]
    DS -->|"Hot-Reload RAM"| RAM["Dynamic Rule Evaluator"]
    DS -->|"Persistensi"| SQL[("SQLite custom_rules")]
```

* **AI sebagai Akselerator Analisis:** Bertugas merumuskan pola log (*regex/substring*), kategori failure domain, dan langkah mitigasi SOP Bahasa Indonesia dari data forensik insiden.
* **Operator SRE sebagai Otoritas Tertinggi (*Gatekeeper*):** Memvalidasi keamanan pola regex (pencegahan ReDoS), memastikan ID branch tidak bertabrakan, dan mengevaluasi kelayakan langkah operasional sebelum diaktifkan ke runtime produksi.
* **Stabilitas Sistem:** AI tidak memiliki akses menulis langsung ke server, database, atau source code layanan.

---

### Akses Operasional SRE Mandiri via REST API

**Pertanyaan:** Bagaimana alur operasional rekan SRE yang ingin mengakses sistem dari laptop masing-masing?

**Penjelasan:**
Diagnostic Service mengekspos endpoint REST API standar melalui port TLS `8443` (`https://<DIAGNOSTIC_HOST>:8443/api/v1/rules`), sehingga operator dapat berinteraksi langsung menggunakan tool standar seperti `curl`:

1. **Ekspor Master Catalog:**
   ```bash
   curl -k -s -H "Authorization: Bearer test-token-12345" \
     https://<SERVER_IP>:8443/api/v1/rules > ~/master-rules.json
   ```
2. **Prompting AI & Formulasi Rule:**
   SRE memasukkan berkas `~/master-rules.json` dan bukti log insiden ke AI (ChatGPT / Claude / Gemini) menggunakan template prompt resmi pada [Runbook Operasional](operations/ai-knowledge-enrichment-and-rule-management-runbook.md).
3. **Ingest Aturan Baru (*Hot-Reload*):**
   ```bash
   curl -k -s -X POST https://<SERVER_IP>:8443/api/v1/rules \
     -H "Authorization: Bearer test-token-12345" \
     -H "Content-Type: application/json" \
     -d @~/proactive-rules.json
   ```

---

### Pertahanan Ingesti 5-Layer Defense-in-Depth

**Pertanyaan:** Bagaimana pertahanan *5-Layer Ingestion Defense-in-Depth* melindungi sistem?

**Penjelasan:**
Setiap payload aturan yang dikirim ke endpoint `POST /api/v1/rules` wajib melewati 5 lapis proteksi ketat sebelum diizinkan aktif:

| Lapis Pertahanan | Mekanisme Validasi | Tindakan Jika Melanggar |
| :--- | :--- | :---: |
| **Layer 1: Auth Guard** | Memeriksa validitas header `Authorization: Bearer <token>` terhadap kredensial resmi. | `401 Unauthorized` |
| **Layer 2: Schema Guard** | Validasi skema JSON via pustaka Ajv terhadap `rulepack-v1.schema.json` (memeriksa properti wajib, tipe data, enum klasifikasi, dan pola regex). | `400 Bad Request` |
| **Layer 3: Collision Guard** | Mencegah penimpaan cabang bawaan immutable (`TD-01` s/d `TD-08`) dan mendeteksi duplikasi cabang kustom yang sudah terdaftar. | `409 Conflict` |
| **Layer 4: Size Guard** | Membatasi ukuran payload maksimum 64 KB per aturan untuk mencegah serangan kejenuhan memori (*Memory Exhaustion / DoS*). | `413 Payload Too Large` |
| **Layer 5: Immutability Guard** | Menegakkan prinsip *append-only*. Endpoint menolak seluruh operasi modifikasi (`PUT`) atau penghapusan (`DELETE`). | `405 Method Not Allowed` |

---

### Penanganan Duplikasi pada Batch Ingestion

**Pertanyaan:** Bagaimana sistem menangani duplikasi saat proses *batch ingestion* dilakukan?

**Penjelasan:**
Pada mode *batch ingestion* (mengirimkan array JSON berisi banyak aturan sekaligus):

* Sistem memproses setiap aturan secara terisolasi (*atomic per-rule validation*).
* Aturan baru yang valid akan disimpan dan mengembalikan status `201 Created`.
* Aturan yang branch ID atau namanya sudah pernah terdaftar sebelumnya akan **dilewati secara otomatis (*graceful skip*)** dengan status `409 Conflict`, tanpa membatalkan atau menggagalkan proses aturan baru lainnya dalam batch tersebut.

---

## 🔐 Data Security, Limits & Reliability

### Pencegahan Kebocoran Data Sensitif (*Redaction*)

**Pertanyaan:** Bagaimana Diagnostic Service mencegah kebocoran data sensitif (*credential / secret redaction*)?

**Penjelasan:**
Diagnostic Service menerapkan prinsip **Bounded & Sanitized Data Collection**:

1. **Penyaringan Otomatis (*Redaction Masking*):** Pola teks yang menyerupai *password*, *token*, *API key*, *private key*, dan *session cookie* disamarkan secara otomatis sebelum disimpan ke database SQLite atau dikirim ke notifikasi email.
2. **Kapasitas Cuplikan Terbatas (*Bounded Excerpts*):** Pembacaan log dibatasi secara ketat (maksimal 64 KB per berkas / 100 baris terakhir). Engine dilarang membaca atau menyimpan keseluruhan dump log yang tidak terbatas (*unbounded dumps*).
3. **Instruksi Mitigasi Non-Eksekutif:** Seluruh `recommendedActions` hanya berupa teks panduan SOP untuk operator manusia dan tidak pernah dieksekusi secara otomatis oleh sistem, mencegah risiko eksekusi perintah berbahaya (*arbitrary code execution*).

---

### Pemrosesan Asinkron Webhook & Bounded Queue

**Pertanyaan:** Mengapa webhook Alertmanager diproses secara asinkron dengan antrean *Bounded Queue* dan SQLite?

**Penjelasan:**
Untuk menjamin keandalan dan mencegah *bottleneck* performa:

* **Respons Instan (*Fast Ingestion*):** Saat menerima webhook dari Alertmanager, HTTP Ingestion Handler segera memvalidasi payload dan mengembalikan HTTP `202 Accepted` dalam hitungan milidetik.
* **Perlindungan Tekanan Balik (*Backpressure Protection*):** Antrean memori dibatasi kapasitasnya (*bounded queue*). Jika antrean penuh, webhook tetap tercatat aman di tabel persisten SQLite `diagnostic_events`.
* **Pemrosesan Terisolasi (*Dedicated Worker*):** Proses pengumpulan bukti log dan evaluasi keputusan dijalankan oleh *Diagnostic Worker* di latar belakang secara asinkron tanpa membebani thread HTTP server.

---

### Perbedaan Firing Diagnosis dan Resolved Notification

**Pertanyaan:** Apa perbedaan antara *Firing Diagnosis* dan *Resolved Notification*?

**Penjelasan:**

* **Firing Diagnosis:** Diterbitkan saat insiden pertama kali terjadi atau saat terjadi perubahan material (*material update*). Memuat 7 seksi laporan forensik mendalam (ringkasan insiden, klasifikasi akar masalah, bukti telemetri lengkap, anomali, dan 4 langkah SOP mitigasi terstruktur).
* **Resolved Notification:** Diterbitkan saat Alertmanager mengirimkan webhook pemulihan layanan (`status: "resolved"`). Notifikasi ini mengonfirmasi bahwa target telah kembali sehat (*healthy*), merujuk pada riwayat diagnosis firing sebelumnya, dan memberikan instruksi penutupan tiket insiden bagi operator.

---

## 🔗 Related Documentation

| Dokumen | Deskripsi |
| :--- | :--- |
| [Architecture Overview](architecture/index.md) | Desain topologi, arsitektur container, dan alur komunikasi monitoring. |
| [Diagnostic Result and Confidence Contract](diagnostic-mvp/diagnostic-result-and-confidence-contract.md) | Spesifikasi formal model data canonical result dan taksonomi klasifikasi. |
| [Knowledge Base & AI Enrichment Architecture](diagnostic-mvp/knowledge-base-and-ai-enrichment-architecture.md) | Arsitektur 5-Layer basis pengetahuan diagnosis dan hot-reloading rules. |
| [AI Knowledge Enrichment Runbook](operations/ai-knowledge-enrichment-and-rule-management-runbook.md) | SOP operasional langkah demi langkah untuk formulasi prompt AI dan kurasi aturan. |
| [Engineering Journal Diagnostic MVP Pilot](engineering-journal/diagnostic-mvp-pilot/index.md) | Histori lengkap implementasi teknis dan bukti verifikasi 100% lulus. |

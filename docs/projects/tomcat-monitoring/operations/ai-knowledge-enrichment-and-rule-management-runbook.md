# Runbook: AI Knowledge Enrichment & Declarative Rule Management

Dokumen operasional ini merupakan panduan resmi bagi **Operator / Site Reliability Engineer (SRE)** untuk mengelola, memperkaya, dan mengimpor basis pengetahuan diagnosis (*Declarative Rulepacks*) ke dalam **Tomcat Diagnostic Service** menggunakan kolaborasi berbasis AI (*Human-in-the-Loop Governance*).

---

## 1. Filosofi & Arsitektur Human-in-the-Loop

Sistem Tomcat Diagnostic memisahkan peran antara kecerdasan generatif AI, kendali verifikasi manusia, dan keandalan engine deterministik:

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                               HUMAN-IN-THE-LOOP ARCHITECTURE                             │
└──────────────────────────────────────────────────────────────────────────────────────────┘

     [PC Operator SRE]                                          [DevOps Lab Runtime]
  ┌───────────────────────┐                                   ┌──────────────────────┐
  │  Master Rules Catalog │                                   │  Diagnostic Service  │
  │  (master-rules.json)  │                                   │   (Port 8443 TLS)    │
  └──────────┬────────────┘                                   └──────────▲───────────┘
             │                                                           │
             │ (1) Proactive Domain Gap /                                │ (4) Safe Ingest
             │     Forensic Log Evidence                                 │     POST /api/v1/rules
             ▼                                                           │     (Bearer Token)
  ┌───────────────────────┐                                   ┌──────────┴───────────┐
  │   AI Engine (LLM)     │ ──(2) JSON Rulepack──► ┌─────────┐│ 5-Layer Ingestion    │
  │ (Gemini/Claude/GPT)   │                        │ SRE QA  ││ Defense Guard        │
  └───────────────────────┘                        │ Review  ││ (Auth, Schema, Match)│
                                                   └────┬────┘└──────────────────────┘
                                                        │
                                                        └─► (3) Validated Knowledge
```

1. **AI sebagai Akselerator Analisis:** Bertugas merumuskan pola log (*regex/substring*) dan langkah mitigasi SOP berbasis data forensik atau skenario domain kegagalan.
2. **Operator SRE sebagai Otoritas Tertinggi (*Gatekeeper*):** Memverifikasi keabsahan logika diagnosis, memeriksa keunikan pola, dan mengeksekusi *ingestion* dengan kredensial resmi.
3. **5-Layer Ingestion Defense-in-Depth:** Memastikan setiap aturan yang masuk melalui API tervalidasi secara ketat terhadap autentikasi, skema JSON, pencegahan tabrakan *branch* bawaan (`TD-01` s/d `TD-08`), batas ukuran memori, dan sifat *append-only*.
4. **Zero-Downtime Hot-Reload:** Aturan yang berhasil di-ingest langsung aktif seketika di memori engine (*RAM*) dan tersimpan permanen di database SQLite `custom_rules` tanpa perlu me-restart layanan.

---

## 2. Dua Mode Pengayaan Pengetahuan (*Enrichment Modes*)

Operator dapat memperkaya basis pengetahuan diagnosis melalui dua pendekatan komplementer:

### Mode A: Pengayaan Proaktif (*Pre-emptive Domain Engineering*)
**Tujuan:** Melengkapi pustaka aturan diagnosis sebelum insiden terjadi di lingkungan produksi, sehingga ketika masalah pertama kali muncul, sistem langsung memberikan diagnosis deterministik (`confirmed_cause`) dan SOP yang tepat tanpa pernah jatuh ke status `UNDETERMINED`.

**7 Taksonomi Domain Kegagalan Produksi Tomcat:**
1. **JVM & Memory Management:** Heap exhaustion, Metaspace exhaustion, GC overhead limit, DirectBuffer OOM, Native memory leak.
2. **Concurrency & Threading:** Thread pool saturation, Java thread deadlock, Thread starvation, Task rejection.
3. **Database & Connection Pooling:** DBCP/HikariCP pool timeout, connection leak, backend max connection reached, SQL lock timeout.
4. **Network, Socket & Upstream:** Socket read timeout, connect timeout, DNS lookup failure (`UnknownHostException`), Connection reset by peer, Broken pipe, TLS/SSL handshake failure.
5. **Application Framework & Lifecycle:** Spring context initialization failure, `BeanCreationException`, Circular dependency, Missing environment variables, Servlet filter startup error.
6. **File System, Storage & OS Limits:** File descriptor exhaustion (`Too many open files`), Disk space full (`No space left on device`), Permission denied.
7. **Security, Session & Auth:** LDAP server timeout, Session replication failure, Token signature validation error.

### Mode B: Pengayaan Reaktif (*Incident-Driven Post-Mortem*)
**Tujuan:** Merumuskan aturan baru secara cepat ketika sistem mendeteksi insiden baru yang tidak memiliki kecocokan pola pada aturan yang ada (status `UNDETERMINED` / `Branch TD-08`).

---

## 3. Standard Operating Procedures (SOP) Operasional

### Langkah 1: Cadangkan / Ekspor Katalog Master dari Sistem

Sebelum melakukan perubahan, ambil salinan katalog master aturan aktif dan simpan di PC lokal Anda:

```bash
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh > ~/master-rules.json
```

---

### Langkah 2: Berikan Prompt ke AI untuk Merumuskan Aturan

Salin prompt di bawah ini ke AI pilihan Anda (Gemini, Claude, atau ChatGPT).

#### A. Template Prompt Proaktif (Per Domain)
````markdown
Kamu adalah Principal JVM & Tomcat SRE Architect.
Saya sedang melakukan PROACTIVE KNOWLEDGE ENRICHMENT untuk Diagnostic Service Tomcat.

Berikut adalah Katalog Master Rule yang ada saat ini:
<PASTE ISI master-rules.json ATAU DAFTAR BRANCH TD-01 s/d TD-18>

--- TUGAS PROAKTIF ---
Rancang Declarative Rulepack baru untuk domain: [PILIH DOMAIN: Misal Database / Spring Framework / OS Limits].
Rumuskan 3-5 failure patterns yang paling sering terjadi di level production.

--- KONTRAK SCHEMA (WAJIB DIPATUHI) ---
1. "branch": ID branch baru lanjutan (misal: "TD-19", "TD-20", dst).
2. "ruleName": Nama unik PascalCase/camelCase.
3. "targetSource": "local_file"
4. "pattern": String substring unik atau regex aman (bebas nested quantifier).
5. "assessment": Ringkasan akar masalah dalam 1 kalimat padat Bahasa Inggris/Indonesia.
6. "classification": "confirmed_cause" atau "probable_cause".
7. "confidence": "high" (untuk confirmed_cause) atau "medium" (untuk probable_cause).
8. "recommendedActions": Array 4 langkah mitigasi SOP Bahasa Indonesia terstruktur.
9. "createdBy": "sre-proactive-enrichment"

Keluarkan HANYA blok Array JSON valid: [ {...}, {...} ] tanpa teks pengantar di luar blok.
````

#### B. Template Prompt Reaktif (Berdasarkan Log Insiden Riil)
````markdown
Kamu adalah Enterprise SRE Expert untuk platform Tomcat Diagnostic.
Terdapat insiden kegagalan baru yang berstatus UNDETERMINED.

--- BUKTI LOG ERROR INSIDEN ---
<PASTE CUPLIKAN ERROR / STACK TRACE DI SINI>

--- TUGAS REAKTIF ---
1. Analisis bukti log error di atas.
2. Buatkan 1 Declarative Rulepack JSON valid dengan nomor branch lanjutan (misal: "TD-19").
3. Pastikan pola "pattern" unik dan spesifik untuk error tersebut.
4. Sertakan 4 langkah mitigasi SOP Bahasa Indonesia terstruktur.
5. Keluarkan HANYA blok JSON tunggal {...} sesuai kontrak skema.
````

---

### Langkah 3: Review & Quality Assurance (SRE Gatekeeping)

Sebelum melakukan impor, pastikan:
* [x] Nomor `branch` tidak menggunakan `TD-01` s/d `TD-08` (area terproteksi *built-in*).
* [x] Pola `pattern` spesifik dan tidak menimbulkan *false positive*.
* [x] `classification` dan `confidence` konsisten (`confirmed_cause` berpasangan dengan `high`).
* [x] Rekomendasi tindakan pada `recommendedActions` jelas, aman, dan dapat ditindaklanjuti oleh tim operasional.

---

### Langkah 4: Ingest Hasil AI ke Diagnostic Service

Gunakan script CLI [`scripts/ingest-rule.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh):

#### Opsi 1: Ingest Berkas Batch Array (Proaktif)
```bash
BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh ~/proactive-rules.json
```

#### Opsi 2: Ingest Berkas Tunggal (Reaktif)
```bash
BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh ~/rule-td19.json
```

#### Opsi 3: Ingest Langsung via Pipe Stdin
```bash
cat ~/new-rule.json | BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh -
```

---

### Langkah 5: Verifikasi Hasil Ingestion & Pembaruan Master Catalog

1. **Periksa status aturan aktif di sistem:**
   ```bash
   /home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh TD-19
   ```
2. **Sinkronkan kembali Master Catalog lokal di PC Anda:**
   ```bash
   /home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh > ~/master-rules.json
   ```

---

## 4. Matriks Master Knowledge Base Terkurasi Saat Ini

Berikut adalah 18 cabang aturan diagnosis aktif yang telah terverifikasi dan siap di lingkungan *DevOps Lab*:

| Branch | Nama Rule (*Rule Identifier*) | Pola Bukti Error (*Pattern*) | Klasifikasi & Confidence | SOP Rekomendasi Mitigasi Operator |
| :---: | :--- | :--- | :---: | :--- |
| **`TD-01`** | `ScrapeTlsUnavailable` *(Built-in)* | Port 9404 unreachable / TLS fail | `confirmed_cause` (high) | Periksa port binding, TLS cert, dan konektivitas scraper Prometheus. |
| **`TD-02`** | `OOMKilled` *(Built-in)* | Exit 137 / cgroup OOM event | `confirmed_cause` (high) | Periksa limit memori container host, alokasi JVM, dan cgroup bounds. |
| **`TD-03`** | `JvmCrash` *(Built-in)* | `hs_err_pid*.log` / SIGSEGV / exit 134 | `confirmed_cause` (high) | Analisis fatal crash dump JVM dan kompatibilitas native library APR. |
| **`TD-04`** | `PortBindConflict` *(Built-in)* | `BindException: Address already in use` | `confirmed_cause` (high) | Periksa port collision pada host port 8080/9404 dan proses zombie. |
| **`TD-05`** | `OrderlyShutdown` *(Built-in)* | Exit 143 / SIGTERM orderly stop | `confirmed_cause` (high) | Verifikasi proses deployment atau shutdown yang disengaja. |
| **`TD-06`** | `ContainerExitedUnknown` *(Built-in)* | Container exited tanpa bukti spesifik | `undetermined` (none) | Periksa status cgroup, runtime container, dan log host. |
| **`TD-07`** | `ContradictingState` *(Built-in)* | Telemetri bertentangan | `undetermined` (none) | Lakukan verifikasi manual langsung ke endpoint runtime target. |
| **`TD-08`** | `UndeterminedEvidence` *(Built-in)* | Bukti tidak cukup / pola asing | `undetermined` (none) | Ekspor bukti forensik ke AI untuk perumusan rulepack baru. |
| **`TD-09`** | `DatabasePoolExhausted` *(Enriched)* | `CannotGetJdbcConnectionException` | `confirmed_cause` (high) | Periksa utilisasi database backend, `maxTotal`, dan connection leak. |
| **`TD-10`** | `ThreadPoolExhausted` *(Enriched)* | `RejectedExecutionException: Thread pool is exhausted` | `confirmed_cause` (high) | Ambil thread dump JVM, sesuaikan `maxThreads`, dan evaluasi traffic spike. |
| **`TD-11`** | `JavaHeapSpaceOOM` *(Enriched)* | `OutOfMemoryError: Java heap space` | `confirmed_cause` (high) | Analisis heap dump (.hprof) via Eclipse MAT, tingkatkan alokasi `-Xmx`. |
| **`TD-12`** | `MetaspaceOOM` *(Enriched)* | `OutOfMemoryError: Metaspace` | `confirmed_cause` (high) | Periksa ClassLoader leak, batasi bytecode generator, naikkan `-XX:MaxMetaspaceSize`. |
| **`TD-13`** | `SSLHandshakeFailure` *(Enriched)* | `javax.net.ssl.SSLHandshakeException` | `confirmed_cause` (high) | Periksa validitas sertifikat backend, perbarui truststore `/conf/truststore.p12`. |
| **`TD-14`** | `HikariPoolTimeout` *(Enriched)* | `Connection is not available, request timed out` | `confirmed_cause` (high) | Aktifkan `leakDetectionThreshold`, tingkatkan `maximumPoolSize`, periksa lock DB. |
| **`TD-15`** | `ContextInitFailure` *(Enriched)* | `LifecycleException: Failed to start component` | `confirmed_cause` (high) | Periksa `web.xml`, Spring context, kelengkapan file `WEB-INF/lib`, dan permission. |
| **`TD-16`** | `JavaThreadDeadlock` *(Enriched)* | `Found one Java-level deadlock` | `confirmed_cause` (high) | Ambil thread dump (`jstack`), analisis siklus lock graph, perbaiki urutan sinkronisasi. |
| **`TD-17`** | `SocketReadTimeout` *(Enriched)* | `SocketTimeoutException: Read timed out` | `confirmed_cause` (high) | Periksa latency upstream API, sesuaikan `connectTimeout`/`readTimeout`, terapkan Circuit Breaker. |
| **`TD-18`** | `SQLQueryTimeout` *(Enriched)* | `java.sql.SQLTimeoutException` | `confirmed_cause` (high) | Analisis slow query log, periksa missing index via `EXPLAIN ANALYZE`, periksa table lock. |

---

## 5. Panduan Respon & Kode Error 5-Layer Guard

| HTTP Status | Kode Error (*Error Code*) | Penyebab Kemungkinan | Tindakan Perbaikan Operator |
| :---: | :--- | :--- | :--- |
| **`201`** | `Created` | Payload valid, aturan berhasil di-ingest. | Tidak ada. Aturan langsung aktif secara *hot-reload*. |
| **`401`** | `unauthorized` | Header `Authorization: Bearer <token>` salah atau tidak dikirim. | Pastikan `BEARER_TOKEN` yang digunakan cocok dengan konfigurasi secret. |
| **`400`** | `invalid_rule_schema` | Struktur JSON tidak lengkap, tipe data salah, atau enum klasifikasi tidak valid. | Periksa apakah seluruh *required fields* (`branch`, `ruleName`, `targetSource`, `pattern`, `assessment`, `classification`, `confidence`, `recommendedActions`, `createdBy`) ada dan bertipe benar. |
| **`400`** | `unsafe_regex_pattern` | Pola `pattern` mengandung konstruksi regex berbahaya (misal: *nested quantifier* seperti `(a+)+` yang rawan *ReDoS*). | Sederhanakan pola regex atau gunakan pencocokan substring biasa. |
| **`409`** | `rule_branch_conflict` | ID `branch` bertabrakan dengan branch *built-in* (`TD-01` s/d `TD-08`) atau branch kustom yang sudah ada di database. | Gunakan nomor branch baru yang belum pernah digunakan (misal: `TD-19`). |
| **`413`** | `payload_too_large` | Ukuran payload JSON melebihi batas keamanan 64 KB. | Ringkas rekomendasi teks atau batasi panjang pola regex. |
| **`405`** | `Method Not Allowed` | Endpoint diakses menggunakan method `PUT`, `DELETE`, atau `PATCH`. | Aturan bersifat *append-only* (*immutable*). Gunakan method `POST` untuk menambah aturan baru. |

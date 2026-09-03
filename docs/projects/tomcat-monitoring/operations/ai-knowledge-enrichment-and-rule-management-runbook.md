# SOP & Runbook: Pengayaan Pengetahuan AI & Manajemen Aturan Deklaratif (Declarative Rulepacks)

Dokumen ini merupakan panduan operasional standar (*Standard Operating Procedure / Runbook*) bagi Operator SRE dalam memperkaya (*knowledge enrichment*), mengevaluasi (*gatekeeping review*), mengimpor (*hot-reload ingestion*), dan mengelola basis aturan diagnosis deklaratif (*Declarative Rulepacks*) pada platform **Tomcat Diagnostic Service**.

---

## 🏛️ Arsitektur Alur Tata Kelola Pengetahuan (*Knowledge Governance*)

Sistem mengadopsi prinsip **Human-in-the-Loop Governance** di mana kecerdasan buatan (*AI*) bertindak sebagai akselerator sintesis log error, sedangkan Operator SRE memegang kendali penuh sebagai penjamin mutu (*gatekeeper*) sebelum aturan baru diaktifkan ke dalam *production runtime*.

```mermaid
flowchart TD
    subgraph SRE_Env["Lingkungan Operator SRE (PC Lokal)"]
        MC["<b>Master Rules Catalog</b><br/>(master-rules.json)"]
        PROMPT["<b>AI Prompt Formulation</b><br/>(Domain / Log Evidence)"]
        QA["<b>SRE QA Review</b><br/>(Pattern & SOP Check)"]
    end

    subgraph AI_Env["External AI Engine"]
        LLM["<b>LLM Analyzer</b><br/>(Gemini / Claude / GPT)"]
    end

    subgraph Runtime_Env["DevOps Lab Container Network"]
        API["<b>Diagnostic Service API</b><br/>POST /api/v1/rules<br/>(Port 8443 TLS)"]
        GUARD["<b>5-Layer Ingestion Guard</b><br/>Auth • Schema • Collision<br/>Immutability • Payload Size"]
        ENGINE["<b>Dynamic Rule Evaluator</b><br/>(In-Memory RAM Engine)"]
        DB[("<b>SQLite Database</b><br/>(custom_rules table)")]
    end

    MC --> PROMPT
    PROMPT -->|"Kirim Konteks"| LLM
    LLM -->|"JSON Rulepack"| QA
    QA -->|"Ingest via CLI"| API
    API --> GUARD
    GUARD -->|"Hot-Reload"| ENGINE
    GUARD -->|"Persistensi"| DB
    DB -.->|"Ekspor & Verifikasi"| MC
```

### 📋 Empat Pilar Tata Kelola Operasional

1. **AI sebagai Akselerator Analisis:** Bertugas merumuskan pola log (*regex/substring*), kategori failure domain, dan langkah mitigasi SOP berbasis data forensik insiden atau taksonomi domain kegagalan.
2. **Operator SRE sebagai Otoritas Tertinggi (*Gatekeeper*):** Memverifikasi keabsahan logika diagnosis, memeriksa keunikan pola, dan mengeksekusi *ingestion* dengan kredensial resmi.
3. **5-Layer Ingestion Defense-in-Depth:** Memastikan setiap aturan yang masuk melalui API tervalidasi secara ketat terhadap autentikasi token, kepatuhan skema JSON, pencegahan tabrakan *branch* bawaan (`TD-01` s/d `TD-08`), batas ukuran memori (maks. 64 KB), dan sifat *append-only*.
4. **Zero-Downtime Hot-Reload & Domain Categorization:** Aturan yang berhasil di-ingest langsung aktif seketika di memori engine (*RAM*), diklasifikasikan ke dalam kategori failure domain resmi, dan tersimpan permanen di database SQLite `custom_rules` tanpa perlu me-restart container layanan.

---

## 🔄 Dua Mode Pengayaan Pengetahuan (*Enrichment Modes*)

Operator dapat memperkaya basis pengetahuan diagnosis melalui dua pendekatan komplementer:

```mermaid
flowchart LR
    subgraph Mode_A["Mode A: Pengayaan Proaktif"]
        direction TB
        DOM["<b>7 Failure Domains</b><br/>Memory • Database • Concurrency<br/>Network • App • OS • Security"] --> PROMPT_A["<b>Formulasi Batch Prompt AI</b><br/>Sintesis 3-5 Pola per Domain"]
        PROMPT_A --> INGEST_A["<b>Batch Ingest JSON Array</b><br/>(scripts/ingest-rule.sh)"]
    end

    subgraph Mode_B["Mode B: Pengayaan Reaktif"]
        direction TB
        INC["<b>Insiden TomcatDown Baru</b><br/>Status: Undetermined (TD-08)"] --> EXTRACT["<b>Ekstrak Bukti Log Forensik</b><br/>catalina.out / thread dump"]
        EXTRACT --> PROMPT_B["<b>Formulasi Prompt Reaktif AI</b><br/>Analisis Root Cause Spesifik"]
        PROMPT_B --> INGEST_B["<b>Single Ingest JSON Object</b><br/>(scripts/ingest-rule.sh)"]
    end
```

### 1. Mode A: Pengayaan Proaktif (*Pre-emptive Domain Engineering*)

Pengayaan proaktif bertujuan melengkapi pustaka aturan diagnosis **sebelum insiden nyata terjadi** di lingkungan produksi. Ketika insiden pertama kali muncul, sistem langsung memberikan diagnosis deterministik (`confirmed_cause`) dan SOP mitigasi seketika tanpa jatuh ke status `UNDETERMINED`.

```mermaid
mindmap
  root((Domain Kegagalan<br/>Tomcat & JVM))
    Concurrency & Threading
      Thread Starvation
      Java Thread Deadlock
      Thread Pool Saturation
    Database & Persistence
      Backend Lock Contention
      SQL Query Timeout
      HikariCP Pool Timeout
      DBCP Connection Leak
    JVM & Memory
      GC Overhead Limit
      Metaspace Exhaustion
      DirectBuffer OOM
      Java Heap Space OOM
    Network & Integration
      Connection Reset by Peer
      DNS Lookup Failure
      SSL Handshake Failure
      Socket Read Timeout
    Application Lifecycle
      BeanCreationException
      Circular Dependency
      Missing Required Properties
      Spring Context Failure
    Storage & OS Limits
      Disk Space Exhaustion
      Permission Denied
      File Descriptor Limit
```

### 2. Mode B: Pengayaan Reaktif (*Incident-Driven Post-Mortem*)

Pengayaan reaktif dilakukan saat Diagnostic Service menerima insiden baru yang belum terpetakan dalam basis aturan (*unmapped failure pattern*), sehingga diklasifikasikan sebagai `UNDETERMINED` (`Branch TD-08`):

```mermaid
sequenceDiagram
    autonumber
    actor SRE as Operator SRE
    participant DS as Diagnostic Service
    participant AI as External AI Engine

    Note over SRE,DS: Terjadi insiden dengan pola error baru
    SRE->>DS: Ekspor Ringkasan Bukti Forensik Insiden
    DS-->>SRE: Cuplikan Log Error (catalina.out / hs_err_pid)
    SRE->>AI: Kirim Log Error + Prompt Sintesis Rulepack
    AI-->>SRE: Declarative Rulepack JSON (misal: TD-19)
    SRE->>SRE: SRE QA Review (Checklist Validasi)
    SRE->>DS: POST /api/v1/rules (Ingest dengan Bearer Token)
    DS-->>SRE: 201 Created (Rulepack Aktif Seketika)
    Note over DS: Insiden serupa berikutnya terpetakan secara otomatis
```

---

## 🧭 Implementation & Operating Plan

| Tahap | Rencana Operasional |
| --- | --- |
| **Export Master Catalog** | Mengambil salinan berkas katalog master aktif dari Diagnostic Service ke PC lokal operator. |
| **Formulate AI Prompting Context** | Menyusun konteks prompt terstruktur (proaktif per domain atau reaktif per insiden) ke AI Engine. |
| **Conduct SRE QA Review** | Melakukan evaluasi kepatuhan (*gatekeeping review*) terhadap JSON Rulepack yang dihasilkan AI. |
| **Ingest Rulepack via API** | Mengimpor berkas JSON (single rule / batch array) ke Diagnostic Service dengan Bearer Token. |
| **Verify Hot-Reload & Sync** | Memverifikasi ketersediaan aturan di runtime dan menyinkronkan kembali katalog master lokal di PC. |

---

## ⚙️ Prosedur Standar Operasional (Implementation Stages)

<div class="procedure-sequence" markdown>

<div class="procedure-step" markdown>

### Export & Backup Master Catalog

**Action:** Mengambil salinan seluruh aturan diagnosis aktif atau memeriksa daftar kategori dari Diagnostic Service dan menyimpannya ke direktori kerja PC lokal operator.

```bash
# 1. Menampilkan daftar ringkasan seluruh kategori aktif beserta jumlah aturan
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh --categories

# 2. Ekspor seluruh katalog aturan aktif ke berkas lokal
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh > ~/master-rules.json

# 3. Atau ekspor per kategori failure domain spesifik
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh --category database_persistence
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh --category jvm_memory
```

!!! success "Expected Result"

    Operator dapat melihat daftar ringkasan kategori aktif di terminal, dan berkas `master-rules.json` tersimpan di PC lokal operator dalam format JSON terstruktur yang memuat seluruh deklarasi aturan aktif (`TD-09` s/d `TD-18`) beserta kategori domainnya.

</div>

<div class="procedure-step" markdown>

### Formulate AI Prompting Context

**Action:** Menyusun prompt terstandarisasi yang memuat ringkasan branch yang ada, target domain kegagalan atau data log insiden riil, serta batasan kontrak skema JSON yang wajib dipatuhi AI Engine.

#### A. Template Prompt Proaktif (Per Domain)
````markdown
Kamu adalah Principal JVM & Tomcat SRE Architect.
Saya sedang melakukan PROACTIVE KNOWLEDGE ENRICHMENT untuk Tomcat Diagnostic Service.

Berikut adalah ringkasan branch aturan yang telah aktif di sistem:
- TD-01 s/d TD-08: Built-in Scrape, OOM Kill, JVM Crash, Port Bind, Orderly Stop, Undetermined.
- TD-09 s/d TD-18: Database Pool Exhausted, Thread Pool Exhausted, Heap OOM, Metaspace OOM, SSL Handshake, HikariCP Timeout, Context Init Failure, Thread Deadlock, Socket Read Timeout, SQL Timeout.

--- TUGAS PROAKTIF ---
Rancang kumpulan Declarative Rulepack baru untuk domain: [PILIH DOMAIN: Misal OS Limits / Spring Framework / Network].
Rumuskan 3-5 failure patterns yang paling sering terjadi di level production.

--- KONTRAK SCHEMA (WAJIB DIPATUHI) ---
1. "branch": ID branch baru kelanjutan (misal: "TD-19", "TD-20", dst).
2. "ruleName": Nama unik PascalCase/camelCase deskriptif.
3. "category": Wajib salah satu dari: "jvm_memory", "concurrency_threading", "database_persistence", "network_integration", "application_lifecycle", "storage_os_limits", "security_session", "general".
4. "targetSource": "local_file"
5. "pattern": Substring unik atau regex aman (tidak boleh mengandung nested quantifier).
6. "assessment": Ringkasan akar masalah dalam 1 kalimat padat.
7. "classification": Wajib "confirmed_cause" atau "probable_cause".
8. "confidence": "high" (jika confirmed_cause) atau "medium" (jika probable_cause).
9. "recommendedActions": Array 4 langkah mitigasi SOP Bahasa Indonesia terstruktur.
10. "createdBy": "sre-proactive-enrichment"

Keluarkan HANYA satu blok Array JSON valid: [ {...}, {...} ] tanpa teks pengantar di luar blok.
````

#### B. Template Prompt Reaktif (Berdasarkan Insiden Riil)
````markdown
Kamu adalah Enterprise SRE Expert untuk platform Tomcat Diagnostic.
Terdapat insiden kegagalan baru yang saat ini berstatus UNDETERMINED.

--- BUKTI LOG ERROR INSIDEN ---
<TEMPELKAN CUPLIKAN LOG ERROR ATAU STACK TRACE DI SINI>

--- TUGAS REAKTIF ---
1. Analisis bukti log error di atas dan tentukan akar masalah utamanya.
2. Buatkan 1 Declarative Rulepack JSON valid dengan nomor branch lanjutan (misal: "TD-19").
3. Pilih "category" domain yang tepat ("jvm_memory", "database_persistence", "network_integration", dll).
4. Pastikan pola "pattern" unik dan spesifik untuk mencocokkan error tersebut.
5. Sertakan 4 langkah mitigasi SOP Bahasa Indonesia terstruktur.
6. Keluarkan HANYA satu blok JSON tunggal {...} sesuai kontrak skema.
````

!!! success "Expected Result"

    AI Engine menghasilkan output berupa blok JSON mentah (*single object* atau *batch array*) yang mematuhi skema formal termasuk properti `category` tanpa teks naratif di luar blok JSON.

</div>

<div class="procedure-step" markdown>

### Conduct SRE QA & Gatekeeping Review

**Action:** Melakukan tinjauan kualitas dan keamanan (*quality assurance & gatekeeping*) terhadap output JSON yang dihasilkan AI sebelum dieksekusi ke runtime Diagnostic Service.

**Daftar Periksa Kepatuhan (*Verification Checklist*):**
* [x] **Branch Safety:** Nilai `branch` tidak menggunakan rentang terproteksi `TD-01` s/d `TD-08`.
* [x] **Category Validity:** Nilai `category` sesuai salah satu enum domain resmi sistem.
* [x] **Pattern Precision:** Pola `pattern` spesifik dan tidak menimbulkan potensi salah deteksi (*false positive*).
* [x] **ReDoS Prevention:** Pola regex bebas dari konstruksi rawan ledakan komputasi (*nested quantifier* seperti `(a+)+` atau `([a-z]+)*`).
* [x] **Classification & Confidence Mapping:** Nilai klasifikasi selaras dengan tingkat keyakinan (`confirmed_cause` wajib berpasangan dengan `high`).
* [x] **Operational Actionability:** Rekomendasi mitigasi pada `recommendedActions` jelas, aman, terurut secara logis, dan dapat dieksekusi operator.

!!! success "Expected Result"

    Seluruh butir daftar periksa terpenuhi (*100% compliant*) dan berkas JSON siap untuk proses *ingestion*.

</div>

<div class="procedure-step" markdown>

### Ingest Rulepack via Diagnostic API

**Action:** Mengirimkan payload JSON yang telah divalidasi ke endpoint `POST /api/v1/rules` pada Diagnostic Service menggunakan helper CLI [`scripts/ingest-rule.sh`](file:///home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh) dengan kredensial Bearer Token resmi operator.

#### Ingest Berkas Batch Array (Mode Proaktif)
```bash
BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh ~/proactive-rules.json
```

#### Ingest Berkas Tunggal (Mode Reaktif)
```bash
BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh ~/rule-td19.json
```

#### Ingest Langsung via Stdin Pipe
```bash
cat ~/new-rule.json | BEARER_TOKEN="test-token-12345" /home/eddywiyatno/git/tomcat-monitoring/scripts/ingest-rule.sh -
```

!!! success "Expected Result"

    Endpoint mengembalikan HTTP status `201 Created`. Aturan baru langsung ter-rehidrasi di memori `DynamicRuleEvaluator` secara *hot-reload* dan tercatat permanen di tabel SQLite `custom_rules`. Pada mode batch, aturan yang sudah terdaftar akan dilewati (`409 Conflict`) tanpa memutus alur aturan lainnya.

</div>

<div class="procedure-step" markdown>

### Verify Hot-Reload & Synchronize Master Catalog

**Action:** Memverifikasi ketersediaan aturan baru di lingkungan runtime dan memperbarui berkas master catalog di PC lokal operator.

```bash
# 1. Verifikasi aturan spesifik yang baru di-ingest
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh TD-19

# 2. Verifikasi aturan terdaftar pada kategori domain terkait
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh --category database_persistence

# 3. Periksa daftar ringkasan kategori aktif terbaru
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh --categories

# 4. Sinkronkan seluruh katalog master ke PC lokal operator
/home/eddywiyatno/git/tomcat-monitoring/scripts/export-rules.sh > ~/master-rules.json
```

!!! success "Expected Result"

    Diagnostic Service menyajikan metadata aturan `TD-19` secara presisi termasuk kategori domainnya, daftar ringkasan kategori terbarui, dan berkas `~/master-rules.json` di PC lokal operator berada dalam status mutakhir (*up-to-date*).

</div>

</div>

---

## 📊 Matriks Master Knowledge Base Terkurasi (18 Branches)

Tabel berikut merangkum 18 cabang aturan diagnosis aktif yang saat ini telah terverifikasi di lingkungan *DevOps Lab*:

| Branch | Kategori Domain | Nama Rule (*Rule Identifier*) | Pola Bukti Error (*Pattern*) | Klasifikasi & Keyakinan | SOP Rekomendasi Mitigasi Operator |
| :---: | :---: | :--- | :--- | :---: | :--- |
| **`TD-01`** | `network_integration` | `ScrapeTlsUnavailable` *(Built-in)* | Port 9404 unreachable / TLS fail | `confirmed_cause`<br/>*(high)* | Periksa port binding, sertifikat TLS, dan konektivitas scraper Prometheus. |
| **`TD-02`** | `jvm_memory` | `OOMKilled` *(Built-in)* | Exit 137 / cgroup OOM event | `confirmed_cause`<br/>*(high)* | Periksa limit memori container host, alokasi JVM, dan cgroup bounds. |
| **`TD-03`** | `jvm_memory` | `JvmCrash` *(Built-in)* | `hs_err_pid*.log` / SIGSEGV / exit 134 | `confirmed_cause`<br/>*(high)* | Analisis fatal crash dump JVM dan kompatibilitas native library APR. |
| **`TD-04`** | `network_integration` | `PortBindConflict` *(Built-in)* | `BindException: Address already in use` | `confirmed_cause`<br/>*(high)* | Periksa port collision pada host port 8080/9404 dan proses zombie. |
| **`TD-05`** | `application_lifecycle` | `OrderlyShutdown` *(Built-in)* | Exit 143 / SIGTERM orderly stop | `confirmed_cause`<br/>*(high)* | Verifikasi proses deployment atau shutdown terjadwal yang disengaja. |
| **`TD-06`** | `storage_os_limits` | `ContainerExitedUnknown` *(Built-in)* | Container exited tanpa bukti spesifik | `undetermined`<br/>*(none)* | Periksa status cgroup, runtime container engine, dan log host. |
| **`TD-07`** | `general` | `ContradictingState` *(Built-in)* | Telemetri saling bertentangan | `undetermined`<br/>*(none)* | Lakukan verifikasi manual langsung ke target endpoint runtime aplikasi. |
| **`TD-08`** | `general` | `UndeterminedEvidence` *(Built-in)* | Bukti tidak cukup / pola asing | `undetermined`<br/>*(none)* | Ekspor data forensik insiden ke AI untuk perumusan rulepack baru. |
| **`TD-09`** | `database_persistence` | `DatabasePoolExhausted` *(Enriched)* | `CannotGetJdbcConnectionException` | `confirmed_cause`<br/>*(high)* | Periksa utilisasi database backend, kapasitas `maxTotal`, dan connection leak. |
| **`TD-10`** | `concurrency_threading` | `ThreadPoolExhausted` *(Enriched)* | `RejectedExecutionException: Thread pool is exhausted` | `confirmed_cause`<br/>*(high)* | Ambil thread dump JVM, sesuaikan parameter `maxThreads`, dan evaluasi traffic spike. |
| **`TD-11`** | `jvm_memory` | `JavaHeapSpaceOOM` *(Enriched)* | `OutOfMemoryError: Java heap space` | `confirmed_cause`<br/>*(high)* | Analisis heap dump (.hprof) via Eclipse MAT, naikkan alokasi `-Xmx`. |
| **`TD-12`** | `jvm_memory` | `MetaspaceOOM` *(Enriched)* | `OutOfMemoryError: Metaspace` | `confirmed_cause`<br/>*(high)* | Periksa ClassLoader leak, batasi dynamic bytecode generator, naikkan `-XX:MaxMetaspaceSize`. |
| **`TD-13`** | `network_integration` | `SSLHandshakeFailure` *(Enriched)* | `javax.net.ssl.SSLHandshakeException` | `confirmed_cause`<br/>*(high)* | Periksa validitas sertifikat backend, perbarui truststore `/conf/truststore.p12`. |
| **`TD-14`** | `database_persistence` | `HikariPoolTimeout` *(Enriched)* | `Connection is not available, request timed out` | `confirmed_cause`<br/>*(high)* | Aktifkan `leakDetectionThreshold`, tingkatkan `maximumPoolSize`, periksa database lock. |
| **`TD-15`** | `application_lifecycle` | `ContextInitFailure` *(Enriched)* | `LifecycleException: Failed to start component` | `confirmed_cause`<br/>*(high)* | Periksa berkas `web.xml`, Spring context, kelengkapan `WEB-INF/lib`, dan file permission. |
| **`TD-16`** | `concurrency_threading` | `JavaThreadDeadlock` *(Enriched)* | `Found one Java-level deadlock` | `confirmed_cause`<br/>*(high)* | Ambil thread dump (`jstack`), analisis siklus lock graph, perbaiki urutan sinkronisasi kode. |
| **`TD-17`** | `network_integration` | `SocketReadTimeout` *(Enriched)* | `SocketTimeoutException: Read timed out` | `confirmed_cause`<br/>*(high)* | Periksa latency upstream API, sesuaikan `connectTimeout`/`readTimeout`, pasang Circuit Breaker. |
| **`TD-18`** | `database_persistence` | `SQLQueryTimeout` *(Enriched)* | `java.sql.SQLTimeoutException` | `confirmed_cause`<br/>*(high)* | Analisis slow query log, periksa missing index via `EXPLAIN ANALYZE`, periksa row lock. |

---

## 🛡️ Panduan Respon & Penanganan Error 5-Layer Guard

| HTTP Status | Kode Error (*Error Code*) | Akar Masalah | Tindakan Perbaikan Operator |
| :---: | :--- | :--- | :--- |
| **`201`** | `Created` | Payload valid, aturan berhasil di-ingest. | Tidak ada tindakan lanjutan. Aturan langsung aktif secara *hot-reload*. |
| **`401`** | `unauthorized` | Header `Authorization: Bearer <token>` salah, kedaluwarsa, atau tidak dikirim. | Pastikan variabel `BEARER_TOKEN` yang dikirim cocok dengan token rahasia yang terkonfigurasi. |
| **`400`** | `invalid_rule_schema` | Struktur JSON tidak lengkap, tipe data salah, atau nilai enum `category`/`classification` tidak valid. | Periksa apakah seluruh properti wajib (`branch`, `ruleName`, `category`, `targetSource`, `pattern`, `assessment`, `classification`, `confidence`, `recommendedActions`, `createdBy`) telah lengkap dan sesuai enum yang diizinkan. |
| **`400`** | `unsafe_regex_pattern` | Pola `pattern` mengandung konstruksi regex berbahaya yang berisiko *ReDoS*. | Sederhanakan pola regex atau gunakan pencocokan substring teks langsung. |
| **`409`** | `rule_branch_conflict` | ID `branch` bertabrakan dengan branch *built-in* (`TD-01` s/d `TD-08`) atau branch kustom yang telah tersimpan. | Gunakan nomor branch baru yang belum pernah terdaftar sebelumnya (misal: `TD-19`). |
| **`413`** | `payload_too_large` | Ukuran payload JSON melebihi ambang batas keamanan 64 KB. | Ringkas instruksi teks rekomendasi mitigasi atau perpendek pola pencocokan. |
| **`405`** | `Method Not Allowed` | Endpoint diakses menggunakan method HTTP yang tidak diizinkan (`PUT`, `DELETE`, `PATCH`). | Basis aturan bersifat *append-only* (*immutable*). Gunakan method `POST` untuk menambahkan aturan baru. |

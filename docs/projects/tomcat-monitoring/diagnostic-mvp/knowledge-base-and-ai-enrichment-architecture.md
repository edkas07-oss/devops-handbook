# Knowledge Base and AI Enrichment Architecture

## 🔍 Overview

Dokumen ini mendefinisikan arsitektur pengelolaan *Knowledge Base* (basis pengetahuan diagnostik) pada **Diagnostic Service**, mencakup struktur penyimpanan multi-lapisan, protokol penanganan insiden yang belum memiliki basis aturan (*unknown / unmapped issue*), serta mekanisme integrasi dan pengayaan basis pengetahuan secara terpadu memanfaatkan Artificial Intelligence (AI) eksternal secara aman (*AI-Augmented SRE/DevOps*).

---

## 🏛️ Arsitektur 5-Layer Knowledge Base

Knowledge base pada platform Tomcat Monitoring dibagi ke dalam **5 lapisan fungsional (*functional layers*)** yang terpisah untuk menjaga isolasi, keamanan, dan determinisme sistem:

```mermaid
flowchart TD
    L5["Layer 5: Governance<br/>Kontrak Arsitektur<br/>(devops-handbook)"]
    L3["Layer 3: Target Topology<br/>Allowlist & Spool Path<br/>(targets.json)"]
    L1["Layer 1: Decision Engine<br/>Logika Aturan TD-01..TD-08<br/>(tomcat-down-engine.js)"]
    L2["Layer 2: Operational SOP<br/>Rekomendasi Mitigasi<br/>(result-renderer.js)"]
    L4["Layer 4: Incident History<br/>Database SQLite<br/>(diagnostic.db)"]

    L5 -.->|"Tata Kelola"| L3
    L5 -.->|"Tata Kelola"| L1
    L5 -.->|"Tata Kelola"| L2
    L5 -.->|"Tata Kelola"| L4

    L3 -->|"Metadata Target"| L1
    L1 -->|"Evaluasi Diagnosis"| L2
    L1 -->|"Simpan Hasil"| L4
```

### 📋 Matriks Komponen 5-Layer Knowledge Base

| Layer | Nama Lapisan | Lokasi Berkas / Sumber | Tanggung Jawab & Isi |
| :---: | :--- | :--- | :--- |
| **1** | **Logic & Decision Engine** | [`src/domain/tomcat-down-engine.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/domain/tomcat-down-engine.js) | Logika pohon keputusan deterministik (TD-01 s/d TD-08), aturan pencocokan pola bukti (*evidence pattern*), penetapan klasifikasi insiden, dan penentuan tingkat keyakinan (*confidence*). |
| **2** | **Operational Actions & Runbook** | [`src/application/result-renderer.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/application/result-renderer.js) & [`troubleshooting/`](file:///home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/troubleshooting/) | Katalog instruksi mitigasi dan panduan investigasi standar (SOP) bagi operator yang terikat pada masing-masing branch diagnosis. |
| **3** | **Target Topology & Mapping** | `/run/tomcat-diagnostic/config/targets.json` | Konfigurasi allowlist target yang memetakan identitas logis (`environment`, `host`, `tomcat_instance`) ke lokasi fisik partisi spool, direktori log, URL health check, dan crash dump. |
| **4** | **Persistent Incident History** | Database SQLite persisten (`diagnostic.db`) | Penyimpanan permanen seluruh *canonical result JSON*, hash SHA-256, snapshot bukti mentah, dan riwayat siklus insiden untuk keperluan audit dan analisis *post-mortem*. |
| **5** | **Enterprise Governance & ADR** | Repositori [`devops-handbook`](file:///home/eddywiyatno/git/devops-handbook) | *Single Source of Truth* (SSOT) yang memuat spesifikasi aturan formal, batas-batas keamanan (*security boundaries*), dan catatan keputusan arsitektur. |

---

## 🛡️ Protokol Penanganan Masalah Tanpa Knowledge Base (*Unknown Issue Protocol*)

Ketika terjadi insiden kegagalan yang **belum terpetakan dalam basis aturan (*unmapped failure pattern*)**, Diagnostic Service memberlakukan prinsip **"Deterministic Honesty" (Kejujuran Deterministik Tanpa Halusinasi)**:

```mermaid
flowchart TD
    A["<b>Insiden Baru Masuk</b><br/>(TomcatDown Firing)"] --> B{"Pola Cocok dengan<br/>Rule TD-01 s/d TD-05?"}

    B -->|"Ya (Cocok)"| C["<b>Eksekusi Branch Terkait</b><br/>• TD-01: Scrape/TLS Fail<br/>• TD-02: OOM Kill<br/>• TD-03: JVM Crash<br/>• TD-04: BindException<br/>• TD-05: Orderly Stop"]

    B -->|"Tidak (Pola Asing)"| D{"Status Container<br/>saat Diamati?"}

    D -->|"Container Exited"| E["<b>Branch TD-06</b><br/>Container exited;<br/>cause undetermined"]
    D -->|"Container Running"| F["<b>Branch TD-08</b><br/>Cause undetermined<br/>from available evidence"]
    D -->|"Bukti Kontradiksi"| G["<b>Branch TD-08</b><br/>Cause undetermined<br/>from contradicting evidence"]

    E & F & G --> H["<b>Klasifikasi: UNDETERMINED</b><br/>Tingkat Keyakinan: NONE (null)"]

    H --> I["<b>Kumpulkan Fakta Forensik</b><br/>• Metrik Scrape Terakhir<br/>• Exit Code & Telemetri Spool<br/>• Potongan Baris Log Terakhir"]

    I --> J["<b>Terbitkan Panduan SOP</b><br/>(Seksi 6: Operator Actions)"]

    J --> K[("<b>Arsipkan ke SQLite</b><br/>canonical_results & summaries")]

    K --> L["<b>Bahan Analisis Post-Mortem</b><br/>& Pengayaan Rule via AI"]
```

### 📋 Matriks Penanganan Insiden Belum Terpetakan (*Unmapped Handling Matrix*)

| Skenario Insiden | Branch Terpilih | Hasil Diagnosis (*Assessment*) | Klasifikasi & Keyakinan | Tindakan Sistem & Rekomendasi Operator |
| :--- | :---: | :--- | :---: | :--- |
| **Container Mati Tanpa Bukti Spesifik** | `TD-06` | *Container exited; cause undetermined* | `undetermined`<br/>*(confidence: none)* | Sajikan exit code aktual (misal: 143/137) di Seksi 3; berikan rekomendasi SOP pemeriksaan log container dan start ulang layanan di Seksi 6. |
| **Container Hidup / Bukti Tidak Cukup** | `TD-08` | *Cause undetermined from available evidence* | `undetermined`<br/>*(confidence: none)* | Sajikan status ketersediaan sumber data di Seksi 5; instruksikan operator melakukan investigasi manual terhadap endpoint dan jaringan. |
| **Ditemukan Bukti Bertentangan** | `TD-08` | *Cause undetermined from contradicting evidence* | `undetermined`<br/>*(confidence: none)* | Tampilkan anomali kontradiksi bukti di Seksi 5; rekomendasikan verifikasi status container dan health probe secara langsung. |

---

## 🤖 Strategi Pengayaan Knowledge Base Berbasis AI Eksternal (*AI Enrichment Strategy*)

Untuk memperkaya basis pengetahuan secara berkelanjutan tanpa mengorbankan stabilitas dan keamanan runtime, integrasi AI dilakukan secara **di luar jalur kritis (*out-of-band / offline post-mortem*)**:

```mermaid
sequenceDiagram
    autonumber
    actor SRE as Tim SRE / DevOps
    participant DB as SQLite Runtime (diagnostic.db)
    participant AI as External AI / LLM Analyzer
    participant Repo as Diagnostic Repository

    Note over DB: Insiden baru berstatus UNDETERMINED tersimpan
    SRE->>DB: 1. Ambil data forensik (canonical result & evidence summaries)
    DB-->>SRE: 2. Snapshot JSON, exit code, metrik, & log stack trace
    SRE->>AI: 3. Input prompt: Data forensik insiden + konteks error
    Note over AI: AI menganalisis akar masalah, pola kegagalan, & solusi mitigasi
    AI-->>SRE: 4. Output: Rekomendasi Rule Baru (Branch, Log Pattern, & SOP Actions)
    SRE->>Repo: 5. Review & Implementasi Rule baru ke engine & renderer
    Note over Repo: 6. Validasi & Automated Testing (npm test & validate.sh)
    Repo->>DB: 7. Deploy rilis baru (Sistem kini mengenali insiden tersebut secara otomatis)
```

---

### 🛠️ Perbandingan Metode Pembaruan Knowledge Base

| Kategori | Built-in Baseline (Code-Level Implementation) | Declarative Rulepack Engine (Append-Only Rules API — TN-018) |
| :--- | :--- | :--- |
| **Media Berkas / Endpoint** | [`src/domain/tomcat-down-engine.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/domain/tomcat-down-engine.js)<br/>[`src/application/result-renderer.js`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/src/application/result-renderer.js) | HTTP Endpoint: `POST /api/v1/rules`<br/>Penyimpanan: Tabel SQLite `custom_rules`<br/>Schema: [`config/schemas/rulepack-v1.schema.json`](file:///home/eddywiyatno/git/tomcat-diagnostic-service/config/schemas/rulepack-v1.schema.json) |
| **Format Masukan** | Kode JavaScript (fungsi deterministik). | Payload JSON terstruktur hasil generasi AI/SRE dengan validasi ketat Ajv & Safety Guard. |
| **Workflow Update** | 1. Tambah branch logic (misal `TD-01`..`TD-08`).<br/>2. Tambah SOP text di renderer.<br/>3. Jalankan unit test & rebuild image. | 1. Kirim HTTPS POST payload JSON ke `/api/v1/rules` dengan Bearer Token.<br/>2. Disimpan ke SQLite dan langsung di-hot-load ke memori engine secara instan tanpa *rebuild image* atau *restart container*. |
| **Keunggulan** | Validasi tipe data ketat, performa tinggi, dan menjadi fondasi *fallback engine* sistem. | Memungkinkan integrasi otomatis AI/SRE, *zero-downtime hot-reloading*, proteksi *append-only* (405 pada PUT/DELETE), dan pencegahan tabrakan *branch* (409 pada duplikat/built-in). |
| **Status** | **Aktif & Terverifikasi (Core Fallback Baseline).** | **Aktif & Terverifikasi (Production Ingestion Baseline — TN-018).** |

---

### 📝 Contoh Format Impor Deklaratif (`POST /api/v1/rules`)

Berikut adalah struktur baku yang tervalidasi oleh schema `rulepack-v1.schema.json`:

```json
{
  "branch": "TD-09",
  "ruleName": "DatabaseConnectionPoolExhausted",
  "category": "database_persistence",
  "targetSource": "local_file",
  "pattern": "CannotGetJdbcConnectionException",
  "assessment": "Tomcat unresponsive: Database connection pool exhausted",
  "classification": "confirmed_cause",
  "confidence": "high",
  "recommendedActions": [
    "Periksa utilisasi koneksi dan beban aktif pada server Database PostgreSQL/MySQL backend.",
    "Tinjau parameter maxTotal dan maxWaitMillis pada Resource DataSource (/conf/context.xml).",
    "Periksa stack trace thread dump untuk mendeteksi potensi connection leak pada aplikasi.",
    "Lakukan restart layanan Tomcat secara terkontrol setelah koneksi database stabil."
  ],
  "createdBy": "operator-sre"
}
```

---

## 📑 Taksonomi Kategori Domain Kegagalan (Failure Domains)

Sistem mengadopsi taksonomi **8 Kategori Domain Kegagalan** untuk menstrukturkan basis pengetahuan diagnosis dan mempermudah perutean eskalasi:

| Kategori Domain (*Category Enum*) | Definisi & Cakupan Kegagalan | Pola & Gejala Tipikal (*Typical Patterns*) | Tim Eskalasi / Triage Target |
| :--- | :--- | :--- | :--- |
| **`jvm_memory`** | Kegagalan alokasi memori internal JVM, class metadata, atau batas garbage collector. | `OutOfMemoryError: Java heap space`, `Metaspace`, `GC overhead limit exceeded`, `Direct buffer memory`. | Tim Backend / Java Developer |
| **`concurrency_threading`** | Kejenuhan worker thread pool Tomcat, thread starvation, atau kondisi saling kunci (*deadlock*). | `RejectedExecutionException: Thread pool is exhausted`, `Java-level deadlock`, thread saturation. | Tim Backend / Platform Engineer |
| **`database_persistence`** | Kegagalan konektivitas, exhaustion connection pool database, timeout query, atau deadlock database. | `CannotGetJdbcConnectionException`, `HikariPool timeout`, `SQLTimeoutException`, connection leak. | Tim DBA / Database Administrator |
| **`network_integration`** | Kegagalan jabat tangan TLS/SSL, timeout komunikasi microservice upstream, atau DNS/socket failure. | `SSLHandshakeException`, `SocketTimeoutException: Read timed out`, `ConnectException: Connection refused`. | Tim Network / Cloud Infrastructure |
| **`application_lifecycle`** | Kegagalan startup container, deployment WAR, inisialisasi context aplikasi, atau runtime servlet error. | `LifecycleException: Failed to start component`, `BeanCreationException`, `ClassNotFoundException`. | Tim Application Developer |
| **`storage_os_limits`** | Batasan resource OS host, exhaustion file descriptor / process limit (ulimit), atau kapasitas disk. | `Too many open files`, `No space left on device`, `Read-only file system`, exit code container tanpa dump. | Tim Sysadmin / Infrastructure |
| **`security_session`** | Kegagalan autentikasi eksternal, otorisasi, validasi token, replikasi sesi cluster, atau filter crash. | `LDAPException`, `SessionReplicationException`, `InvalidTokenException`, CORS filter crash. | Tim Security / IAM & Middleware |
| **`general`** | Kondisi cross-domain, telemetri anomali saling bertentangan, atau klasifikasi *fallback* yang belum terpetakan. | `Contradicting state`, `Undetermined evidence`, pola kegagalan baru yang memerlukan analisis AI. | SRE / Incident Commander |

---

## 📌 Standar Tata Kelola dan Keamanan

1. **Deterministic Execution:** Runtime Diagnostic Service murni mengeksekusi logika pencocokan berbasis aturan; tidak ada *prompting* atau inferensi LLM langsung di jalur penanganan insiden *real-time*.
2. **5-Layer Ingestion Guard:** Ingestion aturan deklaratif baru dilindungi oleh 5 lapis pengamanan ketat: (1) Auth Guard (timing-safe Bearer token), (2) Schema Guard (Ajv validasi schema), (3) Collision Guard (penolakan duplikasi branch atau konflik dengan branch built-in), (4) Size Guard (pembatasan payload maksimal 64 KiB), dan (5) Safety Guard (pemeriksaan keamanan regex dan sanitasi).
3. **Append-Only Immutability:** Endpoint mutasi `PUT`, `DELETE`, dan `PATCH` ditolak secara eksplisit dengan status `405 Method Not Allowed` guna mencegah modifikasi atau penghapusan histori aturan secara sepihak.
4. **Human-in-the-Loop Verification:** Setiap *rule* dan *action* yang dirumuskan oleh AI wajib diverifikasi atau diotorisasi sebelum di-POST ke API produksi.
5. **Auditability & Traceability:** Setiap keputusan insiden selalu memiliki referensi silang ke *rule version*, *evidence hash*, dan data historis di SQLite (`canonical_results` dan `custom_rules`).

# Tomcat Diagnostic Service REST API Reference

## 🔍 Overview

Dokumen ini merupakan spesifikasi referensi resmi (*Authoritative REST API Reference*) untuk antarmuka HTTPS internal pada **Tomcat Diagnostic Service**.

Diagnostic Service bertindak sebagai *Autonomous Diagnostic Engine & Decision Authority* pada platform Tomcat Monitoring. Layanan ini mengekspos endpoint HTTPS internal (Port `8443`) untuk kebutuhan pemantauan kesehatan layanan (*health probes*), pengikisan metrik operasional (*Prometheus metrics scrape*), penerimaan webhook alert otomatis dari Alertmanager, serta pendaftaran aturan diagnosis deklaratif secara dinamis (*hot-reloading rules API*).

---

## 🏛️ Karakteristik & Batasan Arsitektur Antarmuka

1. **Enkripsi TLS Internal Mandatory:**
   Seluruh komunikasi API wajib menggunakan protokol TLS 1.3 / HTTPS pada port `8443` dengan verifikasi truststore CA internal (`diagnostic-service-ca.crt`).
2. **Autentikasi Aman & Timing-Safe:**
   Endpoint terproteksi (`/api/v1/*`) mewajibkan header `Authorization: Bearer <token>` yang divalidasi menggunakan perbandingan *timing-safe* (`crypto.timingSafeEqual`) untuk mencegah serangan *timing attack*.
3. **Penegakan Batas Ukuran Payload (Bounded Memory Ingestion):**
   - Webhook Ingestion (`POST /api/v1/alerts/alertmanager`): Maksimal **256 KiB** (HTTP `413 Payload Too Large` jika melebihi).
   - Declarative Rule Ingestion (`POST /api/v1/rules`): Maksimal **64 KiB**.
4. **Append-Only Immutability Guard:**
   Seluruh operasi mutasi atau penghapusan aturan (`PUT`, `DELETE`, `PATCH`) dilarang secara mutlak dan otomatis mengembalikan status HTTP **`405 Method Not Allowed`** guna menjamin integritas rekam jejak audit (*tamper-proof*).

---

## 📋 Matriks Referensi REST API Terpadu

| Method | Endpoint Path | Autentikasi | Request / Response Format | Batas Payload | Deskripsi Fungsional & Kode Status |
| :---: | :--- | :---: | :---: | :---: | :--- |
| `GET` | `/health/live` | Public | `-` / `application/json` | - | **Liveness Probe:** Memverifikasi proses Node.js aktif dan responsif (`200 {"status":"UP"}`). Digunakan oleh container runtime/orchestrator (Podman/K8s). |
| `GET` | `/health/ready` | Public | `-` / `application/json` | - | **Readiness Probe:** Mengembalikan status kesiapan antrean dan database SQLite (`200` jika siap menerima trafik, `503` jika startup gagal/shutting down). |
| `GET` | `/health` | Public | `-` / `text/plain` | - | **Self-Monitoring Scrape:** Mengekspos metrik operasional internal format Prometheus text format untuk deteksi `DiagnosticServiceDown` via Prometheus. |
| `GET` | `/metrics` | Public | `-` / `text/plain` | - | **Operational Metrics:** Alias endpoint scraping metrik operasional Prometheus (`diagnostic_db_size_bytes`, `diagnostic_stale_locks_recovered_total`, dll.). |
| `POST` | `/api/v1/alerts/alertmanager` | Bearer Token | `application/json` / `application/json` | 256 KiB | **Webhook Ingestion:** Menerima payload alert Alertmanager v4, melakukan deduplikasi event atomik, dan memasukkan tugas ke antrean SQLite (`202 Accepted` / `400` / `401` / `413` / `415` / `429`). |
| `GET` | `/api/v1/rules` | Bearer Token | `-` / `application/json` | - | **Rules Catalog Export:** Mengambil katalog seluruh aturan diagnosis aktif (gabungan 20 built-in rules dan custom rules). Mendukung filter `?category=<enum>` (`200 OK` / `401`). |
| `POST` | `/api/v1/rules` | Bearer Token | `application/json` / `application/json` | 64 KiB | **Declarative Rule Ingestion:** Mendaftarkan aturan baru ke database SQLite `custom_rules` dan melakukan *hot-reload* instan ke RAM evaluator (`201 Created` / `400` / `401` / `409` / `413` / `415`). |
| `GET` | `/api/v1/rules/:id_or_branch` | Bearer Token | `-` / `application/json` | - | **Single Rule Detail:** Mengambil detail spesifikasi satu aturan berdasarkan nama branch (misal: `TD-01`, `TD-09`) atau database ID (`200 OK` / `401` / `404 Not Found`). |
| `PUT`, `DELETE`, `PATCH` | `/api/v1/rules/*` | - | - | - | **Append-Only Guard:** Seluruh operasi modifikasi/penghapusan aturan ditolak (`405 Method Not Allowed`). |

---

## 🔌 Spesifikasi Detail & Contoh Interaksi Endpoint

### 1. Webhook Ingestion (`POST /api/v1/alerts/alertmanager`)

Menerima webhook notifikasi alert dari Alertmanager v4 secara asinkron dengan pola *Durable Acceptance* ([TM-ADR-0015](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)).

- **Headers:**
  - `Authorization: Bearer <diagnostic_bearer_token>`
  - `Content-Type: application/json`
- **Batas Ukuran:** Maksimal 256 KiB.
- **Skema Validasi:** `alertmanager-webhook-v4.schema.json`.
- **Label Wajib:** `alertname`, `environment`, `host`, `tomcat_instance`, `check`, `severity`.

#### Contoh Request:

```bash
curl -k -s -X POST https://127.0.0.1:8443/api/v1/alerts/alertmanager \
  -H "Authorization: Bearer $(cat ~/.local/share/tomcat-monitoring/diagnostic-service-secrets/bearer-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "receiver": "lab-diagnostic-service",
    "status": "firing",
    "groupKey": "{}:{alertname=\"TomcatDown\"}",
    "alerts": [{
      "status": "firing",
      "labels": {
        "alertname": "TomcatDown",
        "environment": "lab",
        "host": "edkas-pc1",
        "tomcat_instance": "default",
        "check": "runtime-availability",
        "severity": "critical"
      },
      "annotations": {
        "summary": "Tomcat JMX scrape is unreachable"
      },
      "startsAt": "2026-09-11T12:00:00Z"
    }]
  }'
```

#### Contoh Respons (`202 Accepted`):

```json
{
  "accepted": 1,
  "duplicate": 0
}
```

---

### 2. Declarative Rulepack Ingestion (`POST /api/v1/rules`)

Mendaftarkan aturan diagnosis baru ke dalam basis pengetahuan dinamis dengan penegakan **5-Layer Ingestion Defense-in-Depth** ([TN-018](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)).

- **Headers:**
  - `Authorization: Bearer <diagnostic_bearer_token>`
  - `Content-Type: application/json`
- **Batas Ukuran:** Maksimal 64 KiB.
- **Skema Validasi:** `rulepack-v1.schema.json` (Ajv Draft 2020-12).
- **Proteksi Anti-Collision:** Menolak nama branch yang bertabrakan dengan branch bawaan (`TD-01` s/d `TD-08`, `AH-01` s/d `AH-05`, `GC-01` s/d `GC-04`, `TH-01` s/d `TH-03`) atau rule custom yang sudah ada.

#### Contoh Request:

```bash
curl -k -s -X POST https://127.0.0.1:8443/api/v1/rules \
  -H "Authorization: Bearer $(cat ~/.local/share/tomcat-monitoring/diagnostic-service-secrets/bearer-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "ruleId": "TomcatDown",
    "branch": "TD-09",
    "ruleName": "DatabaseConnectionPoolExhausted",
    "category": "database_persistence",
    "targetSource": "local_file",
    "pattern": "CannotGetJdbcConnectionException|HikariPool.*Connection is not available",
    "assessment": "Koneksi ke database backend habis atau mengalami deadlock pool",
    "classification": "DATABASE_POOL_EXHAUSTION",
    "confidence": "HIGH",
    "recommendedActions": [
      "Periksa kapasitas connection pool pada context.xml / application.properties",
      "Periksa status keaktifan dan beban koneksi database backend"
    ]
  }'
```

#### Contoh Respons (`201 Created`):

```json
{
  "id": 1,
  "ruleId": "TomcatDown",
  "branch": "TD-09",
  "ruleName": "DatabaseConnectionPoolExhausted",
  "category": "database_persistence",
  "targetSource": "local_file",
  "pattern": "CannotGetJdbcConnectionException|HikariPool.*Connection is not available",
  "assessment": "Koneksi ke database backend habis atau mengalami deadlock pool",
  "classification": "DATABASE_POOL_EXHAUSTION",
  "confidence": "HIGH",
  "recommendedActions": [
    "Periksa kapasitas connection pool pada context.xml / application.properties",
    "Periksa status keaktifan dan beban koneksi database backend"
  ],
  "createdBy": "operator-sre",
  "createdAt": "2026-09-11T12:30:00.000Z"
}
```

---

### 3. Rules Catalog Export & Filtering (`GET /api/v1/rules`)

Mengekspor seluruh katalog aturan diagnosis aktif atau memfilternya berdasarkan kategori domain kegagalan (*failure domain*).

- **Headers:** `Authorization: Bearer <diagnostic_bearer_token>`
- **Query Parameter (Opsional):**
  - `?category=<category_enum>`: Pilihan enum: `jvm_memory`, `concurrency_threading`, `database_persistence`, `network_integration`, `application_lifecycle`, `storage_os_limits`, `security_session`, `general`.

#### Contoh Request:

```bash
# Export seluruh aturan aktif
curl -k -s -H "Authorization: Bearer <token>" https://127.0.0.1:8443/api/v1/rules

# Filter berdasarkan kategori kegagalan konkurensi/thread
curl -k -s -H "Authorization: Bearer <token>" "https://127.0.0.1:8443/api/v1/rules?category=concurrency_threading"
```

#### Contoh Respons (`200 OK`):

```json
{
  "rules": [
    {
      "id": "builtin-TH-01",
      "ruleId": "TomcatThreadPoolSaturated",
      "branch": "TH-01",
      "ruleName": "ConnectorThreadPoolSaturated",
      "category": "concurrency_threading",
      "classification": "CONNECTOR_THREAD_POOL_SATURATED",
      "confidence": "HIGH",
      "recommendedActions": [
        "Periksa metrik tomcat_threads_busy_threads",
        "Lakukan inspeksi thread dump untuk mendeteksi blocking I/O"
      ]
    }
  ],
  "total": 1,
  "category": "concurrency_threading"
}
```

---

### 4. Single Rule Lookup (`GET /api/v1/rules/:id_or_branch`)

Mengambil rincian satu aturan berdasarkan nama cabang keputusan (`branch`) atau ID database SQLite.

- **Headers:** `Authorization: Bearer <diagnostic_bearer_token>`

#### Contoh Request:

```bash
curl -k -s -H "Authorization: Bearer <token>" https://127.0.0.1:8443/api/v1/rules/TD-01
```

#### Contoh Respons (`200 OK`):

```json
{
  "id": "builtin-TD-01",
  "ruleId": "TomcatDown",
  "branch": "TD-01",
  "ruleName": "OrderlyShutdownDetected",
  "category": "application_lifecycle",
  "classification": "ORDERLY_SHUTDOWN",
  "confidence": "HIGH",
  "assessment": "Tomcat dimatikan secara normal melalui shutdown hook",
  "recommendedActions": [
    "Verifikasi apakah jadwal maintenance atau deploy sedang berlangsung",
    "Jalankan startup container jika shutdown tidak direncanakan"
  ]
}
```

---

### 5. Health & Self-Monitoring Probes (`GET /health/live`, `/health/ready`, `/health`, `/metrics`)

Endpoint publik internal tanpa autentikasi untuk pengawasan operasional dan scraping Prometheus.

#### Contoh Scraping Prometheus Metrik (`GET /health` atau `GET /metrics`):

```bash
curl -k -s https://127.0.0.1:8443/health
```

#### Cuplikan Output Metrik Prometheus:

```text
# HELP diagnostic_service_ready Service readiness status (1 = ready, 0 = unavailable)
# TYPE diagnostic_service_ready gauge
diagnostic_service_ready 1

# HELP diagnostic_db_size_bytes Database file size on disk in bytes
# TYPE diagnostic_db_size_bytes gauge
diagnostic_db_size_bytes 73728

# HELP diagnostic_stale_locks_recovered_total Total stale queue locks recovered
# TYPE diagnostic_stale_locks_recovered_total counter
diagnostic_stale_locks_recovered_total 0

# HELP diagnostic_housekeeping_runs_total Total retention pruning housekeeping runs
# TYPE diagnostic_housekeeping_runs_total counter
diagnostic_housekeeping_runs_total 1
```

---

## 🔗 Related Documentation

- [Runbook: AI Knowledge Enrichment & Declarative Rule Management](../operations/ai-knowledge-enrichment-and-rule-management-runbook.md)
- [Tomcat Monitoring Architecture Decision Records](../../../adr/tomcat-monitoring/index.md)
- [Alertmanager Webhook Contract](../diagnostic-mvp/alertmanager-webhook-contract.md)
- [Runtime Configuration and Verification Contract](../diagnostic-mvp/runtime-configuration-and-verification-contract.md)
- [TN-018: Implement Strict Declarative Rulepack Engine](../engineering-journal/diagnostic-mvp-pilot/TN-018-implement-strict-declarative-rulepack-engine.md)

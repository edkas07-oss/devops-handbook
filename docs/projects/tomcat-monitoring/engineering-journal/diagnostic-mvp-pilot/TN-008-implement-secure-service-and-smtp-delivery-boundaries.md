# TN-008 — Implement Secure Service and SMTP Delivery Boundaries

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Mengimplementasikan dan menguji antarmuka HTTPS webhook/health/metrics serta batasan pengiriman SMTP terbatas (*bounded SMTP delivery*) melalui *component tests* sebelum pekerjaan image dimulai.

## 📚 Scope

Pekerjaan yang disetujui mencakup:
- Dependensi presisi Nodemailer dan migrasi *delivery attempts*;
- Handler dan server HTTPS, autentikasi bearer, batasan ukuran request 256 KiB, pemetaan respons;
- Adapter SMTP terbatas;
- Unit tests, component tests, validator, README, dan dokumentasi.

Pekerjaan yang dikecualikan mencakup build image, runtime Mailpit aktual, deployment, konfigurasi pemantauan Prometheus/Alertmanager, commit, dan push.

## 🔄 Technical Workflow

Alur teknis batas penerimaan permintaan HTTPS dan pengiriman notifikasi email via SMTP:

```text
1. HTTPS request -> 2. auth/content/size checks -> 3. durable ingestion -> 4. 202
1. canonical render -> 2. bounded SMTP adapter -> 3. delivery attempt state
```

### Rincian Aktivitas Alur Kerja

#### 1. Jalur Penerimaan Permintaan Ingestion (HTTPS Request Boundary)

1. **HTTPS request:**
   Penerimaan koneksi masuk HTTPS pada port 8443 dengan enkripsi TLS internal.
2. **auth/content/size checks:**
   Pemeriksaan batas keamanan request sebelum pemrosesan:
    - **auth check:** Memvalidasi Bearer token menggunakan perbandingan waktu konstan (`crypto.timingSafeEqual`) guna menangkal *timing attacks*.
    - **content check:** Memvalidasi header wajib `Content-Type: application/json`.
    - **size check:** Membatasi ukuran payload request maksimal 256 KiB (`413 Payload Too Large` jika terlampaui).
3. **durable ingestion:**
   Meneruskan payload yang valid ke modul ingestion SQLite untuk dipersistensikan secara atomik ke database lokal.
4. **202:**
   Mengembalikan respons HTTP `202 Accepted` kepada Alertmanager segera setelah transaksi database berhasil di-commit.

#### 2. Jalur Pengiriman Notifikasi Insiden (SMTP Delivery Boundary)

1. **canonical render:**
   Penerimaan laporan diagnosis 7-seksi SRE yang telah dirender dalam format multipart (HTML dan Plain Text).
2. **bounded SMTP adapter:**
   Pengiriman email notifikasi via SMTP (Nodemailer) dengan penegakan batasan keamanan:
    - **disableFileAccess:** Memblokir akses dan pelampiran file lokal (`disableFileAccess: true`).
    - **disableUrlAccess:** Memblokir akses URL eksternal / mitigasi SSRF (`disableUrlAccess: true`).
    - **socket timeout:** Penerapan batas waktu timeout soket ketat (5000ms pada connection, greeting, dan socket).
3. **delivery attempt state:**
   Pencatatan status hasil pengiriman pada tabel `notification_attempts` (status `sent`, `failed`, kode error) dengan batas maksimal retry 3 kali (*exponential backoff*).

### Pseudocode Batasan HTTPS dan Pengiriman Notifikasi SMTP

```python
# Berkas Implementasi: src/server/http-service.js, src/adapters/smtp-adapter.js, & src/application/notification-delivery.js

# ==============================================================================
# 1. Jalur Penerimaan Permintaan Ingestion (HTTPS)
# ==============================================================================
def handle_https_request(request):
    # 1. HTTPS request: Menerima koneksi masuk HTTPS pada port 8443 (src/server/http-service.js)

    # 2. auth/content/size checks: (src/server/http-service.js)
    # - auth check: Validasi Bearer token timing-safe
    auth_header = request.headers.get("Authorization", "")
    if not timing_safe_equal(auth_header, f"Bearer {CONFIG.BEARER_TOKEN}"):
        return http_response(401, {"error": "unauthorized"})

    # - content check: Validasi header Content-Type application/json
    if request.headers.get("Content-Type") != "application/json":
        return http_response(415, {"error": "unsupported_media_type"})

    # - size check: Validasi batas ukuran payload request maksimum 256 KiB
    if request.content_length > 262144:
        return http_response(413, {"error": "payload_too_large"})

    # 3. durable ingestion: Penyimpanan event alert secara transaksional ke SQLite (src/adapters/sqlite-repository.js)
    queue_id = durable_ingestion(request.json_body)

    # 4. 202: Respons HTTP 202 Accepted segera setelah data tersimpan aman
    return http_response(202, {"status": "accepted", "queue_id": queue_id})


# ==============================================================================
# 2. Jalur Pengiriman Notifikasi Insiden (SMTP)
# ==============================================================================
def deliver_incident_notification(canonical_result, rendered_report):
    # 1. canonical render: Menerima hasil evaluasi kanonikal ter-render multipart (src/application/result-renderer.js)
    attempt_count = sqlite_db.get_attempt_count(canonical_result.id)
    if attempt_count >= 3:
        log_error("Batas maksimal 3 kali pengiriman email telah tercapai; pengiriman dihentikan")
        return False

    # 2. bounded SMTP adapter: Eksekusi pengiriman email via adapter aman (src/adapters/smtp-adapter.js)
    try:
        smtp_client.send_mail(
            from_address=CONFIG.SMTP_FROM,
            to_address=CONFIG.SMTP_TO,
            subject=format_notification_subject(canonical_result),
            text_body=rendered_report.text,
            html_body=rendered_report.html,
            # - disableFileAccess: Tolak akses file lokal
            disable_file_access=True,
            # - disableUrlAccess: Tolak pembacaan URL eksternal / SSRF
            disable_url_access=True,
            # - socket timeout: Batas waktu timeout socket 5000ms
            socket_timeout_ms=5000
        )
        # 3. delivery attempt state: Pencatatan status pengiriman berhasil ('sent') (src/application/notification-delivery.js)
        sqlite_db.record_attempt(canonical_result.id, attempt=attempt_count + 1, status="sent")
        return True
    except SmtpTransportError as err:
        # 3. delivery attempt state: Pencatatan status kegagalan ('failed') dan penjadwalan retry
        sqlite_db.record_attempt(canonical_result.id, attempt=attempt_count + 1, status="failed", error_code=err.code)
        schedule_exponential_backoff(canonical_result, attempt_count + 1)
        return False
```

### Pemetaan Berkas Implementasi & Self-Documentation

Setiap tahapan alur kerja dan pseudocode di atas diimplementasikan secara modular pada berkas sumber (*source code*) repositori `tomcat-diagnostic-service` dengan standar *self-documentation* Bahasa Indonesia:

| Tahap Alur Kerja | Berkas Sumber (*Source File*) | Fungsi / Komponen Utama | Standar *Self-Documentation* & Batasan |
| --- | --- | --- | --- |
| **1. HTTPS request** | `src/server/http-service.js` | Server HTTPS / TLS | Server internal pada port 8443 dengan enkripsi TLS lokal. |
| **2. auth/content/size checks** | `src/server/http-service.js` | Request Security Guard | Bearer auth via `timingSafeEqual`, validasi header `application/json`, dan payload max 256 KiB. |
| **3. durable ingestion** | `src/application/ingest-alertmanager.js`<br/>`src/adapters/sqlite-repository.js` | `ingestAlertmanager()` | Penyerapan dan penyimpanan transaksi event ke database SQLite lokal. |
| **4. 202** | `src/server/http-service.js` | Response Handler | Mengembalikan respons HTTP 202 Accepted segera setelah data tersimpan aman. |
| **5. canonical render** | `src/application/result-renderer.js` | `renderResult()` | Menghasilkan laporan presentasi 7-seksi Enterprise SRE format multipart (HTML & Text). |
| **6. bounded SMTP adapter** | `src/adapters/smtp-adapter.js` | `createSmtpTransport()`, `sendEmail()` | Transport SMTP Nodemailer dengan isolasi `disableFileAccess`, `disableUrlAccess`, dan timeout socket 5000ms. |
| **7. delivery attempt state** | `src/application/notification-delivery.js`<br/>`migrations/003-delivery-attempts.sql` | `NotificationDelivery`, Tabel `notification_attempts` | Pencatatan status pengiriman (`sent`/`failed`), kode error kanonikal, dan kebijakan retry terikat (maksimal 3 kali). |

## 🧭 Implementation Plan

| Tahap | Rencana |
| :--- | :--- |
| **Pin the SMTP Client** | Mengunci dependensi presisi `nodemailer@9.0.6` dengan zero transitive dependencies pada container terisolasi. |
| **Implement Request and Delivery Boundaries** | Mengimplementasikan handler HTTPS aman, bearer auth timing-safe, batas ukuran 256 KiB, dan adapter SMTP terbatas. |
| **Run Source Tests** | Menjalankan validasi statis dan unit tests untuk membuktikan fungsi handler dan pesan multipart. |
| **Verify Ephemeral HTTPS and SMTP Sockets** | Menguji soket riil HTTPS dengan sertifikat sementara dan penerimaan pesan pada listener SMTP mock. |

## ⚙️ Implementation

<div class="procedure" markdown>
<div class="procedure-step" markdown>

### Pin the SMTP Client

```bash
podman run --rm --name tomcat-diagnostic-tn008-dependency --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm install --save-exact nodemailer@9.0.6 \
  --ignore-scripts --no-audit --no-fund
```

!!! success "Expected Result"

    Dependensi presisi dan lockfile tersedia tanpa paket transitif (*zero transitive dependencies*).

**Actual Result:** Nodemailer `9.0.6` ditambahkan dengan nol dependensi transitif.

</div>
<div class="procedure-step" markdown>

### Implement Request and Delivery Boundaries

Skrip migrasi `003` menambahkan pencatatan riwayat pengiriman notifikasi (*notification attempts*). Handler HTTPS mengimplementasikan endpoint webhook, liveness, readiness, metrics, komparasi token bearer *constant-time*, validasi media type JSON, batas 256 KiB, dan kode respons kontrak. Adapter SMTP menonaktifkan akses berkas lokal dan URL serta menerapkan timeout pada level koneksi, greeting, dan socket.

!!! success "Expected Result"

    Batasan source terbentuk tanpa memuat nilai rahasia (*secrets*) atau endpoint environment hardcoded.

**Actual Result:** Berkas source dan unit fixtures tersedia; verifikasi level socket diselesaikan pada langkah pengujian komponen berikutnya.

</div>
<div class="procedure-step" markdown>

### Run Source Tests

```bash
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn008-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Validasi awal sempat gagal karena konfigurasi lock validator hanya mendaftarkan Ajv. Validator dikoreksi untuk mewajibkan Ajv dan Nodemailer secara presisi. Pengujian ulang meluluskan 25 pengujian.

!!! success "Expected Result"

    Pengujian existing dan pengujian baru batasan handler/MIME seluruhnya lulus.

**Actual Result:** 25 pengujian lulus, 0 gagal. Handler dipanggil secara langsung dan SMTP menggunakan stream transport; verifikasi komponen pada level socket dilakukan pada langkah berikutnya.

</div>
<div class="procedure-step" markdown>

### Verify Ephemeral HTTPS and SMTP Sockets

Sertifikat sementara dibuat hanya di bawah direktori yang disetujui:

```bash
test ! -e /tmp/tomcat-diagnostic-tn008-component
mkdir /tmp/tomcat-diagnostic-tn008-component
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost \
  -addext subjectAltName=DNS:localhost,IP:127.0.0.1 \
  -keyout /tmp/tomcat-diagnostic-tn008-component/server.key \
  -out /tmp/tomcat-diagnostic-tn008-component/server.crt
podman run --rm --name tomcat-diagnostic-tn008-component --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z \
  -v /tmp/tomcat-diagnostic-tn008-component:/tmp/tn008-tls:ro,Z -w /app \
  -e TN008_TLS_KEY=/tmp/tn008-tls/server.key \
  -e TN008_TLS_CERT=/tmp/tn008-tls/server.crt \
  localhost/nodejs:24.18.0 npm run test:component
```

!!! success "Expected Result"

    Trusted CA berhasil terhubung, untrusted CA ditolak, endpoint HTTPS merespons dengan benar, dan listener SMTP tiruan menerima satu pesan multipart.

**Actual Result:** 2 pengujian komponen lulus. Pembersihan dilakukan secara presisi:

```bash
rm -r /tmp/tomcat-diagnostic-tn008-component
```

Pemeriksaan akhir memastikan direktori sementara telah dihapus dan tidak ada artefak `.key`, `.crt`, atau `.pem` yang tertinggal di repositori.

</div>
</div>

## 📁 Artifact Manifest

| Path | Responsibility |
| --- | --- |
| `migrations/003-delivery-attempts.sql` | Persistensi riwayat pengiriman notifikasi |
| `src/server/http-service.js` | Server HTTPS dan batasan keamanan request |
| `src/adapters/smtp-adapter.js` | Transport pengiriman SMTP terbatas |
| `test/unit/http-service.test.js` | Pengujian auth, media type, limit ukuran, health, metrics |
| `test/unit/smtp-adapter.test.js` | Pengujian pembuatan pesan multipart |

## 🖥️ Source-Control Handoff

Source-control handoff diotorisasi setelah penutupan teknis:

```bash
git add README.md package.json package-lock.json scripts/validate.sh \
  migrations/003-delivery-attempts.sql src/adapters/sqlite-repository.js \
  src/adapters/smtp-adapter.js src/server/http-service.js \
  test/component/secure-service-component.test.js \
  test/unit/http-service.test.js test/unit/smtp-adapter.test.js
git diff --cached --check
git commit -m "feat(diagnostic-service): add secure service delivery boundaries"
```

Hasil aktual adalah commit `bc4b7ae`; push tidak dilakukan pada aktivitas ini.

## 🧭 Reproduction Guide

```bash
git checkout bc4b7ae
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn008-regression --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Hasil regresi yang diharapkan adalah 25 pengujian lulus. Reproduksi socket membutuhkan prosedur pembuatan sertifikat sementara di atas dan penghapusan direktori secara presisi setelahnya.

## ✅ Verification

| Layer | Actual result |
| --- | --- |
| Static validation | Passed |
| Unit/source integration | 25 passed |
| Actual HTTPS socket | Passed: trusted/untrusted CA and endpoints |
| Fake SMTP socket | Passed: multipart message received |
| Cleanup | Passed: direktori sementara dihapus; artefak sensitif 0 |

## 🧾 Outcome

Batasan source HTTPS dan SMTP telah diimplementasikan. 25 pengujian regresi dan 2 pengujian komponen socket sementara telah lulus tanpa menyimpan state persisten atau sertifikat di dalam repositori Git.

## ⏭️ Next Steps

Mendefinisikan kontrak konfigurasi dan startup aplikasi, kemudian menyiapkan pembuatan image dan verifikasi komponen sekali-pakai (*disposable component verification*) setelah identitas base image yang tidak dapat diubah disetujui.

## 🔗 Related Documentation

- [TN-007](TN-007-implement-worker-canonical-result-and-renderers.md)
- [Webhook Contract](../../diagnostic-mvp/alertmanager-webhook-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)

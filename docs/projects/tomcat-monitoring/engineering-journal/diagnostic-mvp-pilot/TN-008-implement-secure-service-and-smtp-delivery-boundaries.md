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

## 🧭 Implementation Plan

```text
HTTPS request -> auth/content/size checks -> durable ingestion -> 202
canonical render -> bounded SMTP adapter -> delivery attempt state
```

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

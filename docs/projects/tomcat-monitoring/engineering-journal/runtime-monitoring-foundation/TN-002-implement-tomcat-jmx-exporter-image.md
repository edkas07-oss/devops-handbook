# TN-002 — Implement Tomcat JMX Exporter Image

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Reconstructed |
| Project | Tomcat Monitoring |
| Phase | Runtime Monitoring Foundation |
| Activity Date | 2026-08-15 |
| Recorded Date | Unknown; file modified 2026-08-17 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | Unknown; approval evidenced by communication context |

!!! note "Reconstruction Notice"

    Technical Note ini direkonstruksi setelah image build dan smoke test telah
    dilakukan. Tanggal pertama dokumen dibuat tidak dapat dibuktikan;
    filesystem hanya menunjukkan dokumen dimodifikasi pada 2026-08-17. Urutan
    implementasi, output, dan troubleshooting dipertahankan berdasarkan catatan
    serta evidence yang tersedia dan tidak dinyatakan sebagai live recording.

## Objective

Menyiapkan kebutuhan JMX Exporter pada Deployment Topology dengan membangun
derived Tomcat image dan membuktikan bahwa metrics JVM dapat disajikan melalui
HTTPS tanpa mengaktifkan remote JMX.

## Background

TN-001 mengidentifikasi JMX Exporter Java Agent sebagai kebutuhan
Infrastructure pertama yang harus tersedia sebelum Prometheus diintegrasikan.
Repository `tomcat` tetap menyediakan generic image
`localhost/tomcat:9.0`, sedangkan instrumentation ditempatkan pada repository
terpisah agar lifecycle base image dan JMX Exporter tidak bercampur.

Architecture menetapkan interface berikut:

```text
Prometheus
    ↓ HTTPS /metrics, port 9404, TLS sisi server
JMX Exporter Java Agent
    ↓ Local MBean access
Tomcat JVM
```

Pada saat implementasi, root How-to khusus JMX Exporter belum tersedia.
Repository README dan implementation scripts digunakan sebagai referensi
sementara. Technical Note ini mencatat urutan integrasi dan hasilnya, bukan
menyalin prosedur internal pemasangan Java Agent.

## Scope

Technical Note ini mencakup:

- Persiapan repository `tomcat-jmx-exporter`;
- Penggunaan `localhost/tomcat:9.0` sebagai base image;
- Build derived image dengan JMX Exporter `1.6.0`;
- Verifikasi artifact menggunakan pinned SHA-256;
- Integrasi config dan TLS material sebagai runtime input;
- Local HTTPS integration test pada endpoint `/metrics`; serta
- Pencatatan hasil, masalah, perbaikan, dan handoff berikutnya.

Technical Note ini tidak mencakup:

- Tutorial internal instalasi atau konfigurasi JMX Exporter;
- Pembuatan production certificate;
- Integrasi Prometheus dan CA trust;
- Telegraf application health check;
- CI/CD, Ansible, atau target deployment; atau
- Publikasi source dan container image.

## Prerequisites

| Prerequisite | Status | Evidence |
| --- | --- | --- |
| Architecture interface | Verified | HTTPS `9404/metrics` dan local MBean access ditetapkan |
| Repository boundary | Verified | `tomcat` tetap generic dan derived image memiliki owner terpisah |
| Generic Tomcat image | Verified | `localhost/tomcat:9.0` tersedia secara lokal |
| Rootless Podman | Verified | Podman `4.9.3` tersedia pada development workstation |
| JMX Exporter artifact | Verified | Version `1.6.0` dan pinned SHA-256 tersedia |
| Implementation reference | Verified | Repository README dan scripts tersedia |
| Reusable root How-to | Pending | JMX Exporter Java Agent How-to belum diterbitkan |

## Execution Decision

N/A. Implementasi menjalankan repository boundary dan security requirement
yang sudah dicatat pada TN-001. Keputusan arsitektur baru tidak dibuat pada
aktivitas ini.

## Architecture

Implementasi mengikuti current-state documentation berikut:

- **[Deployment Topology](../../architecture/index.md#deployment-topology)**
- **[Security Controls](../../architecture/index.md#security-controls)**
- **[Infrastructure Components](../../infrastructure/index.md#infrastructure-components)**

Artifact yang dihasilkan memenuhi contract berikut:

| Item | Contract |
| --- | --- |
| Base image | `localhost/tomcat:9.0` |
| Derived image | `localhost/tomcat-jmx-exporter:1.0.0` |
| JMX Exporter | Java Agent `1.6.0` dengan pinned SHA-256 |
| Metrics interface | `HTTPS /metrics` pada container port `9404` |
| JVM access | Local MBean access; tanpa remote JMX/RMI |
| TLS | TLS sisi server; tanpa client certificate |
| Runtime config | Read-only mount; dimiliki project monitoring |
| TLS material | Read-only runtime secret; tidak disimpan di image atau Git |

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Confirm Component Readiness

1. Verifikasi repository `tomcat-jmx-exporter` menggunakan
   `localhost/tomcat:9.0` sebagai base image.
2. Verifikasi versioned image, JMX Exporter version, metrics interface, dan
   security boundary sesuai artifact contract.
3. Gunakan README dan scripts pada component repository sebagai execution
   interface sementara sampai reusable JMX Exporter How-to diterbitkan pada
   root How-to.

!!! success "Expected Result"

    Component siap menjalani integration test tanpa memindahkan detail internal
    instalasi Java Agent ke Engineering Journal.

</div>

<div class="procedure-step" markdown>

### Run the Component Integration Test

1. Jalankan build dan automated smoke test menggunakan interface yang
   disediakan component repository.

    ```bash
    cd /home/eddywiyatno/git/tomcat-jmx-exporter
    ./scripts/build.sh
    ./scripts/test.sh
    ```

2. Verifikasi test menyelesaikan build, menjalankan Tomcat dengan embedded JMX
   Exporter, dan mengakses HTTPS `/metrics` dengan certificate validation.
3. Verifikasi hasil metrics memuat bukti exporter scrape dan pengambilan data
   dari JVM Tomcat yang sama.
4. Catat output, artifact identity, masalah yang ditemukan, dan hasil
   perbaikannya sebagai evidence.

Output yang diamati saat implementasi:

```text
.artifacts/jmx_prometheus_javaagent.jar: OK
Build completed: localhost/tomcat-jmx-exporter:1.0.0
Smoke test passed: HTTPS /metrics and local JVM collection are operational.
```

!!! success "Expected Result"

    Derived image memenuhi interface JMX pada Deployment Topology dan siap
    menjadi input integrasi Prometheus.

</div>

<div class="procedure-step" markdown>

### Record the Integration Handoff

1. Catat image `localhost/tomcat-jmx-exporter:1.0.0` sebagai local verified
   artifact.
2. Catat `https://<tomcat-container>:9404/metrics` sebagai interface yang harus
   digunakan Prometheus.
3. Catat production certificate, CA trust, container network, image registry,
   dan pipeline sebagai dependency deployment berikutnya.
4. Pertahankan detail pemasangan dan konfigurasi Java Agent sebagai tanggung
   jawab reusable root How-to.

!!! success "Expected Result"

    Tahap berikutnya memiliki artifact, interface, evidence, dan daftar
    dependency yang jelas untuk integration serta deployment.

</div>

</div>

## Verification

Verifikasi dilakukan pada development workstation tanggal 2026-08-15.

| Item | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Source syntax | `bash -n entrypoint.sh scripts/*.sh` | Shell scripts valid | Passed | Command result dicatat tanpa syntax error |
| Artifact integrity | Build script dan image build checksum verification | SHA-256 sesuai pinned value | Passed | Output `.artifacts/jmx_prometheus_javaagent.jar: OK` |
| Derived image | `./scripts/build.sh` | Versioned dan `latest` image tersedia | Passed | Final image ID `47adae9464a1` |
| Image identity | Inspect environment dan OCI labels | Project `tomcat-jmx-exporter`, image `1.0.0`, JMX Exporter `1.6.0` | Passed after correction | Final inspection setelah build argument diperbaiki |
| HTTPS metrics | `./scripts/test.sh` | Certificate tervalidasi dan `/metrics` tersedia | Passed | Smoke-test output menyatakan HTTPS `/metrics` operational |
| Local JVM collection | Periksa `jvm_memory_heap_used_bytes` | Metric berasal dari JVM Tomcat yang sama | Passed | Metric `jvm_memory_heap_used_bytes` ditemukan pada response |
| Exporter scrape | Periksa `jmx_scrape_duration_seconds` | JMX scrape berhasil | Passed | Metric `jmx_scrape_duration_seconds` ditemukan pada response |
| Cleanup | Periksa temporary container dan TLS files | Tidak ada test resource tertinggal | Passed | Cleanup check pada test script |
| Prometheus integration | Prometheus scrape dengan production CA | Prometheus mengambil metrics | Not verified; outside scope | Tidak ada Prometheus integration test pada aktivitas ini |

Hasil membuktikan kesiapan component secara lokal. Hasil belum membuktikan
integrasi Prometheus, production certificate, container network, CI build, atau
target deployment.

## Troubleshooting

### Issue — Derived image inherited base project identity

#### Symptom

Build pertama menghasilkan tag yang benar, tetapi image inspection menunjukkan
environment `PROJECT=tomcat` dan `VERSION=9.0` dari base image.

#### Investigation

Containerfile menggunakan build arguments `PROJECT` dan `VERSION` yang memiliki
nama sama dengan inherited environment variables pada base image. Banner
runtime derived image akan menampilkan identity base image.

#### Root Cause

Nama build argument bertabrakan dengan environment variable yang diwarisi dari
`localhost/tomcat:9.0` pada saat instruction `ENV` diproses.

#### Resolution

Build arguments diubah menjadi `IMAGE_PROJECT` dan `IMAGE_VERSION`. Image
dibangun ulang dan smoke test dijalankan kembali. Final inspection menunjukkan
project `tomcat-jmx-exporter`, image version `1.0.0`, dan JMX Exporter `1.6.0`.

## Lessons Learned

- Generic Tomcat image dan monitoring instrumentation perlu memiliki lifecycle
  repository yang terpisah.
- Pinned version dan checksum harus diverifikasi sebelum dan selama image
  build.
- Local HTTPS smoke test membuktikan component interface, tetapi tidak
  menggantikan Prometheus integration test.
- Detail pemasangan Java Agent yang reusable harus dipromosikan ke root How-to;
  journal hanya mempertahankan urutan integrasi dan hasil aktual.

## Next Steps

- Publikasikan source component ke Gitea pada TN-003.
- Terbitkan reusable JMX Exporter Java Agent procedure pada root How-to.
- Gunakan derived image sebagai candidate untuk CI build dan integration test.
- Siapkan container network, production TLS material, dan Prometheus CA trust.
- Integrasikan Prometheus dengan `https://<tomcat-container>:9404/metrics`.
- Lanjutkan Telegraf integration ke `http://<tomcat-container>:8080/health`.

## Outcome

Local derived image `localhost/tomcat-jmx-exporter:1.0.0` berhasil dibangun dan
lulus HTTPS serta JVM metrics smoke test pada activity date. Hasil tersebut
membuktikan local component interface yang diuji pada TN-002, bukan Prometheus
integration, production deployment, atau clean build source revision yang
diterbitkan setelah aktivitas ini.

Outstanding work meliputi reusable root How-to, current-source rebuild,
Prometheus integration, Telegraf health check, production TLS, container
network, registry, CI/CD, dan target deployment.

## Related Documentation

- [TN-001 — Design Runtime Monitoring Contract](TN-001-design-runtime-monitoring-contract.md)
- [TN-003 — Publish Tomcat JMX Exporter Source](TN-003-publish-tomcat-jmx-exporter-source.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Development](../../development/index.md)
- [CI/CD](../../ci-cd/index.md)
- [Root How-to Catalog](../../../../how-to/index.md)

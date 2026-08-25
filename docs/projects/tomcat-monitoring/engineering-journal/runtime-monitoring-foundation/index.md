# Runtime Monitoring Foundation Engineering Journal

## Overview

Fase Runtime Monitoring Foundation mencatat awal perjalanan Tomcat Monitoring.
Pekerjaan dimulai dari kebutuhan menyediakan monitoring ringan untuk Tomcat
berbasis container tanpa membuka remote JMX dan tanpa membebani setiap instance
dengan administrasi akun serta credential JMX.

Dari kebutuhan tersebut, fase ini menentukan arsitektur awal, topology,
security boundary, pembagian repository, serta kebutuhan Development,
Infrastructure, dan CI/CD. Hasil desain kemudian diringkas pada
[Architecture](../../architecture/index.md), sementara urutan kerja dan konteks
keputusannya tetap dipertahankan di Engineering Journal.

Implementasi pertama adalah derived Tomcat image dengan embedded JMX Exporter.
Current source `231cb91` telah dibangun menjadi local image dan lulus HTTPS/JVM
component smoke test. Integrasi Prometheus, Telegraf, dan deployment end-to-end
belum dilaksanakan sehingga fase masih berjalan.

## Objective

Membentuk foundation Tomcat Monitoring mulai dari kebutuhan awal sampai
tersedianya komponen monitoring pertama yang terverifikasi dengan cara:

- Menentukan arsitektur, topology, dan security boundary;
- Menetapkan pembagian tanggung jawab source repository;
- Menyiapkan development environment dan container runtime;
- Mengidentifikasi kebutuhan infrastructure dan delivery;
- Membangun dan memverifikasi derived Tomcat image dengan JMX Exporter;
- Menetapkan kebutuhan CI/CD untuk build, integration test, dan deployment; dan
- Mencatat dependency yang membutuhkan prosedur reusable pada root How-to.

## Implementation Result

| Area | Implementation | Status |
| --- | --- | --- |
| Architecture foundation | Topology, monitoring flow, security controls, dan keputusan embedded monitoring instrumentation tersedia | Completed |
| Development readiness | Git, Gitea, Rootless Podman, dan repository boundary tersedia | Completed |
| JMX Exporter infrastructure | Local derived image JMX Exporter `1.6.0` dan endpoint HTTPS `9404/metrics` telah diverifikasi pada TN-002 | Completed |
| Component source | Current source `231cb91` telah dipublikasikan, dibangun menjadi local image, dan lulus HTTPS/JVM smoke test | Completed |
| Application health interface | Telegraf menuju `http://<tomcat-container>:8080/health`; integrasi belum dilaksanakan | Planned |
| Monitoring platform | Prometheus, Telegraf, storage, dashboard, dan Alertmanager | Planned |
| Delivery design | Boundary CI, CD, Ansible, dan deployment verification telah diidentifikasi | Completed |
| AI repository governance | Root `AGENTS.md` pada empat repository telah lulus structural, fresh-session, dan tabletop verification | Completed |
| CI/CD implementation | Pipeline build, integration test, provisioning, dan deployment | Planned |
| End-to-end deployment | Seluruh alur topology berjalan dan diverifikasi | Planned |

## Technical Notes

1. **[TN-001 — Design Runtime Monitoring Contract](TN-001-design-runtime-monitoring-contract.md)**

    Mencatat proses penentuan arsitektur awal, repository boundary, kebutuhan
    delivery, dan urutan implementasi project.

2. **[TN-002 — Implement Tomcat JMX Exporter Image](TN-002-implement-tomcat-jmx-exporter-image.md)**

    Menjalankan kebutuhan infrastructure pertama dengan membangun derived
    Tomcat image dan memverifikasi endpoint JMX Exporter melalui HTTPS.

3. **[TN-003 — Standardize Indonesian Self-Documentation](TN-003-standardize-indonesian-self-documentation.md)**

    Menyeragamkan komentar source, petunjuk penggunaan, dan pesan operator
    tanpa mengubah kontrak runtime.

4. **[TN-004 — Normalize Runtime Monitoring Foundation Journal](TN-004-normalize-runtime-monitoring-foundation-journal.md)**

    Mencatat controlled normalization reconstructed records dan memperjelas
    batas evidence antara current source dan local image verification.

5. **[TN-005 — Implement Repository AGENTS.md Governance](TN-005-implement-repository-agents-governance.md)**

    Menerapkan repository-level instructions agar AI mengikuti ownership,
    approval, verification, dan stop conditions sebelum technical
    implementation dilanjutkan.

6. **[TN-006 — Build and Smoke Test Current Tomcat JMX Exporter Source](TN-006-build-and-smoke-test-current-tomcat-jmx-exporter-source.md)**

    Membangun current source JMX Exporter dan memverifikasi HTTPS endpoint serta
    JVM metrics melalui self-cleaning component smoke test.

!!! note "Phase Output"

    Foundation saat ini memiliki current source `231cb91` dan local image
    `localhost/tomcat-jmx-exporter:1.0.0` hasil build source tersebut. HTTPS
    `/metrics`, JMX scrape duration, dan JVM heap metric lulus self-cleaning
    component smoke test pada TN-006.

    Fase belum selesai karena Prometheus, Telegraf, container network,
    production certificate, persistent storage, Ansible, dan end-to-end
    deployment belum diimplementasikan.

## Lessons Learned

- Engineering Journal perlu dimulai sejak kebutuhan dan arah project dibahas,
  bukan setelah source atau topology selesai dibuat.
- JVM metrics, exporter availability, dan application health merupakan signal
  berbeda yang harus diverifikasi secara terpisah.
- Pemisahan generic Tomcat image dari embedded monitoring instrumentation
  membuat masing-masing artifact memiliki lifecycle yang jelas.
- Dokumentasi project lebih mudah dipahami sebagai portfolio ketika hanya
  menampilkan hasil yang telah dikonsolidasikan, sementara detail perjalanan
  tetap tersedia pada Technical Note.

## Related Documentation

- [Tomcat Monitoring Engineering Journal](../index.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [CI/CD](../../ci-cd/index.md)
- [Operations](../../operations/index.md)
- [Tomcat Monitoring Architecture Decision Records](../../../../adr/tomcat-monitoring/index.md)

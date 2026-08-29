# TN-001 — Design Runtime Monitoring Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Reconstructed |
| Project | Tomcat Monitoring |
| Phase | Runtime Monitoring Foundation |
| Activity Date | 2026-08-15 |
| Recorded Date | Unknown; file modified 2026-08-18 |
| Completion Date | 2026-08-18; based on TM-ADR-0001 acceptance |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | Unknown; approval evidenced by communication context |

!!! note "Reconstruction Notice"

    Technical Note ini disusun setelah sebagian discovery, pembahasan desain,
    dan konsolidasi dokumentasi telah berlangsung. `Activity Date`
    mempertahankan tanggal aktivitas pada catatan awal. Tanggal pertama dokumen
    dibuat tidak dapat dibuktikan; filesystem hanya menunjukkan dokumen
    dimodifikasi pada 2026-08-18. Narasi berikut merupakan rekonstruksi dan
    tidak boleh dibaca sebagai pencatatan live.

## 📝 Legacy Structure Mapping

Technical Note ini mempertahankan struktur lama agar konteks historis tidak
ditulis ulang. Hubungannya dengan activity type `Discovery and Assessment`
adalah:

| Legacy Section | Discovery Record Function |
| --- | --- |
| Background dan Why Embedded Monitoring Instrumentation Was Selected | Inputs, findings, alternatives, risks, dan recommendation |
| Execution Decision | Decision Handoff menuju TM-ADR-0001 |
| Architecture | Findings dan recommended design |
| Implementation | Rekonstruksi urutan discovery serta documentation consolidation |
| Verification | Assessment terhadap kelengkapan design contract |
| Next Steps | Open items dan activity handoff |

Assumption, risk, atau open question yang tidak dinyatakan pada catatan awal
tidak ditambahkan sebagai fakta baru selama normalisasi.

## 🎯 Objective

Menetapkan arsitektur awal dan urutan implementasi Tomcat Monitoring berdasarkan
kebutuhan operasional, batasan keamanan, serta target penggunaan project.

## 🌍 Background

Project dimulai dari kebutuhan memperbaiki cara Apache Tomcat disediakan dan
dimonitor. Implementasi yang sudah berjalan belum seluruhnya berbasis container
dan masih bergantung pada external monitoring tools yang menambah biaya serta
beban administrasi. Remote JMX juga membutuhkan port, akun, dan credential yang
harus dikelola untuk setiap instance.

Target project bukan hanya memigrasikan instalasi yang sudah ada. Hasilnya juga
harus dapat digunakan sebagai standar untuk implementasi Tomcat baru. Karena
itu, nama pendekatan yang digunakan adalah **Apache Tomcat Containerization
with Embedded Monitoring Instrumentation**.

### Why Embedded Monitoring Instrumentation Was Selected

Prometheus bukan external monitoring tool pada arsitektur ini. Prometheus,
Telegraf, dan Alertmanager merupakan containerized monitoring stack yang
dikelola sebagai bagian dari project. TrueSight menjadi sistem eksternal yang
menerima event pada implementasi saat ini. Pilihan yang tidak diambil adalah
penggunaan full external observability platform untuk menyediakan kemampuan
yang belum dibutuhkan project.

Pendekatan embedded monitoring instrumentation dipilih berdasarkan kondisi
operasional berikut:

1. Monitoring hanya membutuhkan JVM dan Tomcat runtime metrics, application
   health, dashboard, historical data, serta alerting. Distributed tracing dan
   korelasi end-to-end belum diperlukan karena pengelolaan event tetap
   memanfaatkan TrueSight.
2. Analisis log dilakukan ketika terjadi masalah dan tidak menjadi aktivitas
   harian. Log lokal dengan rentang dua sampai empat minggu dinilai cukup untuk
   kebutuhan investigasi saat ini. Log yang berkaitan dengan incident harus
   dipertahankan apabila investigasi berlangsung melewati masa retensi normal.
3. Host Tomcat masih memiliki kapasitas CPU dan memory yang dapat digunakan
   oleh komponen monitoring ringan. Pemanfaatannya tetap harus diukur agar tidak
   mengganggu application runtime.
4. Full observability platform akan menambah biaya pengadaan, storage,
   administrasi agent, dan pemeliharaan integrasi yang belum sebanding dengan
   cakupan monitoring saat ini.

Keputusan ini membentuk pendekatan monitoring yang proporsional terhadap use
case saat ini. Kebutuhannya harus dievaluasi kembali apabila distributed
tracing, centralized log analytics, retensi jangka panjang, atau korelasi
lintas aplikasi menjadi kebutuhan operasional.

Sebelum source monitoring dibuat, kebutuhan berikut harus diterjemahkan menjadi
arsitektur yang jelas:

- Tomcat dan monitoring instrumentation harus berbasis container;
- Metrics JVM dan Tomcat harus dibaca secara lokal tanpa remote JMX;
- Metrics harus dapat divisualisasikan dalam bentuk current dan historical
  dashboard;
- Kesehatan aplikasi harus diperiksa melalui HTTP, tidak hanya disimpulkan dari
  status JVM atau keberhasilan scrape exporter;
- Alert harus dapat diteruskan ke notification channel yang berbeda;
- Integrasi TrueSight harus didukung tanpa menjadikan project bergantung pada
  TrueSight; serta
- Implementasi harus dapat direproduksi melalui CI/CD dan Ansible.

Technical Note ini mencatat proses pembentukan desain tersebut. Setelah desain
ditinjau, hasil akhirnya dikonsolidasikan ke dokumentasi Architecture sebagai
ringkasan current-state untuk pembaca project.

## 📚 Scope

- Perumusan masalah dan target penggunaan project;
- Identifikasi kebutuhan monitoring dan availability;
- Penentuan component boundary dan communication flow;
- Penentuan security boundary untuk metrics endpoint;
- Pembagian tanggung jawab source repository;
- Identifikasi kebutuhan Development, Infrastructure, dan CI/CD;
- Penetapan urutan implementasi awal; serta
- Konsolidasi hasil desain ke dokumentasi project.

## 📋 Prerequisites

N/A. Technical Note ini berfokus pada perumusan desain dan arsitektur awal,
sehingga tidak ada access, component, atau technical dependency yang harus
disiapkan sebelum aktivitas dilakukan.

## ⚖️ Execution Decision

### TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat

Refer to:

- **[TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md){ target="_blank" rel="noopener" }**

**Decision**

Gunakan JMX Exporter di dalam JVM Tomcat dan local HTTP health check sebagai
instrumentation utama. Prometheus tetap menjadi metrics collector dan
TrueSight tetap menjadi event management integration saat ini, tanpa
mengadopsi full external observability platform.

**Reason**

- Cakupan monitoring belum membutuhkan distributed tracing atau korelasi
  end-to-end.
- Kebutuhan analisis log bersifat insidental dan dapat dilayani oleh log lokal
  dengan retensi yang ditetapkan.
- Resource host yang tersedia dapat dimanfaatkan untuk komponen monitoring
  ringan dengan pengukuran yang sesuai.
- Biaya dan administrasi full observability platform belum sebanding dengan
  kebutuhan operasional saat ini.

## 🏛️ Architecture

### Design Result

| Concern | Design | Reason |
| --- | --- | --- |
| Tomcat runtime | Tomcat dijalankan sebagai container | Menyediakan runtime yang konsisten untuk migrasi dan implementasi baru |
| JVM metrics | JMX Exporter dijalankan sebagai Java Agent di JVM Tomcat | Membaca MBean secara lokal tanpa remote JMX, akun, atau credential per instance |
| Metrics collection | Prometheus melakukan scrape HTTPS ke JMX Exporter | Menyediakan time-series untuk dashboard, historical analysis, dan alert rules |
| Application health | Telegraf melakukan HTTP GET ke `/health` melalui local container network | Membedakan JVM yang hidup dari aplikasi yang hang atau gagal melayani request |
| Metrics security | JMX Exporter menggunakan server-side TLS tanpa client certificate | Melindungi metrics in transit dengan administrasi yang lebih sederhana daripada mTLS |
| Alert management | Prometheus mengirim firing dan resolved alert ke Alertmanager | Memisahkan evaluasi alert dari grouping, deduplication, dan routing |
| External integration | Alertmanager mendukung notification channel generic dan Integration Bridge | Project tetap platform-agnostic; TrueSight menjadi integrasi pada implementasi saat ini |
| Delivery | CI membangun dan memvalidasi artifact; CD dan Ansible melakukan deployment | Memisahkan proses build dari perubahan runtime target |

Hasil desain dipublikasikan sebagai ringkasan pada:

- **[Deployment Topology](../../architecture/index.md#deployment-topology)**
- **[Monitoring Flow](../../architecture/index.md#monitoring-flow)**
- **[Security Controls](../../architecture/index.md#security-controls)**

Dokumentasi Architecture menampilkan hasil desain yang berlaku. Konteks
pembentukan desain dan urutan pekerjaan tetap berada pada Technical Note ini.

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Define the Project Problem

1. Catat kendala implementasi Tomcat non-container dan ketergantungan pada
   external monitoring tools.
2. Identifikasi beban administrasi remote JMX berupa port, akun, dan credential
   per instance.
3. Tetapkan bahwa project harus mendukung migrasi existing runtime sekaligus
   menjadi standar untuk implementasi baru.

!!! success "Expected Result"

    Masalah yang diselesaikan dan target penggunaan project dapat dijelaskan
    sebelum teknologi monitoring dipilih.

**Actual Result:** kebutuhan migrasi, standardisasi Tomcat baru, pengurangan
remote JMX, dan pengendalian biaya monitoring berhasil dirumuskan.

**Evidence:** bagian `Background`, `Scope`, dan TM-ADR-0001 mencatat masalah
serta target project.

</div>

<div class="procedure-step" markdown>

### Define the Monitoring Signals

1. Tetapkan JVM dan Tomcat runtime metrics sebagai sumber informasi performa.
2. Tetapkan current dan historical dashboard sebagai kebutuhan visualisasi.
3. Tetapkan local HTTP `/health` sebagai pemeriksaan kemampuan aplikasi
   melayani request.
4. Tetapkan firing, resolved, dan missing metrics sebagai kondisi yang harus
   dapat dibedakan oleh alerting.

!!! success "Expected Result"

    Metrics, application health, historical visibility, dan alert state
    memiliki tujuan yang berbeda dan tidak saling menggantikan.

**Actual Result:** JVM metrics, application health, historical data, firing,
resolved, dan missing metric ditetapkan sebagai signal yang berbeda.

**Evidence:** monitoring coverage pada Verification table berstatus `Passed`.

</div>

<div class="procedure-step" markdown>

### Design the Component Topology

1. Tempatkan JMX Exporter sebagai Java Agent di dalam JVM Tomcat.
2. Tempatkan Prometheus, Telegraf, dan Alertmanager sebagai container terpisah
   di dalam monitoring stack project.
3. Hubungkan Prometheus ke JMX Exporter melalui HTTPS `/metrics`.
4. Hubungkan Telegraf ke application endpoint melalui local HTTP `/health`.
5. Hubungkan alerting ke notification channel generic dan Integration Bridge
   untuk TrueSight.

!!! success "Expected Result"

    Setiap komponen memiliki peran, interface, dan arah komunikasi yang dapat
    ditampilkan melalui Deployment Topology dan Monitoring Flow.

**Actual Result:** topology menempatkan JMX Exporter, Prometheus, Telegraf,
Alertmanager, dan Integration Bridge pada peran serta jalur komunikasi yang
jelas.

**Evidence:** halaman Architecture memuat Deployment Topology dan Monitoring
Flow yang direview.

</div>

<div class="procedure-step" markdown>

### Define the Security and Repository Boundaries

1. Nonaktifkan remote JMX sebagai bagian dari design contract.
2. Gunakan server-side TLS pada JMX Exporter metrics endpoint.
3. Pisahkan certificate, password, dan secret dari image serta Git repository.
4. Pertahankan repository `tomcat` sebagai generic base image source.
5. Gunakan repository `tomcat-jmx-exporter` untuk derived image dengan embedded
   instrumentation.
6. Gunakan repository `tomcat-monitoring` untuk configuration, integration,
   validation, dan deployment automation.

!!! success "Expected Result"

    Runtime security material dan lifecycle source tidak bercampur, sementara
    generic Tomcat image tetap dapat digunakan oleh project lain.

**Actual Result:** remote JMX dikeluarkan dari desain, server-side TLS diterima,
dan source dibagi antara generic base, derived image, serta integration
repository.

**Evidence:** TM-ADR-0001, Security Controls, dan Development repository
mapping berstatus `Passed` pada Verification table.

</div>

<div class="procedure-step" markdown>

### Establish the Engineering Sequence

Urutan awal ditetapkan berdasarkan dependency implementasi:

```text
Determine initial architecture
        ↓
Prepare development environment and repository boundaries
        ↓
Build and verify the JMX Exporter derived image
        ↓
Prepare Prometheus, Telegraf, network, TLS, and storage
        ↓
Implement CI build and integration validation
        ↓
Implement Ansible provisioning and continuous deployment
        ↓
Verify dashboard, alerting, and external integration
```

!!! success "Expected Result"

    Pekerjaan teknis dapat dijalankan secara bertahap dan setiap hasil memiliki
    dependency serta handoff yang jelas.

**Actual Result:** urutan architecture, environment preparation, component
build, monitoring integration, CI/CD, dan deployment berhasil ditetapkan.

**Evidence:** phase plan dan diagram engineering sequence tersedia pada TN ini.

</div>

<div class="procedure-step" markdown>

### Consolidate the Architecture Summary

1. Publikasikan topology, monitoring flow, component responsibility, dan
   security controls pada halaman Architecture.
2. Publikasikan ringkasan repository model pada Development.
3. Publikasikan kebutuhan runtime pada Infrastructure.
4. Publikasikan target delivery model pada CI/CD.
5. Pertahankan konteks perencanaan dan urutan pekerjaan pada Engineering
   Journal.

!!! success "Expected Result"

    Pembaca portfolio memperoleh ringkasan desain yang jelas, sedangkan tim
    engineering tetap dapat menelusuri bagaimana desain tersebut dibentuk.

**Actual Result:** hasil desain dikonsolidasikan ke Architecture, Development,
Infrastructure, dan CI/CD tanpa memindahkan histori TN.

**Evidence:** seluruh project page tersebut direview pada Verification table.

</div>

</div>

## ✅ Verification

| Item | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Project intent | Review objective dan scope | Migrasi existing dan implementasi baru tercakup | Passed | Objective dan Scope pada Technical Note ini |
| Monitoring coverage | Review signal requirements | JVM metrics, application health, historical data, dan alert state dapat dibedakan | Passed | Background dan Design Result |
| Component topology | Review Deployment Topology dan Monitoring Flow | Seluruh komponen serta arah komunikasi terdokumentasi | Passed | [Architecture](../../architecture/index.md) |
| Security boundary | Review Security Controls | Remote JMX tidak digunakan dan metrics memakai server-side TLS | Passed | [Security Controls](../../architecture/index.md#security-controls) |
| Repository boundary | Review Development summary | Generic base image, derived image, dan integration source terpisah | Passed | [Development](../../development/index.md) |
| Engineering sequence | Review phase plan | Urutan architecture, preparation, implementation, CI/CD, dan deployment tersedia | Passed | Establish the Engineering Sequence pada Technical Note ini |
| Project summary | Review dokumentasi utama | Hasil desain tersedia sebagai ringkasan current-state | Passed | Architecture, Development, Infrastructure, dan CI/CD project pages |
| ADR traceability | Review ADR catalog | Keputusan arsitektur jangka panjang memiliki ADR | Passed | [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md) diterbitkan pada 2026-08-18 |

Initial architecture dan urutan implementasi telah tersedia. Status Technical
Note menjadi `Completed` setelah keputusan utama mengenai embedded monitoring
instrumentation diterbitkan sebagai TM-ADR-0001. Detail seperti production
certificate lifecycle, persistent storage, dan pipeline engine menjadi
pekerjaan fase berikutnya.

## 🎓 Lessons Learned

- Engineering Journal harus dimulai ketika kebutuhan dan arah project mulai
  dibahas, bukan setelah topology selesai dibuat.
- Status exporter dan JVM tidak cukup untuk membuktikan aplikasi dapat melayani
  request; application health memerlukan pemeriksaan HTTP terpisah.
- Embedded instrumentation mengurangi administrasi remote JMX tanpa menjadikan
  project sebagai centralized monitoring platform baru.
- Integrasi TrueSight harus diperlakukan sebagai implementasi saat ini, bukan
  sebagai batas penggunaan project.
- Dokumentasi project menyampaikan hasil desain, sedangkan Engineering Journal
  mempertahankan alasan, urutan, dan perjalanan pembentukannya.

## ⏭️ Next Steps

- Bangun dan verifikasi derived Tomcat image dengan JMX Exporter pada TN-002.
- Publikasikan component source ke Gitea setelah local verification berhasil.
- Terbitkan reusable JMX Exporter Java Agent procedure pada root How-to.
- Lanjutkan persiapan Prometheus, Telegraf, network, TLS, storage, dan CI/CD
  melalui Technical Note berikutnya.

## 🧾 Outcome

Design contract, repository boundary, monitoring signals, security direction,
dan engineering sequence telah tersedia dan dikonsolidasikan ke project
documentation. Keputusan embedded monitoring instrumentation diterima melalui
TM-ADR-0001 pada 2026-08-18.

Technical implementation selain local JMX Exporter image tetap menjadi
outstanding work. Risiko kapasitas resource, production certificate, persistent
storage, Telegraf health check, Prometheus integration, CI/CD, dan end-to-end
deployment belum ditutup oleh Technical Note ini.

## 🔗 Related Documentation

- [Runtime Monitoring Foundation Engineering Journal](index.md)
- [TN-002 — Implement Tomcat JMX Exporter Image](TN-002-implement-tomcat-jmx-exporter-image.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [CI/CD](../../ci-cd/index.md)
- [Root How-to Catalog](../../../../how-to/index.md)
- [TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

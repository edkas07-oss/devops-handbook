# TN-001 — Define Diagnostic MVP Architecture and Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery, Assessment, and Documentation |
| Record Type | Live with resumed execution |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-30 through 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write — documentation only |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-30; resumed and commit requested 2026-08-31 |

## 🎯 Objective

Menyelaraskan hasil inisiasi Diagnostic MVP dengan kondisi aktual repositori serta menetapkan gerbang keputusan (*Decision Gate*) untuk arsitektur pilot `TomcatDown`.

**Target Utama & Kriteria Keberhasilan:**

1. **Baseline Validation:** Memverifikasi ketiadaan komponen diagnostik di repositori dan mendokumentasikan kesenjangan (*gaps*).
2. **Architecture Baseline:** Mengesahkan ADR fondasi (TM-ADR-0013 s.d. TM-ADR-0017) dan kontrak data MVP.
3. **Boundary:** Dokumentasi murni (*read-only discovery*), tanpa perubahan kode atau eksekusi runtime.

## 🌍 Background

Dokumentasi brainstorming awal mencantumkan rencana serah terima sistem diagnostik, namun setelah diperiksa, berkas spesifikasi teknis dan draf Architecture Decision Record (ADR) pendukungnya belum tersedia. Hasil penelusuran repositori juga mengonfirmasi bahwa komponen penting—seperti Diagnostic Service, basis data SQLite, format canonical result, restricted event collector, serta aturan alert `TomcatDown`—belum dibuat.

### Konsep Minimum Viable Product (MVP) pada Diagnostic Service

Penerapan pendekatan **Minimum Viable Product (MVP)** pada inisiatif ini bertujuan untuk membuktikan nilai dan keandalan arsitektur (*Proof of Value*) secara cepat, terukur, dan aman di lingkungan lab sebelum memperluas sistem ke platform yang lebih kompleks.

Secara konseptual, pendekatan MVP di dalam fase ini memegang tiga prinsip utama:

1. **Minimum (Fokus pada Masalah Paling Esensial):** Alih-alih langsung mendiagnosis puluhan skenario kegagalan atau metrik kompleks, fase ini membatasi cakupan hanya pada satu alert ketersediaan paling krusial: `TomcatDown`.
2. **Viable (Berfungsi Utuh dan Handal di Runtime):** Meskipun cakupannya minimum, solusi yang dibangun bukan sekadar rancangan coba-coba (*prototype*). Layanan ini dirancang sebagai sistem mandiri yang memiliki persistensi basis data lokal (SQLite), batasan keamanan isolasi proses (*least-privilege*), format laporan standar, serta integrasi pengiriman notifikasi email yang andal.
3. **Iteratif (Fondasi Bersih untuk Fase Selanjutnya):** MVP menjadi fondasi modular yang stabil. Kapabilitas lanjutan dapat ditambahkan pada fase berikutnya tanpa merusak kontrak antarmuka data yang telah ditetapkan.

### Penetapan Batasan Pilot

Berdasarkan prinsip MVP di atas, Project Owner menetapkan batasan ketat untuk pelaksanaan pilot ini:

- Metrik *application health* diizinkan hanya sebagai bukti pendukung untuk memvalidasi alert `TomcatDown`.
- Aturan diagnostik lanjutan (seperti *High-Heap* dan *Application-Health Rule*), integrasi TrueSight, Integration Bridge, serta tindakan perbaikan otomatis (*auto-remediation*) sengaja ditunda (*deferred*) atau dinonaktifkan.

## 📚 Scope

| Kategori | Batasan Pekerjaan |
| :--- | :--- |
| **Pekerjaan yang Disetujui (*In-Scope*)** | • Penelusuran menyeluruh terhadap repositori dan dokumen eksisting.<br>• Penyusunan dan pembaruan keputusan arsitektur (`TM-ADR-0006` s/d `TM-ADR-0012`, serta diperluas dengan `TM-ADR-0014` s/d `TM-ADR-0017`).<br>• Penyusunan kontrak antarmuka Diagnostic MVP dan konsolidasi status terkini.<br>• Validasi konsistensi dokumen lokal dan pelaksanaan local commit. |
| **Pekerjaan yang Dikecualikan (*Out-of-Scope*)** | • Penulisan *source code* aplikasi dan konfigurasi runtime.<br>• Pembuatan repositori Git baru atau pembangunan *container image*.<br>• Modifikasi container, network, volume, atau deployment runtime.<br>• Pengujian live sistem, integrasi TrueSight, dan skrip remediasi otomatis. |

## 🔍 Findings

Hasil penelusuran awal dikelompokkan ke dalam tiga area temuan:

### 1. Kondisi Repositori & Ketiadaan Dokumen Otoritatif
- Repositori `tomcat`, `tomcat-monitoring`, dan `devops-handbook` berada dalam kondisi bersih (*clean working tree*). Direktori `brainstorming` bukan repositori Git.
- Berkas arsitektur inti belum lengkap: tidak ditemukan dokumen NFR, spesifikasi aturan `TomcatDown`, taksonomi status/confidence, kontrak notifikasi/integrasi, serta draf ADR pendukung.

### 2. Status Pemantauan Runtime Eksisting
- Prometheus berjalan aktif dengan job `tomcat-jmx-exporter` (interval *scrape* 30 detik, timeout 10 detik, target `tomcat-jmx-exporter:9404`).
- Alertmanager mengarahkan seluruh alert bawaan langsung ke Mailpit.
- Tiga aturan pemantauan *application health* sudah tersedia, namun belum ada aturan alert `TomcatDown`, rute webhook diagnostik, database SQLite, maupun collector spool host.

### 3. Tata Kelola Dokumentasi Handbook
- Penomoran ADR Tomcat Monitoring sebelumnya berakhir pada `TM-ADR-0005`.
- Fase jurnal sebelumnya telah ditutup pada `TN-036`, sehingga Diagnostic MVP memerlukan fase baru tersendiri.

## ⚖️ Accepted Decisions

Sepuluh keputusan arsitektur disepakati sebagai landasan implementasi dan diformalkan ke dalam katalog ADR:

| Domain | Keputusan yang Diterima | Referensi ADR |
| :--- | :--- | :---: |
| **Cakupan Alert & Strategi MVP** | Hanya alert `TomcatDown` yang dialirkan ke rute diagnostik otomatis dengan strategi irisan vertikal (*vertical slice*). | [**TM-ADR-0007**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0007.md)<br>[**TM-ADR-0017**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0017.md) |
| **Identitas Target** | Identitas kanonikal target menggunakan format `environment + host + tomcat_instance` (nilai lab awal: `lab + edkas-pc1 + tomcat-jmx-exporter`). | [**TM-ADR-0010**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md) |
| **Aturan Prometheus** | Aturan alert awal ditetapkan: `up{job="tomcat-jmx-exporter"} == 0` dengan durasi evaluasi `for: 2m`. | [**TM-ADR-0007**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0007.md) |
| **Kepemilikan Repositori** | Repositori baru `tomcat-diagnostic-service` mengelola kode aplikasi dan siklus image; repositori `tomcat-monitoring` mengelola integrasi dan konfigurasi deployment. | [**TM-ADR-0010**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md) |
| **Event Collector Spool** | Repositori `tomcat-diagnostic-event-collector` mengelola service host *rootless* untuk menuliskan spool telemetri berkapasitas terbatas (*bounded spool*). | [**TM-ADR-0008**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md) |
| **Keamanan Webhook & Ingestion** | Webhook menggunakan TLS internal ketat, token bearer, dan pola komit persisten ke SQLite sebelum membalas `202 Accepted` (*durable acceptance*). | [**TM-ADR-0015**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md) |
| **Persistensi SQLite** | Database SQLite tertanam berjalan otomatis, tahan restart container, menargetkan ukuran 100 MiB, dan dibatasi batas kapasitas maksimal 250 MiB. | [**TM-ADR-0009**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0009.md) |
| **Otoritas Notifikasi Mailpit** | Diagnostic Service memegang otoritas tunggal pengiriman email insiden `TomcatDown` (firing, update material, status failure, dan pemulihan *resolved*) dari satu *canonical result*. | [**TM-ADR-0016**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md) |
| **Integrasi Eksternal** | Integration Bridge dan TrueSight tetap dalam status nonaktif dan tidak melakukan panggilan jaringan apa pun. | [**TM-ADR-0012**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0012.md) |
| **Tata Kelola Remediasi** | Dilarang melakukan tindakan perbaikan otomatis (*zero automatic remediation*) sebagai keputusan arsitektur tingkat tinggi. | [**TM-ADR-0014**](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0014.md) |

## 🏛️ Documentation Result

Dokumen kontrak arsitektur ditempatkan di direktori `docs/projects/tomcat-monitoring/diagnostic-mvp/`. Keputusan arsitektur resmi dicatat dalam katalog ADR sebagai `TM-ADR-0006` hingga `TM-ADR-0012`, serta dilengkapi dengan `TM-ADR-0014` hingga `TM-ADR-0017` untuk memformalkan tata kelola operasional, integritas penerimaan webhook, otoritas notifikasi, dan strategi MVP. Halaman proyek memisahkan secara tegas antara desain yang disepakati (*accepted design*) dan kondisi yang sudah terverifikasi di runtime (*current state*).

Draf brainstorming yang hilang tidak direkonstruksi secara manual. Dokumen baru disusun berdasarkan *Decision Gate* yang disetujui dan bukti yang masih bertahan.

## ⏳ Open Questions

Pertanyaan terbuka dan kesenjangan teknis dicatat dalam **Gap Register** (`gap-register.md`). Setiap poin memiliki penanggung jawab (*owner*), kriteria penutupan (*closure evidence*), dan *blocking gate* yang jelas. Tidak ada asumsi sepihak yang diizinkan menjadi keputusan implementasi secara diam-diam.

## 💻 Commands Executed

### Initial Read-Only Discovery
```bash
pwd
rg --files -g 'AGENTS.md' -g '!**/.git/**' /home/eddywiyatno/source/brainstorming /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/devops-handbook /home/eddywiyatno/git/tomcat
sed -n '1,300p' AGENTS.md
git status --short --branch
rg --files
git ls-files
find . -maxdepth 3 -type f -not -path './.git/*' -print
rg -n -i 'TomcatDown|ApplicationHealth|Mailpit|Alertmanager|Diagnostic|SQLite|collector|TrueSight|Integration Bridge|up\{|alert:' . -g '!**/.git/**'
```

Dokumen otoritatif dan kondisi terkini dibaca dengan rentang `sed -n` terbatas. Berkas paket yang hilang diperiksa dengan perulangan `test -e`, dan berkas terkait dicari menggunakan `find` dan `rg`.

### Resumed Documentation Activity
```bash
git status --short --branch
git diff --stat
find docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot -maxdepth 2 -type f -print
mkdir -p docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot
git diff --check
python3 -c '<read-only Markdown local-link checker>'
```

Perubahan dokumentasi manual diterapkan melalui antarmuka patch repositori. Perintah validasi dan hasil aktual dicatat pada bagian Verification setelah dieksekusi.

## ✅ Verification

| Metode Verifikasi | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :---: |
| **`git diff --check`** | Tidak ada spasi berlebih (*whitespace errors*) pada kedua repositori. | Bersih tanpa error pada `devops-handbook` dan `tomcat-monitoring`. | **Passed** |
| **Link Integrity Checker** | Seluruh relative cross-link antar-dokumen valid. | 21 berkas Markdown diperiksa; `broken_links=0`. | **Passed** |
| **Scope Review** | Modifikasi hanya terjadi pada dokumen handbook yang disetujui. | Hanya berkas dokumentasi handbook dan `tomcat-monitoring/README.md` yang berubah. | **Passed** |
| **MkDocs Render** | Kompilasi situs handbook bebas dari error rendering. | MkDocs belum tersedia di `PATH` pada verifikasi awal. | **Not verified** |

Tidak ada klaim verifikasi source, konfigurasi, image, container, volume, network, maupun runtime.

## 🧭 Reproduction Reference

Bagian ini ditambahkan untuk memastikan ketertelusuran (*reproducibility*). Dokumen arsitektur dan kontrak yang disahkan pada Technical Note ini tersimpan secara permanen pada commit handbook **`c924459`**:

```bash
git show --stat c924459
git diff c924459^ c924459 -- docs/adr/tomcat-monitoring docs/projects/tomcat-monitoring
```

Gunakan ADR yang diterima dan halaman `diagnostic-mvp/` dari revisi tersebut untuk mereview keputusan yang berlaku saat TN-001 selesai. Perintah ini adalah instruksi reproduksi; perintah tidak dijalankan ulang dalam koreksi dokumentasi.

## 🧾 Outcome

Gerbang arsitektur berbasis dokumentasi (*Architecture Gate*) berhasil diselesaikan. Status Diagnostic MVP pada akhir Technical Note ini tetap berstatus **belum diimplementasikan dan belum diverifikasi di runtime**. Diperlukan perencanaan implementasi dan persetujuan terpisah sebelum pekerjaan source code, repositori, image, atau runtime dimulai.

## 🔗 Related Documentation

- [Diagnostic MVP Index](../../diagnostic-mvp/index.md)
- [Requirements Traceability](../../diagnostic-mvp/requirements-traceability.md)
- [Gap Register](../../diagnostic-mvp/gap-register.md)
- [Tomcat Monitoring ADR Catalog](../../../../adr/tomcat-monitoring/index.md)
- [TM-ADR-0014: Enforce Zero Automatic Remediation](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0014.md)
- [TM-ADR-0015: Asynchronous Webhook Ingestion with Durable SQLite Acceptance](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0015.md)
- [TM-ADR-0016: Diagnostic Service as Canonical Incident Notification Authority](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0017: Vertical Slice Minimum Viable Product (MVP) Scoping](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0017.md)

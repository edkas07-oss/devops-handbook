# TN-017 — Define JMX Exporter Configuration and Lab TLS Integration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-25 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Menetapkan configuration, validation, TLS, runtime target, isolation, dan
cleanup contract minimum untuk memverifikasi Prometheus scrape terhadap current
JMX Exporter image pada local lab.

## 🌍 Background

TN-008 membuktikan current source `tomcat-jmx-exporter` dapat menghasilkan
image lokal yang menyajikan HTTPS metrics dan JVM heap metric. TN-009 menyimpan
documentation evidence tersebut. Prometheus scrape configuration sudah
menargetkan `https://tomcat-jmx-exporter:9404/metrics`, tetapi integration
repository belum memiliki executable JMX Exporter configuration atau static
validator.

Runtime integration juga belum memiliki lab certificate dengan SAN
`tomcat-jmx-exporter`, trust material yang cocok, exact temporary resource
names, dan cleanup plan. Project owner menyetujui TN-017 sebagai documentation
dan decision gate tanpa perubahan source configuration maupun runtime, serta
meminta pekerjaan tetap mengikuti standar dan mengutamakan efisiensi serta
efektivitas penggunaan Codex.

## 📚 Scope

- Tentukan minimum JMX Exporter metric rules untuk membuktikan scrape path.
- Tentukan source file dan static validation interface.
- Tentukan lab TLS identity, secret boundary, dan trust relationship.
- Tentukan exact runtime alias, network, temporary resource model, dan cleanup
  boundary.
- Pisahkan implementation activity dari runtime verification activity.
- Pertahankan full operational metric coverage dan production certificate
  lifecycle sebagai follow-up terpisah.

Pembuatan configuration, validator, certificate, container, volume, image,
Prometheus reload, scrape test, cleanup runtime, commit, dan push tidak termasuk
scope.

## 📥 Inputs

| Source | Relevant contract |
| --- | --- |
| JMX Exporter example | Menunjukkan server-side TLS dengan PKCS12, password environment reference, certificate alias, JVM heap rule, dan Tomcat server-info rule. |
| Prometheus configuration | Target `tomcat-jmx-exporter:9404`, HTTPS `/metrics`, CA path, dan certificate verification sudah ditetapkan. |
| Architecture | Remote JMX dilarang; Prometheus memverifikasi server certificate; secret dipasang read-only dan tidak disimpan di Git atau image. |
| Operations | Full target coverage mencakup memory, GC, threads, class loading, connector, requests, errors, throughput, dan sessions. |
| Validation pattern | Component validator melakukan exact structural checks tanpa dependency baru dan tidak menggantikan semantic atau runtime test. |
| Runtime contract | JMX Exporter image menerima config, PKCS12 keystore, dan password file dari luar container pada network `devops-lab`. |

## 🔍 Findings

1. Dua rules pada example cukup untuk integration proof karena membuktikan satu
   JVM value dan satu Tomcat MBean mapping, tetapi tidak memenuhi seluruh
   operational coverage.
2. Mengimplementasikan seluruh metric catalog sebelum scrape path terbukti
   akan memperbesar scope dan memperlambat feedback tanpa meningkatkan bukti
   connectivity atau TLS.
3. Certificate untuk integration test harus valid terhadap DNS alias
   `tomcat-jmx-exporter`; CN saja tidak cukup menjadi contract.
4. Mengubah truststore dan lifecycle persistent lab Prometheus untuk component
   integration test menambah rollback risk yang tidak diperlukan.
5. Temporary Prometheus dengan TN-scoped named volumes dapat menggunakan
   configuration yang sama tanpa mengubah container, volumes, atau data
   persistent lab.
6. Telegraf scrape tidak memiliki prerequisite yang sama karena application
   health endpoint nyata belum tersedia; menggabungkannya akan membuat closure
   TN bergantung pada concern lain.

## 💡 Alternatives

| Alternative | State | Assessment |
| --- | --- | --- |
| Implement full JVM dan Tomcat operational metric catalog sekarang | Rejected | Scope besar dan rule correctness belum dapat dibedakan dari scrape connectivity. |
| Gunakan dua minimum rules dari verified example untuk integration proof | Selected | Reuse contract yang sudah lulus component test dan memberikan feedback tercepat. |
| Ubah truststore persistent Prometheus lalu jalankan target sementara | Rejected | Menambah mutation dan restoration terhadap lab state yang sudah diverifikasi. |
| Gunakan temporary Prometheus dan TN-scoped volumes pada `devops-lab` | Selected | Mengisolasi test dan memungkinkan cleanup exact tanpa memengaruhi historical data. |
| Gabungkan JMX Exporter dan Telegraf scrape dalam satu TN | Rejected | Telegraf masih bergantung pada application health endpoint yang belum tersedia. |

## ⚠️ Risks

| Risk | State | Mitigation or follow-up |
| --- | --- | --- |
| Minimum rules dianggap sebagai final monitoring coverage | Open | Dokumentasikan explicit boundary dan buat follow-up metric catalog activity setelah integration path terbukti. |
| Certificate tidak valid untuk network alias | Mitigated by recommendation | Wajibkan SAN `DNS:tomcat-jmx-exporter` dan verifikasi hostname tetap aktif. |
| Secret masuk Git atau command output | Mitigated by recommendation | Generate material di TN-scoped temporary directory, gunakan password file mode `0600`, dan jangan mencetak nilainya. |
| Temporary resource tertinggal | Mitigated by recommendation | Gunakan exact TN-scoped names dan verifikasi cleanup container, volumes, serta directory. |
| Temporary test mengubah persistent Prometheus state | Mitigated by recommendation | Gunakan container dan volumes terpisah; existing `prometheus` serta `prometheus_*` volumes hanya diinspeksi read-only. |

## ❓ Open Questions

| Question | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Apakah minimum two-rule configuration diterima sebagai integration proof, bukan final coverage? | Answered | Project owner | Recommendation A diterima pada 2026-08-25. | Tidak ada untuk planning TN-018; implementation tetap memerlukan authorization. |
| Apakah lab certificate boleh self-signed dan hanya berlaku untuk temporary integration test? | Answered | Project owner | Recommendation B diterima pada 2026-08-25. | Tidak ada untuk planning TN-020; runtime mutation tetap memerlukan authorization. |
| Apakah persistent Prometheus harus tetap tidak berubah selama integration test? | Answered | Project owner | Recommendation C diterima pada 2026-08-25. | Tidak ada untuk planning TN-020; runtime mutation tetap memerlukan authorization. |
| Kapan full operational metric catalog dibuat? | Deferred | Project owner | JMX scrape path lulus dan metric-catalog scope disetujui. | Dashboard dan alert coverage; tidak memblokir integration proof. |
| Bagaimana production certificate lifecycle? | Deferred | Infrastructure atau PKI owner | Issuance, distribution, renewal, revocation, dan secret injection contract disetujui. | Production deployment; tidak memblokir isolated lab test. |

## 💡 Recommendation

### Recommendation A — Minimum source configuration

- Tambahkan `config/jmx-exporter/jmx-exporter.yml` pada TN-018.
- Gunakan TLS structure dan dua rules yang sudah diverifikasi pada example:
  `jvm_memory_heap_used_bytes` serta `tomcat_server_info`.
- Nyatakan bahwa rules tersebut hanya integration baseline, bukan final
  operational coverage.
- Tambahkan `scripts/validate-jmx-exporter.sh` dan wiring ke
  `scripts/validate.sh` tanpa parser atau dependency baru.
- Static validator memeriksa PKCS12 path, password environment reference,
  certificate alias, dua rule names, larangan inline password, dan tepat dua
  baseline rules.

### Recommendation B — Lab TLS boundary

- TN-020 membuat self-signed lab certificate dengan SAN
  `DNS:tomcat-jmx-exporter` di directory
  `/tmp/tomcat-monitoring-tn020-tls.XXXXXX`.
- Certificate, private key, PKCS12 keystore, dan password file tidak masuk Git,
  image, journal output, atau persistent project storage.
- Password file menggunakan mode `0600`; keystore dan certificate dipasang
  read-only.
- Certificate public digunakan sebagai CA trust file temporary Prometheus;
  hostname verification tetap aktif.

### Recommendation C — Isolated runtime topology

- Gunakan network existing `devops-lab` tanpa mengubahnya.
- JMX target menggunakan container name dan DNS alias
  `tomcat-jmx-exporter` agar cocok dengan scrape target serta certificate SAN.
- Gunakan temporary Prometheus container `prometheus-tn020` dengan volumes
  `prometheus_tn020_config`, `prometheus_tn020_truststore`, dan
  `prometheus_tn020_data`.
- Existing container `prometheus` dan volumes `prometheus_config`,
  `prometheus_truststore`, serta `prometheus_data` tidak diubah.
- Tidak perlu memublikasikan port Prometheus atau JMX Exporter ke host untuk
  membuktikan container-network scrape; evidence diambil melalui container
  inspection dan Prometheus API dari namespace test yang disetujui.

### Recommendation D — Verification and cleanup

- Expected success: target JMX berstatus `up=1`, TLS hostname verification
  aktif, dan dua baseline metrics tersedia dari Prometheus query/API.
- Failure behavior: certificate yang tidak dipercaya atau alias yang tidak
  cocok menghasilkan target down tanpa menonaktifkan TLS verification.
- Cleanup exact targets setelah evidence: `tomcat-jmx-exporter`,
  `prometheus-tn020`, tiga `prometheus_tn020_*` volumes, dan TN-scoped TLS
  directory.
- Image, existing network, persistent Prometheus container/volumes, dan
  `.artifacts` tidak termasuk cleanup.

### Recommendation E — Activity split

1. TN-018 mengimplementasikan configuration dan validator source-only.
2. TN-020 membuat temporary TLS/runtime resources, memverifikasi successful
   dan failed TLS scrape behavior, lalu membersihkan exact targets.
3. Follow-up terpisah memperluas metric catalog setelah integration path
   terbukti.

## 🧭 Decision Handoff

Project owner menerima Recommendation A sampai E pada 2026-08-25. Keputusan
tersebut menutup TN-017 dan menjadi planning baseline untuk TN-018 serta TN-020.
Acceptance tidak mengizinkan source change, certificate generation, runtime
mutation, cleanup, commit, atau push secara otomatis.

## ⚙️ Commands Executed

### Targeted discovery

```bash
git status --short --branch
sed -n '1,220p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-009-commit-current-jmx-exporter-verification-documentation.md
sed -n '1,180p' config/jmx-exporter/README.md
sed -n '1,180p' config/prometheus/prometheus.yml
sed -n '1,260p' config/telegraf/health-check.conf
sed -n '1,320p' scripts/run.sh
sed -n '1,280p' scripts/run.sh
sed -n '100,145p;245,285p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-define-prometheus-scrape-configuration-contract.md
sed -n '1,260p' examples/jmx-exporter.yml
rg -n 'JMX Exporter|JVM|Tomcat|heap|thread|session|9404|TLS|certificate|metric rules' docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/operations/index.md
sed -n '1,260p' scripts/validate-telegraf.sh
sed -n '1,260p' scripts/validate-prometheus.sh
sed -n '1,180p' config/README.md
sed -n '1,240p' docs/projects/tomcat-monitoring/architecture/index.md
sed -n '1,130p' docs/projects/tomcat-monitoring/operations/index.md
```

Discovery dibatasi pada sources yang langsung menentukan configuration,
validation, TLS, runtime isolation, dan metric coverage. Tidak ada runtime
inspection atau perubahan source dilakukan.

### Documentation validation

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-define-jmx-exporter-configuration-and-lab-tls-integration-contract.md
rg -n '^\| Status \| In Progress \|$|Recommendation [A-E]|TN-017' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-define-jmx-exporter-configuration-and-lab-tls-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-016-reconcile-and-commit-prometheus-scrape-and-lab-runtime-changes.md
test -f docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-008-build-and-smoke-test-current-tomcat-jmx-exporter-source.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
command -v mkdocs
git status --short --branch
```

Diff check lulus, trailing-whitespace scan tidak menemukan match, TN-017
terdaftar setelah TN-016, seluruh related-documentation target tersedia, dan
lima recommendations ditemukan. MkDocs render berstatus `Not verified` karena
executable tidak tersedia dan dependency tidak dipasang.

### Decision closure validation

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-define-jmx-exporter-configuration-and-lab-tls-integration-contract.md
rg -n '^\| Status \| Completed \|$|Recommendation A sampai E pada 2026-08-25|\| Answered \|' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-define-jmx-exporter-configuration-and-lab-tls-integration-contract.md
git status --short --branch
```

Closure validation membuktikan status `Completed`, tiga decision questions
`Answered`, accepted recommendation record, serta diff dan trailing whitespace
yang bersih.

## 🧾 Outcome

Assessment dan Decision Gate selesai. Project owner menerima Recommendation A
sampai E pada 2026-08-25. TN-018 memiliki planning baseline untuk minimum
source configuration serta static validator; TN-020 memiliki baseline untuk
isolated TLS/runtime verification dan exact cleanup.

Tidak ada source configuration, certificate, container, volume, network,
persistent Prometheus state, commit, atau remote state yang diubah.

## ⏭️ Next Steps

TN-018 dapat dimulai hanya setelah source implementation scope dan verification
criteria mendapatkan authorization eksplisit. TN-020 tetap memiliki
authorization gate terpisah setelah TN-018 selesai.

## 🔗 Related Documentation

- [TN-016 — Reconcile and Commit Prometheus Scrape and Lab Runtime Changes](TN-016-reconcile-and-commit-prometheus-scrape-and-lab-runtime-changes.md)
- [Runtime Monitoring Foundation TN-008](../runtime-monitoring-foundation/TN-008-build-and-smoke-test-current-tomcat-jmx-exporter-source.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Operations](../../operations/index.md)

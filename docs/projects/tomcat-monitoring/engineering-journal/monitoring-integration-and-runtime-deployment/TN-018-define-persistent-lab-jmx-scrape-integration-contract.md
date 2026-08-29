# TN-018 — Define Persistent Lab JMX Scrape Integration Contract

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

Menetapkan contract yang dapat disetujui untuk mengintegrasikan JMX Exporter
ke persistent lab Prometheus tanpa kehilangan data, melemahkan TLS
verification, atau mengubah runtime sebelum target dan rollback jelas.

## 🌍 Background

TN-016 membuktikan successful scrape, strict untrusted-CA failure, dan recovery
pada isolated topology. TN-017 kemudian menerima `tomcat_server` sebagai
canonical runtime metric name. Kedua aktivitas tersebut sengaja tidak mengubah
container `prometheus` maupun volumes persistent.

Project owner menyetujui TN-018 sebagai documentation-only decision gate pada
2026-08-25. Approval mencakup discovery terarah, pencatatan recommendation dan
open questions, serta validasi dokumentasi. Approval tidak mencakup source
atau configuration change, certificate generation, container atau volume
mutation, build, test runtime, cleanup, commit, maupun push.

Controlled journal migration yang sedang tersedia pada working tree Handbook
dipertahankan sebagai baseline pengguna. TN-018 tidak menulis ulang perubahan
renumbering atau evidence historis tersebut.

## 📚 Scope

- Review persistent Prometheus, JMX Exporter runtime, network, storage, TLS,
  ownership, continuity, rollback, dan verification boundary dari source serta
  evidence yang tersedia.
- Bedakan fact, keputusan yang sudah accepted, keputusan yang masih open, dan
  pekerjaan yang belum diverifikasi.
- Rekomendasikan contract minimum untuk persistent lab integration.
- Catat owner, closure condition, dan blocked activity untuk setiap open
  question.
- Daftarkan TN-018 pada phase navigation dan jalankan documentation checks.

Source, configuration, image, certificate, private key, password, container,
volume, network, port, runtime, cleanup, commit, push, publication, serta
deployment tidak termasuk scope.

## 📥 Inputs

- TN-013 sebagai evidence existing persistent Prometheus dan named-volume
  contract.
- TN-016 serta TN-017 sebagai evidence isolated TLS scrape dan canonical
  metric-name contract.
- Source repository `tomcat-monitoring`, `prometheus`, dan
  `tomcat-jmx-exporter` sebagai implementation contract aktual.
- TM-ADR-0001 serta current-state Architecture dan Infrastructure sebagai
  architecture dan ownership boundary.

## 🔍 Findings

### Verified facts

| Fact | State | Evidence |
| --- | --- | --- |
| Persistent collector | Verified | TN-013 mempertahankan container `prometheus` pada network `devops-lab`, host port `9090`, serta volumes `prometheus_config`, `prometheus_truststore`, dan `prometheus_data`. |
| Data boundary | Verified | `prometheus_data` dipasang read-write; configuration dan truststore dipasang read-only pada Prometheus. Initializer mempertahankan data volume. |
| Scrape contract | Verified at source level | Configuration menunjuk `https://tomcat-jmx-exporter:9404/metrics`, menggunakan CA file, dan mempertahankan `insecure_skip_verify: false`. |
| TLS behavior | Verified only in isolation | TN-016 membuktikan trusted-CA success, untrusted-CA failure, dan recovery tanpa mengubah persistent Prometheus. |
| Monitored runtime artifact | Verified at source level | `localhost/tomcat-jmx-exporter:1.0.0` merupakan derived Tomcat image dengan embedded JMX Exporter dan runtime-mounted configuration, keystore, serta password file. |
| Runtime replacement guard | Verified at source level | Generic Prometheus dan JMX Exporter launchers menolak membuat container jika instance name sudah tersedia; penggantian memerlukan tindakan lifecycle eksplisit. |

### Unverified work

- Belum ada persistent Tomcat/JMX Exporter target yang disetujui dan
  diverifikasi pada `devops-lab`.
- Persistent `prometheus_truststore` belum dibuktikan memuat CA actual untuk
  target persistent.
- Persistent Prometheus belum dibuktikan membaca current configuration dan
  mengambil `jvm_memory_heap_used_bytes` serta `tomcat_server` dari target
  persistent.
- Continuity impact, rollback, certificate lifecycle, dan cleanup boundary
  persistent integration belum diterima.

## 🛠️ Alternatives

| Alternative | State | Assessment |
| --- | --- | --- |
| A. Ubah existing persistent Prometheus secara langsung | Assessed | Mempertahankan dashboard dan data volume, tetapi memerlukan exact update/reload atau replacement sequence serta rollback sebelum aman dijalankan. |
| B. Validasi ulang menggunakan isolated Prometheus | Rejected for TN-018 objective | Jalur ini sudah dibuktikan TN-016 dan tidak menjawab persistent integration. |
| C. Buat persistent Prometheus kedua | Assessed | Mengurangi risiko terhadap instance existing, tetapi menggandakan storage, port, ownership, dan lifecycle tanpa kebutuhan yang diterima. |
| D. Tunda Prometheus mutation sampai persistent Tomcat/JMX target dan certificate lifecycle siap | Selected as recommendation | Menghindari partial deployment dan memungkinkan preflight serta rollback ditentukan terhadap exact target. |

## ⚠️ Risks

| Risk | State | Mitigation or closure |
| --- | --- | --- |
| Historical metrics atau dashboard terganggu saat Prometheus diganti | Open | Tetapkan downtime window, preserve `prometheus_data`, exact replacement sequence, readiness check, dan rollback command sebelum implementation. |
| CA atau keystore tidak memiliki lifecycle yang aman | Open | Tetapkan issuer/source, owner, storage di luar Git, permission, renewal, revocation, dan rollback material. |
| Host-published metrics memperluas attack surface | Mitigated | Accepted contract menggunakan container-network scrape tanpa host publication untuk port `9404`. |
| Resource name mengikuti nomor TN | Mitigated in recommendation | Gunakan nama berbasis fungsi dan target; jangan gunakan nomor TN untuk resource baru. |
| Telegraf target tetap down pada shared configuration | Accepted for JMX-only verification | Pisahkan expected exception JMX-only dari follow-up Telegraf integration. |

## ❓ Open Questions

| Question | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Apakah persistent monitored target menggunakan container `tomcat-jmx-exporter` dari derived image current source pada network `devops-lab`? | Answered | Project owner dan `tomcat-jmx-exporter` runtime owner | Accepted on 2026-08-25: gunakan generic derived Tomcat target bernama dan beralias `tomcat-jmx-exporter` pada `devops-lab`, tanpa application-specific WAR dan tanpa host publication port `9404`. | Tidak ada pada decision level; runtime creation tetap memerlukan implementation authorization. |
| Dari mana certificate, keystore, password file, dan CA trust diperoleh untuk persistent lab? | Deferred | Project owner dan infrastructure owner | Self-signed lab certificate telah dipilih pada 2026-08-25; sebelum implementation, lokasi non-Git, owner, permission, validity, renewal, revocation, dan cleanup/rollback masih harus ditetapkan. | JMX runtime startup dan persistent truststore update. |
| Bagaimana existing Prometheus menerima configuration dan CA baru? | Answered at contract level | Project owner dan `tomcat-monitoring` source owner | Accepted on 2026-08-25: gunakan exact existing container dan volumes, pertahankan `prometheus_data`, serta wajibkan implementation plan terpisah untuk sequence, downtime, readiness, dan rollback. | Runtime mutation tetap memerlukan approved implementation plan. |
| Apakah JMX-only verification boleh menerima target Telegraf tetap down? | Answered | Project owner | Accepted on 2026-08-25 sebagai explicit JMX-only exception. | Tidak ada untuk JMX-only verification; Telegraf integration tetap follow-up terpisah. |

### Certificate source resolution

Project owner memilih self-signed certificate untuk persistent lab pada
2026-08-25. Certificate wajib memiliki SAN `DNS:tomcat-jmx-exporter` agar
sesuai dengan internal scrape target dan hostname verification tetap aktif.
Keputusan ini tidak mengizinkan certificate generation dan tidak menetapkan
lokasi secret, validity, renewal, revocation, atau rollback material.

## 💡 Recommendation

1. Pertahankan existing `prometheus`, `prometheus_config`,
   `prometheus_truststore`, dan `prometheus_data` sebagai exact persistent lab
   targets; jangan membuat collector persistent kedua.
2. Sediakan lebih dahulu persistent Tomcat container dari derived image
   `localhost/tomcat-jmx-exporter:1.0.0` dengan network alias
   `tomcat-jmx-exporter` pada `devops-lab` dan tanpa host publication port
   `9404`.
3. Gunakan certificate identity yang SAN-nya cocok dengan
   `tomcat-jmx-exporter`; simpan keystore, password, dan CA di luar Git serta
   image. Implementation tidak dimulai sampai owner dan lifecycle material
   tersebut diterima.
4. Pertahankan `prometheus_data`; batasi mutation pada configuration,
   truststore, dan exact container lifecycle. Tentukan backup atau rollback
   material sebelum replacement.
5. Gunakan nama resource berdasarkan fungsi, bukan nomor TN, untuk resource
   baru atau temporary verification.
6. Verifikasi minimum implementation berikutnya harus membuktikan Prometheus
   ready, dashboard tetap dapat diakses, target JMX `up=1`, strict TLS tetap
   aktif, metrics `jvm_memory_heap_used_bytes` dan `tomcat_server` tersedia,
   data volume tetap terpasang, serta rollback atau cleanup exact target
   selesai bila terjadi kegagalan.

## 🧭 Decision Handoff

Project owner menerima Recommendation TN-018 pada 2026-08-25. Acceptance
menetapkan existing Prometheus dan volumes sebagai persistent collector,
generic derived Tomcat/JMX container pada `devops-lab` sebagai target, internal
port `9404` tanpa host publication, data-volume preservation, functional
resource naming, serta Telegraf-down sebagai explicit JMX-only exception.

Self-signed lab certificate telah diterima sebagai source dan harus memiliki
SAN `DNS:tomcat-jmx-exporter`. Lifecycle detail tetap `Deferred`; lokasi
non-Git, owner, permission, validity, renewal, revocation, dan rollback
material belum ditetapkan. Deferral tersebut tidak menghalangi closure
discovery dan decision contract TN-018, tetapi memblokir certificate
generation, JMX runtime startup, persistent truststore update, dan
implementation authorization. Exact Prometheus mutation, downtime, readiness,
serta rollback commands harus disiapkan pada implementation plan berikutnya
dan mendapatkan authorization terpisah. Accepted direction menerapkan
TM-ADR-0001. Certificate lifecycle yang masih deferred pada TN-018 kemudian
ditetapkan oleh TN-019 dan dicatat pada
[TM-ADR-0003](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0003.md).

## ⚙️ Commands Executed

### Standards and readiness review

```bash
wc -l docs/standards/documentation-standards.md
sed -n '1,1200p' docs/standards/documentation-standards.md
wc -l docs/standards/engineering-journal-standards.md
sed -n '1,1200p' docs/standards/engineering-journal-standards.md
wc -l docs/standards/writing-standards.md
sed -n '1,1200p' docs/standards/writing-standards.md
sed -n '121,280p' docs/standards/documentation-standards.md
sed -n '1,350p' docs/standards/engineering-journal-standards.md
sed -n '351,700p' docs/standards/engineering-journal-standards.md
sed -n '701,1000p' docs/standards/engineering-journal-standards.md
sed -n '1,320p' docs/standards/writing-standards.md
sed -n '250,500p' docs/standards/engineering-journal-standards.md
sed -n '501,700p' docs/standards/engineering-journal-standards.md
sed -n '150,280p' docs/standards/writing-standards.md
tail -n 40 docs/standards/writing-standards.md
tail -n 40 docs/standards/documentation-standards.md
git status --short --branch
git log -1 --oneline --decorate
```

Standar yang berlaku telah dibaca. Handbook memiliki controlled journal
migration yang beririsan dan dipertahankan sebagai baseline pengguna.

### Persistent integration discovery

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/tomcat-monitoring log -1 --oneline --decorate
sed -n '1,340p' scripts/run.sh
sed -n '1,240p' config/prometheus/README.md
sed -n '1,220p' config/prometheus/prometheus.yml
sed -n '1,460p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
rg --files docs/adr/tomcat-monitoring | sort
rg -n 'Prometheus|persistent|certificate|TLS|JMX|volume|network' docs/adr/tomcat-monitoring
rg --files | sort
rg -n 'prometheus_config|prometheus_truststore|prometheus_data|initialize-prometheus|run.sh|9404|jmx-exporter-ca' . --glob '!README.md'
sed -n '1,360p' scripts/run.sh
sed -n '1,280p' README.md
sed -n '1,260p' scripts/initialize-prometheus-volumes.sh
sed -n '1,260p' README.md
sed -n '1,240p' config/prometheus/README.md
sed -n '1,220p' config/prometheus/prometheus.yml
sed -n '1,340p' scripts/initialize-prometheus-volumes.sh
sed -n '1,240p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
sed -n '1,300p' AGENTS.md
rg --files | sort
sed -n '1,300p' README.md
sed -n '1,260p' scripts/run.sh
sed -n '1,240p' Containerfile
rg -n 'persistent|deployment|run.sh|tomcat-jmx-exporter|keystore|certificate|9404|devops-lab' docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/architecture/index.md
```

Command pertama `sed -n '1,340p' scripts/run.sh` pada repository
`tomcat-monitoring` gagal karena file tersebut tidak tersedia. Command
`sed -n '1,260p' scripts/initialize-prometheus-volumes.sh` pada repository
`prometheus` juga gagal karena initializer dimiliki integration repository.
Discovery kemudian diarahkan ke owner repository yang benar. Tidak ada runtime
atau external state yang diinspeksi maupun diubah.

### Documentation review

```bash
git diff --check
git diff --no-index --check /dev/null docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-017-reconcile-tomcat-server-metric-name-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'TN-017|TN-018|Status \| In Progress|Open Questions|Decision Handoff|prometheus_config|tomcat-jmx-exporter' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
command -v mkdocs
git status --short --branch
```

Diff dan trailing-whitespace checks lulus. TN-018 terdaftar setelah TN-017 dan
seluruh related-documentation targets tersedia. MkDocs render berstatus
`Not verified` karena executable tidak tersedia dan dependency tidak dipasang.

### Decision acceptance

```bash
git status --short --branch
sed -n '108,175p;245,285p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
```

Project owner menerima Recommendation pada 2026-08-25. Review memastikan
acceptance dapat dicatat tanpa mengubah controlled journal migration atau
runtime state; certificate lifecycle detail tetap tidak tersedia dan
dipertahankan sebagai prerequisite `Deferred`.

### Certificate source decision

```bash
git status --short --branch
sed -n '112,165p;255,285p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
```

Project owner memilih self-signed certificate untuk persistent lab pada
2026-08-25. Keputusan dicatat sebagai partial resolution; tidak ada certificate
atau secret material yang dibuat maupun dibaca.

## 🧾 Outcome

TN-018 selesai sebagai discovery dan decision contract. Existing persistent
Prometheus, generic Tomcat/JMX target, internal metrics exposure, data
preservation, functional resource naming, JMX-only Telegraf exception, dan
self-signed lab certificate source telah diterima. Certificate lifecycle tetap
prerequisite `Deferred`; exact Prometheus mutation dan rollback sequence tetap
wajib disetujui pada implementation plan berikutnya. Tidak ada current-state
documentation yang diubah karena belum ada runtime state baru. Documentation
checks lulus kecuali MkDocs render tidak tersedia.

Tidak ada source, configuration, certificate, secret, container, volume,
network, port, image, runtime, atau external state yang diubah.

## ⏭️ Next Steps

Tetapkan lokasi non-Git, owner, permission, validity, renewal, revocation, dan
rollback material untuk self-signed lab certificate. Setelah prerequisite
tersebut ditutup, ajukan implementation plan terpisah dengan exact target,
mutation sequence, downtime, rollback, verification, dan cleanup boundary.

## 🔗 Related Documentation

- [TN-017 — Reconcile Tomcat Server Metric Name Contract](TN-017-reconcile-tomcat-server-metric-name-contract.md)
- [TN-016 — Verify Isolated JMX Exporter TLS Scrape Integration](TN-016-verify-isolated-jmx-exporter-tls-scrape-integration.md)
- [TN-013 — Verify Prometheus Named-Volume Runtime and Lab Access](TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [TM-ADR-0003 — Use Host-Managed Non-Git TLS Material for the Persistent Lab](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0003.md)

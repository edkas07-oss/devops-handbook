# TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-26 |
| Recorded Date | 2026-08-26 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-26 |

## 🎯 Objective

Menetapkan ownership runtime Alertmanager dan contract notification integration
yang dapat menjadi dasar implementation planning tanpa membuat source,
configuration, runtime, receiver eksternal, atau secret.

## 🌍 Background

TN-024 menyelesaikan tiga application-health alert rules dan membuktikan
firing serta resolved behavior pada persistent Prometheus. Alertmanager,
notification routing, Integration Bridge, dan TrueSight masih belum
diimplementasikan, sehingga alert hanya terlihat melalui Prometheus API.

TM-ADR-0001 telah menerima Alertmanager sebagai bagian containerized monitoring
stack dan Integration Bridge sebagai external-integration boundary. Keputusan
tersebut belum menetapkan lifecycle image, repository runtime, interface
Prometheus, routing baseline, secret injection, atau verification boundary.

Project owner menyetujui TN-025 dan perubahan Engineering Journal serta
current-state documentation pada 2026-08-26. Authorization tidak mencakup
pembuatan repository runtime, perubahan source `tomcat-monitoring`, download,
image pull atau build, test component, container, volume, receiver aktual,
credential, cleanup, commit, maupun push.

## 📚 Scope

Aktivitas ini mencakup:

- Menyelesaikan Runtime Component Ownership Gate untuk Alertmanager.
- Menetapkan upstream identity dan pinning policy sebagai handoff runtime.
- Menetapkan ownership configuration, validation, storage, dan orchestration.
- Menetapkan interface Prometheus ke Alertmanager serta notification routing
  baseline untuk lab.
- Menetapkan receiver, secret, dan Integration Bridge boundary.
- Menentukan validation layers, implementation order, open questions, dan
  authorization gate berikutnya.
- Memperbarui phase index, navigation, dan current-state documentation sesuai
  keputusan yang telah berlaku.

Source atau configuration implementation, repository runtime baru, image
build, semantic test, persistent deployment, external delivery, TrueSight
mapping, secret creation, cleanup, commit, dan push tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| TN-024 | Prometheus telah memuat tiga rules dan membuktikan mutually exclusive firing serta resolved behavior; Alertmanager dan notification flow tidak disentuh. |
| TM-ADR-0001 | Alertmanager menangani grouping, deduplication, dan routing firing/resolved alert; TrueSight berada di belakang external-integration boundary. |
| Repository governance | Runtime component dengan lifecycle image reusable sendiri harus berada pada repository runtime terpisah. |
| Local repository state | Repository `/home/eddywiyatno/git/alertmanager` belum tersedia; `tomcat-monitoring` hanya memiliki placeholder `config/alertmanager/README.md`. |
| Prometheus dan Telegraf runtime | Kedua component menggunakan repository generik terpisah untuk upstream pin, build, smoke test, run, dan cleanup; integration configuration tetap dimiliki `tomcat-monitoring`. |
| Official Alertmanager documentation | Release production terbaru pada assessment adalah `0.34.0`; official image tersedia melalui Quay.io, port default `9093`, configuration mendukung grouping, webhook `url_file`, dan `send_resolved`. |

## 🔍 Findings

### Runtime Component Ownership Gate

| Question | Finding |
| --- | --- |
| Reusable image lifecycle? | Ya. Alertmanager memerlukan upstream pinning, image identity, build, `amtool` smoke test, entrypoint, run, data mount, dan cleanup contract. |
| Existing generic runtime? | Tidak ada. Exact directory `/home/eddywiyatno/git/alertmanager` tidak tersedia pada assessment. |
| Required runtime owner | Repository generik baru `alertmanager`. |
| Integration owner | Repository `tomcat-monitoring` tetap memiliki `alertmanager.yml`, routing, receiver references, Prometheus alerting target, validator, named-volume initialization, dan deployment orchestration. |
| Upstream identity | `quay.io/prometheus/alertmanager:v0.34.0`, dipin secara exact pada runtime source; immutable digest diverifikasi pada build activity berikutnya. |

Mengonsumsi tag floating atau menjalankan upstream langsung dari
`tomcat-monitoring` akan mencampur lifecycle runtime dengan configuration
integration. Membungkus Alertmanager di repository Prometheus juga tidak tepat
karena keduanya memiliki release, binary, data, startup, dan cleanup lifecycle
yang independen.

### Runtime and storage boundary

Lab baseline menggunakan interface berikut:

| Concern | Contract |
| --- | --- |
| Container identity | Alias internal `alertmanager` pada network `devops-lab`. |
| Prometheus delivery | HTTP API v2 ke `alertmanager:9093` melalui container network; port tidak dipublikasikan ke host secara default. |
| Configuration | Named volume `alertmanager_config`, dipasang read-only ke `/etc/alertmanager`. |
| Runtime data | Named volume `alertmanager_data`, dipasang read-write ke `/alertmanager` untuk notification log dan silence state. |
| Secret material | File read-only di bawah `/run/secrets/tomcat-monitoring`; tidak masuk image, configuration source, command output, atau Git. |
| UI access | Tidak termasuk baseline. Host publication memerlukan target, access control, dan authorization terpisah. |

HTTP internal dipilih hanya sebagai lab container-network baseline. Contract ini
tidak menerima plaintext untuk flow lintas host atau network yang tidak
dipercaya; TLS dan authentication untuk environment lain tetap harus dinilai
sebelum deployment.

### Routing and notification boundary

Alertmanager harus mempertahankan stable labels dari TN-023:
`alertname`, `job`, `instance`, `service`, `check`, dan `severity`. Baseline
grouping menggunakan `alertname`, `job`, `instance`, `service`, dan `check`;
`severity` tersedia untuk route matching dan downstream event mapping tanpa
menjadi grouping dimension.

Lab timing baseline ditetapkan sebagai berikut:

| Setting | Baseline | Purpose |
| --- | --- | --- |
| `group_wait` | `30s` | Memberi waktu alert terkait masuk ke group pertama. |
| `group_interval` | `5m` | Membatasi notification update untuk group yang sama. |
| `repeat_interval` | `4h` | Mengingatkan kondisi yang tetap firing tanpa menghasilkan notification setiap evaluation cycle. |
| `send_resolved` | `true` | Memenuhi contract project bahwa recovery diteruskan ke integration layer. |

Nilai tersebut adalah baseline lab, bukan production notification SLO.
Production owner harus menerima timing dan escalation policy sebelum rollout.

Receiver eksternal menggunakan generic Alertmanager webhook menuju Integration
Bridge. Endpoint direferensikan dengan `url_file` pada runtime secret path,
bukan URL literal di Git. Default webhook payload dipertahankan agar
Integration Bridge memiliki ownership terhadap mapping ke SNMP Trap atau
`msend`; custom Alertmanager payload dan credential TrueSight tidak menjadi
tanggung jawab configuration Alertmanager.

Actual endpoint, authentication method, certificate trust, retry expectation,
event class, severity mapping, deduplication key, dan TrueSight field mapping
belum tersedia. Karena itu, external receiver dan end-to-end runtime tetap
terblokir walaupun source-level route contract sudah ditetapkan.

### Validation boundary

Verification harus dibagi agar satu hasil tidak digunakan untuk mengklaim
layer lain:

| Layer | Required Evidence | Does Not Prove |
| --- | --- | --- |
| Runtime source | Shell syntax, exact upstream pin, non-root identity, `amtool` dan Alertmanager version output. | Configuration atau notification delivery. |
| Configuration source | Static no-secret scan dan `amtool check-config`, termasuk UTF-8 matcher compatibility. | Persistent runtime loading. |
| Isolated component | Temporary Alertmanager readiness, config loading, disposable webhook capture, firing/resolved payload, grouping, dan cleanup. | Persistent Prometheus integration atau TrueSight. |
| Persistent integration | Prometheus delivery, Alertmanager active state, data-volume continuity, controlled failure/recovery, rollback, dan exact cleanup. | Integration Bridge atau TrueSight receipt. |
| External flow | Integration Bridge receives webhook and TrueSight records firing/resolved with accepted mapping. | Production SLO suitability unless production target is used. |

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Tambahkan Alertmanager ke repository runtime Prometheus | Mencampur dua independent upstream dan lifecycle image serta menyulitkan release dan verification terpisah. | Rejected |
| Konsumsi upstream image langsung dari `tomcat-monitoring` | Memerlukan pengecualian ownership dan membuat integration repository memiliki image lifecycle reusable. | Rejected |
| Buat repository runtime generik `alertmanager` | Konsisten dengan Telegraf/Prometheus, menjaga upstream pin dan lifecycle reusable terpisah dari configuration project. | Selected |
| Kirim langsung dari Alertmanager ke TrueSight | Mengikat routing pada satu event manager dan memindahkan mapping/credential ke component yang salah. | Rejected |
| Gunakan webhook ke Integration Bridge | Mempertahankan platform-agnostic routing dan menempatkan TrueSight mapping pada integration boundary. | Selected |
| Simpan URL webhook literal dalam Git | Official schema memperlakukan webhook URL sebagai secret dan nilai dapat berbeda per environment. | Rejected |
| Gunakan `url_file` dari runtime secret mount | Memisahkan source non-secret dari endpoint dan credential environment. | Selected |

## ⚠️ Risks

| Risk | State | Mitigation or Follow-up |
| --- | --- | --- |
| Floating upstream menghasilkan image yang tidak reproducible | Mitigated by contract | Pin `v0.34.0`; catat digest aktual pada authorized build. |
| Grouping menggabungkan alert yang memiliki target berbeda | Mitigated for baseline | Group menggunakan stable target identity dari TN-023. |
| Notification flood terjadi saat failure berulang | Mitigated for lab | Gunakan `group_wait`, `group_interval`, dan `repeat_interval` baseline; validasi behavior secara isolated. |
| URL atau credential Integration Bridge masuk Git | Mitigated by contract | Gunakan runtime file reference dan sensitive-pattern validation. |
| Alertmanager data hilang saat replacement | Open | Tetapkan lifecycle, backup, rollback, permission, dan continuity `alertmanager_data` sebelum persistent deployment. |
| Lab timing tidak sesuai production escalation | Accepted for lab | Production owner menetapkan SLO dan timing sebelum rollout. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Siapa owner Integration Bridge dan apa exact webhook endpoint, authentication, serta TLS contract? | Open | Project owner bersama Integration Bridge owner | Owner, protocol, endpoint delivery method, authentication, trust, timeout, dan retry expectation diterima tanpa menyimpan secret di Git. | Actual webhook receiver, persistent external integration, dan end-to-end notification verification. |
| Bagaimana Alertmanager labels dipetakan ke TrueSight event class, severity, identity, dan deduplication key? | Open | Integration Bridge dan TrueSight owners | Firing/resolved sample payload dan field mapping diterima serta memiliki test criteria. | TrueSight receiver mapping dan external event verification. |
| Apa source dan lifecycle secret file untuk webhook URL atau authentication material? | Open | Project owner bersama infrastructure/security owner | Secret provider, file path, permission, injection, rotation, revocation, dan cleanup contract diterima. | Persistent receiver deployment. |
| Berapa grouping dan notification timing untuk production? | Deferred | Project owner bersama operations owner | Production alert volume, escalation policy, repeat expectation, dan SLO diterima. | Production rollout; tidak memblokir lab baseline. |
| Apakah production memerlukan Alertmanager HA dan backup silence state? | Deferred | Project owner bersama infrastructure owner | Availability target, replica topology, persistence, backup, dan recovery requirement diterima. | Production topology; tidak memblokir single-instance lab. |

## 💡 Recommendation

Gunakan repository runtime baru `alertmanager` dengan upstream exact
`quay.io/prometheus/alertmanager:v0.34.0`. Runtime repository hanya memiliki
image metadata dan generic build/test/run/clean lifecycle; configuration,
receiver reference, named-volume initialization, Prometheus target, validation,
dan deployment orchestration tetap berada pada `tomcat-monitoring`.

Urutan delivery minimum adalah:

1. Bentuk dan validasi statis source repository runtime Alertmanager.
2. Build dan smoke-test image sebagai activity terpisah dengan authorization
   image serta disposable cleanup.
3. Implementasikan non-secret Alertmanager configuration, validator, dan
   Prometheus delivery contract setelah runtime terverifikasi.
4. Lakukan isolated firing/resolved webhook verification menggunakan receiver
   disposable sebelum persistent runtime.
5. Tutup ownership, endpoint, secret, dan mapping Open Questions sebelum
   Integration Bridge atau TrueSight digunakan.

## 🤝 Decision Handoff

Project owner menerima objective dan documentation scope TN-025 pada
2026-08-26. Berdasarkan mandatory Runtime Component Ownership Gate, repository
runtime baru `alertmanager`, upstream pin `v0.34.0`, repository boundaries,
internal lab interface, routing baseline, `send_resolved: true`, dan
file-based webhook secret reference ditetapkan sebagai contract planning.

Contract ini menerapkan TM-ADR-0001 tanpa mengubah accepted topology atau
external-integration boundary, sehingga ADR baru tidak diperlukan. Ia tidak
memberikan authorization untuk membuat repository, source, image, runtime,
volume, receiver, secret, atau external event.

## ⚙️ Commands Executed

Seluruh shell command pada aktivitas ini bersifat read-only atau documentation
verification. Tidak ada command build, test component, container, cleanup,
commit, push, atau external-state mutation yang dijalankan.

```bash
# Run from each relevant repository root before activity selection
git status --short --branch

# Governance, journal, and current-state discovery
rg --files -g 'AGENTS.md' -g '!**/.git/**' /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/devops-handbook /home/eddywiyatno/git/tomcat /home/eddywiyatno/git/tomcat-jmx-exporter /home/eddywiyatno/git/telegraf /home/eddywiyatno/git/prometheus /home/eddywiyatno/git/nodejs
sed -n '1,260p' /home/eddywiyatno/git/tomcat-monitoring/AGENTS.md
sed -n '1,260p' /home/eddywiyatno/git/devops-handbook/AGENTS.md
rg --files /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring /home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,320p' docs/projects/tomcat-monitoring/index.md
sed -n '1,520p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,520p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
sed -n '176,279p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
sed -n '560,640p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md

# Documentation standards and precedent
sed -n '1,520p' docs/standards/documentation-standards.md
sed -n '1,520p' docs/standards/engineering-journal-standards.md
sed -n '521,1100p' docs/standards/engineering-journal-standards.md
sed -n '1,520p' docs/standards/writing-standards.md
sed -n '1,360p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-023-define-application-health-alert-and-missing-metric-contract.md
sed -n '1,360p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-009-establish-prometheus-runtime-repository.md
sed -n '1,160p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages

# Runtime ownership and integration source evidence
rg --files
sed -n '1,420p' /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager/README.md
sed -n '1,420p' /home/eddywiyatno/git/prometheus/AGENTS.md
sed -n '1,420p' /home/eddywiyatno/git/prometheus/README.md
sed -n '1,420p' /home/eddywiyatno/git/prometheus/PROJECT
sed -n '1,420p' /home/eddywiyatno/git/prometheus/VERSION
sed -n '1,420p' /home/eddywiyatno/git/prometheus/CONFIG
sed -n '1,420p' /home/eddywiyatno/git/prometheus/Containerfile
sed -n '1,420p' /home/eddywiyatno/git/telegraf/AGENTS.md
sed -n '1,420p' /home/eddywiyatno/git/telegraf/README.md
sed -n '1,420p' /home/eddywiyatno/git/telegraf/PROJECT
sed -n '1,420p' /home/eddywiyatno/git/telegraf/VERSION
sed -n '1,420p' /home/eddywiyatno/git/telegraf/CONFIG
sed -n '1,420p' /home/eddywiyatno/git/telegraf/Containerfile
test -d /home/eddywiyatno/git/alertmanager && printf 'alertmanager_repository=present\n' || printf 'alertmanager_repository=absent\n'
rg -n -C 4 'alertmanager|alerting|receiver|route|resolve|secret' README.md config scripts validation
sed -n '1,360p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,360p' docs/projects/tomcat-monitoring/development/index.md
sed -n '1,360p' docs/projects/tomcat-monitoring/ci-cd/index.md

# Documentation verification
git diff --check
git status --short --branch
git diff --stat
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
rg -n 'TN-025|TN-025-define-alertmanager' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md
test -f docs/projects/tomcat-monitoring/architecture/index.md
test -f docs/projects/tomcat-monitoring/development/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token:|^[[:space:]]*passwor[d]:|https?://[^[:space:]/]+:[^[:space:]@]+@' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
command -v mkdocs
git diff -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
```

Directory check melaporkan `alertmanager_repository=absent`; hasil tersebut
adalah evidence bahwa repository target belum tersedia. Whitespace dan secret
scans tidak menemukan match sehingga `rg` mengembalikan exit code `1` seperti
yang diharapkan. `command -v mkdocs` juga tidak menghasilkan path karena
executable tidak tersedia.

Patch dokumentasi pertama tidak diterapkan karena context baris Architecture
berbeda dari target patch. Tool membatalkan patch tanpa perubahan parsial;
patch berikutnya diselaraskan dengan source aktual dan berhasil diterapkan.
Official Prometheus Download, Alertmanager configuration, Alertmanager overview, dan
official upstream repository juga direview secara read-only pada 2026-08-26.

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Review phase placement dan metadata | TN-025 menjadi nomor tertinggi pada phase aktif dan memiliki metadata live activity serta authorization. | Passed. | Phase index, `.pages`, dan heading review menempatkan TN-025 setelah TN-024. |
| Review ownership gate | Satu runtime owner, integration owner, upstream identity, dan lifecycle boundary ditetapkan tanpa membuat repository. | Passed. | Runtime repository baru `alertmanager` dipilih; directory target tetap tidak tersedia dan tidak dibuat. |
| Review architecture consistency | Contract menerapkan TM-ADR-0001 tanpa memindahkan TrueSight mapping atau credential ke Alertmanager. | Passed. | Current-state Architecture, Infrastructure, dan Development memisahkan runtime, configuration, dan external integration ownership. |
| Review notification contract | Stable labels, grouping, lab timing, resolved delivery, receiver, dan secret boundary dapat dibedakan. | Passed untuk planning contract. | Routing table, webhook boundary, risks, dan Open Questions tersedia pada TN ini. |
| Review links, whitespace, dan sensitive patterns | Relative target tersedia; diff tidak memiliki whitespace error atau secret material. | Passed. | Exact file checks, targeted scans, dan `git diff --check` lulus. |
| MkDocs render | Site dapat dirender tanpa error. | Not verified. | `mkdocs` executable tidak tersedia dan dependency tidak dipasang. |
| Alertmanager configuration dan runtime | `amtool`, readiness, grouping, webhook firing/resolved, persistence, rollback, dan cleanup lulus. | Not verified; di luar scope TN-025. | Menjadi mandatory criteria pada implementation dan verification Technical Note berikutnya. |
| External notification flow | Integration Bridge dan TrueSight menerima serta memetakan firing/resolved event. | Not verified; prerequisite belum tersedia. | Open Questions menetapkan owner dan closure condition. |

## 🧾 Outcome

Runtime Component Ownership Gate Alertmanager selesai. Repository generik baru
`alertmanager` ditetapkan sebagai owner upstream pin dan lifecycle image;
`tomcat-monitoring` tetap menjadi owner configuration, validator, Prometheus
wiring, named-volume initialization, dan deployment orchestration.

Internal lab interface, data/configuration boundary, stable routing labels,
grouping dan timing baseline, resolved delivery, webhook receiver, serta
file-based secret boundary telah ditetapkan. Integration Bridge ownership,
endpoint, authentication, TLS, TrueSight mapping, production timing, dan HA
tetap terbuka dengan owner serta closure condition yang eksplisit.

Objective discovery selesai dan current-state documentation telah
dikonsolidasikan. Tidak ada repository runtime, source/configuration project,
image, container, volume, secret, receiver, external event, commit, atau push
yang dibuat atau diubah.

## ⏭️ Next Steps

Buka Technical Note implementation baru untuk membentuk repository runtime
generik `alertmanager` dengan exact source plan dan authorization. Build dan
smoke test image tetap memerlukan scope terpisah. Configuration integration dan
external notification tidak boleh dimulai hanya berdasarkan approval TN-025.

## 🔗 Related Documentation

- [TN-024 — Implement and Verify Prometheus Application-Health Alert Rules](TN-024-implement-and-verify-prometheus-application-health-alert-rules.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [Prometheus Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Prometheus Download](https://prometheus.io/download/)

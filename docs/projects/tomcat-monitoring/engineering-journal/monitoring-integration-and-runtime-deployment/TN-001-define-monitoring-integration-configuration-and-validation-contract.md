# TN-001 — Define Monitoring Integration Configuration and Validation Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Menetapkan implementation plan dan validation contract minimum yang dapat
direview sebelum repository `tomcat-monitoring` menerima source atau
configuration monitoring.

## 🌍 Background

Architecture contract telah diterima, tetapi repository `tomcat-monitoring`
belum memiliki layout source maupun validator. Nilai interface yang menentukan
health check, network, TLS secret source, storage, dan deployment juga belum
ditetapkan. Aktivitas ini dimulai setelah Documentation Gate dan scope
assessment disetujui.

## 📚 Scope

Mencatat facts, dependency, risk, open question, recommendation, dan
implementation plan untuk initial integration slice. Aktivitas ini tidak
membuat source atau configuration monitoring, menjalankan build atau test,
memasang dependency, maupun mengubah runtime atau external state.

## 📥 Inputs

| Source | Fact used by this activity |
| --- | --- |
| TM-ADR-0001 | Embedded JMX Exporter, Prometheus, Telegraf, Alertmanager, dan Integration Bridge adalah architecture contract yang accepted. |
| `tomcat-jmx-exporter` contract | Derived image menyediakan HTTPS `/metrics` pada port `9404`; runtime configuration, TLS keystore, dan password keystore dipasang dari luar image. |
| Project architecture and infrastructure pages | Telegraf memeriksa `http://<tomcat-container>:8080/health`; Prometheus mengambil metrics JMX Exporter dan Telegraf. |
| Repository state | `tomcat-monitoring` hanya memiliki governance instruction dan belum memiliki implementation layout. |

## 🔍 Findings

| Area | State | Assessment |
| --- | --- | --- |
| Repository ownership | Defined | `tomcat-monitoring` memiliki JMX Exporter rules, Prometheus, Telegraf, Alertmanager, dashboard, integration, dan automation; repository lain tetap read-only contract provider. |
| JMX Exporter interface | Defined | Image membutuhkan config pada `/etc/tomcat-jmx-exporter/config.yml` dan material TLS runtime yang tidak boleh masuk repository atau image. |
| Initial configuration layout | Not started | Layout source dan validation interface belum ada; keduanya harus ditetapkan sebelum configuration dibuat. |
| Health check interface | Partially defined | Path dan container port telah ditetapkan, tetapi expected status/body, timeout, interval, dan export/scrape interface Telegraf belum ditentukan. |
| Runtime deployment | Not ready | Network, storage, certificate lifecycle, target inventory, rollback, registry, dan external integration ownership belum ditentukan. |
| Current-source image evidence | Not verified | Source `tomcat-jmx-exporter` saat ini belum clean-build dan smoke-test; hasil image revision sebelumnya tidak dapat menjadi bukti candidate baru. |

## ⚠️ Risks

| Risk | State | Mitigation or follow-up |
| --- | --- | --- |
| Configuration dibuat dengan nilai health atau TLS yang diasumsikan | Open | Selesaikan interface decision sebelum membuat configuration yang dapat dijalankan. |
| Secret atau certificate masuk ke Git atau image layer | Open | Gunakan template non-secret dan runtime secret injection saja. |
| Validator CI dibuat sebelum validation interface komponen tersedia | Open | Definisikan validator lokal per artifact sebelum pipeline. |
| Derived image lama diperlakukan sebagai candidate current source | Open | Jadwalkan clean build dan smoke test sebagai verification activity terpisah dengan authorization build. |

## ❓ Open Questions

| Question | State | Required before |
| --- | --- | --- |
| Berapa expected HTTP status, response body, timeout, dan interval untuk `/health`? | Open | Telegraf configuration implementation |
| Bagaimana Prometheus mengambil health metrics Telegraf, termasuk protocol dan port? | Open | Prometheus and Telegraf integration implementation |
| Apa nama network, port allocation, storage/retention, dan deployment target awal? | Open | Runtime deployment |
| Apa secret source serta certificate issuance, renewal, dan ownership model? | Open | TLS-enabled runtime deployment |
| Apa source container-status metrics dan ownership Integration Bridge/TrueSight? | Open | Alerting and external-integration implementation |

## 💡 Recommendation

Pisahkan pekerjaan menjadi dua gate berikut:

1. Setujui initialization scope repository yang hanya membentuk struktur non-secret, documentation contract, dan validator stub tanpa menjalankan dependency atau runtime.
2. Setujui implementation scope per integration slice setelah nilai interface yang dibutuhkan slice tersebut diputuskan; clean build derived image adalah verification activity terpisah dan bukan bukti end-to-end integration.

Urutan tersebut menghasilkan progress yang dapat direview tanpa memilih nilai runtime atau menyimpan material sensitif secara prematur.

## ⚙️ Execution Record

| Sequence | Purpose | Command actually executed | Actual result |
| --- | --- | --- | --- |
| 1 | Identify repository roots and state | `git -C <repository> rev-parse --show-toplevel`; `git -C <repository> status --short --branch` | Menetapkan root lima repository dan menemukan perubahan user hanya pada `personal-site` handbook. |
| 2 | Read governance and contracts | `sed -n '1,420p' <AGENTS.md-or-contract>`; `rg --files <repository>` | Mengonfirmasi ownership, read-only boundary, dan source contract. |
| 3 | Review project evidence | `sed -n '1,360p' <project-page-or-TN>`; `git -C <repository> log --oneline -8` | Memisahkan verified, planned, dan evidence yang belum ada. |

Expected result seluruh tahap adalah assessment tanpa source/runtime change; actual result memenuhi expected result.

## 🧭 Decision Handoff

Tidak ada keputusan arsitektur baru yang diambil. TM-ADR-0001 tetap menjadi source of truth architecture. Approval berikutnya yang diperlukan adalah Implementation Gate untuk initialization repository non-secret; keputusan runtime yang masih terbuka tetap tidak dapat dianggap accepted.

## 🧾 Outcome

Assessment dan implementation plan minimum telah disiapkan sebagai record live. Objective Technical Note selesai karena facts, dependency, risks, open questions, dan handoff telah dibedakan. Navigation, relative links, heading structure, dan `git diff --check` pada target documentation telah direview. MkDocs render validation berstatus `Not verified` karena command `mkdocs` tidak tersedia dan tidak dipasang. Tidak ada source, configuration, build, test, runtime, atau external-state change yang dilakukan.

## ⏭️ Next Steps

Implementation Gate berikutnya telah diselesaikan melalui TN-002. Untuk
aktivitas lanjutan, pilih satu component slice dan catat owner, source artifact,
validator lokal, input runtime non-secret, expected result, serta batas bukti
yang tidak akan diklaim.

Untuk Telegraf health check, input minimum yang diperlukan adalah target URL
internal, expected status dan body, timeout, interval, serta metrics interface
untuk Prometheus. Keputusan network deployment, TLS, storage, registry, dan
external integration tetap berada di luar component slice ini.

## 📝 Commands Executed

```bash
git -C <repository> status --short --branch
git -C <repository> rev-parse --show-toplevel
rg --files <repository>
sed -n '1,420p' <instruction-or-project-document>
git -C <repository> log --oneline -8
git -C devops-handbook diff --check -- docs/projects/tomcat-monitoring
```

Command di atas digunakan untuk context discovery dan review; seluruhnya
read-only.

## 🔗 Related Documentation

- [Runtime Monitoring Foundation](../runtime-monitoring-foundation/index.md)
- [TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [CI/CD](../../ci-cd/index.md)

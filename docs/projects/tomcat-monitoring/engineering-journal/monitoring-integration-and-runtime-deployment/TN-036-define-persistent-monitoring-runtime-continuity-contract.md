# TN-036 — Define Persistent Monitoring Runtime Continuity Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-30 |
| Recorded Date | 2026-08-30 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-30 |

## 🎯 Objective

Menetapkan recommendation dan Decision Handoff untuk restart policy,
host-boot orchestration, ownership, startup dependency, serta verification
boundary persistent lab monitoring tanpa mengubah source runtime atau
container state.

## 🌍 Background

TN-035 menyelesaikan persistent Prometheus–Alertmanager–Mailpit delivery dan
menyisakan restart policy serta host-boot orchestration sebagai deferred
operability decision. Current-state Infrastructure masih mencatat owner
`Runtime service continuity` sebagai `not determined`.

Project owner menyetujui TN-036 sebagai documentation-only decision assessment
pada 2026-08-30 dan menanyakan apakah TN ini menjadi Technical Note terakhir
dalam phase Monitoring Integration and Runtime Deployment. Status tersebut
tidak dapat diasumsikan hanya dari nomor TN: phase closure memerlukan keputusan
eksplisit mengenai continuity serta disposition pekerjaan phase yang masih
planned atau deferred.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- read-only review terhadap Engineering Journal, current-state documentation,
  repository boundary, dan lifecycle interface runtime terkait;
- assessment alternatif manual continuity, container restart policy, dan
  rootless systemd/Quadlet orchestration;
- penetapan recommendation, decision questions, ownership boundary, dan
  verification criteria; serta
- pembuatan TN-036 dan pembaruan phase navigation.

Aktivitas ini tidak mencakup source atau configuration change pada
`tomcat-monitoring` maupun runtime repository, Podman inspection, container
mutation, host service change, host reboot, implementation, runtime test,
cleanup, ADR acceptance, commit, atau push.

## 📥 Inputs

| Input | State | Relevance |
| --- | --- | --- |
| TN-035 `Next Steps` | Verified | Restart policy dan host-boot orchestration menjadi deferred operability decision. |
| Infrastructure ownership | Verified | Runtime service continuity belum memiliki owner atau mechanism yang diterima. |
| Runtime repository contracts | Observed | `run.sh` membuat container secara langsung dan tidak menetapkan restart atau host-boot contract. |
| Integration repository contract | Verified | Deployment orchestration dimiliki `tomcat-monitoring`; generic runtime repository tidak boleh mengambil alih automation project. |
| Project owner direction | Accepted | TN-036 dijalankan sebagai penutup phase; capability lanjutan dibahas pada phase baru ketika aktivitasnya dimulai. |

## 🔍 Findings

1. Source `tomcat-monitoring` saat ini menyediakan configuration initializer,
   validator, dan integration fixtures, tetapi belum menyediakan deklarasi
   service host atau deployment orchestration untuk memulihkan topology setelah
   reboot.
2. Runtime `run.sh` Tomcat/JMX Exporter, Telegraf, Prometheus, dan Alertmanager
   menjalankan `podman run --detach` tanpa restart policy. Source inspection
   tersebut tidak membuktikan current container settings atau host service
   state karena runtime inspection berada di luar approved scope.
3. Menambahkan policy pada generic runtime repository akan melanggar ownership
   boundary: availability expectation, startup ordering, environment identity,
   dan deployment verification merupakan tanggung jawab integration
   orchestration.
4. `--restart` pada container dapat menjadi bagian dari process-recovery
   policy, tetapi tidak cukup sebagai host-boot contract tanpa mechanism host
   yang menjalankan kembali rootless container dan menetapkan ordering.
5. Rootless systemd/Quadlet merupakan kandidat yang paling lengkap bila target
   membutuhkan automatic recovery setelah process failure dan host reboot.
   Kelayakannya belum diverifikasi terhadap versi Podman/systemd, user
   lingering, lokasi unit, startup ordering, dan exact lab runtime.
6. Ansible dan CI/CD tetap planned. Keduanya dapat menyediakan provisioning dan
   deployment yang reproducible, tetapi tidak otomatis menjadi boot-time
   service owner tanpa keputusan tambahan.
7. Dashboard, CI/CD/Ansible, external delivery, container-status metrics,
   production deployment, dan end-to-end verification bukan objective yang
   harus diselesaikan di phase ini. Project owner menerima pemisahan pekerjaan
   tersebut ke phase baru ketika aktivitasnya benar-benar dimulai.

## 🔀 Alternatives

| Alternative | State | Capability | Trade-off |
| --- | --- | --- | --- |
| Manual recovery; continuity tetap deferred | Selected | Mempertahankan persistent lab sebagai environment yang dijalankan operator sesuai kebutuhan. | Tidak menjamin recovery otomatis setelah process failure atau host reboot. |
| Integration-owned container restart policy | Assessed | Dapat menangani sebagian process-exit recovery dengan policy yang disetujui. | Host-boot activation, dependency ordering, dan operator visibility tetap memerlukan contract terpisah. |
| Rootless systemd/Quadlet di `tomcat-monitoring` | Deferred | Dapat menyatakan container, network, volume, dependency, restart, dan boot lifecycle pada owner integration. | Ditinjau kembali hanya jika automatic continuity menjadi kebutuhan yang disetujui. |
| Ansible atau CI/CD sebagai boot-time owner | Rejected for boot lifecycle; retained for provisioning | Cocok untuk reproducible provisioning dan controlled deployment. | Pipeline atau playbook tidak seharusnya diasumsikan berjalan otomatis pada setiap host boot. |

## ⚠️ Risks

| Risk | State | Mitigation or Closure Condition |
| --- | --- | --- |
| Restart loop menutupi configuration atau dependency failure | Deferred | Tidak ada restart automation pada current contract; review kembali sebelum future implementation. |
| Startup order tersedia tetapi readiness dependency belum terpenuhi | Deferred | Definisikan dependency dan readiness criteria jika automatic continuity dibuka kembali. |
| Rootless service tidak aktif saat host boot | Accepted | Current lab bersifat operator-managed dan tidak mengklaim automatic host-boot recovery. |
| Automation mereferensikan certificate atau secret secara tidak aman | Open | Gunakan existing non-Git material dan reference contract; jangan menyalin sensitive material ke unit atau Git. |
| Phase ditutup sementara outstanding work tidak memiliki tujuan penerus | Closed | Capability lanjutan dipisahkan ke phase baru ketika pekerjaan benar-benar dimulai. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah persistent lab harus pulih otomatis setelah container process failure dan host reboot? | Answered — operator-managed on 2026-08-30 | Project owner | Manual start dan recovery diterima sebagai current availability boundary. | Tidak ada; automatic continuity ditunda. |
| Siapa owner host-level rootless service lifecycle? | Deferred | Project owner atau infrastructure owner | Owner ditetapkan jika automatic continuity dibuka kembali. | Future continuity automation only. |
| Apakah rootless systemd/Quadlet diterima sebagai target mechanism? | Deferred | Project owner | Alternative dinilai kembali jika automatic continuity dibutuhkan. | Future continuity automation only. |
| Apakah TN-036 menjadi TN terakhir phase ini? | Answered — Yes on 2026-08-30 | Project owner | Capability lanjutan dipisahkan ke phase baru ketika aktivitasnya dimulai. | Tidak ada; phase closure dapat diselesaikan. |

## 💡 Recommendation

Pertahankan persistent lab sebagai operator-managed environment. Jangan
menambahkan restart/boot behavior ke generic runtime repository dan jangan
membuat implementation TN untuk continuity sebelum terdapat kebutuhan baru
serta authorization terpisah.

Dashboard, container-status metrics, CI/CD/Ansible, external delivery,
production deployment, dan end-to-end verification dicatat sebagai pekerjaan
future. Phase baru dibuat hanya ketika salah satu aktivitas tersebut dimulai.

## ⚖️ Decision Handoff

Project owner menetapkan persistent lab sebagai operator-managed environment
pada 2026-08-30. Restart policy dan host-boot automation ditunda; rootless
systemd/Quadlet tetap menjadi alternatif future dan bukan accepted target
implementation.

Project owner juga menetapkan TN-036 sebagai Technical Note terakhir phase
Monitoring Integration and Runtime Deployment. Pekerjaan lanjutan dipisahkan
ke phase baru ketika benar-benar dimulai. Keputusan ini tidak membatalkan
pekerjaan future dan tidak mengotorisasi implementasinya.

## 🖥️ Commands Executed

Command berikut dijalankan dalam read-only discovery. Tidak ada build, test,
Podman command, container inspection, atau host-service command yang
dijalankan.

```bash
# /home/eddywiyatno/git/tomcat-monitoring dan /home/eddywiyatno/git/devops-handbook
git status --short --branch
sed -n '1,300p' AGENTS.md
rg --files /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring /home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,280p' docs/projects/tomcat-monitoring/index.md
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,900p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
sed -n '901,1240p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
sed -n '1570,1785p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
rg -n -C 3 'restart policy|host-boot|orchestration|External delivery|external delivery|TrueSight|Next|Planned|Deferred|Not started' docs/projects/tomcat-monitoring/{architecture,development,infrastructure,operations,ci-cd}/index.md
sed -n '185,250p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,190p' docs/projects/tomcat-monitoring/operations/index.md

# /home/eddywiyatno/git/devops-handbook
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,1089p' docs/standards/engineering-journal-standards.md
sed -n '1,420p' docs/standards/writing-standards.md
sed -n '1,160p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages

# /home/eddywiyatno/git/tomcat-monitoring
sed -n '1,220p' README.md
sed -n '1,180p' scripts/initialize-alertmanager-volumes.sh
sed -n '1,180p' scripts/initialize-prometheus-volumes.sh
rg --files

# Runtime repositories: tomcat, tomcat-jmx-exporter, telegraf, prometheus, alertmanager
git status --short --branch
sed -n '1,300p' AGENTS.md
sed -n '1,300p' README.md
sed -n '1,260p' scripts/run.sh
sed -n '1,260p' entrypoint.sh

# /home/eddywiyatno/git/devops-handbook documentation review
git diff --check
git diff --stat
git diff --name-status
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-036-define-persistent-monitoring-runtime-continuity-contract.md
rg -n 'TN-036-define-persistent-monitoring-runtime-continuity-contract.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-036-define-persistent-monitoring-runtime-continuity-contract.md
if command -v mkdocs >/dev/null; then mkdocs build --strict --site-dir /tmp/tm-tn036-mkdocs-site; else echo 'mkdocs=not-installed'; fi
git status --short --branch
tn='docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-036-define-persistent-monitoring-runtime-continuity-contract.md'
check_output="$(git diff --check --no-index /dev/null "$tn" || true)"
test -z "$check_output"
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/projects/tomcat-monitoring/operations/index.md
test -f docs/projects/tomcat-monitoring/ci-cd/index.md

# Phase-closure review after project-owner direction
git status --short --branch
sed -n '1,70p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,55p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '220,260p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,250p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-036-define-persistent-monitoring-runtime-continuity-contract.md
sed -n '180,215p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '240,330p' docs/projects/tomcat-monitoring/infrastructure/index.md

# Final phase-closure validation
git diff --check
tn='docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-036-define-persistent-monitoring-runtime-continuity-contract.md'
check_output="$(git diff --check --no-index /dev/null "$tn" || true)"
test -z "$check_output"
test -f "$tn"
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
rg -n 'TN-036-define-persistent-monitoring-runtime-continuity-contract.md' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n 'Monitoring Integration and Runtime Deployment.*Completed' docs/projects/tomcat-monitoring/engineering-journal/index.md
rg -n 'Runtime service continuity.*manual start|Persistent lab saat ini bersifat operator-managed' docs/projects/tomcat-monitoring/infrastructure/index.md
git diff --stat
git diff --name-status
git status --short --branch
```

## 🧾 Outcome

Assessment telah mengidentifikasi ownership boundary, empat alternatif,
recommendation bersyarat, risiko, dan decision questions. Tidak ada runtime
state yang diperiksa atau diubah, sehingga current container health dan
host-boot behavior tetap `Not verified`.

Project owner menerima operator-managed lab sebagai current availability
boundary dan menutup phase pada TN-036. Tidak ada source, runtime, container,
host-service, atau secret change. Runtime health dan host-boot behavior tidak
diperiksa ulang dalam aktivitas documentation-only ini.

Documentation review lulus: changed tracked files dan TN baru tidak memiliki
whitespace error, TN-036 terdaftar pada phase index serta `.pages`, seluruh
relative documentation targets tersedia, dan heading structure telah direview.
Phase index berstatus `Completed`, current-state Infrastructure mencatat manual
start/recovery, dan stale `In Progress` decision text tidak ditemukan pada
TN-036 di luar command history.
MkDocs render berstatus `Not verified` karena executable tidak tersedia;
dependency tidak dipasang.

## ⏭️ Next Steps

Mulai phase baru hanya ketika dashboard, monitoring status container,
CI/CD/Ansible, external delivery, production deployment, end-to-end
verification, atau automatic continuity benar-benar dikerjakan dan memiliki
scope serta authorization sendiri.

## 🔗 Related Documentation

- [TN-035 — Implement and Verify Persistent Prometheus–Alertmanager–Mailpit Delivery](TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md)
- [Monitoring Integration and Runtime Deployment](index.md)
- [Tomcat Monitoring Infrastructure](../../infrastructure/index.md)
- [Tomcat Monitoring Operations](../../operations/index.md)
- [Tomcat Monitoring CI/CD](../../ci-cd/index.md)

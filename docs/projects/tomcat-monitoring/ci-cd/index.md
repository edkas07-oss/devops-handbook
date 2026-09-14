# CI/CD

## Overview

Tomcat Monitoring akan menggunakan pipeline terpisah untuk Continuous
Integration dan Continuous Deployment. CI memvalidasi source, configuration,
automation, dan container candidate. CD memilih artifact yang telah lolos CI,
kemudian menjalankan provisioning melalui Ansible dan memverifikasi hasilnya.

Pipeline belum diimplementasikan. Halaman ini mendefinisikan target flow dan
boundary agar build, provisioning, deployment, dan validation tidak bercampur.
Seluruh target validation diturunkan dari interface pada
[Deployment Topology](../architecture/index.md#deployment-topology), bukan dari
detail internal masing-masing tool.

## Repository Responsibilities

| Repository | Current Responsibility | Status |
| --- | --- | --- |
| `tomcat` | Menyediakan reusable Apache Tomcat 9.0 container image dan runtime scripts | Available |
| `tomcat-jmx-exporter` | Menyediakan derived Tomcat image dengan embedded JMX Exporter | Initial source published; CI not implemented |
| `tomcat-monitoring` | Menyediakan monitoring configuration, automation, dan validation | Repository initialized; source not started |
| `tmctl` | Menyediakan unified cross-platform operator CLI berbasis Go untuk orkestrasi Socket API (Linux & Windows) | Available (TN-012) |
| `tm-agent` | Menyediakan unified cross-platform event collector daemon berbasis Go untuk socket streaming (Linux & Windows) | Available (TN-013) |
| `devops-handbook` | Menyimpan current-state documentation dan engineering history | Available |

Repository `tomcat` saat ini telah memiliki Containerfile, build script,
multi-instance runtime script, persistent volume model, dan container
healthcheck dasar. Repository `tomcat-jmx-exporter` telah menyediakan build
source untuk derived image tanpa mengubah generic Tomcat image.

Lokasi Ansible inventory, playbook, role, dan pipeline definition juga belum
ditetapkan. Keputusan tersebut harus dibuat sebelum pipeline diimplementasikan.

## Pipeline Definitions

| Pipeline | Definition | Responsibility | Status |
| --- | --- | --- | --- |
| Continuous Integration | Not determined | Validate, test, build, dan publish immutable candidate | Planned |
| Continuous Deployment | Not determined | Select candidate, provision dengan Ansible, deploy, dan verify | Planned |

Pipeline engine, agent label, trigger, credential identifier, dan artifact
storage belum ditentukan.

## Continuous Integration

Target CI flow:

```text
Checkout source
  → validate repository structure
  → lint configuration and automation
  → validate JMX Exporter, Telegraf, Prometheus, and Alertmanager configuration
  → build immutable container candidate
  → run container-based integration test
  → verify metrics and local HTTP health result
  → publish immutable candidate
```

CI harus menghentikan proses ketika validation gagal. Pipeline tidak boleh
melakukan provisioning atau mengubah runtime target.

CI menjalankan interface build dan validation yang disediakan oleh setiap
repository. Detail pemasangan JMX Exporter tidak ditulis ulang di pipeline;
prosedur reusable menjadi tanggung jawab [root How-to](../../../how-to/index.md)
dan implementation script pada repository `tomcat-jmx-exporter`.

### CI Validation Scope

- Memvalidasi syntax Containerfile, shell script, YAML, TOML, dan Ansible.
- Memastikan repository tidak berisi password, token, private key, atau
  certificate secret.
- Memastikan Tomcat dapat dimulai dengan JMX Exporter sebagai Java Agent.
- Memastikan JMX Exporter menyajikan metrics melalui HTTPS.
- Memastikan Prometheus dapat memverifikasi certificate dan mengambil metrics.
- Memastikan Telegraf dapat menjalankan local HTTP health check.
- Memastikan Prometheus dapat mengambil health metrics dari Telegraf.
- Memastikan alert rules dan Alertmanager configuration valid.
- Memastikan container candidate memiliki immutable version identity.

Validation command dan tool untuk setiap artifact belum ditetapkan.

## Continuous Deployment

Target CD flow:

```text
Select immutable candidate
  → validate deployment parameters and inventory
  → run infrastructure preflight
  → provide runtime secret and certificate material
  → execute Ansible provisioning
  → deploy Tomcat and monitoring containers
  → verify metrics, health check, dashboard, and alerts
  → execute second Ansible run for idempotency verification
  → record deployment result
```

CD tidak melakukan rebuild. Candidate yang dijalankan harus sama dengan
candidate yang telah melewati CI.

### Ansible Responsibilities

Ansible direncanakan untuk:

- Memverifikasi Rootless Podman prerequisites;
- Menyiapkan container network dan persistent storage;
- Memasang certificate dan trust material dari secret source;
- Membuat target Tomcat containers;
- Menjalankan Prometheus, Telegraf, dan Alertmanager containers;
- Menerapkan JMX Exporter, Telegraf, Prometheus, dan alert configuration;
- Mempertahankan desired state ketika playbook dijalankan kembali; serta
- Menyediakan output yang dapat digunakan pipeline untuk verification.

Ansible tidak boleh menyimpan secret di inventory, playbook, role, atau
repository.

## Artifact Contract

| Artifact | Purpose | Current State |
| --- | --- | --- |
| Generic Tomcat base image | Menjalankan reusable Tomcat runtime tanpa monitoring instrumentation | Available |
| Instrumented Tomcat derived image | Menambahkan JMX Exporter pada generic Tomcat image | Earlier local image build and smoke test verified; current-source clean build and automated publication not implemented |
| Monitoring configuration | Menyediakan JMX Exporter, Telegraf, Prometheus, dan alert configuration | Not started |
| Ansible automation | Menyediakan reproducible provisioning dan deployment | Not started |
| Validation result | Membuktikan candidate dan deployment memenuhi success criteria | Not determined |

Artifact name, version format, registry atau storage, checksum, retention, dan
promotion mechanism belum ditetapkan.

## Runtime Configuration

| Setting | Value |
| --- | --- |
| Container runtime | Rootless Podman `4.9.3` / Docker Dual-Engine ([TM-ADR-0026](../../adr/tomcat-monitoring/adr-records/TM-ADR-0026.md), [TN-008](../engineering-journal/continuous-integration-and-deployment/TN-008-implement-and-standardize-multi-engine-container-runtime-portability.md)) |
| Tomcat base image repository | `tomcat` |
| JMX Exporter image repository | `tomcat-jmx-exporter` |
| Monitoring repository | `tomcat-monitoring` |
| Pipeline engine | Jenkins Pipeline as Code ([TM-ADR-0024](../../adr/tomcat-monitoring/adr-records/TM-ADR-0024.md), [TN-001](../engineering-journal/continuous-integration-and-deployment/TN-001-design-production-ready-jenkins-cicd-pipeline-architecture.md)) |
| Pipeline execution node | Dedicated DooD Agent `builder-01` ([TN-007](../engineering-journal/continuous-integration-and-deployment/TN-007-execute-and-verify-end-to-end-cicd-pipelines-in-jenkins-controller.md)) |
| Ansible execution environment | Containerized `ansible-controller:1.0` / Host Ansible Core ([TM-ADR-0025](../../adr/tomcat-monitoring/adr-records/TM-ADR-0025.md), [TN-009](../engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md)) |
| Container image registry | Enterprise Container Registry (Harbor / Nexus / Quay) & Local Storage ([TN-010](../engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md)) |
| Target inventory | `inventories/lab.ini`, `inventories/staging.ini`, `inventories/production.ini` |
| Secret source | Jenkins Credentials Store & 0700/0400 Local Secret Files |

## Current Status

Siklus otomatisasi CI/CD dan Ansible Fleet Provisioning telah **selesai diimplementasikan dan diverifikasi 100%** di seluruh ekosistem repositori platform Tomcat Monitoring:
- **Component CI Pipelines:** Beroperasi otomatis di `tomcat-diagnostic-service` ([TN-004](../engineering-journal/continuous-integration-and-deployment/TN-004-implement-production-ready-ci-pipeline-for-diagnostic-service.md)) dan `tomcat-diagnostic-event-collector` ([TN-005](../engineering-journal/continuous-integration-and-deployment/TN-005-implement-production-ready-ci-pipeline-for-event-collector.md)).
- **Stack CD Hub:** Beroperasi otomatis di `tomcat-monitoring` ([TN-006](../engineering-journal/continuous-integration-and-deployment/TN-006-implement-stack-orchestration-cd-pipeline-for-tomcat-monitoring.md)).
- **Ansible Fleet Provisioning:** Menyediakan armada multi-node secara idempoten ([TN-009](../engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md)).
- **Plug-and-Play Enterprise Container Registry:** Mendukung migrasi nir-modifikasi kode ke Harbor / Nexus ([TN-010](../engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md)).
- **Cross-Platform Engine API & Go Tooling:** Perancangan orkestrasi multi-OS via Container Engine Socket API dan kakas Go `tmctl`/`tm-agent` ([TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), [TN-011](../engineering-journal/continuous-integration-and-deployment/TN-011-design-cross-platform-container-engine-api-orchestration-and-agent-architecture.md)), implementasi biner tunggal `tmctl` lintas OS ([TN-012](../engineering-journal/continuous-integration-and-deployment/TN-012-implement-unified-cross-platform-operator-cli-tmctl.md)), serta implementasi agen daemon `tm-agent` pengumpul event socket API ([TN-013](../engineering-journal/continuous-integration-and-deployment/TN-013-implement-unified-cross-platform-event-collector-daemon-tm-agent.md)).

## Related Pages

- [Continuous Integration and Deployment Engineering Journal](../engineering-journal/continuous-integration-and-deployment/index.md)
- [SOP: Panduan Migrasi Enterprise Container Registry](../operations/enterprise-container-registry-migration-guide.md)
- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [Operations](../operations/index.md)
- [Follow-up Tasks Backlog](../follow-up-tasks.md)

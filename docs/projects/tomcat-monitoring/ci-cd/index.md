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
| Container runtime | Rootless Podman `4.9.3` |
| Tomcat base image repository | `tomcat` |
| JMX Exporter image repository | `tomcat-jmx-exporter` |
| Monitoring repository | `tomcat-monitoring` |
| Pipeline engine | Not determined |
| Pipeline execution node | Not determined |
| Ansible execution environment | Not determined |
| Container image registry | Not determined |
| Artifact storage | Not determined |
| Target inventory | Not determined |
| Secret source | Not determined |

## Deployment Verification

Deployment belum dapat dinyatakan berhasil hanya berdasarkan status container
`Running`. CD harus membuktikan seluruh kondisi berikut:

- Seluruh target container berada pada desired state;
- Prometheus berhasil mengambil JMX Exporter metrics melalui HTTPS;
- Certificate JMX Exporter berhasil diverifikasi;
- Telegraf memperoleh expected HTTP status dan response body;
- Prometheus menerima health metrics Telegraf;
- Dashboard dapat membaca current dan historical metrics;
- Firing alert diterima Alertmanager;
- Resolved alert diproses setelah kondisi kembali normal;
- Integrasi TrueSight berhasil apabila termasuk target environment; dan
- Ansible run kedua tidak menghasilkan perubahan yang tidak diperlukan.

Method, expected result, dan actual result akan dicatat ketika pipeline telah
dijalankan.

## Failure and Rollback

Strategi rollback belum ditetapkan. Sebelum CD digunakan pada target runtime,
design harus menentukan:

- Kondisi yang menghentikan deployment;
- Immutable image atau configuration version sebelumnya;
- Backup dan recovery untuk persistent data;
- Pemulihan certificate dan secret reference;
- Perilaku ketika hanya sebagian container berhasil diperbarui; serta
- Verification yang wajib diulang setelah rollback.

Pipeline tidak boleh menghapus runtime yang masih berfungsi sebelum rollback
path tersedia dan diverifikasi.

## Pending Decisions

- Pipeline engine dan execution node.
- Pembagian pipeline definition antara repository `tomcat`,
  `tomcat-jmx-exporter`, dan `tomcat-monitoring`.
- CI build dan publication contract untuk derived image pada repository
  `tomcat-jmx-exporter`.
- Struktur Ansible inventory, playbook, dan role.
- Immutable version dan artifact promotion model.
- Container registry atau artifact storage.
- Secret dan certificate source.
- Deployment strategy dan rollback mechanism.
- Environment target untuk integration test dan initial deployment.

## Current Status

CI/CD dan Ansible provisioning belum diimplementasikan. Rootless Podman,
repository `tomcat`, dan initial source repository `tomcat-jmx-exporter` telah
tersedia untuk mendukung tahap desain serta pengujian awal. Local derived image
dari source revision awal telah lulus smoke test. Current-source clean build
dan seluruh pipeline result masih berstatus `Not verified`.

## Related Pages

- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [Operations](../operations/index.md)
- [Engineering Journal](../engineering-journal/index.md)

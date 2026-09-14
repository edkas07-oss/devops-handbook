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
| `tomcat-monitoring` | Menyediakan monitoring configuration, thin declarative Ansible orchestration, dan validation | Available (TN-014) |
| `tmctl` | Menyediakan unified cross-platform operator CLI berbasis Go untuk orkestrasi Socket API (Linux & Windows) | Available (TN-012) |
| `tm-agent` | Menyediakan unified cross-platform event collector daemon berbasis Go untuk socket streaming (Linux & Windows) | Available (TN-013) |
| `devops-handbook` | Menyimpan current-state documentation dan engineering history | Available |

---

## Current Status

Siklus otomatisasi CI/CD dan Ansible Fleet Provisioning telah **selesai diimplementasikan dan diverifikasi 100%** di seluruh ekosistem repositori platform Tomcat Monitoring:
- **Component CI Pipelines:** Beroperasi otomatis di `tomcat-diagnostic-service` ([TN-004](../engineering-journal/continuous-integration-and-deployment/TN-004-implement-production-ready-ci-pipeline-for-diagnostic-service.md)) dan `tomcat-diagnostic-event-collector` ([TN-005](../engineering-journal/continuous-integration-and-deployment/TN-005-implement-production-ready-ci-pipeline-for-event-collector.md)).
- **Stack CD Hub:** Beroperasi otomatis di `tomcat-monitoring` ([TN-006](../engineering-journal/continuous-integration-and-deployment/TN-006-implement-stack-orchestration-cd-pipeline-for-tomcat-monitoring.md)).
- **Ansible Fleet Provisioning:** Menyediakan armada multi-node secara idempoten ([TN-009](../engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md)).
- **Plug-and-Play Enterprise Container Registry:** Mendukung migrasi nir-modifikasi kode ke Harbor / Nexus ([TN-010](../engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md)).
- **Cross-Platform Engine API & Go Tooling:** Perancangan orkestrasi multi-OS via Container Engine Socket API dan kakas Go `tmctl`/`tm-agent` ([TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), [TN-011](../engineering-journal/continuous-integration-and-deployment/TN-011-design-cross-platform-container-engine-api-orchestration-and-agent-architecture.md)), implementasi biner tunggal `tmctl` lintas OS ([TN-012](../engineering-journal/continuous-integration-and-deployment/TN-012-implement-unified-cross-platform-operator-cli-tmctl.md)), implementasi agen daemon `tm-agent` pengumpul event socket API ([TN-013](../engineering-journal/continuous-integration-and-deployment/TN-013-implement-unified-cross-platform-event-collector-daemon-tm-agent.md)), serta refaktorisasi Ansible roles menjadi thin declarative orchestrator berbasis `tmctl` dengan OS Fact Branching ([TN-014](../engineering-journal/continuous-integration-and-deployment/TN-014-refactor-ansible-roles-into-thin-orchestrator-based-on-tmctl-and-os-fact-branching.md)).

## Related Pages

- [Continuous Integration and Deployment Engineering Journal](../engineering-journal/continuous-integration-and-deployment/index.md)
- [SOP: Panduan Migrasi Enterprise Container Registry](../operations/enterprise-container-registry-migration-guide.md)
- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [Operations](../operations/index.md)
- [Follow-up Tasks Backlog](../follow-up-tasks.md)

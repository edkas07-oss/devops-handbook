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
| `tomcat-monitoring` | Menyediakan monitoring configuration, thin declarative Ansible orchestration, dan Stack CD Release Hub | Available & Verified Live (TN-015 / TN-016) |
| `tmctl` | Menyediakan unified cross-platform operator CLI berbasis Go untuk orkestrasi Socket API (Linux & Windows) beserta CI pipeline multi-OS | Available & Verified Live (TN-012 / TN-015 / TN-016) |
| `tm-agent` | Menyediakan unified cross-platform event collector daemon berbasis Go untuk socket streaming (Linux & Windows) beserta CI pipeline multi-OS | Available & Verified Live (TN-013 / TN-015 / TN-016) |
| `devops-handbook` | Menyimpan current-state documentation dan engineering history | Available |

---

## Current Status

Siklus otomatisasi CI/CD, kompilasi silang biner multi-OS, pengarsipan artefak dengan SHA-256 fingerprint hashing, serta orkestrasi Stack CD Hub telah **selesai dieksekusi dan diverifikasi 100% secara live pada Jenkins Controller (`http://localhost:8080`)**:
- **Component CI Pipelines:** Beroperasi otomatis di `tomcat-diagnostic-service` ([TN-004](../engineering-journal/continuous-integration-and-deployment/TN-004-implement-production-ready-ci-pipeline-for-diagnostic-service.md)), `tomcat-diagnostic-event-collector` ([TN-005](../engineering-journal/continuous-integration-and-deployment/TN-005-implement-production-ready-ci-pipeline-for-event-collector.md)), `tmctl` ([TN-015](../engineering-journal/continuous-integration-and-deployment/TN-015-implement-production-ready-cicd-pipelines-for-tmctl-and-tm-agent-multi-os-artifacts-and-stack-release-hub-integration.md) & [TN-016](../engineering-journal/continuous-integration-and-deployment/TN-016-execute-live-multi-os-cicd-pipeline-verification-in-jenkins-controller-and-consolidate-global-architecture.md)), dan `tm-agent` ([TN-015](../engineering-journal/continuous-integration-and-deployment/TN-015-implement-production-ready-cicd-pipelines-for-tmctl-and-tm-agent-multi-os-artifacts-and-stack-release-hub-integration.md) & [TN-016](../engineering-journal/continuous-integration-and-deployment/TN-016-execute-live-multi-os-cicd-pipeline-verification-in-jenkins-controller-and-consolidate-global-architecture.md)).
- **Stack CD Hub:** Beroperasi otomatis di `tomcat-monitoring` ([TN-006](../engineering-journal/continuous-integration-and-deployment/TN-006-implement-stack-orchestration-cd-pipeline-for-tomcat-monitoring.md), [TN-015](../engineering-journal/continuous-integration-and-deployment/TN-015-implement-production-ready-cicd-pipelines-for-tmctl-and-tm-agent-multi-os-artifacts-and-stack-release-hub-integration.md), & [TN-016](../engineering-journal/continuous-integration-and-deployment/TN-016-execute-live-multi-os-cicd-pipeline-verification-in-jenkins-controller-and-consolidate-global-architecture.md)).
- **Ansible Fleet Provisioning:** Menyediakan armada multi-node secara idempoten ([TN-009](../engineering-journal/continuous-integration-and-deployment/TN-009-implement-and-verify-ansible-fleet-provisioning-and-deployment-playbooks.md)).
- **Plug-and-Play Enterprise Container Registry:** Mendukung migrasi nir-modifikasi kode ke Harbor / Nexus ([TN-010](../engineering-journal/continuous-integration-and-deployment/TN-010-implement-plug-and-play-container-registry-integration.md)).
- **Cross-Platform Engine API & Go Tooling:** Perancangan orkestrasi multi-OS via Container Engine Socket API dan kakas Go `tmctl`/`tm-agent` ([TM-ADR-0027](../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md), [TN-011](../engineering-journal/continuous-integration-and-deployment/TN-011-design-cross-platform-container-engine-api-orchestration-and-agent-architecture.md)), implementasi biner tunggal `tmctl` lintas OS ([TN-012](../engineering-journal/continuous-integration-and-deployment/TN-012-implement-unified-cross-platform-operator-cli-tmctl.md)), implementasi agen daemon `tm-agent` pengumpul event socket API ([TN-013](../engineering-journal/continuous-integration-and-deployment/TN-013-implement-unified-cross-platform-event-collector-daemon-tm-agent.md)), refaktorisasi Ansible roles menjadi thin declarative orchestrator berbasis `tmctl` dengan OS Fact Branching ([TN-014](../engineering-journal/continuous-integration-and-deployment/TN-014-refactor-ansible-roles-into-thin-orchestrator-based-on-tmctl-and-os-fact-branching.md)), implementasi pipeline CI/CD produksi biner multi-OS ([TN-015](../engineering-journal/continuous-integration-and-deployment/TN-015-implement-production-ready-cicd-pipelines-for-tmctl-and-tm-agent-multi-os-artifacts-and-stack-release-hub-integration.md)), serta eksekusi dan pembuktian live verifikasi multi-OS pada Jenkins Controller & dedicated build agent `builder-01` ([TN-016](../engineering-journal/continuous-integration-and-deployment/TN-016-execute-live-multi-os-cicd-pipeline-verification-in-jenkins-controller-and-consolidate-global-architecture.md)).


## Related Pages

- [Continuous Integration and Deployment Engineering Journal](../engineering-journal/continuous-integration-and-deployment/index.md)
- [SOP: Panduan Migrasi Enterprise Container Registry](../operations/enterprise-container-registry-migration-guide.md)
- [Architecture](../architecture/index.md)
- [Development](../development/index.md)
- [Infrastructure](../infrastructure/index.md)
- [Operations](../operations/index.md)
- [Follow-up Tasks Backlog](../follow-up-tasks.md)

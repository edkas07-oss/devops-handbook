# TN-002 — Initialize Monitoring Repository Validation Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Menyediakan layout repository non-secret dan validation contract statis sebagai
dasar implementasi konfigurasi monitoring berikutnya.

## 🌍 Background

TN-001 menyimpulkan bahwa repository `tomcat-monitoring` belum memiliki source
layout atau validator. Project owner menyetujui Implementation Gate yang
terbatas pada struktur non-secret, dokumentasi contract, dan validator statis.

## 📚 Scope

Aktivitas ini membuat README repository, direktori configuration dan validation
dengan documentation contract, `.gitignore`, dan `scripts/validate.sh`.
Validator hanya memeriksa struktur dan file contract yang dibuat pada aktivitas
ini. Aktivitas tidak membuat konfigurasi Prometheus, Telegraf, Alertmanager,
atau JMX Exporter yang executable; tidak membuat secret atau certificate; dan
tidak menjalankan dependency, build image, container, network, atau deployment.

## 📋 Prerequisites

- TM-ADR-0001 tetap menjadi architecture source of truth.
- TN-001 telah mengidentifikasi dependency dan open question yang belum
  diputuskan.
- Working tree `tomcat-monitoring` bersih sebelum implementation dimulai.

## ⚖️ Execution Decision

Implementasi membentuk interface repository terlebih dahulu agar setiap
configuration component kelak memiliki ownership dan validator yang jelas.
Keputusan ini menerapkan boundary pada TM-ADR-0001 tanpa menetapkan nilai
runtime baru.

## ⚙️ Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Prepare the Repository Contract** | Membuat dokumentasi, directory contract, dan validator baseline. |
| **Validate the Shell Syntax** | Memastikan validator Bash memiliki sintaks yang valid. |
| **Run the Baseline Validation** | Memeriksa layout dan kebijakan nama file sensitif. |
| **Verify the Change Integrity** | Memastikan perubahan tidak memiliki whitespace error. |

## ⚙️ Implementation

Repository `tomcat-monitoring` menerima artifact berikut:

| Artifact | Purpose |
| --- | --- |
| `.gitignore` | Mengecualikan nama file TLS, environment, secret directory, dan output validator lokal. |
| `README.md` | Menjelaskan ownership, status awal, batas secret, dan validation interface. |
| `config/` | Menetapkan contract documentation untuk JMX Exporter, Prometheus, Telegraf, dan Alertmanager tanpa configuration executable. |
| `validation/README.md` | Menetapkan pemisahan source, component, integration, dan deployment validation. |
| `scripts/validate.sh` | Memeriksa baseline layout, syntax validator, dan nama file material sensitif. |

Tidak ada YAML, certificate, credential, image, container, network, atau
deployment artifact yang dibuat.

## ⚙️ Execution Record

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Prepare the Repository Contract

Tambahkan artifact yang dijelaskan pada bagian Implementation, lalu jadikan
validator dapat dijalankan.

```bash
chmod 0755 /home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
```

!!! success "Expected Result"

    Contract repository tersedia dan validator memiliki permission executable.

**Actual Result:** artifact tersedia dan permission berhasil diterapkan.

**Evidence:** inventory Implementation dan command `chmod` yang selesai tanpa
error.

</div>

<div class="procedure-step" markdown>

### Validate the Shell Syntax

```bash
bash -n /home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
```

!!! success "Expected Result"

    Validator tidak memiliki syntax error.

**Actual Result:** pemeriksaan lulus tanpa output.

**Evidence:** command selesai dengan exit code `0`.

</div>

<div class="procedure-step" markdown>

### Run the Baseline Validation

```bash
/home/eddywiyatno/git/tomcat-monitoring/scripts/validate.sh
```

!!! success "Expected Result"

    File contract tersedia dan kebijakan nama file sensitif terpenuhi.

**Actual Result:** baseline validation lulus.

**Evidence:** output `Baseline validation passed`.

</div>

<div class="procedure-step" markdown>

### Verify the Change Integrity

```bash
git -C /home/eddywiyatno/git/tomcat-monitoring diff --check
```

!!! success "Expected Result"

    Tidak ada whitespace error pada perubahan repository.

**Actual Result:** pemeriksaan lulus tanpa output.

**Evidence:** command selesai dengan exit code `0`.

</div>

</div>

## ✅ Verification

| Criterion | Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- | --- |
| Bash syntax | `bash -n scripts/validate.sh` | Tidak ada syntax error | Passed | Command selesai tanpa output error. |
| Baseline layout | `./scripts/validate.sh` | File contract tersedia dan tidak ada nama file sensitif yang dilarang | Passed | Output: `Baseline validation passed: repository layout dan contract statis valid.` |
| Whitespace | `git diff --check` | Tidak ada whitespace error pada perubahan repository | Passed | Command selesai tanpa output error. |
| Runtime boundary | Review scope dan artifact | Tidak ada dependency, image build, test container, runtime, atau deployment | Passed | Aktivitas hanya membuat documentation contract dan validator Bash statis. |
| Handbook render | `mkdocs` availability check | Render navigation diperiksa bila tool tersedia | Not verified | Command `mkdocs` tidak tersedia; dependency tidak dipasang karena di luar scope. |

## 📝 Commands Executed

```bash
chmod 0755 scripts/validate.sh
bash -n scripts/validate.sh
./scripts/validate.sh
git diff --check
git -C devops-handbook diff --check -- docs/projects/tomcat-monitoring
command -v mkdocs
```

## 📝 Documentation Mapping

`README.md`, `config/`, `validation/`, dan `scripts/validate.sh` menjadi source
of truth implementation baseline di repository. Development setup dan phase
journal diperbarui untuk membedakan baseline layout dari configuration dan
runtime integration yang belum dibuat.

## 🧾 Outcome

Initial repository layout dan validation contract selesai dibuat serta lolos
static validation. Scope yang disetujui selesai tanpa scope change. Repository
masih belum memiliki configuration component executable atau evidence runtime;
keputusan health check, TLS, network, storage, dan deployment tetap terbuka.

## ⏭️ Next Steps

Component slice pertama telah dipilih dan diimplementasikan pada TN-003:
Telegraf memeriksa `TOMCAT_HEALTH_URL` dengan `GET`, HTTP `200`, body status
`UP`, timeout `5s`, interval `30s`, dan endpoint metrics internal
`:9273/metrics`.

Lanjutan yang diperlukan adalah component verification terisolasi: image
Telegraf resmi yang dipin, fixture HTTP sementara, network sementara tanpa host
port atau persistent volume, tiga kondisi health response, serta cleanup semua
resource test. Verification ini membuktikan parser dan behavior component,
bukan Prometheus scrape atau deployment runtime.

## 🔗 Related Documentation

- [TN-001 — Define Monitoring Integration Configuration and Validation Contract](TN-001-define-monitoring-integration-configuration-and-validation-contract.md)
- [TM-ADR-0001 — Adopt Embedded Monitoring Instrumentation for Apache Tomcat](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [Development Setup](../../development/setup.md)
- [Architecture](../../architecture/index.md)

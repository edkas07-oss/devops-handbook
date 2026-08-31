# TN-004 — Establish Diagnostic Service Repository Governance and Static Validation Baseline

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Membentuk governance, metadata dependency-free, dan static validation baseline
yang dapat dijalankan secara lokal pada repository `tomcat-diagnostic-service`.

## 🌍 Background

TN-003 menyelesaikan Decision Gate toolchain serta menetapkan repository dan
validation contract Diagnostic Service. Repository lokal tersedia pada branch
`main`, tetapi belum memiliki commit atau file. Project owner menyetujui TN-004
pada 2026-08-31 sebagai source baseline pertama tanpa dependency installation,
build, runtime, commit, atau push.

## 📚 Scope

Aktivitas yang disetujui mencakup pembuatan `AGENTS.md` sebagai governance
artifact pertama; metadata project dan package dependency-free; dokumentasi
usage contract; static validator; navigation jurnal; serta konsolidasi status
repository pada current-state Development.

Aktivitas tidak mencakup schema payload, migration, business logic, SQLite,
HTTP server, evidence adapter, SMTP, dependency installation, image lifecycle,
build, container, integration configuration, runtime test, cleanup, commit,
atau push.

## 📋 Prerequisites

| Prerequisite | State |
| --- | --- |
| TN-003 implementation plan | Completed |
| TM-ADR-0013 toolchain decision | Accepted |
| Repository `tomcat-diagnostic-service` | Available; no commits yet |
| Source and documentation scope | Approved by project owner on 2026-08-31 |

Rollback untuk perubahan source-only ini adalah review dan penghapusan exact
uncommitted files dalam scope TN-004. Tidak ada rollback runtime karena tidak
ada runtime state yang diubah; penghapusan tidak dijalankan tanpa destructive
authorization terpisah.

## ⚖️ Execution Decision

Baseline menerapkan [TM-ADR-0013](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md):
Node.js `24.18.0`, ESM JavaScript, dan dependency aplikasi minimum. TN ini
hanya menyiapkan contract repository; penggunaan `node:sqlite`, JSON Schema
validator, dan SMTP client tetap ditunda ke implementation TN pemiliknya.

## 🧭 Implementation Plan

| Stage | Plan |
| --- | --- |
| **Establish Repository Governance** | Membuat aturan ownership, boundary, authorization, verification, dan security repository. |
| **Create Static Baseline** | Membuat metadata dependency-free, README, package contract, serta validator tanpa network atau runtime. |
| **Verify and Consolidate Baseline** | Menjalankan pemeriksaan source-only dan memperbarui current-state serta journal evidence. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Establish Repository Governance

`AGENTS.md` dibuat sebagai artifact repository pertama. File tersebut
menetapkan ownership, source of truth, boundary Diagnostic Service terhadap
integration repository dan collector, approval, verification, Git, serta
security contract.

Tidak ada command mutation yang dijalankan pada tahap ini; file dibuat melalui
workspace patch setelah authorization diterima.

!!! success "Expected Result"

    Repository memiliki governance yang mencegah source implementation
    melampaui accepted Diagnostic MVP boundary.

**Actual Result:** `AGENTS.md` tersedia dan secara eksplisit melarang
automatic remediation, secret di Git, unapproved runtime action, serta
perluasan scope tanpa approval.

**Evidence:** `/home/eddywiyatno/git/tomcat-diagnostic-service/AGENTS.md`.

</div>

<div class="procedure-step" markdown>

### Create Static Baseline

Baseline berikut dibuat tanpa dependency installation atau network access:

- `README.md`, `PROJECT`, `VERSION`, dan non-secret `CONFIG`;
- ESM `package.json` serta dependency-free `package-lock.json`;
- `.gitignore` untuk dependency, coverage, database, environment, key, dan
  certificate artifact; serta
- `scripts/validate.sh` untuk metadata, JSON, shell syntax, forbidden
  dependency, dan limited secret-assignment checks.

File executable hanya mengubah mode static validator:

```bash
chmod 0755 scripts/validate.sh
```

!!! success "Expected Result"

    Seluruh artifact baseline tersedia, tidak memasang application dependency,
    dan validator dapat dijalankan langsung dari root repository.

**Actual Result:** Delapan contract files dan satu executable validator
tersedia. Package manifest dan lock tidak memiliki `dependencies` atau
`devDependencies`; planned source directory tidak dibuat dengan placeholder.

**Evidence:** `rg --files | sort` menampilkan hanya artifact baseline yang
disetujui.

</div>

<div class="procedure-step" markdown>

### Verify and Consolidate Baseline

Percobaan validator pertama gagal sebelum metadata validation karena
executable Node.js tidak tersedia pada host:

```bash
./scripts/validate.sh
```

```text
Validasi gagal: command wajib tidak tersedia: node
```

Dependency terhadap executable aplikasi tidak diperlukan untuk static
validation. Parser JSON kemudian diganti dengan Python 3 standard library;
scope dan contract application tidak berubah. Verification diulang:

```bash
./scripts/validate.sh
bash -n scripts/*.sh
if rg -n '[[:blank:]]+$' AGENTS.md README.md CONFIG PROJECT VERSION package.json package-lock.json .gitignore scripts/validate.sh; then exit 1; else echo 'trailing_whitespace=0'; fi
git diff --check
git status --short --branch
```

!!! success "Expected Result"

    Static validator dan shell syntax lulus, file tidak memiliki trailing
    whitespace atau diff error, dan Git hanya menampilkan exact uncommitted
    baseline TN-004.

**Actual Result:** Validator mencetak `Static validation passed`; shell syntax
dan whitespace checks lulus. Repository tetap `No commits yet` dan hanya
memiliki untracked files TN-004. Current-state Development serta journal
navigation diperbarui sesuai state tersebut.

**Evidence:** output verification 2026-08-31 dan diff terbatas pada
`tomcat-diagnostic-service` serta dokumentasi Tomcat Monitoring.

</div>

</div>

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| `./scripts/validate.sh` | Governance, metadata, lock, dependency boundary, shell syntax, dan limited secret scan konsisten | Passed setelah parser JSON menggunakan Python 3 standard library | `Static validation passed: governance and dependency-free baseline are consistent.` |
| `bash -n scripts/*.sh` | Seluruh Bash script valid secara syntax | Passed | Command selesai tanpa output |
| Trailing-whitespace scan | Tidak ada trailing whitespace pada baseline | Passed | `trailing_whitespace=0` |
| `git diff --check` | Tidak ada whitespace error pada tracked diff | Passed | Command selesai tanpa output; untracked files diperiksa terpisah oleh scan |
| Git scope review | Hanya exact baseline dan approved documentation yang berubah | Passed | Diagnostic repository berisi untracked baseline; handbook diff terbatas pada TN-004, navigation, phase index, dan Development |
| MkDocs strict render | Navigation dan Markdown dapat dirender oleh handbook toolchain | Not verified | `mkdocs=not-installed`; dependency tidak dipasang |
| Node.js application test | Application behavior diuji | Not verified | Application source dan dependency belum termasuk TN-004 |
| Build dan runtime test | Image serta component behavior diuji | Not verified | Build dan runtime berada di luar authorization |

## 🖥️ Commands Executed

Command implementation dan verification dicatat pada procedure step sesuai
chronology. Read-only discovery material yang menentukan scope menggunakan:

```bash
git status --short --branch
rg --files /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring /home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md
sed -n '1,520p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
sed -n '1,280p' docs/standards/documentation-standards.md
sed -n '1,1200p' docs/standards/engineering-journal-standards.md
sed -n '1,500p' docs/standards/writing-standards.md
sed -n '1,300p' /home/eddywiyatno/git/nodejs/AGENTS.md
sed -n '1,300p' /home/eddywiyatno/git/nodejs/README.md
sed -n '1,300p' /home/eddywiyatno/git/nodejs/PROJECT
sed -n '1,300p' /home/eddywiyatno/git/nodejs/VERSION
sed -n '1,300p' /home/eddywiyatno/git/nodejs/CONFIG
sed -n '1,300p' /home/eddywiyatno/git/nodejs/Containerfile
sed -n '1,300p' /home/eddywiyatno/git/nodejs/entrypoint.sh
```

Perintah `chmod` dan seluruh verification commands tercatat pada
`Create Static Baseline` serta `Verify and Consolidate Baseline`. Tidak ada
dependency, npm, build, Podman, container, cleanup, Git stage, commit, atau
push command yang dijalankan.

Final documentation review menggunakan:

```bash
git diff --check
tn='docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-004-establish-diagnostic-service-repository-governance-and-static-validation-baseline.md'
check_output="$(git diff --check --no-index /dev/null "$tn" || true)"
test -z "$check_output"
if command -v mkdocs >/dev/null; then mkdocs build --strict --site-dir /tmp/tm-tn004-mkdocs-site; else echo 'mkdocs=not-installed'; fi
rg -n 'TN-004-establish-diagnostic-service-repository-governance-and-static-validation-baseline.md' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md
git status --short --branch
```

## 🧾 Outcome

Governance, project/package metadata dependency-free, README, dan static
validator telah dibentuk serta memenuhi mandatory source-only verification.
Current-state Development mencatat bahwa artifact masih uncommitted dan
application implementation belum dimulai.

Percobaan validator pertama gagal karena executable Node.js tidak tersedia;
validator diperbaiki agar source-only JSON validation menggunakan Python 3
standard library dan re-verification lulus. Tidak ada application behavior,
SQLite durability, image, runtime health, notification, atau monitoring
integration yang diklaim terverifikasi.

## ⏭️ Next Steps

Aktivitas berikutnya adalah Technical Note terpisah untuk schema, versioned
migration, durable SQLite ingestion, dan queue boundary setelah scope serta
authorization implementation disetujui. Pemilihan exact JSON Schema validator
dilakukan pada TN pertama yang benar-benar memerlukannya. Image build tetap
menunggu immutable reusable Node.js base identity dan authorization terpisah.

## 🔗 Related Documentation

- [TN-003 — Define Diagnostic Service Repository Implementation and Validation Contract](TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Development](../../development/index.md)
- [TM-ADR-0013 — Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md)

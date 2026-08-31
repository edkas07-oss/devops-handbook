# TN-009 — Implement Application Configuration and Startup Lifecycle

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-01 |
| Recorded Date | 2026-09-01 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-01 |

## 🎯 Objective

Implement dan memverifikasi konfigurasi non-secret berversi, startup HTTPS
application, satu worker loop, Prometheus serialization, serta graceful
shutdown Diagnostic Service tanpa image build atau persistent runtime.

## 🌍 Background

TN-008 menutup HTTPS request dan SMTP delivery boundaries pada source commit
`bc4b7ae`. Application startup configuration, migration-before-readiness,
worker lifecycle, dan coordinated shutdown belum tersedia. Immutable Node.js
base identity juga belum tersedia sehingga image build tetap dilarang.

## 📚 Scope

Scope yang disetujui mencakup source dan documentation pada repository
`tomcat-diagnostic-service` serta `devops-handbook`; static, source, dan
ephemeral HTTPS/SQLite/fake-SMTP component verification; dan cleanup exact
target `/tmp/tomcat-diagnostic-tn009-component`.

Image build, `Containerfile`, persistent container atau volume, deployment,
`tomcat-monitoring` integration configuration, commit, dan push tidak termasuk
scope.

## 📋 Prerequisites

| Prerequisite | Expected state | Initial evidence |
| --- | --- | --- |
| Diagnostic Service revision | `bc4b7ae`, clean, aligned with `origin/main` | Confirmed at intake |
| Handbook revision | `f8ad89d`, clean, aligned with `origin/main` | `git rev-parse HEAD`, `git rev-parse origin/main`, dan `git status --short --branch` |
| TN-008 | `Completed`; 25 source tests and 2 socket tests passed | TN-008 Outcome dan Next Steps |
| Immutable Node.js base identity | Not available | Image build excluded |
| Implementation authorization | Approved for stated plan and exact temporary cleanup target | Project-owner response on 2026-09-01 |

## ⚖️ Execution Decision

Configuration menyimpan hanya operational values dan mounted-file references.
Secret, certificate, private key, dan environment-specific allowlist tetap di
luar Git. Startup membuka database dan menjalankan migration sebelum readiness,
kemudian mengaktifkan HTTPS dan tepat satu sequential worker loop. Shutdown
menghentikan acceptance terlebih dahulu dan menutup database terakhir.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Record the Approved Baseline** | Membuat live TN, mencatat authorization, revision, contract, dan exclusions. |
| **Implement Versioned Configuration** | Menambahkan JSON Schema serta loader untuk operational settings dan mounted-file secrets. |
| **Implement Startup and Metrics Lifecycle** | Menambahkan Prometheus serialization, startup orchestration, one-worker loop, dan graceful shutdown. |
| **Extend Tests and Validation** | Menambahkan startup failure/shutdown tests serta memperbarui validator dan public contract. |
| **Run Source Verification** | Menjalankan static validator dan source tests; mencatat failure serta resolution. |
| **Run Ephemeral Component Verification** | Membuktikan HTTPS, SQLite, fake SMTP, migration/readiness, dan shutdown memakai exact temporary target. |
| **Consolidate Documentation and Close** | Memperbarui current state, navigation, artifact manifest, matrix, cleanup evidence, dan outcome. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Record the Approved Baseline

Git status, repository instructions, TN-008 Outcome/Next Steps, documentation
standards, current-state contract, identities, validator, dan source interfaces
yang langsung terdampak direview. Kedua working tree bersih; baseline revision
cocok dengan handoff.

Commands pada repository `tomcat-diagnostic-service`:

```bash
pwd && git status --short --branch && sed -n '1,240p' AGENTS.md
rg --files -g '!node_modules/**' | sort && printf '\n--- package ---\n' && sed -n '1,220p' package.json && printf '\n--- identities ---\n' && for f in PROJECT VERSION CONFIG README.md scripts/validate.sh; do echo "### $f"; sed -n '1,260p' "$f"; done
for f in src/server/http-service.js src/adapters/sqlite-repository.js src/application/diagnostic-worker.js src/application/health-metrics.js src/adapters/smtp-adapter.js src/application/target-registry.js; do echo "### $f"; sed -n '1,320p' "$f"; done
for f in src/adapters/application-health-adapter.js src/adapters/prometheus-adapter.js src/adapters/local-file-evidence-adapter.js src/adapters/collector-spool-adapter.js src/application/result-renderer.js src/server/webhook-schema.js src/application/ingest-alertmanager.js test/integration/diagnostic-worker.test.js test/unit/http-service.test.js; do echo "### $f"; sed -n '1,340p' "$f"; done
sed -n '1,280p' src/domain/tomcat-down-engine.js && sed -n '1,220p' src/application/bounded-queue.js && sed -n '1,300p' test/component/secure-service-component.test.js && rg -n "HealthMetrics|recordNotification|saveCanonicalResult|renderResult|SmtpAdapter" src test
```

Commands pada repository `devops-handbook`:

```bash
git status --short --branch && sed -n '1,260p' AGENTS.md && rg -n "TN-008|Outcome|Next Steps" . --glob '*.md' --glob '!node_modules/**'
sed -n '1,240p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-008-implement-secure-service-and-smtp-delivery-boundaries.md && sed -n '1,180p' docs/projects/tomcat-monitoring/diagnostic-mvp/index.md && sed -n '1,180p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md && sed -n '1,220p' docs/standards/documentation-standards.md && sed -n '1,220p' docs/standards/writing-standards.md
git rev-parse HEAD && git rev-parse origin/main && git status --short --branch && sed -n '520,1120p' docs/standards/engineering-journal-standards.md && sed -n '220,700p' docs/standards/documentation-standards.md && sed -n '220,520p' docs/standards/writing-standards.md
```

!!! success "Expected Result"

    Authorization, revision, prerequisite, approved scope, dan exclusions
    tercatat sebelum source atau configuration berubah.

**Actual Result:** Passed. Live record dibuat sebelum implementation source.

</div>

<div class="procedure-step" markdown>

### Implement Versioned Configuration

Application JSON Schema v1 dan loader ditambahkan. Schema membatasi listen
address, SQLite path, mounted TLS/token/allowlist paths, SMTP endpoint dan
optional credential-file references, queue, timeout, serta request limit.
Loader menolak unknown field, path non-absolute/non-normalized, invalid atau
empty allowlist, dan empty secret file tanpa memasukkan nilainya ke error.

Perubahan dilakukan melalui `apply_patch`; tidak ada shell command yang
menulis file. Patch pada tahap ini membuat schema dan loader, lalu patch
lanjutan memperbaiki project-root resolution. Inspection command yang
dijalankan setelah patch test awal gagal mencocokkan context adalah:

```bash
sed -n '1,120p' test/unit/health-metrics.test.js
```

!!! success "Expected Result"

    Runtime configuration tervalidasi dan secret hanya dibaca dari mounted
    file; tidak ada credential, certificate, atau target environment di Git.

**Actual Result:** Passed melalui configuration tests dan sensitive-artifact
scan. Target allowlist tetap file milik integration repository saat deployment.

</div>

<div class="procedure-step" markdown>

### Implement Startup and Metrics Lifecycle

`DiagnosticApplication` membuka SQLite sehingga migration selesai sebelum
listen/readiness, membentuk HTTPS handler, dan menjalankan satu sequential
worker loop. `SIGTERM`/`SIGINT` masuk melalui `src/main.js`. Shutdown mengubah
acceptance serta readiness ke false, menutup listener, menghentikan worker,
kemudian menutup database. Health model diserialisasi menjadi Prometheus text
0.0.4 dengan deterministic ordering, escaped labels, dan valid-name checks.

Lifecycle, metrics serializer, HTTP acceptance/request-limit changes, SMTP
configuration wiring, dan entrypoint diterapkan melalui `apply_patch`; tidak
ada shell command yang menulis source pada tahap ini.

!!! success "Expected Result"

    Startup dan shutdown memiliki urutan yang dapat diuji; metrics merupakan
    valid bounded text tanpa target-sensitive labels.

**Actual Result:** Passed. Lifecycle tests membuktikan startup failure menutup
database, tepat satu worker loop berjalan, dan database ditutup terakhir.

</div>

<div class="procedure-step" markdown>

### Extend Tests and Validation

Validator, package startup contract, README, unit/integration tests, dan
component startup scenario diperbarui mengikuti artifact baru.

README, validator, package metadata/lock, dan test files diterapkan melalui
`apply_patch`. Source contract direview dengan command berikut sebelum README
patch disesuaikan terhadap text aktual:

```bash
sed -n '1,180p' README.md
sed -n '1,55p' package-lock.json && git status --short && git diff --check && git diff --stat
```

!!! success "Expected Result"

    Static contract menolak artifact hilang atau startup metadata yang tidak
    konsisten; public usage menjelaskan mounted-file boundary.

**Actual Result:** Passed. Validator mencakup schema, loader, lifecycle,
entrypoint, serta exact `start`/`bin` contract.

</div>

<div class="procedure-step" markdown>

### Run Source Verification

Static validation pertama lulus, tetapi local `npm test` gagal sebelum test
karena `npm` tidak tersedia. Percobaan Podman dalam sandbox kemudian gagal
sebelum container start karena `/run/user/1000/libpod` read-only. Approved
runtime execution mengatasi environment boundary tersebut.

Regression pertama lulus 30 tests tetapi proses bertahan sekitar 60 detik.
Evidence menunjukkan losing polling timer masih menahan event loop. Timer
diubah menjadi explicitly cleared/resolved saat shutdown. Direct signal wiring
test kemudian ditambahkan; rerun final lulus 31/31 dalam 295 ms.

Commands dijalankan berurutan dari repository `tomcat-diagnostic-service`:

```bash
./scripts/validate.sh && npm test
./scripts/validate.sh && podman run --rm --name tomcat-diagnostic-tn009-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
podman run --rm --name tomcat-diagnostic-tn009-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
./scripts/validate.sh && podman run --rm --name tomcat-diagnostic-tn009-source-rerun --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
./scripts/validate.sh && bash -n scripts/*.sh && podman run --rm --name tomcat-diagnostic-tn009-final-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
./scripts/validate.sh && bash -n scripts/*.sh && podman run --rm --name tomcat-diagnostic-tn009-signal-source --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app localhost/nodejs:24.18.0 npm test
./scripts/validate.sh && bash -n scripts/*.sh && git diff --check && git status --short --branch
```

Command pertama gagal pada `npm: command not found`. Command kedua gagal
sebelum container start karena rootless Podman state read-only. Command ketiga
adalah rerun command container yang sama dengan approved external runtime
access. Output process yang masih berjalan dipoll melalui execution-session
API; polling tersebut bukan shell command.

!!! success "Expected Result"

    Validator, Bash syntax, dan seluruh source tests lulus pada current working
    tree tanpa network dependency installation.

**Actual Result:** Passed. Static validation dan Bash syntax lulus; 31 tests
passed, 0 failed, 0 skipped.

</div>

<div class="procedure-step" markdown>

### Run Ephemeral Component Verification

Exact directory `/tmp/tomcat-diagnostic-tn009-component` menampung one-day test
certificate, mounted token/allowlist, application JSON, dan SQLite database.
Final rerun menggunakan existing local `localhost/nodejs:24.18.0`; tidak ada
image build.

Initial component cycle:

```bash
test ! -e /tmp/tomcat-diagnostic-tn009-component && mkdir /tmp/tomcat-diagnostic-tn009-component && openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -addext subjectAltName=DNS:localhost,IP:127.0.0.1 -keyout /tmp/tomcat-diagnostic-tn009-component/server.key -out /tmp/tomcat-diagnostic-tn009-component/server.crt
podman run --rm --name tomcat-diagnostic-tn009-component --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -v /tmp/tomcat-diagnostic-tn009-component:/tmp/tn009:Z -w /app -e TN008_TLS_KEY=/tmp/tn009/server.key -e TN008_TLS_CERT=/tmp/tn009/server.crt -e TN009_COMPONENT_DIR=/tmp/tn009 localhost/nodejs:24.18.0 npm run test:component
rm -r /tmp/tomcat-diagnostic-tn009-component && test ! -e /tmp/tomcat-diagnostic-tn009-component && ! find . -type f \( -name '*.key' -o -name '*.crt' -o -name '*.pem' -o -name '*.sqlite' -o -name '*.sqlite-wal' -o -name '*.sqlite-shm' \) -print -quit | grep -q .
```

Final component cycle setelah source adjustment:

```bash
test ! -e /tmp/tomcat-diagnostic-tn009-component && mkdir /tmp/tomcat-diagnostic-tn009-component && openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -addext subjectAltName=DNS:localhost,IP:127.0.0.1 -keyout /tmp/tomcat-diagnostic-tn009-component/server.key -out /tmp/tomcat-diagnostic-tn009-component/server.crt
podman run --rm --name tomcat-diagnostic-tn009-final-component --userns=keep-id -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -v /tmp/tomcat-diagnostic-tn009-component:/tmp/tn009:Z -w /app -e TN008_TLS_KEY=/tmp/tn009/server.key -e TN008_TLS_CERT=/tmp/tn009/server.crt -e TN009_COMPONENT_DIR=/tmp/tn009 localhost/nodejs:24.18.0 npm run test:component
rm -r /tmp/tomcat-diagnostic-tn009-component && test ! -e /tmp/tomcat-diagnostic-tn009-component && ! find . -type f \( -name '*.key' -o -name '*.crt' -o -name '*.pem' -o -name '*.sqlite' -o -name '*.sqlite-wal' -o -name '*.sqlite-shm' \) -print -quit | grep -q .
```

!!! success "Expected Result"

    Trusted HTTPS, migration-before-readiness, graceful shutdown, SQLite
    migration state, dan fake SMTP socket lulus tanpa persistent resource.

**Actual Result:** Passed. 3 tests passed in 214 ms: application startup/
SQLite/shutdown, TLS socket boundary, dan multipart delivery ke fake SMTP.

</div>

<div class="procedure-step" markdown>

### Consolidate Documentation and Close

README, Diagnostic MVP current state, Architecture, Development,
Infrastructure, phase index, `.pages`, dan TN-009 diperbarui. Klaim dibatasi
pada source serta ephemeral component layer.

Documentation mapping dan context inspection pada repository
`devops-handbook`:

```bash
rg -n "Diagnostic Service|application startup|configuration|HTTP server|runtime not|TN-008|bc4b7ae" docs/projects/tomcat-monitoring/{index.md,architecture/index.md,development/index.md,infrastructure/index.md,operations/index.md,diagnostic-mvp/index.md} docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/{index.md,.pages} mkdocs.yml
sed -n '1,30p' docs/projects/tomcat-monitoring/diagnostic-mvp/index.md && sed -n '94,110p' docs/projects/tomcat-monitoring/diagnostic-mvp/index.md && sed -n '32,44p' docs/projects/tomcat-monitoring/development/index.md && sed -n '74,84p' docs/projects/tomcat-monitoring/development/index.md && sed -n '112,126p' docs/projects/tomcat-monitoring/development/index.md
rg -n "30|247|Thirty|source tests|signal-source" docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md
sed -n '300,314p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md
sed -n '314,320p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md
```

Final source-repository review:

```bash
git diff --check && ./scripts/validate.sh && bash -n scripts/*.sh && test ! -e /tmp/tomcat-diagnostic-tn009-component && git status --short --branch && git diff --stat
git rev-parse HEAD && git rev-parse origin/main && git diff --check && test ! -e /tmp/tomcat-diagnostic-tn009-component && git status --short --branch
```

Final handbook review:

```bash
git diff --check && git status --short --branch && command -v mkdocs || true && rg -n "TN-009|Status \| Completed|30 regression|3 ephemeral|application startup" docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot docs/projects/tomcat-monitoring/{diagnostic-mvp/index.md,development/index.md,architecture/index.md,infrastructure/index.md} && test -f docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md
git diff --check && test -f docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md && rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md && rg -n 'TN-009' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages && git status --short --branch && git diff --stat
git rev-parse HEAD && git rev-parse origin/main && git diff --check && rg -n '^\| Status \| Completed \|$|31 passed|3 passed|MkDocs render|Not verified|commit, atau push' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-009-implement-application-configuration-and-startup-lifecycle.md && git status --short --branch
```

Documentation changes dilakukan melalui `apply_patch`; tidak ada shell command
yang menulis handbook.

Source-control handoff dijalankan setelah technical closure. Initial staging
command gagal pada `.git/index.lock` read-only di sandbox, lalu exact staging
diulang dengan approved repository access. README wording yang menyebut
`working tree` ditemukan usang setelah commit pertama dan diperbaiki melalui
`apply_patch`; commit kemudian diamend sehingga final source identity menjadi
`a398349`.

```bash
git add README.md package.json package-lock.json scripts/validate.sh config/schemas/application-config-v1.schema.json src/adapters/smtp-adapter.js src/application/application.js src/application/config-loader.js src/application/health-metrics.js src/main.js src/server/http-service.js test/component/application-startup-component.test.js test/integration/application-lifecycle.test.js test/unit/config-loader.test.js test/unit/health-metrics.test.js test/unit/main.test.js && git diff --cached --check && git status --short && git diff --cached --stat
git add README.md package.json package-lock.json scripts/validate.sh config/schemas/application-config-v1.schema.json src/adapters/smtp-adapter.js src/application/application.js src/application/config-loader.js src/application/health-metrics.js src/main.js src/server/http-service.js test/component/application-startup-component.test.js test/integration/application-lifecycle.test.js test/unit/config-loader.test.js test/unit/health-metrics.test.js test/unit/main.test.js
git diff --cached --check && git status --short && git diff --cached --stat
git commit -m "feat(diagnostic-service): add configuration startup lifecycle"
git diff --check && git add README.md && git diff --cached --check && git commit --amend --no-edit
```

!!! success "Expected Result"

    Current state, navigation, artifact/test manifest, cleanup, dan
    reproduction boundary konsisten dengan working tree yang diuji.

**Actual Result:** Passed setelah final documentation/source diff review,
relative-navigation inspection, dan whitespace validation.

</div>

</div>

## ✅ Verification

| Layer | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| Static validation | Required artifacts, metadata, dependency, shell, dan security boundaries konsisten | Passed | `./scripts/validate.sh`; `bash -n scripts/*.sh` |
| Source/unit-local integration | Existing dan TN-009 behavior lulus | 31 passed; 0 failed/skipped; 295 ms | Final `npm test` dalam ephemeral Node.js container |
| Startup failure | Readiness tetap false dan migrated database ditutup | Passed | `application-lifecycle.test.js` |
| Graceful shutdown | Acceptance/readiness berhenti; one worker berhenti sebelum database close | Passed | Ordered lifecycle assertions |
| Prometheus text | Deterministic serialization dan unsafe identity rejection | Passed | `health-metrics.test.js` |
| Socket component | HTTPS, SQLite migration/readiness/shutdown, dan fake SMTP lulus | 3 passed; 0 failed/skipped; 214 ms | Final `npm run test:component` |
| Image test | Excluded | Not run | Immutable base identity belum tersedia |
| Persistent runtime/integration | Excluded | Not run | Tidak ada container/volume/deployment |
| Cleanup | Exact temporary target dan sensitive/generated artifacts absent | Passed | `test ! -e` dan bounded `find` scan |
| Documentation source | Whitespace, TN headings, navigation entry, links-in-scope, dan file presence konsisten | Passed | `git diff --check`, `rg`, dan `test -f` |
| MkDocs render | Site dapat dirender | Not verified | `command -v mkdocs` tidak menemukan CLI; dependency tidak dipasang |

## ⚙️ Commands Executed

| Tahap | Lokasi command aktual |
| --- | --- |
| Record the Approved Baseline | Procedure step **Record the Approved Baseline** |
| Implement Versioned Configuration | Procedure step **Implement Versioned Configuration** |
| Implement Startup and Metrics Lifecycle | Tidak ada shell command; perubahan memakai `apply_patch` |
| Extend Tests and Validation | Procedure step **Extend Tests and Validation** |
| Run Source Verification | Procedure step **Run Source Verification** |
| Run Ephemeral Component Verification | Procedure step **Run Ephemeral Component Verification** |
| Consolidate Documentation and Close | Procedure step **Consolidate Documentation and Close** |

Section ini hanya menjadi indeks. Seluruh command aktual ditempatkan pada
procedure step tempat command tersebut dijalankan.

## 📁 Artifact Manifest

| Path | Responsibility |
| --- | --- |
| `config/schemas/application-config-v1.schema.json` | Versioned non-secret application contract |
| `src/application/config-loader.js` | Schema/path/allowlist validation dan mounted-file loading |
| `src/application/application.js` | Migration, HTTPS, one-worker, readiness, dan shutdown lifecycle |
| `src/main.js` | `--config` startup serta SIGTERM/SIGINT handling |
| `src/application/health-metrics.js` | Prometheus text serialization |
| `src/server/http-service.js` | Configurable request limit, acceptance gate, metrics media type |
| `src/adapters/smtp-adapter.js` | Optional mounted SMTP authentication and secure mode |
| `test/unit/config-loader.test.js` | Configuration dan secret-redaction scenarios |
| `test/unit/main.test.js` | Shared idempotent SIGTERM/SIGINT shutdown path |
| `test/integration/application-lifecycle.test.js` | Startup failure dan ordered shutdown |
| `test/component/application-startup-component.test.js` | Actual HTTPS/SQLite startup component scenario |
| `README.md`, `scripts/validate.sh`, `package.json`, `package-lock.json` | Public, validation, dan startup contracts |

## 🧪 Test-Scenario Matrix

| Scenario | Layer | Result |
| --- | --- | --- |
| Valid schema and mounted secret/allowlist files | Unit | Passed |
| Invalid schema does not expose mounted secret | Unit | Passed |
| Deterministic metrics and invalid identity rejection | Unit | Passed |
| Listen/startup failure keeps not-ready and closes database | Local integration | Passed |
| Exactly one worker loop and database-last shutdown | Local integration | Passed |
| Configurable HTTP request limit and acceptance gate regression | Unit | Passed |
| Application config, three migrations, HTTPS readiness, graceful close | Socket component | Passed |
| Trusted/untrusted TLS behavior | Socket component | Passed |
| Multipart message reaches fake SMTP listener | Socket component | Passed |
| Image/persistent/runtime integration | Excluded | Not run |

## 🧹 Cleanup Evidence

Approved exact target `/tmp/tomcat-diagnostic-tn009-component` dibuat dua kali
untuk initial dan final component runs, lalu dihapus setelah masing-masing run.
Final `test ! -e` passed. Repository scan menemukan nol `.key`, `.crt`, `.pem`,
`.sqlite`, `.sqlite-wal`, atau `.sqlite-shm` artifact.

## 🧭 Reproduction Boundary

Baseline source adalah `bc4b7ae`; final TN-009 source adalah commit `a398349`.
Reproduction memerlukan source commit tersebut, existing local
`localhost/nodejs:24.18.0`, OpenSSL certificate setup, source command, component
command, dan exact cleanup di atas. Image, persistent runtime, Mailpit aktual,
deployment, serta end-to-end monitoring tidak termasuk klaim.

## 🧾 Outcome

Versioned configuration, mounted-file secret boundary, application startup,
migration-before-readiness, exactly-one worker loop, Prometheus text, startup
failure handling, dan graceful shutdown telah diimplementasikan. Thirty-one
source tests dan three ephemeral component tests passed; exact temporary
resources dibersihkan. MkDocs render tidak diverifikasi karena CLI tidak
tersedia. Source telah dicommit sebagai `a398349`; tidak ada image build,
persistent runtime, atau push.

## ⏭️ Next Steps

Setelah immutable Node.js base identity diterima, rencanakan image lifecycle
dan disposable image-level verification sebagai authorization terpisah.

## 🔗 Related Documentation

- [TN-008](TN-008-implement-secure-service-and-smtp-delivery-boundaries.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Non-Functional and Security Contract](../../diagnostic-mvp/non-functional-and-security-contract.md)
- [SQLite Lifecycle Contract](../../diagnostic-mvp/sqlite-lifecycle-contract.md)

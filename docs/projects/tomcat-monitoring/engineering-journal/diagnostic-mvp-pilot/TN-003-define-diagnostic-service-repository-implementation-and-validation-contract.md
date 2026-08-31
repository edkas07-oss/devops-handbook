# TN-003 — Define Diagnostic Service Repository Implementation and Validation Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write — documentation only |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Menghasilkan implementation plan, source boundary, dan validation interface
yang dapat disetujui untuk repository `tomcat-diagnostic-service` sebelum
source implementation dimulai.

## 🌍 Background

TN-001 menerima arsitektur Diagnostic MVP dan menetapkan repository
`tomcat-diagnostic-service` sebagai pemilik source aplikasi, dependency lock,
image lifecycle, migration, dan component test. TN-002 menyelesaikan
konsolidasi keputusan tersebut ke current-state documentation. Repository
lokal dan remote sekarang tersedia, tetapi branch `main` belum memiliki commit,
source, governance, validation interface, atau image.

`GAP-001` mewajibkan approved repository plan, source contract, dan validation
interface sebelum service implementation. Approval sesi ini hanya mencakup
documentation dan planning; ia tidak mengizinkan source, dependency, build,
runtime, commit, atau push.

## 📚 Scope

Aktivitas mencakup bounded discovery terhadap contract Diagnostic MVP,
repository kosong, dan reusable Node.js runtime; assessment alternatif
toolchain; recommendation repository layout, dependency boundary, validation
layers, implementation sequence, serta readiness gate.

Aktivitas tidak mencakup perubahan pada `tomcat-diagnostic-service`, pembuatan
source atau scaffold, pemasangan dependency, image build, container, network,
volume, database, collector, monitoring configuration, runtime test, cleanup,
commit, atau push.

## 📥 Inputs

- Diagnostic MVP hanya menerima `TomcatDown`; automatic remediation,
  Integration Bridge, dan TrueSight tidak aktif.
- Webhook harus melakukan authentication, validation, normalization, dan
  durable SQLite commit sebelum mengembalikan `202`.
- Service menggunakan satu worker, queue maksimum 50, timeout 60 detik, dan
  bounded evidence dengan target identity yang berasal dari local allowlist.
- SQLite menggunakan WAL, automatic forward migration, satu logical writer,
  target 100 MiB, dan hard boundary 250 MiB.
- Prometheus query menggunakan total timeout lima detik, satu attempt tanpa
  retry dalam satu diagnostic run, lalu processing berlanjut dengan evidence
  source lain dan menandai metrics sebagai unavailable.
- Plain-text dan HTML email menggunakan tujuh bagian berurutan dari alert
  summary sampai rule serta diagnostic traceability.
- Repository aplikasi memiliki source, dependency lock, image lifecycle,
  migrations, dan component tests. Integration configuration dan end-to-end
  verification tetap dimiliki repository `tomcat-monitoring`.

## 🔍 Findings

### Repository readiness

1. `tomcat-diagnostic-service` tersedia pada branch `main`, tetapi tidak
   memiliki commit maupun file. Remote tracking yang tercetak sebagai
   `origin/main [gone]` konsisten dengan remote repository yang belum memiliki
   initial commit.
2. Repository kosong belum memiliki `AGENTS.md`; governance harus dibuat
   sebagai artifact pertama sebelum source aplikasi.
3. `tomcat-monitoring`, `devops-handbook`, dan reusable `nodejs` runtime berada
   pada worktree bersih. Tidak ada perubahan pengguna yang beririsan.

### Contract pressure on the implementation

Implementation harus memisahkan webhook acceptance transaction dari
asynchronous diagnostic work, tetapi tetap memakai satu logical writer. Ia
memerlukan validation terhadap untrusted JSON, deterministic rule fixtures,
versioned schema dan migrations, HTTPS, bearer authentication, SMTP rendering,
bounded filesystem reads, health endpoints, serta metrics tanpa sensitive
labels.

Source layout harus membuat boundary tersebut dapat diuji secara terpisah.
HTTP handler tidak boleh langsung memiliki path, query, SQLite, renderer, atau
SMTP detail; adapter memperoleh target hanya dari validated local
configuration.

### Operator refinement before commit

Review project owner menerima total Prometheus timeout lima detik dengan satu
attempt tanpa retry pada satu diagnostic run. Timeout tidak membatalkan
diagnosis; log, crash artifact, application health, dan collector spool tetap
diproses, sementara canonical result mencatat Prometheus sebagai `timeout`.

Review yang sama menerima struktur email tujuh bagian: Alert Summary,
Diagnostic Assessment, Key Metrics Snapshot, Correlated Log Evidence,
Unavailable or Contradicting Evidence, Recommended Operator Actions, serta
Rule and Diagnostic Traceability. Log section menggunakan correlated sanitized
excerpt, bukan arbitrary latest-log tail. RCA wording hanya digunakan jika
classification mengizinkan klaim tersebut.

### Reusable Node.js runtime

Repository `nodejs` menyediakan pinned local base image
`localhost/nodejs:24.18.0`, working directory `/app`, non-root user, npm, dan
signal-forwarding entrypoint. Ia sengaja tidak menyediakan framework,
application dependency, port, health check, atau default command sehingga
seluruh application contract tetap dimiliki Diagnostic Service.

Node.js `24.18.0` menyediakan stable built-in test runner dan built-in HTTPS.
Built-in `node:sqlite` tersedia tanpa experimental flag, tetapi upstream masih
memberinya stability `1.2` atau release candidate. Status tersebut merupakan
risiko compatibility yang harus diterima secara eksplisit jika dipakai untuk
durable pilot state.

## 🔀 Alternatives

| Alternative | State | Assessment |
| --- | --- | --- |
| Node.js 24 ESM JavaScript, native HTTPS/test, dan built-in `node:sqlite` | Selected and accepted | Selaras dengan reusable runtime lokal dan meminimalkan native application dependency; risiko release-candidate `node:sqlite` diterima dengan exact pin, adapter isolation, dan mandatory tests |
| Node.js 24 dengan third-party SQLite binding | Assessed | SQLite binding lebih matang, tetapi menambah native dependency, Alpine build toolchain, supply-chain surface, dan image complexity |
| Python dengan standard-library SQLite | Assessed | SQLite matang dan implementation langsung, tetapi belum ada reusable runtime contract lokal dan menambah runtime ownership serta lifecycle baru |
| Go dengan SQLite driver | Assessed | Binary dan resource control kuat, tetapi migration, SMTP, schema validation, serta SQLite driver menambah toolchain baru tanpa reusable repository contract |

TypeScript tidak direkomendasikan untuk baseline pertama. Ia menambahkan
compile stage dan generated artifact sebelum contract behavior terbukti.
Versioned JSON schema, runtime validation, JSDoc, module boundary, dan fixture
tests tetap diwajibkan agar plain ESM JavaScript tidak mengurangi validation
coverage.

## ⚠️ Risks

| Risk | State | Treatment |
| --- | --- | --- |
| `node:sqlite` berubah selama Node.js 24 lifecycle | Open | Pin exact base runtime; bungkus SQLite pada satu adapter; tambahkan migration, restart, WAL, deduplication, dan capacity contract tests |
| Synchronous SQLite API menahan event loop | Mitigated by design | Satu worker dan satu logical writer sesuai accepted contract; batasi transaction dan larang evidence collection atau SMTP di dalam transaction |
| Minimal-dependency approach menghasilkan handwritten validation yang rapuh | Open | Gunakan versioned JSON Schema dan pilih satu validator dependency yang exact-pinned pada implementation gate |
| Satu TN implementasi menjadi terlalu luas | Mitigated by plan | Pecah delivery berdasarkan independently verifiable repository, persistence, ingestion, diagnosis, dan delivery boundaries |
| Runtime build mengonsumsi mutable local tag | Open | Application `Containerfile` harus menggunakan exact approved base identity; digest atau publication identity ditetapkan sebelum build authorization |
| Prometheus lambat menghabiskan global diagnostic budget | Mitigated by accepted contract | Gunakan total timeout lima detik dan satu attempt; lanjutkan source lain serta render unavailable marker |
| Email menyatakan RCA lebih kuat daripada evidence | Mitigated by accepted contract | Renderer mengikuti classification/confidence dan menampilkan limitation serta contradicting/unavailable evidence |

## 🧭 Recommendation

Gunakan Node.js `24.18.0` LTS dengan ESM JavaScript dan image turunan dari
reusable Node.js runtime. Gunakan built-in HTTPS dan `node:test`; gunakan
`node:sqlite` hanya setelah project owner menerima risiko release-candidate.
Pilih satu JSON Schema validator dan satu SMTP client sebagai application
dependencies yang exact-pinned melalui `package-lock.json`; jangan menambahkan
web framework, ORM, queue broker, template engine, atau general-purpose host
control dependency pada baseline.

### Repository source contract

```text
tomcat-diagnostic-service/
├── AGENTS.md
├── README.md
├── PROJECT
├── VERSION
├── CONFIG
├── Containerfile
├── package.json
├── package-lock.json
├── config/
│   └── schemas/
├── migrations/
├── src/
│   ├── adapters/
│   ├── application/
│   ├── domain/
│   └── server/
├── test/
│   ├── fixtures/
│   ├── integration/
│   └── unit/
└── scripts/
    ├── build.sh
    ├── clean.sh
    ├── run.sh
    ├── test.sh
    └── validate.sh
```

`domain` memiliki normalized evidence, rule, canonical result, dan lifecycle
semantics tanpa network atau filesystem access. `application` mengorkestrasi
use case dan queue. `adapters` memiliki SQLite, Prometheus, bounded file/spool,
dan SMTP implementation. `server` memiliki HTTPS, authentication, request
limit, schema validation, health, readiness, dan metrics interfaces.

### Validation interface

| Interface | Boundary | Expected result |
| --- | --- | --- |
| `./scripts/validate.sh` | Required files, metadata consistency, shell syntax, package lock, schema fixtures, forbidden dependency/import patterns, dan secret scan terbatas | Source contract valid tanpa network atau runtime container |
| `npm test` | Unit serta local integration tests dengan temporary SQLite dan fixtures | Determinism, validation, migration, idempotency, isolation, bounds, five-second Prometheus fallback, ordered renderer, dan disabled-integration behavior lulus |
| `./scripts/build.sh` | Application image derived from exact approved Node.js base | Versioned local image terbangun sebagai non-root artifact |
| `./scripts/test.sh` | Disposable component test | Startup, liveness/readiness, HTTPS/auth, commit-before-`202`, restart persistence, metrics, resource boundary, dan exact cleanup terbukti |

`validate.sh` dan `npm test` menjadi interface minimum sebelum CI/CD. Build dan
component test tidak termasuk authorization TN ini maupun implementation TN
pertama.

### Implementation sequence

```text
Decision Gate: toolchain and node:sqlite risk
            |
            v
Repository governance and static validation baseline
            |
            v
Schema, migrations, durable ingestion, and queue
            |
            v
Target isolation, evidence adapters, and TomcatDown engine
            |
            v
Canonical result, Mailpit renderer, health, and metrics
            |
            v
Image build and disposable component verification
            |
            v
tomcat-monitoring integration and end-to-end verification
```

Setiap tahap setelah Decision Gate memerlukan Technical Note dan authorization
yang sesuai. Collector, physical TLS/token lifecycle, production deployment,
dan end-to-end failure injection tetap berada di luar repository bootstrap.

## ❓ Open Questions

| Question | State | Owner | Closure condition | Blocked activity |
| --- | --- | --- | --- | --- |
| Apakah Node.js `24.18.0` ESM JavaScript diterima sebagai service toolchain? | Answered — accepted 2026-08-31 | Project owner | Closed by explicit acceptance and TM-ADR-0013 | Tidak lagi memblokir planning source implementation |
| Apakah risiko release-candidate `node:sqlite` diterima untuk pilot dengan exact runtime pin dan adapter isolation? | Answered — accepted 2026-08-31 | Project owner | Closed by explicit risk acceptance and TM-ADR-0013 | Tidak lagi memblokir persistence design |
| JSON Schema validator dan SMTP client mana yang dipin? | Deferred | Service owner / engineer | Upstream version/security review pada implementation TN yang pertama memerlukannya | Schema validator dan notification implementation; tidak memblokir governance baseline |
| Apa immutable identity reusable Node.js base? | Open | Runtime owner / engineer | Approved version plus digest atau published artifact identity | Image build; tidak memblokir source baseline |

## ⚖️ Decision Handoff

Project owner menerima dua recommendation yang saling terkait pada 2026-08-31:

1. Node.js `24.18.0` dengan plain ESM JavaScript, built-in HTTPS/test, tanpa web
   framework atau ORM; dan
2. built-in `node:sqlite` untuk pilot dengan exact runtime pin, isolated
   adapter, serta mandatory migration/restart/WAL/capacity tests.

Decision Gate selesai. Acceptance menyelesaikan planning objective TN-003 dan
mengizinkan penyusunan TN implementation berikutnya. Persetujuan tersebut
belum mengizinkan perubahan source.

Timeout Prometheus lima detik dan struktur email tujuh bagian telah diterima
project owner pada 2026-08-31. Keduanya tidak lagi menjadi bagian Decision Gate
toolchain.

## 📚 Scope Changes

| Element | Record |
| --- | --- |
| Reason | Review project owner sebelum commit menemukan bahwa timeout Prometheus dan urutan canonical email belum cukup eksplisit |
| Impact | Scope dokumentasi diperluas ke rule specification, notification contract, requirements traceability, dan record TN-003 |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |
| Boundary | Tidak mengizinkan source, dependency, build, runtime, commit, atau push |

Project owner kemudian menerima Decision Gate Node.js dan `node:sqlite` serta
memberikan authorization commit dokumentasi pada 2026-08-31. Authorization
tersebut tidak memperluas scope ke source atau runtime.

## 💻 Commands Executed

### Standards and repository discovery

```bash
git status --short --branch
sed -n '1,360p' docs/standards/documentation-standards.md
sed -n '1,520p' docs/standards/engineering-journal-standards.md
sed -n '521,1100p' docs/standards/engineering-journal-standards.md
sed -n '1,430p' docs/standards/writing-standards.md
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,240p' docs/standards/engineering-journal-standards.md
sed -n '241,480p' docs/standards/engineering-journal-standards.md
sed -n '481,720p' docs/standards/engineering-journal-standards.md
sed -n '721,940p' docs/standards/engineering-journal-standards.md
sed -n '941,1089p' docs/standards/engineering-journal-standards.md
sed -n '1,120p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages
sed -n '1,180p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md
```

### Contract and alternative discovery

```bash
rg -n -i 'node\.js|nodejs|typescript|javascript|python|go|fastify|express|runtime|dependency|package|validator|validation interface' docs/projects/tomcat-monitoring/diagnostic-mvp docs/adr/tomcat-monitoring/adr-records/TM-ADR-0006.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0007.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0008.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0009.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0010.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0011.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0012.md
rg -n -i 'tomcat-diagnostic|diagnostic service|sqlite|fastify|express|typescript|node\.js|python|golang|webhook' /home/eddywiyatno/source/brainstorming /home/eddywiyatno/git/nodejs/README.md /home/eddywiyatno/git/nodejs/PROJECT /home/eddywiyatno/git/nodejs/VERSION /home/eddywiyatno/git/nodejs/CONFIG /home/eddywiyatno/git/nodejs/Containerfile /home/eddywiyatno/git/nodejs/entrypoint.sh
git -C /home/eddywiyatno/git/nodejs status --short --branch
sed -n '1,280p' /home/eddywiyatno/git/nodejs/AGENTS.md
sed -n '1,240p' /home/eddywiyatno/git/nodejs/README.md
sed -n '1,240p' /home/eddywiyatno/git/nodejs/PROJECT
sed -n '1,240p' /home/eddywiyatno/git/nodejs/VERSION
sed -n '1,240p' /home/eddywiyatno/git/nodejs/CONFIG
sed -n '1,240p' /home/eddywiyatno/git/nodejs/Containerfile
sed -n '1,240p' /home/eddywiyatno/git/nodejs/entrypoint.sh
rg --files /home/eddywiyatno/git/nodejs/scripts | sort | xargs -r -n1 sed -n '1,220p'
for f in tomcat-down-rule-specification.md alertmanager-webhook-contract.md target-and-evidence-contract.md restricted-event-collector-contract.md diagnostic-result-and-confidence-contract.md sqlite-lifecycle-contract.md notification-and-integration-contract.md non-functional-and-security-contract.md requirements-traceability.md; do echo "===== $f ====="; sed -n '1,360p' "docs/projects/tomcat-monitoring/diagnostic-mvp/$f"; done
```

Contract pages pada authoritative reading order dibaca menggunakan bounded
`sed -n`. Official Node.js `24.18.0` SQLite dan test-runner documentation juga
direview secara read-only; tidak ada dependency atau network artifact yang
ditambahkan ke repository.

### Documentation verification

```bash
git diff --check
python3 -c 'import pathlib,re,sys; files=[pathlib.Path(p) for p in sys.argv[1:]]; broken=[]
for f in files:
 text=f.read_text()
 for target in re.findall(r"(?<!!)\[[^]]+\]\(([^)]+)\)", text):
  target=target.strip("<>").split("#",1)[0]
  if not target or "://" in target or target.startswith("/") or target.startswith("mailto:"): continue
  resolved=(f.parent/target).resolve()
  if not resolved.exists(): broken.append((str(f),target))
print(f"files={len(files)} broken_links={len(broken)}")
for item in broken: print(f"{item[0]} -> {item[1]}")
sys.exit(1 if broken else 0)' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
rg -n '^#|\| Status \||Authorization Status|Decision Gate|GAP-001|source implementation' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
command -v mkdocs || true
git status --short --branch
git diff --stat
git diff -- docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
rg -n '^#{1,6} ' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
if rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md; then exit 1; else echo 'trailing_whitespace=0'; fi
```

### Operator refinement review

```bash
git status --short --branch
sed -n '1,130p' docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md
sed -n '1,120p' docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md
sed -n '1,130p' docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md
sed -n '1,380p' docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
```

### Operator refinement verification

```bash
git diff --check
python3 -c 'import pathlib,re,sys; files=[pathlib.Path(p) for p in sys.argv[1:]]; broken=[]
for f in files:
 text=f.read_text()
 for target in re.findall(r"(?<!!)\[[^]]+\]\(([^)]+)\)", text):
  target=target.strip("<>").split("#",1)[0]
  if not target or "://" in target or target.startswith("/") or target.startswith("mailto:"): continue
  resolved=(f.parent/target).resolve()
  if not resolved.exists(): broken.append((str(f),target))
print(f"files={len(files)} broken_links={len(broken)}")
for item in broken: print(f"{item[0]} -> {item[1]}")
sys.exit(1 if broken else 0)' docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
rg -n -C 2 'five-second|five seconds|lima detik|without retry|without an in-run retry|seven ordered|tujuh bagian|Correlated Log Evidence|RULE-007|MSG-003' docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
if rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md; then exit 1; else echo 'trailing_whitespace=0'; fi
git status --short --branch
git diff --stat
```

### Decision closure and commit preparation

```bash
git status --short --branch
sed -n '1,260p' docs/adr/tomcat-monitoring/index.md
sed -n '1,160p' docs/adr/tomcat-monitoring/adr-records/.pages
sed -n '1,240p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0010.md
sed -n '1,240p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0012.md
sed -n '1,210p' docs/projects/tomcat-monitoring/development/index.md
sed -n '1,180p' docs/projects/tomcat-monitoring/diagnostic-mvp/gap-register.md
git diff --check
python3 -c 'import pathlib,re,sys; files=[pathlib.Path(p) for p in sys.argv[1:]]; broken=[]
for f in files:
 text=f.read_text()
 for target in re.findall(r"(?<!!)\[[^]]+\]\(([^)]+)\)", text):
  target=target.strip("<>").split("#",1)[0]
  if not target or "://" in target or target.startswith("/") or target.startswith("mailto:"): continue
  resolved=(f.parent/target).resolve()
  if not resolved.exists(): broken.append((str(f),target))
print(f"files={len(files)} broken_links={len(broken)}")
for item in broken: print(f"{item[0]} -> {item[1]}")
sys.exit(1 if broken else 0)' docs/adr/tomcat-monitoring/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md docs/projects/tomcat-monitoring/diagnostic-mvp/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/diagnostic-mvp/gap-register.md docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
rg -n 'TM-ADR-0013|Status \| Completed|Answered — accepted|GAP-001.*Closed|Accepted design and implementation plan|Node.js `24.18.0`' docs/adr/tomcat-monitoring docs/projects/tomcat-monitoring
if rg -n '[[:blank:]]+$' docs/adr/tomcat-monitoring/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md docs/projects/tomcat-monitoring/diagnostic-mvp/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/diagnostic-mvp/gap-register.md docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md; then exit 1; else echo 'trailing_whitespace=0'; fi
git status --short --branch
git diff --stat
```

## 🧭 Reproduction Reference

Section ini ditambahkan pada 2026-08-31. TN-003 menghasilkan implementation
contract dan TM-ADR-0013, bukan source aplikasi. Exact published result berada
pada handbook commit `2c0535e`.

```bash
git show --stat 2c0535e
git show 2c0535e:docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md
git show 2c0535e:docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
```

Source implementation baru dimulai pada TN-004. Karena itu TN-003 tidak dapat
digunakan sebagai build procedure dan tidak menyatakan sebaliknya.

## ✅ Verification

| Method | Expected result | Actual result | Evidence |
| --- | --- | --- | --- |
| `git diff --check` | Tidak ada whitespace error | Passed | Command selesai tanpa output |
| Read-only local-link checker | Seluruh relative Markdown link pada changed Markdown scope memiliki target | Passed | `files=10 broken_links=0` |
| Metadata dan gate review | Status, authorization, open question, dan Decision Gate terlihat | Passed | Heading serta marker contract ditemukan oleh `rg` |
| Scope review | Diff hanya menyentuh approved journal, ADR, contract, dan current-state documentation | Passed | Sepuluh Markdown files dan satu `.pages` navigation file; repository source lain tetap bersih |
| MkDocs render | File dapat dirender melalui project toolchain | Not verified | `mkdocs` tidak tersedia pada `PATH`; dependency tidak dipasang |

## 🧾 Outcome

Planning record telah dibuat dan repository, source, validation, serta urutan
implementation telah menjadi accepted contract. Node.js `24.18.0` ESM dan
risiko release-candidate `node:sqlite` diterima dengan exact pin, adapter
isolation, serta mandatory persistence tests. Tidak ada source atau runtime
state yang berubah.

Prometheus timeout/fallback dan canonical email ordering sekarang menjadi
accepted implementation contract dengan requirement serta future evidence yang
dapat ditelusuri. SQLite retention tidak diubah karena existing contract sudah
menetapkan startup/hourly housekeeping, 30-day retention, WAL checkpoint,
incremental vacuum, dan target/hard capacity behavior.

`GAP-001` ditutup secara append-oriented melalui Gap Register dan TM-ADR-0013.
GAP lain tetap mempertahankan owner serta closure condition existing. Exact
immutable identity reusable Node.js base tetap diperlukan sebelum image build.

## ⏭️ Next Steps

Aktivitas berikutnya adalah TN-004 untuk membentuk repository governance dan
static validation baseline saja. Source edit, dependency installation, image
build, runtime, integration, dan push tetap memerlukan authorization terpisah
sesuai scope masing-masing.

## 💻 Version-Control Handoff

Project owner memberikan authorization commit pada 2026-08-31 untuk seluruh
documentation scope TN-003. Push tetap menjadi tindakan manual operator.

Stage attempt pertama gagal karena sandbox memasang Git metadata directory
sebagai read-only sehingga `.git/index.lock` tidak dapat dibuat. Working tree
dan index tidak berubah oleh kegagalan tersebut. Command `git add` yang sama
kemudian dijalankan ulang melalui approved elevated Git permission dan
berhasil; tidak ada file di luar exact list yang ditambahkan.

```bash
git add docs/adr/tomcat-monitoring/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/diagnostic-mvp/gap-register.md docs/projects/tomcat-monitoring/diagnostic-mvp/index.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/requirements-traceability.md docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/.pages docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/index.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
git add docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git status --short --branch
git diff --cached -- docs/adr/tomcat-monitoring/adr-records/TM-ADR-0013.md docs/projects/tomcat-monitoring/diagnostic-mvp/tomcat-down-rule-specification.md docs/projects/tomcat-monitoring/diagnostic-mvp/notification-and-integration-contract.md docs/projects/tomcat-monitoring/diagnostic-mvp/gap-register.md docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot/TN-003-define-diagnostic-service-repository-implementation-and-validation-contract.md
git commit -m "docs(tomcat-monitoring): define diagnostic service contract"
```

## 🔗 Related Documentation

- [TN-002 — Reconcile Diagnostic MVP Current-State Consolidation](TN-002-reconcile-diagnostic-mvp-current-state-consolidation.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Gap Register](../../diagnostic-mvp/gap-register.md)
- [Development](../../development/index.md)
- [TM-ADR-0010 — Deploy One Bounded Diagnostic Service per Tomcat Host](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md)
- [TM-ADR-0013 — Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0013.md)
- [Node.js `24.18.0` SQLite documentation](https://nodejs.org/download/release/v24.18.0/docs/api/sqlite.html)
- [Node.js `24.18.0` test runner documentation](https://nodejs.org/download/release/v24.18.0/docs/api/test.html)

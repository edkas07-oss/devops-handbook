# TN-029 — Verify Isolated Alertmanager Firing and Resolved Webhook Behavior

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-27 |
| Recorded Date | 2026-08-27 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-27 |

## 🎯 Objective

Menyediakan verification interface yang reproducible dan membuktikan bahwa
Alertmanager mengirim webhook `firing` serta `resolved` dengan stable grouping
labels melalui receiver lokal disposable.

## 🌍 Background

TN-028 menyelesaikan routing configuration non-secret, Prometheus API v2
delivery reference, dan semantic configuration validation. Receiver behavior,
payload firing/resolved, dan grouping belum diverifikasi. TN-025 menempatkan
isolated component test sebagai verification layer tersendiri yang tidak
memerlukan Integration Bridge atau TrueSight aktual.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- membuat receiver capture fixture dan verification interface minimal pada
  repository `tomcat-monitoring`;
- menggunakan Python standard library dan `curl` yang sudah tersedia tanpa
  dependency installation;
- menjalankan local image `localhost/alertmanager:1.0.0` sebagai container
  disposable `tm-tn029-alertmanager`;
- menggunakan listener `127.0.0.1:19080` dan Alertmanager API
  `127.0.0.1:19093` selama test;
- mengirim synthetic firing dan resolved alert melalui Alertmanager API v2;
- memeriksa status payload, receiver, dan lima stable group labels;
- menjalankan static validation serta cleanup audit; dan
- memperbarui source documentation, current-state documentation, navigation,
  dan Engineering Journal.

Persistent Alertmanager, named volume, image build atau pull, Integration
Bridge aktual, TrueSight, credential, external delivery, dependency
installation, commit, dan push tidak termasuk.

## 📋 Prerequisites

| Prerequisite | State | Evidence |
| --- | --- | --- |
| Runtime ownership | Completed and accepted. | TN-025 dan repository runtime `alertmanager`. |
| Configuration contract | Completed. | TN-028; `amtool` dan `promtool` validation passed. |
| Repository worktrees | Clean before implementation. | `git status --short --branch` pada tiga repository terkait. |
| Local tooling | Available. | Python 3.12, `curl`, dan `jq` ditemukan; implementation hanya memerlukan Python dan `curl`. |
| Port collision | Not observed. | Tidak ada listener pada TCP `19080` atau `19093` saat preflight. |
| Implementation authorization | Approved. | Project owner menyetujui objective, scope, verification, dan cleanup TN-029 pada 2026-08-27. |

## ⚖️ Execution Decision

Test menggunakan source routing yang disalin ke temporary directory. Hanya
`group_wait` dan `group_interval` dipercepat untuk membatasi durasi isolated
test; routing, receiver, secret-file reference, resolved behavior, dan group
labels tetap berasal dari source configuration. Static validator tetap
memeriksa exact lab baseline pada source asli.

Alertmanager menggunakan host network hanya selama test agar kedua interface
terikat ke loopback tanpa membuat network baru atau memublikasikan port ke
interface lain. Endpoint file berisi URL listener synthetic, dibuat di
temporary directory, tidak disimpan di Git, dan bukan endpoint atau credential
Integration Bridge aktual.

## 📋 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Implement the Webhook Verification Interfaces** | Menambahkan capture fixture, shell verification interface, dan static contract. |
| **Document the Verification Boundary** | Memperbarui README tanpa mengklaim runtime berhasil sebelum pengujian. |
| **Run the Static Source Validation** | Memeriksa shell, Python, aggregate contract, whitespace, diff, dan sensitive patterns. |
| **Run the Isolated Firing and Resolved Verification** | Menjalankan receiver dan disposable Alertmanager lalu memeriksa dua payload. |
| **Remove and Audit the Temporary Resources** | Membersihkan exact container, listener, files, dan memastikan volume state tidak berubah. |
| **Consolidate the Verified Result** | Memperbarui current-state documentation dan menutup TN berdasarkan mandatory criteria. |

## ⚙️ Implementation

Source implementation menghasilkan:

- bounded Python receiver pada
  `fixtures/alertmanager-webhook-receiver/capture.py` yang hanya menerima
  `POST /alerts`, menyimpan JSON synthetic, dan berhenti setelah dua request;
- `scripts/verify-alertmanager-webhook.sh` yang memeriksa dependency dan port,
  membuat temporary configuration, menjalankan exact disposable container,
  mengirim alert melalui API v2, memvalidasi payload, dan menjalankan cleanup
  audit;
- static fixture contract pada Alertmanager validator dan required-file
  inventory aggregate;
- source documentation yang menjelaskan dependency, invocation, dan batas
  verification; serta
- current-state documentation yang membedakan isolated receiver result dari
  persistent dan external delivery.

Temporary configuration mempertahankan source route, receiver,
`send_resolved`, secret-file path, dan lima group labels. `group_wait` serta
`group_interval` pada salinan tersebut diubah menjadi `1s`; source baseline
`30s` dan `5m` tidak diubah. Runtime menggunakan host network dengan kedua
service terikat pada loopback, `--tmpfs /alertmanager`, read-only temporary
mounts, dan tanpa named volume.

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Implement the Webhook Verification Interfaces

Tambahkan Python receiver, shell verification interface, fixture contract, dan
required-file inventory pada repository `tomcat-monitoring`.

!!! success "Expected Result"

    Interface hanya menerima payload synthetic, memakai exact temporary
    resources, dan dapat memvalidasi firing serta resolved.

**Actual Result:** fixture dan verification script tersedia sesuai contract.

**Evidence:** source inventory dan static validator checks.

</div>

<div class="procedure-step" markdown>

### Document the Verification Boundary

Perbarui README component dan validation agar isolated result tidak dianggap
sebagai persistent atau external delivery.

!!! success "Expected Result"

    Dependency, invocation, evidence, dan hal yang belum diuji dapat dibedakan.

**Actual Result:** source serta current-state documentation memisahkan ketiga
verification boundary tersebut.

**Evidence:** documentation diff dan final review.

</div>

<div class="procedure-step" markdown>

### Run the Static Source Validation

```bash
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
```

!!! success "Expected Result"

    Shell, Python, aggregate validators, whitespace, diff, dan sensitive scan
    lulus sebelum runtime test.

**Actual Result:** seluruh static checks lulus setelah setiap source correction.

**Evidence:** `Source implementation and static validation` command record.

</div>

<div class="procedure-step" markdown>

### Run the Isolated Firing and Resolved Verification

Jalankan verification interface yang membuat receiver, temporary config, dan
exact disposable Alertmanager lalu mengirim dua state synthetic.

```bash
./scripts/verify-alertmanager-webhook.sh
```

!!! success "Expected Result"

    Receiver menangkap urutan `firing,resolved` dengan receiver identity dan
    lima stable grouping labels yang sama.

**Actual Result:** final retry lulus setelah timestamp payload dan socket probe
diperbaiki.

**Evidence:** output `webhook_sequence=firing,resolved`, captured payload, dan
tabel Verification.

</div>

<div class="procedure-step" markdown>

### Remove and Audit the Temporary Resources

Pastikan self-cleanup menghapus exact container, listener, dan temporary files,
kemudian bandingkan volume state sebelum serta sesudah test.

!!! success "Expected Result"

    Tidak ada container, listener, temporary directory, atau volume baru yang
    tertinggal.

**Actual Result:** cleanup dan independent audit lulus.

**Evidence:** exact absence checks dan unchanged volume state.

</div>

<div class="procedure-step" markdown>

### Consolidate the Verified Result

Catat actual result, troubleshooting chronology, boundary, dan next activity
tanpa memperluas klaim ke persistent atau external delivery.

!!! success "Expected Result"

    TN hanya ditutup setelah seluruh mandatory criteria memiliki evidence.

**Actual Result:** seluruh criteria lulus dan TN ditutup sebagai `Completed`.

**Evidence:** Verification, Troubleshooting, Exceptions, Outcome, dan current-
state documentation.

</div>

</div>

## ⚙️ Commands Executed

### Handoff discovery before authorization

```bash
sed -n '1,240p' /home/eddywiyatno/git/prompt-template/prompt-next-technical-note.md
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/devops-handbook status --short --branch
find .. -name AGENTS.md -print
rg --files /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring /home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring | sort
sed -n '1,320p' /home/eddywiyatno/git/tomcat-monitoring/AGENTS.md
sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/AGENTS.md
sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/index.md
sed -n '1,520p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,520p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-028-implement-alertmanager-configuration-and-validation-contract.md
rg -n -C 6 'receiver fixture|isolated|firing|resolved|webhook|Decision Gate|prerequisite|Next Steps|Open Questions' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md
rg -n -C 4 'Alertmanager|receiver|webhook|firing|resolved|Integration Bridge' docs/projects/tomcat-monitoring/{architecture,infrastructure,development}/index.md
rg --files . | sort
sed -n '1,280p' README.md
sed -n '1,240p' config/alertmanager/README.md
sed -n '1,220p' config/alertmanager/alertmanager.yml
```

### Governance and implementation discovery after authorization

```bash
# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
sed -n '1,320p' README.md
sed -n '1,320p' scripts/validate.sh
sed -n '1,360p' scripts/validate-alertmanager.sh
sed -n '1,300p' validation/README.md

# /home/eddywiyatno/git/devops-handbook
git status --short --branch
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,260p' docs/standards/documentation-standards.md
sed -n '1,280p' docs/standards/writing-standards.md
sed -n '1,240p' docs/standards/engineering-journal-standards.md
sed -n '241,480p' docs/standards/engineering-journal-standards.md
sed -n '481,720p' docs/standards/engineering-journal-standards.md
sed -n '721,980p' docs/standards/engineering-journal-standards.md
sed -n '1,160p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
rg -n '^# TN-024|^\| Status|^\| Activity Type|^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-024-implement-and-verify-prometheus-application-health-alert-rules.md

# /home/eddywiyatno/git/alertmanager
git status --short --branch
sed -n '1,320p' AGENTS.md
sed -n '1,280p' README.md
sed -n '1,280p' scripts/run.sh
# Failed discovery command; file does not exist
sed -n '1,280p' scripts/validate.sh
sed -n '1,220p' Containerfile

# Tool and port preflight
command -v python3
python3 --version
command -v curl
curl --version | sed -n '1p'
command -v jq || true
command -v mkdocs || true
ss -ltn '( sport = :19080 or sport = :19093 )' 2>/dev/null || true
```

### Source implementation and static validation

Source and documentation patches were applied with `apply_patch`. The initial
combined patch failed its README context check atomically; no partial source
change occurred. Context-correct patches were then applied.

```bash
chmod 0755 scripts/verify-alertmanager-webhook.sh fixtures/alertmanager-webhook-receiver/capture.py
git status --short --branch
git diff --stat
git diff -- scripts/verify-alertmanager-webhook.sh fixtures/alertmanager-webhook-receiver/capture.py scripts/validate.sh scripts/validate-alertmanager.sh README.md config/alertmanager/README.md validation/README.md
bash -n scripts/*.sh
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("fixtures/alertmanager-webhook-receiver/capture.py").read_text())'
./scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$' README.md config fixtures scripts validation
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer_token:|password:|credential-url|https?://[^[:space:]/]+:[^[:space:]@]+@' README.md config fixtures scripts validation
```

### Runtime verification, diagnostics, and cleanup

```bash
# Sandboxed attempt; failed before image inspection because Podman state was read-only
./scripts/verify-alertmanager-webhook.sh

# Approved runtime retry; Alertmanager API returned HTTP 400 for the initial resolved fixture
./scripts/verify-alertmanager-webhook.sh

# Static validation after correcting startsAt/endsAt ordering
bash -n scripts/*.sh
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("fixtures/alertmanager-webhook-receiver/capture.py").read_text())'
./scripts/validate.sh
git diff --check

# Retry stopped during collision preflight because the socket probe did not reuse a TIME_WAIT address
./scripts/verify-alertmanager-webhook.sh

# Read-only collision diagnostic
ss -ltnp '( sport = :19080 or sport = :19093 )' 2>/dev/null || true
podman ps --all --filter name=tm-tn029-alertmanager --format 'id={{.ID}} name={{.Names}} status={{.Status}}'
ps -eo pid,ppid,stat,args | rg 'capture.py|tm-tn029' || true

# Static validation after aligning collision probe with HTTPServer SO_REUSEADDR behavior
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check

# Successful disposable verification and self-cleanup
./scripts/verify-alertmanager-webhook.sh

# Independent post-run audit and documentation source search
podman ps --all --filter name=tm-tn029-alertmanager --format 'id={{.ID}} name={{.Names}} status={{.Status}}'
ss -ltn '( sport = :19080 or sport = :19093 )' 2>/dev/null || true
rg -n -C 2 'Alertmanager|receiver behavior|firing/resolved|external flow|external integration' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/development/index.md

# Final regression after distinguishing early-failure volume audit output
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
./scripts/verify-alertmanager-webhook.sh

# Final independent resource audit
podman ps --all --filter name=tm-tn029-alertmanager --format 'id={{.ID}} name={{.Names}} status={{.Status}}'
ss -ltn '( sport = :19080 or sport = :19093 )' 2>/dev/null || true
```

### Documentation consolidation and final review

```bash
rg -n -C 3 'TrueSight|Integration Bridge|Notification Channel|email|External Integration|Next Steps' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-029-verify-isolated-alertmanager-firing-and-resolved-webhook-behavior.md
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@|<lab-recipient>' docs/projects/tomcat-monitoring
rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-029-verify-isolated-alertmanager-firing-and-resolved-webhook-behavior.md
rg -n 'TN-029|TN-029-verify-isolated' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
command -v mkdocs || true
git status --short --branch
git diff --stat
```

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Static source validation | Fixture dan verification interface memenuhi repository contract. | Passed. | Shell dan Python parsing, aggregate validator, whitespace check, dan diff check lulus. |
| Isolated runtime readiness | Exact disposable Alertmanager memuat derived test configuration dan ready pada loopback. | Passed. | API menerima synthetic alert setelah readiness polling. |
| Firing delivery | Receiver menangkap satu payload `firing` untuk synthetic alert. | Passed. | Output `webhook_sequence=firing,resolved`. |
| Resolved delivery | Receiver menangkap satu payload `resolved` untuk identity alert yang sama. | Passed. | Captured alert dan top-level payload sama-sama berstatus `resolved`. |
| Grouping contract | Receiver dan lima stable group labels sesuai source contract. | Passed. | Receiver `integration-bridge`; labels `alertname`, `check`, `instance`, `job`, dan `service`. |
| Cleanup audit | Container, listener, temporary files, dan volume state kembali ke kondisi awal. | Passed. | Self-cleanup dan independent post-run audit menemukan tidak ada container atau loopback listener; volume state unchanged. |

## 🧰 Troubleshooting

Initial sandboxed Podman command gagal saat mengubah sticky bit pada
`/run/user/1000/libpod`, lalu menampilkan image seolah-olah tidak tersedia.
Cleanup berjalan tanpa resource karena kegagalan terjadi sebelum container
dibuat. Approved runtime retry digunakan sebagai evidence aktual.

Retry pertama mencapai API, tetapi resolved request menghasilkan HTTP `400`.
Synthetic payload menggunakan `endsAt` satu detik sebelum `startsAt`; fixture
dikoreksi agar `startsAt` lima menit lebih awal. Static validation diulang dan
API menerima interval yang telah dikoreksi pada final test.

Retry berikutnya berhenti sebelum membuat resource karena socket bind probe
menilai port masih digunakan. Audit `ss`, Podman, dan process list tidak
menemukan listener atau container; address masih berada pada lifecycle socket
sebelumnya. Probe diberi `SO_REUSEADDR` agar konsisten dengan Python
`HTTPServer`, tanpa mengizinkan collision dengan listener aktif. Final retry
kemudian lulus.

## ⚠️ Exceptions

Test mempercepat `group_wait` dan `group_interval` hanya pada temporary copy.
Lab timing baseline `30s` dan `5m` tetap tervalidasi secara statis, tetapi
behavior timing aktualnya tidak diuji. Persistent Prometheus delivery,
Alertmanager persistence dan restart, actual Integration Bridge, TLS,
authentication, retry behavior, TrueSight mapping, dan external notification
tidak diverifikasi. MkDocs render juga tidak diverifikasi karena executable
tidak tersedia dan dependency installation tidak diotorisasi.

## ❓ Open Questions

| Question | Owner | Closure Criterion | Blocked Work |
| --- | --- | --- | --- |
| SMTP relay, port, sender, dan TLS policy apa yang digunakan oleh lab? | Project owner dan infrastructure/email owner | Accepted SMTP connectivity dan sender contract | Email configuration dan component test |
| Bagaimana authentication secret dibuat, dipasang, dirotasi, dan dicabut? | Infrastructure dan security owner | Approved secret provider, file path, permission, rotation, revocation, dan cleanup | Persistent Alertmanager email receiver |
| Apakah recipient disimpan sebagai non-secret source atau diberikan saat runtime? | Project owner dan security owner | Accepted representation yang menjaga personal data boundary | Recipient configuration |
| Subject, body, grouping, dan firing/resolved receipt apa yang menjadi acceptance criteria? | Project owner | Approved sample semantics dan observable test result | Email delivery verification |
| Kapan Integration Bridge dan TrueSight ditinjau kembali? | Project owner dan TrueSight owner | Target environment tersedia dan Decision Gate baru disetujui | TrueSight implementation; tidak memblokir lab email |

## 🧾 Outcome

TN-029 selesai. Source repository sekarang memiliki isolated verification
interface yang reproducible. Local Alertmanager image terbukti mengirim
payload firing dan resolved menuju receiver synthetic dengan receiver identity
dan lima stable grouping labels yang ditetapkan.

Result ini hanya menutup isolated receiver behavior. Tidak ada persistent
container, named volume, actual endpoint, credential, external event, commit,
atau push yang dibuat. Exact disposable container, listener, dan temporary
files telah dibersihkan; independent audit tidak menemukan resource TN-029.

## ⏭️ Next Steps

Project owner menetapkan direct email dari Alertmanager sebagai next lab
notification path dan menunda Integration Bridge serta TrueSight karena target
tersebut tidak tersedia di lab. Recipient telah diberikan dalam session, tetapi
alamat personal tidak disalin ke Git sampai representation boundary disetujui.

TN-030 yang direkomendasikan adalah **Define Alertmanager Email Notification
Channel Contract** dengan activity type `Discovery and Assessment`.
Objective-nya menetapkan SMTP relay dan port, sender identity, authentication
serta TLS, secret provider dan mount contract, recipient representation, email
content, dan firing/resolved acceptance criteria. TN tersebut tidak mengirim
email, membuat credential, atau menjalankan persistent Alertmanager. Source
implementation dan actual email delivery memerlukan TN serta authorization
terpisah setelah contract selesai.

## 🔗 Related Documentation

- [TN-028 — Implement Alertmanager Configuration and Validation Contract](TN-028-implement-alertmanager-configuration-and-validation-contract.md)
- [TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract](TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)

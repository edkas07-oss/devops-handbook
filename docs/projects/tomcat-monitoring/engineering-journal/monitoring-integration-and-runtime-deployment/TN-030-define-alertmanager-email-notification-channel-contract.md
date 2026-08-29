# TN-030 — Define Alertmanager Email Notification Channel Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-27 |
| Recorded Date | 2026-08-27 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-27 |

## 🎯 Objective

Menetapkan contract direct email notification channel Alertmanager untuk lab
yang memisahkan non-secret routing source, SMTP serta TLS requirement,
authentication secret, recipient representation, dan verification boundary.

## 🌍 Background

TN-029 membuktikan isolated firing dan resolved webhook behavior. Setelah
verification tersebut, project owner menetapkan email langsung sebagai next
lab notification path karena TrueSight dan Integration Bridge tidak tersedia
di lab. Target recipient telah diberikan dalam session, tetapi belum disimpan
di Git atau digunakan untuk pengiriman aktual.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- memvalidasi schema email receiver Alertmanager `v0.34.0` dan persyaratan
  Gmail melalui dokumentasi resmi;
- menentukan SMTP relay dan port baseline, sender identity, TLS,
  authentication, secret injection, recipient representation, email content,
  grouping, firing/resolved semantics, validation layers, dan cleanup
  boundary;
- menetapkan hubungan lab email dengan future Integration Bridge dan TrueSight;
- memperbarui Engineering Journal dan current-state documentation; serta
- menghasilkan implementation handoff dengan prerequisite dan authorization
  yang eksplisit.

Perubahan Alertmanager configuration atau validator, credential atau App
Password creation, secret file, image, container, network, persistent runtime,
email aktual, external delivery test, commit, dan push tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| Project direction | Direct email dipilih sebagai next lab notification path; TrueSight ditunda karena tidak tersedia di lab. |
| TN-029 | Local Alertmanager telah membuktikan firing/resolved receiver behavior dan exact disposable cleanup. |
| Runtime contract | Local image menggunakan Alertmanager `v0.34.0`; routing configuration dan secret tetap dimiliki `tomcat-monitoring`. |
| Existing source | Active source masih menggunakan receiver webhook `integration-bridge`; belum ada email configuration atau SMTP secret. |
| Recipient | Recipient aktual diberikan kepada project owner tetapi tidak disalin ke Git selama contract discovery. |

## 🔍 Findings

### Alertmanager email schema

Alertmanager `v0.34.0` mendukung receiver `email_configs` dengan `to` sebagai
templated string, `send_resolved`, SMTP smarthost, sender, authentication
username, `auth_password_file`, TLS requirement, TLS configuration, message
body, dan templated headers. Ia tidak menyediakan Gmail `Sign in with Google`
atau OAuth flow pada email receiver; SMTP authentication yang tersedia adalah
username dengan password atau secret.

Karena `to` merupakan templated string, recipient lab dapat berasal dari named
template yang dipasang saat runtime. `auth_username` bukan templated string dan
tidak memiliki file variant, sehingga exact sender Gmail account harus menjadi
non-secret environment contract yang disetujui sebelum source implementation.

### Gmail SMTP baseline

Google mendokumentasikan `smtp.gmail.com` dengan port `587` untuk TLS dan full
account address plus App Password untuk authentication. App Password hanya
tersedia ketika 2-Step Verification aktif dan dapat tidak tersedia pada
security-key-only, organization-managed, atau Advanced Protection account.
Google juga mencabut App Password setelah account password berubah; rotation
dan recovery contract harus mengantisipasi kondisi tersebut.

Lab baseline ditetapkan sebagai berikut:

| Setting | Contract |
| --- | --- |
| Notification channel | Direct email dari Alertmanager; Integration Bridge dan TrueSight deferred |
| Smarthost | `smtp.gmail.com:587` |
| Transport | Explicit TLS/STARTTLS; `require_tls: true` |
| TLS verification | `server_name: smtp.gmail.com`, `insecure_skip_verify: false`, minimum `TLS12` |
| Sender and auth username | Exact full Gmail account yang disetujui; sender dan authenticated account harus sama atau menggunakan alias yang diterima provider |
| Authentication | Gmail App Password melalui `auth_password_file`; regular Google password dilarang |
| App Password path | `/run/secrets/tomcat-monitoring/gmail-app-password` |
| Recipient | Named template dari `/run/secrets/tomcat-monitoring/email-recipient.tmpl`; actual address tidak disimpan di Git atau evidence |
| Receiver name | `lab-email` |
| Resolved delivery | `send_resolved: true` |
| Grouping and timing | Lima stable labels serta `30s`/`5m`/`4h` baseline yang sudah diterima tetap berlaku |
| Subject baseline | `[Tomcat Monitoring][{{ .Status }}] {{ .CommonLabels.alertname }} - {{ .CommonLabels.instance }}` |
| Message body | Default Alertmanager HTML pada baseline awal; custom template hanya ditambahkan bila acceptance review membutuhkannya |

Port `587` dipilih karena Google menetapkannya untuk TLS dan Alertmanager
menggunakan explicit TLS pada port selain `465`. `force_implicit_tls` tidak
perlu ditetapkan. Port `465` tetap menjadi fallback yang memerlukan contract
implicit TLS baru; port `25` dan unencrypted SMTP tidak termasuk baseline.

### Secret and personal-data lifecycle

App Password dibuat manual oleh owner Gmail setelah 2-Step Verification aktif.
Nilai hanya boleh ditulis ke accepted non-Git secret source, tidak boleh masuk
shell history, command argument, Git, image layer, documentation, screenshot,
atau log. Runtime mount harus read-only dan hanya dapat dibaca UID Alertmanager;
permission exact ditentukan setelah mapped runtime UID diverifikasi.

Rotation menggunakan App Password baru, atomic secret replacement, controlled
Alertmanager reload atau replacement, successful delivery verification, lalu
revocation password lama. Immediate revocation wajib dilakukan jika secret
terekspos atau tidak lagi digunakan. Bila account password berubah, App
Password dianggap invalid sampai replacement diverifikasi.

Recipient merupakan personal routing data, bukan credential, tetapi tetap
environment-specific. Source configuration hanya memanggil named template;
operator menyediakan runtime template file di luar Git. File tidak boleh
ditampilkan pada evidence atau sensitive scan output. Perubahan recipient
memerlukan controlled file replacement serta configuration reload atau
replacement verification.

### Verification layers

| Layer | Required Evidence | Does Not Prove |
| --- | --- | --- |
| Static source | Exact receiver, SMTP/TLS baseline, file references, stable grouping, `send_resolved`, no literal password atau recipient. | Schema parse, network, atau email receipt. |
| Semantic configuration | `amtool check-config` menerima source dengan disposable placeholder secret dan recipient template. | Gmail authentication atau SMTP reachability. |
| Network preflight | DNS resolution, TCP `587`, STARTTLS, certificate hostname, dan TLS minimum berhasil dari approved runtime context tanpa mengirim email. | Authentication atau inbox delivery. |
| Isolated delivery | Disposable Alertmanager mengirim synthetic firing lalu resolved; recipient mengonfirmasi sender, subject, content, grouping, dan two-state receipt; exact cleanup lulus. | Persistent Prometheus integration atau restart behavior. |
| Persistent integration | Prometheus delivery, Alertmanager state, restart, controlled failure/recovery, dan no-duplicate behavior diverifikasi. | Production suitability atau TrueSight. |

Network preflight dan delivery merupakan external-state actions dan memerlukan
authorization terpisah. Actual email harus menggunakan synthetic lab content
tanpa credential, internal secret, atau sensitive application data.

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Gmail SMTP `587` dengan TLS dan App Password | Tersedia untuk account yang mendukung App Password; cocok dengan Alertmanager password-file schema dan dynamic lab IP. | Selected for lab baseline |
| Gmail implicit TLS pada `465` | Didukung provider dan Alertmanager, tetapi tidak memberi manfaat untuk baseline ketika STARTTLS `587` tersedia. | Retained fallback |
| Google Workspace SMTP relay | Google merekomendasikannya untuk managed organization, tetapi membutuhkan Workspace administration dan relay policy yang tidak tersedia pada lab personal. | Rejected for current lab |
| OAuth atau Sign in with Google | Lebih disukai Google, tetapi tidak tersedia pada Alertmanager `email_config` v0.34.0 tanpa component tambahan. | Rejected for current scope |
| Recipient literal di Git | Sederhana tetapi mengikat generic source ke personal lab target dan menyimpan personal routing data. | Rejected |
| Recipient melalui runtime named template | Mempertahankan reusable source dan memisahkan personal target dari Git serta evidence. | Selected |
| Integration Bridge dan TrueSight | Tetap sesuai future architecture, tetapi target tidak tersedia pada lab. | Deferred |

## ⚠️ Risks

| Risk | State | Mitigation or Follow-up |
| --- | --- | --- |
| Regular account password tersimpan sebagai SMTP credential | Mitigated by contract | Hanya App Password melalui file; reject inline password. |
| App Password option tidak tersedia | Open prerequisite | Verifikasi 2-Step Verification dan account eligibility sebelum implementation. |
| Personal recipient atau App Password masuk Git/evidence | Mitigated by contract | Gunakan two runtime files, placeholder scan, dan redacted evidence. |
| Gmail memfilter atau menunda synthetic notification | Accepted for lab | Periksa Inbox dan Spam; bedakan SMTP acceptance dari inbox receipt. |
| Alert berisi data sensitif | Mitigated by contract | Batasi subject/body pada operational labels dan synthetic content. |
| Repeat notification menghasilkan spam | Mitigated for baseline | Pertahankan grouping dan `repeat_interval: 4h`; gunakan synthetic test bounded. |
| Secret rotation memutus delivery | Open operational risk | Atomic replacement, reload/replacement, test delivery, lalu revoke old App Password. |
| Email berhasil tetapi persistent integration gagal | Open | Pisahkan isolated delivery dari persistent Prometheus/Alertmanager verification. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| SMTP relay, port, sender, dan TLS policy apa yang berlaku? | Answered except sender identity | Project owner | Exact full Gmail sender account disetujui; baseline lain ditetapkan TN-030 | Email source implementation |
| Bagaimana authentication secret dibuat, dipasang, dirotasi, dan dicabut? | Answered for contract | Project owner dan security owner | Runtime UID permission serta creation authorization dikonfirmasi pada implementation preflight | Secret provisioning dan delivery test |
| Bagaimana recipient direpresentasikan tanpa menyimpan personal data yang tidak perlu? | Answered | Project owner | Runtime named-template contract diterapkan dan validated | N/A setelah implementation |
| Apa criteria firing dan resolved email yang wajib dibuktikan? | Answered | Project owner | Isolated test membuktikan sender, subject, content, grouping, two-state receipt, dan cleanup | N/A setelah verification plan diterapkan |
| Apakah Gmail sender account mendukung 2-Step Verification dan App Password? | Open | Project owner | Account eligibility diverifikasi tanpa mengekspos account atau secret | Email implementation dan delivery |
| Apakah runtime memiliki outbound DNS dan TCP `587` ke Gmail? | Open | Infrastructure owner | Approved network preflight lulus dari runtime context | Actual SMTP verification |
| Kapan Integration Bridge dan TrueSight ditinjau kembali? | Deferred | Project owner dan TrueSight owner | Environment target tersedia dan Decision Gate baru dibuka | Future TrueSight integration; tidak memblokir email lab |

## 💡 Recommendation

Gunakan receiver `lab-email` dengan Gmail SMTP `587`, explicit TLS minimum
`TLS12`, App Password file, runtime recipient template, stable grouping, dan
`send_resolved: true`. Source implementation berikutnya harus mengganti active
lab receiver webhook dengan email receiver tanpa menghapus histori atau future
TrueSight architecture dari documentation.

Pecah delivery menjadi dua activity setelah exact sender disetujui: pertama,
implementasikan non-secret source, template reference, static validator, dan
disposable `amtool` validation tanpa network; kedua, lakukan authorized network
preflight dan isolated firing/resolved inbox verification menggunakan actual
runtime files. Persistent deployment tetap menjadi activity terpisah.

## 🤝 Decision Handoff

Project owner menerima direct email sebagai next lab notification direction
dan menyetujui TN-030 untuk menetapkan contract. Gmail SMTP `587`, TLS minimum,
App Password file, runtime recipient template, receiver identity, grouping,
resolved behavior, message baseline, secret lifecycle, dan layered
verification ditetapkan sebagai planning contract.

Contract ini menggunakan generic Notification Channel branch yang sudah ada
dan menunda TrueSight tanpa menghapus future architecture boundary. Arah Gmail
yang dipilih pada TN-030 kemudian digantikan oleh keputusan Mailpit pada
[TM-ADR-0005](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md).
Exact sender Gmail account dan account eligibility pada saat itu masih menjadi
prerequisite. Approval TN-030 tidak mengizinkan source
implementation, App Password creation, secret file, network preflight,
container, persistent runtime, atau actual email delivery.

## ⚙️ Commands Executed

```bash
# /home/eddywiyatno/git/devops-handbook
git status --short --branch
sed -n '1,380p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-029-verify-isolated-alertmanager-firing-and-resolved-webhook-behavior.md
sed -n '160,220p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,90p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages

# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
sed -n '1,260p' config/alertmanager/alertmanager.yml
sed -n '1,280p' config/alertmanager/README.md
sed -n '1,260p' scripts/validate-alertmanager.sh
rg -n -C 3 'email|smtp|notification|receiver|secret' README.md config scripts validation

# /home/eddywiyatno/git/alertmanager
git status --short --branch
sed -n '1,180p' PROJECT
sed -n '1,180p' VERSION
sed -n '1,220p' CONFIG
sed -n '1,280p' Containerfile
sed -n '1,280p' README.md
```

Official Alertmanager `v0.34.0` configuration reference, Prometheus
notification integration catalog, Google Gmail SMTP guidance, dan Google App
Password lifecycle guidance juga direview melalui read-only web access.

Final documentation review:

```bash
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@|<lab-recipient>|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' docs/projects/tomcat-monitoring
rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-030-define-alertmanager-email-notification-channel-contract.md
rg -n 'TN-030|TN-030-define-alertmanager' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-030-define-alertmanager-email-notification-channel-contract.md
command -v mkdocs || true
git status --short --branch
git diff --stat
```

## 🧾 Outcome

TN-030 selesai sebagai discovery dan planning contract. Direct email melalui
Gmail dipilih sebagai lab notification channel; TrueSight tetap deferred.
Contract memisahkan reusable source, personal recipient, dan App Password serta
menetapkan TLS, grouping, resolved delivery, content, lifecycle, dan
verification layers.

Belum ada source configuration, credential, secret file, network connection,
container, email, commit, atau push yang dibuat. Implementation tetap blocked
pada exact Gmail sender account, App Password eligibility, dan authorization
baru. Structure, navigation, whitespace, sensitive-data scan, dan diff check
lulus. MkDocs render tidak diverifikasi karena executable tidak tersedia dan
dependency installation tidak diotorisasi.

## ⏭️ Next Steps

Project owner menentukan exact Gmail sender account dan memastikan account
mendukung 2-Step Verification serta App Password. Setelah prerequisite
tersebut tersedia, buka TN implementation terpisah untuk non-secret email
receiver source dan semantic validation tanpa mengirim email.

## 🔗 Related Documentation

- [TN-029 — Verify Isolated Alertmanager Firing and Resolved Webhook Behavior](TN-029-verify-isolated-alertmanager-firing-and-resolved-webhook-behavior.md)
- [TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract](TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Alertmanager v0.34.0 Configuration](https://github.com/prometheus/alertmanager/blob/v0.34.0/docs/configuration.md)
- [Gmail SMTP for Apps](https://knowledge.workspace.google.com/admin/gmail/send-email-from-a-printer-scanner-or-app?hl=en)
- [Google App Passwords](https://support.google.com/mail/answer/185833?hl=en)

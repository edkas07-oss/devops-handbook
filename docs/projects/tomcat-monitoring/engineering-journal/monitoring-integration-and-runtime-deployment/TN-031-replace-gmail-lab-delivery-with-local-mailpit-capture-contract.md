# TN-031 — Replace Gmail Lab Delivery with Local Mailpit Capture Contract

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

Mengganti baseline Gmail App Password untuk lab dengan Mailpit lokal sebagai
SMTP capture yang memverifikasi email firing dan resolved tanpa credential
Google atau external delivery.

## 🌍 Background

TN-030 menetapkan direct Gmail SMTP sebagai lab notification path. Pada
Decision Gate berikutnya, project owner menilai ulang risiko App Password.
Google menyatakan App Password sebagai compatibility mechanism untuk aplikasi
yang tidak menyediakan Sign in with Google dan tidak merekomendasikannya untuk
sebagian besar penggunaan. Alertmanager `email_config` menyediakan SMTP
username serta password atau password file, tetapi tidak menyediakan Gmail
OAuth flow pada email receiver.

Project owner kemudian menerima Mailpit lokal agar lab tetap dapat
memverifikasi pembentukan email tanpa memberikan akses Google Account kepada
Alertmanager. Perubahan ini menggantikan hasil planning Gmail pada TN-030 tanpa
menulis ulang status atau evidence historisnya.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- menilai risiko Gmail App Password dan alternatif delivery;
- memilih Mailpit lokal sebagai disposable SMTP capture untuk lab;
- menetapkan topology, security boundary, verification layers, ownership gate,
  dan implementation handoff awal;
- menunda external inbox delivery, SMTP relay, Gmail API gateway, Integration
  Bridge, dan TrueSight; serta
- memperbarui Engineering Journal dan current-state documentation.

Image pull, penetapan upstream version atau digest, source configuration,
validator, dependency, network, port, image build, container, persistent
runtime, actual email, external delivery, cleanup runtime, commit, dan push
tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| TN-030 | Gmail SMTP `587`, TLS, App Password file, recipient template, dan layered verification pernah ditetapkan sebagai planning contract. |
| Google guidance | App Password hanya tersedia dengan 2-Step Verification, tidak direkomendasikan untuk sebagian besar penggunaan, dan digunakan ketika aplikasi tidak menyediakan Sign in with Google. |
| Alertmanager schema | `email_config` mendukung SMTP authentication melalui password atau password file; Gmail OAuth tidak tersedia pada receiver tersebut. |
| Mailpit documentation | Mailpit menerima SMTP secara lokal dan menyediakan HTTP API untuk menginspeksi captured message. |
| Project decision | Project owner menyetujui Mailpit lokal dan tidak melanjutkan Gmail App Password sebagai baseline lab. |

## 🔍 Findings

### Security and delivery boundary

App Password lebih terbatas daripada membagikan regular Google password, tetapi
tetap menjadi reusable credential yang melewati interactive second step pada
koneksi aplikasi. Menggunakan account khusus dapat mengurangi dampak, tetapi
tidak diperlukan bila objective lab hanya membuktikan email yang dibentuk
Alertmanager.

Mailpit memindahkan verification boundary ke network lokal. Alertmanager dapat
mengirim SMTP ke disposable Mailpit, kemudian verification interface membaca
captured message melalui HTTP API. Flow tersebut tidak membutuhkan account,
App Password, recipient personal, DNS eksternal, atau inbox eksternal.

### Accepted lab topology

```text
Synthetic API v2 alert
          |
          v
Disposable Alertmanager
          |
          | SMTP on isolated local network
          v
Disposable Mailpit
          |
          | HTTP API inspection
          v
Local verification interface
```

Mailpit merupakan verification utility, bukan persistent notification channel.
SMTP dan API hanya boleh tersedia pada isolated disposable topology. Bila host
publication diperlukan untuk test driver, binding harus loopback-only dan
exact port ditetapkan sebelum execution authorization. Tidak ada relay ke
external SMTP server pada baseline ini.

### Verification boundary

| Layer | Required Evidence | Does Not Prove |
| --- | --- | --- |
| Static source | Receiver Mailpit, stable grouping, `send_resolved`, no Gmail field, credential, atau personal recipient. | Schema parse atau email capture. |
| Semantic configuration | `amtool check-config` menerima configuration tanpa external secret. | SMTP connectivity atau message content. |
| Isolated capture | Mailpit menerima firing dan resolved; API membuktikan sender placeholder, recipient placeholder, subject, body, grouping, dan two-state capture. | External inbox delivery, provider authentication, persistence, atau production suitability. |
| Cleanup audit | Exact Alertmanager, Mailpit, network, temporary file, dan published loopback port tidak tersisa. | Persistent runtime lifecycle. |

### Runtime Component Ownership Gate

Mailpit adalah runtime container baru sehingga image tidak boleh ditarik atau
dijalankan sebelum ownership gate selesai. Activity implementation berikutnya
harus menentukan salah satu dari repository runtime generik, repository runtime
baru, atau approved direct-upstream exception. Gate juga harus menetapkan
upstream identity dan immutable pin, image provenance, lifecycle run/test/
cleanup, configuration owner, exact resource names, network, port binding,
rollback, dan evidence.

Karena Mailpit hanya digunakan sebagai disposable test utility dan tidak
menjadi reusable production runtime pada keputusan ini, direct-upstream
consumption dapat dinilai sebagai kandidat. Kandidat tersebut belum accepted
dan bukan authorization untuk image pull atau component test.

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Gmail SMTP dengan App Password | Sederhana dan didukung Alertmanager, tetapi memberi reusable Google credential kepada aplikasi dan tidak diperlukan untuk local capture objective. | Superseded for current lab |
| Mailpit lokal | Tidak memerlukan external account atau secret dan menyediakan observable SMTP capture melalui API. | Selected |
| Google Workspace SMTP relay | Lebih sesuai untuk managed organization, tetapi membutuhkan Workspace administration serta network policy yang tidak tersedia pada lab. | Deferred |
| Transactional email provider | Menyediakan dedicated SMTP credential, tetapi menambah vendor account, sender verification, secret, dan kemungkinan biaya. | Deferred |
| Webhook gateway ke Gmail API OAuth | Menghindari App Password, tetapi menambah application source, OAuth client, refresh-token lifecycle, dan deployment. | Rejected for current lab |
| Integration Bridge dan TrueSight | Tetap menjadi future external integration boundary; target tidak tersedia di lab. | Deferred |

## ⚠️ Risks

| Risk | State | Mitigation or Follow-up |
| --- | --- | --- |
| Local capture dianggap membuktikan external delivery | Open | Nyatakan result boundary pada source, validator, TN, dan current-state documentation. |
| Mailpit image dikonsumsi tanpa ownership atau immutable pin | Open prerequisite | Selesaikan Runtime Component Ownership Gate sebelum pull atau test. |
| SMTP atau API terpapar ke network host | Mitigated by contract | Gunakan isolated network; jika publication diperlukan, bind loopback-only dengan exact port. |
| Disposable resource tertinggal | Open implementation risk | Tetapkan exact names, trap cleanup, preflight collision check, dan post-cleanup audit. |
| Captured alert memuat data sensitif | Mitigated by contract | Gunakan synthetic labels, placeholder sender/recipient, dan bounded message evidence. |
| External notification capability tetap belum terbukti | Accepted | Tunda sampai provider atau relay terpisah melewati Decision Gate. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Bagaimana Mailpit image dimiliki dan dikonsumsi? | Open | Project owner | Repository runtime atau direct-upstream exception, immutable pin, provenance, dan lifecycle disetujui | Image pull dan Mailpit component test |
| Network, exact resource names, dan loopback port apa yang digunakan? | Open | Project owner dan infrastructure owner | Collision preflight, isolated network, exact names, port binding, dan cleanup contract diterima | Disposable integration verification |
| Apakah external inbox delivery masih diperlukan setelah local capture? | Deferred | Project owner | Operational requirement dan provider target tersedia | External delivery implementation |
| Kapan Integration Bridge dan TrueSight ditinjau kembali? | Deferred | Project owner dan TrueSight owner | Environment target tersedia dan Decision Gate baru dibuka | Future TrueSight integration |

## 💡 Recommendation

Gunakan Mailpit hanya untuk isolated SMTP capture. Activity berikutnya harus
menyelesaikan Runtime Component Ownership Gate dan implementation plan sebelum
mengubah Alertmanager source atau menjalankan container. Setelah gate diterima,
pisahkan source implementation serta disposable semantic/capture verification
dari persistent Alertmanager deployment.

External inbox delivery tidak menjadi success criterion lab saat ini. Bila
kebutuhan tersebut kembali muncul, pilih managed SMTP relay atau provider
dengan dedicated credential melalui Decision Gate baru; jangan menghidupkan
kembali Gmail App Password secara implisit.

## 🤝 Decision Handoff

Project owner menerima Mailpit lokal pada 2026-08-27. Keputusan ini menggantikan
Gmail SMTP dan App Password sebagai current lab baseline, mempertahankan TN-030
sebagai historical planning record, dan menunda seluruh external delivery.

Mailpit tidak mengubah generic notification-channel architecture pada
TM-ADR-0001 dan hanya menjadi disposable lab verification utility. Karena itu,
ADR baru tidak diperlukan. Approval TN-031 tidak mengizinkan source
implementation, image pull, container execution, network atau port change,
persistent runtime, maupun external delivery.

## ⚙️ Commands Executed

```bash
# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
find .. -name AGENTS.md -print
sed -n '1,220p' AGENTS.md
git diff --stat && git diff -- config/alertmanager/alertmanager.yml config/alertmanager/README.md scripts/validate-alertmanager.sh scripts/validate.sh validation/README.md README.md
sed -n '1,240p' config/alertmanager/alertmanager.yml && sed -n '1,260p' scripts/validate-alertmanager.sh

# /home/eddywiyatno/git/devops-handbook
git status --short --branch
find .. -name AGENTS.md -print
sed -n '1,180p' AGENTS.md
rg --files docs/projects/tomcat-monitoring docs/adr/tomcat-monitoring
sed -n '1,140p' docs/projects/tomcat-monitoring/engineering-journal/index.md
sed -n '1,260p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '1,180p' docs/projects/tomcat-monitoring/index.md
sed -n '1,340p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-030-define-alertmanager-email-notification-channel-contract.md
wc -l docs/standards/documentation-standards.md docs/standards/engineering-journal-standards.md docs/standards/writing-standards.md
sed -n '1,280p' docs/standards/documentation-standards.md
sed -n '1,240p' docs/standards/engineering-journal-standards.md
sed -n '241,480p' docs/standards/engineering-journal-standards.md
sed -n '481,720p' docs/standards/engineering-journal-standards.md
sed -n '721,980p' docs/standards/engineering-journal-standards.md
sed -n '241,360p' docs/standards/engineering-journal-standards.md
sed -n '361,480p' docs/standards/engineering-journal-standards.md
sed -n '481,600p' docs/standards/engineering-journal-standards.md
sed -n '601,720p' docs/standards/engineering-journal-standards.md
sed -n '1,280p' docs/standards/writing-standards.md
sed -n '160,280p' docs/standards/writing-standards.md
sed -n '1,260p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n -C 3 'Gmail|App Password|direct email|email langsung|lab-email|Mailpit|notification channel|SMTP' docs/projects/tomcat-monitoring
sed -n '1,220p' docs/projects/tomcat-monitoring/architecture/index.md
sed -n '1,340p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,220p' docs/projects/tomcat-monitoring/development/index.md
sed -n '1,120p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
git diff --check && git diff --stat && git status --short --branch
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md
rg -n '^## |TN-031|TN-031-replace-gmail' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' docs/projects/tomcat-monitoring
rg -n 'Gmail|App Password|smtp\.gmail\.com|direct email|email langsung' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md
command -v mkdocs || true
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md && test -f docs/projects/tomcat-monitoring/architecture/index.md && test -f docs/projects/tomcat-monitoring/infrastructure/index.md && test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
git diff -- docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md
```

Official Google App Password, Google less-secure-app, Alertmanager
configuration, Google Workspace SMTP relay, Gmail API, Amazon SES credential,
dan Mailpit SMTP serta integration-testing documentation direview melalui
read-only web access.

## 🧾 Outcome

Mailpit lokal diterima sebagai current lab SMTP capture dan Gmail App Password
tidak lagi menjadi baseline implementasi. External inbox delivery, Google
credential, dan personal recipient keluar dari scope lab sekarang.

Belum ada Alertmanager source, image, dependency, container, network, port,
runtime, email, cleanup, commit, atau push yang dibuat atau dijalankan. Mailpit
implementation tetap blocked pada Runtime Component Ownership Gate serta
implementation authorization terpisah.

Navigation entry, heading structure, relative file targets, trailing
whitespace, sensitive-data pattern, dan `git diff --check` lulus. MkDocs render
tidak diverifikasi karena executable tidak tersedia dan dependency
installation tidak diotorisasi.

## 🎓 Lessons Learned

Verification email tidak selalu memerlukan external delivery. Memisahkan
message-generation verification dari provider-delivery verification dapat
menghilangkan credential berisiko sekaligus menjaga result boundary yang
lebih jelas.

## ⏭️ Next Steps

Buka Technical Note baru untuk menentukan Mailpit ownership, immutable upstream
pin, disposable topology, exact resources, cleanup, dan implementation plan.
Jangan menarik image atau menjalankan component test sebelum gate tersebut
diterima.

## 🔗 Related Documentation

- [TN-030 — Define Alertmanager Email Notification Channel Contract](TN-030-define-alertmanager-email-notification-channel-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Google App Passwords](https://support.google.com/mail/answer/185833?hl=en)
- [Mailpit Sending Messages](https://mailpit.axllent.org/docs/usage/sending-messages/)
- [Mailpit Integration Testing](https://mailpit.axllent.org/docs/integration/)

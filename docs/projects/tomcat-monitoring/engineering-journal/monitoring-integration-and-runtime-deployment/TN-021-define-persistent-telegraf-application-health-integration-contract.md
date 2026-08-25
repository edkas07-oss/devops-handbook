# TN-021 — Define Persistent Telegraf Application-Health Integration Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery and Assessment |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-25 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Menghasilkan rekomendasi contract yang dapat direview untuk persistent
Telegraf application-health integration, termasuk ownership target, runtime
injection, topology, prerequisite, dan verification boundary.

## 🌍 Background

TN-020 menyelesaikan persistent JMX TLS scrape integration dan menyerahkan
Telegraf persistent integration sebagai aktivitas terpisah. Telegraf source
contract telah lulus component verification pada TN-008, tetapi test tersebut
menggunakan temporary BusyBox fixture, bukan application runtime aktual.

Configuration project mewajibkan `TOMCAT_HEALTH_URL`. Generic launcher
repository `telegraf` hanya menerima file configuration dan tidak menyuntikkan
nilai tersebut. Persistent generic JMX lab target juga tidak membawa
application-specific WAR atau contract `/health`, sehingga target aktual dan
ownership deployment harus ditetapkan sebelum implementation plan dapat dibuat.

## 📚 Scope

Aktivitas ini mencakup read-only inspection terhadap source contract Telegraf,
Tomcat, JMX Exporter, Prometheus, current-state documentation, ADR, dan evidence
TN-008; assessment alternatif target; serta dokumentasi recommendation,
decision handoff, open question, dan navigation TN-021.

Source, configuration, validator, image, container, network, volume,
certificate, application endpoint, dan persistent runtime tidak diubah atau
diuji. Build, component test, deployment, cleanup, commit, push, alerting, serta
end-to-end verification tidak termasuk scope.

## 📥 Inputs

| Input | Relevance |
| --- | --- |
| TN-020 | Menyerahkan persistent Telegraf integration sebagai activity terpisah. |
| TN-008 | Membuktikan component behavior hanya terhadap temporary HTTP fixture. |
| `tomcat-monitoring/config/telegraf/health-check.conf` | Menetapkan required URL, HTTP result, timeout, interval, dan metrics listener. |
| `tomcat-monitoring/config/prometheus/prometheus.yml` | Menetapkan scrape target Telegraf internal `telegraf:9273`. |
| `telegraf/scripts/run.sh` | Menunjukkan generic launcher hanya memasang configuration file. |
| Generic Tomcat dan JMX Exporter contracts | Menentukan bahwa application-specific WAR dan health configuration bukan milik base runtime. |
| TM-ADR-0001 | Menetapkan Telegraf sebagai separate-container application-health checker. |

## 🔍 Findings

### Verified facts

| Fact | State | Evidence |
| --- | --- | --- |
| Telegraf memerlukan `TOMCAT_HEALTH_URL` saat configuration dimuat. | Verified by source inspection | `health-check.conf` dan static validator. |
| Health success berarti HTTP `200` dan body JSON yang memuat `"status":"UP"`; timeout `5s`, interval `30s`. | Verified by source inspection | `health-check.conf`. |
| Telegraf mengekspos metrics internal pada `:9273/metrics`. | Verified by source inspection and historical component test | Source contract dan TN-008. |
| Prometheus configuration menunjuk target internal `telegraf:9273`. | Verified by source inspection | `prometheus.yml`. |
| TN-008 menggunakan temporary BusyBox fixture dan tidak membuktikan application runtime aktual atau persistent deployment. | Verified from journal evidence | Scope Boundary TN-008. |
| Generic Telegraf launcher tidak memiliki interface untuk `TOMCAT_HEALTH_URL`. | Verified by source inspection | `telegraf/scripts/run.sh`. |
| Generic Tomcat hanya memiliki container health check terhadap root HTTP path dan tidak menyediakan application-specific `/health`. | Verified by source inspection | Tomcat `Containerfile`, repository boundary, dan file inventory. |
| JMX Exporter image menambahkan Java Agent, bukan application WAR atau health endpoint. | Verified by source inspection | JMX Exporter `Containerfile` dan README. |

### Integration gap

Existing source telah menentukan consumer-side interface, tetapi belum ada
provider-side implementation. Menggunakan root page generic Tomcat tidak dapat
memenuhi body contract `status: UP` dan hanya membuktikan HTTP connector hidup,
bukan kesehatan aplikasi. Menjalankan fixture secara persistent juga hanya
memindahkan component test menjadi long-running test resource dan tidak
memenuhi objective application-health monitoring.

## 🔀 Alternatives

| Alternative | Assessment | State |
| --- | --- | --- |
| Gunakan root page atau container health check generic Tomcat. | Tidak memenuhi response body contract dan tidak membuktikan kesehatan aplikasi. | Rejected |
| Deploy HTTP fixture sebagai persistent target. | Dapat menghasilkan metrics, tetapi signal hanya menilai fixture dan berisiko disalahartikan sebagai application health. | Rejected |
| Tambahkan application-specific `/health` ke generic Tomcat atau JMX Exporter image. | Melanggar generic repository boundary dan mengikat base image pada satu application contract. | Rejected |
| Tunggu concrete application runtime, lalu inject URL melalui deployment orchestration `tomcat-monitoring`. | Mempertahankan ownership, memenuhi TM-ADR-0001, dan menghasilkan signal aplikasi nyata. | Selected for recommendation |

## ⭐ Recommendation

Gunakan contract berikut sebagai dasar implementation planning setelah
Decision Gate diterima:

| Contract Area | Recommended Contract |
| --- | --- |
| Health provider | Application repository atau deployment owner menyediakan endpoint nyata. |
| Target interface | `http://<application-service>:8080/health` dari network `devops-lab`, dengan HTTP `200` dan JSON `status: UP`. |
| URL ownership | Nilai environment-specific diberikan saat deployment dan tidak di-hardcode ke source. |
| Runtime injection | Deployment orchestration milik `tomcat-monitoring` meneruskan `TOMCAT_HEALTH_URL` ke Telegraf. |
| Generic Telegraf runtime | Repository `telegraf` tetap memiliki image serta generic lifecycle dan tidak memiliki target aplikasi. |
| Generic Tomcat/JMX runtime | Tidak menjadi provider application-health sampai downstream application benar-benar dipasang. |
| Telegraf identity | Persistent container menggunakan network alias `telegraf`; port `9273` hanya tersedia pada container network. |
| Prometheus path | Prometheus tetap mengambil `http://telegraf:9273/metrics`. |
| Implementation prerequisite | Image/revision aplikasi, container atau service name, endpoint behavior, owner, lifecycle, rollback, dan cleanup target harus spesifik. |
| Verification boundary | Uji URL dari Telegraf network, healthy/mismatch/unreachable behavior, metrics scrape Prometheus, persistence/restart, dan exact cleanup atau retained-state handoff. |

Recommendation ini tidak memerlukan ADR baru karena memperjelas penerapan
ownership dan runtime injection di dalam arsitektur TM-ADR-0001 tanpa mengubah
topology atau keputusan arsitektur yang telah accepted.

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Application runtime mana yang menjadi persistent health target pertama? | Open | Project owner bersama application owner | Image/revision, service identity pada `devops-lab`, endpoint `/health`, response contract, dan lifecycle owner ditetapkan serta endpoint tersedia untuk verification. | Persistent Telegraf implementation planning dan deployment. |

## ⚠️ Risks

| Risk | State | Mitigation |
| --- | --- | --- |
| Fixture atau root Tomcat disalahartikan sebagai application-health proof. | Open | Larang keduanya sebagai persistent production-equivalent target. |
| URL injection ditempatkan di generic runtime repository. | Mitigated by recommendation | Pertahankan environment-specific orchestration di `tomcat-monitoring`. |
| TN berikutnya dimulai tanpa exact application lifecycle dan cleanup owner. | Open | Gunakan Open Question closure condition sebagai prerequisite gate. |
| Prometheus scrape Telegraf dianggap sehat berdasarkan source contract. | Open | Wajibkan live scrape verification; source inspection tetap `Not verified` untuk runtime. |

## ⚖️ Decision Handoff

| Item | Status |
| --- | --- |
| Recommended direction | Concrete application runtime + deployment-time URL injection oleh `tomcat-monitoring`. |
| Decision status | Proposed; belum accepted. |
| Decision owner | Project owner. |
| Required input | Persetujuan contract recommendation dan identitas application target pertama. |
| Implementation authorization | Not requested; implementation plan belum dapat dibuat sampai target ditentukan. |

### Resolution — 2026-08-25

Project owner menerima recommended contract dan mengizinkan penggunaan aplikasi
lab kecil sebagai target pertama. Pemilihan bentuk aplikasi didelegasikan untuk
diselesaikan melalui discovery TN-022. Discovery tersebut memilih exploded JSP
webapp milik `tomcat-monitoring`, dipasang sebagai root application pada
persistent `tomcat-jmx-exporter`, tanpa mengubah generic image.

Decision Gate contract berstatus `Accepted`. Open Question target telah
dipersempit menjadi exact source, mount, dan runtime identity pada TN-022,
tetapi deployment tetap menunggu Implementation Gate karena akan mengganti
persistent container dan menambah container Telegraf.

## ✅ Verification

| Criterion | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Source mapping | Setiap finding utama memiliki source evidence. | Passed. | Telegraf, Tomcat, JMX Exporter, Prometheus, TN-008, dan TM-ADR-0001 direview. |
| Decision boundary | Fact, rejected alternatives, recommendation, dan accepted decision tidak tercampur. | Passed. | Recommendation ditandai selected; Decision Handoff tetap Proposed. |
| Runtime boundary | Tidak ada runtime health claim atau external-state mutation. | Passed by command review. | Tidak ada build, Podman, curl, cleanup, atau deployment command. |
| Documentation structure | Metadata, base sections, conditional sections, navigation, links, dan whitespace valid. | Passed. | `git diff --check`, trailing-whitespace scan, heading review, navigation search, dan relative-target checks lulus. |
| MkDocs render | Navigation dapat dirender. | Not verified. | `mkdocs` belum tersedia dari TN-020 dan dependency tidak dipasang dalam scope ini. |

## ⚙️ Commands Executed

Seluruh command berikut merupakan read-only discovery atau documentation
verification. Dua salah-path `sed` dicatat karena command tersebut benar-benar
dijalankan dan gagal sebelum path yang tepat diperiksa.

### Handoff and governance discovery

```bash
# /home/eddywiyatno/git/prompt-template
sed -n '1,260p' prompt-next-technical-note.md

# /home/eddywiyatno/git/devops-handbook
git status --short --branch
tail -80 docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
cat docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
cat AGENTS.md
sed -n '1,280p' docs/standards/engineering-journal-standards.md
sed -n '281,760p' docs/standards/engineering-journal-standards.md
wc -l docs/standards/engineering-journal-standards.md docs/standards/documentation-standards.md docs/standards/writing-standards.md
sed -n '520,900p' docs/standards/engineering-journal-standards.md
sed -n '760,980p' docs/standards/engineering-journal-standards.md
cat docs/standards/documentation-standards.md
cat docs/standards/writing-standards.md
sed -n '160,420p' docs/standards/writing-standards.md
sed -n '180,280p' docs/standards/writing-standards.md
```

### Project, journal, and source-contract discovery

```bash
# /home/eddywiyatno/git/devops-handbook
cat AGENTS.md
git status --short --branch
rg -n "Telegraf|application health|health|TOMCAT_HEALTH_URL|persistent|Next Steps|Open Question" docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/operations/index.md docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
sed -n '1,180p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md
sed -n '180,360p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md
sed -n '1,140p' docs/projects/tomcat-monitoring/index.md
sed -n '1,250p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,130p' docs/projects/tomcat-monitoring/operations/index.md
sed -n '1,280p' docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md

# /home/eddywiyatno/git/tomcat-monitoring
cat AGENTS.md
git status --short --branch
sed -n '1,260p' config/telegraf/health-check.conf
sed -n '1,260p' README.md
sed -n '1,260p' scripts/run.sh
rg -n "TOMCAT_HEALTH_URL|http_response|9273|health-check" .
sed -n '1,260p' validation/validate-telegraf.sh
sed -n '1,180p' config/telegraf/README.md
sed -n '1,180p' scripts/validate-telegraf.sh

# /home/eddywiyatno/git/telegraf
cat AGENTS.md
git status --short --branch
sed -n '1,260p' README.md
sed -n '1,260p' scripts/run.sh

# /home/eddywiyatno/git/tomcat
cat AGENTS.md
git status --short --branch
rg -n "health|WAR|8080|endpoint|application" README.md Containerfile entrypoint.sh scripts PROJECT VERSION CONFIG
sed -n '1,130p' Containerfile
sed -n '1,180p' README.md
rg --files

# /home/eddywiyatno/git/tomcat-jmx-exporter
sed -n '1,180p' Containerfile
sed -n '1,220p' README.md
rg --files
```

Command `sed -n '1,260p' scripts/run.sh` pada repository `tomcat-monitoring`
gagal karena repository integration memang tidak memiliki launcher tersebut.
Command `sed -n '1,260p' validation/validate-telegraf.sh` gagal karena validator
aktual berada pada `scripts/validate-telegraf.sh`; pemeriksaan kemudian diulang
dengan path yang tepat.

### Documentation verification

```bash
# /home/eddywiyatno/git/devops-handbook
git diff --check
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n '^## ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
rg -n 'TN-021|TN-021-define-persistent-telegraf' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|keystore-password[^`[:space:]]*=' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
command -v mkdocs
git diff --stat -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-021-define-persistent-telegraf-application-health-integration-contract.md
git status --short --branch
```

`git diff --check`, file existence, heading, dan navigation checks lulus.
Trailing-whitespace dan secret-pattern scans tidak menghasilkan temuan.
`command -v mkdocs` tidak menghasilkan path, sehingga render tidak dijalankan.

## 🔄 Source-Control Handoff

TN-021 dan navigation masih berupa perubahan working tree Handbook. Tidak ada
source repository yang berubah. Commit memerlukan authorization terpisah;
push tetap merupakan tindakan manual operator setelah session handoff.

## 🧾 Outcome

Assessment selesai dan menghasilkan recommended persistent integration
contract yang mempertahankan repository boundary. Persistent generic JMX
target, Tomcat root page, dan long-running fixture tidak layak menjadi
application-health provider. Target yang valid harus berupa concrete
application runtime, sedangkan `tomcat-monitoring` memiliki deployment-time URL
injection dan configuration integration.

Objective discovery TN-021 selesai karena findings, alternatives, risks,
recommendation, open question, dan decision handoff telah tersedia. Pada
closure awal contract masih proposed; project owner kemudian menerimanya dan
mendelegasikan pemilihan aplikasi lab kecil melalui resolution di atas.
Persistent Telegraf implementation tetap menunggu exact Implementation Gate
TN-022. Tidak ada source atau runtime state yang berubah.

## ⏭️ Next Steps

Setelah Decision Gate diterima dan concrete application target ditentukan,
buat implementation-planning activity baru untuk resource identity, exact
runtime command atau orchestration artifact, rollback, cleanup, dan live
verification. Jangan memulai persistent Telegraf deployment hanya dengan
temporary fixture atau generic Tomcat target.

## 🔗 Related Documentation

- [TN-020 — Deploy Persistent Lab JMX TLS Scrape Integration](TN-020-deploy-persistent-lab-jmx-tls-scrape-integration.md)
- [TN-022 — Deploy Persistent Tomcat Lab Health Application and Telegraf Integration](TN-022-deploy-persistent-tomcat-lab-health-application-and-telegraf-integration.md)
- [TN-008 — Verify Telegraf Health Check with Edkas-pc1 Alias](TN-008-verify-telegraf-health-check-with-edkas-pc1-alias.md)
- [Infrastructure](../../infrastructure/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

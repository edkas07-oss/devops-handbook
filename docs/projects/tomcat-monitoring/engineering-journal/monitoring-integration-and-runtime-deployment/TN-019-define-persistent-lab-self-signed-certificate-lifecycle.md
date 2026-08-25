# TN-019 — Define Persistent Lab Self-Signed Certificate Lifecycle

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

Menetapkan lifecycle self-signed certificate persistent lab yang dapat menjadi
prerequisite implementation JMX TLS scrape tanpa menyimpan secret di Git atau
image.

## 🌍 Background

TN-018 menerima self-signed certificate dengan SAN
`DNS:tomcat-jmx-exporter`, tetapi lokasi non-Git, ownership, permission,
validity, renewal, revocation, serta rollback material masih `Deferred`.
Persistent runtime dan truststore mutation tidak boleh dimulai sebelum
lifecycle tersebut jelas.

Project owner menyetujui default certificate lifecycle TN-019 pada 2026-08-25.
Approval hanya mencakup decision record dan current-state documentation. Tidak
ada directory, key, certificate, password, keystore, container, volume, atau
runtime yang boleh dibuat maupun diubah.

## 📚 Scope

- Tetapkan identity, lokasi persistent non-Git, ownership, dan permission.
- Tetapkan validity, renewal trigger, distribution, revocation, serta rollback
  boundary.
- Konsolidasikan accepted lab contract ke Infrastructure documentation.
- Perbarui phase navigation dan jalankan documentation checks.

Certificate generation, secret read, source atau configuration change,
container, volume, network, image, runtime, cleanup, commit, push, publication,
dan deployment tidak termasuk scope.

## 📥 Inputs

- Accepted persistent integration boundary TN-018.
- JMX Exporter runtime paths untuk configuration, PKCS12 keystore, dan
  password file.
- Prometheus trust-file contract
  `/run/secrets/tomcat-monitoring/jmx-exporter-ca.crt`.
- Project-owner approval terhadap default lifecycle pada 2026-08-25.

## 🔍 Findings

| Finding | State | Evidence |
| --- | --- | --- |
| Certificate type | Accepted | Self-signed certificate hanya digunakan untuk persistent lab. |
| TLS identity | Accepted | SAN wajib `DNS:tomcat-jmx-exporter`, sesuai internal scrape alias. |
| Secret boundary | Accepted | Material persistent berada di luar Git dan image pada directory yang hanya dimiliki lab runtime operator. |
| Validity | Accepted | Certificate berlaku 365 hari dan diperbarui ketika remaining validity mencapai 30 hari. |
| Rotation safety | Accepted | Material lama dipertahankan sampai Prometheus membuktikan target baru `up=1` dengan strict verification. |
| Production boundary | Unchanged | Contract ini tidak menetapkan production CA atau certificate lifecycle. |

## 🛠️ Alternatives

| Alternative | State | Assessment |
| --- | --- | --- |
| Temporary directory | Rejected | Tidak sesuai persistent lifecycle dan dapat hilang saat host lifecycle berubah. |
| Repository directory | Rejected | Berisiko memasukkan private key atau password ke Git dan build context. |
| Persistent non-Git user-data directory | Selected | Selaras dengan rootless Podman ownership dan memisahkan secret dari source repository. |
| Internal atau production CA | Deferred outside lab scope | Tidak diperlukan untuk lab contract dan tetap memerlukan infrastructure/PKI decision tersendiri. |

## ⚠️ Risks

| Risk | State | Mitigation |
| --- | --- | --- |
| Private key atau password terbaca user lain | Mitigated by contract | Directory `0700`; key, password, dan PKCS12 `0600`. |
| Certificate expiry menghentikan scrape | Mitigated by contract | Renewal dimulai saat remaining validity 30 hari. |
| Rotation memutus trust | Mitigated by contract | Pertahankan previous material sampai new target `up=1`; pulihkan previous set bila verification gagal. |
| Old self-signed certificate tetap dipercaya | Mitigated by contract | Setelah cutover berhasil, ganti CA trust dan keluarkan previous certificate dari active truststore. |
| Secret masuk log atau journal | Mitigated by contract | Jangan mencetak password, private key, PKCS12 content, atau secret-derived output. |

## ⚖️ Decision

Persistent lab menggunakan lifecycle berikut:

| Concern | Accepted contract |
| --- | --- |
| Lifecycle owner | Project owner sebagai lab runtime owner; filesystem material dimiliki rootless Podman user. |
| Directory | `/home/eddywiyatno/.local/share/tomcat-monitoring/jmx-exporter-tls` di luar seluruh source repository. |
| Directory mode | `0700`. |
| Private key | `server.key`, mode `0600`. |
| Public certificate | `server.crt`, mode `0444`, sekaligus CA trust untuk self-signed lab identity. |
| PKCS12 | `keystore.p12`, mode `0600`. |
| Password file | `keystore-password`, mode `0600`; nilai tidak dicetak. |
| Subject identity | SAN `DNS:tomcat-jmx-exporter`; Common Name tidak digunakan sebagai pengganti SAN. |
| Validity | 365 hari. |
| Renewal trigger | Remaining validity 30 hari. |
| Distribution | Keystore dan password dipasang read-only pada Tomcat/JMX container; public certificate disalin ke `prometheus_truststore` sebagai `jmx-exporter-ca.crt`. |
| Rotation | Generate next material terpisah, verifikasi identity dan permissions, update target dan trust, lalu buktikan `up=1`. |
| Rollback | Previous complete material set dipertahankan sampai successful scrape; bila gagal, pulihkan previous target material dan CA trust. |
| Revocation model | Self-signed lab tidak menggunakan CRL/OCSP; hentikan trust dengan mengganti active CA file dan tidak lagi menjalankan target dengan old certificate. |
| Cleanup | Previous material hanya boleh dihapus setelah new target `up=1`, rollback tidak lagi diperlukan, exact path diperiksa, dan destructive authorization diberikan. |

## 🧭 Decision Handoff

Decision menyelesaikan certificate-lifecycle prerequisite TN-018 pada tingkat
contract. Implementation berikutnya tetap memerlukan exact command plan,
preflight collision check, certificate generation authorization, Prometheus
mutation/downtime plan, rollback sequence, verification criteria, dan exact
cleanup authorization.

Contract ini menerapkan server-side TLS boundary TM-ADR-0001 pada persistent
lab tanpa mengubah architecture decision. Production CA dan lifecycle tetap
berada di luar scope sehingga ADR baru tidak diperlukan.

## ⚙️ Commands Executed

### Readiness and source review

```bash
git status --short --branch
sed -n '1,340p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
sed -n '128,165p;185,225p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '90,140p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
sed -n '18,35p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
```

Working tree berisi controlled journal migration dan TN-018 yang dipertahankan.
Current-state Infrastructure masih menyatakan seluruh certificate lifecycle
belum ditetapkan; TN-019 membatasi resolution pada persistent lab.

### Documentation validation

```bash
git diff --check
git diff --no-index --check /dev/null docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-018-define-persistent-lab-jmx-scrape-integration-contract.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
test -f docs/adr/tomcat-monitoring/adr-records/TM-ADR-0001.md
rg -n 'TN-018|TN-019|Status \| Completed|self-signed|365|30 hari|0700|0600|0444|Production certificate' docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-019-define-persistent-lab-self-signed-certificate-lifecycle.md
command -v mkdocs
git status --short --branch
```

Diff, trailing whitespace, file existence, navigation order, dan exact
certificate-contract references lulus. MkDocs render berstatus `Not verified`
karena executable tidak tersedia dan dependency tidak dipasang.

## 🧾 Outcome

Persistent lab self-signed certificate lifecycle telah diterima, termasuk
non-Git storage, owner boundary, permissions, 365-day validity, 30-day renewal
trigger, distribution, rotation, rollback, revocation model, dan cleanup gate.
Production certificate lifecycle tetap `Not determined`.

Documentation checks lulus kecuali MkDocs render tidak tersedia.

Tidak ada directory, certificate, private key, password, keystore, source,
configuration, container, volume, network, image, runtime, atau external state
yang dibuat, dibaca, maupun diubah.

## ⏭️ Next Steps

Siapkan implementation plan terpisah untuk generation self-signed material,
persistent Tomcat/JMX startup, Prometheus configuration dan truststore update,
controlled Prometheus replacement, verification, rollback, serta exact cleanup
boundary.

## 🔗 Related Documentation

- [TN-018 — Define Persistent Lab JMX Scrape Integration Contract](TN-018-define-persistent-lab-jmx-scrape-integration-contract.md)
- [Infrastructure](../../infrastructure/index.md)
- [Architecture](../../architecture/index.md)
- [TM-ADR-0001](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md)

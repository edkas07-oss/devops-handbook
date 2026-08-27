# TN-032 — Define Mailpit Runtime Ownership and Disposable Verification Contract

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

Menetapkan ownership, immutable upstream identity, disposable topology, exact
resources, security boundary, cleanup, dan implementation handoff Mailpit
sebelum image pull atau component test diizinkan.

## 🌍 Background

TN-031 menggantikan Gmail App Password dengan Mailpit lokal sebagai isolated
SMTP capture. Mailpit merupakan runtime container baru sehingga Runtime
Component Ownership Gate harus selesai sebelum source integration, image pull,
atau component test.

Project owner menyetujui TN-032 untuk menentukan contract tersebut tanpa
menjalankan implementation. Working tree `tomcat-monitoring` dan
`devops-handbook` masih menyimpan perubahan TN-029 sampai TN-031 yang harus
dipertahankan.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- memverifikasi upstream image source dan stable release Mailpit;
- menilai repository runtime, repository baru, dan direct-upstream exception;
- menentukan immutable image reference, ownership source, dan upgrade gate;
- menentukan disposable network, containers, internal endpoint, loopback
  ports, synthetic identity, lifecycle, rollback, serta cleanup contract;
- melakukan read-only collision inspection terhadap exact resource names dan
  ports; serta
- memperbarui Engineering Journal dan navigation.

Image pull, source atau validator change, dependency installation, network atau
container creation, port publication, runtime execution, generated data,
cleanup mutation, persistent deployment, external delivery, commit, dan push
tidak termasuk.

## 📥 Inputs

| Input | Relevant Evidence |
| --- | --- |
| TN-031 | Mailpit dipilih sebagai disposable SMTP capture; ownership dan immutable pin masih terbuka. |
| Official image documentation | Upstream menyediakan official Docker Hub image dan GHCR mirror dengan stable release tags. |
| Official GHCR package | `v1.31.0` tersedia dengan multi-platform manifest digest dan platform-specific manifests. |
| Development host | `x86_64` dengan rootless Podman `4.9.3`. |
| Collision inspection | Candidate container names, network name, dan loopback ports tidak digunakan pada 2026-08-27. |

## 🔍 Findings

### Upstream identity and pinning

Mailpit upstream adalah `axllent/mailpit`. Official documentation menyatakan
Docker Hub sebagai source image resmi dan GHCR sebagai mirror. GHCR dipilih
karena halaman package resminya menyediakan immutable manifest identity yang
dapat ditelusuri tanpa bergantung pada mutable `latest` atau minor tag.

Identity yang dinilai dan kemudian diterima pada 2026-08-27 adalah:

| Property | Accepted Contract |
| --- | --- |
| Upstream source | `https://github.com/axllent/mailpit` |
| Registry | `ghcr.io` official mirror |
| Release | `v1.31.0` |
| Immutable reference | `ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24` |
| Manifest scope | Multi-platform manifest list |
| Observed `linux/amd64` child | `sha256:29154cb86d35bcff4c0f82f185fc6720e89248b2cd2bc43f312a2b31fddd34ad` |
| Mutable tags | `latest`, `edge`, dan minor-only tag dilarang sebagai runtime identity |

Tag tetap disertakan agar intent versi mudah dibaca, sedangkan digest menjadi
identity yang menentukan bytes. Implementation preflight harus membuktikan
bahwa resolved manifest, platform `linux/amd64`, dan reported Mailpit version
sesuai sebelum verification result diterima. Perubahan version atau digest
memerlukan assessment serta authorization baru.

### Ownership assessment

| Option | Assessment | State |
| --- | --- | --- |
| Existing generic runtime repository | Tidak tersedia dan tidak diperlukan oleh component lain saat ini. | Rejected |
| New generic Mailpit runtime repository | Memberi lifecycle build sendiri, tetapi berlebihan untuk disposable upstream test utility tanpa customization. | Rejected |
| Direct-upstream exception | Menjaga Mailpit sebagai bounded test dependency; no build, publication, persistent lifecycle, atau production ownership ditambahkan. | Accepted |

Pada accepted boundary, upstream memiliki image build dan release. Repository
`tomcat-monitoring` hanya memiliki immutable reference, disposable verification
script, temporary configuration, validation assertions, dan cleanup behavior.
Tidak ada Mailpit image yang dibangun, ditag ulang, atau dipublikasikan project.

### Disposable topology

```text
Host test driver
  |-- http://127.0.0.1:19093 --> tm-tn033-alertmanager:9093
  `-- http://127.0.0.1:18025 --> tm-tn033-mailpit:8025 API

tm-tn033-mailpit network
  tm-tn033-alertmanager --SMTP--> mailpit:1025
  tm-tn033-mailpit
```

| Resource | Exact Contract |
| --- | --- |
| Network | `tm-tn033-mailpit` |
| Mailpit container | `tm-tn033-mailpit` |
| Alertmanager container | `tm-tn033-alertmanager` |
| Mailpit network alias | `mailpit` |
| Mailpit SMTP | Internal `mailpit:1025`; never published to host |
| Mailpit API | Container `8025`, host `127.0.0.1:18025` only |
| Alertmanager API | Container `9093`, host `127.0.0.1:19093` only |
| Sender | `alertmanager@tomcat-monitoring.invalid` |
| Recipient | `operator@tomcat-monitoring.invalid` |
| Storage | No named volume atau host bind; disposable container storage only |
| Restart | Disabled; no persistent service behavior |
| External relay | Disabled and prohibited |

The `.invalid` domain keeps sender and recipient synthetic. The API and
Alertmanager ports are published only because the host test driver must inject
alerts and inspect captured messages. SMTP remains internal to the dedicated
network.

Read-only inspection found no existing exact container or network with these
names and no listener on ports `18025` or `19093`. This observation is not a
reservation; implementation must repeat collision preflight immediately before
resource creation.

### Lifecycle and cleanup contract

Implementation must use a temporary directory created with `mktemp -d` for the
temporary Alertmanager configuration and bounded evidence. A cleanup trap must
target only the two exact containers, exact network, and resolved temporary
directory. Cleanup must run after success, failure, or interruption.

The implementation record must distinguish:

1. preflight absence and port availability;
2. image acquisition using the accepted immutable reference;
3. disposable network and container creation;
4. Mailpit API readiness and Alertmanager readiness;
5. synthetic firing and resolved capture assertions;
6. exact cleanup; and
7. post-cleanup absence plus closed loopback ports.

Image removal is not part of automatic cleanup. Removing the pulled image is a
separate destructive action requiring exact digest inspection and explicit
authorization. Rollback for source changes is a reviewed source reversal, not
a runtime resource replacement; no persistent state exists to restore.

## ⚠️ Risks

| Risk | State | Mitigation or Follow-up |
| --- | --- | --- |
| Mutable upstream tag changes silently | Mitigated by accepted contract | Pin version plus manifest digest; verify platform child and reported version. |
| Direct upstream becomes an unmanaged production dependency | Mitigated by boundary | Limit exception to disposable lab verification; reopen ownership gate for persistent or reusable use. |
| Mailpit API is exposed beyond the host | Mitigated by contract | Bind API only to `127.0.0.1`; do not publish SMTP. |
| Local untrusted input reaches Mailpit | Mitigated by contract | Dedicated network, synthetic bounded messages, no external relay, and exact test lifetime. |
| Candidate port becomes occupied after assessment | Open implementation risk | Repeat collision preflight immediately before creation and fail closed. |
| Cleanup removes unrelated resource | Mitigated by contract | Exact TN-scoped names, ownership labels, collision failure, and no wildcard cleanup. |
| Image remains in local store | Accepted pending separate decision | Do not conflate disposable runtime cleanup with destructive image removal. |

## ❓ Open Questions

| Question | State | Owner | Closure Condition | Blocked Activity |
| --- | --- | --- | --- | --- |
| Apakah direct-upstream exception dengan exact `v1.31.0` digest diterima? | Answered | Project owner | Direct-upstream exception dan immutable reference diterima pada 2026-08-27 | N/A; implementation tetap memerlukan authorization terpisah |
| Apakah image harus dihapus setelah verification? | Deferred | Project owner | Exact local image identity tersedia dan destructive cleanup authorization diberikan | Image cleanup only; tidak memblokir component verification |
| Apakah Mailpit akan menjadi persistent atau reusable runtime? | Deferred | Project owner | Requirement baru tersedia; ownership gate dibuka kembali | Future persistent or shared use |

## 💡 Recommendation

Terima direct-upstream exception dengan exact immutable reference
`ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24`.
Gunakan topology, names, ports, synthetic identities, no-volume boundary, dan
cleanup contract TN-032 hanya untuk disposable lab verification.

Dengan Decision Gate diterima, TN-032 ditutup. Buka TN-033 untuk source
implementation serta isolated Mailpit capture verification dengan
authorization terpisah untuk source changes, exact image pull, disposable
network/containers, loopback ports, runtime test, dan exact cleanup.

## 🤝 Decision Handoff

Project owner menerima direct-upstream exception dan exact immutable reference
pada 2026-08-27. Upstream memiliki image build serta release, sedangkan
`tomcat-monitoring` memiliki immutable reference, disposable verification
script, temporary configuration, assertions, dan exact cleanup behavior.

Acceptance menutup Runtime Component Ownership Gate hanya untuk disposable lab
verification. Persistent, reusable, production, retagged, atau project-built
Mailpit tetap memerlukan ownership gate baru. Decision ini tidak mengizinkan
image pull, source implementation, container execution, port publication, atau
cleanup mutation.

## ⚙️ Commands Executed

```bash
# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch && uname -m && command -v podman && podman --version
ss -ltn '( sport = :18025 or sport = :19093 )'
podman container exists tm-tn033-mailpit; printf 'mailpit_container=%s\n' "$?"; podman container exists tm-tn033-alertmanager; printf 'alertmanager_container=%s\n' "$?"; podman network exists tm-tn033-mailpit; printf 'network=%s\n' "$?"

# Approved read-only retry outside the restricted sandbox
podman --version; podman container exists tm-tn033-mailpit; printf 'mailpit_container=%s\n' "$?"; podman container exists tm-tn033-alertmanager; printf 'alertmanager_container=%s\n' "$?"; podman network exists tm-tn033-mailpit; printf 'network=%s\n' "$?"; ss -ltn '( sport = :18025 or sport = :19093 )'

# /home/eddywiyatno/git/devops-handbook
git status --short --branch && sed -n '1,340p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md
git diff --check && git status --short --branch
sed -n '1,420p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md
rg -n '^## |TN-032|c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24|29154cb86d35bcff4c0f82f185fc6720e89248b2cd2bc43f312a2b31fddd34ad' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' docs/projects/tomcat-monitoring
test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md && test -f docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md
command -v mkdocs || true
rg -n -C 2 'Mailpit|ownership|immutable' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/architecture/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md
git diff --check
rg -n -C 2 'Mailpit.*(pending|not determined)|ownership.*pending|Decision Gate masih menunggu|TN-032 tetap `In Progress`|Pending project-owner' docs/projects/tomcat-monitoring
rg -n 'Status \| Completed|Direct-upstream exception.*Accepted|c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24|TN-032-define-mailpit' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
git status --short --branch && git diff --stat
```

The initial Podman and socket inspection failed inside the restricted sandbox
because the runtime directory and netlink socket were unavailable. The exact
read-only check was repeated with approval outside the sandbox and succeeded;
it did not create, start, stop, or remove any resource.

Official Mailpit Docker documentation, GHCR package metadata for `v1.31.0`,
upstream release information, and relevant upstream security advisories were
reviewed through read-only web access.

## 🧾 Outcome

Assessment menghasilkan direct-upstream recommendation, exact immutable image,
repository boundary, disposable topology, security controls, resource names,
ports, lifecycle, rollback, dan cleanup contract. Candidate resources tidak
berkonflik ketika diperiksa pada 2026-08-27.

Project owner menerima direct-upstream exception, exact immutable image,
repository boundary, disposable topology, security controls, resource names,
ports, lifecycle, rollback, dan cleanup contract. Runtime Component Ownership
Gate selesai untuk disposable lab verification.

Tidak ada source, image, container, network, port publication, runtime data,
cleanup mutation, commit, atau push yang dibuat atau dijalankan.

Navigation, heading structure, digest transcription, link targets, trailing
whitespace, dan `git diff --check` lulus. Sensitive-data scan hanya menemukan
dua synthetic `.invalid` addresses yang memang menjadi contract test; tidak ada
credential atau personal address. MkDocs render tidak diverifikasi karena
executable tidak tersedia dan dependency installation tidak diotorisasi.

## ⏭️ Next Steps

Buka TN-033 untuk source implementation dan isolated Mailpit capture
verification. Scope tersebut memerlukan authorization terpisah untuk source
changes, exact image pull, disposable network dan containers, loopback ports,
runtime test, serta exact cleanup.

## 🔗 Related Documentation

- [TN-031 — Replace Gmail Lab Delivery with Local Mailpit Capture Contract](TN-031-replace-gmail-lab-delivery-with-local-mailpit-capture-contract.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Mailpit Docker Images](https://mailpit.axllent.org/docs/install/docker/)
- [Mailpit GHCR Package](https://github.com/axllent/mailpit/pkgs/container/mailpit)
- [Mailpit v1.31.0 Package](https://github.com/axllent/mailpit/pkgs/container/mailpit/1159210268?tag=v1.31.0)

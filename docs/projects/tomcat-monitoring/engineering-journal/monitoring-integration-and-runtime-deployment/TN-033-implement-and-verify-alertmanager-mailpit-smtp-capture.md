# TN-033 — Implement and Verify Alertmanager Mailpit SMTP Capture

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

Mengimplementasikan non-secret Alertmanager email receiver untuk Mailpit dan
memverifikasi isolated firing serta resolved SMTP capture menggunakan exact
disposable topology TN-032.

## 🌍 Background

TN-031 memilih Mailpit lokal agar lab tidak memerlukan Gmail credential atau
external delivery. TN-032 menerima direct-upstream exception, immutable
Mailpit `v1.31.0` image, exact resources, loopback ports, synthetic identities,
dan cleanup contract.

Working tree masih menyimpan perubahan TN-029 sampai TN-032. TN-033 harus
meneruskan perubahan tersebut tanpa reset, overwrite, atau unrelated cleanup.

## 📚 Scope

Aktivitas yang disetujui mencakup:

- mengubah Alertmanager configuration dari webhook lab receiver menjadi
  non-secret Mailpit email receiver;
- memperbarui static validator, repository validator, verification interface,
  dan documentation yang terkait langsung;
- menarik exact accepted Mailpit image;
- membuat network `tm-tn033-mailpit`, containers `tm-tn033-mailpit` serta
  `tm-tn033-alertmanager`, dan loopback bindings `18025` serta `19093`;
- menjalankan static, shell, semantic, dan isolated firing/resolved capture
  verification; serta
- menghapus exact containers, network, dan temporary files yang dibuat TN-033.

Image Mailpit tetap disimpan. Persistent runtime, named volume, host SMTP
publication, external relay atau email, credential, personal recipient,
Prometheus delivery, commit, dan push tidak termasuk.

## 📋 Prerequisites

| Prerequisite | Expected State | Initial State |
| --- | --- | --- |
| Ownership gate | Direct-upstream exception and immutable pin accepted | Satisfied by TN-032 |
| Mailpit image | Exact `v1.31.0` manifest digest accepted | Satisfied by TN-032; not yet pulled |
| Alertmanager image | `localhost/alertmanager:1.0.0` available | To verify before runtime |
| Exact resources | Candidate names absent | Read-only TN-032 inspection passed; repeat before creation |
| Loopback ports | `18025` and `19093` available | Read-only TN-032 inspection passed; repeat before creation |
| Secrets | None required | Satisfied |

## ⚖️ Execution Decision

Use the TN-032 direct-upstream exception and exact Mailpit reference:

```text
ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24
```

Mailpit SMTP remains internal at `mailpit:1025`. The host test driver reaches
only Mailpit API `127.0.0.1:18025` and Alertmanager API
`127.0.0.1:19093`. No external relay or persistent storage is allowed.

## 🗺️ Architecture

```text
Host verification script
  |-- POST synthetic alerts --> 127.0.0.1:19093
  `-- inspect messages -------> 127.0.0.1:18025

tm-tn033-alertmanager --SMTP--> mailpit:1025
         \________ tm-tn033-mailpit network ________/
```

## 🧭 Implementation Plan

1. Record preflight state and implement source plus validation contracts.
2. Run shell syntax and static repository validation.
3. Pull and verify the exact Mailpit image identity.
4. Run semantic configuration check and isolated firing/resolved capture.
5. Audit exact cleanup and consolidate verified results into documentation.

Rollback for source changes is limited to a reviewed follow-up change; user
changes are not reset. Runtime cleanup targets only resources created by this
activity. Image removal requires separate authorization and is excluded.

## ⚙️ Implementation

Active Alertmanager receiver berubah dari `integration-bridge` webhook menjadi
`lab-mailpit` email receiver. Configuration menetapkan:

- internal-only SMTP `mailpit:1025` dengan `require_tls: false` karena koneksi
  hanya berada pada disposable container network;
- synthetic sender `alertmanager@tomcat-monitoring.invalid` dan recipient
  `operator@tomcat-monitoring.invalid`;
- `send_resolved: true`, lima stable grouping labels, dan deterministic subject;
  serta
- tidak ada authentication, secret, personal identity, relay, atau external
  endpoint.

Static validator memeriksa exact receiver contract, reserved `.invalid`
identities, ketiadaan active webhook dan credential, serta exact Mailpit
verification resources. Repository validator mewajibkan interface baru
`scripts/verify-alertmanager-mailpit.sh`.

Verification interface menarik immutable Mailpit reference, memverifikasi
manifest digest, platform dan API-reported version, membuat exact network serta
containers, mempercepat grouping hanya pada temporary configuration, kemudian
mengirim synthetic firing dan resolved alert melalui Alertmanager API v2.
Mailpit API membuktikan dua subject dan message identities yang diharapkan.
Historical TN-029 webhook interface dipertahankan dengan temporary webhook
configuration sendiri sehingga tidak bergantung pada active receiver. Syntax
interface tersebut divalidasi, tetapi runtime TN-029 tidak diulang pada TN-033.

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| Shell and static validation | Updated scripts parse and source contract passes | Passed | `bash -n scripts/*.sh`, `./scripts/validate.sh`, and `git diff --check` exit `0` |
| Semantic configuration | `amtool check-config` accepts Mailpit receiver | Passed | `semantic_config=passed` from exact Alertmanager container |
| Image identity | Accepted manifest resolves to `linux/amd64` and Mailpit `v1.31.0` | Passed | Digest `sha256:c96991d9...c9ce24`, platform `linux/amd64`, API version `v1.31.0` |
| Isolated capture | One firing and one resolved email match synthetic contract | Passed | Sequence, sender, recipient, both subjects, and body tokens for all five grouping labels passed |
| Security boundary | SMTP is internal and no credential or external delivery is used | Passed | `smtp_endpoint=mailpit:1025 host_smtp_published=false`; only loopback APIs were published |
| Cleanup audit | Exact containers, network, temporary files, and listeners are absent | Passed | Containers/network absent, ports released, volumes unchanged, image retained |
| Documentation consistency | Current-state pages and TN navigation reflect completed implementation | Passed with tooling limitation | Link/navigation references and `git diff --check` passed; MkDocs executable was not installed, so rendered-site build was not run |

## ⚙️ Commands Executed

```bash
# /home/eddywiyatno/git/tomcat-monitoring
sed -n '1,420p' scripts/verify-alertmanager-webhook.sh
sed -n '1,260p' scripts/validate.sh && sed -n '1,300p' scripts/validate-alertmanager.sh
sed -n '1,260p' README.md && sed -n '1,240p' config/alertmanager/README.md && sed -n '1,220p' validation/README.md
git diff -- README.md config/alertmanager/README.md scripts/validate-alertmanager.sh scripts/validate.sh validation/README.md && git status --short --branch
git status --short && sed -n '1,240p' config/alertmanager/alertmanager.yml && sed -n '1,280p' scripts/validate-alertmanager.sh && sed -n '1,260p' scripts/validate.sh && sed -n '1,320p' scripts/verify-alertmanager-webhook.sh
sed -n '1,280p' README.md && sed -n '1,260p' config/alertmanager/README.md && sed -n '1,300p' validation/README.md && sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md
chmod 0755 scripts/verify-alertmanager-mailpit.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
./scripts/verify-alertmanager-mailpit.sh
podman image inspect --format 'digest={{.Digest}} arch={{.Architecture}} os={{.Os}} labels={{json .Labels}}' 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
podman ps -a --filter name=tm-tn033 --format '{{.Names}}'
podman network ls --filter name=tm-tn033-mailpit --format '{{.Name}}'
rg -n "TN-033|Mailpit|mailpit|Pending|not yet pulled|belum diimplementasikan|belum diterapkan" docs/projects/tomcat-monitoring -g '*.md'
rg -n 'Mailpit.*(pending|not implemented|not verified)|source integration, image pull|runtime belum dikerjakan|implementation pending|source, image, and runtime not implemented' docs/projects/tomcat-monitoring -g '*.md'
rg -n 'Status \| Completed|message_body_group_labels|exit `0`|TN-033-implement-and-verify' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
if command -v mkdocs >/dev/null; then mkdocs --version; else echo 'mkdocs=not-installed'; fi
```

Runtime verification dijalankan empat kali. Dua run pertama berhasil menangkap
firing/resolved dan menyelesaikan cleanup, tetapi interface berakhir nonzero
ketika `/mailpit --version` dipipe ke `head` (`141`) lalu ketika binary tersebut
mengembalikan nonzero untuk opsi versi (`1`). Version evidence dipindahkan ke
supported `/api/v1/info`; run ketiga selesai `exit 0`. Final run menambahkan
full-message API assertion dan membuktikan body memuat seluruh stable label serta
value, lalu selesai `exit 0`. Setiap run melaporkan exact cleanup passed, jadi
tidak ada container atau network TN-033 tertinggal.

## 🔀 Version-Control Handoff

Project owner memberikan authorization commit terpisah setelah implementation
dan verification selesai pada 2026-08-27. Source repository
`tomcat-monitoring` dicatat dalam commit `f380636` (`feat: add Alertmanager
delivery verification`). Engineering Journal dan current-state documentation
disimpan melalui commit terpisah pada repository `devops-handbook`. Push tetap
tidak diotorisasi dan tidak dilakukan.

## 🧾 Outcome

TN-033 selesai. Alertmanager sekarang memiliki active non-secret Mailpit email
receiver dan reproducible isolated verification interface. Final runtime
verification membuktikan semantic parse, accepted Mailpit image identity,
firing/resolved SMTP capture, synthetic sender/recipient, internal-only SMTP,
serta exact cleanup. Immutable Mailpit image tetap tersedia sesuai authorization.

Klaim ini tidak mencakup persistent Alertmanager, Prometheus-to-Alertmanager
delivery, inbox delivery, provider authentication, external relay, Integration
Bridge, TrueSight, commit, atau push.

## ❓ Open Questions

| Question | Status | Owner | Closure Condition |
| --- | --- | --- | --- |
| Apakah Alertmanager akan diterapkan pada persistent lab? | Deferred | Project owner | New Technical Note accepts topology, continuity, rollback, exact resources, and runtime authorization |
| Apakah Prometheus-to-Alertmanager runtime delivery akan diverifikasi? | Deferred | Project owner | Persistent or isolated delivery target and verification boundary are approved |
| Apakah inbox atau external event delivery diperlukan? | Deferred | Project owner and future integration owner | Provider or Integration Bridge ownership, TLS/authentication, secret lifecycle, recipient handling, and external-delivery authorization are accepted |

## ⏭️ Next Steps

Tentukan activity berikutnya melalui Technical Note baru. Kandidat terdekat
adalah persistent Alertmanager integration atau Prometheus delivery
verification; keduanya memerlukan topology, continuity, rollback, exact runtime
resources, dan authorization tersendiri. External delivery tetap deferred.

## 🔗 Related Documentation

- [TN-032 — Define Mailpit Runtime Ownership and Disposable Verification Contract](TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)

# TN-028 — Implement Alertmanager Configuration and Validation Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-26 |
| Recorded Date | 2026-08-26 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-26 |

## 🎯 Objective

Mengimplementasikan configuration Alertmanager non-secret, static validator,
dan Prometheus delivery reference, lalu memverifikasi semantics menggunakan
local component images tanpa persistent deployment atau external endpoint.

## 🌍 Background

TN-025 menetapkan grouping labels, receiver boundary, internal interface, dan
secret-reference contract. TN-027 kemudian menghasilkan local image
`localhost/alertmanager:1.0.0` yang lulus component smoke test. Project owner
menyetujui implementation source dan semantic validation tersebut, tetapi
tidak mengizinkan persistent Alertmanager, endpoint Integration Bridge aktual,
secret provisioning, atau external notification.

## 📚 Scope

Aktivitas ini mencakup:

- Menambahkan `config/alertmanager/alertmanager.yml` dengan route baseline dan
  receiver `integration-bridge`.
- Menggunakan `url_file` pada
  `/run/secrets/tomcat-monitoring/integration-bridge-webhook-url`; tidak ada URL
  atau credential aktual di Git.
- Menambahkan static Alertmanager validator dan menghubungkannya ke aggregate
  validation.
- Menambahkan Prometheus Alertmanager API v2 target `alertmanager:9093`.
- Menjalankan static validation, `amtool check-config`, dan
  `promtool check config` menggunakan disposable `--rm` containers.
- Mengaudit container serta dangling-volume state sebelum dan sesudah test.
- Memperbarui source documentation dan Engineering Journal.

Persistent container, named volume, network mutation, port publication,
receiver fixture, live alert delivery, endpoint eksternal, secret creation,
commit, dan push tidak termasuk.

## 📋 Criteria

| Criterion | Expected Result |
| --- | --- |
| Alertmanager source | Route menggunakan lima stable grouping labels dan satu receiver `integration-bridge`. |
| Secret boundary | Receiver menggunakan `url_file`; inline secret dan direct TrueSight transport ditolak. |
| Prometheus delivery | Source menunjuk `alertmanager:9093` menggunakan API v2. |
| Static validation | Shell syntax dan aggregate validators lulus. |
| Semantic validation | `amtool` dan `promtool` menerima configuration yang dipasang read-only. |
| Runtime boundary | Tidak ada persistent Alertmanager, endpoint eksternal, atau volume baru. |

## 🛠️ Execution Record

### 1. Inspect governance, source, and image prerequisites

**Command actually executed.**

```bash
# /home/eddywiyatno/git/tomcat-monitoring
git status --short --branch
sed -n '1,260p' AGENTS.md
sed -n '1,260p' README.md
sed -n '1,240p' config/alertmanager/README.md
sed -n '1,260p' config/prometheus/prometheus.yml
sed -n '1,260p' config/prometheus/README.md
sed -n '1,260p' scripts/validate.sh
sed -n '1,260p' scripts/validate-prometheus.sh
sed -n '1,260p' validation/README.md

# Initial sandboxed checks, followed by approved retry
podman image exists localhost/alertmanager:1.0.0
podman image exists localhost/prometheus:1.0.0
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0
```

**Actual result and evidence.** Source tree was clean. Initial Podman access
failed while setting the sticky bit on `/run/user/1000/libpod`; its negative
results were discarded. The approved retry confirmed both local images were
present and no Alertmanager container existed.

### 2. Implement configuration and validation contracts

**Changes applied.** Alertmanager source now defines `resolve_timeout: 5m`,
route receiver `integration-bridge`, grouping labels `alertname`, `job`,
`instance`, `service`, and `check`, plus `group_wait: 30s`,
`group_interval: 5m`, and `repeat_interval: 4h`. Its webhook uses only the
approved secret-file reference and sends resolved notifications.

Prometheus source now defines one API v2 Alertmanager target at
`alertmanager:9093`. A new Alertmanager validator checks the exact baseline,
receiver cardinality, secret boundary, and absence of direct TrueSight
transport. Aggregate and Prometheus validators plus component documentation
were updated accordingly.

The first combined patch was rejected atomically because the expected context
in `validation/README.md` had changed; no partial edit occurred. The same
approved source changes were then applied as two context-correct patches.

### 3. Run static validation

**Command actually executed.**

```bash
chmod 0755 scripts/validate-alertmanager.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
rg -n '[[:blank:]]+$' README.md config scripts validation
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer_token:|password:|credential-url' README.md config scripts validation
git status --short --branch
git diff --stat
```

**Actual result and evidence.** Shell parsing and every component validator
passed. The sensitive-pattern scan reported only the existing placeholder
`${JMX_EXPORTER_KEYSTORE_PASSWORD}`; it is a variable reference rather than a
stored secret. Whitespace and diff checks passed.

### 4. Run disposable semantic validation and cleanup audit

**Command actually executed.**

```bash
before_volumes="$(podman volume ls --filter dangling=true --format '{{.Name}}' | sort)"
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman ps --all --filter ancestor=localhost/prometheus:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager:/etc/alertmanager:ro --entrypoint /bin/amtool localhost/alertmanager:1.0.0 check-config /etc/alertmanager/alertmanager.yml
podman run --rm --pull=never --volume /home/eddywiyatno/git/tomcat-monitoring/config/prometheus:/etc/prometheus:ro --entrypoint /bin/promtool localhost/prometheus:1.0.0 check config /etc/prometheus/prometheus.yml
podman ps --all --filter ancestor=localhost/alertmanager:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
podman ps --all --filter ancestor=localhost/prometheus:1.0.0 --format 'id={{.ID}} name={{.Names}} status={{.Status}} image={{.Image}}'
after_volumes="$(podman volume ls --filter dangling=true --format '{{.Name}}' | sort)"
test "$before_volumes" = "$after_volumes"
printf 'dangling_volume_state=unchanged\n'
```

**Actual result and evidence.** `amtool` reported `SUCCESS`, one route and one
receiver. `promtool` reported `SUCCESS`, one rule file and three rules. The
pre-existing persistent Prometheus container `5efe0dc00a65` remained up and
unchanged. No Alertmanager container remained and dangling-volume state was
unchanged. No external endpoint was contacted.

## ⚙️ Commands Executed

Commands that changed source or runtime state, together with their verification
commands, are recorded verbatim in the four execution stages above. Final
documentation checks were also run:

```bash
# /home/eddywiyatno/git/devops-handbook
git diff --check
git status --short --branch
rg -n '^## |^### ' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-028-implement-alertmanager-configuration-and-validation-contract.md
rg -n 'TN-028|TN-028-implement-alertmanager' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring
rg -n 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KE[Y]|bearer[_]token=|^[[:space:]]*passwor[d]=|https?://[^[:space:]/]+:[^[:space:]@]+@' docs/projects/tomcat-monitoring
command -v mkdocs
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/alertmanager status --short --branch
```

## 📋 Evidence

| Evidence | Result |
| --- | --- |
| Static validation | Aggregate source validation and shell parsing passed. |
| Alertmanager semantics | `amtool check-config` succeeded with one route and one receiver. |
| Prometheus semantics | `promtool check config` succeeded with one rule file and three rules. |
| Secret boundary | Only a `url_file` path is stored; no URL or credential value was added. |
| Runtime audit | No retained Alertmanager container; existing Prometheus unchanged; dangling volumes unchanged. |

## ⚠️ Exceptions

MkDocs render is not verified because the executable is not installed and no
dependency installation was authorized. Receiver behavior, webhook payload,
firing/resolved delivery, endpoint TLS/authentication, persistence, and restart
behavior were intentionally not tested.

## ❓ Open Questions

| Question | Owner | Closure Criterion | Blocked Work |
| --- | --- | --- | --- |
| What are the Integration Bridge endpoint, authentication, and TLS requirements? | Project owner and Integration Bridge owner | Approved endpoint contract and non-secret runtime reference | Persistent receiver and external delivery |
| Which provider owns secret creation, rotation, and revocation? | Project owner, infrastructure owner, and security owner | Approved secret lifecycle and exact mount contract | Persistent Alertmanager deployment |
| How are webhook fields mapped to TrueSight SNMP Trap or `msend`? | Integration Bridge and TrueSight owners | Accepted field mapping and end-to-end acceptance criteria | External TrueSight verification |

## ✅ Conclusion

TN-028 criteria passed. Alertmanager and Prometheus source contracts are
implemented and semantically valid against the local component images. The
implementation preserves the non-secret boundary and introduces no persistent
Alertmanager runtime, external notification, or new storage state.

## 🧾 Outcome

Repository `tomcat-monitoring` can now statically and semantically validate its
Alertmanager routing source and Prometheus API v2 delivery reference. This is
source-level readiness only; it does not establish operational notification
delivery.

## ⏭️ Next Steps

The smallest separate activity is an isolated disposable receiver test for
firing and resolved webhook behavior. Persistent deployment and external
Integration Bridge validation remain blocked on the open decisions above and
require separate authorization.

## 🔗 Related Documentation

- [TN-027 — Build and Smoke Test Alertmanager Runtime](TN-027-build-and-smoke-test-alertmanager-runtime.md)
- [TN-025 — Define Alertmanager Runtime Ownership and Notification Integration Contract](TN-025-define-alertmanager-runtime-ownership-and-notification-integration-contract.md)
- [Architecture](../../architecture/index.md)
- [Infrastructure](../../infrastructure/index.md)
- [Development](../../development/index.md)

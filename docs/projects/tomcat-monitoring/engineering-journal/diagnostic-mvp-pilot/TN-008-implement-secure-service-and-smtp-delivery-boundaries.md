# TN-008 — Implement Secure Service and SMTP Delivery Boundaries

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-31 |

## 🎯 Objective

Implement and component-test HTTPS webhook/health/metrics interfaces and
bounded SMTP delivery before image work begins.

## 📚 Scope

Exact Nodemailer dependency, delivery migration, HTTPS handler/server, bearer
authentication, 256 KiB request limit, response mapping, SMTP adapter, tests,
validator, README, dan documentation. Image, Mailpit actual, deployment,
monitoring configuration, commit, dan push excluded.

## 🧭 Implementation Plan

```text
HTTPS request -> auth/content/size checks -> durable ingestion -> 202
canonical render -> bounded SMTP adapter -> delivery attempt state
```

## ⚙️ Implementation

<div class="procedure" markdown>
<div class="procedure-step" markdown>

### Pin the SMTP Client

```bash
podman run --rm --name tomcat-diagnostic-tn008-dependency --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm install --save-exact nodemailer@9.0.6 \
  --ignore-scripts --no-audit --no-fund
```

!!! success "Expected Result"

    Exact dependency and lockfile are available without transitive packages.

**Actual Result:** Nodemailer `9.0.6` added with zero transitive dependencies.

</div>
<div class="procedure-step" markdown>

### Implement Request and Delivery Boundaries

Migration `003` adds notification attempts. HTTPS handler implements webhook,
liveness, readiness, metrics, constant-time bearer comparison, JSON media
type, 256 KiB limit, and contract response codes. SMTP adapter disables file
and URL access and applies connection/greeting/socket timeouts.

!!! success "Expected Result"

    Source boundaries exist without secret values or environment endpoints.

**Actual Result:** Source and unit fixtures available; socket verification was
completed in the following component-test step.

</div>
<div class="procedure-step" markdown>

### Run Source Tests

```bash
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn008-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

First validation failed because root lock expectation still listed only Ajv.
The validator was corrected to require exact Ajv and Nodemailer. Re-run passed
25 tests.

!!! success "Expected Result"

    Existing tests and new handler/MIME boundary tests pass.

**Actual Result:** 25 passed, 0 failed. Handler was invoked directly and SMTP
used stream transport; socket-level component verification remains open.

</div>
<div class="procedure-step" markdown>

### Verify Ephemeral HTTPS and SMTP Sockets

Temporary certificate material was created only under the approved directory:

```bash
test ! -e /tmp/tomcat-diagnostic-tn008-component
mkdir /tmp/tomcat-diagnostic-tn008-component
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost \
  -addext subjectAltName=DNS:localhost,IP:127.0.0.1 \
  -keyout /tmp/tomcat-diagnostic-tn008-component/server.key \
  -out /tmp/tomcat-diagnostic-tn008-component/server.crt
podman run --rm --name tomcat-diagnostic-tn008-component --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z \
  -v /tmp/tomcat-diagnostic-tn008-component:/tmp/tn008-tls:ro,Z -w /app \
  -e TN008_TLS_KEY=/tmp/tn008-tls/server.key \
  -e TN008_TLS_CERT=/tmp/tn008-tls/server.crt \
  localhost/nodejs:24.18.0 npm run test:component
```

!!! success "Expected Result"

    Trusted CA succeeds, untrusted CA fails, HTTPS endpoints respond, and the
    fake SMTP listener receives one multipart message.

**Actual Result:** 2 component tests passed. Exact cleanup then ran:

```bash
rm -r /tmp/tomcat-diagnostic-tn008-component
```

Final checks confirmed the directory was absent and no `.key`, `.crt`, or
`.pem` artifact existed in the repository.

</div>
</div>

## 📁 Artifact Manifest

| Path | Responsibility |
| --- | --- |
| `migrations/003-delivery-attempts.sql` | Delivery attempt persistence |
| `src/server/http-service.js` | HTTPS and request boundary |
| `src/adapters/smtp-adapter.js` | Bounded SMTP transport |
| `test/unit/http-service.test.js` | Auth/media/size/health/metrics tests |
| `test/unit/smtp-adapter.test.js` | Multipart message generation |

## 🖥️ Source-Control Handoff

Source-control handoff was authorized after technical closure:

```bash
git add README.md package.json package-lock.json scripts/validate.sh \
  migrations/003-delivery-attempts.sql src/adapters/sqlite-repository.js \
  src/adapters/smtp-adapter.js src/server/http-service.js \
  test/component/secure-service-component.test.js \
  test/unit/http-service.test.js test/unit/smtp-adapter.test.js
git diff --cached --check
git commit -m "feat(diagnostic-service): add secure service delivery boundaries"
```

Actual result: commit `bc4b7ae`; push was not performed in this activity.

## 🧭 Reproduction Guide

```bash
git checkout bc4b7ae
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn008-regression --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Regression expected result is 25 passed. Socket reproduction additionally
requires the temporary-certificate procedure above and must remove the exact
directory afterward.

## ✅ Verification

| Layer | Actual result |
| --- | --- |
| Static validation | Passed |
| Unit/source integration | 25 passed |
| Actual HTTPS socket | Passed: trusted/untrusted CA and endpoints |
| Fake SMTP socket | Passed: multipart message received |
| Cleanup | Passed: exact directory removed; sensitive artifacts 0 |

## 🧾 Outcome

HTTPS and SMTP source boundaries are implemented. Twenty-five regression tests
and two ephemeral socket component tests passed without persistent state or
certificate material in Git.

## ⏭️ Next Steps

Define the application startup/configuration contract, then prepare image build
and disposable component verification after immutable base identity approval.

## 🔗 Related Documentation

- [TN-007](TN-007-implement-worker-canonical-result-and-renderers.md)
- [Webhook Contract](../../diagnostic-mvp/alertmanager-webhook-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)

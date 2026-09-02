# Runtime Configuration and Verification Contract

## 🔍 Overview

Contract ini menetapkan cara integration owner mengonsumsi image Diagnostic
Service tanpa memasukkan configuration, target, certificate, atau secret ke
application image. Contract ini juga menetapkan boundary disposable
multi-component verification sebelum persistent deployment dipertimbangkan.

Image TN-013 menjadi verified current application artifact:

```text
localhost/tomcat-diagnostic-service@sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f
```

Digest tersebut membawa notification lifecycle TN-012 serta SQLite permission
resolution TN-013 dan telah lulus image-static serta disposable runtime
verification. Digest TN-010 tetap menjadi historical baseline. Mutable tag
tidak boleh menjadi runtime identity.

## 📌 Ownership Boundary

| Artifact or lifecycle | Owner |
| --- | --- |
| Application source, schema, migration, image lifecycle, dan component test | `tomcat-diagnostic-service` |
| Non-secret application JSON, target allowlist, routing, mount declarations, disposable orchestration, dan integration assertions | `tomcat-monitoring` |
| TLS private key, bearer token, optional SMTP credential, certificate distribution, dan rotation | Non-Git security/platform storage |
| Reusable Node.js runtime | `nodejs`; consumed only through the immutable base embedded in the application image |
| SQLite schema, migration, transaction, dan application data lifecycle | `tomcat-diagnostic-service` |
| Physical SQLite volume/bind, capacity allocation, backup, dan destructive cleanup | Integration/platform owner |
| Mailpit image build and release | Upstream `axllent/mailpit` |
| Mailpit immutable reference, disposable integration, assertions, dan cleanup | `tomcat-monitoring` |

`tomcat-diagnostic-service` tidak memiliki environment-specific files.
`tomcat-monitoring` hanya menyimpan non-secret configuration dan reference;
secret value serta generated certificate tetap berada di luar Git.

## 📋 Application Configuration

Integration-owned JSON menggunakan schema version `1` dan nilai pilot berikut:

| Field | Accepted pilot value |
| --- | --- |
| `listen.host` | `0.0.0.0` |
| `listen.port` | `8443` |
| `databasePath` | `/var/lib/tomcat-diagnostic/diagnostic.db` |
| `tls.certificateFile` | `/run/tomcat-diagnostic/tls/server.crt` |
| `tls.privateKeyFile` | `/run/tomcat-diagnostic/tls/server.key` |
| `bearerTokenFile` | `/run/tomcat-diagnostic/secrets/bearer-token` |
| `targetAllowlistFile` | `/run/tomcat-diagnostic/config/targets.json` |
| `smtp.host` | `mailpit` for disposable/lab verification |
| `smtp.port` | `1025` |
| `smtp.secure` | `false` only on the isolated internal Mailpit network |
| `smtp.from` | `diagnostic@tomcat-monitoring.invalid` |
| `smtp.to` | `operator@tomcat-monitoring.invalid` |
| `queue.capacity` | `50` |
| `queue.pollIntervalMs` | `250` |
| `timeouts.diagnosticMs` | `60000` |
| `timeouts.smtpMs` | `10000` |
| `timeouts.shutdownMs` | `10000` |
| `requestLimitBytes` | `262144` |

`smtp.usernameFile` dan `smtp.passwordFile` harus absent bersama untuk Mailpit.
Jika external SMTP kemudian diterima, keduanya harus hadir sebagai pair dan
menunjuk mounted secret files. Endpoint, identity, TLS mode, retry policy, dan
credential lifecycle external SMTP memerlukan contract terpisah.

Application JSON tidak boleh memuat token, password, private key, certificate
content, environment credential, atau target yang berasal dari webhook.

Notification retry merupakan fixed pilot policy milik source, bukan
environment configuration: maksimum tiga attempts, backoff 1 dan 5 detik,
maximum age 60 detik, dan existing work queue berkapasitas 50 tanpa queue
kedua. Perubahan nilai memerlukan contract review.

## 💾 Mount and Permission Contract

| Host artifact | Container target | Mount | Host mode |
| --- | --- | --- | ---: |
| `application.json` | `/run/tomcat-diagnostic/application.json` | File, read-only | `0444` |
| `targets.json` | `/run/tomcat-diagnostic/config/targets.json` | File, read-only | `0444` |
| Diagnostic certificate | `/run/tomcat-diagnostic/tls/server.crt` | File, read-only | `0444` |
| Diagnostic private key | `/run/tomcat-diagnostic/tls/server.key` | File, read-only | `0400` |
| Bearer token | `/run/tomcat-diagnostic/secrets/bearer-token` | File, read-only | `0400` |
| Optional SMTP username | `/run/tomcat-diagnostic/secrets/smtp-username` | File, read-only | `0400` |
| Optional SMTP password | `/run/tomcat-diagnostic/secrets/smtp-password` | File, read-only | `0400` |
| SQLite storage directory | `/var/lib/tomcat-diagnostic` | Directory, read-write | `0700` |

Current rootless lab material is owned by the runtime operator UID/GID
`1000:1000`. Parent directories containing private material use `0700`.
Generated SQLite database, WAL, and shared-memory files must remain writable
only by the runtime identity and use `0600` where supported.

The application image runs as symbolic user `node`. Runtime preflight must
prove that this effective user can read every mounted input and create, lock,
checkpoint, and reopen files below `/var/lib/tomcat-diagnostic`. Numeric image
UID must be inspected from the exact digest before orchestration; it must not
be inferred from a mutable base tag. A different host UID/GID requires an
explicit user-namespace and ownership mapping review.

All configuration, certificate, allowlist, and secret mounts are read-only.
Only the SQLite directory is read-write. A whole non-Git parent directory must
not be mounted when the service needs only one bounded child file.

## 🏗️ Disposable Verification Topology

The next runtime activity must use exact TN-scoped resources. Candidate names
are reserved by contract but must still pass collision preflight immediately
before creation:

| Resource | Exact contract |
| --- | --- |
| Network | `tm-tn013-diagnostic` |
| Diagnostic container | `tm-tn013-diagnostic-service` |
| HTTPS client container | `tm-tn013-diagnostic-client` |
| Mailpit container | `tm-tn013-diagnostic-mailpit` |
| Temporary directory | `mktemp -d /tmp/tomcat-diagnostic-tn013.XXXXXX`; resolved path recorded before runtime authorization |
| Diagnostic image | Exact TN-013 verified digest; TN-010 digest is historical baseline only |
| HTTPS client image | `localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d` |
| Mailpit image | `ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24` |
| Diagnostic endpoint | Internal `https://diagnostic-service:8443`; no host publication |
| Mailpit SMTP/API | Internal `mailpit:1025` and `mailpit:8025`; no host publication required |
| SQLite | Temporary bind subdirectory to `/var/lib/tomcat-diagnostic`; no named volume |
| Restart policy | Disabled |

The client validates the Diagnostic Service CA, sends the standard
Alertmanager webhook with bearer authentication, and queries Mailpit through
the same isolated network. It does not replace later verification using the
actual integration-owned Alertmanager route.

Persistent deployment continues to target named volume `diagnostic_data` at
`/var/lib/tomcat-diagnostic`. The disposable bind does not supersede that ADR;
it isolates test evidence and provides an exact removable cleanup target.

## ✅ Verification Contract

Verification layers must remain distinguishable:

| Layer | Mandatory evidence |
| --- | --- |
| Static configuration | JSON schema, exact paths, non-secret scan, image digest, mount modes, and ownership assertions |
| Image static | Exact digest, user, workdir, command, and absence of runtime material in the image |
| Disposable component | TLS trust, live/ready endpoints, metrics, bearer rejection, accepted webhook, queue/worker completion, SQLite state, and SIGTERM exit `0` |
| Notification boundary | SMTP attempt persisted and matching bounded plain-text/HTML message captured by Mailpit |
| Cleanup | Three exact containers, exact network, and resolved temporary directory absent; images retained |
| Persistent integration | Explicitly outside the disposable activity |
| End-to-end monitoring | Requires actual Alertmanager route and remains a later activity |

TN-012 source connects canonical result persistence, renderer, bounded SMTP
retry, attempt persistence, initial firing, one material update, dan resolved
correlation. Source regression and ephemeral SMTP socket tests passed. Current
TN-013 image memuat source tersebut. Disposable verification membuktikan
firing/duplicate/resolved delivery, persisted attempts, Mailpit text/HTML,
SQLite mode `0600`, database reopen, dan graceful shutdown.

Before runtime authorization, the next Technical Note must publish the exact
resolved temporary directory, image identities, container names, network,
ports, bind sources/targets, ownership labels, and cleanup commands. Cleanup
requires separate destructive-action authorization after evidence is recorded.
Image removal is excluded.

## 📌 Status

**Accepted and disposable-runtime verified.** Configuration paths, ownership,
permissions, retry policy, exact image identity, integration interface,
Mailpit capture, temporary SQLite lifecycle, and TN-013 topology are verified.
Persistent deployment, actual Alertmanager route, named-volume durability,
collector integration, dan production secret lifecycle remain unverified.

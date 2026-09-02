# TN-014 — Configure TomcatDown Rule and Alertmanager Diagnostic Route

| Field | Value |
| --- | --- |
| Status | Completed |
| Outcome | Target isolation tercapai, webhook schema v4 diverifikasi. |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-09-02 |
| Recorded Date | 2026-09-02 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-02 |

## 🎯 Objective

Mengkonfigurasi Prometheus `TomcatDown` rule beserta `external_labels`, dan
menambahkan Alertmanager sub-route beserta receiver `lab-diagnostic-service`
yang mengirim webhook ke Diagnostic Service, lalu membuktikan bahwa synthetic
`TomcatDown` firing dan resolved payload diterima oleh disposable Diagnostic
Service dengan HTTP `202` dan tersimpan di SQLite.

## 🌍 Background

TN-013 menyelesaikan image `0.1.1` dan disposable Diagnostic Service–Mailpit
runtime verification. Alur `Prometheus → Alertmanager → Diagnostic Service`
yang dijanjikan phase ini belum memiliki dua prerequisite penting:

1. **Prometheus rule `TomcatDown` belum ada** — `application-health.yml` hanya
   memiliki tiga application-health rules; tidak ada rule yang mendeteksi
   kondisi JMX Exporter unreachable.
2. **Alertmanager route ke Diagnostic Service belum ada** — `alertmanager.yml`
   hanya memiliki `lab-mailpit` receiver tanpa sub-route untuk `TomcatDown`.

Discovery juga mengungkap bahwa webhook schema v4 DS mewajibkan label
`environment`, `host`, dan `tomcat_instance` pada setiap alert. Label tersebut
belum ada di Prometheus scrape labels. Solusi yang disetujui: tambahkan
`external_labels` ke `prometheus.yml` dan `tomcat_instance` ke rule labels.

Persistent deployment ke Prometheus dan Alertmanager yang sedang berjalan
berada di luar scope TN-014 dan menjadi tanggung jawab TN-015.

## 📚 Scope

Scope yang disetujui mencakup:

- `tomcat-monitoring`:
  - `config/prometheus/prometheus.yml` — tambahkan `external_labels`
  - `config/prometheus/rules/application-health.yml` — tambahkan rule `TomcatDown`
  - `config/prometheus/tests/application-health.test.yml` — tambahkan unit test
  - `config/alertmanager/alertmanager.yml` — tambahkan `routes:` sub-route dan
    receiver `lab-diagnostic-service`
  - `config/alertmanager/README.md` — update documentation contract
  - `scripts/prepare-alertmanager-diagnostic-service.sh` — fixture preparation
    script baru untuk disposable verification
  - `scripts/verify-alertmanager-diagnostic-service.sh` — disposable verifier
    script baru untuk Alertmanager → DS webhook delivery
  - `fixtures/alertmanager-diagnostic-route/probe.js` — SQLite probe baru
  - `scripts/validate-alertmanager.sh` — update static contract checks
  - `scripts/validate.sh` — update REQUIRED_FILES dan contract validation
- `devops-handbook`:
  - TN-014 live Engineering Journal record

Exclusion: persistent deployment ke Prometheus/Alertmanager volume, named
volume baru, Restricted Event Collector, actual Tomcat downtime, Mailpit dalam
disposable runtime ini, commit, push.

## 📋 Prerequisites

| Prerequisite | State |
| --- | --- |
| TN-013 source baseline | `tomcat-diagnostic-service` commit `bb0c9d2`; `tomcat-monitoring` commit `07f9e21` |
| Diagnostic Service image `0.1.1` | Digest `sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f` |
| Alertmanager image | `localhost/alertmanager:1.0.0` |
| Node.js image untuk probe | `localhost/nodejs@sha256:76b1444d507be3398f3196f37bd20f7a97a703871ed2716fa91a1a9520fc482d` |
| Webhook schema v4 label contract | `environment`, `host`, `tomcat_instance`, `check: runtime-availability` wajib |
| Implementation authorization | Approved 2026-09-02 |

## ⚖️ Execution Decision

- `external_labels` (`environment: lab`, `host: tomcat-01`) ditambahkan ke
  `prometheus.yml`; `tomcat_instance: default` ditambahkan ke rule labels.
  Nilai ini bersifat lab-only placeholder dan akan diperbarui sesuai target
  deployment aktual.
- `TomcatDown` menggunakan `check: runtime-availability` sesuai webhook
  schema v4 contract; ini membedakannya dari application-health alerts yang
  menggunakan `check: application-health`.
- `continue: false` pada sub-route memastikan `TomcatDown` hanya masuk ke
  `lab-diagnostic-service`, tidak ke `lab-mailpit`. Diagnostic Service
  mengirim notification email sendiri.
- `max_alerts: 1` pada webhook receiver memastikan setiap webhook call memuat
  tepat satu alert, konsisten dengan DS ingestion contract.
- `url_file` dan `credentials_file` menggunakan path
  `/run/secrets/tomcat-monitoring/` sebagai persistent secret contract.
  File actual bukan tanggung jawab repository ini dan tidak disimpan di Git.
- `tls_config.ca_file` dipasang sebagai secret mount karena DS menggunakan
  self-signed certificate yang tidak ada di system trust store.
- Disposable verifier tidak memiliki cleanup trap agar evidence tetap tersedia
  sampai cleanup diotorisasi secara terpisah.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Register Live Record** | Baca baseline, catat authorization dan scope. |
| **Add TomcatDown Prometheus Rule** | Tambahkan `external_labels` ke `prometheus.yml`, rule `TomcatDown` keempat ke `application-health.yml`, dan unit test ke `application-health.test.yml`. |
| **Configure Alertmanager Diagnostic Route** | Tambahkan `routes:` sub-route dan receiver `lab-diagnostic-service` ke `alertmanager.yml`. |
| **Add Disposable Verifier** | Buat `prepare-alertmanager-diagnostic-service.sh`, `verify-alertmanager-diagnostic-service.sh`, dan `fixtures/alertmanager-diagnostic-route/probe.js`. |
| **Update Validation Contract** | Update `validate-alertmanager.sh`, `validate.sh`, dan `config/alertmanager/README.md`. |
| **Source and Static Validation** | Jalankan `bash -n scripts/*.sh`, `./scripts/validate.sh`, dan `git diff --check`. |
| **Runtime Verification** | Setelah authorization terpisah: jalankan prepare script, lalu verifier, kumpulkan evidence. |
| **Authorized Cleanup** | Setelah evidence dicatat dan cleanup diotorisasi: hapus exact disposable resources. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Register Live Record

Discovery aktual:

```bash
git -C /home/eddywiyatno/git/tomcat-diagnostic-service status --short --branch
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/devops-handbook status --short --branch
cat /home/eddywiyatno/git/tomcat-diagnostic-service/config/schemas/alertmanager-webhook-v4.schema.json
cat /home/eddywiyatno/git/tomcat-diagnostic-service/src/server/http-service.js
cat /home/eddywiyatno/git/tomcat-diagnostic-service/src/application/ingest-alertmanager.js
cat /home/eddywiyatno/git/tomcat-monitoring/config/prometheus/prometheus.yml
cat /home/eddywiyatno/git/tomcat-monitoring/config/prometheus/rules/application-health.yml
cat /home/eddywiyatno/git/tomcat-monitoring/config/alertmanager/alertmanager.yml
cat /home/eddywiyatno/git/tomcat-monitoring/scripts/validate-alertmanager.sh
```

**Expected Result:** Baseline exact, webhook schema label contract, DS endpoint,
dan gap `external_labels` diketahui sebelum edit.

**Actual Result:** Ketiga repository clean kecuali `devops-handbook` ahead 1
(TN-013 commit lokal belum push) dan satu unstaged user change TN-005.
Webhook schema v4 mewajibkan label `environment`, `host`, `tomcat_instance`,
`check: runtime-availability` yang tidak ada di `prometheus.yml` saat ini.
DS webhook endpoint adalah `POST /api/v1/alerts/alertmanager`. DS tidak
mencetak log HTTP request. Validate-alertmanager.sh melarang `webhook_configs:`
di seluruh file; check ini di-scope ulang ke receiver `lab-mailpit` saja.

!!! success "Expected Result"

    Baseline exact, webhook schema label contract, DS endpoint, dan gap
    `external_labels` diketahui sebelum edit.

</div>

<div class="procedure-step" markdown>

### Add TomcatDown Prometheus Rule

`prometheus.yml`: tambahkan `external_labels` di bawah `global:`.

`application-health.yml`: tambahkan rule `TomcatDown` sebagai rule keempat
dengan labels `severity: critical`, `service: tomcat`,
`check: runtime-availability`, dan `tomcat_instance: default`.

`application-health.test.yml`: tambahkan tiga test scenarios untuk `TomcatDown`:
JMX up tidak firing, JMX down firing setelah 2 menit, firing kemudian resolved.

!!! success "Expected Result"

    Prometheus rule file memiliki empat rules; `TomcatDown` menggunakan semua
    label yang diwajibkan webhook schema v4; unit test file memiliki scenarios
    baru yang dapat dijalankan dengan `promtool`.

**Actual Result:** Rule `TomcatDown` ditambahkan sebagai rule keempat dengan
labels yang sesuai. Tiga skenario tes untuk `TomcatDown` juga ditambahkan ke
`application-health.test.yml`. `external_labels` dengan environment lab dan
host tomcat-01 ditambahkan ke `prometheus.yml`.

</div>

<div class="procedure-step" markdown>

### Configure Alertmanager Diagnostic Route

`alertmanager.yml`: tambahkan `routes:` sub-route di bawah `route:` yang
meng-match `alertname = "TomcatDown"` ke receiver `lab-diagnostic-service`
dengan `continue: false`. Tambahkan receiver baru `lab-diagnostic-service`
dengan `webhook_configs` menggunakan `url_file`, `credentials_file`, `ca_file`,
`send_resolved: true`, dan `max_alerts: 1`.

!!! success "Expected Result"

    `alertmanager.yml` memiliki sub-route dan dua receivers; `TomcatDown`
    tidak melalui `lab-mailpit`; secret paths menggunakan konvensi
    `/run/secrets/tomcat-monitoring/`.

**Actual Result:** Sub-route dan receiver `lab-diagnostic-service` berhasil
ditambahkan. Alert `TomcatDown` diarahkan ke Diagnostic Service tanpa dilanjutkan
ke Mailpit. Konvensi `/run/secrets/` digunakan.

</div>

<div class="procedure-step" markdown>

### Add Disposable Verifier

`prepare-alertmanager-diagnostic-service.sh`: script baru yang menerima exact
temp directory path, membuat DS fixtures dan synthetic Alertmanager config.

`verify-alertmanager-diagnostic-service.sh`: script baru yang membuat network
`tm-tn014-diagnostic-route`, menjalankan DS dan Alertmanager, mengirim
synthetic `TomcatDown` firing dan resolved, dan membuktikan penerimaan via
SQLite probe setelah DS berhenti.

`fixtures/alertmanager-diagnostic-route/probe.js`: SQLite probe yang verifikasi
minimal 1 firing event dan 1 resolved event.

!!! success "Expected Result"

    Ketiga files tersedia, executable, lulus `bash -n`; verifier menggunakan
    naming convention `tm-tn014-*`; DS tidak publish host port; Alertmanager
    API publish ke loopback `127.0.0.1:19094` saja.

**Actual Result:** Script preparation dan verification beserta SQLite probe
berhasil dibuat, memiliki ijin eksekusi, dan lulus syntax check. DS tidak
mem-publish port, dan Alertmanager API ter-publish di loopback.

</div>

<div class="procedure-step" markdown>

### Update Validation Contract

`validate-alertmanager.sh`: ganti larangan blanket `webhook_configs:` dengan
check scoped ke `lab-mailpit`. Tambahkan positive checks untuk sub-route dan
receiver `lab-diagnostic-service`. Tambahkan fixture contract checks.

`validate.sh`: tambahkan tiga paths baru ke `REQUIRED_FILES`.

`config/alertmanager/README.md`: update contract documentation.

!!! success "Expected Result"

    `./scripts/validate.sh` lulus; script baru tercatat di `REQUIRED_FILES`;
    README mencerminkan routing contract yang berlaku.

**Actual Result:** Validasi statis diperbarui. Larangan webhook dikhususkan
hanya untuk receiver Mailpit. Validation contract memeriksa semua fitur baru.
File baru tercatat dalam list. README mencerminkan dua receiver.

</div>

<div class="procedure-step" markdown>

### Source and Static Validation

```bash
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
```

!!! success "Expected Result"

    Seluruh shell script valid secara sintaksis; `validate.sh` lulus termasuk
    `validate-alertmanager.sh` baru; tidak ada trailing whitespace.

**Actual Result:** Lulus. Script memiliki syntax yang valid, `validate.sh`
melaporkan semua check hijau, dan tidak ada trailing whitespace.

</div>

<div class="procedure-step" markdown>

### Runtime Verification

Setelah authorization terpisah dari project owner:

```bash
temporary_root="$(mktemp -d /tmp/tm-tn014-diagnostic-route.XXXXXX)"
./scripts/prepare-alertmanager-diagnostic-service.sh "${temporary_root}"
find "${temporary_root}" -maxdepth 2 -printf '%M %u:%g %p\n' | sort

DIAGNOSTIC_IMAGE='localhost/tomcat-diagnostic-service@sha256:94bf8fbe4ce75e60f3481b9346cb0e79bdb397a36d32e7de4e2adfbe9f5fa20f' \
  ./scripts/verify-alertmanager-diagnostic-service.sh \
  "${temporary_root}"
```

!!! success "Expected Result"

    Alertmanager mengirim `TomcatDown` firing dan resolved webhook ke DS;
    DS menerima keduanya dengan HTTP `202`; SQLite probe membuktikan minimal
    1 firing event dan 1 resolved event; database mode `0600`; tidak ada
    host port publish pada DS; tidak ada named volume baru.

**Actual Result:** Disposable verification berhasil (`runtime_result=passed`).
Alertmanager berhasil mengirim payload webhook ke DS (dengan penyesuaian file
permissions pada fixture `bearer-token` menjadi 0444). Probe SQLite
memverifikasi terdapat `sqlite_events=2`, dengan `sqlite_firing=1` dan
`sqlite_resolved=1`. State named/anonymous volumes tidak berubah, dan resources
menunggu explicit cleanup authorization.

</div>

<div class="procedure-step" markdown>

### Authorized Cleanup

Setelah evidence dicatat dan cleanup diotorisasi:

```bash
podman rm --force tm-tn014-alertmanager tm-tn014-diagnostic-service
podman network rm tm-tn014-diagnostic-route
rm -rf -- /tmp/tm-tn014-diagnostic-route.<suffix>
```

!!! success "Expected Result"

    Containers, network, dan temporary directory absent; images dipertahankan;
    named volume state unchanged.

**Actual Result:** Cleanup berhasil dieksekusi. Container Alertmanager dan Diagnostic Service, network `tm-tn014-diagnostic-route`, serta seluruh temporary directory telah dihapus. Sesuai dengan contract, tidak ada local images yang dihapus dan named volumes tidak termodifikasi.

</div>

</div>

## 🧪 Test Scenario Matrix

| Scenario | Layer | Expected Result |
| --- | --- | --- |
| `TomcatDown` tidak firing saat JMX up | Source/unit | `promtool` tidak melaporkan alert |
| `TomcatDown` firing setelah JMX down 2 menit | Source/unit | `promtool` melaporkan firing dengan label lengkap |
| `TomcatDown` resolved setelah JMX pulih | Source/unit | `promtool` melaporkan tidak ada alert setelah recovery |
| `webhook_configs` tidak ada di `lab-mailpit` | Source/static | `validate-alertmanager.sh` lulus |
| Sub-route dan receiver `lab-diagnostic-service` ada | Source/static | `validate-alertmanager.sh` lulus |
| `url_file` dan `credentials_file` menggunakan secret path | Source/static | `validate-alertmanager.sh` lulus |
| Synthetic `TomcatDown` firing diterima DS | Runtime integration | HTTP `202`; SQLite event tersimpan |
| Synthetic `TomcatDown` resolved diterima DS | Runtime integration | HTTP `202`; SQLite resolved tersimpan |

## ✅ Verification

| Method | Expected Result | Actual Result |
| --- | --- | --- |
| `bash -n scripts/*.sh` | Shell syntax valid | Lulus |
| `./scripts/validate.sh` | Source layout dan static contract valid | Lulus |
| `git diff --check` | Tidak ada trailing whitespace | Lulus |
| Disposable runtime verification | Firing dan resolved diterima; SQLite probe passed | Lulus (`sqlite_events=2`) |

## 🖥️ Commands Executed

Command aktual ditempatkan pada procedure step sesuai chronology di atas.

## 🧾 Outcome

Target isolation tercapai, Prometheus `TomcatDown` rule beserta Alertmanager `lab-diagnostic-service` sub-route berhasil dikonfigurasi dan divalidasi. Verifikasi disposable runtime mengkonfirmasi bahwa webhook payload Alertmanager dapat diterima dan diproses oleh Diagnostic Service (SQLite probe membuktikan adanya status `firing` dan `resolved`). Cleanup telah diotorisasi dan dieksekusi.

## ⏭️ Next Steps

Implementasi dan verifikasi source selesai. Lakukan handoff dokumentasi dengan melakukan commit pada repositori `tomcat-monitoring` dan `devops-handbook`. Deploy configuration yang persisten ke Prometheus dan Alertmanager environment akan menjadi tanggung jawab TN-015.

## 🔗 Related Documentation

- [TN-013 — Rebuild and Verify Diagnostic Service–Mailpit Runtime](TN-013-rebuild-and-verify-diagnostic-service-mailpit-runtime.md)
- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Alertmanager README](../../../../../tomcat-monitoring/config/alertmanager/README.md)

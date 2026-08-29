# TN-008 — Verify Telegraf Health Check with Edkas-pc1 Alias

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Menyelesaikan component verification Telegraf dengan mengakses endpoint metrics
melalui alias network `edkas-pc1`.

## 🌍 Background

TN-004 belum dapat menutup component verification karena client pada network
test tidak berhasil mengakses endpoint metrics menggunakan alias yang diminta.
TN-007 kemudian menghasilkan image lokal Telegraf yang telah lulus smoke test.
TN-008 mengulangi pengujian dengan topology sementara yang lebih jelas dan
mencatat kondisi sehat, body mismatch, status mismatch, serta cleanup.

## 📚 Scope

Aktivitas mencakup image lokal `localhost/telegraf:1.0.0`, network dan HTTP
fixture sementara, alias `edkas-pc1`, pengujian tiga response, serta cleanup
seluruh resource bernama `tn008-*`. Persistent runtime, host port, named volume,
Prometheus, Tomcat production, TLS, alerting, deployment, dan publication tidak
termasuk.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Runtime artifact | Menggunakan `localhost/telegraf:1.0.0` dari TN-007. |
| Metrics access | Client sementara mengambil `http://edkas-pc1:9273/metrics` pada network test. |
| Healthy condition | Fixture `200` dan body `UP` menghasilkan metric health. |
| Body mismatch | Fixture `200` dengan body `DOWN` menunjukkan kegagalan check. |
| Status mismatch | Fixture `404` menunjukkan kegagalan check. |
| Cleanup | Container, network, dan temporary directory test dihapus. |

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Review Test Readiness** | Memastikan resource `tn008-*` tidak ada dan image lokal tersedia. |
| **Create the Isolated Network and Healthy Fixture** | Membuat network serta endpoint sementara dengan HTTP `200` dan body `UP`. |
| **Start Telegraf with the Required Alias** | Menjalankan Telegraf menggunakan alias metrics `edkas-pc1`. |
| **Retrieve Healthy Metrics through the Alias** | Mengambil metrics dari client sementara dan memeriksa kondisi sehat. |
| **Verify the Body Mismatch** | Mengubah body menjadi `DOWN` dan memeriksa hasil Telegraf. |
| **Verify the Status Mismatch** | Menghapus endpoint untuk menghasilkan HTTP `404`. |
| **Remove Every Temporary Resource** | Menghapus container, network, dan directory sementara lalu mengaudit cleanup. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Review Test Readiness

**Purpose.** Memastikan tidak ada resource `tn008-*` yang tertinggal dan image lokal hasil TN-007 tersedia sebelum test dimulai.

**Command actually executed.**

```bash
podman ps --all --filter name=tn008- --format '{{.Names}} {{.Status}}'
podman network ls --format '{{.Name}}' | rg '^tn008-telegraf-verify$' || true
podman image inspect localhost/telegraf:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'
```

!!! success "Expected Result"

    Tidak ada container atau network test yang sudah ada; image Telegraf lokal
    tersedia.

**Actual Result:** tidak ada resource `tn008-*` sebelum pengujian dan image
Telegraf tersedia.

**Evidence:** dua query resource tidak menghasilkan output; image inspection
mencatat ID `4f8c425e8fd8...`, user `telegraf`, dan entrypoint yang benar.

</div>

<div class="procedure-step" markdown>

### Create the Isolated Network and Healthy Fixture

**Purpose.** Menyediakan endpoint non-production `200` dengan body `UP` yang hanya dapat diakses dari network test.

**Command actually executed.**

```bash
test ! -e /tmp/tn008-telegraf-verify && install -d -m 0700 /tmp/tn008-telegraf-verify/www && printf '%s\n' '{"status":"UP"}' > /tmp/tn008-telegraf-verify/www/health
podman network create tn008-telegraf-verify
podman run --detach --rm --name tn008-health-fixture --network tn008-telegraf-verify --network-alias tomcat-health-fixture --volume /tmp/tn008-telegraf-verify/www:/www:ro,Z docker.io/library/busybox:1.38.0 httpd -f -p 8080 -h /www
```

!!! success "Expected Result"

    Network test dan fixture HTTP sementara dibuat tanpa host port, named
    volume, credential, atau target production.

**Actual Result:** network dan fixture sehat berhasil dibuat.

**Evidence:** container fixture dimulai dengan ID `5091ed936db2...` pada
network `tn008-telegraf-verify`.

</div>

<div class="procedure-step" markdown>

### Start Telegraf with the Required Alias

**Purpose.** Menjalankan image lokal TN-007 dengan configuration project dan alias yang diminta untuk endpoint metrics.

**Command actually executed.**

```bash
podman run --detach --rm --name tn008-telegraf --network tn008-telegraf-verify --network-alias edkas-pc1 --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z localhost/telegraf:1.0.0 --config /etc/telegraf/telegraf.conf
podman logs tn008-telegraf
```

!!! success "Expected Result"

    Telegraf memuat `http_response` dan `prometheus_client`, kemudian listen
    secara internal pada `:9273/metrics`.

**Actual Result:** Telegraf berhasil berjalan dengan alias `edkas-pc1` tanpa
host port.

**Evidence:** log mencatat input, output, dan listener `:9273/metrics`; container
ID `86bd8efe3068...` tersedia selama test.

</div>

<div class="procedure-step" markdown>

### Retrieve Healthy Metrics through the Alias

**Purpose.** Membuktikan client sementara dapat menjangkau listener Telegraf melalui `edkas-pc1`, sekaligus memeriksa hasil kondisi sehat.

**Command actually executed.**

```bash
sleep 32
podman run --rm --network tn008-telegraf-verify docker.io/library/busybox:1.38.0 wget -qO- http://edkas-pc1:9273/metrics | rg '^http_response_'
podman logs tn008-telegraf
podman run --rm --network tn008-telegraf-verify docker.io/library/busybox:1.38.0 wget -qO- http://edkas-pc1:9273/metrics
```

!!! success "Expected Result"

    Setelah satu interval `30s`, client mengakses metrics melalui alias dan
    health response terlihat sebagai sukses.

**Actual Result:** filter pertama tidak menghasilkan baris dan tidak dianggap
sukses. Pengambilan payload penuh melalui alias berhasil.

**Evidence:** payload memuat:

```text
http_response_response_status_code_match{...,result="success",...,status_code="200"} 1
http_response_response_string_match{...,result="success",...,status_code="200"} 1
http_response_result_code{...,result="success",...,status_code="200"} 0
```

Alias `edkas-pc1` karenanya terbukti dapat di-resolve dan diakses oleh client pada network test. Filter awal yang kosong dicatat sebagai diagnostic command yang tidak memberikan evidence, lalu dikoreksi dengan payload penuh.

</div>

<div class="procedure-step" markdown>

### Verify the Body Mismatch

**Purpose.** Membuktikan body yang tidak sesuai contract direkam sebagai kegagalan health check.

**Command actually executed.**

```bash
printf '%s\n' '{"status":"DOWN"}' > /tmp/tn008-telegraf-verify/www/health
podman run --rm --network tn008-telegraf-verify --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z --entrypoint /usr/bin/telegraf localhost/telegraf:1.0.0 --test --config /etc/telegraf/telegraf.conf
```

!!! success "Expected Result"

    HTTP `200` dengan body `DOWN` memberikan status body mismatch.

**Actual Result:** Telegraf menandai response sebagai body mismatch.

**Evidence:** metric memuat `result=response_string_mismatch`,
`status_code=200`, `response_string_match=0i`, dan `result_code=1i`.

</div>

<div class="procedure-step" markdown>

### Verify the Status Mismatch

**Purpose.** Membuktikan status selain `200` direkam sebagai kegagalan health check.

**Command actually executed.**

```bash
rm /tmp/tn008-telegraf-verify/www/health
podman run --rm --network tn008-telegraf-verify --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z --entrypoint /usr/bin/telegraf localhost/telegraf:1.0.0 --test --config /etc/telegraf/telegraf.conf
```

!!! success "Expected Result"

    Endpoint fixture yang tidak ada memberikan status mismatch.

**Actual Result:** Telegraf menandai response HTTP `404` sebagai status mismatch.

**Evidence:** metric memuat `result=response_status_code_mismatch`,
`status_code=404`, `response_status_code_match=0i`, dan `result_code=6i`.

</div>

<div class="procedure-step" markdown>

### Remove Every Temporary Resource

**Purpose.** Mengakhiri test tanpa menyisakan container, network, atau fixture file pada host.

**Command actually executed.**

```bash
podman rm --force tn008-telegraf tn008-health-fixture
podman network rm tn008-telegraf-verify
rm -rf /tmp/tn008-telegraf-verify
podman ps --all --filter name=tn008- --format '{{.Names}} {{.Status}}'
podman network ls --format '{{.Name}}' | rg '^tn008-telegraf-verify$' || true
test ! -e /tmp/tn008-telegraf-verify
```

!!! success "Expected Result"

    Kedua container, network, dan temporary directory hilang.

**Actual Result:** kedua container, network, dan temporary directory berhasil
dihapus. Fixture membutuhkan SIGKILL setelah tidak berhenti melalui SIGTERM
dalam 10 detik.

**Evidence:** tiga pemeriksaan akhir tidak menghasilkan output dan `test`
berhasil.

</div>

</div>

## ✅ Verification Result

Semua criteria TN-008 terpenuhi. Dengan image lokal `localhost/telegraf:1.0.0`, client sementara berhasil mengambil endpoint metrics melalui alias `edkas-pc1`. Contract `200` + `UP` menghasilkan sukses, body `DOWN` menghasilkan `response_string_mismatch`, dan endpoint `404` menghasilkan `response_status_code_mismatch`.

Hasil ini menyelesaikan blocker network-client yang dicatat pada [TN-004](TN-004-verify-telegraf-health-check-component.md). Status `Blocked` pada TN-004 tetap merupakan catatan historis aktivitas tersebut; resolution dicatat secara append-oriented pada TN-008 ini, bukan dengan mengubah evidence masa lalu.

## 🧾 Outcome

TN-008 menutup blocker TN-004. Alias `edkas-pc1` dapat diakses oleh client pada
network test; kondisi `200` + `UP`, body `DOWN`, dan status `404` menghasilkan
metric yang sesuai. Seluruh resource sementara telah dibersihkan.

Hasil ini terbatas pada component verification. Prometheus scrape, target
Tomcat nyata, persistent deployment, dan external monitoring belum dibuktikan.

## ⚠️ Scope Boundary

Verifikasi ini membuktikan component Telegraf dan configuration health-check pada network test sementara saja. Ia tidak membuktikan scrape Prometheus, runtime Tomcat nyata, TLS, alerting, deployment, registry publication, atau commit. Tidak ada persistent container, host port, named volume, secret, atau production target yang dibuat.

## 🧾 Documentation Integrity Check

**Purpose.** Memastikan catatan hasil TN-008 dan index fase tidak memiliki error whitespace Git.

**Command actually executed.**

```bash
git -C /home/eddywiyatno/git/devops-handbook diff --check -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment
```

**Expected result.** Tidak ada output dan exit code `0`.

**Actual result and evidence.** Passed tanpa output dengan exit code `0`.

## 🔄 Source-Control Handoff

Hasil rangkaian implementasi dan verification Telegraf disimpan terpisah sesuai
repository ownership:

| Repository | Commit | Scope |
| --- | --- | --- |
| `telegraf` | `cae6aab` | Generic Telegraf runtime dan lifecycle scripts. |
| `tomcat-monitoring` | `ce605b8` | Health-check configuration, validator, dan integration baseline. |
| `devops-handbook` | `3aadf6f` | Engineering Journal dan current-state documentation. |

## ⏭️ Next Steps

Tidak ada tindak lanjut wajib untuk menutup component verification Telegraf. Integrasi Prometheus, target Tomcat nyata, dan deployment harus dibuka sebagai Technical Note baru dengan topology, resource, rollback, dan authorization terpisah.

## 🔗 Related Documentation

- [TN-004 — Verify Telegraf Health Check Component](TN-004-verify-telegraf-health-check-component.md)
- [TN-007 — Build and Smoke Test Telegraf Runtime](TN-007-build-and-smoke-test-telegraf-runtime.md)

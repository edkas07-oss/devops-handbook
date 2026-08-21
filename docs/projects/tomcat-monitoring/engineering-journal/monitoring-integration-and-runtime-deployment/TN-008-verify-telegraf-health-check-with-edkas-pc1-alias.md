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

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Runtime artifact | Menggunakan `localhost/telegraf:1.0.0` dari TN-007. |
| Metrics access | Client sementara mengambil `http://edkas-pc1:9273/metrics` pada network test. |
| Healthy condition | Fixture `200` dan body `UP` menghasilkan metric health. |
| Body mismatch | Fixture `200` dengan body `DOWN` menunjukkan kegagalan check. |
| Status mismatch | Fixture `404` menunjukkan kegagalan check. |
| Cleanup | Container, network, dan temporary directory test dihapus. |

## ⚙️ Execution Plan

1. Buat network dan fixture response sehat.
2. Jalankan Telegraf image lokal dengan network alias `edkas-pc1`.
3. Ambil metrics melalui alias tersebut dari client sementara.
4. Ubah fixture menjadi body `DOWN`, lalu jalankan Telegraf `--test`.
5. Hapus fixture `/health` untuk menghasilkan `404`, lalu ulangi `--test`.
6. Bersihkan seluruh resource test dan catat hasil aktual.

## ⚙️ Execution Record

### 0. Pre-execution resource and artifact check

**Purpose.** Memastikan tidak ada resource `tn008-*` yang tertinggal dan image lokal hasil TN-007 tersedia sebelum test dimulai.

**Command actually executed.**

```bash
podman ps --all --filter name=tn008- --format '{{.Names}} {{.Status}}'
podman network ls --format '{{.Name}}' | rg '^tn008-telegraf-verify$' || true
podman image inspect localhost/telegraf:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'
```

**Expected result.** Tidak ada container atau network test yang sudah ada; image Telegraf lokal tersedia.

**Actual result and evidence.** Dua pemeriksaan resource tidak menghasilkan baris output. Image tersedia dengan ID `4f8c425e8fd8fd412b25ba0aa8489c3e668e75560f48fd114d09cb9cf9d67cae`, user `telegraf`, dan entrypoint `/usr/local/bin/telegraf-entrypoint`.

### 1. Create isolated network and healthy HTTP fixture

**Purpose.** Menyediakan endpoint non-production `200` dengan body `UP` yang hanya dapat diakses dari network test.

**Command actually executed.**

```bash
test ! -e /tmp/tn008-telegraf-verify && install -d -m 0700 /tmp/tn008-telegraf-verify/www && printf '%s\n' '{"status":"UP"}' > /tmp/tn008-telegraf-verify/www/health
podman network create tn008-telegraf-verify
podman run --detach --rm --name tn008-health-fixture --network tn008-telegraf-verify --network-alias tomcat-health-fixture --volume /tmp/tn008-telegraf-verify/www:/www:ro,Z docker.io/library/busybox:1.38.0 httpd -f -p 8080 -h /www
```

**Expected result.** Network test dan fixture HTTP sementara dibuat tanpa host port, named volume, credential, atau target production.

**Actual result and evidence.** Network `tn008-telegraf-verify` dibuat dan container fixture dimulai dengan ID `5091ed936db2ee6599492e1a2c71e00fcad3d6891bbda2b1bc6a6d66bf57a300`.

### 2. Start Telegraf with alias `edkas-pc1`

**Purpose.** Menjalankan image lokal TN-007 dengan configuration project dan alias yang diminta untuk endpoint metrics.

**Command actually executed.**

```bash
podman run --detach --rm --name tn008-telegraf --network tn008-telegraf-verify --network-alias edkas-pc1 --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z localhost/telegraf:1.0.0 --config /etc/telegraf/telegraf.conf
podman logs tn008-telegraf
```

**Expected result.** Telegraf memuat `http_response` dan `prometheus_client`, kemudian listen secara internal pada `:9273/metrics`.

**Actual result and evidence.** Container dimulai dengan ID `86bd8efe306841a41f30dbe7fc263df5f94aa80af2c9743bb9590713e9b88eeb`. Log menyatakan `Loaded inputs: http_response`, `Loaded outputs: prometheus_client`, dan `Listening on http://[::]:9273/metrics`. Tidak ada port host yang dipublikasikan.

### 3. Retrieve healthy metrics through the alias

**Purpose.** Membuktikan client sementara dapat menjangkau listener Telegraf melalui `edkas-pc1`, sekaligus memeriksa hasil kondisi sehat.

**Command actually executed.**

```bash
sleep 32
podman run --rm --network tn008-telegraf-verify docker.io/library/busybox:1.38.0 wget -qO- http://edkas-pc1:9273/metrics | rg '^http_response_'
podman logs tn008-telegraf
podman run --rm --network tn008-telegraf-verify docker.io/library/busybox:1.38.0 wget -qO- http://edkas-pc1:9273/metrics
```

**Expected result.** Setelah satu interval `30s`, client mengakses metrics melalui alias dan health response terlihat sebagai sukses.

**Actual result and evidence.** Pengambilan pertama dengan filter tidak menghasilkan baris, sehingga tidak diperlakukan sebagai sukses. Diagnostic payload penuh melalui alias berhasil diambil dan memuat:

```text
http_response_response_status_code_match{...,result="success",...,status_code="200"} 1
http_response_response_string_match{...,result="success",...,status_code="200"} 1
http_response_result_code{...,result="success",...,status_code="200"} 0
```

Alias `edkas-pc1` karenanya terbukti dapat di-resolve dan diakses oleh client pada network test. Filter awal yang kosong dicatat sebagai diagnostic command yang tidak memberikan evidence, lalu dikoreksi dengan payload penuh.

### 4. Verify body mismatch (`DOWN`)

**Purpose.** Membuktikan body yang tidak sesuai contract direkam sebagai kegagalan health check.

**Command actually executed.**

```bash
printf '%s\n' '{"status":"DOWN"}' > /tmp/tn008-telegraf-verify/www/health
podman run --rm --network tn008-telegraf-verify --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z --entrypoint /usr/bin/telegraf localhost/telegraf:1.0.0 --test --config /etc/telegraf/telegraf.conf
```

**Expected result.** HTTP `200` dengan body `DOWN` memberikan status body mismatch.

**Actual result and evidence.** Telegraf `--test` mengeluarkan metric dengan `result=response_string_mismatch`, `status_code=200`, `response_status_code_match=1i`, `response_string_match=0i`, dan `result_code=1i`.

### 5. Verify status mismatch (`404`)

**Purpose.** Membuktikan status selain `200` direkam sebagai kegagalan health check.

**Command actually executed.**

```bash
rm /tmp/tn008-telegraf-verify/www/health
podman run --rm --network tn008-telegraf-verify --env TOMCAT_HEALTH_URL=http://tomcat-health-fixture:8080/health --volume /home/eddywiyatno/git/tomcat-monitoring/config/telegraf/health-check.conf:/etc/telegraf/telegraf.conf:ro,Z --entrypoint /usr/bin/telegraf localhost/telegraf:1.0.0 --test --config /etc/telegraf/telegraf.conf
```

**Expected result.** Endpoint fixture yang tidak ada memberikan status mismatch.

**Actual result and evidence.** Telegraf `--test` mengeluarkan metric dengan `result=response_status_code_mismatch`, `status_code=404`, `response_status_code_match=0i`, `response_string_match=0i`, dan `result_code=6i`.

### 6. Remove every temporary resource

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

**Expected result.** Kedua container, network, dan temporary directory hilang.

**Actual result and evidence.** `podman rm` menghapus `tn008-telegraf` dan `tn008-health-fixture`; Podman memperingatkan bahwa fixture tidak berhenti pada SIGTERM selama 10 detik dan kemudian dihentikan dengan SIGKILL. `podman network rm` menghapus network. Tiga pemeriksaan akhir tidak menghasilkan output dan `test` berhasil, sehingga tidak ada resource TN-008 yang tersisa.

## ✅ Verification Result

Semua criteria TN-008 terpenuhi. Dengan image lokal `localhost/telegraf:1.0.0`, client sementara berhasil mengambil endpoint metrics melalui alias `edkas-pc1`. Contract `200` + `UP` menghasilkan sukses, body `DOWN` menghasilkan `response_string_mismatch`, dan endpoint `404` menghasilkan `response_status_code_mismatch`.

Hasil ini menyelesaikan blocker network-client yang dicatat pada [TN-004](TN-004-verify-telegraf-health-check-component.md). Status `Blocked` pada TN-004 tetap merupakan catatan historis aktivitas tersebut; resolution dicatat secara append-oriented pada TN-008 ini, bukan dengan mengubah evidence masa lalu.

## ⚠️ Scope Boundary

Verifikasi ini membuktikan component Telegraf dan configuration health-check pada network test sementara saja. Ia tidak membuktikan scrape Prometheus, runtime Tomcat nyata, TLS, alerting, deployment, registry publication, commit, atau push. Tidak ada persistent container, host port, named volume, secret, atau production target yang dibuat.

## 🧾 Documentation Integrity Check

**Purpose.** Memastikan catatan hasil TN-008 dan index fase tidak memiliki error whitespace Git.

**Command actually executed.**

```bash
git -C /home/eddywiyatno/git/devops-handbook diff --check -- docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment
```

**Expected result.** Tidak ada output dan exit code `0`.

**Actual result and evidence.** Passed tanpa output dengan exit code `0`.

## ⏭️ Next Steps

Tidak ada tindak lanjut wajib untuk menutup component verification Telegraf. Integrasi Prometheus, target Tomcat nyata, dan deployment harus dibuka sebagai Technical Note baru dengan topology, resource, rollback, dan authorization terpisah.

## 🔗 Related Documentation

- [TN-004 — Verify Telegraf Health Check Component](TN-004-verify-telegraf-health-check-component.md)
- [TN-007 — Build and Smoke Test Telegraf Runtime](TN-007-build-and-smoke-test-telegraf-runtime.md)

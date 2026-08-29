# TN-007 — Build and Smoke Test Telegraf Runtime

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

Membangun image Telegraf dari source repository saat ini dan memverifikasi
binary serta user non-root melalui container sementara.

## 🌍 Background

TN-006 telah membuat source runtime Telegraf dan hanya memverifikasi sintaks
serta integritas source. Image hasil source tersebut belum dibangun dan binary
di dalam container belum diuji.

## 📚 Scope

Aktivitas ini mencakup pemeriksaan sintaks, build image lokal, smoke test
(pengujian singkat kemampuan dasar), pemeriksaan identitas image, dan audit
container sementara. Konfigurasi health check, network integration, deployment
persistent, publication, commit, serta penghapusan image tidak termasuk.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Shell syntax | `entrypoint.sh` dan seluruh script valid. |
| Build | Tag `localhost/telegraf:1.0.0` dan `:latest` terbentuk dari source saat ini. |
| Binary | Container sementara menampilkan versi Telegraf yang dipin. |
| User | Container sementara menjalankan `id -u` selain `0`. |
| Cleanup | Container smoke test memakai `--rm`; tidak ada persistent runtime. |

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Validate the Shell Source** | Memastikan entrypoint dan lifecycle scripts memiliki sintaks yang valid. |
| **Build the Local Image** | Membentuk tag versioned dan `latest` dari source saat ini. |
| **Run the Runtime Smoke Test** | Memeriksa versi Telegraf dan memastikan container tidak berjalan sebagai root. |
| **Inspect the Image and Temporary Container State** | Memeriksa identity image dan memastikan test tidak menyisakan container. |
| **Verify the Source and Journal Integrity** | Memeriksa whitespace pada source dan dokumentasi. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Validate the Shell Source

```bash
bash -n entrypoint.sh scripts/*.sh
```

!!! success "Expected Result"

    Entrypoint dan seluruh lifecycle scripts memiliki sintaks yang valid.

**Actual Result:** pemeriksaan lulus tanpa output.

**Evidence:** exit code command adalah `0`.

</div>

<div class="procedure-step" markdown>

### Build the Local Image

```bash
./scripts/build.sh
```

!!! success "Expected Result"

    Tag `localhost/telegraf:1.0.0` dan `localhost/telegraf:latest` terbentuk.

**Actual Result:** kedua tag berhasil dibentuk.

**Evidence:** kedua tag menunjuk image
`4f8c425e8fd8fd412b25ba0aa8489c3e668e75560f48fd114d09cb9cf9d67cae`.

</div>

<div class="procedure-step" markdown>

### Run the Runtime Smoke Test

```bash
./scripts/test.sh
```

!!! success "Expected Result"

    Binary menampilkan versi yang dipin dan pemeriksaan user non-root lulus.

**Actual Result:** output menampilkan `Telegraf 1.39.3 (git: HEAD@eb37a442)`
dan command selesai dengan exit code `0`.

**Evidence:** assertion internal untuk user non-root tidak menghasilkan error.

</div>

<div class="procedure-step" markdown>

### Inspect the Image and Temporary Container State

```bash
podman image inspect localhost/telegraf:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'
podman ps --all --filter name=telegraf --format '{{.Names}} {{.Status}}'
```

!!! success "Expected Result"

    Image menggunakan user `telegraf` dan custom entrypoint; tidak ada
    container test yang tertinggal.

**Actual Result:** user dan entrypoint sesuai; daftar container kosong.

**Evidence:** inspect melaporkan `User=telegraf` dan entrypoint
`/usr/local/bin/telegraf-entrypoint`; `podman ps` tidak menghasilkan baris.

</div>

<div class="procedure-step" markdown>

### Verify the Source and Journal Integrity

```bash
git -C /home/eddywiyatno/git/telegraf diff --check
git -C /home/eddywiyatno/git/devops-handbook diff --check -- docs/projects/tomcat-monitoring
```

!!! success "Expected Result"

    Source dan dokumentasi tidak memiliki whitespace error.

**Actual Result:** kedua pemeriksaan lulus tanpa output.

**Evidence:** kedua command selesai dengan exit code `0`.

</div>

</div>

## 🖥️ Commands Executed

Seluruh command aktual dicatat pada lima procedure step di atas dengan nama dan
urutan yang sama seperti Implementation Plan.

## 🧾 Outcome

Telegraf runtime source revision saat ini berhasil dibangun sebagai
`localhost/telegraf:1.0.0` dan lulus smoke test binary/non-root. Klaim ini
terbatas pada image lokal dan container sementara; tidak membuktikan runtime
configuration, Telegraf health check, Prometheus scrape, deployment, registry
publication atau commit.

## ⏭️ Next Steps

Source siap untuk review, commit, dan publication hanya bila project owner
memberikan authorization Git terpisah. Component integration menggunakan image
baru memerlukan scope verification baru dan harus lebih dahulu menyelesaikan
blocker network client pada TN-004.

## 🔗 Related Documentation

- [TN-006 — Establish Telegraf Runtime Repository](TN-006-establish-telegraf-runtime-repository.md)
- [TN-004 — Verify Telegraf Health Check Component](TN-004-verify-telegraf-health-check-component.md)

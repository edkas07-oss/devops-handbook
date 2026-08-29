# TN-006 — Establish Telegraf Runtime Repository

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Reconstructed |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Membuat source Telegraf runtime generik dalam repository terpisah agar
`tomcat-monitoring` hanya mengonsumsi artifact serta memiliki configuration
integration.

## 🌍 Background

Project owner mengonfirmasi bahwa `tomcat`, `tomcat-jmx-exporter`, dan Telegraf
adalah artifact runtime terpisah; `tomcat-monitoring` memiliki configuration
dan observability integration. Record dibuat segera setelah source awal selesai,
sehingga berstatus Reconstructed secara transparan.

## 📚 Scope

Aktivitas ini hanya membuat source runtime Telegraf yang dapat digunakan ulang:
metadata image, `Containerfile`, entrypoint, dokumentasi, dan script lifecycle
(build, test, run, dan cleanup). Konfigurasi health check, integrasi Prometheus,
image build, runtime test, container, network, commit, dan publication tidak
termasuk.

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Inspect the Upstream Runtime Contract** | Memeriksa user dan entrypoint image resmi sebagai dasar runtime. |
| **Prepare the Runtime Scripts** | Menerapkan permission executable pada entrypoint dan lifecycle scripts. |
| **Validate the Shell Source** | Memeriksa sintaks seluruh shell script. |
| **Verify the Source Integrity** | Memastikan perubahan source tidak memiliki whitespace error. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Inspect the Upstream Runtime Contract

Periksa metadata image resmi agar source baru mempertahankan perilaku upstream
yang relevan.

```bash
podman image inspect docker.io/library/telegraf:1.39.3-alpine --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Cmd={{json .Config.Cmd}}'
```

!!! success "Expected Result"

    User, entrypoint, dan command image resmi dapat diketahui sebelum source
    runtime dibuat.

**Actual Result:** entrypoint resmi memakai `tini` dan `entrypoint.sh`; metadata
user kosong.

**Evidence:** output `podman image inspect` menjadi dasar entrypoint generik.

</div>

<div class="procedure-step" markdown>

### Prepare the Runtime Scripts

Terapkan permission executable pada entrypoint dan seluruh lifecycle scripts.

```bash
chmod 0755 /home/eddywiyatno/git/telegraf/entrypoint.sh /home/eddywiyatno/git/telegraf/scripts/*.sh
```

!!! success "Expected Result"

    Entrypoint dan lifecycle scripts dapat dijalankan oleh pengguna repository.

**Actual Result:** permission executable berhasil diterapkan.

**Evidence:** command `chmod` selesai tanpa error.

</div>

<div class="procedure-step" markdown>

### Validate the Shell Source

Periksa sintaks sebelum source diserahkan untuk build terpisah.

```bash
bash -n /home/eddywiyatno/git/telegraf/entrypoint.sh /home/eddywiyatno/git/telegraf/scripts/*.sh
```

!!! success "Expected Result"

    Seluruh shell script lulus pemeriksaan sintaks.

**Actual Result:** seluruh shell script valid.

**Evidence:** `bash -n` selesai tanpa output error.

</div>

<div class="procedure-step" markdown>

### Verify the Source Integrity

Periksa perubahan source untuk mendeteksi whitespace error.

```bash
git -C /home/eddywiyatno/git/telegraf diff --check
```

!!! success "Expected Result"

    Tidak ada whitespace error pada source baru.

**Actual Result:** pemeriksaan lulus.

**Evidence:** `git diff --check` selesai tanpa output error.

</div>

</div>

## 🖥️ Commands Executed

Seluruh command aktual dicatat pada empat procedure step di atas sesuai urutan
pelaksanaannya.

## 🧾 Outcome

Repository `telegraf` kini memiliki `AGENTS.md`, identity/configuration,
Containerfile, rootless-friendly entrypoint, dan scripts build/test/run/clean.
Tidak ada image build, runtime test, container, network, atau commit.

## ⏭️ Next Steps

Lanjutkan ke TN-007 untuk membangun image lokal dan memeriksa versi binary serta
user non-root (pengguna container yang bukan `root`) melalui container
sementara.

## 🔗 Related Documentation

- [TN-005 — Record Executed Commands and Strengthen Journal Governance](TN-005-record-executed-commands-and-strengthen-journal-governance.md)
- [TM-ADR-0002 — Separate Generic Runtime Images from Monitoring Integration Configuration](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md)

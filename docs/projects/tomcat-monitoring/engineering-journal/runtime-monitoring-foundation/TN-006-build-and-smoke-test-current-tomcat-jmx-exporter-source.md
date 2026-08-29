# TN-006 — Build and Smoke Test Current Tomcat JMX Exporter Source

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Runtime Monitoring Foundation |
| Activity Date | 2026-08-25 |
| Recorded Date | 2026-08-25 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-25 |

## 🎯 Objective

Membuktikan current source commit `231cb91` dapat menghasilkan image
`localhost/tomcat-jmx-exporter:1.0.0` yang lulus HTTPS dan JVM metrics smoke
test.

## 🌍 Background

TN-002 membuktikan image lokal dari source revision sebelumnya dapat menyajikan
JMX Exporter metrics melalui HTTPS. Setelah itu, self-documentation dan
repository governance diperbarui sampai current commit `231cb91`, tetapi image
belum dibangun ulang dari current source. Kondisi tersebut menghalangi image
lokal digunakan sebagai evidence current source untuk integration activity.

Read-only discovery menemukan base image `localhost/tomcat:9.0` dan target
image `localhost/tomcat-jmx-exporter:1.0.0` tersedia. Target lama memiliki image
ID `47adae9464a12d9be01b87d4e442659b05c2522f9c5ede662025bbe59f2c6685`
dan dibuat pada 2026-08-15. Project owner menyetujui build yang mengganti tag
`1.0.0` dan `latest`, serta self-cleaning smoke test; image lama tidak dihapus
secara eksplisit.

## 📚 Scope

- Catat source revision, base-image readiness, target-image collision, dan
  tool prerequisites.
- Jalankan shell syntax dan source validation yang tersedia.
- Jalankan `scripts/build.sh` dari current source commit `231cb91`.
- Verifikasi identity dan labels image hasil build.
- Jalankan `scripts/test.sh` untuk memverifikasi HTTPS `/metrics`, JMX scrape,
  dan minimum JVM heap metric.
- Verifikasi temporary container serta test material telah dibersihkan.
- Konsolidasikan hasil ke phase index dan current-state documentation.

CA production, persistent container, Prometheus scrape, Telegraf integration,
cleanup image lama, commit, publication, dan deployment tidak termasuk
scope.

## ✅ Criteria

| Criterion | Expected result |
| --- | --- |
| Source identity | Working tree bersih pada commit `231cb91`. |
| Prerequisites | Base image, Podman, `curl`, `openssl`, dan build contract tersedia. |
| Source validation | `bash -n` serta source checks yang tersedia lulus. |
| Build | `scripts/build.sh` menghasilkan image tag `1.0.0` dan `latest` dari current source. |
| Image contract | Image labels menunjukkan version `1.0.0` dan JMX Exporter `1.6.0`. |
| Smoke test | HTTPS `/metrics`, JMX scrape duration, dan JVM heap metric tersedia. |
| Cleanup | Temporary smoke-test container dan test directory tidak tersisa. |
| Boundary | Tidak ada persistent runtime, image cleanup, commit, atau deployment. |

## 🧪 Method

| Tahap | Metode |
| --- | --- |
| **Review the Handoff and Approval Gate** | Memeriksa source, governance, scope, dan image yang tersedia sebelum mutation. |
| **Validate Build Readiness and Source** | Memeriksa commit, tool, artifact checksum, shell syntax, dan base image. |
| **Build Current Source and Inspect the Image** | Membangun current source lalu memeriksa identity serta label image. |
| **Run the Smoke Test and Verify Cleanup** | Menguji endpoint HTTPS dan JVM metrics lalu memastikan resource sementara terhapus. |
| **Consolidate Current-State Documentation** | Memperbarui dokumentasi hanya berdasarkan hasil build dan test yang terbukti. |
| **Verify Documentation and Final Source State** | Memeriksa diff, link, status TN, dan kondisi akhir source. |

## 🧪 Execution

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Review the Handoff and Approval Gate

```bash
git status --short --branch
sed -n '1,280p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-013-verify-prometheus-named-volume-runtime-and-lab-access.md
sed -n '1,280p' docs/projects/tomcat-monitoring/infrastructure/index.md
sed -n '1,280p' AGENTS.md
sed -n '1,280p' README.md
rg --files | sort
sed -n '1,320p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
sed -n '1,360p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-005-implement-repository-agents-governance.md
sed -n '1,120p' PROJECT
sed -n '1,120p' VERSION
sed -n '1,220p' CONFIG
sed -n '1,300p' Containerfile
sed -n '1,320p' entrypoint.sh
sed -n '1,360p' scripts/build.sh
sed -n '1,420p' scripts/test.sh
git rev-parse HEAD
git log -3 --oneline --decorate
podman image exists localhost/tomcat:9.0
podman image exists localhost/tomcat-jmx-exporter:1.0.0
podman image inspect localhost/tomcat-jmx-exporter:1.0.0 --format '{{.Id}} {{.Created}} {{index .Labels "org.opencontainers.image.version"}} {{index .Labels "io.prometheus.jmx-exporter.version"}}'
```

!!! success "Expected Result"

    Governance, approved scope, source revision, base image, dan existing target
    image dapat diidentifikasi sebelum build dimulai.

**Actual Result:** percobaan pertama tiga command Podman gagal karena sandbox tidak dapat mengubah
permission `/run/user/1000/libpod`. Read-only inspection yang sama berhasil
setelah runtime permission disetujui. Base dan target image tersedia; target
lama memiliki labels version `1.0.0` dan JMX Exporter `1.6.0`.

**Evidence:** source dan image inspection mencatat initial commit serta old
image identity sebelum mutation.

</div>

<div class="procedure-step" markdown>

### Validate Build Readiness and Source

```bash
git status --short --branch
git rev-parse HEAD
bash -n entrypoint.sh scripts/*.sh
git diff --check
command -v podman curl openssl sha256sum
git status --ignored --short .artifacts
test -f docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-006-build-and-smoke-test-current-tomcat-jmx-exporter-source.md
git status --short --branch
sha256sum .artifacts/jmx_prometheus_javaagent.jar
rg --files --hidden .artifacts
podman image exists localhost/tomcat:9.0
podman image inspect localhost/tomcat-jmx-exporter:1.0.0 localhost/tomcat-jmx-exporter:latest --format '{{.Id}} {{.RepoTags}} {{.Created}}'
```

!!! success "Expected Result"

    Source berada pada commit `231cb91`, seluruh tool tersedia, shell syntax
    lulus, artifact checksum sesuai, dan base image siap digunakan.

**Actual Result:** working tree source bersih pada full commit
`231cb915cc2e058abd1fa0377877b120a9d7e2be`. Shell syntax dan source
whitespace check lulus; seluruh tool prerequisite tersedia. Artifact cache
hanya berisi JMX Exporter JAR dan checksum
`a95983fd96e865d2bcdf911cc500e7c82808c27ab9fd226bf96732b6c3d8c46e`
sesuai `CONFIG`. Base image tersedia. Sebelum build, tag `1.0.0` dan `latest`
keduanya menunjuk image lama `47adae9464a1`.

**Evidence:** commit, tool inventory, checksum, dan old image ID tercatat pada
output pemeriksaan readiness.

</div>

<div class="procedure-step" markdown>

### Build Current Source and Inspect the Image

```bash
./scripts/build.sh
podman image inspect localhost/tomcat-jmx-exporter:1.0.0 localhost/tomcat-jmx-exporter:latest --format '{{.Id}} {{.RepoTags}} {{.Created}} {{index .Labels "org.opencontainers.image.version"}} {{index .Labels "io.prometheus.jmx-exporter.version"}}'
git status --short --branch
```

!!! success "Expected Result"

    Build menghasilkan tag `1.0.0` dan `latest` dari current source dengan
    label version serta JMX Exporter yang benar.

**Actual Result:** build memverifikasi checksum JMX Exporter JAR di host dan kembali di image
layer, lalu menyelesaikan 13 Containerfile steps. Tag `1.0.0` serta `latest`
kini menunjuk image ID
`47eaad88a544ec0ef718f1fe449ce617c2fcd060a0ecfbd623530ec9d564fc30`
dengan labels version `1.0.0` dan JMX Exporter `1.6.0`. Source working tree tetap
bersih setelah build.

**Evidence:** kedua tag menunjuk image ID `47eaad88a544...` dan source tetap
bersih.

</div>

<div class="procedure-step" markdown>

### Run the Smoke Test and Verify Cleanup

```bash
./scripts/test.sh
podman ps --all --filter name=tomcat-jmx-exporter-test --format '{{.Names}} {{.Status}}'
find /tmp -maxdepth 1 -type d -name 'tomcat-jmx-exporter-test.*' -print
git status --short --branch
```

!!! success "Expected Result"

    HTTPS `/metrics`, JMX scrape duration, dan JVM heap metric tersedia;
    container serta directory test sementara tidak tersisa.

**Actual Result:** smoke test melaporkan bahwa HTTPS `/metrics` dan pengumpulan metrics JVM lokal
berfungsi. Script memverifikasi metric `jmx_scrape_duration_seconds` dan
`jvm_memory_heap_used_bytes`. Pemeriksaan setelah test tidak menemukan
container `tomcat-jmx-exporter-test-*` maupun temporary test directory; source
working tree tetap bersih.

**Evidence:** test output memuat `jmx_scrape_duration_seconds` dan
`jvm_memory_heap_used_bytes`; cleanup query tidak menemukan resource.

</div>

<div class="procedure-step" markdown>

### Consolidate Current-State Documentation

```bash
rg -n 'clean image build|current source|Current source|earlier source revision|image.*belum diverifikasi|belum.*build|JMX Exporter source' docs/projects/tomcat-monitoring
sed -n '1,170p' docs/projects/tomcat-monitoring/development/index.md
sed -n '1,125p' docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
sed -n '62,85p' docs/projects/tomcat-monitoring/index.md
sed -n '195,225p' docs/projects/tomcat-monitoring/infrastructure/index.md
```

!!! success "Expected Result"

    Project documentation menghubungkan current source `231cb91` dengan image
    serta smoke-test evidence tanpa mengklaim publication atau deployment.

**Actual Result:** Project overview, Development, Infrastructure, dan phase index diperbarui untuk
mengaitkan current source `231cb91` dengan image serta smoke-test evidence
TN-006. Klaim registry publication, deployment, Prometheus scrape, dan
end-to-end monitoring tetap tidak dibuat.

**Evidence:** pencarian current-state menunjukkan revision dan batas klaim yang
sesuai.

</div>

<div class="procedure-step" markdown>

### Verify Documentation and Final Source State

```bash
git diff --check
git diff --stat
git diff -- docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/.pages docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
rg -n '[[:blank:]]+$' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/.pages docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-006-build-and-smoke-test-current-tomcat-jmx-exporter-source.md
rg -n '^\| Status \| Completed \|$|231cb915cc2e058abd1fa0377877b120a9d7e2be|47eaad88a544ec0ef718f1fe449ce617c2fcd060a0ecfbd623530ec9d564fc30|TN-006' docs/projects/tomcat-monitoring/index.md docs/projects/tomcat-monitoring/development/index.md docs/projects/tomcat-monitoring/infrastructure/index.md docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/.pages docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-006-build-and-smoke-test-current-tomcat-jmx-exporter-source.md
command -v mkdocs
test -f docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-002-implement-tomcat-jmx-exporter-image.md
test -f docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-005-implement-repository-agents-governance.md
test -f docs/projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/index.md
test -f docs/projects/tomcat-monitoring/infrastructure/index.md
git status --short --branch
```

!!! success "Expected Result"

    Diff dan whitespace check lulus, seluruh relative link tersedia, status TN
    konsisten, dan source repository tetap bersih.

**Actual Result:** documentation diff check lulus, trailing-whitespace scan tidak menemukan
match, status TN serta source/image references ditemukan, dan seluruh relative
link target TN-006 tersedia. Source repository tetap bersih. `mkdocs` tidak
tersedia sehingga render site tidak dijalankan dan dependency tidak dipasang.

**Evidence:** seluruh source/link check lulus; MkDocs dicatat `Not verified`.

</div>

</div>

## 🖥️ Commands Executed

Seluruh command aktual ditempatkan pada enam procedure step di atas sesuai
urutan pelaksanaannya. Nama tahap pada section ini sama dengan tahap pada
`Method`, sehingga command tidak perlu direkonstruksi dari raw command dump.

| Evidence | Actual result |
| --- | --- |
| Source identity | Working tree bersih pada `231cb915cc2e058abd1fa0377877b120a9d7e2be`. |
| Artifact integrity | Host dan image build menerima pinned SHA-256 JMX Exporter `1.6.0`. |
| Build | Image `47eaad88a544ec0ef718f1fe449ce617c2fcd060a0ecfbd623530ec9d564fc30` berhasil dibangun dan menerima tags `1.0.0` serta `latest`. |
| Image labels | Version `1.0.0` dan JMX Exporter `1.6.0`. |
| Smoke test | HTTPS `/metrics`, JMX scrape duration, dan JVM heap metric lulus. |
| Cleanup | Tidak ada temporary test container atau test directory yang tersisa. |
| Source state | Working tree tetap bersih setelah build dan test. |

## ⚠️ Exceptions

Build menggunakan cache pada beberapa Containerfile steps, tetapi JMX Exporter
JAR tetap diverifikasi pada host dan kembali di image layer. Hasil ini
membuktikan build current source yang bersih dari perubahan working tree; ia
bukan `--no-cache` build.

MkDocs render berstatus `Not verified` karena executable tidak tersedia dan
dependency tidak dipasang.

## 📌 Conclusion

Seluruh mandatory criteria TN-006 memenuhi expected result. Image hasil current
source layak menjadi input aktivitas integration berikutnya pada local lab,
dengan batas bahwa CA actual, target runtime, dan Prometheus scrape belum diuji.

## 🔄 Source-Control Handoff

Dokumentasi hasil build dan smoke test current source disimpan pada commit
Handbook `e1aee71`. Repository `tomcat-jmx-exporter` tidak memerlukan commit
baru karena verification tidak mengubah source.

## 🧾 Outcome

Current source `231cb91` berhasil menghasilkan local image
`localhost/tomcat-jmx-exporter:1.0.0` dengan ID `47eaad88a544`. HTTPS endpoint,
JMX scrape duration, dan JVM heap metric lulus self-cleaning component smoke
test. Seluruh mandatory criteria terpenuhi dan temporary resource dibersihkan.

Image lama tidak dihapus sesuai exclusion. Hasil ini tidak membuktikan registry
publication, deployment, Prometheus scrape, Telegraf, atau end-to-end topology.

## ⏭️ Next Steps

Setelah current-source image terverifikasi, aktivitas terpisah dapat menyiapkan
CA actual, runtime target, network aliases, dan cleanup plan untuk Prometheus
scrape integration.

## 🔗 Related Documentation

- [TN-002 — Implement Tomcat JMX Exporter Image](TN-002-implement-tomcat-jmx-exporter-image.md)
- [TN-005 — Implement Repository AGENTS.md Governance](TN-005-implement-repository-agents-governance.md)
- [Runtime Monitoring Foundation](index.md)
- [Infrastructure](../../infrastructure/index.md)

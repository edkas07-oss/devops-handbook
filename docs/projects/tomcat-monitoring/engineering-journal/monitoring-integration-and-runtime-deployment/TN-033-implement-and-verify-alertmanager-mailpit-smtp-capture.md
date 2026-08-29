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

Menambahkan tujuan pengiriman email Alertmanager ke Mailpit tanpa credential
(informasi autentikasi), lalu membuktikan bahwa email peringatan (`firing`) dan
email pemulihan (`resolved`) diterima melalui container sementara yang telah
ditetapkan pada TN-032.

## 🌍 Background

TN-031 memilih Mailpit lokal agar lab tidak memerlukan credential Gmail atau
pengiriman email ke layanan eksternal. TN-032 menerima penggunaan image resmi
Mailpit secara langsung (`direct-upstream exception`), mengunci versi Mailpit
`v1.31.0`, serta menetapkan nama resource, port lokal, identitas pengujian, dan
aturan pembersihan resource sementara.

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

Gunakan pengecualian image upstream yang telah diterima pada TN-032 dengan
referensi Mailpit berikut:

```text
ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24
```

SMTP Mailpit hanya tersedia di dalam container network melalui
`mailpit:1025`. Script pengujian pada host hanya mengakses API Mailpit melalui
`127.0.0.1:18025` dan API Alertmanager melalui `127.0.0.1:19093`. Pengujian
tidak mengirim email ke layanan eksternal dan tidak menyimpan message secara
permanen.

Keputusan ini menerapkan
[TM-ADR-0005](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md),
yang mencatat alasan Mailpit menjadi target verifikasi notification lab.

## 🗺️ Architecture

```text
Host verification script
  |-- POST synthetic alerts --> 127.0.0.1:19093
  `-- inspect messages -------> 127.0.0.1:18025

tm-tn033-alertmanager --SMTP--> mailpit:1025
         \________ tm-tn033-mailpit network ________/
```

## 🧭 Implementation Plan

Implementation mengikuti lima tahap berikut. Nama dan urutannya sama dengan
procedure step pada bagian `Implementation` agar rencana dan pelaksanaan dapat
dibandingkan secara langsung.

| Tahap | Rencana |
| --- | --- |
| **Review the Approved Boundary and Current Source** | Memeriksa scope yang disetujui, source yang berlaku, serta perubahan TN sebelumnya yang harus dipertahankan. |
| **Implement and Validate the Mailpit Interfaces** | Menerapkan konfigurasi serta script Mailpit, kemudian menjalankan pemeriksaan sintaks dan validator repository. |
| **Run the Isolated Email Capture** | Menjalankan Alertmanager dan Mailpit sementara untuk menguji email peringatan (`firing`) dan pemulihan (`resolved`). |
| **Confirm the Image Identity and Cleanup** | Memastikan image Mailpit sesuai versi yang diterima dan seluruh resource sementara telah dibersihkan. |
| **Consolidate the Verified Result** | Menyelaraskan hasil yang sudah dibuktikan ke dokumentasi serta mencatat source-control handoff. |

```text
Review the Approved Boundary and Current Source
                    |
                    v
Implement and Validate the Mailpit Interfaces
                    |
                    v
Run the Isolated Email Capture
                    |
                    v
Confirm the Image Identity and Cleanup
                    |
                    v
Consolidate the Verified Result
```

Perubahan source hanya boleh dikoreksi melalui perubahan lanjutan yang direview;
perubahan pengguna tidak boleh di-reset. Pembersihan runtime hanya mencakup
resource yang dibuat TN-033. Penghapusan image memerlukan izin terpisah dan
tidak termasuk dalam aktivitas ini.

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Review the Approved Boundary and Current Source

Pastikan pekerjaan dimulai dari source dan perubahan pengguna yang benar.
Pemeriksaan ini juga memastikan konfigurasi webhook lama tetap dapat digunakan
sebagai pengujian historis TN-029.

1. Baca script pengujian webhook, validator, dan dokumentasi yang berlaku.
2. Periksa diff serta status working tree sebelum perubahan dilakukan.
3. Pastikan perubahan TN sebelumnya dapat dipertahankan tanpa reset.

```bash
# /home/eddywiyatno/git/tomcat-monitoring
sed -n '1,420p' scripts/verify-alertmanager-webhook.sh
sed -n '1,260p' scripts/validate.sh && sed -n '1,300p' scripts/validate-alertmanager.sh
sed -n '1,260p' README.md && sed -n '1,240p' config/alertmanager/README.md && sed -n '1,220p' validation/README.md
git diff -- README.md config/alertmanager/README.md scripts/validate-alertmanager.sh scripts/validate.sh validation/README.md && git status --short --branch
git status --short && sed -n '1,240p' config/alertmanager/alertmanager.yml && sed -n '1,280p' scripts/validate-alertmanager.sh && sed -n '1,260p' scripts/validate.sh && sed -n '1,320p' scripts/verify-alertmanager-webhook.sh
sed -n '1,280p' README.md && sed -n '1,260p' config/alertmanager/README.md && sed -n '1,300p' validation/README.md && sed -n '1,320p' /home/eddywiyatno/git/devops-handbook/docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md
```

!!! success "Expected Result"

    Source, validator, dokumentasi, dan perubahan yang sudah ada dapat
    dibedakan. Tidak ada perubahan pengguna yang perlu di-reset atau ditimpa.

**Actual Result:** kondisi awal berhasil diperiksa. Perubahan TN-029 sampai
TN-032 dipertahankan dan menjadi baseline TN-033.

**Evidence:** output `git status`, diff terbatas, serta isi source dan
dokumentasi terkait tersedia dalam execution record.

</div>

<div class="procedure-step" markdown>

### Implement and Validate the Mailpit Interfaces

Ubah tujuan pengiriman aktif dari webhook `integration-bridge` menjadi email
lokal `lab-mailpit`, lalu pastikan seluruh script masih valid secara sintaks dan
kontrak repository.

Konfigurasi yang diterapkan menetapkan:

- internal-only SMTP `mailpit:1025` dengan `require_tls: false` karena koneksi
  hanya berada pada disposable container network;
- synthetic sender `alertmanager@tomcat-monitoring.invalid` dan recipient
  `operator@tomcat-monitoring.invalid`;
- `send_resolved: true`, lima stable grouping labels, dan deterministic subject;
  serta
- tidak ada authentication, secret, personal identity, relay, atau external
  endpoint.

Validator statis memeriksa receiver, identitas `.invalid`, ketiadaan webhook
aktif dan credential, serta nama resource pengujian Mailpit. Validator utama
repository juga mewajibkan script baru
`scripts/verify-alertmanager-mailpit.sh`.

1. Terapkan konfigurasi email Mailpit dan script pengujiannya.
2. Jadikan script pengujian dapat dieksekusi.
3. Jalankan pemeriksaan sintaks, validator repository, dan whitespace.

```bash
# /home/eddywiyatno/git/tomcat-monitoring
chmod 0755 scripts/verify-alertmanager-mailpit.sh
bash -n scripts/*.sh
./scripts/validate.sh
git diff --check
```

!!! success "Expected Result"

    Script pengujian dapat dieksekusi, seluruh shell script valid, kontrak
    konfigurasi Mailpit lulus, dan diff tidak memiliki whitespace error.

**Actual Result:** seluruh pemeriksaan selesai dengan exit code `0`.

**Evidence:** `bash -n`, `./scripts/validate.sh`, dan `git diff --check`
seluruhnya lulus.

</div>

<div class="procedure-step" markdown>

### Run the Isolated Email Capture

Jalankan pengujian menggunakan Alertmanager dan Mailpit sementara. Script
membuat network serta container dengan nama khusus TN-033, mengirim alert
peringatan dan pemulihan, memeriksa kedua email melalui API Mailpit, lalu
membersihkan resource sementara.

1. Jalankan script verification dengan reference image yang telah diterima.
2. Biarkan script mengirim alert firing dan resolved melalui Alertmanager.
3. Periksa kedua message melalui API Mailpit.
4. Ulangi pengujian setelah memperbaiki cara pembacaan versi Mailpit.

```bash
# /home/eddywiyatno/git/tomcat-monitoring
./scripts/verify-alertmanager-mailpit.sh
```

Command yang sama dijalankan empat kali selama penyempurnaan verification
interface:

1. Run pertama menangkap kedua email dan membersihkan resource, tetapi berakhir
   dengan exit code `141` karena output `/mailpit --version` diteruskan ke
   `head`.
2. Run kedua kembali menangkap kedua email dan membersihkan resource, tetapi
   opsi versi Mailpit mengembalikan exit code `1`.
3. Pemeriksaan versi dipindahkan ke API `/api/v1/info`; run ketiga selesai
   dengan exit code `0`.
4. Run terakhir menambahkan pemeriksaan body message lengkap dan kembali
   selesai dengan exit code `0`.

!!! success "Expected Result"

    Mailpit menerima satu email peringatan dan satu email pemulihan dengan
    sender, recipient, subject, dan lima grouping label yang sesuai. Seluruh
    resource sementara dibersihkan meskipun pengujian gagal di tengah proses.

**Actual Result:** run terakhir lulus. Dua kegagalan awal hanya berasal dari
cara membaca versi Mailpit; pengiriman email dan cleanup pada kedua run tersebut
tetap berhasil.

**Evidence:** run ketiga dan keempat selesai dengan exit code `0`; final run
memastikan body message memuat seluruh grouping label dan value yang diwajibkan.

</div>

<div class="procedure-step" markdown>

### Confirm the Image Identity and Cleanup

Periksa bahwa image yang digunakan sesuai versi yang diterima dan tidak ada
container atau network TN-033 yang tertinggal.

1. Periksa digest, architecture, operating system, dan label image Mailpit.
2. Cari seluruh container dengan nama yang diawali `tm-tn033`.
3. Cari network `tm-tn033-mailpit`.

```bash
# /home/eddywiyatno/git/tomcat-monitoring
podman image inspect --format 'digest={{.Digest}} arch={{.Architecture}} os={{.Os}} labels={{json .Labels}}' 'ghcr.io/axllent/mailpit:v1.31.0@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24'
podman ps -a --filter name=tm-tn033 --format '{{.Names}}'
podman network ls --filter name=tm-tn033-mailpit --format '{{.Name}}'
```

!!! success "Expected Result"

    Image cocok dengan digest serta platform yang diterima. Container
    `tm-tn033-mailpit`, container `tm-tn033-alertmanager`, dan network
    `tm-tn033-mailpit` sudah tidak tersedia.

**Actual Result:** identity Mailpit `v1.31.0` pada `linux/amd64` sesuai.
Container, network, temporary file, dan listener TN-033 tidak tersisa. Image
Mailpit sengaja dipertahankan sesuai scope.

**Evidence:** image inspection mengembalikan identity yang diterima, sedangkan
container dan network query tidak mengembalikan resource TN-033.

</div>

<div class="procedure-step" markdown>

### Consolidate the Verified Result

Pastikan dokumentasi tidak lagi menyatakan Mailpit belum diterapkan dan catat
source-control handoff tanpa melakukan commit atau push di luar izin terpisah.

1. Cari pernyataan lama yang masih menyebut Mailpit belum diterapkan.
2. Pastikan status TN-033 dan navigation entry sudah konsisten.
3. Periksa ketersediaan MkDocs dan kondisi final kedua repository.

```bash
# /home/eddywiyatno/git/devops-handbook
rg -n "TN-033|Mailpit|mailpit|Pending|not yet pulled|belum diimplementasikan|belum diterapkan" docs/projects/tomcat-monitoring -g '*.md'
rg -n 'Mailpit.*(pending|not implemented|not verified)|source integration, image pull|runtime belum dikerjakan|implementation pending|source, image, and runtime not implemented' docs/projects/tomcat-monitoring -g '*.md'
rg -n 'Status \| Completed|message_body_group_labels|exit `0`|TN-033-implement-and-verify' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/index.md docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/.pages
if command -v mkdocs >/dev/null; then mkdocs --version; else echo 'mkdocs=not-installed'; fi

# Post-push diagram clarification
git status --short --branch
sed -n '175,235p' docs/projects/tomcat-monitoring/engineering-journal/monitoring-integration-and-runtime-deployment/TN-033-implement-and-verify-alertmanager-mailpit-smtp-capture.md
git -C /home/eddywiyatno/git/tomcat-monitoring status --short --branch
git -C /home/eddywiyatno/git/tomcat-monitoring log -1 --oneline
```

!!! success "Expected Result"

    Status TN, phase index, dan current-state documentation menyampaikan hasil
    yang sama. Riwayat commit dapat ditelusuri dan tidak ada klaim bahwa render
    MkDocs sudah diverifikasi bila executable tidak tersedia.

**Actual Result:** pemeriksaan konsistensi dan `git diff --check` lulus. MkDocs
tidak tersedia sehingga rendered-site build tidak dijalankan.

**Evidence:** pencarian status tidak menemukan klaim current-state yang
bertentangan; commit dan branch handoff dapat ditelusuri pada kedua repository.

</div>

</div>

Script webhook historis TN-029 tetap menggunakan konfigurasi webhook sementara
dan tidak bergantung pada receiver aktif Mailpit. Sintaks script tersebut
divalidasi, tetapi pengujian runtime TN-029 tidak diulang dalam TN-033.

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

## ✅ Operator Validation

Pengujian TN-033 memakai container sementara dan langsung membersihkannya
setelah hasil API diperoleh. Karena itu, inbox Mailpit TN-033 sudah tidak dapat
dibuka setelah aktivitas selesai.

| Item | Value |
| --- | --- |
| Status | Tidak tersedia setelah cleanup TN-033 |
| Pemeriksa | Project owner |
| Sasaran pemeriksaan | Satu email firing dan satu email resolved dengan identitas pengujian |
| Cara akses selama pengujian | API/UI Mailpit hanya melalui `127.0.0.1:18025` ketika verification script masih berjalan |
| Masa berlaku evidence | Sementara; message hilang ketika container Mailpit TN-033 dibersihkan |
| Pemeriksaan otomatis | Lulus; API memverifikasi sender, recipient, subject, urutan status, dan lima grouping label |
| Keputusan visual | Tidak dilakukan pada TN-033 karena resource sudah dibersihkan |

!!! info "Cara Memeriksa Hasil Setelah TN-033"

    Jangan menjalankan ulang container sementara hanya untuk membuka UI karena
    tindakan tersebut memerlukan authorization runtime baru. Persistent Mailpit
    dan petunjuk membuka UI kemudian tersedia pada
    [TN-035](TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md#operator-validation).

## 🖥️ Commands Executed

Seluruh command aktual ditempatkan pada procedure step sesuai urutan
pelaksanaannya. Section ini menjadi indeks agar pembaca tidak perlu mencari
ulang command berdasarkan raw log.

| Tahap | Procedure Step |
| --- | --- |
| Pemeriksaan source dan scope | [Review the Approved Boundary and Current Source](#review-the-approved-boundary-and-current-source) |
| Perubahan serta validasi source | [Implement and Validate the Mailpit Interfaces](#implement-and-validate-the-mailpit-interfaces) |
| Pengujian firing/resolved | [Run the Isolated Email Capture](#run-the-isolated-email-capture) |
| Pemeriksaan image dan cleanup | [Confirm the Image Identity and Cleanup](#confirm-the-image-identity-and-cleanup) |
| Konsolidasi dokumentasi | [Consolidate the Verified Result](#consolidate-the-verified-result) |

## 🔀 Version-Control Handoff

Project owner memberikan authorization commit terpisah setelah implementation
dan verification selesai pada 2026-08-27. Source repository
`tomcat-monitoring` dicatat dalam commit `f380636` (`feat: add Alertmanager
delivery verification`). Engineering Journal dan current-state documentation
disimpan melalui commit `de08cb3` pada repository `devops-handbook`. Project
owner kemudian melakukan push; kedua local branch telah terkonfirmasi sejajar
dengan `origin/main`.

## 🧾 Outcome

TN-033 selesai. Alertmanager memiliki konfigurasi untuk mengirim email ke
Mailpit tanpa credential. Pengujian container sementara membuktikan bahwa satu
email peringatan dan satu email pemulihan diterima dengan sender, recipient,
subject, serta grouping label yang sesuai. Pengujian juga membuktikan bahwa
SMTP hanya tersedia di container network dan seluruh resource sementara sudah
dibersihkan. Image Mailpit tetap tersedia sesuai authorization.

Hasil ini belum membuktikan pengiriman alert dari Prometheus, runtime
Alertmanager yang terus berjalan, email eksternal, Integration Bridge, atau
TrueSight. Inbox TN-033 juga tidak dapat diperiksa lagi setelah cleanup karena
Mailpit pada aktivitas ini bersifat sementara.

## ❓ Open Questions

| Question | Status | Owner | Closure Condition |
| --- | --- | --- | --- |
| Apakah Alertmanager akan diterapkan pada persistent lab? | Deferred | Project owner | New Technical Note accepts topology, continuity, rollback, exact resources, and runtime authorization |
| Apakah Prometheus-to-Alertmanager runtime delivery akan diverifikasi? | Deferred | Project owner | Persistent or isolated delivery target and verification boundary are approved |
| Apakah inbox atau external event delivery diperlukan? | Deferred | Project owner and future integration owner | Provider or Integration Bridge ownership, TLS/authentication, secret lifecycle, recipient handling, and external-delivery authorization are accepted |

## ⏭️ Next Steps

### Batas yang Sudah Dibuktikan TN-033

```text
Synthetic alert dari verification script
                |
                v
Disposable Alertmanager
                |
                | SMTP internal: mailpit:1025
                v
Disposable Mailpit
                |
                v
Mailpit API memverifikasi firing dan resolved email

Setelah verification:
Alertmanager container + Mailpit container + network -> dihapus
Mailpit image                                      -> dipertahankan
```

Alur tersebut membuktikan fungsi email receiver Alertmanager secara isolated.
Ia belum membuktikan bahwa persistent Prometheus benar-benar mengirim alert ke
Alertmanager.

### Target Alur Berikutnya

```text
Persistent Prometheus
        |
        | alert firing/resolved melalui API v2
        v
Persistent Alertmanager
        |
        | SMTP internal
        v
Mailpit verification target
        |
        v
Operator memeriksa email firing dan resolved
```

### Urutan Technical Note yang Direkomendasikan

```text
TN-033 Completed
        |
        v
TN-034 Decision Contract
  - tetapkan persistent topology dan exact resources
  - pilih Mailpit temporary atau persistent
  - tetapkan storage, continuity, rollback, dan cleanup
  - tetapkan verification boundary dan authorization
        |
        | project-owner approval
        v
TN-035 Implementation and Verification
  - deploy persistent Alertmanager
  - hubungkan persistent Prometheus ke alertmanager:9093
  - hasilkan alert firing dan resolved
  - buktikan delivery sampai Mailpit
  - verifikasi continuity atau jalankan rollback
```

TN-034 kemudian menetapkan rancangan persistent runtime dan TN-035 telah
menerapkannya. Untuk memeriksa email melalui browser, gunakan bagian
[Operator Validation pada TN-035](TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md#operator-validation).
External inbox delivery, Gmail, Integration Bridge, dan TrueSight tetap berada
di luar hasil TN-033.

## 📝 Notes

Penyajian TN-033 dinormalisasi pada 2026-08-29 berdasarkan format procedure
TN-035. Normalisasi hanya memperjelas urutan langkah, hasil yang diharapkan,
hasil aktual, command, dan operator handoff; fakta teknis serta status historis
TN-033 tidak diubah.

## 🔗 Related Documentation

- [TN-032 — Define Mailpit Runtime Ownership and Disposable Verification Contract](TN-032-define-mailpit-runtime-ownership-and-disposable-verification-contract.md)
- [TN-035 — Implement and Verify Persistent Prometheus–Alertmanager–Mailpit Delivery](TN-035-implement-and-verify-persistent-prometheus-alertmanager-mailpit-delivery.md)
- [TM-ADR-0005 — Use Mailpit as the Persistent Lab Notification Verification Target](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md)
- [Architecture](../../architecture/index.md)
- [Development](../../development/index.md)
- [Infrastructure](../../infrastructure/index.md)

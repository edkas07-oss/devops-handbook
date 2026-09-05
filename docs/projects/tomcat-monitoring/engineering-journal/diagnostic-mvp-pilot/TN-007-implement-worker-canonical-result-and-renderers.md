# TN-007 — Implement Worker, Canonical Result, and Renderers

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

Mengubah durable queue item menjadi persisted canonical result melalui satu worker, lalu membentuk plain-text/HTML content dan operational state tanpa HTTP atau SMTP runtime.

## 📚 Scope

Pekerjaan yang disetujui mencakup:
- Migration `002`, *single worker*, *global deadline* 60 detik;
- Semantik *canonical result* v1, hash deterministik, proteksi *material-change*, dan persistensi SQLite;
- Model status operasional *health/metrics*;
- *Renderer* laporan 7-seksi (Plain Text dan HTML);
- Unit tests, integration tests, validator, README, dan dokumentasi *current-state*.

Pekerjaan yang dikecualikan mencakup HTTP/TLS, SMTP, runtime Mailpit, build image, deployment, commit, dan push.

## 📋 Prerequisites

| Item | State |
| --- | --- |
| TN-005/TN-006 source | Commit `aa55170`, tersinkronisasi dengan `origin/main` |
| Node runtime | Local image `localhost/nodejs:24.18.0` |
| Tests | Container sementara (*temporary container*) dan SQLite saja |

## 🔄 Technical Workflow

Alur kerja pemrosesan antrean kerja oleh *single worker loop*, pembentukan hasil kanonikal, hingga rendering laporan:

```text
1. durable queue -> 2. single worker -> 3. bounded evidence -> 4. TD rule
                 -> 5. canonical result v1 -> 6. SQLite -> 7. text/HTML renderer
```

### Rincian Aktivitas Alur Kerja

1. **durable queue:**
   Antrean kerja persisten (`work_queue`) pada database SQLite lokal yang menampung event alert terverifikasi berstatus `queued`.
2. **single worker:**
   Worker asinkron loop tunggal (*concurrency = 1*) yang secara sekuensial mengklaim item tertua dari antrean dan mengubah statusnya menjadi `processing` untuk mencegah *lock contention* pada SQLite.
3. **bounded evidence:**
   Pengumpulan bukti telemetri terisolasi (log catalina, rekaman spool atomik, metrik JMX Prometheus, dan status health) yang dibatasi pada jendela waktu kejadian insiden untuk target terkait.
4. **TD rule:**
   Evaluasi seluruh bukti yang terkumpul terhadap basis aturan keputusan deterministik `TomcatDown`.
5. **canonical result v1:**
   Penyusunan hasil diagnosis kanonikal standar v1:
    - **diagnostic_id:** Pembuatan pengidentifikasi unik diagnosis (UUID v4).
    - **result_hash:** Perhitungan SHA-256 hash deterministik dengan mengecualikan timestamp volatil (*volatile timestamp exclusion*).
    - **material update guard:** Pengecekan perubahan materiil insiden untuk membatasi pengiriman notifikasi berulang.
6. **SQLite:**
   Persistensi atomik hasil kanonikal ke tabel `canonical_results` dan ringkasan bukti ke `evidence_summaries`, lalu memperbarui status item antrean `work_queue` menjadi `completed`.
7. **text/HTML renderer:**
   Transformasi hasil kanonikal menjadi format presentasi laporan diagnosis 7-seksi SRE:
    - **plain text renderer:** Format teks polos (*plain text*) 7-seksi SRE sebagai payload fallback email.
    - **HTML renderer:** Format HTML responsif 7-seksi SRE untuk rendering visual email insiden.

## 🧭 Implementation Plan

| Tahap | Rencana |
| :--- | :--- |
| **Add Result Persistence** | Menambahkan migrasi `002-canonical-results.sql` dan persistensi canonical results pada repositori SQLite. |
| **Implement the Single Worker Loop** | Mengimplementasikan pemrosesan antrean sekuensial tunggal (single worker) untuk evaluasi deterministik. |
| **Implement Canonical Renderers** | Mengembangkan format renderer laporan diagnosis 7-seksi (HTML dan Plain Text). |
| **Run Source Verification** | Menjalankan validasi statis dan pengujian integrasi berbasis kontainer sementara. |

## ⚙️ Implementation

<div class="procedure" markdown>
<div class="procedure-step" markdown>

### Add Result Persistence

Skrip `002-canonical-results.sql` menambahkan tabel `canonical_results`, `evidence_summaries` terbatas, dan satu counter *material-update* per insiden. Method repositori memuat event dari antrean, menyimpan hasil diagnosis dan bukti, serta mereservasi satu kali izin pembaruan material secara atomik.

!!! success "Expected Result"

    Canonical result dan bukti tersimpan di database sebelum status antrean berubah menjadi *completed*.

**Actual Result:** Pengujian integrasi temporary-SQLite membuktikan penyimpanan hasil, perubahan status antrean menjadi *completed*, dan reservasi pembaruan material berhasil (panggilan pertama `true`, panggilan kedua `false`).

</div>
<div class="procedure-step" markdown>

### Build and Render the Canonical Result

Modul canonical result memvalidasi status pemrosesan serta klasifikasi/confidence, mengurutkan bukti, mencatat sumber bukti yang tidak tersedia, dan melakukan hashing terhadap konten stabil dengan mengecualikan timestamp dinamis. Format Plain Text dan HTML menggunakan 7 seksi terurut yang sama; HTML melakukan escaping terhadap nilai yang tidak tepercaya.

!!! success "Expected Result"

    Input semantik yang sama menghasilkan hash yang identik, dan kedua renderer menjaga urutan pesan yang disetujui tanpa memperkuat asesmen secara sepihak.

**Actual Result:** Seluruh pengujian hash, material-change, penolakan confidence tidak valid, urutan seksi, dan HTML escaping lulus 100%.

</div>
<div class="procedure-step" markdown>

### Run the Single Worker

Worker mengambil satu item antrean, menerapkan batas waktu global 60 detik, mengevaluasi aturan TD-01 s/d TD-08, menyimpan canonical result ke SQLite, lalu menyelesaikan item antrean. Jika terjadi kegagalan, item ditandai sebagai *failed*. Status health/metrics hanya memuat label operasional terbatas.

!!! success "Expected Result"

    Tepat satu item diproses dan tidak ada timer deadline yang tetap aktif setelah pengumpulan bukti selesai.

**Actual Result:** Eksekusi pertama sempat menggantung (*hung*) karena timer `Promise.race` yang kalah tidak dibersihkan. Proses dihentikan paksa, menyisakan container sementara. Worker diperbaiki dengan menambahkan pembersihan timer pada blok `finally`; container yang tertinggal dihapus setelah persetujuan dan pengujian diulang.

</div>
<div class="procedure-step" markdown>

### Verify the Complete Source

```bash
./scripts/validate.sh
bash -n scripts/*.sh
podman run --rm --name tomcat-diagnostic-tn007-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

!!! success "Expected Result"

    Pengujian ingest/isolasi yang ada dan pengujian baru worker/result/renderer seluruhnya lulus hanya menggunakan state sementara.

**Actual Result:** Eksekusi akhir meluluskan 22 pengujian, 0 gagal. Container dihapus secara otomatis.

</div>
</div>

## 📁 Artifact Manifest

| Path | Responsibility |
| --- | --- |
| `migrations/002-canonical-results.sql` | Persistensi result/evidence dan proteksi material update |
| `src/application/diagnostic-worker.js` | Siklus hidup single-worker dan timeout deadline |
| `src/domain/canonical-result.js` | Semantik skema, hash SHA-256, dan deteksi material change |
| `src/application/result-renderer.js` | Perenderan output laporan 7-seksi Text/HTML |
| `src/application/health-metrics.js` | Status liveness, readiness, counter, dan gauge |
| `src/adapters/sqlite-repository.js` | Pembacaan antrean dan persistensi hasil ke SQLite |
| `test/unit/canonical-result.test.js` | Pengujian hash, validasi, urutan render, dan escaping |
| `test/unit/health-metrics.test.js` | Pengujian status operasional tanpa label sensitif |
| `test/integration/diagnostic-worker.test.js` | Siklus transaksi queue-to-result |

## 🧪 Test Scenario Matrix

| Boundary | Scenarios |
| --- | --- |
| Worker | Single claim, persistensi sebelum penyelesaian antrean, pembersihan timer |
| Canonical result | Hash stabil, confidence valid, deteksi material change |
| SQLite | Migration 002, baris evidence, reservasi satu kali material update |
| Renderer | Urutan 7-seksi dan proteksi HTML escaping |
| Health/metrics | Status live/ready, counter/gauge, tanpa label target |
| Regression | Seluruh pengujian TN-005 dan TN-006 tetap lulus |

## 🖥️ Commands Executed

Perintah kronologis ditampilkan pada prosedur implementasi. Perintah pembersihan container yang gagal:

```bash
podman rm -f tomcat-diagnostic-tn007-node
```

Perintah pengujian dijalankan tiga kali: eksekusi pertama dihentikan akibat bug timer, eksekusi kedua meluluskan 21 pengujian, dan eksekusi akhir meluluskan 22 pengujian setelah penambahan cakupan *material-update* dan *health/metrics*. Berkas source dibuat melalui patch workspace, bukan mutasi shell.

Source-control handoff kemudian diotorisasi dan dijalankan:

```bash
git add README.md scripts/validate.sh migrations/002-canonical-results.sql \
  src/adapters/sqlite-repository.js src/application/diagnostic-worker.js \
  src/application/health-metrics.js src/application/result-renderer.js \
  src/domain/canonical-result.js test/integration/diagnostic-worker.test.js \
  test/unit/canonical-result.test.js test/unit/health-metrics.test.js
git diff --cached --check
git commit -m "feat(diagnostic-service): persist and render canonical results"
```

Hasil aktual adalah commit `1ea79fa`. Commit belum dipush pada penutupan TN-007.

## 🧭 Reproduction Guide

```bash
git checkout 1ea79fa
./scripts/validate.sh
podman run --rm --name tomcat-diagnostic-tn007-node --userns=keep-id \
  -v /home/eddywiyatno/git/tomcat-diagnostic-service:/app:Z -w /app \
  localhost/nodejs:24.18.0 npm test
```

Hasil yang diharapkan adalah validasi statis lulus dan 22 pengujian lulus. Gunakan clone/worktree bersih sebelum checkout agar perubahan lokal tidak tertimpa.

## ✅ Verification

| Method | Expected | Actual |
| --- | --- | --- |
| Static validator and Bash syntax | Kontrak source valid | Passed |
| `npm test` in Node.js 24.18.0 | Skenario baru dan regresi lulus | 22 passed |
| Runtime integration | Perilaku HTTP, SMTP, Mailpit | Not verified; excluded |

## 🧾 Outcome

Pemrosesan antrean menjadi canonical result, persistensi database SQLite, proteksi pembaruan material, status operasional, dan perenderan notifikasi telah diimplementasikan dan diuji secara lokal. Pengiriman jaringan dan endpoint service belum diimplementasikan pada tahap ini.

## ⏭️ Next Steps

Mengimplementasikan antarmuka service HTTP/TLS, autentikasi bearer, batasan ukuran request, endpoint health/metrics, dan adapter pengiriman SMTP; kemudian membangun dan menjalankan verifikasi komponen sementara (*disposable component verification*) di bawah otorisasi terpisah.

## 🔗 Related Documentation

- [TN-006](TN-006-implement-target-isolation-evidence-adapters-and-tomcatdown-engine.md)
- [Diagnostic Result Contract](../../diagnostic-mvp/diagnostic-result-and-confidence-contract.md)
- [Notification Contract](../../diagnostic-mvp/notification-and-integration-contract.md)

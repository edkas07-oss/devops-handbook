# TN-005 — Implement Repository AGENTS.md Governance

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Runtime Monitoring Foundation |
| Activity Date | 2026-08-20 |
| Recorded Date | 2026-08-20 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-20 |
| Completion Date | 2026-08-20 |

## 🎯 Objective

Menyediakan repository-level instructions yang membuat AI memahami ownership,
batas perubahan, kebutuhan approval, metode verification, dan kondisi berhenti
sebelum technical implementation Tomcat Monitoring dilanjutkan.

## 🌍 Background

Assessment workflow menemukan bahwa empat repository yang terlibat belum
memiliki instruction file aktif. Tanpa repository-level governance, aturan
generic Tomcat image, derived JMX Exporter image, monitoring integration, dan
dokumentasi hanya bergantung pada konteks percakapan yang dapat berubah antar
session.

Stage 06 telah menetapkan dan memperoleh persetujuan atas sembilan decision
handoff. Implementasi ini menerjemahkan keputusan tersebut menjadi satu root
`AGENTS.md` pada setiap Git repository. Berdasarkan official OpenAI guidance,
file harus diverifikasi dengan fresh Codex session karena instruction chain
dibentuk sekali saat run atau session dimulai.

## 📚 Scope

- Membuat root `AGENTS.md` pada repository `devops-handbook`, `tomcat`,
  `tomcat-jmx-exporter`, dan `tomcat-monitoring`;
- Menggunakan sepuluh section yang sama dengan rule spesifik setiap repository;
- Memastikan global instruction, parent instruction, dan nested override tidak
  diubah atau ditambahkan;
- Menjalankan structural dan fresh-session discovery verification; serta
- Mencatat hasil dan batas evidence implementasi.

Aktivitas ini tidak mengubah source, configuration, artifact, image, runtime,
CI/CD, deployment, Git history, atau external state.

## 📋 Prerequisites

| Prerequisite | Result |
| --- | --- |
| Governance design | Stage 06 selesai dan sembilan decision handoff disetujui. |
| Repository roots | Empat Git root tersedia dan telah diperiksa. |
| Existing instruction state | Tidak ada root, parent, atau nested instruction aktif pada scope repository. |
| Authorization | Project owner mengizinkan Stage 07 untuk membuat dan memverifikasi instruction files. |

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Create the Root Instruction Files** | Membuat satu `AGENTS.md` pada root setiap repository. |
| **Apply the Common and Repository-Specific Rules** | Menerapkan struktur umum dan aturan khusus repository yang telah disetujui. |
| **Verify File Structure and Sensitive Content** | Memeriksa lokasi, heading, ukuran, whitespace, dan sensitive content. |
| **Run Fresh-Session Discovery** | Menjalankan sesi Codex baru dalam mode read-only dari setiap Git root. |
| **Verify Fresh-Session Interpretation** | Memastikan sesi baru memahami purpose, boundary, approval, verification, dan stop condition. |
| **Record the Final Evidence** | Mencatat hasil aktual, evidence, batas verifikasi, dan status akhir TN. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Create the Root Instruction Files

1. Buat satu `AGENTS.md` pada root `devops-handbook`.
2. Buat satu `AGENTS.md` pada root `tomcat`.
3. Buat satu `AGENTS.md` pada root `tomcat-jmx-exporter`.
4. Buat satu `AGENTS.md` pada root `tomcat-monitoring`.

!!! success "Expected Result"

    Tepat satu non-empty root `AGENTS.md` tersedia pada setiap repository dan
    tidak ada parent atau nested override baru.

**Actual Result:** keempat root instruction file selesai dibuat.

**Evidence:** file inventory menemukan tepat empat file pada Git root yang
disetujui.

</div>

<div class="procedure-step" markdown>

### Apply the Common and Repository-Specific Rules

1. Terapkan sepuluh section governance yang sama pada setiap file.
2. Isi purpose, source of truth, boundary, dan verification sesuai ownership
   repository.
3. Bedakan izin edit, build/test, runtime, cleanup, Git, dan external state.

!!! success "Expected Result"

    Seluruh file memiliki struktur yang sama tanpa mencampur tanggung jawab
    repository yang berbeda.

**Actual Result:** seluruh file memiliki sepuluh section yang disetujui dan
aturan spesifik sesuai repository.

**Evidence:** structural check menghasilkan `10/10` heading pada masing-masing
file.

</div>

<div class="procedure-step" markdown>

### Verify File Structure and Sensitive Content

1. Periksa lokasi serta jumlah instruction file.
2. Periksa ukuran, trailing whitespace, dan scoped diff.
3. Cari credential, key material, dan assigned secret.

!!! success "Expected Result"

    File berada pada root yang benar, berukuran di bawah 32 KiB, tidak memiliki
    whitespace error, dan tidak memuat data sensitif.

**Actual Result:** seluruh structural dan sensitive-content check lulus.

**Evidence:** ukuran file tercatat `5,375`, `4,929`, `5,116`, dan `5,530`
bytes; pemeriksaan whitespace dan sensitive value tidak menemukan error.

</div>

<div class="procedure-step" markdown>

### Run Fresh-Session Discovery

1. Mulai proses Codex baru dari setiap Git root.
2. Gunakan mode read-only agar verification tidak mengubah repository.
3. Minta setiap sesi menyebutkan instruction source yang aktif.

!!! success "Expected Result"

    Setiap sesi baru menemukan `AGENTS.md` dari repository tempat sesi dimulai.

**Actual Result:** empat fresh session menemukan root instruction yang sesuai.

**Evidence:** setiap session menyebutkan path `AGENTS.md` repository yang benar.

</div>

<div class="procedure-step" markdown>

### Verify Fresh-Session Interpretation

1. Minta setiap sesi merangkum purpose dan repository boundary.
2. Periksa pemahaman terhadap approval dan verification requirement.
3. Jalankan tabletop review untuk tindakan persistent, destructive, Git,
   external state, dan scope change.

!!! success "Expected Result"

    Sesi baru mempertahankan ownership repository dan meminta authorization
    ketika tindakan melampaui izin read-only atau approved scope.

**Actual Result:** seluruh interpretation dan tabletop review lulus.

**Evidence:** empat ringkasan mempertahankan responsibility dan prohibited
boundary masing-masing serta meminta approval pada tindakan yang diwajibkan.

</div>

<div class="procedure-step" markdown>

### Record the Final Evidence

1. Konsolidasikan structural, discovery, interpretation, dan tabletop result.
2. Catat bahwa MkDocs render belum dapat dijalankan.
3. Pastikan tidak ada source, runtime, Git history, atau external state di luar
   scope yang berubah.

!!! success "Expected Result"

    Hasil akhir membedakan pemeriksaan yang lulus, yang belum diverifikasi, dan
    side effect yang tidak dilakukan.

**Actual Result:** seluruh mandatory governance verification lulus; MkDocs
render tetap `Not verified` karena executable tidak tersedia.

**Evidence:** Verification table dan repository handoff mencatat hasil serta
batasnya.

</div>

</div>

Setiap instruction file menggunakan section `Repository Purpose`, `Source of
Truth`, `Repository Boundaries`, `Working Rules`, `Approval Requirements`,
`Verification`, `Git and External State`, `Secrets and Sensitive Data`,
`Documentation Handoff`, dan `Stop Conditions`.

## 🖥️ Commands Executed

Exact command log tidak tersedia pada record TN-005 yang diterbitkan. Karena
command aktual tidak dapat direkonstruksi dengan aman dari hasil akhir,
normalisasi 2026-08-29 tidak menambahkan command yang tidak memiliki evidence.
Procedure step di atas hanya menggunakan actual result dan evidence yang sudah
tercatat pada Technical Note.

## ✅ Verification

| Method | Expected Result | Actual Result | Evidence |
| --- | --- | --- | --- |
| File inventory | Tepat satu non-empty root `AGENTS.md` pada setiap repository | Passed | Empat file ditemukan tepat pada Git root; tidak ada parent, nested, atau override instruction baru. |
| Content structure check | Setiap file memiliki sepuluh section yang disetujui | Passed | Masing-masing file memiliki hasil `10/10` common contract headings. |
| Size and whitespace check | File di bawah 32 KiB dan tidak memiliki whitespace error | Passed | Ukuran `5,375`, `4,929`, `5,116`, dan `5,530` bytes; trailing-whitespace dan scoped diff checks lulus. |
| Sensitive-content review | Tidak ada secret atau generated TLS material | Passed | Sensitive-value pattern review tidak menemukan credential, key material, atau assigned secret. |
| Fresh-session discovery | Sesi baru menemukan root instruction yang sesuai | Passed | Fresh Codex session dari setiap Git root menyebut `AGENTS.md` repository yang benar. |
| Fresh-session interpretation | Purpose, boundary, approval, verification, dan stop condition dirangkum sesuai repository | Passed | Keempat ringkasan mempertahankan responsibility dan prohibited boundary masing-masing. |
| Tabletop approval review | Read, edit, build/test, runtime, cleanup, Git, external state, dan scope change dibedakan | Passed | Fresh sessions meminta authorization terpisah untuk persistent, destructive, Git, external-state, dan scope-change actions. |
| MkDocs render | Dokumentasi dapat dirender setelah navigation berubah | Not verified | Executable `mkdocs` tidak tersedia dan dependency installation tidak diotorisasi. |
| Side-effect review | Tidak ada perubahan di luar instruction dan documentation scope | Passed | Tidak ada source change, build, component test, runtime operation, cleanup, commit, publication, atau deployment. |

## 🧾 Outcome

Empat repository-level instruction files selesai dibuat dan seluruh mandatory
structural, discovery, interpretation, serta tabletop verification memenuhi
expected result. Governance kini aktif untuk fresh Codex session yang dimulai
dari masing-masing repository root.

Instruction files telah melalui structural dan behavior verification. MkDocs
render belum diverifikasi karena executable tidak tersedia, tetapi kondisi ini
tidak mengurangi hasil instruction discovery dan behavior verification.

## 🎓 Lessons Learned

- Keberadaan `AGENTS.md` tidak cukup menjadi bukti bahwa instruction aktif;
  fresh-session discovery dan interpretation perlu diuji.
- Common section contract dapat menjaga konsistensi tanpa mencampur ownership
  repository yang berbeda.
- Tabletop verification membuat batas authorization dapat diuji tanpa
  menimbulkan build, runtime, destructive, Git, atau external-state side effect.

## 🔄 Source-Control Handoff

Governance repository disimpan terpisah sesuai ownership:

| Repository | Commit |
| --- | --- |
| `devops-handbook` | `651710e` |
| `tomcat` | `e2d2df6` |
| `tomcat-jmx-exporter` | `231cb91` |
| `tomcat-monitoring` | `5cff160` |

## ⏭️ Next Steps

Technical implementation Tomcat Monitoring berikutnya dimulai dalam fresh
session agar repository instructions dimuat sejak awal.

## 🔗 Related Documentation

- [TN-004 — Normalize Runtime Monitoring Foundation Journal](TN-004-normalize-runtime-monitoring-foundation-journal.md)
- [Runtime Monitoring Foundation Engineering Journal](index.md)
- [Stage 06 — Design Repository AGENTS.md Governance](../../../../file/tomcat-monitoring-workflow-review/stage-06-agents-governance-design.md)
- [Stage 07 — Implement Repository AGENTS.md Governance](../../../../file/tomcat-monitoring-workflow-review/stage-07-implement-agents-governance.md)
- [Engineering Journal Standards](../../../../standards/engineering-journal-standards.md)
- [Official OpenAI AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

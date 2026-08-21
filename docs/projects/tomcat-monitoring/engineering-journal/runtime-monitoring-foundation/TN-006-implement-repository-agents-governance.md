# TN-006 — Implement Repository AGENTS.md Governance

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

## Objective

Menyediakan repository-level instructions yang membuat AI memahami ownership,
batas perubahan, kebutuhan approval, metode verification, dan kondisi berhenti
sebelum technical implementation Tomcat Monitoring dilanjutkan.

## Background

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

## Scope

- Membuat root `AGENTS.md` pada repository `devops-handbook`, `tomcat`,
  `tomcat-jmx-exporter`, dan `tomcat-monitoring`;
- Menggunakan sepuluh section yang sama dengan rule spesifik setiap repository;
- Memastikan global instruction, parent instruction, dan nested override tidak
  diubah atau ditambahkan;
- Menjalankan structural dan fresh-session discovery verification; serta
- Mencatat hasil dan batas evidence implementasi.

Aktivitas ini tidak mengubah source, configuration, artifact, image, runtime,
CI/CD, deployment, Git history, atau external state.

## Prerequisites

| Prerequisite | Result |
| --- | --- |
| Governance design | Stage 06 selesai dan sembilan decision handoff disetujui. |
| Repository roots | Empat Git root tersedia dan telah diperiksa. |
| Existing instruction state | Tidak ada root, parent, atau nested instruction aktif pada scope repository. |
| Authorization | Project owner mengizinkan Stage 07 untuk membuat dan memverifikasi instruction files. |

## Implementation Plan

1. Buat satu `AGENTS.md` pada root setiap repository.
2. Terapkan common content contract dan repository-specific rules yang telah
   disetujui.
3. Periksa file placement, structure, size, whitespace, dan sensitive content.
4. Jalankan proses Codex baru dalam mode read-only dari setiap Git root.
5. Pastikan proses baru mengenali instruction source serta merangkum governance
   yang sesuai tanpa melakukan perubahan.
6. Catat actual result dan evidence sebelum menentukan status akhir Technical
   Note.

## Implementation

| Target | Intended Implementation | State |
| --- | --- | --- |
| `devops-handbook/AGENTS.md` | Documentation governance dan current-state handoff boundary | Completed |
| `tomcat/AGENTS.md` | Generic reusable Tomcat runtime boundary | Completed |
| `tomcat-jmx-exporter/AGENTS.md` | Derived image, pinned artifact, dan local component verification boundary | Completed |
| `tomcat-monitoring/AGENTS.md` | Monitoring integration, delivery automation, dan end-to-end boundary | Completed |

Setiap instruction file menggunakan section `Repository Purpose`, `Source of
Truth`, `Repository Boundaries`, `Working Rules`, `Approval Requirements`,
`Verification`, `Git and External State`, `Secrets and Sensitive Data`,
`Documentation Handoff`, dan `Stop Conditions`.

## Verification

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
| Side-effect review | Tidak ada perubahan di luar instruction dan documentation scope | Passed | Tidak ada source change, build, component test, runtime operation, cleanup, commit, push, publication, atau deployment. |

## Outcome

Empat repository-level instruction files selesai dibuat dan seluruh mandatory
structural, discovery, interpretation, serta tabletop verification memenuhi
expected result. Governance kini aktif untuk fresh Codex session yang dimulai
dari masing-masing repository root.

Instruction files masih merupakan local working-tree changes. Commit dan push
tidak dilakukan karena membutuhkan authorization terpisah. MkDocs render belum
diverifikasi karena executable tidak tersedia, tetapi kondisi ini tidak
mengurangi hasil instruction discovery dan behavior verification.

## Lessons Learned

- Keberadaan `AGENTS.md` tidak cukup menjadi bukti bahwa instruction aktif;
  fresh-session discovery dan interpretation perlu diuji.
- Common section contract dapat menjaga konsistensi tanpa mencampur ownership
  repository yang berbeda.
- Tabletop verification membuat batas authorization dapat diuji tanpa
  menimbulkan build, runtime, destructive, Git, atau external-state side effect.

## Next Steps

Project owner mereview Stage 07. Commit atau push hanya dilakukan melalui
authorization terpisah. Technical implementation Tomcat Monitoring berikutnya
dimulai dalam fresh session agar repository instructions dimuat sejak awal.

## Related Documentation

- [TN-005 — Normalize Runtime Monitoring Foundation Journal](TN-005-normalize-runtime-monitoring-foundation-journal.md)
- [Runtime Monitoring Foundation Engineering Journal](index.md)
- [Stage 06 — Design Repository AGENTS.md Governance](../../../../file/tomcat-monitoring-workflow-review/stage-06-agents-governance-design.md)
- [Stage 07 — Implement Repository AGENTS.md Governance](../../../../file/tomcat-monitoring-workflow-review/stage-07-implement-agents-governance.md)
- [Engineering Journal Standards](../../../../standards/engineering-journal-standards.md)
- [Official OpenAI AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

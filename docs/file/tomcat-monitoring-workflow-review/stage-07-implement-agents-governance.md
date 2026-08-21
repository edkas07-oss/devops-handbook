# Stage 07 — Implement Repository AGENTS.md Governance

| Field | Value |
| --- | --- |
| Project | Tomcat Monitoring Workflow Review |
| Review Area | AI repository governance |
| Activity Type | Implementation |
| Record Type | Live |
| Working Mode | Write |
| Status | Completed |
| Activity Date | 2026-08-20 |
| Recorded Date | 2026-08-20 |
| Owner | Project owner |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-20 |
| Reviewed By | Project owner |
| Review Date | 2026-08-20 |
| Completed Date | 2026-08-20 |

## Objective

Menerapkan governance yang disetujui pada Stage 06 menjadi root `AGENTS.md`
untuk empat repository dan membuktikan bahwa setiap instruction file ditemukan
oleh fresh Codex session dari repository yang tepat.

## Background

Stage 06 menghasilkan sembilan decision handoff yang telah disetujui project
owner. Keputusan tersebut menetapkan satu root `AGENTS.md` pada
`devops-handbook`, `tomcat`, `tomcat-jmx-exporter`, dan `tomcat-monitoring`,
tanpa global instruction baru, parent instruction, atau nested override.

Official OpenAI documentation menyatakan bahwa Codex menyusun instruction
chain sekali pada awal run atau session. Oleh karena itu, keberadaan file tidak
cukup menjadi evidence; instruction discovery harus diuji menggunakan proses
Codex baru dari masing-masing Git root.

## Scope

- Membuat satu root `AGENTS.md` pada setiap repository yang disetujui;
- Menerapkan common content contract sepuluh section;
- Menerapkan repository boundary, approval requirements, verification rules,
  secret handling, documentation handoff, dan stop conditions;
- Membuat live Engineering Journal record `TN-006`;
- Memperbarui phase index dan navigation untuk `TN-006`; serta
- Memverifikasi struktur file dan fresh-session instruction discovery.

Stage ini tidak mengubah global instruction, nested instruction, source,
runtime configuration, image, container, volume, pipeline, deployment, Git
commit, atau remote repository.

## Prerequisites

| Prerequisite | Result |
| --- | --- |
| Stage 06 governance design | Sembilan decision handoff telah disetujui project owner. |
| Repository roots | Empat Git root telah ditemukan dan tidak memiliki instruction file aktif. |
| Official discovery behavior | Root-to-working-directory discovery dan once-per-session loading telah dikonfirmasi. |
| Documentation authorization | Pembuatan instruction files dan verification evidence telah disetujui. |

## Implementation Plan

1. Membuat live record Stage 07 dan `TN-006` sebelum instruction files.
2. Membuat empat root `AGENTS.md` dengan common contract yang sama dan aturan
   spesifik sesuai ownership repository.
3. Memeriksa lokasi, ukuran, struktur heading, whitespace, serta kemungkinan
   secret atau nested instruction.
4. Menjalankan fresh Codex session read-only dari setiap repository root.
5. Membandingkan ringkasan fresh session dengan responsibility dan boundary
   yang telah disetujui pada Stage 06.
6. Mencatat actual result serta evidence pada `TN-006` dan working record ini.

## Activity Record

| Activity | State | Evidence |
| --- | --- | --- |
| Official guidance verification | Completed | Official AGENTS.md documentation menjelaskan discovery, precedence, size limit, dan once-per-session loading. |
| Repository instruction inventory | Completed | Tidak ditemukan `AGENTS.md` atau `AGENTS.override.md` pada empat repository. |
| Live journal initialization | Completed | `TN-006` dibuat sebelum repository instruction files. |
| Instruction implementation | Completed | Empat root `AGENTS.md` dibuat sesuai approved common contract dan repository boundary. |
| Structural verification | Completed | Placement, heading, size, layering, whitespace, link target, dan sensitive-value checks lulus. |
| Fresh-session verification | Completed | Empat fresh Codex sessions menemukan instruction source yang benar dan merangkum governance sesuai repository. |
| Tabletop approval verification | Completed | Empat fresh sessions membedakan read, edit, build/test, persistent runtime, destructive cleanup, Git, external state, dan scope change. |
| Project owner review | Completed | Project owner telah mereview dan menyetujui hasil Stage 07. |

## Verification Criteria

| Criterion | Expected Result |
| --- | --- |
| Placement | Tepat satu non-empty `AGENTS.md` berada pada root setiap repository. |
| Layering | Tidak ada global, parent, nested, atau override file baru. |
| Structure | Setiap file memiliki sepuluh section common content contract. |
| Size | Setiap instruction file berada di bawah default combined limit 32 KiB. |
| Safety | Tidak ada secret, credential, private key, certificate, atau token. |
| Discovery | Fresh Codex session menyebut root `AGENTS.md` yang sesuai. |
| Interpretation | Ringkasan purpose, boundary, approval, verification, dan stop condition sesuai repository. |
| Side effect | Tidak ada source change, build, test, runtime operation, commit, push, atau deployment. |

## Verification Result

| Criterion | Actual Result | Evidence |
| --- | --- | --- |
| Placement | Passed | Tepat satu non-empty root `AGENTS.md` ditemukan pada setiap Git root. |
| Layering | Passed | Tidak ada global, parent, nested, atau override instruction baru; global file tetap empty. |
| Structure | Passed | Masing-masing file memiliki `10/10` common contract sections. |
| Size | Passed | Ukuran file berada pada rentang `4,929` sampai `5,530` bytes, di bawah default limit `32 KiB`. |
| Safety and integrity | Passed | Trailing-whitespace, scoped diff, relative-target, dan sensitive-value checks tidak menemukan error. |
| Discovery | Passed | Fresh sessions menyebut root `AGENTS.md` yang sesuai pada keempat repository. |
| Interpretation | Passed | Purpose, boundary, approval, verification, dan stop conditions dirangkum sesuai ownership repository. |
| Tabletop behavior | Passed | Seluruh fresh sessions menjaga pemisahan authorization untuk edit, build/test, runtime, cleanup, commit, push/deploy, dan scope change. |
| MkDocs render | Not verified | Executable `mkdocs` tidak tersedia; dependency tidak dipasang karena tidak termasuk authorization. |
| Side effect | Passed | Tidak ada source change, build, component test, runtime operation, cleanup, commit, push, publication, atau deployment. |

## Outcome

Empat root instruction files telah dibuat dan lulus structural,
fresh-session discovery, interpretation, serta tabletop approval verification.
Repository boundary tidak tercampur dan tindakan yang mengubah persistent atau
external state tetap membutuhkan authorization terpisah.

Project owner telah mereview dan menyetujui hasil implementasi sehingga Stage
07 dinyatakan `Completed`. Seluruh file masih berupa local working-tree
changes; commit dan push tidak dilakukan dan memerlukan instruksi terpisah.

## Related Documentation

- [Stage 06 — Design Repository AGENTS.md Governance](stage-06-agents-governance-design.md)
- [TN-006 — Implement Repository AGENTS.md Governance](../../projects/tomcat-monitoring/engineering-journal/runtime-monitoring-foundation/TN-006-implement-repository-agents-governance.md)
- [Engineering Journal Standards](../../standards/engineering-journal-standards.md)
- [Official OpenAI AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

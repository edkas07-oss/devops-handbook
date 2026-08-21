# Stage 02 — Engineering Journal Standards Design

| Field | Value |
| --- | --- |
| Project | Tomcat Monitoring Workflow Review |
| Review Area | Engineering Journal Standards |
| Activity Type | Discovery and Assessment |
| Working Mode | Read-only assessment; only this working record may be updated |
| Status | Completed |
| Started | 2026-08-20 |
| Completed | 2026-08-20 |
| Record Type | Live |
| Approved By | Project owner |
| Approval Date | 2026-08-20 |

## Purpose

Menerjemahkan lifecycle kerja yang disetujui pada Stage 01 menjadi rancangan
perubahan Engineering Journal Standards. Rancangan harus membuat Engineering
Journal dapat digunakan sejak brainstorming sampai activity closure tanpa
memaksa seluruh jenis aktivitas menggunakan section yang sama.

Stage ini belum mengubah Engineering Journal Standards, Engineering Journal
Tomcat Monitoring, project documentation, ADR, atau source repository.

## Approved Input

Rancangan menggunakan keputusan Stage 01 berikut sebagai baseline:

- Lifecycle kerja sepuluh tahap;
- Empat approval gate;
- Engineering Journal sebagai rekaman utama perjalanan project;
- Project documentation sebagai hasil konsolidasi current state;
- ADR sebagai sumber keputusan signifikan;
- How-to dan Troubleshooting sebagai sumber prosedur reusable;
- `AGENTS.md` sebagai governance layer cara AI bekerja; serta
- Penggunaan base template dengan conditional sections.

Referensi:

- [Stage 01 — Review and Agree the Working Lifecycle](stage-01-working-lifecycle.md)
- [Engineering Journal Standards](../../standards/engineering-journal-standards.md)
- [Engineering Principles](../../standards/engineering-principles.md)
- [Documentation Standards](../../standards/documentation-standards.md)
- [Writing Standards](../../standards/writing-standards.md)

## Current Standard Assessment

| Area | Current Condition | Required Direction |
| --- | --- | --- |
| Journal starting point | Pre-implementation disebutkan, tetapi brainstorming belum menjadi aktivitas resmi. | Nyatakan bahwa jurnal dimulai sejak kebutuhan dan brainstorming project. |
| Documentation output mapping | Kebutuhan project diarahkan langsung ke root project `index.md`. | Arahkan raw need dan discussion ke jurnal; project documentation menerima hasil yang sudah dikonsolidasikan. |
| Technical Note template | Satu struktur memaksa `Implementation` dan `Verification` pada seluruh Technical Note. | Gunakan base sections dan conditional sections berdasarkan activity type. |
| Information classification | Fact, assumption, hypothesis, alternative, risk, open question, dan decision belum dibedakan. | Definisikan information type dan lifecycle state masing-masing. |
| Record timing | Satu field `Date` tidak membedakan aktivitas aktual dan waktu pencatatan. | Tambahkan live/reconstructed record serta activity dan recorded dates. |
| Approval evidence | Approval dan authorized scope belum dicatat secara konsisten. | Definisikan cara minimal mencatat decision, implementation, scope-change, dan closure approval. |
| AI governance | Tidak ada boundary yang menjelaskan hubungan jurnal dengan `AGENTS.md`. | Tegaskan bahwa `AGENTS.md` mengatur perilaku AI; jurnal hanya mencatat aktivitas dan authorization yang relevan. |
| Activity completion | `Completed` berorientasi pada implementasi dan verification. | Gunakan completion criteria berdasarkan activity type. |
| Procedure pattern | Sequential procedure tersedia dan berguna. | Pertahankan, tetapi hanya wajib ketika aktivitas memang memiliki langkah eksekusi berurutan. |
| Verification model | Method, expected result, actual result, dan evidence sudah dibedakan. | Pertahankan untuk aktivitas yang menghasilkan klaim teknis atau perubahan sistem. |

## Proposed Standard Model

Engineering Journal Standards tetap menjadi satu dokumen standar. Tidak perlu
membuat standar terpisah untuk brainstorming atau pre-implementation.

Struktur konseptual yang diusulkan:

```text
Engineering Journal Standards
├── Purpose and documentation boundaries
├── Engineering activity lifecycle
├── Activity and information model
│   ├── Activity types
│   ├── Information types and states
│   ├── Record types and dates
│   └── Approval and authorization records
├── Documentation structure and naming
├── Activity status
├── Document templates
│   ├── Project journal index
│   ├── Phase index
│   ├── Technical Note base template
│   └── Conditional sections by activity type
├── Implementation procedure pattern
├── Verification and evidence
├── Repository workflow
└── Review checklist
```

## Proposed Activity Types

Activity type menjelaskan sifat pekerjaan dan menentukan conditional sections.
Activity type bukan nama phase dan tidak menggantikan status Technical Note.

| Activity Type | Used For | Typical Output |
| --- | --- | --- |
| Discovery and Assessment | Kebutuhan awal, brainstorming, architecture input, assessment, dan readiness review. | Problem statement, findings, alternatives, assumptions, risks, open questions, dan recommendation. |
| Implementation | Perubahan source, configuration, automation, atau artifact. | Verified change dan implementation evidence. |
| Experiment | Prototype atau pengujian hypothesis sebelum menjadi keputusan atau implementasi final. | Supported atau rejected hypothesis beserta evidence. |
| Deployment or Migration | Perubahan pada runtime target, provisioning, release, atau pemindahan workload. | Deployment result, rollback status, dan runtime verification. |
| Verification or Audit | Pemeriksaan independen terhadap kondisi, compliance, artifact, atau implementasi yang sudah ada. | Findings dan verification conclusion. |
| Troubleshooting or Recovery | Investigasi gangguan, root cause analysis, resolution, atau service recovery. | Confirmed cause, applied resolution, dan re-verification. |
| Documentation Consolidation | Konsolidasi hasil engineering menjadi current-state documentation, How-to, atau Troubleshooting. | Updated documentation dan source mapping. |

Implementation planning tidak menjadi activity type terpisah. Planning dicatat
pada Technical Note `Implementation`, `Deployment or Migration`, atau activity
lain yang akan dieksekusi. Technical Note tetap berstatus `Planned` sampai
Implementation Gate disetujui.

Keputusan signifikan tidak memerlukan activity type `Decision` tersendiri.
Pembahasan keputusan berada pada activity yang menghasilkan keputusan, sedangkan
keputusan final dan konsekuensinya dicatat pada ADR.

## Proposed Information Model

Information type membedakan sifat informasi. Information state menjelaskan
perkembangannya. Keduanya tidak boleh digabung menjadi satu istilah.

| Information Type | Meaning | Recommended States |
| --- | --- | --- |
| Fact | Kondisi atau hasil yang benar-benar diamati. | Observed, Verified, Disputed |
| Assumption | Pernyataan yang digunakan sementara tetapi belum dibuktikan. | Open, Verified, Invalidated |
| Hypothesis | Penjelasan atau dugaan yang harus diuji. | Proposed, Tested, Supported, Rejected |
| Alternative | Pilihan yang dipertimbangkan sebelum keputusan. | Proposed, Assessed, Selected, Rejected |
| Risk | Kondisi yang dapat menghambat atau merugikan hasil. | Open, Mitigated, Accepted, Closed |
| Open Question | Informasi yang masih membutuhkan jawaban. | Open, Answered, Deferred |
| Decision | Pilihan yang telah melalui decision gate. | Proposed, Accepted, Superseded |

Tidak seluruh Technical Note harus membuat tabel untuk semua information type.
Gunakan hanya jenis yang benar-benar muncul pada aktivitas. Informasi yang
belum pasti tidak boleh ditulis sebagai fact atau accepted decision.

## Proposed Record Types and Dates

| Record Type | Usage |
| --- | --- |
| Live | Technical Note dibuat sebelum atau selama aktivitas dan diperbarui berdasarkan perjalanan aktual. |
| Reconstructed | Technical Note dibuat setelah aktivitas selesai berdasarkan source, evidence, dan ingatan yang masih tersedia. |

Reconstructed record wajib:

- Menyatakan bahwa catatan direkonstruksi;
- Mencatat activity date dan recorded date secara terpisah;
- Menjelaskan evidence yang digunakan;
- Menyatakan bagian yang tidak dapat diverifikasi; dan
- Tidak menulis ulang histori seolah-olah catatan dibuat secara live.

## Proposed Technical Note Metadata

### Required metadata

| Field | Purpose |
| --- | --- |
| Status | Menunjukkan lifecycle aktivitas. |
| Activity Type | Menentukan karakter aktivitas dan conditional sections. |
| Record Type | Membedakan live dan reconstructed record. |
| Project | Menunjukkan project owner aktivitas. |
| Phase | Menunjukkan workstream tempat aktivitas berada. |
| Activity Date | Tanggal aktivitas dimulai atau dilakukan. |
| Recorded Date | Tanggal Technical Note pertama kali dibuat. |
| Owner | Pihak yang bertanggung jawab terhadap hasil aktivitas. |

### Conditional authorization metadata

Metadata berikut digunakan ketika aktivitas melibatkan perubahan:

| Field | Purpose |
| --- | --- |
| Working Mode | `Read-only`, `Write`, atau `Mixed`. |
| Authorization Status | `Not Required`, `Pending`, atau `Approved`. |
| Approved By | Pihak yang menyetujui implementation plan dan scope. |
| Approval Date | Tanggal authorization diberikan. |

Authorized scope tidak ditulis sebagai kalimat panjang di metadata. Scope yang
disetujui tetap dijelaskan pada section `Scope`; metadata hanya mencatat status
authorization dan pemberi persetujuan.

## Proposed Approval Record

| Gate | Minimum Record |
| --- | --- |
| Documentation Gate | Persetujuan membuat atau memperbarui jurnal dicatat pada communication context atau metadata working record. |
| Decision Gate | Accepted decision dicatat pada ADR atau bagian decision activity yang menautkan ADR. |
| Implementation Gate | Authorization status, approver, approval date, dan approved scope tersedia sebelum perubahan dimulai. |
| Scope Change Gate | Perubahan scope dicatat secara append-oriented dengan alasan, dampak, approver, dan tanggal. |
| Activity Closure | Status akhir, closure result, outstanding item, dan residual risk dicatat. |

Standar tidak perlu menyimpan transkrip persetujuan. Catat keputusan approval
secara ringkas dan dapat ditelusuri.

## Proposed Base Template

Seluruh Technical Note menggunakan metadata dan base sections berikut:

```text
Objective
Background
Scope
Activity Record
Outcome
Related Documentation
```

`Activity Record` bukan heading literal yang wajib digunakan. Bagian tersebut
diisi oleh conditional sections sesuai activity type. Sebagai contoh, activity
Implementation menggunakan `Prerequisites`, `Implementation`, dan
`Verification`, sedangkan Discovery menggunakan `Findings`, `Alternatives`, dan
`Open Questions`.

`Objective`, `Background`, `Scope`, `Outcome`, dan `Related Documentation`
menjadi base sections. Gunakan `N/A` hanya jika section wajib benar-benar tidak
memiliki isi dan berikan alasan singkat.

## Proposed Conditional Sections

| Activity Type | Conditional Sections |
| --- | --- |
| Discovery and Assessment | Inputs, Findings, Assumptions, Alternatives, Risks, Open Questions, Recommendation, Decision Handoff |
| Implementation | Prerequisites, Execution Decision, Architecture when needed, Implementation Plan, Implementation, Verification, Troubleshooting, Scope Changes |
| Experiment | Prerequisites, Hypothesis, Experiment Setup, Method, Expected Result, Actual Result, Conclusion |
| Deployment or Migration | Prerequisites, Execution Decision, Change Plan, Rollback Plan, Deployment or Migration, Verification, Rollback Result, Scope Changes |
| Verification or Audit | Criteria, Method, Evidence, Findings, Exceptions, Conclusion |
| Troubleshooting or Recovery | Symptom, Impact, Investigation, Hypotheses, Root Cause, Resolution or Recovery, Re-verification |
| Documentation Consolidation | Source Inputs, Documentation Mapping, Changes, Review Result |

`Lessons Learned`, `Next Steps`, dan `Notes` tetap optional untuk seluruh
activity type.

## Proposed Completion Criteria

| Activity Type | Completed When |
| --- | --- |
| Discovery and Assessment | Findings diklasifikasikan, open items terlihat, dan recommendation atau handoff tersedia. |
| Implementation | Approved scope selesai dan mandatory verification memenuhi expected result. |
| Experiment | Method dijalankan dan conclusion didukung actual result. |
| Deployment or Migration | Target state atau rollback state telah diverifikasi. |
| Verification or Audit | Seluruh criteria memiliki result atau exception yang dinyatakan. |
| Troubleshooting or Recovery | Root cause atau batas investigasi dinyatakan, resolution dicatat, dan re-verification dilakukan jika perubahan diterapkan. |
| Documentation Consolidation | Target documentation diperbarui dan source mapping direview. |

Status `Completed` tidak berarti seluruh project atau phase selesai. Status
hanya berlaku pada objective Technical Note tersebut.

## Proposed Changes by Existing Standard Section

| Existing Section | Proposed Action |
| --- | --- |
| Overview | Perkuat posisi jurnal sebagai rekaman utama perjalanan project sejak kebutuhan awal. |
| Objectives | Tambahkan tujuan menjaga traceability brainstorming, decision, authorization, dan evidence. |
| Scope | Tambahkan discovery, brainstorming, assessment, decision handoff, dan documentation consolidation. |
| Design Principles | Pertahankan; tambahkan curated record dan transparent reconstruction. |
| Project Initiation and Pre-Implementation Flow | Ganti menjadi Engineering Activity Lifecycle berdasarkan Stage 01. |
| Documentation Output Mapping | Koreksi agar raw discussion masuk jurnal dan project documentation menerima consolidated current state. |
| Implementation Entry Criteria | Pertahankan sebagai Implementation Gate checklist dengan penyesuaian authorized scope. |
| Documentation Structure | Pertahankan. |
| File Naming Convention | Pertahankan. |
| Status | Pertahankan status utama; perjelas completion criteria per activity type. |
| Document Templates | Ubah menjadi base template dan conditional section matrix. |
| Sequential Procedures | Pertahankan untuk aktivitas yang benar-benar berurutan. |
| Verification | Pertahankan Method, Expected Result, Actual Result, dan Evidence untuk aktivitas yang memerlukannya. |
| Repository Workflow | Perbarui agar mengikuti lifecycle, approval gate, dan documentation consolidation. |
| Best Practices | Tambahkan live recording, information classification, dan no fabricated chronology. |
| Review Checklist | Pisahkan base checks dan activity-specific checks. |

Section baru yang diperlukan:

- Activity Types;
- Information Types and States;
- Record Types and Dates; serta
- Approval and Authorization Records.

## Boundary with AGENTS.md

Engineering Journal Standards tidak menentukan command permission, sandbox,
branch policy, push policy, atau tool-specific behavior AI. Aturan tersebut
menjadi tanggung jawab `AGENTS.md`.

Engineering Journal hanya mencatat:

- Working mode aktivitas;
- Authorization status;
- Approved scope;
- Scope changes yang disetujui; dan
- Evidence hasil pekerjaan.

Pendekatan ini mencegah duplikasi antara governance repository dan histori
engineering.

## Design Risks

| Risk | Mitigation |
| --- | --- |
| Metadata terlalu banyak dan memperlambat aktivitas kecil. | Authorization metadata dibuat conditional untuk aktivitas yang mengubah state. |
| Activity types terlalu spesifik dan sulit dipilih. | Gunakan tujuh tipe berbasis tujuan aktivitas, bukan berdasarkan teknologi. |
| Discovery journal berubah menjadi transkrip chat. | Wajibkan curated record dan larang penyalinan percakapan tanpa seleksi. |
| Informasi status menjadi administratif. | Catat hanya information type yang relevan dan gunakan tabel ketika jumlahnya lebih dari sedikit. |
| Jurnal menduplikasi ADR atau project documentation. | Gunakan documentation mapping dan hyperlink sebagai source-of-truth boundary. |
| Reconstructed note dianggap live record. | Wajibkan record type, activity date, recorded date, dan reconstruction disclosure. |

## Review Points

Sebelum Stage 02 ditutup, project owner perlu menyetujui atau mengoreksi:

1. Tujuh proposed activity types.
2. Base sections `Objective`, `Background`, `Scope`, `Outcome`, dan
   `Related Documentation`.
3. Conditional sections untuk setiap activity type.
4. Information types dan state masing-masing.
5. Metadata wajib dan metadata authorization yang conditional.
6. Penggunaan `Live` dan `Reconstructed` record.
7. Cara mencatat empat approval gate.
8. Boundary antara Engineering Journal Standards dan `AGENTS.md`.
9. Daftar section standar yang akan ditambah, diubah, dan dipertahankan.

## Next Step

Menerapkan rancangan yang telah disetujui ke Engineering Journal Standards.
Setelah standar diperbarui dan diverifikasi, Engineering Journal Tomcat
Monitoring dinilai ulang menggunakan standar tersebut.

## Closure Result

Stage 02 dinyatakan `Completed` setelah project owner menyetujui seluruh sembilan
review point berikut:

1. Tujuh activity types;
2. Base sections Technical Note;
3. Conditional sections berdasarkan activity type;
4. Information types dan lifecycle state;
5. Metadata wajib dan conditional authorization metadata;
6. Penggunaan record type `Live` dan `Reconstructed`;
7. Cara pencatatan empat approval gate;
8. Boundary antara Engineering Journal Standards dan `AGENTS.md`; serta
9. Daftar section standar yang dipertahankan, diubah, dan ditambahkan.

Persetujuan ini menetapkan rancangan Stage 02 sebagai baseline untuk perubahan
Engineering Journal Standards pada tahap berikutnya. Tidak ada perubahan pada
Engineering Journal Standards, Engineering Journal Tomcat Monitoring, project
documentation, ADR, atau source repository selama Stage 02.

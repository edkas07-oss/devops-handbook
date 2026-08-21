# Repository Instructions

## Repository Purpose

Repository ini adalah source of truth untuk DevOps Engineering Handbook. Isinya
mencakup standards, Architecture Decision Records (ADR), reusable How-to dan
Troubleshooting, Engineering Journal, serta dokumentasi current-state setiap
project. Repository ini tidak memiliki runtime source atau deployment state
project yang didokumentasikan.

## Source of Truth

- Baca seluruh standard yang relevan di `docs/standards/` sebelum mengubah
  dokumentasi yang diaturnya.
- Gunakan `docs/standards/documentation-standards.md` untuk struktur dokumentasi
  project, `docs/standards/engineering-journal-standards.md` untuk activity
  record, dan `docs/standards/writing-standards.md` untuk gaya penulisan.
- Gunakan `docs/adr/` untuk keputusan arsitektur signifikan dan `docs/how-to/`
  untuk prosedur lintas project yang dapat digunakan kembali.
- Perlakukan source, configuration, dan runtime repository project terkait
  sebagai evidence; jangan menggantikannya dengan asumsi dari dokumentasi.

## Repository Boundaries

- Engineering Journal menyimpan perjalanan, konteks, authorization, aktivitas,
  dan evidence secara kronologis.
- ADR menyimpan keputusan signifikan, alasan, alternatif, dan konsekuensinya.
- Project pages menyampaikan ringkasan portfolio serta arsitektur dan kondisi
  yang berlaku saat ini.
- How-to dan Troubleshooting menyimpan prosedur reusable, bukan histori project.
- Jangan menyimpan runtime source, generated artifact, credential, certificate,
  private key, token, atau deployment state di repository ini.

## Working Rules

- Mulai dengan memeriksa instruction, standard, navigation, related pages, Git
  status, dan perubahan pengguna yang beririsan dengan task.
- Kerjakan hanya file dan section dalam explicit scope. Jangan merapikan atau
  menormalisasi area lain tanpa persetujuan.
- Pertahankan seluruh unrelated dirty-worktree changes dan jangan mengembalikan
  perubahan yang tidak dibuat dalam aktivitas saat ini.
- Gunakan `rg` atau `rg --files` untuk pencarian dan `apply_patch` untuk edit
  manual.
- Buat atau perbarui Engineering Journal secara live ketika aktivitas project
  memerlukan record; jangan menyalin raw conversation sebagai dokumentasi.
- Jika fakta, keputusan, atau current state belum dapat dibuktikan, tandai
  ketidakpastian dan jangan menuliskannya sebagai hasil terverifikasi.

## Approval Requirements

- Read-only inspection yang relevan dapat dilakukan tanpa approval tambahan.
- Pembuatan atau perubahan dokumentasi hanya boleh dilakukan dalam approved
  documentation scope.
- Perubahan di luar approved scope harus berhenti pada Scope Change Gate.
- Jangan memasang dependency, mengubah toolchain, menjalankan publication,
  commit, atau push tanpa authorization terpisah.
- Izin mengedit tidak memberikan izin otomatis untuk commit, push, publish,
  deployment, atau perubahan pada repository lain.

## Verification

- Review struktur heading, navigation, relative links, fenced blocks, dan
  trailing whitespace pada seluruh file yang diubah.
- Gunakan `git diff --check` dan review diff terbatas pada target aktivitas.
- Jalankan MkDocs validation yang tersedia untuk perubahan yang memengaruhi
  render atau navigation. Gunakan output directory sementara bila memungkinkan.
- Jika `mkdocs` atau dependency lain tidak tersedia, catat `Not verified` dan
  jangan memasangnya tanpa approval.
- Nyatakan `Completed` atau `Verified` hanya jika expected result, actual result,
  dan evidence yang diwajibkan dapat dibedakan dan seluruhnya mendukung klaim.

## Git and External State

- Jangan menjalankan `git commit`, `git push`, membuat tag atau release, atau
  menerbitkan site tanpa instruksi eksplisit.
- Jangan menghapus, reset, checkout, atau menimpa perubahan pengguna.
- Dokumentasikan hasil berdasarkan working tree aktual; jangan menganggap file
  untracked sudah dipublikasikan.
- Perlakukan perubahan remote repository, documentation site, registry, dan
  runtime environment sebagai external-state action dengan approval terpisah.

## Secrets and Sensitive Data

- Jangan membaca atau menampilkan secret yang tidak dibutuhkan task.
- Jangan menyimpan password, token, private key, session cookie, credential,
  generated certificate, atau nilai environment sensitif di dokumentasi, Git,
  output command, screenshot, maupun evidence.
- Gunakan placeholder seperti `<username>`, `<host>`, dan `<secret>`, serta
  redaksi output minimum yang tetap membuktikan hasil.

## Documentation Handoff

- Catat aktivitas dan evidence pada Engineering Journal yang sesuai.
- Buat atau tautkan ADR ketika keputusan signifikan telah accepted.
- Konsolidasikan hasil yang benar-benar berlaku ke project pages.
- Promosikan prosedur atau penyelesaian masalah yang dapat digunakan kembali ke
  How-to atau Troubleshooting tanpa menduplikasi source of truth.
- Perbarui phase index, project journal index, dan navigation hanya ketika
  perubahan aktivitas memang membutuhkannya.

## Stop Conditions

Berhenti dan minta direction jika repository boundary atau source of truth
tidak jelas, required decision belum accepted, scope perlu diperluas, perubahan
pengguna beririsan dan tidak aman dipertahankan, secret berisiko terekspos,
verification membutuhkan dependency atau akses yang belum disetujui, atau
evidence tidak cukup untuk mendukung status yang diminta.

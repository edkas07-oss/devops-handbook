# TM-ADR-0013

| Property | Value |
| --- | --- |
| **ADR ID** | TM-ADR-0013 |
| **Title** | Use Node.js 24 ESM and Isolated Built-In SQLite for Diagnostic Service |
| **Project** | Tomcat Monitoring |
| **Section** | Diagnostic Service Implementation Architecture |
| **Status** | Accepted |
| **Date** | 2026-08-31 |

---

## 🔍 Overview

Diagnostic Service menggunakan Node.js `24.18.0` LTS dengan plain ESM
JavaScript dan built-in `node:sqlite` yang diisolasi melalui satu adapter.

## 🌍 Context

Diagnostic Service memerlukan HTTPS webhook, strict input validation, durable
SQLite acceptance sebelum HTTP `202`, satu asynchronous worker, deterministic
rule tests, SMTP rendering, health endpoints, dan bounded evidence adapters.
Repository reusable `nodejs` telah menyediakan pinned non-root runtime,
signal-forwarding entrypoint, npm, dan working directory `/app` tanpa memilih
framework atau application dependency.

Pilihan implementation yang dinilai adalah Node.js dengan built-in SQLite,
Node.js dengan third-party native SQLite binding, Python standard library, dan
Go dengan SQLite driver. Built-in `node:sqlite` pada Node.js `24.18.0` masih
berstatus release candidate sehingga compatibility risk harus terlihat dan
dibatasi.

## ⚖️ Decision

Gunakan Node.js `24.18.0` LTS dengan plain ESM JavaScript, built-in HTTPS, dan
stable `node:test`. Jangan menambahkan web framework, ORM, queue broker,
template engine, atau general-purpose host-control dependency pada baseline.

Gunakan built-in `node:sqlite` untuk pilot dengan ketentuan:

- runtime dan application base identity dipin secara exact sebelum build;
- seluruh SQLite access berada di belakang satu adapter;
- transaction acceptance tetap singkat dan tidak mencakup evidence collection
  atau SMTP delivery;
- migration, WAL, commit-before-`202`, restart deduplication, retention,
  capacity, dan recovery behavior memiliki mandatory tests; serta
- perubahan compatibility pada Node.js atau `node:sqlite` memerlukan contract
  review sebelum runtime pin diperbarui.

Gunakan versioned JSON Schema, runtime validation, JSDoc, module boundary, dan
fixture tests. JSON Schema validator dan SMTP client dipilih serta dipin saat
implementation TN pertama yang membutuhkannya.

## 🏛️ Architecture

```text
Reusable Node.js runtime
        |
        v
Diagnostic Service ESM application
        |
        +--> server adapter: HTTPS, authentication, schema, health, metrics
        +--> application layer: accepted-work queue and use cases
        +--> domain layer: deterministic evidence, rule, and result model
        +--> adapters: SQLite, Prometheus, bounded files/spool, and SMTP
```

SQLite implementation detail tidak boleh bocor ke HTTP handler, rule engine,
renderer, atau evidence adapters lain. Pemisahan ini menjadi compatibility
boundary jika pilot kemudian memerlukan binding atau runtime berbeda.

## 💡 Rationale

Node.js menggunakan reusable runtime yang sudah tersedia dan dapat memenuhi
network serta test interface tanpa framework tambahan. Plain ESM menghindari
compile stage sebelum behavior pilot terbukti. Built-in SQLite meminimalkan
native dependency dan Alpine build toolchain dibanding third-party binding.

Python dan Go tetap viable, tetapi keduanya memperkenalkan runtime ownership
dan lifecycle baru tanpa reusable local contract. Risiko release-candidate
`node:sqlite` diterima untuk pilot karena exact pin, adapter isolation, single
writer, bounded workload, dan mandatory persistence tests membatasi dampaknya.

## ⚠️ Consequences

- Repository `tomcat-diagnostic-service` bergantung pada exact reusable Node.js
  runtime identity yang harus tersedia sebelum image build.
- Runtime upgrade tidak boleh dilakukan hanya karena tag LTS baru tersedia;
  SQLite compatibility dan contract tests harus direview ulang.
- Synchronous SQLite API dapat menahan event loop, sehingga transaction harus
  pendek dan seluruh downstream I/O berada di luar transaction.
- Validator schema dan SMTP client tetap menjadi exact-pinned application
  dependencies; pilihan versinya belum diterima oleh ADR ini.
- Source, dependency, image, dan runtime tetap belum diimplementasikan atau
  diverifikasi oleh keputusan ini.

## 📌 Status

**Accepted — implemented and verified in devops-lab.**

## 📅 Date

**2026-08-31**

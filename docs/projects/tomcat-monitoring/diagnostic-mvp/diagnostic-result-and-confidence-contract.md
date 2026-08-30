# Diagnostic Result and Confidence Contract

## 🔍 Overview

Satu canonical result version `1` menjadi sumber tunggal bagi persistence,
plain-text email, HTML email, dan future integration projection. Renderer tidak
boleh memperkuat atau menafsirkan ulang assessment.

## 📦 Required Structure

Canonical result memuat:

- `schema_version`, `diagnostic_id`, `rule_id`, dan `rule_version`;
- alert fingerprint, lifecycle status, start/end time, dan event key;
- canonical target identity dan runtime generation bila tersedia;
- processing status dan timing;
- normalized evidence, observations, unavailable sources, dan contradictions;
- primary assessment, contributing factors, dan recommended actions;
- delivery-independent result hash dan redaction metadata.

Processing status adalah `completed`, `partially_completed`, `failed`,
`unsupported`, `skipped`, atau `resolved_without_previous_firing`. Status ini
berbeda dari assessment classification.

## ⚖️ Assessment and Confidence

Classification yang diizinkan adalah `confirmed_cause`, `probable_cause`,
`possible_cause`, `contributing_factor`, `symptom`, `not_supported`, dan
`undetermined`.

| Classification | Allowed confidence |
| --- | --- |
| `confirmed_cause` | `high` only |
| `probable_cause` | `medium` or `high` |
| `possible_cause` | `low` or `medium` |
| `contributing_factor` | `low`, `medium`, or `high` |
| `symptom` | `low`, `medium`, or `high` |
| `not_supported` | no confidence |
| `undetermined` | no confidence |

Confidence berasal dari branch decision table `TomcatDown`, bukan numeric
score atau penjumlahan evidence generik. Confirmed cause membutuhkan direct
evidence dan temporal correlation. Missing evidence tidak menjadi negative
proof.

## 🔁 Determinism and Material Change

Normalized evidence yang sama dengan `rule_version` yang sama harus
menghasilkan canonical result yang sama. Result hash mengecualikan volatile
delivery timestamp.

Perubahan disebut material hanya jika classification, confidence, processing
status, primary assessment, atau evidence availability berubah. Pilot
mengizinkan maksimum satu material-update notification per incident.

## 🔐 Safety

Result hanya menyimpan bounded sanitized excerpts. Credential, token, cookie,
request body, complete crash report, dan unbounded stack trace dilarang.
Recommended action bersifat instruksi operator dan tidak pernah dieksekusi.

## 📌 Status

**Accepted contract — schema and validator not implemented.**

# PS-ADR-0007

| Property | Value |
|----------|-------|
| **ADR ID** | PS-ADR-0007 |
| **Title** | Use Pipeline as Code |
| **Project** | Personal Site |
| **Section** | Automation |
| **Status** | Accepted |
| **Date** | 2026-07-29 |

---

## 🔍 Overview

Project **Personal Site** menggunakan pendekatan **Pipeline as Code**, yaitu seluruh proses automation didefinisikan menggunakan file **Jenkinsfile** yang disimpan bersama source code project.

Pendekatan ini menjadikan pipeline sebagai bagian dari implementasi project sehingga dapat dikelola menggunakan version control dan direproduksi pada environment lain.

---

## 🌍 Context

Project **Personal Site** membutuhkan proses **Build**, **Deployment**, dan **Validation** yang konsisten.

Terdapat dua pendekatan yang dapat digunakan:

- Mendefinisikan pipeline melalui **Jenkins Web UI**.
- Mendefinisikan pipeline menggunakan **Jenkinsfile** (*Pipeline as Code*).

Konfigurasi melalui Web UI tidak menjadi bagian dari source code sehingga perubahan lebih sulit dilacak dan direproduksi.

---

## ⚖️ Decision

Project **Personal Site** menggunakan **Pipeline as Code**.

Seluruh pipeline akan didefinisikan pada file **Jenkinsfile** yang disimpan di root repository project dan dikelola menggunakan Git.

---

## 🏛️ Architecture

```text
Git Repository
        │
        ▼
Jenkins Pipeline
        │
        ▼
Jenkinsfile
        │
        ▼
Build
        │
        ▼
Deployment
        │
        ▼
Validation
```

Pipeline menjadi bagian dari repository sehingga seluruh proses automation dapat dikelola bersama source code.

---

## 💡 Rationale

Keputusan ini dipilih karena:

- Mendukung praktik **DevOps** dan **Pipeline as Code**.
- Pipeline memiliki histori perubahan melalui Git.
- Mempermudah review perubahan.
- Dapat direproduksi pada environment lain.
- Mengurangi konfigurasi manual pada Jenkins.

---

## ⚠️ Consequences

### Positive

- Pipeline terdokumentasi bersama source code.
- Mendukung version control.
- Memudahkan backup dan recovery.
- Konsisten antar environment.
- Pipeline dapat dikembangkan secara bertahap.

### Trade-offs

- Membutuhkan pemahaman Jenkins Pipeline.
- Perubahan pipeline harus melalui proses commit.
- Kesalahan pada Jenkinsfile dapat menyebabkan pipeline gagal dijalankan.

---

## 📌 Status

**Accepted**

---

## 📅 Date

**2026-07-29**
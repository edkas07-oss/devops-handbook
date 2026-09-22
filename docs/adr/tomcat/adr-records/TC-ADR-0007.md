# TC-ADR-0007

| Property | Value |
| --- | --- |
| **ADR ID** | TC-ADR-0007 |
| **Title** | Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler and Day-1/Day-2 Decoupling |
| **Project** | Apache Tomcat Enterprise |
| **Section** | GitOps and Continuous Deployment |
| **Status** | Accepted |
| **Date** | 2026-09-22 |

---

## 🔍 Overview

Apache Tomcat Enterprise mengadopsi standar **Pure Pull-Based GitOps** (sesuai standar CNCF OpenGitOps) untuk pengelolaan armada kontainer Tomcat di lingkungan multi-host VM/bare-metal. Arsitektur ini memisahkan secara tegas antara **Day-1 One-Time Host Provisioning** dengan **Day-2 Ongoing Autonomous Reconciliation**. Repositori Git berperan sebagai *Single Source of Truth* tunggal (`tomcat-spec.yaml`), dan setiap host target menjalankan biner operator **`tcctl gitops sync`** secara otonom via `systemd --user timer` tanpa membutuhkan koneksi SSH masuk (*zero inbound SSH push*) untuk siklus rilis harian.

---

## 🌍 Context

Pengelolaan deployment Apache Tomcat pada puluhan server di perusahaan enterprise menghadapi dilema arsitektur:

1. **Kelemahan Model Push Tradisional (CI/Ansible to Target)**:
   - Server CI (Jenkins) atau Ansible Controller harus memegang kredensial SSH superuser ke seluruh server produksi. Jika server CI disusupi, seluruh server produksi rentan terhadap eksploitasi massal.
   - Model push tidak memiliki mekanisme deteksi deviasi (*drift detection*) berkelanjutan. Jika seseorang mengubah konfigurasi server secara manual, drift tersebut tidak terdeteksi hingga jadwal deployment berikutnya.
2. **Kebutuhan Standar Modern (Pure GitOps)**:
   - GitOps murni mensyaratkan arsitektur berbasis tarikan (*pull-based*), di mana target runtime secara otonom memantau Git dan menyelaraskan diri (*self-healing*) jika terjadi perbedaan.
3. **Pemisahan Batas CI dan CD**:
   - CI berfokus pada pembangunan perangkat lunak dan kendali mutu (`tcctl hardening audit`, Trivy scan, push image ke registry).
   - CD berfokus murni pada rekonsiliasi kondisi deklaratif dari Git ke runtime.

---

## ⚖️ Decision

Project memutuskan untuk mengadopsi **Pure Pull-Based GitOps via `tcctl`** dengan ketentuan:

1. **Pemisahan Tegas Day-1 vs Day-2**:
   - **Day-1 (One-Time Provisioning)**: Pemasangan biner `tcctl` dan inisialisasi awal ke VM yang sudah ada menggunakan otomasi bootstrap satu kali. Setelah selesai, akses bootstrap langsung ditutup permanen.
   - **Day-2 (Pure GitOps Lifecycle)**: Seluruh pembaruan image, konfigurasi XML, dan sertifikat SSL selanjutnya dikendalikan murni melalui Git commit dan ditarik secara otonom oleh `tcctl` di host target.
2. **Manifest Deklaratif Tunggal (`tomcat-spec.yaml`)**:
   - Seluruh spesifikasi armada (nama instance, image tag, port binding, JMX exporter, dan volume) didefinisikan dalam format YAML deklaratif di Git repository (`tomcat-fleet-config`).
3. **Autonomous Local Reconciler (`tcctl gitops sync`)**:
   - Dijalankan di setiap host target menggunakan `systemd --user timer` (berjalan sebagai unprivileged user `tomcat` dengan `loginctl enable-linger`).
   - Melakukan polling berkala (misal tiap 60 detik) dengan *randomized jitter* untuk mencegah beban lonjakan (*thundering herd*) pada server Git.
4. **Drift Detection & Continuous Self-Healing**:
   - `tcctl` secara terus-menerus membandingkan *desired state* di Git dengan *actual state* di Podman.
   - Jika konfigurasi lokal diubah secara tidak sah di server, `tcctl` secara otomatis mengembalikannya ke kondisi yang tertera di Git.
5. **Zero Inbound SSH Port Requirement**:
   - Host produksi tidak perlu membuka port SSH inbound untuk keperluan deployment aplikasi. Komunikasi hanya berlangsung satu arah secara keluar (*outbound HTTPS/SSH*) ke server Git.

---

## 🏛️ Architecture & GitOps Flow

```mermaid
flowchart TD
    subgraph SOT ["GitOps Single Source of Truth (Gitea)"]
        SPEC["tomcat-spec.yaml\n(Desired State)"]
        XML["conf/ (Hardened XML Templates)"]
    end

    subgraph TARGET_HOST ["Autonomous Target Host (Host Reconciler)"]
        TIMER["systemd --user timer\n(tcctl-gitops.timer)"]
        
        subgraph RECONCILER ["tcctl gitops sync"]
            FETCH["1. Git Fetch / Pull"]
            AUDIT["2. Pre-Flight CIS Audit"]
            DIFF["3. Drift Detection Engine"]
            ROLLOUT["4. Staging Zero-Downtime Swap"]
        end

        subgraph RUNTIME ["Podman Rootless Runtime"]
            CONTAINER["Tomcat Container (<name>)"]
            VOLUMES[("Runtime Volumes :ro,Z")]
        end

        TIMER --> FETCH
        FETCH -.->|Outbound Pull| SOT
        FETCH --> AUDIT --> DIFF
        DIFF -->|Drift / Update Detected| ROLLOUT
        ROLLOUT ==>|Atomic Reconcile| CONTAINER
        ROLLOUT ==>|Sync Volume Data| VOLUMES
    end
```

---

## 🌟 Consequences

### Positive
- **Keamanan Tertinggi (No Inbound SSH)**: Meniadakan kebutuhan penyimpanan kredensial produksi di CI server.
- **Self-Healing Otomatis**: Menjamin kepatuhan konfigurasi runtime terhadap Git 24/7 tanpa celah manipulasi lokal.
- **Kepatuhan CNCF OpenGitOps**: Selaras dengan prinsip standar industri modern.

### Negative / Trade-offs
- Target host membutuhkan akses jaringan outbound (port HTTPS/SSH) ke repositori Git pusat.
- Memerlukan konfigurasi *deploy key* read-only pada masing-masing host.

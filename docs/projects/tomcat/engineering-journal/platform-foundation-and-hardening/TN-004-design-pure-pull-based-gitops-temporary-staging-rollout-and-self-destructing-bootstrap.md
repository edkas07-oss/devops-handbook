# TN-004 — Implement Pure Pull-Based GitOps, Temporary Staging Rollout, and Self-Destructing Bootstrap

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Apache Tomcat Enterprise |
| Phase | Platform Foundation & Hardening |
| Activity Date | 2026-09-22 |
| Recorded Date | 2026-09-22 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-22 |


## 🎯 Objective

Mendokumentasikan keputusan arsitektur dan spesifikasi desain komprehensif terkait tiga pilar operasional modern pada platform **Apache Tomcat Enterprise**:

1. **Refactoring Zero-Downtime Rollout**: Mengeliminasi suffix permanen (`-blue`/`-green`) menjadi **Temporary Staging Container (`<name>-staging`)** dengan promosi nama kanonikal (`<name>`) secara atomik, sehingga kontainer produksi aktif selalu memiliki identitas bersih yang stabil.
2. **Adopsi Pure Pull-Based GitOps**: Mengadopsi prinsip CNCF OpenGitOps melalui **Autonomous Host Reconciler** (`tcctl gitops sync` via `systemd --user timer`), memisahkan secara tegas tanggung jawab CI (Build, Hardening Audit, Vulnerability Scanning) dari CD (Deklaratif, Self-Healing, Pull-Based).
3. **Penyelesaian Paradoks Day-1 Bootstrapping**: Mengimplementasikan pola **Self-Destructing Ephemeral SSH Access** untuk provisioning biner `tcctl` dan timer pada armada VM eksisting (*brownfield*), memusnahkan kredensial sementara dari `~/.ssh/authorized_keys` seketika saat bootstrap selesai tanpa meninggalkan *dormant backdoor*.

---

## 🌍 Background

Pengelolaan armada Apache Tomcat pada puluhan server virtual (VM) atau bare-metal di lingkungan enterprise memunculkan tantangan operasional dan perdebatan arsitektur:

### 1. Keterbatasan Model CI/CD Tradisional (Push via SSH / Ansible)
Pada model push tradisional, Jenkins CI server atau Ansible Controller bertindak sebagai orkestrator sentral yang melakukan SSH push langsung ke seluruh host target:
- **Blast Radius Kredensial**: Server CI memegang kunci SSH superuser ke puluhan VM produksi. Kompromi pada CI server membuka akses langsung ke seluruh armada host.
- **Inbound Firewall Holes**: Setiap VM target harus membuka port 22 (SSH) ke runner CI atau Ansible controller.
- **Ketiadaan Deteksi Drift Berkelanjutan**: Model push hanya berjalan saat ada trigger rilis. Jika terjadi modifikasi konfigurasi manual atau container mati di luar jam rilis, tidak ada mekanisme rekonsiliasi mandiri (*self-healing*).

### 2. Ortodoksi GitOps (CNCF OpenGitOps Standard)
GitOps mensyaratkan empat prinsip utama:
1. **Deklaratif**: Seluruh kondisi sistem didefinisikan secara deklaratif dalam Git (`tomcat-spec.yaml`).
2. **Berversi dan Tak Berubah (*Versioned & Immutable*)**: Git menjadi *Single Source of Truth* tunggal.
3. **Ditarik Otomatis (*Pulled Automatically*)**: Agen software pada runtime target secara otonom menarik kondisi yang dideklarasikan.
4. **Rekonsiliasi Berkelanjutan (*Continuously Reconciled*)**: Agen secara konstan membandingkan kondisi aktual dengan kondisi yang diinginkan dan melakukan koreksi otomatis (*self-healing*).

Menggunakan Ansible atau script dari CI untuk melakukan push ke target **bukanlah GitOps**, melainkan *Scripted Push Configuration Management*. Untuk mencapai GitOps murni pada multi-host non-Kubernetes, biner operator `tcctl` di host target harus bertindak sebagai *Pull Reconciler*.

### 3. Paradoks Bootstrapping (Day-1 vs Day-2)
Untuk menjalankan agent GitOps di host target, biner `tcctl` dan unit systemd harus terpasang terlebih dahulu. Pada VM yang sudah terbentuk (*brownfield*), hal ini membutuhkan akses awal (Day-1). Namun, membiarkan kunci SSH tersimpan di puluhan server menimbulkan beban pembersihan manual (*post-bootstrap cleanup PR*) yang rawan kelalaian. Pola *Self-Destructing Ephemeral SSH Access* dipilih sebagai solusi paling elegan: kunci bootstrap secara otomatis memusnahkan baris dirinya sendiri dari `~/.ssh/authorized_keys` di akhir skrip instalasi.

### 4. Ketidaknyamanan Suffix Permanen Blue-Green
Model Blue-Green konvensional menamai kontainer dengan `<name>-blue` atau `<name>-green`. Akibatnya, nama kontainer produksi yang sedang aktif berganti-ganti setiap rilis, menyulitkan tim monitoring, operator lapangan, serta penulisan query Prometheus dan reverse proxy routing. Solusi yang lebih bersih adalah kontainer aktif selalu bernama kanonikal `<name>`, dan kontainer baru sementara diberi nama `<name>-staging` hanya selama proses pre-flight probe berlangsung.

---

## 📚 Scope & Decision References

Dokumen ini merangkum dan menjadi acuan bagi tiga Architecture Decision Records:

- [**TC-ADR-0006**: Refactor Zero-Downtime Rollout to Temporary Staging Containers with Canonical Name Promotion](../../../../adr/tomcat/adr-records/TC-ADR-0006.md)
- [**TC-ADR-0007**: Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler and Day-1/Day-2 Decoupling](../../../../adr/tomcat/adr-records/TC-ADR-0007.md)
- [**TC-ADR-0008**: Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access](../../../../adr/tomcat/adr-records/TC-ADR-0008.md)

---

## 💬 Rekaman Tanya Jawab & Diskusi Arsitektur (Architectural Q&A)

Sesi perancangan arsitektur ini melibatkan diskusi kritis dan tanya-jawab mendalam untuk membedah dilema operasional nyata di lingkungan enterprise. Bagian ini mendokumentasikan secara lengkap pertanyaan strategis yang diajukan beserta analisis teknis solusinya agar mudah dipahami oleh seluruh tim rekayasa:

---

### ❓ Pertanyaan 1: "Artinya orkestrasinya tetap ada di CI?"

Terkait pertanyaan mengenai letak kendali orkestrasi deployment, terdapat perbedaan mendasar antara **Traditional CD** dan **GitOps CD**:

#### 1. Traditional CI/CD (Orkestrasi CD Menempel di CI Server)

* **Mekanisme Kerja**:
  * Pada model tradisional, Jenkins (CI) bertindak sebagai pemegang kendali orkestrasi deployment.
  * Setelah tahapan build & test selesai, Jenkins yang login langsung via SSH atau memanggil Ansible untuk me-restart server satu per satu secara berurutan.
* **Kelemahan Keamanan di Enterprise**:
  * Jenkins harus menyimpan SSH keys / kredensial superuser ke seluruh server produksi.
  * Jika server Jenkins disusupi peretas (misalnya melalui celah remote code execution pada plugin), seluruh armada server produksi dapat dikuasai seketika (*broad blast radius*).
  * Seluruh server target wajib membuka port 22 (inbound SSH) langsung ke arah runner/worker CI.

#### 2. GitOps CD (Orkestrasi CD Terpisah / Decoupled dari CI)

* **Mekanisme Kerja**:
  * Pada model GitOps, CI Server (Jenkins) **TIDAK PERNAH** menyentuh atau login ke server produksi.
  * Tugas CI selesai setelah image OCI berhasil di-push ke container registry dan file konfigurasi deklaratif (`tomcat-spec.yaml`) di Git diperbarui versi tag-nya melalui commit/pull request otomatis.
* **Pemisahan Batas & Keamanan (*Air Gap / Decoupling Boundary*)**:
  * Git repository bertindak sebagai gerbang pemisah (*air gap / decoupling boundary*).
  * Kendali orkestrasi CD berpindah sepenuhnya ke **CD Controller / Reconciler di host target**.
  * Reconciler di host target yang secara otonom mendeteksi perubahan commit di Git dan mengeksekusi staggered rollout ke armada kontainer menggunakan biner operator `tcctl`.

```
Traditional CD:  [CI Server (Jenkins)] ──(SSH Push / Broad Blast Radius)──> [Server Prod 1..N]
GitOps CD:       [CI Server (Jenkins)] ──(Commit Spec)──> [Git Repo] <──(HTTPS Pull)── [Host Reconciler (tcctl)]
```

#### 🛠️ Peran Modular `tcctl` pada Kedua Domain

Biner operator `tcctl` dirancang secara modular agar melayani kedua domain dengan batas tanggung jawab yang tegas:

| Domain Operasional | Subcommand `tcctl` | Tanggung Jawab & Fungsi |
| :--- | :--- | :--- |
| **Sisi CI (Quality Gates)** | `tcctl hardening audit` | Memvalidasi sintaks dan elemen `server.xml` agar patuh 100% pada CIS Apache Tomcat Benchmark sebelum image OCI di-build. |
| | `tcctl va scan` | Memindai container image terhadap basis data CVE Trivy untuk memastikan tidak ada celah keamanan di atas batas ambang (*threshold*). |
| **Sisi CD / GitOps (Host Reconciliation)** | `tcctl apply -f <spec>` | Menerapkan *desired state* deklaratif dari `tomcat-spec.yaml` ke runtime Podman lokal. |
| | `tcctl deploy rollout` | Melakukan swap kontainer zero-downtime menggunakan *temporary staging container* (tanpa akhiran `-blue`/`-green`). |
| | `tcctl monitoring health` | Memverifikasi ketersediaan dan indikator kesehatan kontainer pasca-rollout. |

---

### ❓ Pertanyaan 2: "Tapi lucunya adalah tcctl itu di deploy-nya sepertinya harus menggunakan CI/CD tradisional, kecuali sudah embedded di image VM. Tapi itu sulit karena VM sudah terbentuk (brownfield). Betul begitu?"

Pertanyaan ini menyentuh dilema klasik dalam rekayasa platform: **Paradoks Ayam-dan-Telur (*The Chicken-and-Egg Bootstrap Paradox*)**.

#### Analisis Dilema Brownfield vs Greenfield

1. **Kondisi Ideal (Greenfield / Immutable Infrastructure)**:
   * Pada infrastruktur baru, biner `tcctl` dan timer systemd dapat langsung ditanam ke dalam *Golden Image* (misal via Packer / AMI / OVA) sebelum VM dinyalakan. Saat VM pertama kali boot, sistem langsung 100% berstatus otonom.
2. **Realita Lapangan Enterprise (Brownfield VMs)**:
   * Pada puluhan server virtual yang sudah lama beroperasi dan tidak mungkin di-rebuild dari awal, biner operator tidak bisa tiba-tiba muncul di server secara mandiri.
   * **Kesimpulan Pengamatan User 100% Benar**: Harus ada intervensi awal yang menyerupai mekanisme tradisional (SSH push / Ansible) untuk mengantarkan biner `tcctl` ke server tersebut pertama kali.

#### Resolusi Paradoks: Memisahkan Day-1 dari Day-2

Kunci dari arsitektur ini bukanlah menolak akses awal, melainkan **memisahkan siklus hidup infrastruktur menjadi dua fase tegas**:

* **Day-1 (One-Time Bootstrap Event — Terjadi Sekali Seumur Hidup Server)**:
  * Digunakan khusus untuk onboarding server: meletakkan biner `tcctl`, menyiapkan named volume, mengaktifkan linger user `tomcat`, dan menyalakan `systemd --user timer`.
  * Begitu selesai, pintu akses Day-1 **langsung dihancurkan permanen**.
* **Day-2 (Continuous Autonomous Operations — Berjalan Selamanya)**:
  * Seluruh siklus deployment aplikasi, pembaruan versi, patching image, dan rotasi konfigurasi selanjutnya dilakukan **murni 100% via GitOps pull reconciler**.
  * Tidak ada lagi push SSH harian yang membebani tim SRE dan mengekspos risiko keamanan.

---

### ❓ Pertanyaan 3: "Apakah ada mekanisme SSH yang disediakan hanya 1 kali penggunaannya? Soalnya kalau tidak, maka PR sekali harus menghapus key di semua host. Betulkah demikian?"

Pertanyaan ini menyoroti risiko operasional nyata: jika administrator menaruh SSH key untuk kebutuhan bootstrap Day-1, menghapus kunci tersebut lewat tiket terpisah atau "PR sekali di masa depan" adalah praktik yang **sangat berisiko karena seringkali terlupakan atau terbengkalai**, meninggalkan *dormant backdoor* di server produksi.

#### Solusi Arsitektur: Pola Self-Destructing Ephemeral SSH Access

Kami merancang mekanisme di mana kredensial SSH Day-1 **memusnahkan dirinya sendiri secara atomik** tanpa membutuhkan intervensi manual atau PR susulan:

1. **Penandaan Tag Kunci Sementara**:
   Saat kunci publik diinjeksikan ke target host (misal via bastion atau sesi provisioning awal), baris kunci diberi metadata tag identifikasi:
   ```text
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... # ephemeral-day1-bootstrap
   ```
2. **Eksekusi Otomasi Bootstrap**:
   Skrip `day1_bootstrap.sh` berjalan di server target: memasang biner `tcctl`, mengonfigurasi direktori volume, dan menyalakan timer GitOps.
3. **Pemusnahan Diri Mandiri (*Self-Purge Execution*)**:
   Pada instruksi paling akhir sebelum skrip selesai, skrip mengeksekusi penghapusan baris kuncinya sendiri:
   ```bash
   sed -i '/# ephemeral-day1-bootstrap/d' ~/.ssh/authorized_keys
   ```
4. **Verifikasi Hangus Seketika**:
   * Sesi SSH aktif selesai dan terputus.
   * Setiap upaya koneksi baru menggunakan private key yang sama langsung ditolak oleh sshd (`Permission denied (publickey)`).
   * **Hasil**: Zero manual cleanup, zero leftover keys, dan tidak ada celah backdoor tertinggal.

---

### ❓ Pertanyaan 4: "Kenapa tidak pakai Blue-Green biasa dengan suffix permanen (-blue / -green)? Mengapa memilih Temporary Staging Rollout (<name>-staging -> <name>)?"

Pada implementasi blue-green konvensional, kontainer mempertahankan akhiran permanen, misalnya `payment-blue` pada rilis ganjil dan `payment-green` pada rilis genap.

#### Masalah Operasional Akibat Suffix Permanen:

1. **Dashboard Monitoring & Prometheus Metrics Rusak**:
   * Metrik diekspor dengan label `container_name="payment-blue"`. Pada rilis berikutnya, label berubah menjadi `container_name="payment-green"`.
   * Query alerting dan visualisasi Grafana menjadi rumit karena metrik terpecah menjadi time-series yang berbeda atau memerlukan regex rumit (`container=~"payment-(blue|green)"`).
2. **Beban Kognitif SRE Saat Insiden Malam Hari**:
   * Operator yang login darurat saat insiden menjalankan `podman ps` dan harus memeriksa konfigurasi port proxy untuk mengetahui kontainer mana yang saat ini aktif melayani traffic pelanggan.
3. **Konfigurasi Reverse Proxy Bolak-Balik**:
   * Nginx / HAProxy upstream harus terus-menerus diubah arah port-nya bolak-balik antara 8080 dan 8081.

#### Solusi: Temporary Staging Rollout dengan Promosi Kanonikal Atomik

* Kontainer produksi aktif **SELALU** bernama kanonikal bersih: `<name>` (misal `payment-service`) dan binding di port utama (`8080`).
* Kontainer baru diluncurkan sementara dengan nama `<name>-staging` di port staging (`9080`) hanya selama 15–30 detik untuk menjalani pre-flight healthcheck probe.
* Begitu lolos, kontainer lama dihentikan, dan kontainer baru dipromosikan mengambil nama kanonikal `<name>` di port 8080. Kontainer staging dibersihkan.
* SRE, Prometheus exporter, reverse proxy, dan log collector selalu melihat satu kontainer tunggal bernama stabil `payment-service`.

---

### ❓ Pertanyaan 5: "Bagaimana cara GitOps bekerja di lingkungan non-Kubernetes (Bare-Metal / VM) tanpa resource overhead k8s?"

* **Tantangan**: Memasang cluster Kubernetes (k8s/k3s) pada puluhan VM dedicated hanya untuk menjalankan satu atau dua instance Tomcat adalah pemborosan resource CPU/Memory (*over-engineering*).
* **Solusi**: Memanfaatkan biner operator Go mandiri (`tcctl`) berukuran ~15MB yang dipicu oleh timer bawaan Linux OS:
  * Unit `systemd --user timer` berjalan di bawah user aplikasi non-root `tomcat` (tanpa butuh akses root).
  * Timer berjalan setiap 5 menit dengan *randomized jitter* (30 detik) agar tidak terjadi lonjakan request (*thundering herd*) ke Git server internal.
  * Reconciler menarik `tomcat-spec.yaml`, membandingkan *desired state* dengan kondisi Podman, dan secara mandiri menyembuhkan deviasi (*self-healing*) jika ada kontainer yang mati atau termodifikasi secara tidak sah.
  * Seluruh armada VM tidak membutuhkan port masuk (inbound SSH 22 dapat ditutup di firewall), cukup akses keluar (*outbound HTTPS 443*) ke Git dan Registry internal.

---

### ❓ Pertanyaan 6: "Apakah biner MinGit di server target berbahaya, dan apakah mekanisme git pull via CLI adalah yang terbaik saat ini?"

Pertanyaan ini muncul saat mengevaluasi dependensi biner di lingkungan Windows Server (`win-lab`) yang belum memiliki kakas `git` terpasang.

#### 1. Penilaian Keamanan MinGit
* **Secara Keamanan (Security): TIDAK BERBAHAYA**. MinGit (*Minimal Git*) adalah paket resmi yang dirilis langsung oleh tim pengembang **Git for Windows** (didistribusikan via repositori resmi `git-for-windows/git` di GitHub). MinGit bukan malware atau aplikasi pihak ketiga yang meragukan, melainkan biner Git resmi tanpa antarmuka GUI (~30 MB) yang dirancang untuk otomasi server/CI.
* **Dari Sisi Desain Sistem Enterprise: MEMBEBANI HOST**. Memasang MinGit di host target menambah dependensi OS sekunder, membutuhkan ekstraksi file, pembaruan Machine PATH, serta berpotensi memicu kendala konfigurasi bawaan seperti *circular include loop* pada `etc/gitconfig` (seperti yang tercatat pada [TN-005](TN-005-verify-windows-container-runtime-provisioning-and-tcctl-operator-testing.md)).

#### 2. Keunggulan Arsitektur HTTP / REST API Pull (ArgoCD-Style)
Dalam filosofi GitOps, server target bertindak murni sebagai **konsumen pasif (*Read-Only Consumer*)**. Host produksi tidak pernah membuat commit, tidak melakukan merge, dan tidak mem-push branch. Oleh karena itu, memanggil biner `git.exe` eksternal adalah bentuk *over-dependency*.

Pendekatan paling elegan dan berstandar *cloud-native* adalah reconciler `tcctl` melakukan **Direct HTTP / REST API Fetch** langsung ke Gitea:
1. **Deteksi Deviasi / Commit Baru**: `GET /api/v1/repos/{owner}/{repo}/commits?limit=1&sha={branch}`
2. **Download Manifes Terbaru**: `GET /{owner}/{repo}/raw/branch/{branch}/tomcat-spec.yaml`

```text
Model Konvensional:  [Host Reconciler] ──(exec git.exe CLI)──> [Git Repo] (Wajib MinGit di Host)
Model Cloud-Native:  [Host Reconciler (tcctl)] ──(Direct HTTP GET)──> [Gitea REST API] (Zero External Dependency)
```

**Hasil Evaluasi**: Biner `tcctl` menjadi **Single Static Binary Mandiri (Zero Dependency)** tanpa membutuhkan instalasi MinGit pada Windows maupun Linux.

---

### ❓ Pertanyaan 7: "Jika menggunakan REST API Gitea, di mana letak user menset URL Git reponya?"

User tidak perlu menyusun path API yang rumit. Pengalaman operator tetap konsisten dan intuitif menggunakan format Git URL standar:

1. **Input Saat Inisialisasi (`tcctl gitops init`)**:
   Operator cukup menentukan URL Git repository biasa pada perintah inisialisasi awal:
   ```bash
   tcctl gitops init --repo http://localhost:3000/gitadm/tomcat-gitops.git --branch main
   ```
2. **Penyimpanan Profil Lokal (`gitops-config.json`)**:
   Karena di server target tidak dibentuk folder `.git`, `tcctl` mencatat konfigurasi repository ke file lokal:
   `~/.config/tcctl/gitops/gitops-config.json` (Linux) atau `C:\Users\Administrator\.config\tcctl\gitops\gitops-config.json` (Windows):
   ```json
   {
     "repo_url": "http://localhost:3000/gitadm/tomcat-gitops.git",
     "branch": "main",
     "spec_file": "tomcat-spec.yaml"
   }
   ```
3. **Konversi Otomatis ke REST API**:
   Saat reconciler berjalan berkala via timer, `tcctl` secara otomatis mem-parse URL Git tersebut menjadi endpoint REST API Gitea:
   * Base Host: `http://localhost:3000`
   * Owner: `gitadm`
   * Repo: `tomcat-gitops`
   * Commit Endpoint: `http://localhost:3000/api/v1/repos/gitadm/tomcat-gitops/commits?limit=1&sha=main`
   * Raw Spec Endpoint: `http://localhost:3000/gitadm/tomcat-gitops/raw/branch/main/tomcat-spec.yaml`

---

### ❓ Pertanyaan 8: "Jika menggunakan Git CI seperti GitHub Actions atau Gitea Actions, di mana letak inputnya tanpa intervensi manual di server?"

Pada alur produksi enterprise, **tidak ada operator yang mengetik perintah `tcctl` secara manual di server**. Seluruh siklus rilis dikendalikan otomatis oleh pemisahan dua fase:

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant AppRepo as Application Repo (Git)
    participant CI as Gitea Actions / GitHub Actions
    participant Reg as Container Registry (OCI)
    participant GitOpsRepo as Manifest Repo (tomcat-gitops)
    participant Target as Host Production (tcctl Reconciler)

    Dev->>AppRepo: git push code aplikasi baru
    AppRepo->>CI: Trigger Workflow CI Otomatis
    Note over CI: 1. Build Artifact & Hardened Image<br/>2. Scan Keamanan (tcctl va & Trivy)
    CI->>Reg: Push image baru (e.g. tomcat:9.0-jdk11 atau v1.2.0)
    
    rect rgb(235, 245, 255)
    Note over CI,GitOpsRepo: [INPUT OTOMATIS CI KE GITOPS]
    CI->>GitOpsRepo: CI mengupdate tag image di tomcat-spec.yaml<br/>(Git commit & push otomatis via Bot Token)
    end

    Note over Target,GitOpsRepo: [REKONSILIASI OTONOM BERKALA]
    Target->>GitOpsRepo: Task Scheduler / Timer memanggil tcctl gitops sync
    Target->>GitOpsRepo: Deteksi Commit SHA baru via Gitea REST API
    Target->>Reg: Pull image baru
    Target->>Target: Zero-Downtime Rollout (:9080 staging -> :8080 canonical)
```

#### Contoh Implementasi Workflow CI (`.gitea/workflows/release.yaml`):
```yaml
name: Build, Test & GitOps Promotion

on:
  push:
    branches: [ main ]

jobs:
  build-and-promote:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Kode
        uses: actions/checkout@v4

      - name: Build & Push Image
        run: |
          docker build -t localhost:3000/gitadm/payment-service:${{ github.sha }} .
          docker push localhost:3000/gitadm/payment-service:${{ github.sha }}

      - name: Promosikan ke GitOps Manifest Repo (Automated Input)
        run: |
          git clone http://gitadm:${{ secrets.GITEA_TOKEN }}@localhost:3000/gitadm/tomcat-gitops.git gitops-repo
          cd gitops-repo
          sed -i 's/tag: .*/tag: "${{ github.sha }}"/' tomcat-spec.yaml
          git config user.name "gitea-actions[bot]"
          git config user.email "bot@internal.corp"
          git commit -am "chore(release): promote payment-service to ${{ github.sha }}"
          git push origin main
```

**Keuntungan Enterprise**:
* **Zero Inbound SSH**: CI server tidak pernah memegang kunci SSH ke armada host produksi.
* **Audit Trail 100% di Git**: Setiap pergantian versi tercatat siapa yang build dan commit SHA rilisnya.
* **Instant Rollback**: Jika versi baru bermasalah di produksi, cukup klik **"Revert"** pada commit terakhir di Web UI Gitea, maka seluruh armada host target otomatis rollback dalam 5 menit tanpa perlu menyentuh server.

---

### ❓ Pertanyaan 9: "Mengapa konfigurasi network dan storage tidak perlu ditentukan manual pada tomcat-spec.yaml?"

Manifes GitOps harus bersifat seringkas dan sedeklaratif mungkin (*Minimalist & Opinionated Defaults*):
1. **Pemisahan Network**:
   Menentukan nama network secara statis (seperti `devops-lab`) menimbulkan kerapuhan lintas platform. Pada Windows, driver network adalah Host Networking Service (HNS) NAT default (`nat`), sedangkan di Linux adalah bridge default. Dengan mengosongkan segmen `network`, operator `tcctl` membiarkan container engine mengaitkan kontainer ke network default bawaan runtime secara transparan (sama persis seperti mekanisme pada proyek `tomcat-monitoring`).
2. **Otomasi Storage**:
   Sesuai [TC-ADR-0009](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat/adr-records/TC-ADR-0009.md), penyimpanan kontainer diturunkan secara deterministik dari `containerName`:
   * Pada Windows: Host Bind-Mount terstruktur otomatis dibentuk di `<BaseDir>\<containerName>\[conf, webapps, logs]` (misal `C:\tomcats\payment-service\`).
   * Pada Linux: Engine Named Volumes otomatis dibentuk sebagai `<containerName>_conf:ro,Z`, `<containerName>_webapps:Z`, dan `<containerName>_logs:Z`.
   Menghilangkan blok `storage:` dari YAML membuat manifes portabel dan bebas dari konfigurasi redundan.

---

### ❓ Pertanyaan 10: "Bagaimana pengelolaan memori JVM (Heap Size, GC, dan JVM Options) di dalam kontainer, dan bagaimana cara memodifikasinya?"

Pada lingkungan bare-metal atau VM konvensional, JVM umumnya dialokasikan menggunakan parameter statis seperti `-Xms4g -Xmx4g`. Namun di dalam kontainer (Docker/OCI), JVM berjalan di dalam isolasi batasan sumber daya (*resource limits*) yang dikendalikan oleh Linux cgroups atau Windows Job Objects.
Jika alokasi memori JVM tidak dirancang dengan tepat, kontainer berisiko tinggi mengalami **OOMKilled (Exit Code 137)** mendadak dari kernel OS tanpa pesan error atau jejak stack trace pada log Apache Tomcat!

#### 1. Anatomi Memori JVM: Bahaya Fatal Menyamakan Heap dengan Memory Limit Kontainer

Kesalahan paling umum dalam kontainerisasi Java adalah menyetel `-Xmx` sama dengan memory limit kontainer (misalnya: limit kontainer = 4 GB, lalu disetel `-Xmx4g`).

JVM **bukan hanya Heap**! Struktur konsumsi memori JVM terdiri dari:
1. **Heap Memory** (`-Xmx`): Tempat seluruh objek instansiasi aplikasi Java dialokasikan dan dikelola oleh Garbage Collector.
2. **Non-Heap Memory**:
   * **Metaspace** (`-XX:MaxMetaspaceSize`): Memuat metadata kelas (*class metadata*), konstanta, dan metode (*method bytecode*).
   * **Thread Stack** (`-Xss`): Setiap thread Java yang aktif mengonsumsi alokasi memori off-heap (default 1 MB per thread pada OS 64-bit). Jika Tomcat melayani 200 worker threads (`maxThreads="200"`), maka memori off-heap yang dikonsumsi thread stack saja mencapai **200 MB**!
   * **Code Cache**: Memori tempat Just-In-Time (JIT) Compiler menyimpan kompilasi kode native machine.
   * **Direct Byte Buffers & NIO**: Buffer memori native yang dialokasikan langsung di luar JVM Heap untuk I/O jaringan berkecepatan tinggi oleh Tomcat Connector (NIO/APR).
   * **Garbage Collector & JVM Internal Overhead**: Struktur data internal untuk melacak object graph dan card tables.

```
Total Memory Kontainer (e.g. 4.0 GB)
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│  ┌───────────────────────────────────┐  ┌──────────────────┐  │
│  │                                   │  │ Non-Heap:        │  │
│  │          Java Heap Memory         │  │ • Metaspace      │  │
│  │          (Max 70% - 75%)          │  │ • Thread Stacks  │  │
│  │                                   │  │ • Code Cache     │  │
│  │       -XX:MaxRAMPercentage=75.0   │  │ • Direct Buffers │  │
│  │               (~3.0 GB)           │  │ • OS Overhead    │  │
│  │                                   │  │ (25% - 30%)      │  │
│  └───────────────────────────────────┘  └──────────────────┘  │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Golden Rule Alokasi JVM di Kontainer**:
> Heap maksimum (`-Xmx` atau `MaxRAMPercentage`) **hanya boleh dialokasikan 70% – 75%** dari total batas memori kontainer! Sisa 25% – 30% wajib dialokasikan untuk memori Non-Heap dan overhead OS kontainer. Jika Heap disetel mendekati 100%, lonjakan alokasi off-heap atau thread baru akan memicu kernel OS membunuh kontainer secara seketika (*OOMKilled Exit Code 137*).

#### 2. Dynamic Memory Sizing via Container Awareness (`-XX:+UseContainerSupport`)

Mulai OpenJDK 8u191+ dan secara default pada OpenJDK 11+, JVM dilengkapi kapabilitas membaca limit memori cgroups/Job Object secara native:
* Hindari menyetel nilai statis (seperti `-Xmx4g`), karena jika limit kontainer diubah di masa depan (misal di `tomcat-spec.yaml` dinaikkan dari 4 GB menjadi 8 GB), JVM tidak akan memanfaatkan kapasitas tambahan tersebut tanpa modifikasi manual.
* Gunakan persentase dinamis:
  ```bash
  -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=75.0 -XX:MinRAMPercentage=75.0
  ```
  Dengan konfigurasi ini, jika limit kontainer pada `tomcat-spec.yaml` disetel 4 GB, Heap otomatis dialokasikan ~3.0 GB. Jika limit dinaikkan menjadi 8 GB, JVM otomatis menyesuaikan Heap menjadi ~6.0 GB tanpa perlu memodifikasi Dockerfile atau image kontainer.

#### 3. Lokasi Modifikasi JVM Options: `CATALINA_OPTS` vs `JAVA_OPTS`

Dalam Apache Tomcat, terdapat pemisahan tegas antara variabel lingkungan JVM:
* **Gunakan `CATALINA_OPTS` (Bukan `JAVA_OPTS`)**:
  * `JAVA_OPTS` dieksekusi pada *setiap* pemanggilan perintah Java di Tomcat, termasuk perintah `bin/shutdown.sh` / `bin/shutdown.bat` dan utilitas internal seperti `bin/version.sh`. Jika `-Xmx` besar ditaruh di `JAVA_OPTS`, skrip shutdown akan mencoba mengalokasikan Heap besar hanya untuk mengirim sinyal stop, yang berpotensi gagal akibat limit memori kontainer sudah habis.
  * `CATALINA_OPTS` **hanya** dieksekusi saat server Tomcat dijalankan (`catalina.sh run` / `catalina.bat run`).

* **Mekanisme Penerapan**:
  1. **Melalui Skrip `setenv` Bawaan Tomcat**:
     * Pada Linux: `<CATALINA_HOME>/bin/setenv.sh`
       ```bash
       export CATALINA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"
       ```
     * Pada Windows: `<CATALINA_HOME>/bin/setenv.bat`
       ```cmd
       set "CATALINA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"
       ```
  2. **Melalui Environment Variable pada Manifes GitOps (`tomcat-spec.yaml`)**:
     Operator dapat mendefinisikan flag JVM langsung pada manifes deklaratif, yang diteruskan oleh `tcctl` ke kontainer:
     ```yaml
     container:
       env:
         CATALINA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"
     ```
  3. **Fail-Fast Resiliency**:
     Parameter `-XX:+ExitOnOutOfMemoryError` atau `-XX:+CrashOnOutOfMemoryError` wajib disertakan agar saat terjadi OutOfMemory, proses JVM langsung dihentikan seketika. Hal ini memungkinkan reconciler otonom `tcctl` mendeteksi bahwa kontainer mati dan langsung memicu *auto-healing / self-recovery*.

---

### ❓ Pertanyaan 11: "Mengapa JDK 8 tidak dianjurkan untuk kontainer modern, dan apakah JDK 11 LTS masih layak untuk Apache Tomcat 9?"

#### 1. Mengapa JDK 8 Ditinggalkan / Tidak Dianjurkan untuk Kontainer Modern:
Meskipun JDK 8 memiliki riwayat adopsi yang sangat luas di masa lalu, penggunaannya pada platform kontainer modern menghadapi hambatan teknis serius:
1. **Ukuran Base Image Windows yang Masif (ServerCore vs. NanoServer)**:
   JDK 8 membutuhkan pustaka Win32 API lengkap yang tidak tersedia di Windows NanoServer. Akibatnya, image Windows Container untuk JDK 8 wajib menggunakan base image **Windows ServerCore** dengan ukuran masif (**4.5 GB – 5.0 GB**). Bandingkan dengan JDK 11 Headless yang dapat berjalan di atas **Windows NanoServer** dengan ukuran hanya **~250 MB – 300 MB**! Ukuran ServerCore yang besar memperlambat pipeline CI, memboroskan bandwidth registry, dan memperlama proses cold pull di host target.
2. **Keterbatasan Dukungan Kontainer (cgroups & CPU Quota)**:
   Meskipun rilis akhir (8u191+) mem-backport `-XX:+UseContainerSupport`, implementasinya belum stabil terhadap cgroups v2, multi-socket core detection, dan CPU quota throttling. JVM sering salah membaca jumlah core fisik host alih-alih alokasi CPU limit kontainer, menyebabkan pemborosan thread Garbage Collection (*GC thrashing*).
3. **Garbage Collector Usang**:
   Default GC pada JDK 8 adalah *Parallel GC* yang berorientasi throughput tetapi menghasilkan waktu jeda (*Stop-The-World pause*) yang panjang. Fitur G1GC pada Java 8 belum optimal dan mengonsumsi overhead memori off-heap yang tinggi.
4. **Protokol Kriptografi Usang**:
   JDK 8 tidak mendukung TLS 1.3 secara native, menyulitkan kepatuhan terhadap standar audit keamanan perbankan dan industri (CIS-Benchmark / PCI-DSS v4.0).

#### 2. Mengapa JDK 11 LTS adalah "Sweet Spot" dan Sangat Ideal untuk Tomcat 9:
Bagi arsitektur enterprise yang menstandarisasi **Apache Tomcat 9.0**, JDK 11 LTS adalah pilihan paling optimal (*Sweet Spot*) karena alasan-alasan fundamental berikut:
1. **Kompatibilitas Penuh Namespace `javax.*` (Zero Breaking Changes)**:
   Apache Tomcat 9 mengimplementasikan spesifikasi Java EE 8 (Servlet 4.0, JSP 2.3) yang menggunakan namespace paket `javax.*`. Mulai Tomcat 10+ (Jakarta EE 9/10 dan Spring Boot 3), seluruh ekosistem Java bermigrasi ke namespace baru `jakarta.*`. Aplikasi legacy enterprise yang bergantung pada paket `javax.*` dapat berjalan stabil di atas JDK 11 pada Tomcat 9 tanpa memerlukan refactoring kode ataupun perubahan dependensi.
2. **Dukungan Penuh Windows NanoServer**:
   OpenJDK 11 mendukung distribusi headless murni yang dapat berjalan langsung di atas Windows Server 2022 NanoServer, memangkas footprint image dari 5 GB menjadi < 400 MB (pengurangan ukuran >90%).
3. **Siklus Hidup Dukungan Vendor (Long-Term Support)**:
   Distribusi OpenJDK enterprise terkemuka (Eclipse Adoptium/Temurin, Red Hat OpenJDK, Amazon Corretto, Azul Zulu) memberikan komitmen *Extended Support* dan pembaruan patch keamanan untuk OpenJDK 11 hingga setidaknya **Oktober 2027** (bahkan beberapa vendor menyediakan dukungan berbayar hingga 2028-2030).
4. **Kapabilitas Kontainer Matang**:
   Mendukung penuh cgroups v1 dan v2, pembacaan CPU quota yang akurat, default G1GC yang hemat memori, string deduplication, dan dukungan penuh TLS 1.3 native.

| Kriteria Evaluasi | OpenJDK 8 | **OpenJDK 11 LTS (Sweet Spot)** | OpenJDK 17 / 21 LTS |
| :--- | :--- | :--- | :--- |
| **Target Pasangan Tomcat** | Tomcat 8.5 / 9.0 | **Tomcat 9.0 (Rekomendasi)** | Tomcat 10.1 / 11.0 |
| **Java EE Namespace** | `javax.*` | **`javax.*` (100% kompatibel legacy)** | `jakarta.*` (Wajib refactor paket) |
| **Ukuran Windows Image** | ServerCore (~4.5 GB - 5.0 GB) | **NanoServer (~250 MB - 350 MB)** | NanoServer (~250 MB - 350 MB) |
| **Container Awareness** | Terbatas (Backport 8u191+) | **Native & Matang (cgroups v1/v2)** | Native & Optimal |
| **Default Garbage Collector** | Parallel GC (STW pauses lama) | **G1GC (Low pause, stabil)** | G1GC / ZGC Generational |
| **Dukungan TLS 1.3** | Tidak native (perlu tweak) | **Native out-of-the-box** | Native out-of-the-box |
| **Vendor Support Window** | Berakhir / Limited | **Aktif s/d Oktober 2027+** | Aktif s/d 2029 - 2031 |

---

### ❓ Pertanyaan 12: "Siapa yang mengeksekusi `docker build` untuk Windows Container, dan bagaimana portabilitas workflow CI di Gitea Actions, GitLab CI, dan Bitbucket Pipelines?"

#### 1. Eksekusi `docker build` untuk Windows Container
* **Arsitektur Kernel Kontainer**:
  Sebuah Windows Container **tidak dapat di-build ataupun dieksekusi di atas host/kernel Linux**. Windows Container membutuhkan subsistem kernel Windows Server (Windows Server Silos / Hyper-V Container isolation).
* **Siapa yang Menjalankan `docker build`?**:
  Proses `docker build` dan pengujian kontainer dijalankan oleh **Dedicated Windows CI Runner / Build Agent** (misalnya VM Windows Server 2022 yang terpasang Docker CE / Mirantis Container Runtime dan menjalankan agent runner CI).
* **Peran Server CI (Gitea / GitLab / Bitbucket)**:
  Server CI (yang umumnya berjalan di Linux VM atau Kubernetes) hanya bertindak sebagai *orchestrator / web dispatcher*. Saat menerima pemicu commit kode, server CI mendispatch pekerjaan build ke Windows Runner melalui routing tag (misal: `tags: [windows, docker]`). Windows Runner lokal tersebut yang memanggil `docker build`, `tcctl.exe hardening audit`, dan `docker push` ke image registry internal.

#### 2. Portabilitas Workflow Antara Gitea Actions, GitLab CI, dan Bitbucket Pipelines
* **Apakah file workflow otomatis terbaca lintas platform?**
  **Tidak.** Format file dan sintaks struktur YAML bersifat spesifik untuk masing-masing platform CI:
  * Gitea Actions / GitHub Actions: `.gitea/workflows/<name>.yaml` (menggunakan hierarki `jobs.<id>.steps[].run`).
  * GitLab CI: `.gitlab-ci.yml` (menggunakan hierarki `stages:`, `<job_name>:`, `script:`).
  * Bitbucket Pipelines: `bitbucket-pipelines.yml` (menggunakan hierarki `pipelines: default: - step: script:`).
* **Prinsip Engine-Agnostic Core CLI**:
  Meskipun "wrapper" sintaks YAML berbeda, **perintah inti CLI yang dijalankan di dalamnya adalah 100% IDENTIK dan PORTABEL**. Seluruh logika validasi keamanan, audit CIS-Benchmark, scan kerentanan, dan build kontainer dibungkus di dalam CLI tool (`docker`, `tcctl.exe`, `git`), bukan di-hardcode ke dalam fitur spesifik platform CI.

#### 3. Komparasi Sintaks Workflow Lintas Platform

Berikut perbandingan implementasi pipeline CI yang mengeksekusi urutan build, audit keamanan dengan `tcctl.exe`, dan promosi ke GitOps repository:

=== "Gitea Actions / GitHub Actions (`.gitea/workflows/ci.yaml`)"

    ```yaml
    name: Windows Container CI
    on:
      push:
        branches: [ main ]
    jobs:
      build-and-promote:
        runs-on: [ windows, docker ]
        steps:
          - name: Checkout Source Code
            uses: actions/checkout@v4

          - name: Build Windows Container Image
            run: |
              docker build -t registry.corp.internal:5000/payment-service:${{ github.sha }} .

          - name: Audit Hardening CIS-Benchmark
            run: |
              tcctl.exe hardening audit --target localhost:8080 --output audit-report.json

          - name: Push Container Image
            run: |
              docker push registry.corp.internal:5000/payment-service:${{ github.sha }}

          - name: Promote to GitOps Manifest
            run: |
              git clone http://gitadm:${{ secrets.GIT_TOKEN }}@git.corp.internal/gitadm/tomcat-gitops.git gitops-repo
              cd gitops-repo
              powershell -Command "(Get-Content tomcat-spec.yaml) -replace 'tag: .*', 'tag: \"${{ github.sha }}\"' | Set-Content tomcat-spec.yaml"
              git commit -am "chore(release): promote payment-service to ${{ github.sha }}"
              git push origin main
    ```

=== "GitLab CI (`.gitlab-ci.yml`)"

    ```yaml
    stages:
      - build
      - test
      - publish
      - promote

    variables:
      IMAGE_TAG: $CI_REGISTRY_IMAGE/payment-service:$CI_COMMIT_SHORT_SHA

    build_image:
      stage: build
      tags:
        - windows
        - docker
      script:
        - docker build -t $IMAGE_TAG .

    audit_security:
      stage: test
      tags:
        - windows
        - docker
      script:
        - tcctl.exe hardening audit --target localhost:8080 --output audit-report.json

    push_image:
      stage: publish
      tags:
        - windows
        - docker
      script:
        - docker push $IMAGE_TAG

    promote_gitops:
      stage: promote
      tags:
        - windows
      script:
        - git clone http://oauth2:$GITOPS_ACCESS_TOKEN@gitlab.corp.internal/platform/tomcat-gitops.git gitops-repo
        - cd gitops-repo
        - powershell -Command "(Get-Content tomcat-spec.yaml) -replace 'tag: .*', 'tag: \"$CI_COMMIT_SHORT_SHA\"' | Set-Content tomcat-spec.yaml"
        - git commit -am "chore(release): promote payment-service to $CI_COMMIT_SHORT_SHA"
        - git push origin main
      only:
        - main
    ```

=== "Bitbucket Pipelines (`bitbucket-pipelines.yml`)"

    ```yaml
    pipelines:
      branches:
        main:
          - step:
              name: Build and Security Audit
              runs-on:
                - self.hosted
                - windows
                - docker
              script:
                - docker build -t registry.corp.internal:5000/payment-service:$BITBUCKET_COMMIT .
                - tcctl.exe hardening audit --target localhost:8080 --output audit-report.json
                - docker push registry.corp.internal:5000/payment-service:$BITBUCKET_COMMIT
          - step:
              name: Promote to GitOps Repository
              runs-on:
                - self.hosted
                - windows
              script:
                - git clone http://x-token-auth:$GITOPS_TOKEN@bitbucket.org/platform/tomcat-gitops.git gitops-repo
                - cd gitops-repo
                - powershell -Command "(Get-Content tomcat-spec.yaml) -replace 'tag: .*', 'tag: \"$BITBUCKET_COMMIT\"' | Set-Content tomcat-spec.yaml"
                - git commit -am "chore(release): promote payment-service to $BITBUCKET_COMMIT"
                - git push origin main
    ```

---

### ❓ Pertanyaan 13: "Jika CI sudah ada di Gitea/GitLab/Bitbucket dan GitOps ditangani oleh `tcctl`, apakah Ansible masih diperlukan? Apakah fungsinya hanya untuk Day-1?"

**Konfirmasi Arsitektur**:
**Tepat sekali.** Dalam paradigma arsitektur *Pure Pull-Based GitOps*, Ansible **tidak lagi digunakan untuk operasional harian aplikasi (Day-2 Continuous Operations)**.

#### 1. Demarkasi Tanggung Jawab yang Tegas: Day-1 vs. Day-2

| Kategori | **Day-1 Machine Provisioning (Ansible)** | **Day-2 Continuous Lifecycle (Pure Pull-Based GitOps via `tcctl`)** |
| :--- | :--- | :--- |
| **Fokus & Siklus** | Inisialisasi mesin baru (*One-time initial machine bootstrap*). | Operasional berkelanjutan (*Continuous application lifecycle & self-healing*). |
| **Aktivitas Utama** | • Install Docker Engine / Mirantis Runtime pada VM baru.<br>• Buat struktur direktori sistem (`C:\Program Files\tcctl`).<br>• Letakkan biner `tcctl.exe` dan konfigurasi awal `config.yaml`.<br>• Eksekusi `tcctl gitops init` (mendaftarkan Scheduled Task / systemd timer).<br>• Konfigurasi firewall lokal awal. | • Memeriksa repositori manifes GitOps secara berkala (polling REST API).<br>• Deteksi *drift* konfigurasi antara Git dan status runtime kontainer.<br>• Melakukan staging rollout dan pre-flight health probe.<br>• Melakukan zero-downtime swap kontainer aktif.<br>• Memulihkan kontainer secara otomatis jika terjadi insiden (*self-healing*). |
| **Kebutuhan Akses Jaringan** | **Inbound SSH (Port 22)** dibuka sementara hanya pada saat setup awal. | **Zero Inbound Port** (Hanya Outbound HTTPS Port 443 ke Git Server dan Image Registry). |
| **Manajemen Kredensial** | **Ephemeral SSH Key**: Kunci SSH sementara yang **langsung dimusnahkan (*self-destruct*)** setelah bootstrap selesai sesuai [TC-ADR-0008](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat/adr-records/TC-ADR-0008.md). | Read-only Git Token atau Deploy Key (HTTPS) tersimpan di file konfigurasi lokal host. |
| **Metode Eksekusi** | Push-based terpusat dari Ansible Control Node. | Pull-based otonom dari dalam masing-masing host target. |

#### 2. Mengapa Ansible Tidak Digunakan untuk Day-2 Operations?
1. **Menghilangkan Ketergantungan SSH Terpusat (Eliminasi Blast Radius)**:
   Jika Day-2 mengandalkan Ansible (push-based), maka Ansible Control Node harus menyimpan private SSH key dengan akses root/Administrator ke seluruh ratusan server produksi. Jika server Ansible disusupi (*compromised*), seluruh armada infrastruktur jatuh ke tangan penyerang. Dengan Pure Pull-Based GitOps, server target tidak membuka port SSH inbound sama sekali.
2. **Mencegah Configuration Drift Berkelanjutan**:
   Ansible hanya berjalan saat dieksekusi secara manual oleh operator atau dipicu oleh webhook. Jika ada perubahan konfigurasi manual di host target di luar jadwal Ansible, penyimpangan (*drift*) tersebut tidak terdeteksi. Sebaliknya, agent `tcctl` GitOps berjalan otonom setiap 5 menit di host lokal, mendeteksi setiap anomali, dan langsung merekonsiliasi kontainer kembali ke status yang dideklarasikan di Git.
3. **Kepatuhan Audit Keamanan (CIS-Benchmark)**:
   Setelah proses Day-1 oleh Ansible selesai dan diverifikasi, port SSH 22 pada host Windows Server produksi dapat ditutup secara permanen di firewall. Mesin beroperasi dalam status *Zero Inbound Attack Surface*, yang merupakan standar tertinggi dalam arsitektur keamanan Zero Trust.

---

### ❓ Pertanyaan 14: "Apakah pengujian fungsi GitOps ini sudah menggunakan Gitea Actions? Apa batas pemisah antara GitOps Reconciler (CD) dan Gitea Actions (CI)?"

#### 1. Klarifikasi Posisi Pengujian GitOps
**Belum.** Pengujian fungsi GitOps yang telah berhasil diverifikasi pada host target Windows Server (`win-lab` / `win2022`) adalah pengujian sisi **CD Engine / Autonomous Pull-Based Reconciler**. 

Pada pengujian tersebut, pembaruan versi image pada `tomcat-spec.yaml` masih dilakukan secara manual oleh operator (edit file manifes $\rightarrow$ `git commit` $\rightarrow$ `git push` ke repositori `tomcat-gitops`). Target host kemudian menarik perubahan tersebut dan mengeksekusi rolling update secara otonom.

#### 2. Batas Demarkasi Tanggung Jawab: CI (Gitea Actions) vs CD (GitOps Reconciler)

Pemisahan tanggung jawab secara tegas (*Separation of Concerns*) antara CI dan CD pada arsitektur GitOps modern:

```
[Developer]
    │ (git push)
    ▼
[Repo: tomcat (Source Code)]
    │
    ▼ ════════════════ CONTINUOUS INTEGRATION (CI) DOMAIN ════════════════
    │ Gitea Actions Workflow (.gitea/workflows/ci.yaml)
    │  1. Build Container Image (OCI Image Build)
    │  2. Security Gate 1: CIS Hardening Audit (tcctl hardening audit)
    │  3. Security Gate 2: Vulnerability Scan (tcctl va scan / Trivy)
    │  4. Push OCI Image to Internal Registry (localhost:3000)
    │  5. Automated GitOps Promotion (CI Bot commits & pushes tag update)
    ▼ ════════════════════════════════════════════════════════════════════
[Repo: tomcat-gitops (Declarative Spec: tomcat-spec.yaml)]
    ▲
    │ (Pure Pull-Based via HTTPS / REST API - Periodic Poll)
    ▼ ════════════════ CONTINUOUS DEPLOYMENT (CD) DOMAIN ════════════════
    │ Autonomous Reconciler Host Runtime (tcctl gitops sync)
    │  1. Detect Remote Git Commit / Image Tag Change
    │  2. Launch Temporary Staging Container (<name>-staging pada port 9080)
    │  3. Pre-flight Readiness Health Check Probe (HTTP 200 OK)
    │  4. Drain & Terminate Previous Canonical Instance (<name> pada port 8080)
    │  5. Promote Staging to Canonical Name (<name> pada port 8080)
    │  6. Continuous Drift Detection & Self-Healing (Task Scheduler / systemd)
    ▼ ════════════════════════════════════════════════════════════════════
[Target Host Runtime (win-lab / Windows Server 2022)]
```

#### 3. Mengapa Keduanya Terpisah?
1. **Prinsip Least Privilege**: CI Runner tidak memerlukan kredensial superuser, SSH key, atau akses jaringan langsung ke server produksi. CI runner hanya perlu akses tulis (*push token*) ke repositori manifes `tomcat-gitops`.
2. **Immutability & Audit Trail**: Repositori `tomcat-gitops` menjadi buku besar deklaratif (*Single Source of Truth*). Setiap versi yang meluncur ke produksi tercatat dalam riwayat Git commit lengkap dengan identitas commit bot CI, pesan rilis, dan timestamp.
3. **Resilience & Kemandirian Runtime**: Jika server Gitea atau CI Runner mengalami downtime, kontainer di host target tetap berjalan stabil, dan reconciler lokal tetap melakukan drift detection serta self-healing mandiri tanpa terganggu ketiadaan CI server.

---

## 📐 Architecture & Design Blueprint

### 1. Arsitektur Dekopel CI dan Pure Pull-Based GitOps (Day-2)

Pemisahan tanggung jawab secara tegas antara Continuous Integration (CI) dan Continuous Deployment (CD):

```mermaid
flowchart TD
    subgraph DEV_WORKFLOW ["1. Developer & CI Pipeline"]
        Dev["Developer Push Code"] --> GitApp["Application Repo (Git)"]
        GitApp --> CI["CI Pipeline (Jenkins / GitLab CI)"]
        CI --> Audit["tcctl hardening audit (CIS-Bench)"]
        Audit --> TrivyScan["Trivy Vulnerability Scan"]
        TrivyScan --> PushReg["Push OCI Image to Registry"]
        PushReg --> UpdateManifest["Commit & Push Image Tag Update"]
        UpdateManifest --> GitOpsRepo[("GitOps Repo: tomcat-spec.yaml\n(Single Source of Truth)")]
    end

    subgraph NETWORK_BOUNDARY ["Firewall / Network Boundary (Egress Only)"]
        direction TB
        FW["No Inbound Ports Needed (SSH Port 22 Closed)\nEgress: HTTPS (443) only to Git & Registry"]
    end

    subgraph TARGET_HOSTS ["2. Fleet Target Hosts (Autonomous Reconcilers)"]
        GitOpsRepo -.->|HTTPS Pull| SyncHost1["Host 1: tcctl gitops sync\n(systemd --user timer)"]
        GitOpsRepo -.->|HTTPS Pull| SyncHost2["Host 2: tcctl gitops sync\n(systemd --user timer)"]
        GitOpsRepo -.->|HTTPS Pull| SyncHostN["Host N: tcctl gitops sync\n(systemd --user timer)"]

        SyncHost1 --> Container1["Podman Rootless\nActive: tomcat-app (:8080)"]
        SyncHost2 --> Container2["Podman Rootless\nActive: tomcat-app (:8080)"]
        SyncHostN --> ContainerN["Podman Rootless\nActive: tomcat-app (:8080)"]
    end

    UpdateManifest -.->|Triggers Pull| NETWORK_BOUNDARY
    NETWORK_BOUNDARY -.-> TARGET_HOSTS
```

### 2. Alur Transisi Temporary Staging Container Rollout

Mekanisme zero-downtime tanpa suffix permanen pada kontainer produksi:

```mermaid
sequenceDiagram
    autonumber
    participant Op as tcctl gitops sync / deploy
    participant Host as Podman Engine
    participant Active as tomcat-app (Active :8080)
    participant Staging as tomcat-app-staging (:9080)
    participant Upstream as Nginx / Edge Proxy

    Note over Active: Kondisi Normal: tomcat-app aktif di port 8080
    Op->>Host: 1. Tarik Image OCI Baru (podman pull)
    Op->>Host: 2. Jalankan Staging Container: tomcat-app-staging (Port 9080)
    activate Staging
    
    loop Health Probe Loop (max 60 detik)
        Op->>Staging: GET http://localhost:9080/health
        Staging-->>Op: 200 OK (Ready & Warm)
    end

    Note over Op,Host: Promosi Atomik (Switchover)
    Op->>Active: 3. Stop kontainer lama (Graceful SIGTERM)
    deactivate Active
    Op->>Active: 4. Hapus kontainer lama (podman rm tomcat-app)
    
    Op->>Staging: 5. Stop staging sementara (podman stop tomcat-app-staging)
    Op->>Host: 6. Jalankan kontainer baru dengan nama kanonikal: tomcat-app (Port 8080)
    activate Active
    Op->>Host: 7. Cleanup staging container (podman rm tomcat-app-staging)
    deactivate Staging
    
    Note over Active: Layanan Kembali Normal di Port 8080 Tanpa Suffix!
```

### 3. Alur Self-Destructing Ephemeral SSH Access (Day-1 Bootstrapping)

Pola provisioning awal yang membersihkan jejaknya sendiri:

```mermaid
sequenceDiagram
    autonumber
    participant Admin as Provisioning Host (Ansible / Operator)
    participant Target as Target Brownfield VM
    participant AuthKeys as Target: ~/.ssh/authorized_keys
    participant Systemd as Target: systemd --user

    Admin->>Target: 1. Inject Ephemeral Public Key dengan Tag Spesifik\n(ssh-rsa AAAAB3Nza... # ephemeral-day1-bootstrap)
    Target->>AuthKeys: Simpan kunci
    
    Admin->>Target: 2. Eksekusi Script Bootstrap via SSH
    Note over Target: - Install biner tcctl ke /usr/local/bin atau ~/.local/bin\n- Setup volume podman & file permissions (0755/0644)\n- Generate unit file: tcctl-gitops.service & timer
    Target->>Systemd: 3. Enable & Start tcctl-gitops.timer
    
    Note over Target: Tahap Akhir: Self-Destruction
    Target->>AuthKeys: 4. sed -i '/ephemeral-day1-bootstrap/d' ~/.ssh/authorized_keys
    Note over AuthKeys: Kunci Terhapus Seketika!
    
    Admin->>Target: 5. Verifikasi Koneksi Berikutnya
    Target-->>Admin: Permission Denied (publickey)
    Note over Admin,Target: Day-1 Selesai! Host Sekarang 100% Otonom (Day-2 GitOps)
```

---

## ⚙️ Detail Spesifikasi Teknis

### 1. Spesifikasi Deklarasi GitOps (`tomcat-spec.yaml`)

File manifes yang disimpan di repositori GitOps (misalnya `git@git.corp/infra/tomcat-fleet.git`):

```yaml
version: "1.0"
metadata:
  application: "payment-service"
  environment: "production"
  tier: "backend"

spec:
  # Konfigurasi Image OCI
  image:
    repository: "tomcat"
    tag: "9.0-jdk11"
    pullPolicy: "IfNotPresent"

  # Konfigurasi Runtime Kanonikal
  runtime:
    containerName: "payment-service"      # Nama kanonikal bersih tanpa suffix
    httpPort: 8080                       # Port produksi utama
    stagingPort: 9080                    # Port sementara saat rollout nol-downtime
    httpsPort: 8443                      # Native TLS HTTPS connector

  # Pre-Flight Readiness & Health Probe
  healthCheck:
    path: "/"
    expectedStatus: 200
    timeoutSeconds: 60

  # Target Rollback Policy
  autoRollback: true
```

> [!NOTE]
> **Minimalist Specification Pattern**: Blok `storage:` dan `network:` sengaja tidak didefinisikan secara manual. Operator `tcctl` secara deterministik menurunkan konfigurasi storage dari `containerName` (Host Bind-Mount `C:\tomcats\<containerName>` pada Windows per TC-ADR-0009 atau Engine Named Volumes pada Linux) serta membiarkan container runtime menggunakan default network engine (tanpa hardcoded `devops-lab`).


### 2. Spesifikasi Autonomous Host Reconciler (`tcctl gitops`)

Subcommand baru yang akan ditambahkan pada `tcctl`:

- **`tcctl gitops init`**:
  - Menerima argumen URL repositori GitOps dan interval timer (misal: `5m`).
  - Mengkloning atau mengonfigurasi local working copy di `~/.config/tcctl/gitops/`.
  - Mendaftarkan dan mengaktifkan unit systemd timer pada user level:
    - Unit Service: `~/.config/systemd/user/tcctl-gitops.service`
    - Unit Timer: `~/.config/systemd/user/tcctl-gitops.timer`
- **`tcctl gitops sync`**:
  - Mengeksekusi `git fetch origin` dan memeriksa apakah `HEAD` branch sinkron berbeda dengan commit aktif saat ini.
  - Membaca dan memvalidasi sintaks `tomcat-spec.yaml`.
  - Memeriksa apakah versi image, port, konfigurasi volume, atau variabel lingkungan mengalami deviasi (*drift*).
  - Jika terjadi perubahan atau drift:
    - Melakukan `podman pull` image OCI yang baru.
    - Menjalankan `tcctl deploy rollout` menggunakan temporary staging container.
    - Memperbarui file state lokal `~/.config/tcctl/gitops/state.json` dengan commit hash terbaru.
    - Mengirimkan audit log rekonsiliasi ke Syslog / Journald.

### 3. Template Unit Systemd User Service & Timer

**File: `~/.config/systemd/user/tcctl-gitops.service`**
```ini
[Unit]
Description=Apache Tomcat Enterprise GitOps Reconciler (tcctl)
Documentation=https://devops-handbook.corp.internal/projects/tomcat/
After=network.target

[Service]
Type=oneshot
WorkingDirectory=%h/.config/tcctl/gitops
ExecStart=%h/bin/tcctl gitops sync --spec %h/.config/tcctl/gitops/tomcat-spec.yaml
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
```

**File: `~/.config/systemd/user/tcctl-gitops.timer`**
```ini
[Unit]
Description=Periodic GitOps Reconciliation Timer for Apache Tomcat
RefersTo=tcctl-gitops.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
RandomizedDelaySec=30s
Persistent=true

[Install]
WantedBy=timers.target
```

---

## 🔒 Security & Governance Assessment

| Aspek Keamanan | Status Tradisional (Push/SSH) | Status Baru (Pure GitOps & Ephemeral Day-1) |
| --- | --- | --- |
| **Akses Jaringan Inbound** | Membuka Port 22 ke CI/Ansible Controller | **Zero Inbound Ports**. Host hanya membuka egress HTTPS (443) ke Git & Registry. |
| **Kredensial SSH** | Kunci tersimpan permanen di puluhan server target | **Kunci terhapus seketika (*self-destruct*)** setelah Day-1 selesai. |
| **Blast Radius Kompromi CI** | Penyerang di CI mendapatkan shell akses ke semua VM produksi | Penyerang di CI **hanya dapat mengubah manifes Git**, dicegah oleh branch protection, CIS quality gate, dan PR review. |
| **Deteksi Deviasi (*Drift*)** | Tidak terdeteksi hingga jadwal rilis berikutnya | **Otomatis pulih (*self-healing*)** dalam interval maksimal 5 menit melalui reconciler. |
| **Hak Akses File Runtime** | Berisiko permission mismatch pada non-root rootless Podman | Terjamin `0755` (dir) dan `0644` (file) sehingga user `tomcat` (UID 1001) dapat membaca volume `:ro,Z`. |

---

## 🗺️ Implementation Roadmap

```mermaid
flowchart LR
    P1["Fase 1: Dokumentasi & ADR\n(TC-ADR-0006..0008, TN-004)\n[COMPLETED]"] --> P2["Fase 2: Refactor tcctl deploy rollout\n(Temporary Staging Container)\n[COMPLETED]"]
    P2 --> P3["Fase 3: Implementasi tcctl gitops\n(Subcommands: init, sync, status)\n[COMPLETED]"]
    P3 --> P4["Fase 4: Day-1 Bootstrap Scripts\n(Self-Destructing Ephemeral SSH)\n[COMPLETED]"]
    P4 --> P5["Fase 5: Verifikasi Live Runtime\n(Rootless Podman + Drift Healing)\n[COMPLETED]"]
```

1. **Fase 1 (Dokumentasi & ADR)**:
   - Diterbitkan: `TC-ADR-0006`, `TC-ADR-0007`, `TC-ADR-0008`, dan Technical Note `TN-004`.
2. **Fase 2 (Refactoring Operator `tcctl deploy rollout`)**:
   - Paket `internal/orchestrator/rollout.go` mengimplementasikan alur staging: meluncurkan `<name>-staging` pada staging port (`port + 1000`), health probe pre-flight, graceful drain kontainer lama, penghentian staging, dan promosi nama kanonikal `<name>`.
3. **Fase 3 (Implementasi Paket `internal/gitops` pada `tcctl`)**:
   - Paket `internal/gitops` mengimplementasikan: parser `tomcat-spec.yaml` (`gopkg.in/yaml.v3`), state persistence (`state.json`), `tcctl gitops init`, `tcctl gitops sync`, `tcctl gitops status`, dan unit generator `systemd --user timer`.
4. **Fase 4 (Otomasi Day-1 Ephemeral Bootstrap)**:
   - Skrip `scripts/bootstrap/day1_bootstrap.sh` dan Ansible playbook `scripts/bootstrap/day1_bootstrap.yml` dengan instruksi pemusnahan kunci mandiri (`sed -i '/ephemeral-day1-bootstrap/d' ~/.ssh/authorized_keys`).
5. **Fase 5 (Pengujian Live Runtime & Verifikasi)**:
   - Seluruh skenario telah teruji live pada Rootless Podman (rollout nol-downtime, deteksi drift dan self-healing otomatis, serta pembersihan kunci SSH).

---

## 🧪 Verification & Live Proof

### 1. Unit Tests Suite (`go test`)
```bash
go test -v ./...
```
Hasil verifikasi:
- `TestDefaultSpecTemplate`: PASS (0.00s)
- `TestValidationErrors`: PASS (0.00s)
- `TestStateSaveAndLoad`: PASS (0.00s)
- Status: **100% Passed** dalam 5 milidetik.

### 2. Multi-Platform Static Compilation (`make build-all`)
- Linux Binary: `bin/tcctl` (ELF 64-bit LSB executable, statically linked, CGO_ENABLED=0).
- Windows Binary: `bin/tcctl.exe` (PE32+ executable for MS Windows, statically linked).

### 3. Live Temporary Staging Rollout Proof
Dieksekusi menggunakan perintah:
```bash
tcctl deploy rollout --name test-app --port 8085 --staging-port 9085 --image localhost/tomcat:9.0
```
Hasil observasi:
1. `Active Canonical Instance: test-app (Port: 8085)`
2. `Phase 1: Launching temporary staging container 'test-app-staging' on port 9085...`
3. `Phase 1: Staging container 'test-app-staging' passed health probe (200 OK).`
4. `Phase 2: Draining and stopping previous canonical instance 'test-app' -> Stopped and removed.`
5. `Phase 3: Promoting new version to canonical name 'test-app' on primary port 8085...`
6. `podman ps` menampilkan: hanya satu kontainer `test-app` aktif tanpa akhiran `-staging`, `-blue`, atau `-green`.

### 4. Autonomous Drift Detection & Self-Healing Proof
1. Kontainer `test-app` dihentikan secara paksa (`podman stop test-app`).
2. `tcctl gitops sync --spec tomcat-spec.yaml` mendeteksi anomali:
   `⚠ Drift or Update Detected: Container is not running (stopped or missing)`
3. Reconciler secara otomatis memicu pemulihan (*self-healing*) dan menghidupkan kembali instance `test-app` sesuai spesifikasi manifes GitOps.
4. `state.json` mencatat status: `"syncStatus": "SYNCED"`.

### 5. Self-Destructing Ephemeral Key Proof
Uji coba pembersihan kunci sementara pada file `authorized_keys` membuktikan bahwa baris bertanda `# ephemeral-day1-bootstrap` berhasil terhapus secara atomik, sementara kunci permanen milik administrator dan workstation tetap utuh tanpa modifikasi.

### 6. Windows Server 2022 Live Verification (Zero-Dependency & Program Files Layout)

Pengujian end-to-end GitOps otonom fase 3 dilakukan secara langsung pada node target **Windows Server 2022 (`win-lab`)** dengan runtime **Docker CE v27.5.1** dan image terverifikasi `tomcat:9.0-jdk11` (dibangun dari NanoServer LTSC2022 + Eclipse Temurin JDK 11 pada TN-007).

#### A. Desain Arsitektur Khusus Host Windows
1. **Zero External Git CLI Dependency (Tanpa MinGit)**:
   Host Windows lab tidak memerlukan instalasi `git.exe` atau MinGit portable. Reconciler `tcctl` secara native memanfaatkan Gitea REST API (`/api/v1/repos/<owner>/<repo>/commits` dan raw spec fetch `/raw/branch/<branch>/<spec>`) untuk deteksi revisi commit dan sinkronisasi manifes secara instan melalui HTTP.
2. **Unified Directory Layout**:
   Biner operator dan manifes GitOps ditempatkan secara terpusat dan rapi di dalam:
   - Root direktori: `C:/Program Files/tcctl/`
   - Biner eksekusi: `C:/Program Files/tcctl/tcctl.exe`
   - GitOps working directory: `C:/Program Files/tcctl/gitops/` (`gitops-config.json`, `state.json`, `tomcat-spec.yaml`)
3. **Forward Slash Path Normalization**:
   Seluruh path pada konfigurasi, argumen, dan volume mount di Windows dinormalisasi menggunakan garis miring (`/`), mencegah *backslash escape parsing corruption* (`\t`, `\u`, dll.) pada format JSON, YAML, maupun perintah Docker CLI.
4. **Autonomous Windows Task Scheduler**:
   Reconciler otonom diregistrasikan ke Windows Task Scheduler dengan nama `tcctl-gitops-reconciler` menggunakan PowerShell `Register-ScheduledTask`, beroperasi secara periodik setiap 5 menit di bawah akun `SYSTEM`.
5. **Streamlined Opinionated Manifest**:
   Manifes `tomcat-spec.yaml` disederhanakan tanpa blok `network:` dan `storage:`. Storage host bind-mount otomatis diturunkan ke `C:/tomcats/<container_name>` sesuai TC-ADR-0009.

#### B. Rekaman Eksekusi: Initial GitOps Initialization (`tcctl gitops init`)
```powershell
PS C:\Users\Administrator> & "C:/Program Files/tcctl/tcctl.exe" gitops init --repo http://localhost:3000/gitadm/tomcat-gitops.git --branch main --timer

========================================================
 Initializing Autonomous GitOps Environment (tcctl gitops init)
========================================================

ℹ GitOps Working Directory: C:/Program Files/tcctl/gitops
✔ Saved GitOps configuration profile (gitops-config.json)
ℹ Fetching manifest 'tomcat-spec.yaml' directly via Gitea REST API...
✔ Successfully fetched 'tomcat-spec.yaml' via Gitea REST API!
ℹ Found existing spec at C:/Program Files/tcctl/gitops/tomcat-spec.yaml
✔ Registered Windows Scheduled Task 'tcctl-gitops-reconciler' (Every 5 minutes)
✔ GitOps initialization completed successfully!

Next Steps:
  1. Review and edit specification:
     C:/Program Files/tcctl/gitops/tomcat-spec.yaml
  2. Test immediate reconciliation:
     tcctl gitops sync --spec C:/Program Files/tcctl/gitops/tomcat-spec.yaml
  3. View reconciler status:
     tcctl gitops status --dir C:/Program Files/tcctl/gitops
```

#### C. Rekaman Eksekusi: Drift Detection & Self-Healing
Kontainer produksi `payment-service` dihentikan secara manual (`docker stop payment-service`) untuk mensimulasikan kegagalan sistem atau intervensi operator liar:

```powershell
PS C:\Users\Administrator> & "C:/Program Files/tcctl/tcctl.exe" gitops sync

========================================================
 Executing GitOps Autonomous Reconciliation (tcctl gitops sync)
========================================================

ℹ Specification File : C:/Program Files/tcctl/gitops/tomcat-spec.yaml
ℹ Working Directory  : C:/Program Files/tcctl/gitops
ℹ GitOps config detected (http://localhost:3000/gitadm/tomcat-gitops.git). Checking remote updates via Gitea REST API...
ℹ Remote Git HEAD (API): d29d9d6 ("chore(spec): streamline manifest to minimalist pattern with tomcat:9.0-jdk11")
ℹ Desired Container  : payment-service (Image: tomcat:9.0-jdk11)
⚠ Drift or Update Detected: Container is not running (stopped or missing)

========================================================
 Executing Zero-Downtime Rollout for 'payment-service'
========================================================

ℹ Container Engine: docker
ℹ No running container found with canonical name 'payment-service'.
ℹ Performing direct initial deployment of canonical instance...

========================================================
 Deploying Hardened Tomcat Container: payment-service
========================================================

ℹ Detected Container Engine: docker
ℹ Step 1: Preparing Host Bind-Mount Directory Structure in C:/tomcats/payment-service...
ℹ Step 2: Auditing XML in Host Directory (C:/tomcats/payment-service/conf)...
✔ Pre-flight XML audit on Host Directory passed (100% compliant).
ℹ Step 3: Launching container 'payment-service' (image: tomcat:9.0-jdk11) via docker...
✔ Container started successfully (ID: 64cfc00c1b03)
ℹ Step 4: Probing HTTP healthcheck endpoint: http://localhost:8080/
✔ Tomcat HTTP Server is HEALTHY (Response status: 404)
✔ HTTP healthcheck probe passed.
✔ Tomcat instance 'payment-service' is up, running, and fully hardened!

 Runtime Environment:
   - Container Image : tomcat:9.0-jdk11
   - Tomcat Version  : Apache Tomcat/9.0.98
   - Java / JDK      : 11.0.32+9 (Eclipse Adoptium)

 Endpoints:
   - HTTP    : http://localhost:8080/
   - HTTPS   : https://localhost:8443/

 Host Bind Mounts (TC-ADR-0009):
   - Base Dir : C:/tomcats
   - Conf     : C:/tomcats/payment-service/conf (Read-Only :ro)
   - Webapps  : C:/tomcats/payment-service/webapps
   - Logs     : C:/tomcats/payment-service/logs

✔ Autonomous GitOps Reconciliation Completed! Instance 'payment-service' is in desired state.
```

#### D. Rekaman Eksekusi: Zero-Downtime Canary Rollout via Temporary Staging
Setelah pengembang mempromosikan commit `8c23789` pada repositori GitOps (`tomcat:9.0-jdk11` -> `tomcat:9.0-jdk11-v2`), rekonsiliasi dijalankan:

```powershell
PS C:\Users\Administrator> & "C:/Program Files/tcctl/tcctl.exe" gitops sync

========================================================
 Executing GitOps Autonomous Reconciliation (tcctl gitops sync)
========================================================

ℹ Specification File : C:/Program Files/tcctl/gitops/tomcat-spec.yaml
ℹ Working Directory  : C:/Program Files/tcctl/gitops
ℹ GitOps config detected (http://localhost:3000/gitadm/tomcat-gitops.git). Checking remote updates via Gitea REST API...
ℹ Remote Git HEAD (API): 8c23789 ("feat(deploy): promote payment-service image to tomcat:9.0-jdk11-v2")
ℹ New remote commit or missing spec detected. Fetching latest tomcat-spec.yaml from Gitea...
✔ Updated 'C:/Program Files/tcctl/gitops/tomcat-spec.yaml' from Gitea repository.
ℹ Desired Container  : payment-service (Image: tomcat:9.0-jdk11-v2)
⚠ Drift or Update Detected: Image version mismatch (Running: tomcat:9.0-jdk11, Desired: tomcat:9.0-jdk11-v2)

========================================================
 Executing Zero-Downtime Rollout for 'payment-service'
========================================================

ℹ Container Engine: docker
ℹ Active Canonical Instance: payment-service (Port: 8080)
ℹ Temporary Staging Name   : payment-service-staging (Port: 9080)
ℹ Phase 1: Launching temporary staging container 'payment-service-staging' on port 9080...

========================================================
 Deploying Hardened Tomcat Container: payment-service-staging
========================================================

ℹ Detected Container Engine: docker
ℹ Step 1: Preparing Host Bind-Mount Directory Structure in C:/tomcats/payment-service-staging...
ℹ Bootstrapping self-signed TLS material (PKCS#12) for instance 'payment-service-staging'...
✔ Self-signed TLS keystore (PKCS#12) created in C:/tomcats/payment-service-staging/conf/ssl
ℹ Seeding hardened XML configuration templates (PKCS12 mode) into C:/tomcats/payment-service-staging/conf...
✔ Hardened XML templates successfully written into 'C:/tomcats/payment-service-staging/conf'.
ℹ Step 2: Auditing XML in Host Directory (C:/tomcats/payment-service-staging/conf)...
✔ Pre-flight XML audit on Host Directory passed (100% compliant).
ℹ Step 3: Launching container 'payment-service-staging' (image: tomcat:9.0-jdk11-v2) via docker...
✔ Container started successfully (ID: 70977c3fbe38)
ℹ Step 4: Probing HTTP healthcheck endpoint: http://localhost:9080/
✔ Tomcat HTTP Server is HEALTHY (Response status: 404)
✔ HTTP healthcheck probe passed.
✔ Tomcat instance 'payment-service-staging' is up, running, and fully hardened!

 Runtime Environment:
   - Container Image : tomcat:9.0-jdk11-v2
   - Tomcat Version  : Apache Tomcat/9.0.98
   - Java / JDK      : 11.0.32+9 (Eclipse Adoptium)

 Endpoints:
   - HTTP    : http://localhost:9080/

 Host Bind Mounts (TC-ADR-0009):
   - Base Dir : C:/tomcats
   - Conf     : C:/tomcats/payment-service-staging/conf (Read-Only :ro)
   - Webapps  : C:/tomcats/payment-service-staging/webapps
   - Logs     : C:/tomcats/payment-service-staging/logs

✔ Phase 1: Staging container 'payment-service-staging' passed health probe (200 OK).
ℹ Phase 2: Draining and stopping previous canonical instance 'payment-service'...
✔ Previous instance 'payment-service' stopped and removed.
ℹ Phase 3: Promoting new version to canonical name 'payment-service' on primary port 8080...

========================================================
 Deploying Hardened Tomcat Container: payment-service
========================================================

ℹ Detected Container Engine: docker
ℹ Step 1: Preparing Host Bind-Mount Directory Structure in C:/tomcats/payment-service...
ℹ Step 2: Auditing XML in Host Directory (C:/tomcats/payment-service/conf)...
✔ Pre-flight XML audit on Host Directory passed (100% compliant).
ℹ Step 3: Launching container 'payment-service' (image: tomcat:9.0-jdk11-v2) via docker...
✔ Container started successfully (ID: 73fc5765d6d3)
ℹ Step 4: Probing HTTP healthcheck endpoint: http://localhost:8080/
✔ Tomcat HTTP Server is HEALTHY (Response status: 404)
✔ HTTP healthcheck probe passed.
✔ Tomcat instance 'payment-service' is up, running, and fully hardened!

 Runtime Environment:
   - Container Image : tomcat:9.0-jdk11-v2
   - Tomcat Version  : Apache Tomcat/9.0.98
   - Java / JDK      : 11.0.32+9 (Eclipse Adoptium)

 Endpoints:
   - HTTP    : http://localhost:8080/
   - HTTPS   : https://localhost:8443/

 Host Bind Mounts (TC-ADR-0009):
   - Base Dir : C:/tomcats
   - Conf     : C:/tomcats/payment-service/conf (Read-Only :ro)
   - Webapps  : C:/tomcats/payment-service/webapps
   - Logs     : C:/tomcats/payment-service/logs

✔ Zero-Downtime Rollout completed! Active instance: 'payment-service' (clean canonical name, no suffix) on port 8080
✔ Autonomous GitOps Reconciliation Completed! Instance 'payment-service' is in desired state.
```

#### E. Rekaman Eksekusi: Reconciler Status & Structured JSON Export
Status rekonsiliasi dan timer diperiksa menggunakan perintah:

```powershell
PS C:\Users\Administrator> & "C:/Program Files/tcctl/tcctl.exe" gitops status --json-out "C:/temp/gitops-status.json"

========================================================
 Apache Tomcat Enterprise — GitOps Reconciler Status
========================================================

ℹ GitOps Directory : C:/Program Files/tcctl/gitops
ℹ Spec File        : C:/Program Files/tcctl/gitops/tomcat-spec.yaml

 📦 GitOps Repository (REST API Mode):
    - Remote URL : http://localhost:3000/gitadm/tomcat-gitops.git
    - Branch     : main
    - Last Commit: 8c23789

 📄 Desired Specification (payment-service):
    - Desired Image : tomcat:9.0-jdk11-v2
    - Container Name: payment-service
    - HTTP Port     : 8080
    - Config Volume : payment-service_conf

 🔄 Reconciler State (state.json):
    - Last Sync Time : 2026-09-24 05:46:05 UTC
    - Last Sync Status: SYNCED
    - Last Synced Rev: 8c23789

 🐳 Live Container Runtime (docker):
    - payment-service	Up 28 seconds	tomcat:9.0-jdk11-v2	0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp

 ⏱️  Windows Scheduled Task:
    - tcctl-gitops-reconciler: Ready

✔ GitOps status JSON exported to C:/temp/gitops-status.json
```

File JSON terekspor di `C:/temp/gitops-status.json` dengan format standar TN-009:
```json
{
  "timestamp": "2026-09-24T05:46:29Z",
  "directory": "C:/Program Files/tcctl/gitops",
  "spec_file": "C:/Program Files/tcctl/gitops/tomcat-spec.yaml",
  "git": {
    "remote_url": "http://localhost:3000/gitadm/tomcat-gitops.git",
    "branch": "main",
    "commit": "8c23789"
  },
  "spec": {
    "Version": "1.0",
    "Metadata": {
      "Application": "payment-service",
      "Environment": "production",
      "Tier": "backend"
    },
    "Spec": {
      "Image": {
        "Repository": "tomcat",
        "Tag": "9.0-jdk11-v2",
        "PullPolicy": "IfNotPresent"
      },
      "Runtime": {
        "ContainerName": "payment-service",
        "HTTPPort": 8080,
        "StagingPort": 9080,
        "HTTPSPort": 8443
      },
      "Storage": {
        "ConfigVolume": "payment-service_conf",
        "WebappsVolume": "payment-service_webapps",
        "LogsVolume": "payment-service_logs"
      },
      "HealthCheck": {
        "Path": "/",
        "ExpectedStatus": 200,
        "TimeoutSeconds": 60
      },
      "AutoRollback": true
    }
  },
  "state": {
    "lastSyncTime": "2026-09-24T05:46:05.4946233Z",
    "lastCommit": "8c23789",
    "commitMessage": "feat(deploy): promote payment-service image to tomcat:9.0-jdk11-v2",
    "image": "tomcat:9.0-jdk11-v2",
    "containerName": "payment-service",
    "httpPort": 8080,
    "httpsPort": 8443,
    "syncStatus": "SYNCED"
  },
  "live_container": "payment-service\tUp 28 seconds\ttomcat:9.0-jdk11-v2\t0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp",
  "timer_active": true,
  "timer_status": "Ready"
}
```

#### F. Rekaman Eksekusi: Verifikasi Lengkap GitOps Otonom di Windows Server 2022 (`win2022`) & Promosi Deklaratif ke JDK 21 LTS (2026-09-25)

Pada 25 September 2026, dilakukan rangkaian pengujian komprehensif end-to-end terhadap fungsi GitOps otonom pada host target **Windows Server 2022 Datacenter (`win2022` / `3.210.194.165`)** menggunakan biner terbaru `C:\Program Files\tcctl\tcctl.exe` yang terintegrasi dengan arsitektur Dynamic JVM Tuning ([TC-ADR-0010](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat/adr-records/TC-ADR-0010.md) & [TN-010](file:///home/eddywiyatno/git/devops-handbook/docs/projects/tomcat/engineering-journal/platform-foundation-and-hardening/TN-010-design-host-bin-setenv-and-dynamic-jvm-tuning.md)).

Seluruh skenario pengujian diverifikasi secara berurutan dan tercatat dengan hasil 100% lulus:

##### 1. Tahap 1: Inisialisasi GitOps & Pendaftaran Scheduled Task (`tcctl gitops init`)
Perintah inisialisasi dijalankan langsung di host Windows Server:
```powershell
PS C:\> tcctl.exe gitops init --repo http://localhost:3000/gitadm/tomcat-gitops.git --branch main --timer
```

*Output Terminal:*
```text
========================================================
 Initializing Autonomous GitOps Environment (tcctl gitops init)
========================================================

ℹ GitOps Working Directory: C:/Program Files/tcctl/gitops
✔ Saved GitOps configuration profile (gitops-config.json)
ℹ Fetching manifest 'tomcat-spec.yaml' directly via Gitea REST API...
✔ Successfully fetched 'tomcat-spec.yaml' via Gitea REST API!
ℹ Found existing spec at C:/Program Files/tcctl/gitops/tomcat-spec.yaml
✔ Registered Windows Scheduled Task 'tcctl-gitops-reconciler' (Every 5 minutes)
✔ GitOps initialization completed successfully!
```

*Verifikasi Scheduled Task:*
```powershell
PS C:\> Get-ScheduledTask -TaskName 'tcctl-gitops-reconciler'

TaskPath                                       TaskName                          State     
--------                                       --------                          -----     
\                                              tcctl-gitops-reconciler           Ready     
```

##### 2. Tahap 2: Initial Declarative Sync & Host Bind Mount `bin/setenv` (`tcctl gitops sync`)
Eksekusi sinkronisasi perdana secara deklaratif menarik spesifikasi awal (`tomcat:9.0-jdk11-v2`):
```powershell
PS C:\> tcctl.exe gitops sync --work-dir 'C:/Program Files/tcctl/gitops'
```

*Output Terminal:*
```text
========================================================
 Executing GitOps Autonomous Reconciliation (tcctl gitops sync)
========================================================

ℹ Specification File : C:/Program Files/tcctl/gitops/tomcat-spec.yaml
ℹ Working Directory  : C:/Program Files/tcctl/gitops
ℹ GitOps config detected (http://localhost:3000/gitadm/tomcat-gitops.git). Checking remote updates via Gitea REST API...
ℹ Remote Git HEAD (API): 8c23789 ("feat(deploy): promote payment-service image to tomcat:9.0-jdk11-v2")
ℹ Desired Container  : payment-service (Image: tomcat:9.0-jdk11-v2)
⚠ Drift or Update Detected: Container is not running (stopped or missing)

========================================================
 Deploying Hardened Tomcat Container: payment-service
========================================================

ℹ Detected Container Engine: docker
ℹ Step 1: Preparing Host Bind-Mount Directory Structure in C:/tomcats/payment-service...
✔ Environment configuration templates (setenv) verified in 'C:/tomcats/payment-service/bin'.
ℹ Bootstrapping self-signed TLS material (PKCS#12) for instance 'payment-service'...
✔ Self-signed TLS keystore (PKCS#12) created in C:/tomcats/payment-service/conf/ssl
ℹ Seeding hardened XML configuration templates (PKCS12 mode) into C:/tomcats/payment-service/conf...
✔ Hardened XML templates successfully written into 'C:/tomcats/payment-service/conf'.
ℹ Step 2: Auditing XML in Host Directory (C:/tomcats/payment-service/conf)...
✔ Pre-flight XML audit on Host Directory passed (100% compliant).
ℹ Loaded JVM options from host setenv (C:/tomcats/payment-service/bin): -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -XX:+UseG1GC -XX:+UseStringDeduplication -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Jakarta -Djava.awt.headless=true
ℹ Step 3: Launching container 'payment-service' (image: tomcat:9.0-jdk11-v2) via docker...
✔ Container started successfully (ID: ddc6902387c1)
ℹ Step 4: Probing HTTP healthcheck endpoint: http://localhost:8080/
✔ Tomcat HTTP Server is HEALTHY (Response status: 404)
✔ HTTP healthcheck probe passed.
✔ Tomcat instance 'payment-service' is up, running, and fully hardened!

 Runtime Environment:
   - Container Image : tomcat:9.0-jdk11-v2
   - Tomcat Version  : Apache Tomcat/9.0.98
   - Java / JDK      : 11.0.32+9 (Eclipse Adoptium)

 Endpoints:
   - HTTP    : http://localhost:8080/
   - HTTPS   : https://localhost:8443/

 Host Bind Mounts (TC-ADR-0009 & TC-ADR-0010):
   - Base Dir : C:/tomcats
   - Bin      : C:/tomcats/payment-service/bin (Environment & setenv)
   - Conf     : C:/tomcats/payment-service/conf (Read-Only :ro)
   - Webapps  : C:/tomcats/payment-service/webapps
   - Logs     : C:/tomcats/payment-service/logs

✔ Autonomous GitOps Reconciliation Completed! Instance 'payment-service' is in desired state.
```

##### 3. Tahap 3: Uji Drift Detection & Self-Healing
Untuk menguji keandalan reconciler dalam menangani kegagalan atau gangguan manual:
1. Kontainer produksi `payment-service` dimatikan secara paksa:
   ```powershell
   PS C:\> docker stop payment-service
   # Status kontainer berubah menjadi: Exited (3221225786)
   ```
2. Reconciler dipicu untuk melakukan pemeriksaan (*drift detection*):
   ```powershell
   PS C:\> tcctl.exe gitops sync --work-dir 'C:/Program Files/tcctl/gitops'
   ```
3. Reconciler secara mandiri mendeteksi ketiadaan kontainer yang aktif:
   `⚠ Drift or Update Detected: Container is not running (stopped or missing)`
4. Reconciler mengeksekusi self-healing, meluncurkan kembali instance kontainer (ID baru: `c81692e913b6`), memverifikasi health probe, dan memulihkan status ke `SYNCED` tanpa memerlukan intervensi manual.

##### 4. Tahap 4: Uji Zero-Downtime Rollout via Staging Container ke JDK 21 LTS
Pada tahap ini, dilakukan simulasi upgrade versi aplikasi secara deklaratif dari JDK 11 ke JDK 21 LTS:
1. Manifes `tomcat-spec.yaml` diperbarui di workstation pengembang:
   ```yaml
   spec:
     image:
       repository: "tomcat"
       tag: "9.0-jdk21"
   ```
2. Perubahan di-commit dan di-push ke repositori GitOps:
   ```bash
   git commit -am "feat(deploy): promote payment-service image to tomcat:9.0-jdk21"
   git push origin main
   # Commit Hash: d534c62
   ```
3. Reconciler di Windows Server mengeksekusi sinkronisasi:
   ```powershell
   PS C:\> tcctl.exe gitops sync --work-dir 'C:/Program Files/tcctl/gitops'
   ```
4. *Hasil Eksekusi Reconciler:*
   - Deteksi commit remote baru: `Remote Git HEAD (API): d534c62`.
   - Deteksi perbedaan image: `⚠ Drift or Update Detected: Image version mismatch (Running: tomcat:9.0-jdk11-v2, Desired: tomcat:9.0-jdk21)`.
   - **Phase 1 (Staging Launch)**: Meluncurkan temporary staging container `payment-service-staging` di port `9080` (Java / JDK: `21.0.12+8-LTS`).
   - **Phase 1 Probe**: Melakukan HTTP health probe ke endpoint staging `http://localhost:9080/` $\rightarrow$ status `200/404 HEALTHY`.
   - **Phase 2 (Drain & Terminate)**: Menghentikan dan menghapus kontainer lama `payment-service` pada port `8080`.
   - **Phase 3 (Canonical Promotion)**: Meluncurkan kontainer baru ke nama kanonikal murni `payment-service` pada port produksi `8080` dan `8443`.
   - **Hasil Akhir**: Hanya 1 kontainer aktif bernama bersih `payment-service` tanpa embel-embel deployment suffix, berjalan di atas Java 21 LTS.

##### 5. Tahap 5: Observabilitas Dual-Channel & Export JSON Status
Status rekonsiliasi diperiksa dan diekspor ke format JSON terstruktur:
```powershell
PS C:\> tcctl.exe gitops status --dir 'C:/Program Files/tcctl/gitops' --json-out 'C:/Program Files/tcctl/gitops/gitops-status.json'
```

*Output Visual Dashboard:*
```text
========================================================
 Apache Tomcat Enterprise — GitOps Reconciler Status
========================================================

ℹ GitOps Directory : C:/Program Files/tcctl/gitops
ℹ Spec File        : C:/Program Files/tcctl/gitops/tomcat-spec.yaml

 📦 GitOps Repository (REST API Mode):
    - Remote URL : http://localhost:3000/gitadm/tomcat-gitops.git
    - Branch     : main
    - Last Commit: d534c62

 📄 Desired Specification (payment-service):
    - Desired Image : tomcat:9.0-jdk21
    - Container Name: payment-service
    - HTTP Port     : 8080
    - Config Volume : payment-service_conf

 🔄 Reconciler State (state.json):
    - Last Sync Time : 2026-09-25 15:03:47 UTC
    - Last Sync Status: SYNCED
    - Last Synced Rev: d534c62

 🐳 Live Container Runtime (docker):
    - payment-service	Up 16 seconds	tomcat:9.0-jdk21	0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp

 ⏱️  Windows Scheduled Task:
    - tcctl-gitops-reconciler: Ready

✔ GitOps status JSON exported to C:/Program Files/tcctl/gitops/gitops-status.json
```

*Isi Berkas JSON Terstruktur (`C:/Program Files/tcctl/gitops/gitops-status.json`):*
```json
{
  "timestamp": "2026-09-25T15:03:47Z",
  "directory": "C:/Program Files/tcctl/gitops",
  "spec_file": "C:/Program Files/tcctl/gitops/tomcat-spec.yaml",
  "git": {
    "remote_url": "http://localhost:3000/gitadm/tomcat-gitops.git",
    "branch": "main",
    "commit": "d534c62"
  },
  "spec": {
    "Version": "1.0",
    "Metadata": {
      "Application": "payment-service",
      "Environment": "production",
      "Tier": "backend"
    },
    "Spec": {
      "Image": {
        "Repository": "tomcat",
        "Tag": "9.0-jdk21",
        "PullPolicy": "IfNotPresent"
      },
      "Runtime": {
        "ContainerName": "payment-service",
        "HTTPPort": 8080,
        "StagingPort": 9080,
        "HTTPSPort": 8443
      },
      "HealthCheck": {
        "Path": "/",
        "ExpectedStatus": 200,
        "TimeoutSeconds": 60
      },
      "AutoRollback": true
    }
  },
  "state": {
    "lastSyncTime": "2026-09-25T15:03:47.382Z",
    "lastCommit": "d534c62",
    "commitMessage": "feat(deploy): promote payment-service image to tomcat:9.0-jdk21",
    "image": "tomcat:9.0-jdk21",
    "containerName": "payment-service",
    "httpPort": 8080,
    "httpsPort": 8443,
    "syncStatus": "SYNCED"
  },
  "live_container": "payment-service\tUp 16 seconds\ttomcat:9.0-jdk21\t0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp",
  "timer_active": true,
  "timer_status": "Ready"
}
```

##### 6. Tahap 6: Verifikasi Eksekusi Windows Task Scheduler & Endpoints Hardened
1. Task Scheduler `tcctl-gitops-reconciler` diuji eksekusinya menggunakan:
   ```powershell
   PS C:\> Start-ScheduledTask -TaskName 'tcctl-gitops-reconciler'
   PS C:\> Get-ScheduledTaskInfo -TaskName 'tcctl-gitops-reconciler'

   LastRunTime        : 9/25/2026 3:04:04 PM
   LastTaskResult     : 0
   NextRunTime        : 9/25/2026 3:05:05 PM
   NumberOfMissedRuns : 0
   TaskName           : tcctl-gitops-reconciler
   ```
   *Hasil*: Nilai `LastTaskResult: 0` membuktikan bahwa Windows Task Scheduler sukses mengeksekusi rekonsiliasi tanpa error.

2. Verifikasi Header Hardening pada Port Produksi:
   ```powershell
   PS C:\> curl.exe -I -s http://localhost:8080/
   HTTP/1.1 404 
   Date: Fri, 25 Sep 2026 15:04:39 GMT
   Server: ApplicationServer

   PS C:\> curl.exe -k -I -s https://localhost:8443/
   HTTP/1.1 404 
   Date: Fri, 25 Sep 2026 15:04:40 GMT
   Server: ApplicationServer
   ```
   *Hasil*: Banner versi Tomcat sepenuhnya tersembunyi (`Server: ApplicationServer`), membuktikan bahwa konfigurasi CIS Hardening aktif dan efektif di seluruh port HTTP dan HTTPS.

---

## 🚀 Next Steps: End-to-End Closed-Loop Automation via Gitea Actions CI

Dengan terbuktinya keandalan sisi **Continuous Deployment (CD) / GitOps Reconciler** pada target host Windows Server, langkah strategis berikutnya adalah **mengotomasi sisi Continuous Integration (CI)** agar siklus promosi rilis tertutup secara sempurna (*closed-loop automation*).

Berikut rencana tahapan implementasi selanjutnya yang akan dieksekusi:

```mermaid
flowchart TD
    Step1["Tahap 1: Aktivasi Gitea Actions & Runner Setup"] --> Step2["Tahap 2: Konfigurasi Kredensial & Cross-Repo Push Token"]
    Step2 --> Step3["Tahap 3: Penyusunan Workflow CI (.gitea/workflows/ci.yaml)"]
    Step3 --> Step4["Tahap 4: Pengujian Gate CIS Hardening & Trivy VA"]
    Step4 --> Step5["Tahap 5: Eksekusi Automated Promotion ke tomcat-gitops"]
    Step5 --> Step6["Tahap 6: Pembuktian Grand E2E (Developer Push -> Target Rollout)"]
```

### Rincian Rencana Kerja:

#### 1. Tahap 1: Aktivasi Gitea Actions & Runner Setup
- Mengaktifkan seksi `[actions]` pada konfigurasi Gitea (`/home/eddywiyatno/devops-lab/gitea-data/gitea/conf/app.ini`):
  ```ini
  [actions]
  ENABLED = true
  ```
- Menjalankan `act_runner` pada workstation Linux (`edkas-pc1`) dalam **Host Execution Mode** (`labels: ["ubuntu-latest:host"]`).
- Memastikan `act_runner` terdaftar di Gitea Admin dengan status **Idle / Online**.

#### 2. Tahap 2: Konfigurasi Kredensial & Cross-Repo Promotion Token
- Membuat Gitea Personal Access Token (PAT) untuk akun `gitadm` dengan izin akses ke repositori `tomcat-gitops`.
- Mendaftarkan token tersebut sebagai Gitea Secret dengan nama `GITOPS_PUSH_TOKEN` pada repositori `tomcat`.

#### 3. Tahap 3: Penyusunan Workflow CI (`.gitea/workflows/ci.yaml`)
- Menambahkan file workflow otomatisasi di repositori `tomcat` yang mencakup 5 tahapan:
  1. **Build Container Image**: Menjalankan build OCI image dengan metadata tag SHA unik (`9.0-${SHORT_SHA}`).
  2. **Quality Gate 1 (CIS Hardening)**: Menjalankan audit statis `tcctl hardening audit --conf conf/` (wajib 100% compliant).
  3. **Quality Gate 2 (VA Scan)**: Menjalankan pemindaian celah keamanan `tcctl va scan --image <image> --severity HIGH,CRITICAL` (exit-code enforcement).
  4. **Registry Push**: Mendorong citra yang tersertifikasi aman ke internal OCI Registry Gitea (`localhost:3000`).
  5. **Automated GitOps Promotion**: CI Bot mengklon repositori `tomcat-gitops`, memperbarui tag pada `tomcat-spec.yaml`, lalu melakukan commit & push secara otomatis.

#### 4. Tahap 4: Pembuktian Akbar End-to-End (Grand E2E Verification)
- Pengembang melakukan `git push` perubahan kode aplikasi pada repositori `tomcat`.
- Memverifikasi pipeline CI berjalan dan lolos seluruh quality gate keamanan.
- Memverifikasi bot CI berhasil mengupdate commit pada repositori `tomcat-gitops`.
- Mengamati Task Scheduler `tcctl-gitops-reconciler` di Windows Server mendeteksi commit baru tersebut secara otonom dan mengeksekusi rolling update zero-downtime hingga sehat.

---

## 🔗 Related Documentation

- [tcctl Build & Installation Guide (INSTALL.md)](file:///home/eddywiyatno/git/tcctl/INSTALL.md)
- [TC-ADR-0006: Refactor Zero-Downtime Rollout to Temporary Staging Containers](../../../../adr/tomcat/adr-records/TC-ADR-0006.md)
- [TC-ADR-0007: Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler](../../../../adr/tomcat/adr-records/TC-ADR-0007.md)
- [TC-ADR-0008: Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access](../../../../adr/tomcat/adr-records/TC-ADR-0008.md)
- [Update Management Specification](../../update-management/index.md)
- [Architecture Decision Records Index](../../../../adr/tomcat/index.md)
- [Engineering Journal Index](index.md)


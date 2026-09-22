# Update Management Specification

## 🔍 Overview

Spesifikasi **Manajemen Update** mengatur tata kelola patching berkala, pembaruan base image, dan rilis versi aplikasi tanpa menghentikan ketersediaan layanan (*zero-downtime deployment*) serta arsitektur **Pure Pull-Based GitOps** pada armada Apache Tomcat Enterprise.

---

## 🔄 Strategi Rollout: Temporary Staging Container & Atomic Promotion

Berdasarkan [TC-ADR-0006](../../../adr/tomcat/adr-records/TC-ADR-0006.md), arsitektur zero-downtime deployment pada operator `tcctl` tidak lagi menggunakan slot permanen bergantian dengan akhiran statis (`<name>-blue` dan `<name>-green`). Sebagai gantinya, pembaruan menggunakan mekanisme **Temporary Staging Container (`<name>-staging`)** dengan promosi nama kanonikal (`<name>`) secara atomik:

```
 1. Kondisi Awal:
    [Edge / Reverse Proxy] ----> [tomcat-app (Active :8080)]

 2. Deploy Staging & Pre-Flight Probe:
    [Edge / Reverse Proxy] ----> [tomcat-app (Active :8080)]
                                 [tomcat-app-staging (Standby :9080)] <--- Health Polling (max 60s)

 3. Atomic Promotion & Switchover:
    a. Hentikan kontainer lama: podman stop tomcat-app (Graceful SIGTERM)
    b. Hapus kontainer lama: podman rm tomcat-app
    c. Hentikan staging sementara: podman stop tomcat-app-staging
    d. Luncurkan kontainer baru dengan nama kanonikal: tomcat-app (:8080)
    e. Bersihkan staging: podman rm tomcat-app-staging

 4. Kondisi Akhir:
    [Edge / Reverse Proxy] ----> [tomcat-app (Active :8080)] (Versi Baru, Nama Bersih!)
```

### Keuntungan Dibandingkan Suffix Permanen:
- **Nama Bersih dan Stabil**: Kontainer produksi aktif selalu bernama kanonikal `<name>` (misalnya `payment-service`), memudahkan pelacakan log, metrik Prometheus, dan pemeliharaan filter `podman ps`.
- **Ephemeral Staging**: Kontainer staging `<name>-staging` hanya hidup beberapa puluh detik selama masa validasi kesehatan (*warmup*).

---

## 🚀 Arsitektur Pure Pull-Based GitOps (Day-2 Ongoing)

Sesuai [TC-ADR-0007](../../../adr/tomcat/adr-records/TC-ADR-0007.md), siklus deployment berkelanjutan mengadopsi standar **Pure Pull-Based GitOps**:

1. **Git Sebagai Single Source of Truth**: Seluruh konfigurasi runtime dideklarasikan dalam file `tomcat-spec.yaml` di repositori Git terpusat.
2. **Autonomous Host Reconciler**: Setiap host target menjalankan biner operator `tcctl gitops sync` secara berkala via `systemd --user timer` (default interval: 5 menit).
3. **Zero Inbound SSH Footprint**: Server target tidak membuka port SSH (Port 22) ke server CI (Jenkins / GitLab CI) atau Ansible Controller. Komunikasi murni berupa *outbound HTTPS pull* ke Git repository dan OCI Container Registry.
4. **Automated Drift Healing**: Jika kontainer mengalami perubahan konfigurasi manual di luar Git atau berhenti secara tidak sengaja, reconciler secara otonom mengembalikan kondisi kontainer ke spesifikasi yang dideklarasikan di Git.

```mermaid
flowchart LR
    Git["GitOps Repo\n(tomcat-spec.yaml)"] -->|HTTPS Pull (5m)| Timer["systemd --user timer\n(tcctl gitops sync)"]
    Timer --> Reconciler{"Perbedaan / Drift\nTerdeteksi?"}
    Reconciler -- Ya --> Pull["podman pull new image"]
    Pull --> Rollout["tcctl deploy rollout\n(Staging -> Canonical)"]
    Rollout --> Done["State Synced\n(Audit Logged)"]
    Reconciler -- Tidak --> Sleep["Idle until next tick"]
```

---

## 🔑 Day-1 Bootstrapping: Self-Destructing Ephemeral SSH Access

Sesuai [TC-ADR-0008](../../../adr/tomcat/adr-records/TC-ADR-0008.md), untuk VM yang sudah terbentuk (*brownfield*), instalasi awal biner `tcctl` dan timer GitOps diselesaikan menggunakan pola **Self-Destructing Ephemeral SSH Access**:

1. **Injeksi Kunci Sementara**: Ansible atau administrator menginjeksikan public key bertanda khusus ke `~/.ssh/authorized_keys` di VM target:
   ```
   ssh-rsa AAAAB3NzaC1... # ephemeral-day1-bootstrap
   ```
2. **Eksekusi Otomasi Bootstrap**:
   - Memasang biner statis `tcctl` ke `~/.local/bin/` atau `/usr/local/bin/`.
   - Menginisialisasi Engine Runtime Named Volumes (`_conf`, `_webapps`, `_logs`) dengan permission `0755` (dir) dan `0644` (file) agar terbaca oleh non-root user `tomcat` (UID 1001).
   - Menghasilkan dan mengaktifkan unit `tcctl-gitops.service` dan `tcctl-gitops.timer`.
3. **Pemusnahan Kunci Diri Sendiri (*Self-Purge*)**:
   - Pada baris terakhir proses instalasi, skrip mengeksekusi:
     ```bash
     sed -i '/# ephemeral-day1-bootstrap/d' ~/.ssh/authorized_keys
     ```
   - Kunci terhapus seketika. Upaya koneksi SSH berikutnya langsung ditolak (`Permission denied`).
   - Host target resmi beralih 100% menjadi otonom (*autonomous Day-2 GitOps*).

---

## 🛑 Penanganan Graceful Shutdown

Saat container dihentikan atau di-rollout, proses Tomcat tidak boleh dimatikan secara mendadak (`kill -9`). 

* **Konfigurasi `server.xml`**:
  ```xml
  <Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true" unloadDelay="10000">
  ```
  `unloadDelay="10000"` memberi toleransi waktu hingga 10 detik bagi servlet untuk menyelesaikan request yang sedang berjalan sebelum context di-destroy.
* **Penanganan Sinyal di `entrypoint.sh`**:
  Entrypoint script mengimplementasikan perangkap sinyal (`trap 'kill -TERM $PID' TERM INT`) sehingga sinyal `SIGTERM` dari Podman diteruskan dengan aman ke JVM Tomcat.

---

## ⏪ Mekanisme Instant Rollback

Jika temporary staging container (`<name>-staging`) gagal merespons HTTP 200 pada interval verifikasi (misal: timeout 60 detik pasca-start):
1. Reconciler `tcctl` mendeteksi kegagalan pre-flight healthcheck probe.
2. Alur rollout dibatalkan seketika.
3. Kontainer staging yang gagal langsung dihentikan dan dihapus (`podman rm -f <name>-staging`).
4. Kontainer produksi utama `<name>` **tetap berjalan tanpa interupsi sedikit pun**.
5. Kesalahan dicatat pada audit log journald dan status commit GitOps ditandai sebagai `Rollback / Failed Verification`.

---

## 🔗 Related Documentation & Records

- [TC-ADR-0006: Refactor Zero-Downtime Rollout to Temporary Staging Containers](../../../adr/tomcat/adr-records/TC-ADR-0006.md)
- [TC-ADR-0007: Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler](../../../adr/tomcat/adr-records/TC-ADR-0007.md)
- [TC-ADR-0008: Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access](../../../adr/tomcat/adr-records/TC-ADR-0008.md)
- [TN-004: Design Pure Pull-Based GitOps, Temporary Staging Rollout, and Self-Destructing Bootstrap](../engineering-journal/platform-foundation-and-hardening/TN-004-design-pure-pull-based-gitops-temporary-staging-rollout-and-self-destructing-bootstrap.md)

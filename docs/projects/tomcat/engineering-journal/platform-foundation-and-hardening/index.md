# Platform Foundation & Hardening Engineering Journal

## 🔍 Overview

Fase **Platform Foundation & Hardening** mencatat pembangunan fondasi awal untuk Apache Tomcat Enterprise. Pekerjaan difokuskan pada perancangan arsitektur kontainer murni (*pure greenfield container*), eliminasi beban migrasi VM tradisional, penguatan keamanan (*hardening*) berbasis CIS Apache Tomcat Benchmark, pengembangan multi-platform operator CLI (`tcctl`) berbasis bahasa Go, serta validasi decoupling konfigurasi menggunakan Engine Runtime Named Volumes (`podman volume`).

## 🎯 Objective

Membangun fondasi platform Apache Tomcat Enterprise yang aman, terstandarisasi, dan siap produksi dengan:

1. Menolak pendekatan migrasi VM tradisional dan mengadopsi Greenfield Hardened OCI Container (`Containerfile` dengan unprivileged user `tomcat` UID `1001`, read-only rootfs, noexec tmpfs, dan capability drop).
2. Mengimplementasikan dan memverifikasi 9 aturan inti CIS Apache Tomcat Benchmark pada konfigurasi XML (`server.xml`, `context.xml`, `web.xml`).
3. Mengembangkan unified multi-platform operator CLI (`tcctl`) dalam bahasa Go 1.23+ yang mengompilasi biner statis mandiri untuk Linux (`bin/tcctl`) dan Windows (`bin/tcctl.exe`).
4. Mengadopsi Engine Runtime Named Volumes (`podman volume`) dengan injeksi konfigurasi read-only (`:ro`), serta memvalidasi kemampuan audit offline pada physical mount point host.
5. Memverifikasi seluruh stack secara live pada Rootless Podman runtime dengan waktu startup < 30ms dan status kepatuhan CIS 100%.

## 🛠️ Implementation Result

| Komponen / Area | Implementasi | Status |
| --- | --- | --- |
| **Container Architecture** | Hardened `Containerfile`, unprivileged user `tomcat` UID 1001, root-owned binary `750/640`, read-only root filesystem, tmpfs `/tmp` dan `/work`. | Completed |
| **CIS XML Hardening** | Port shutdown `-1`, server banner obfuscation, `ErrorReportValve`, disable AJP, global `HttpHeaderSecurityFilter`, restriksi method `TRACE`, `httpOnly`, `sameSiteCookies="lax"`. | Completed |
| **Security Audit Automation** | Shell script validator `scripts/audit-cis.sh` (8/8 checks passed, 100% compliant). | Completed |
| **Multi-Platform Operator CLI** | Go codebase (`/home/eddywiyatno/git/tcctl`), subcommands `hardening`, `va`, `monitoring`, `deploy`. Standalone static binaries `bin/tcctl` & `bin/tcctl.exe`. | Completed |
| **Engine Runtime Named Volumes** | Decoupling state menggunakan named volume (`_conf:ro,Z`, `_webapps:Z`, `_logs:Z`). Auto-seeding templates & offline host mountpoint inspection terverifikasi. | Completed |
| **Vulnerability Assessment** | Trivy security scanner integration (`scripts/scan.sh` & `tcctl va scan`) dengan automated quality gate. | Completed |
| **Observability & Deploy** | Synthetic HTTP health probe, JMX metrics parser, dan Blue-Green deployment runner dengan automated rollback. | Completed |
| **Pure GitOps & Staging Rollout** | Arsitektur Pure Pull-Based GitOps (`tcctl gitops sync` via `systemd --user timer`), refactoring temporary staging container rollout (`<name>-staging` -> `<name>`), dan Day-1 self-destructing bootstrap key. | Design Accepted |
| **Windows Container & Operator Testing** | Provisioning Windows Containers di Windows Server 2022 AWS, instalasi Docker CE v27.5.1, Tooling PATH, dan validasi live `tcctl.exe` (Audit CIS & SSL check). | Completed |

## 📄 Technical Notes

1. **[TN-001 — Architect Pure Container Model and Security Hardening](TN-001-architect-pure-container-model-and-security-hardening.md)**

    Mencatat penolakan migrasi VM legacy, perancangan Greenfield Hardened OCI Container, implementasi 9 parameter CIS XML hardening, dan pembuktian live runtime Podman (28ms startup, read-only rootfs, 100% compliance).

2. **[TN-002 — Implement Cross-Platform Operator tcctl and Runtime Volume Architecture](TN-002-implement-cross-platform-operator-tcctl-and-runtime-volume-architecture.md)**

    Mencatat konsolidasi tooling ke repositori baru `tcctl` berbasis Go, kompilasi multi-platform (Linux & Windows), adopsi Engine Runtime Named Volumes (Opsi 2), dan validasi audit offline pada host volume mountpoint saat kontainer off.

3. **[TN-003 — Implement SSL/TLS Management and Native PEM Connector](TN-003-implement-ssl-tls-management-and-native-pem-connector.md)**

    Mencatat penyelesaian Pilar 6: konfigurasi konektor HTTPS native OpenSSL PEM di port 8443, pembuatan sertifikat self-signed, pembuatan CSR untuk CA eksternal, validasi kesesuaian kunci, dan quality gate kadaluarsa pada `tcctl`.

4. **[TN-004 — Design Pure Pull-Based GitOps, Temporary Staging Rollout, and Self-Destructing Bootstrap](TN-004-design-pure-pull-based-gitops-temporary-staging-rollout-and-self-destructing-bootstrap.md)**

    Mencatat blueprint arsitektur transformasi operasional enterprise: refactoring zero-downtime rollout dengan temporary staging container (`<name>-staging`) dan promosi nama kanonikal (`<name>`), adopsi Pure Pull-Based GitOps otonom via `systemd --user timer`, dan penyelesaian paradoks Day-1 brownfield bootstrapping melalui self-destructing ephemeral SSH access.

5. **[TN-005 — Verify Windows Container Runtime Provisioning and tcctl Operator Testing](TN-005-verify-windows-container-runtime-provisioning-and-tcctl-operator-testing.md)**

    Mencatat sinkronisasi repositori berdampingan ke host Windows Server 2022 di AWS EC2, provisioning runtime Windows Containers dan Docker Engine Community Edition, penyediaan tooling Git dan Trivy, pengujian live biner `tcctl.exe` (Audit CIS dan SSL volume check), serta rekapitulasi analisis akar masalah dan solusi teknis selama instalasi.

!!! note "Phase Output"

    Fase ini menghasilkan dua repositori operasional yang telah terverifikasi penuh:
    
    - Repositori `tomcat` (`/home/eddywiyatno/git/tomcat`): Berisi hardened `Containerfile`, baseline XML configurations di `conf/` (termasuk native PEM connector 8443), sample webapps, serta skrip otomasi CIS audit, Trivy scan, dan Blue-Green deployment.
    - Repositori `tcctl` (`/home/eddywiyatno/git/tcctl`): Berisi codebase Go 1.23+ dan biner mandiri `bin/tcctl` (Linux) serta `bin/tcctl.exe` (Windows) dengan kapabilitas hardening audit, volume management, vulnerability quality gate, synthetic health monitoring, SSL/TLS lifecycle (self-signed, CSR, setup, check), dan deployment orchestration.

## 🎓 Lessons Learned

- **Digester Rules Precedence**: Filter keamanan HTTP (`HttpHeaderSecurityFilter`) pada Apache Tomcat adalah Servlet Filter (`conf/web.xml`), bukan Valve pada `conf/server.xml`. Memasukkannya sebagai Valve akan menggagalkan startup parser Catalina.
- **Rootless Podman Tmpfs Permissions**: Pada Rootless Podman, flag tmpfs tidak boleh menggunakan opsi numerik host `uid=1001`, melainkan harus menggunakan `mode=1777` agar proses unprivileged di dalam user namespace kontainer memiliki akses tulis yang valid.
- **Offline Storage Inspectability**: Engine Runtime Named Volumes (`podman volume`) menyimpan data fisik di path host (`~/.local/share/containers/storage/volumes/<vol>/_data/`), memungkinkan audit statis dan seeding konfigurasi dilakukan tanpa perlu menjalankan kontainer terlebih dahulu.
- **Cross-Platform Go Portability**: Mengembangkan operator CLI dengan Go menghasilkan biner statis mandiri (`CGO_ENABLED=0`) tanpa dependensi interpreter eksternal, menghilangkan beban sinkronisasi antara Bash dan PowerShell.
- **Native OpenSSL PEM vs Keystore**: Tomcat 9.0+ mendukung file PEM standar secara natif melalui Apache Tomcat Native library, mengeliminasi kebutuhan konversi Java Keystore (`.jks`) dan mempermudah otomasi dengan Corporate CA atau Let's Encrypt.
- **GitOps Orthodoxy on VMs**: Menjalankan skrip push via SSH dari CI/Ansible ke host target bukanlah GitOps, melainkan Scripted Push. GitOps sejati mensyaratkan target reconciler otonom (`tcctl gitops sync`) yang menarik manifes secara periodik, menjamin zero-inbound network footprint dan pemulihan deviasi (*self-healing*) otomatis.
- **The Self-Destructing Bootstrap Pattern**: Mengatasi paradoks instalasi Day-1 pada brownfield VM dapat diselesaikan dengan menyertakan instruksi `sed -i` pembersihan kunci SSH pada baris terakhir skrip instalasi, memusnahkan kredensial sementara tanpa memerlukan intervensi manual tambahan.
- **Clean Container Naming**: Penggunaan suffix `-blue`/`-green` secara permanen membingungkan operator dan sistem monitoring. Mekanisme temporary staging container (`<name>-staging`) memungkinkan promosi nama kanonikal (`<name>`) secara mulus pasca-verifikasi readiness probe.
- **Windows Containers Network & Storage Portability**: Arsitektur Windows Containers menggunakan driver jaringan NAT HNS (bukan bridge) dan direktori volume fisik pada `C:\ProgramData\docker\volumes\<name>\_data`. Biner `tcctl.exe` terbukti mampu menginspeksi dan memverifikasi kriptografi volume secara offline pada Windows.

## 🔗 Related Documentation

- [Apache Tomcat Enterprise Overview](../../index.md)
- [Architecture & Security Boundary](../../architecture/index.md)
- [Security Hardening Guide](../../security-hardening/index.md)
- [Vulnerability Assessment Guide](../../vulnerability-assessment/index.md)
- [Update Management Guide](../../update-management/index.md)
- [SSL Management Guide](../../ssl-management/index.md)
- [TC-ADR-0001: Greenfield Container Architecture](../../../../adr/tomcat/adr-records/TC-ADR-0001.md)
- [TC-ADR-0002: CIS XML Hardening Quality Gate](../../../../adr/tomcat/adr-records/TC-ADR-0002.md)
- [TC-ADR-0003: Engine Runtime Named Volumes](../../../../adr/tomcat/adr-records/TC-ADR-0003.md)
- [TC-ADR-0004: Unified Go Operator tcctl](../../../../adr/tomcat/adr-records/TC-ADR-0004.md)
- [TC-ADR-0005: Native OpenSSL PEM Connector & TLS Lifecycle](../../../../adr/tomcat/adr-records/TC-ADR-0005.md)
- [TC-ADR-0006: Refactor Zero-Downtime Rollout to Temporary Staging Containers](../../../../adr/tomcat/adr-records/TC-ADR-0006.md)
- [TC-ADR-0007: Adoption of Pure Pull-Based GitOps via Autonomous Host Reconciler](../../../../adr/tomcat/adr-records/TC-ADR-0007.md)
- [TC-ADR-0008: Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access](../../../../adr/tomcat/adr-records/TC-ADR-0008.md)


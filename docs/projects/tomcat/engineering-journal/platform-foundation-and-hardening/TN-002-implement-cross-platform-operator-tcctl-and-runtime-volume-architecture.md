# TN-002 — Implement Cross-Platform Operator tcctl and Runtime Volume Architecture

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Apache Tomcat Enterprise |
| Phase | Platform Foundation & Hardening |
| Activity Date | 2026-09-21 |
| Recorded Date | 2026-09-21 |
| Owner | Project owner |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-09-21 |

## 🎯 Objective

Mengembangkan operator CLI terpadu (*unified operator*) multi-platform bernama **`tcctl`** menggunakan bahasa pemrograman Go 1.23+, mengompilasi biner statis mandiri untuk platform Linux dan Windows, mengintegrasikan manajemen Engine Runtime Named Volumes (`podman volume` / `docker volume`) dengan injeksi konfigurasi read-only (`:ro`), serta memverifikasi kemampuan audit kepatuhan CIS secara offline langsung pada host storage mountpoint saat kontainer dalam keadaan tidak aktif (*off*).

## 🌍 Background

Setelah arsitektur dasar kontainer Tomcat ter-hardening divalidasi pada TN-001, otomasi pengelolaan masih tersebar dalam beberapa skrip shell Bash (`audit-cis.sh`, `scan.sh`, `deploy-bluegreen.sh`). Pendekatan ini memiliki sejumlah kelemahan untuk skala enterprise:
1. Tidak dapat dijalankan secara langsung pada host sistem operasi Windows Server tanpa layer emulasi (WSL/Cygwin).
2. Ketergantungan pada utilitas parsing XML host yang perilakunya dapat berbeda antar distribusi Linux.
3. Diskusi pemilihan strategi storage menyepakati adopsi **Opsi 2 (Engine Runtime Named Volumes)** dibanding host bind-mounts langsung. Pengguna secara spesifik mengonfirmasi bahwa named volume tetap dapat diakses dan diinspeksi fisiknya pada host storage (`~/.local/share/containers/storage/volumes/<vol>/_data/`) bahkan saat kontainer dalam kondisi mati.
4. Repositori lama `tmctl` disepakati untuk tidak disentuh atau dimodifikasi, melainkan fungsinya ditransformasikan dan diperluas ke dalam repositori baru `tcctl` pada branch `lab`.

## 📚 Scope

Pekerjaan pada Technical Note ini mencakup:

- Inisialisasi repositori Git baru `/home/eddywiyatno/git/tcctl` pada branch `lab` (memastikan repositori `tmctl` tetap utuh tanpa perubahan).
- Rancang bangun arsitektur Go modular:
  - `internal/volume`: Engine detection (Podman/Docker), volume create, inspect physical mountpoint, dan template auto-seeding.
  - `internal/hardening`: XML parser berbasis Go standard library untuk mengaudit 9 aturan CIS Benchmark dan generator template.
  - `internal/va`: Trivy runner dengan compliance report generator (JSON & Terminal).
  - `internal/monitoring`: Synthetic HTTP health probe dan Prometheus JMX metrics scraper.
  - `internal/orchestrator`: Blue-Green deployment runner dengan runtime named volume mounts.
- Kompilasi biner statis mandiri lintas platform (`bin/tcctl` untuk Linux ELF amd64 dan `bin/tcctl.exe` untuk Windows PE amd64).
- Pengujian live terhadap volume engine `podman volume`: inspeksi host mount point dan eksekusi audit offline dengan status kontainer mati.

## ⚖️ Execution Decision

Aktivitas ini mengimplementasikan keputusan arsitektur berikut:

- [TC-ADR-0003: Decouple Configuration State Using Engine Runtime Named Volumes with Read-Only Mounts](../../../../adr/tomcat/adr-records/TC-ADR-0003.md)
- [TC-ADR-0004: Consolidate Multi-Platform Lifecycle and Hardening Governance into Unified Go Operator (tcctl)](../../../../adr/tomcat/adr-records/TC-ADR-0004.md)

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Initialize Repository tcctl** | Menginisialisasi repositori Git baru di `/home/eddywiyatno/git/tcctl` pada branch `lab`. |
| **Implement Engine Volume Management** | Mengembangkan modul `internal/volume` untuk inspeksi dan seeding volume runtime. |
| **Implement CIS Hardening Subsystem** | Mengembangkan parser XML dan engine evaluasi aturan CIS di `internal/hardening`. |
| **Implement Vulnerability, Monitoring, & Deploy** | Mengembangkan paket `va`, `monitoring`, dan `orchestrator`. |
| **Compile Multi-Platform Static Binaries** | Membangun biner Linux amd64 dan Windows amd64 melalui `Makefile`. |
| **Verify Offline Volume Inspection & CIS Audit** | Menguji pembacaan mount point host dari named volume Podman dan memverifikasi kepatuhan CIS 100%. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Initialize Repository tcctl

Repositori baru diinisialisasi secara mandiri dengan branch `lab`:

```bash
mkdir -p /home/eddywiyatno/git/tcctl
cd /home/eddywiyatno/git/tcctl
git init -b lab
go mod init tcctl
```

Repositori `/home/eddywiyatno/git/tmctl` diverifikasi tidak mengalami perubahan apapun.

</div>

<div class="procedure-step" markdown>

### Implement Engine Volume Management

Paket `internal/volume/volume.go` diimplementasikan dengan fungsi:
- `DetectEngine()`: Mendeteksi ketersediaan runtime `podman` (prioritas utama) atau `docker`.
- `GetVolumeMountpoint(volName)`: Menjalankan `podman volume inspect <name> --format '{{.Mountpoint}}'` untuk mendapatkan path host absolut (misal: `/home/eddywiyatno/.local/share/containers/storage/volumes/<name>/_data`).
- `EnsureVolumeWithHardenedTemplates(volName)`: Membuat volume bila belum ada dan menginjeksi file template XML ter-hardening (`server.xml`, `context.xml`, `web.xml`) jika volume masih kosong.

</div>

<div class="procedure-step" markdown>

### Implement CIS Hardening Subsystem

Paket `internal/hardening/` dibangun dengan model Go XML:
- `auditor.go`: Menguji 9 aturan spesifik CIS:
  1. Shutdown port disabled (`port="-1"`)
  2. Server banner obfuscated
  3. `ErrorReportValve` aktif dengan `showReport="false"` & `showServerInfo="false"`
  4. AJP Connector disabled / absent
  5. `HttpHeaderSecurityFilter` aktif pada `web.xml`
  6. HTTP TRACE method diblokir pada `web.xml`
  7. Cookie `useHttpOnly="true"` aktif pada `context.xml`
  8. Cookie `sameSiteCookies="lax"` aktif pada `context.xml`
  9. File permissions restricted (verifikasi direktori `750` dan file `640` milik `root:tomcat`)
- Mendukung flag `--dir` (path lokal) dan `--volume` (nama named volume engine).

</div>

<div class="procedure-step" markdown>

### Implement Vulnerability, Monitoring, & Deploy

1. `internal/va/`:
   - `scanner.go`: Memanggil Trivy CLI dengan parameter output JSON/tabel.
   - `report.go`: Evaluasi thresholding CVE untuk quality gate CI/CD.
2. `internal/monitoring/`:
   - `health.go`: HTTP client untuk probe `/health` dengan timeout konfiguratif.
   - `metrics.go`: HTTP client untuk mem-parse endpoint Prometheus `/metrics`.
3. `internal/orchestrator/`:
   - `runner.go`: Membentuk argumen container runtime dengan named volumes:
     `-v <instance>_conf:/usr/local/tomcat/conf:ro,Z`
     `-v <instance>_webapps:/usr/local/tomcat/webapps:Z`
     `-v <instance>_logs:/usr/local/tomcat/logs:Z`
     ditambah opsi isolasi `--read-only`, `--cap-drop=ALL`, dan `--tmpfs`.
   - `bluegreen.go`: Orkestrator transisi container Blue ke Green dengan automated rollback.

</div>

<div class="procedure-step" markdown>

### Compile Multi-Platform Static Binaries

Disusun `Makefile` dengan target build cross-platform (`CGO_ENABLED=0`):

```bash
make build-all
```

Menghasilkan:
- `bin/tcctl`: Linux ELF 64-bit x86-64 statically linked
- `bin/tcctl.exe`: Windows PE32+ executable x86-64 console

</div>

<div class="procedure-step" markdown>

### Verify Offline Volume Inspection & CIS Audit

Pengujian live dilakukan dengan membuat named volume Podman `test-audit_conf`, menginisialisasi template XML hardening, dan mengauditnya secara offline menggunakan flag `--volume`:

```bash
./bin/tcctl hardening audit --volume test-audit_conf
```

</div>

</div>

## 🧪 Verification

### 1. Multi-Platform Binary Verification

Pemeriksaan jenis artefak biner hasil kompilasi:

```bash
file bin/tcctl bin/tcctl.exe
# Output:
# bin/tcctl:     ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=..., stripped
# bin/tcctl.exe: PE32+ executable (console) x86-64 (stripped to external PDB), for MS Windows, 11 sections
```

### 2. Live Offline Volume Inspection & CIS Audit

Eksekusi `./bin/tcctl hardening audit --volume test-audit_conf` membuktikan bahwa `tcctl` berhasil mendeteksi engine `podman`, menginspeksi host physical mount point volume tanpa kontainer yang berjalan, dan memvalidasi seluruh 9 parameter CIS:

```text
Inspecting Podman volume: test-audit_conf
Host mountpoint: /home/eddywiyatno/.local/share/containers/storage/volumes/test-audit_conf/_data
Auditing directory: /home/eddywiyatno/.local/share/containers/storage/volumes/test-audit_conf/_data
Loaded 3 XML files for auditing.
[PASS] Shutdown port is disabled (port="-1")
[PASS] Server banner is obfuscated (server="ApplicationServer")
[PASS] ErrorReportValve is configured to hide stack traces and server info
[PASS] AJP Connector is disabled or not present
[PASS] HttpHeaderSecurityFilter is configured in web.xml
[PASS] HTTP TRACE method is restricted in web.xml
[PASS] Session cookie useHttpOnly is enabled in context.xml
[PASS] Session cookie sameSiteCookies is configured in context.xml
[PASS] Directory permissions are secure (owner=root, perms<=750)

==================================================
Total Checks : 9
Passed       : 9
Failed       : 0
Compliance   : 100.0%
Result       : AUDIT PASSED - All CIS hardening rules compliant!
==================================================
```

### 3. CLI Subcommand Output

Verifikasi banner dan subcommands:

```text
tcctl - Apache Tomcat Enterprise Operator CLI
Version: 1.0.0
Git Commit: 4469203
Built: 2026-09-21T14:13:56Z
Engine: podman (version 4.9.3)
```

## 🧾 Outcome

- Operator CLI `tcctl` berhasil diimplementasikan penuh dalam bahasa Go 1.23+, menghasilkan biner mandiri untuk Linux dan Windows.
- Arsitektur Engine Runtime Named Volumes (Opsi 2) berhasil diwujudkan: konfigurasi diinjeksikan secara read-only (`:ro`), sementara host physical mount point dapat diakses secara instan saat kontainer mati untuk keperluan audit statis pre-flight.
- Repositori `tmctl` lama tetap terjaga tanpa modifikasi apapun.
- Repositori `tcctl` telah terinisialisasi dan ter-commit pada branch `lab` (commit `4469203`).

## 🎓 Lessons Learned

1. **Volume Mountpoint Transparency**: Path host rootless Podman pada `~/.local/share/containers/storage/volumes/<vol>/_data` memberikan fleksibilitas penuh untuk melakukan operasi filesystem langsung tanpa overhead container bootstrap.
2. **Go Cross-Compilation Efficiency**: Penggunaan Go standard library murni (`CGO_ENABLED=0`) memungkinkan kompilasi biner Windows (`.exe`) dari lingkungan Linux dalam hitungan 2 detik tanpa toolchain mingw tambahan.

## ⏭️ Next Steps

- Mendaftarkan arsitektur dan jurnal engineering ini ke dalam DevOps Handbook.
- Meninjau tata kelola `AGENTS.md` dan `.gitignore` di seluruh ekosistem repositori.

## 🔗 Related Documentation

- [Phase 1 Index](index.md)
- [TN-001: Architect Pure Container Model and Security Hardening](TN-001-architect-pure-container-model-and-security-hardening.md)
- [TC-ADR-0003: Engine Runtime Named Volumes](../../../../adr/tomcat/adr-records/TC-ADR-0003.md)
- [TC-ADR-0004: Unified Go Operator tcctl](../../../../adr/tomcat/adr-records/TC-ADR-0004.md)
- [Update Management Guide](../../update-management/index.md)

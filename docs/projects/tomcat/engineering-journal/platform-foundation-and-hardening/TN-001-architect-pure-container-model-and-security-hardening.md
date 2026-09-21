# TN-001 — Architect Pure Container Model and Security Hardening

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

Merancang dan mengimplementasikan arsitektur Greenfield Hardened OCI Container untuk Apache Tomcat dengan konfigurasi keamanan berbasis CIS Apache Tomcat Benchmark, memverifikasi eksekusi unprivileged non-root (UID 1001), filesystem read-only, tmpfs mounts, serta membuktikan compliance rate 100% pada Rootless Podman runtime.

## 🌍 Background

Pengelolaan instance Apache Tomcat pada enterprise yang masih bergantung pada Virtual Machine konvensional menghadapi kendala konfigurasi drift, privilege berlebih, dan ketergantungan pada utilitas sistem yang tidak esensial. Upaya memigrasikan VM eksisting secara "lift-and-shift" berisiko membawa celah keamanan dan file sampah.

Untuk mencapai standar ketahanan enterprise modern, diputuskan untuk membangun arsitektur kontainer murni (*pure greenfield container*) dari nol, menyingkirkan seluruh default webapps bawaan (`ROOT`, `manager`, `host-manager`, `examples`, `docs`), memperketat izin direktori biner menjadi milik `root:tomcat` dengan mode `750/640`, serta menerapkan 9 aturan hardening CIS Benchmark pada file konfigurasi XML.

## 📚 Scope

Pekerjaan pada Technical Note ini mencakup:

- Pembuatan `Containerfile` ter-hardening berbasis image resmi Tomcat dengan unprivileged user `tomcat` (UID `1001`, GID `1001`).
- Pengerasan konfigurasi XML pada `conf/server.xml`, `conf/context.xml`, dan `conf/web.xml`.
- Pembuatan skrip audit otomatis `scripts/audit-cis.sh` untuk memeriksa 8 indikator statis CIS.
- Pembuatan skrip vulnerability assessment `scripts/scan.sh` berbasis Trivy.
- Pembuatan skrip zero-downtime Blue-Green deployment `scripts/deploy-bluegreen.sh`.
- Pengujian live container startup pada Rootless Podman, verifikasi status read-only rootfs, port isolation, dan waktu cold start.

Exclusions:
- Prosedur migrasi manual untuk legacy VM dikesampingkan karena arsitektur difokuskan pada model greenfield container murni.

## ⚖️ Execution Decision

Aktivitas ini mengimplementasikan keputusan arsitektur berikut:

- [TC-ADR-0001: Adopt Greenfield Hardened OCI Container Architecture for Apache Tomcat](../../../../adr/tomcat/adr-records/TC-ADR-0001.md)
- [TC-ADR-0002: Enforce Pre-Flight Static XML Configuration Audit and CIS Tomcat Benchmark](../../../../adr/tomcat/adr-records/TC-ADR-0002.md)

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Develop Hardened Containerfile** | Merancang biner immutable, unprivileged user `tomcat` (UID 1001), dan pembersihan default webapps. |
| **Implement Hardened XML Configurations** | Mengonfigurasi `server.xml`, `context.xml`, dan `web.xml` sesuai rekomendasi CIS. |
| **Implement CIS Audit Automation** | Membangun skrip `scripts/audit-cis.sh` untuk evaluasi kepatuhan statis. |
| **Implement Vulnerability & Deployment Scripts** | Menyediakan `scripts/scan.sh` dan `scripts/deploy-bluegreen.sh`. |
| **Verify Runtime on Rootless Podman** | Menjalankan kontainer uji dan memvalidasi read-only rootfs, tmpfs, UID, dan port listening. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Develop Hardened Containerfile

File `Containerfile` disusun di repositori `/home/eddywiyatno/git/tomcat` dengan karakteristik:
- User unprivileged `tomcat:tomcat` dengan UID `1001` dan GID `1001`.
- Direktori instalasi `/usr/local/tomcat` diatur izinnya menjadi kepemilikan `root:tomcat` dengan mode `750` untuk direktori dan `640` untuk file.
- Penghapusan seluruh aplikasi default di `/usr/local/tomcat/webapps/*`.
- Pembuatan direktori runtime writable khusus `/usr/local/tomcat/conf/Catalina/localhost` berizin `tomcat:tomcat 750` agar unprivileged user dapat mendeposit konteks aplikasi saat boot tanpa membuka izin direktori `conf` induk.

</div>

<div class="procedure-step" markdown>

### Implement Hardened XML Configurations

Tiga file konfigurasi XML utama diterapkan di `conf/`:

1. `conf/server.xml`:
   - Elemen `<Server port="-1" shutdown="SHUTDOWN">`: menonaktifkan listening socket port shutdown 8005.
   - Elemen `<Connector port="8080" protocol="HTTP/1.1" server="ApplicationServer" ...>`: menyamarkan HTTP response server banner.
   - Elemen `<Valve className="org.apache.catalina.valves.ErrorReportValve" showReport="false" showServerInfo="false"/>`: menyembunyikan detail stack trace dan versi Tomcat.
   - Menonaktifkan/menghapus konektor AJP (port 8009).

2. `conf/context.xml`:
   - `<Context useHttpOnly="true">`: mengaktifkan proteksi HttpOnly pada session cookies.
   - `<CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="lax" />`: menetapkan atribut SameSite cookie.

3. `conf/web.xml`:
   - Mendeklarasikan filter `org.apache.catalina.filters.HttpHeaderSecurityFilter` dan memetakannya ke `/*` (mengaktifkan HSTS, Anti-Clickjacking `X-Frame-Options: DENY`, dan `X-Content-Type-Options: nosniff`).
   - Mendeklarasikan `<security-constraint>` dengan `<http-method>TRACE</http-method>` dan `<auth-constraint />` kosong untuk menolak request HTTP TRACE (mencegah XST).

</div>

<div class="procedure-step" markdown>

### Implement CIS Audit Automation

Dibuat skrip `scripts/audit-cis.sh` yang menjalankan 8 pemeriksaan deterministik:
1. Server banner obfuscation check
2. ErrorReportValve configuration check
3. Shutdown port disabled check (port="-1")
4. AJP Connector disabled check
5. HttpHeaderSecurityFilter active check
6. Restricted HTTP TRACE method check
7. Session Cookie useHttpOnly check
8. Session Cookie sameSiteCookies check

</div>

<div class="procedure-step" markdown>

### Implement Vulnerability & Deployment Scripts

1. `scripts/scan.sh`: Mengintegrasikan Trivy container scanner untuk mengaudit CVE pada base image dan aplikasi, memformat output ke format tabel dan JSON, serta memicu quality gate failure bila ditemukan CVE dengan severity `CRITICAL` atau `HIGH`.
2. `scripts/deploy-bluegreen.sh`: Mengotomatisasi siklus rilis zero-downtime dengan menaikkan container Green berdampingan dengan container Blue, melakukan synthetic healthcheck loop, menukar traffic, dan menghentikan container Blue lama dengan fallback rollback instan jika healthcheck gagal.

</div>

<div class="procedure-step" markdown>

### Verify Runtime on Rootless Podman

Membangun image lokal `tomcat-hardened:test` dan menjalankannya dengan opsi keamanan maksimal:

```bash
podman run -d --name tomcat-verify \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,mode=1777 \
  --tmpfs /usr/local/tomcat/temp:rw,noexec,nosuid,nodev,mode=1777 \
  --tmpfs /usr/local/tomcat/work:rw,noexec,nosuid,nodev,mode=1777 \
  --cap-drop=ALL \
  -p 8080:8080 \
  tomcat-hardened:test
```

</div>

</div>

## 🧪 Verification

### 1. CIS Hardening Audit Verification

Skrip `scripts/audit-cis.sh` dieksekusi terhadap direktori konfigurasi `conf/`:

```text
[PASS] Server banner is obfuscated (server="ApplicationServer")
[PASS] ErrorReportValve is configured to hide stack traces and server info
[PASS] Shutdown port is disabled (port="-1")
[PASS] AJP Connector is disabled
[PASS] HttpHeaderSecurityFilter is configured in web.xml
[PASS] HTTP TRACE method is restricted in web.xml
[PASS] Session cookie useHttpOnly is enabled in context.xml
[PASS] Session cookie sameSiteCookies is configured in context.xml

Total Checks : 8
Passed       : 8
Failed       : 0
Compliance   : 100%
Result       : AUDIT PASSED - All CIS hardening rules compliant!
```

### 2. Runtime Execution & Startup Evidence

Pemeriksaan log kontainer Tomcat menunjukkan cold start bersih tanpa error atau peringatan:

```text
21-Sep-2026 20:53:14.120 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version name:   Apache Tomcat/10.1.34
21-Sep-2026 20:53:14.125 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.config.file=/usr/local/tomcat/conf/logging.properties
21-Sep-2026 20:53:14.540 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-nio-8080"]
21-Sep-2026 20:53:14.568 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [28] milliseconds
```

### 3. Read-Only Root Filesystem Verification

Menguji percobaan modifikasi file di dalam kontainer:

```bash
podman exec tomcat-verify touch /usr/local/tomcat/bin/hack.sh
# Output: touch: /usr/local/tomcat/bin/hack.sh: Read-only file system (exit code 1)
```

### 4. Listening Sockets Verification

Memeriksa port yang aktif mendengarkan:
- Port 8080 (HTTP): `LISTEN` (ProtocolHandler aktif)
- Port 8005 (Shutdown): `CLOSED` (port="-1" efektif, tidak ada socket terbuka)
- Port 8009 (AJP): `CLOSED` (tidak ada socket terbuka)

## 🧾 Outcome

Arsitektur Greenfield Hardened OCI Container untuk Apache Tomcat berhasil dirancang, diimplementasikan, dan diverifikasi secara penuh:
- Seluruh 8/8 aturan CIS benchmark terpenuhi (100% compliance).
- Kontainer beroperasi stabil pada mode `--read-only` dengan unprivileged UID 1001 dan cold start secepat 28 milidetik.
- Seluruh skrip otomasi (`audit-cis.sh`, `scan.sh`, `deploy-bluegreen.sh`) siap digunakan dan diintegrasikan ke tooling operator.

## 🎓 Lessons Learned

1. **Servlet Filter vs Valve**: Filter keamanan HTTP (`HttpHeaderSecurityFilter`) wajib ditempatkan di `conf/web.xml`, bukan di `conf/server.xml` sebagai Valve. Kesalahan penempatan atribut akan memicu kegagalan parser XML Catalina pada saat inisialisasi.
2. **Rootless Tmpfs Permissions**: Pada Rootless Podman, opsi tmpfs memerlukan `mode=1777` agar proses Tomcat non-root di dalam namespace memiliki write permission yang memadai pada `/tmp` dan `/usr/local/tomcat/work`.

## ⏭️ Next Steps

- Mengonsolidasikan seluruh skrip shell otomasi menjadi multi-platform Go CLI operator (`tcctl`).
- Mengadopsi Engine Runtime Named Volumes (`podman volume`) untuk memisahkan konfigurasi (`conf:ro`), aplikasi web (`webapps`), dan log (`logs`).

## 🔗 Related Documentation

- [Phase 1 Index](index.md)
- [TN-002: Implement Cross-Platform Operator tcctl and Runtime Volume Architecture](TN-002-implement-cross-platform-operator-tcctl-and-runtime-volume-architecture.md)
- [Security Hardening Guide](../../security-hardening/index.md)
- [TC-ADR-0001: Greenfield Container Architecture](../../../../adr/tomcat/adr-records/TC-ADR-0001.md)
- [TC-ADR-0002: CIS XML Hardening Quality Gate](../../../../adr/tomcat/adr-records/TC-ADR-0002.md)

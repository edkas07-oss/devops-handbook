# TN-003 — Implement SSL/TLS Management and Native PEM Connector

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

Mengimplementasikan **Pilar ke-6 (Manajemen SSL/TLS Certificate)** dengan mengonfigurasi konektor HTTPS native OpenSSL PEM format (port 8443) pada Apache Tomcat 9.0+, membangun modul manajemen sertifikat terpadu pada operator CLI `tcctl` (pembuatan sertifikat self-signed, pembuatan CSR untuk external CA, validasi kesesuaian kunci publik-privat, dan quality gate kadaluarsa), serta memverifikasi runtime HTTPS secara live pada container rootless Podman.

## 🌍 Background

Pada arsitektur awal, penanganan SSL/TLS direncanakan melalui dua pola: Pola A (Edge TLS Reverse Proxy) dan Pola B (Native End-to-End TLS di Tomcat). Penggunaan format konvensional Java Keystore (`.jks`) atau skrip shell eksternal (`generate-cert.sh`) yang bergantung pada utilitas host OpenSSL dinilai tidak portabel, rawan kesalahan (*error-prone*), dan menyalahi prinsip operator tunggal multi-platform `tcctl`.

Stakeholder menetapkan kebutuhan konkret:
1. `tcctl` harus mampu membuat sertifikat *self-signed* secara mandiri untuk bootstraping lab/staging tanpa membutuhkan instalasi OpenSSL di host.
2. Jika menggunakan sertifikat eksternal (Corporate CA / Public PKI), `tcctl` bertugas membuat Certificate Signing Request (CSR) beserta private key-nya, memvalidasi bahwa sertifikat yang diterima cocok dengan private key, dan mengonfigurasi konektor HTTPS secara otomatis.
3. Seluruh material TLS harus dapat diinjeksikan langsung ke dalam Engine Runtime Named Volumes (`podman volume`) dengan izin akses yang sesuai bagi unprivileged non-root user (UID 1001).

## 📚 Scope

Pekerjaan pada Technical Note ini mencakup:

- Rancang bangun paket `internal/ssl` pada repositori `/home/eddywiyatno/git/tcctl`:
  - `tcctl ssl check`: Memeriksa sisa masa berlaku sertifikat x509 PEM terhadap ambang batas peringatan (`< 30 hari`) dan kritis (`< 7 hari`).
  - `tcctl ssl generate`: Menghasilkan sertifikat self-signed RSA-2048 dan kunci privat dalam format PEM.
  - `tcctl ssl csr`: Menghasilkan CSR standar PKCS#10 (`request.csr`) dan kunci privat untuk CA Korporat.
  - `tcctl ssl setup`: Memvalidasi modulus RSA antara sertifikat eksternal dan private key sebelum menginstalnya ke volume atau direktori, serta mengaktifkan konektor HTTPS di `server.xml`.
- Konfigurasi konektor HTTPS native OpenSSL PEM di `conf/server.xml` pada port `8443` dengan cipher suite kuat (`TLSv1.2+TLSv1.3`).
- Pembaruan `Containerfile` dan `entrypoint.sh` untuk mengekspos port 8443.
- Pengujian live runtime Tomcat: cold start, inisialisasi APR/OpenSSL, dan verifikasi respons HTTP (8080) serta HTTPS (8443).

## ⚖️ Execution Decision

Aktivitas ini mengimplementasikan keputusan arsitektur berikut:

- [TC-ADR-0005: Adopt Native OpenSSL PEM Connector and Automated TLS Lifecycle Governance via tcctl](../../../../adr/tomcat/adr-records/TC-ADR-0005.md)

## 🧭 Implementation Plan

| Tahap | Rencana |
| --- | --- |
| **Develop Go SSL Subsystem in tcctl** | Mengembangkan paket `internal/ssl/cert.go` dengan Go standard library (`crypto/x509`, `crypto/rsa`). |
| **Integrate SSL Commands into CLI** | Menambahkan subcommands `check`, `generate`, `csr`, dan `setup` pada `cmd/tcctl/main.go`. |
| **Configure Native PEM Connector in Tomcat** | Menambahkan konektor port 8443 dengan `<SSLHostConfig>` pada `conf/server.xml`. |
| **Update Container Metadata & Entrypoint** | Mengekspos port 8443 dan menambahkan informasi layanan HTTPS pada banner startup. |
| **Verify Multi-Platform Binaries & Live Runtime** | Mengompilasi biner Linux/Windows dan menguji koneksi HTTPS live via Rootless Podman. |

## ⚙️ Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Develop Go SSL Subsystem in tcctl

File `internal/ssl/cert.go` diimplementasikan dengan kapabilitas:
- `CheckCertificate()`: Mem-parsing x509 PEM, mengekstrak Subject, SANs, masa aktif, dan status (`OK`, `WARNING`, `CRITICAL`, `EXPIRED`).
- `GenerateSelfSignedCert()`: Membuat sertifikat x509 mandiri dan kunci RSA 2048-bit dengan izin direktori `0755` dan file `0644`.
- `GenerateCSR()`: Membuat permintaan penandatanganan sertifikat standar PKCS#10 (`request.csr`) dan private key.
- `SetupExternalCert()`: Memvalidasi kecocokan modulus antara publik key sertifikat dan private key (`privKey.N.Cmp(certPubKey.N) == 0`), mencegah kesalahan instalasi kunci yang salah.
- Mendukung flag `--volume` untuk berinteraksi langsung dengan physical mount point Engine Named Volume (`podman volume`).

</div>

<div class="procedure-step" markdown>

### Integrate SSL Commands into CLI

Modifikasi `cmd/tcctl/main.go` mengintegrasikan subcommands:
- `tcctl ssl check [--cert <path>] [--volume <name>] [--warn-days 30] [--crit-days 7] [--json]`
- `tcctl ssl generate [--out-dir <dir>] [--volume <name>] [--domain <domain>] [--days <days>]`
- `tcctl ssl csr [--domain <domain>] [--org <org>] [--out-dir <dir>] [--volume <name>]`
- `tcctl ssl setup --cert <cert.pem> --key <privkey.pem> [--chain <chain.pem>] [--volume <name>] [--server-xml <path>]`

</div>

<div class="procedure-step" markdown>

### Configure Native PEM Connector in Tomcat

File `conf/server.xml` diperbarui dengan menambahkan konektor native OpenSSL:

```xml
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true"
               server="ApplicationServer"
               xpoweredBy="false"
               allowTrace="false">
        <SSLHostConfig protocols="TLSv1.2+TLSv1.3"
                       ciphers="HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK">
            <Certificate certificateFile="conf/ssl/cert.pem"
                         certificateKeyFile="conf/ssl/privkey.pem"
                         certificateChainFile="conf/ssl/chain.pem"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
```

</div>

<div class="procedure-step" markdown>

### Update Container Metadata & Entrypoint

- `Containerfile`: Menambahkan instruksi `EXPOSE 8080 8443` dan pembuatan direktori `conf/ssl` dengan izin `0750`.
- `entrypoint.sh`: Menambahkan log output `HTTPS Port : 8443 (Native OpenSSL PEM)`.

</div>

<div class="procedure-step" markdown>

### Verify Multi-Platform Binaries & Live Runtime

Kompilasi statis dijalankan dengan `make build-all` di repositori `tcctl`:
- `bin/tcctl` (Linux amd64 ELF)
- `bin/tcctl.exe` (Windows amd64 PE)

Material sertifikat diinjeksikan langsung ke named volume `test-tls_conf` menggunakan:
```bash
./bin/tcctl ssl generate --volume test-tls_conf --domain localhost
```

Kontainer dijalankan dengan opsi rootless podman:
```bash
podman run -d --name tomcat-tls-verify \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,mode=1777 \
  --tmpfs /usr/local/tomcat/temp:rw,noexec,nosuid,nodev,mode=1777 \
  --tmpfs /usr/local/tomcat/work:rw,noexec,nosuid,nodev,mode=1777 \
  --cap-drop=ALL \
  -v test-tls_conf:/usr/local/tomcat/conf:ro,Z \
  -v test-tls_logs:/usr/local/tomcat/logs:Z \
  -p 18080:8080 -p 18443:8443 \
  localhost/tomcat:9.0
```

</div>

</div>

## 🧪 Verification

### 1. CSR Generation Verification

Membuat CSR untuk CA eksternal menggunakan `tcctl ssl csr`:

```bash
./bin/tcctl ssl csr --domain tomcat.corp.internal --org "Enterprise Corp" --out-dir /tmp/test-csr
# Output:
# ✔ CSR and private key successfully created:
#   CSR: /tmp/test-csr/request.csr
#   Key: /tmp/test-csr/privkey.pem
```

Inspeksi CSR membuktikan format standar x509 PKCS#10:
`Subject: C = ID, O = Enterprise Corp, CN = tomcat.corp.internal`, `Public-Key: (2048 bit)`.

### 2. Key Mismatch Protection Verification

Saat menguji pemasangan sertifikat dengan private key yang salah (`dummy.key`):

```bash
./bin/tcctl ssl setup --cert signed-cert.pem --key dummy.key --out-dir /tmp/test-fail
# Output:
# ✖ Failed to install certificate: certificate and private key do not match! Public modulus differs
# Exit Code: 1
```

Tooling menolak pemasangan kunci yang tidak cocok, mencegah kegagalan runtime saat booting.

### 3. Expiry Quality Gate Verification

Menguji toleransi ambang batas kadaluarsa sertifikat:
- Saat masa berlaku > ambang batas: Status `[OK]`, return code `0`.
- Saat masa berlaku < warning threshold: Status `[WARNING]`.
- Saat masa berlaku < critical threshold: Status `[CRITICAL]`, return code `1` (menghentikan pipeline CI/CD).

### 4. Live Runtime HTTPS & APR OpenSSL Verification

Pemeriksaan log kontainer membuktikan keberhasilan inisialisasi native OpenSSL:

```text
INFO: Loaded Apache Tomcat Native library [1.3.8] using APR version [1.7.2].
INFO: OpenSSL successfully initialized [OpenSSL 3.0.13 30 Jan 2024]
INFO: Initializing ProtocolHandler ["http-nio-8080"]
INFO: Initializing ProtocolHandler ["https-openssl-nio-8443"]
INFO: Connector [https-openssl-nio-8443], TLS virtual host [_default_], certificate type [RSA] configured from key [conf/ssl/privkey.pem], certificate [conf/ssl/cert.pem] and certificate chain [conf/ssl/chain.pem]
INFO: Starting ProtocolHandler ["http-nio-8080"]
INFO: Starting ProtocolHandler ["https-openssl-nio-8443"]
INFO: Server startup in [31] milliseconds
```

Pengujian koneksi HTTPS melalui `curl`:

```bash
curl -k -I https://localhost:18443/
# Output:
# HTTP/1.1 404
# Content-Type: text/html;charset=utf-8
# Server: ApplicationServer
```

Koneksi HTTPS berhasil melayani request dengan enkripsi modern dan banner server tetap tersamarkan.

## 🧾 Outcome

- **Pilar ke-6 (Manajemen SSL/TLS Certificate)** berhasil diselesaikan secara penuh.
- Operator CLI `tcctl` kini memiliki kapabilitas lengkap untuk mengelola sertifikat mandiri (*self-signed*), permintaan CSR CA eksternal, validasi kecocokan pasangan kunci (*key matching*), dan evaluasi masa kadaluarsa otomatis.
- Tomcat 9.0+ beroperasi dengan konektor native OpenSSL PEM di port 8443 tanpa konversi Java Keystore (.jks).
- Seluruh 6 pilar arsitektur Apache Tomcat Enterprise kini berstatus **Completed**.

## 🎓 Lessons Learned

1. **Host-to-Container Permission Mapping**: Pada rootless Podman, file private key di host named volume harus memiliki izin `0644` (atau direktori `0755`) agar unprivileged user `tomcat` (UID `1001`, yang dipetakan ke subuid namespace host) dapat membaca berkas konfigurasi di dalam mount point read-only.
2. **Elimination of Host Utility Debt**: Mengganti ketergantungan skrip Bash OpenSSL dengan Go standard library (`crypto/x509`) secara instan membebaskan sistem dari dependensi biner host eksternal dan memungkinkan eksekusi native pada sistem operasi Windows Server.

## ⏭️ Next Steps

- Memperbarui matriks 6 pilar solusi di dokumentasi utama handbook menjadi `Completed`.
- Menyelaraskan panduan operasional pada dokumentasi SSL Management handbook.

## 🔗 Related Documentation

- [Platform Foundation Phase Index](index.md)
- [TN-001: Architect Pure Container Model and Security Hardening](TN-001-architect-pure-container-model-and-security-hardening.md)
- [TN-002: Implement Cross-Platform Operator tcctl and Runtime Volume Architecture](TN-002-implement-cross-platform-operator-tcctl-and-runtime-volume-architecture.md)
- [TC-ADR-0005: Native OpenSSL PEM Connector & TLS Lifecycle](../../../../adr/tomcat/adr-records/TC-ADR-0005.md)
- [SSL Management Guide](../../ssl-management/index.md)

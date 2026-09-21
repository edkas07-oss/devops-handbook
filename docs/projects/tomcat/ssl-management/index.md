# SSL & TLS Certificate Management

## 🔍 Overview

Spesifikasi **Manajemen SSL & TLS Certificate** menjamin komunikasi terenkripsi yang aman (*in-transit encryption*) untuk Apache Tomcat Enterprise Edition. Pendekatan arsitektur ini mengeliminasi kompleksitas konversi format sertifikat legacy seperti Java Keystore (`.jks`) maupun PKCS#12 (`.p12`), serta beralih ke konektor **Native OpenSSL PEM** yang didukung secara resmi oleh Apache Tomcat 9.0+ melalui pustaka Apache Portable Runtime (APR / Tomcat Native).

Seluruh siklus hidup (*lifecycle*) sertifikat dikendalikan secara tersentralisasi melalui operator CLI lintas platform **`tcctl`**:
- **Penerbitan Mandiri (*Self-Signed*)**: Untuk bootstrapping lingkungan *development* dan *lab*.
- **Pembuatan CSR (*Certificate Signing Request*)**: Standard PKCS#10 untuk permohonan sertifikat ke CA korporat / publik.
- **Validasi & Instalasi Sertifikat Eksternal**: Verifikasi keselarasan kriptografi (*modulus match*) sebelum instalasi ke runtime volume.
- **Audit & Pemantauan Masa Berlaku**: Pengecekan otomatis batas kedaluwarsa sertifikat dengan gerbang kualitas CI/CD (*exit code 1* pada ambang batas kritis).

> [!NOTE] Referensi Arsitektur
> Keputusan arsitektur terkait adopsi konektor native PEM dan tata kelola TLS terpusat didokumentasikan secara rinci pada [TC-ADR-0005: Adopt Native OpenSSL PEM Connector and Automated TLS Lifecycle Governance via tcctl](../../adr/tomcat/adr-records/TC-ADR-0005.md) dan catatan teknis [TN-003: Implementasi SSL/TLS Management & Native OpenSSL PEM Connector](../engineering-journal/platform-foundation-and-hardening/TN-003-implement-ssl-tls-management-and-native-pem-connector.md).

---

## 🔒 Pola Arsitektur SSL

Dalam operasional enterprise, diterapkan dua pola arsitektur sesuai kebutuhan kepatuhan regulasi:

### Pola A: Edge TLS Termination (Disarankan untuk Skala Besar)
Sertifikat publik dikelola terpusat pada Reverse Proxy (misalnya Nginx atau Load Balancer enterprise):
* **Otomasi**: Menggunakan protokol ACME (Let's Encrypt atau Automated Corporate CA).
* **Hot-Reload**: Perpanjangan sertifikat dieksekusi dengan `nginx -s reload` tanpa menyentuh container Tomcat maupun merestart JVM.
* **Internal Routing**: Komunikasi dari reverse proxy ke Tomcat backend dapat menggunakan HTTP (jika berada dalam private overlay network terisolasi) atau mTLS.

### Pola B: Native End-to-End TLS di Tomcat (Zero-Trust & Kepatuhan Ketat)
Jika kepatuhan regulasi (seperti PCI-DSS, HIPAA, atau kebijakan internal perbankan) mewajibkan enkripsi penuh *in-transit* hingga ke level JVM/Tomcat engine:

Tomcat 9.0+ dikonfigurasi dengan konektor OpenSSL berbasis file PEM standar tanpa perlu konversi format JKS.

```xml
<!-- HTTPS Connector 8443 (Native OpenSSL PEM format) -->
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

#### Parameter Pengerasan TLS:
1. **`protocols="TLSv1.2+TLSv1.3"`**: Menonaktifkan protokol usang dan rentan (SSLv2, SSLv3, TLS 1.0, TLS 1.1).
2. **`ciphers="HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK"`**: Membatasi cipher suite hanya pada algoritma enkripsi modern dengan jaminan *Forward Secrecy* (FS).
3. **`server="ApplicationServer"` & `xpoweredBy="false"`**: Menyamarkan header identitas server guna mencegah *fingerprinting* informasi versi runtime.
4. **`allowTrace="false"`**: Mencegah eksploitasi serangan *Cross-Site Tracing* (XST) melalui HTTP TRACE.

---

## 📁 Struktur Penyimpanan & Runtime Volume

Material sertifikat TLS disimpan di dalam direktori `conf/ssl/` pada Engine Named Volume konfigurasi (`<instance-name>_conf`):

```
<instance-name>_conf/
├── server.xml
├── web.xml
├── context.xml
└── ssl/
    ├── cert.pem        (Public X.509 Certificate)
    ├── privkey.pem     (RSA 2048-bit Private Key)
    ├── chain.pem       (CA Intermediate / Root Chain)
    └── request.csr     (PKCS#10 Certificate Signing Request - jika ada)
```

### Izin Akses File pada Rootless Podman
Saat container dijalankan dengan flag `--read-only` dan volume dipasang secara read-only (`:ro,Z`), file material TLS harus memiliki izin berkas (*POSIX permissions*) yang tepat agar dapat dibaca oleh user unprivileged `tomcat` (UID `1001` di dalam container, yang dipetakan ke UID subuid pada namespace host):
- Direktori `ssl/`: Izin `0755` (`drwxr-xr-x`).
- Berkas PEM (`cert.pem`, `privkey.pem`, `chain.pem`): Izin `0644` (`-rw-r--r--`).

> [!WARNING] Catatan Izin Berkas Rootless
> Jika private key disimpan dengan izin `0600` di host user reguler tanpa izin baca untuk subuid pengguna, Tomcat yang berjalan sebagai non-root (UID `1001`) akan mengalami kegagalan *Permission Denied* saat membaca file kunci privat pada saat startup.

---

## 🛠️ Manajemen Siklus Sertifikat via `tcctl`

CLI `tcctl` menyediakan subperintah `tcctl ssl` mandiri tanpa ketergantungan pada utilitas shell script eksternal maupun biner OpenSSL lokal.

### 1. Bootstrapping Sertifikat Self-Signed (`tcctl ssl generate`)
Digunakan untuk menginisialisasi sertifikat uji coba mandiri secara instan dengan Subject Alternative Names (SAN) mencakup `localhost`, `127.0.0.1`, dan alamat IP lokal.

```bash
# Opsi A: Generate ke direktori lokal
tcctl ssl generate --out-dir conf/ssl --domain app.devops.local --days 365

# Opsi B: Generate langsung ke dalam Engine Named Volume
tcctl ssl generate --volume tomcat-app_conf --domain localhost --days 365
```

Output:
```
ℹ Generating self-signed TLS certificates directly into volume 'tomcat-app_conf'...
✔ Certificates generated in volume 'tomcat-app_conf':
  Cert: ~/.local/share/containers/storage/volumes/tomcat-app_conf/_data/ssl/cert.pem
  Key : ~/.local/share/containers/storage/volumes/tomcat-app_conf/_data/ssl/privkey.pem
```

---

### 2. Permohonan Sertifikat Resmi via CSR (`tcctl ssl csr`)
Ketika aplikasi dipromosikan ke tahap produksi yang membutuhkan sertifikat resmi dari Corporate PKI atau Public CA:

```bash
# Membuat private key dan PKCS#10 CSR
tcctl ssl csr --domain tomcat.corp.internal \
              --org "Enterprise DevOps Corp" \
              --country ID \
              --volume tomcat-app_conf
```

Output:
```
ℹ Generating CSR directly into volume 'tomcat-app_conf' for domain 'tomcat.corp.internal'...
✔ CSR and private key created in volume 'tomcat-app_conf':
  CSR: ~/.local/share/containers/storage/volumes/tomcat-app_conf/_data/ssl/request.csr
  Key: ~/.local/share/containers/storage/volumes/tomcat-app_conf/_data/ssl/privkey.pem
```

Operator cukup mengirimkan file `request.csr` ke tim Certificate Authority (CA) perusahaan untuk ditandatangani.

---

### 3. Validasi & Pemasangan Sertifikat Eksternal (`tcctl ssl setup`)
Setelah menerima berkas sertifikat publik (`.crt` / `.pem`) dari CA, `tcctl` memvalidasi keselarasan kriptografi (*cryptographic key-matching*) terlebih dahulu sebelum memasangnya ke volume target dan mengaktifkan konektor HTTPS pada `server.xml`:

```bash
# Memverifikasi dan memasang sertifikat eksternal
tcctl ssl setup --cert /tmp/signed-cert.pem \
                --key /tmp/private.key \
                --chain /tmp/ca-bundle.pem \
                --volume tomcat-app_conf
```

#### Mekanisme Validasi Kriptografi Pre-Flight:
1. Mengekstrak modulus kunci publik RSA dari berkas sertifikat ($N_{cert}$).
2. Mengekstrak modulus kunci privat RSA dari berkas private key ($N_{key}$).
3. Memverifikasi bahwa $N_{cert} == N_{key}$. Jika terjadi ketidaksesuaian (*mismatch*), proses dihentikan seketika dengan pesan kesalahan eksplisit guna mencegah runtime crash pada Tomcat.

---

### 4. Audit & Peringatan Masa Berlaku (`tcctl ssl check`)
Mencegah insiden *outage* akibat sertifikat kedaluwarsa dengan audit otomatis:

```bash
# Audit sertifikat di dalam Engine Named Volume
tcctl ssl check --volume tomcat-app_conf --warn-days 30 --crit-days 7

# Atau audit berkas sertifikat spesifik
tcctl ssl check --cert /path/to/cert.pem
```

Contoh Output Tabel:
```
+-------------------+---------------------------------------------+
| PARAMETER         | VALUE                                       |
+-------------------+---------------------------------------------+
| Subject           | CN=localhost                                |
| Issuer            | CN=localhost                                |
| Valid From        | 2026-09-21 14:35:10 UTC                     |
| Valid Until       | 2027-09-21 14:35:10 UTC                     |
| Days Remaining    | 364 days                                    |
| DNS SANs          | localhost                                   |
| IP SANs           | 127.0.0.1                                   |
| Status            | [OK]                                        |
+-------------------+---------------------------------------------+
```

#### Integrasi Otomasi CI/CD & Monitoring (JSON Output):
```bash
tcctl ssl check --volume tomcat-app_conf --json
```

```json
{
  "subject": "CN=localhost",
  "issuer": "CN=localhost",
  "not_before": "2026-09-21T14:35:10Z",
  "not_after": "2027-09-21T14:35:10Z",
  "days_remaining": 364,
  "dns_names": [
    "localhost"
  ],
  "ip_addresses": [
    "127.0.0.1"
  ],
  "status": "OK"
}
```

#### Kebijakan Exit Code untuk Gerbang Kualitas (Quality Gates):
- **`Status: OK`** (Sisa waktu $\ge 30$ hari): Exit code `0`.
- **`Status: WARNING`** (Sisa waktu $< 30$ hari): Exit code `0` (peringatan pada log).
- **`Status: CRITICAL`** (Sisa waktu $< 7$ hari): Exit code `1` (menghentikan pipeline CI/CD / memicu eskalasi on-call).
- **`Status: EXPIRED`** (Telah kedaluwarsa): Exit code `1`.

---

## 🧪 Verifikasi & Pengujian Runtime

Setelah container dijalankan dengan port binding `8443:8443`:

### 1. Pengujian HTTP & HTTPS Endpoint
```bash
# Pengujian respon HTTP (port 8080)
curl -I http://localhost:8080/

# Pengujian respon HTTPS (port 8443) dengan validasi header server masking
curl -k -I https://localhost:8443/
```

Contoh respon sukses terenkripsi:
```http
HTTP/1.1 404
Server: ApplicationServer
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Type: text/html;charset=utf-8
Content-Language: en
Date: Mon, 21 Sep 2026 15:10:42 GMT
```

### 2. Validasi Handshake & Negosiasi Protokol TLS 1.3
```bash
openssl s_client -connect localhost:8443 -tls1_3
```

Memverifikasi bahwa koneksi menegosiasikan protokol `TLSv1.3` dengan cipher suite berkekuatan tinggi (misalnya `TLS_AES_256_GCM_SHA384`) dan informasi banner runtime tetap tersamarkan (*masked*).

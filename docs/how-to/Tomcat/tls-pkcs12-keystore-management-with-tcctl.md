# Panduan Tata Kelola TLS PKCS#12 Keystore dengan tcctl

---
**Kategori:** Apache Tomcat Operations  
**Target:** Operator DevOps, System Administrator  
**Tools:** `tcctl` (Universal CLI), Docker / Podman, Windows Server & Linux  
---

## 1. Pendahuluan

Apache Tomcat di lingkungan enterprise memerlukan perlindungan komunikasi melalui protokol enkripsi TLS (HTTPS port 8443). Format standar yang paling banyak digunakan di ekosistem Java Enterprise dan sistem operasi Windows adalah **PKCS#12 (`.p12` / `.pfx`)**.

CLI `tcctl` menyediakan manajemen siklus hidup sertifikat TLS secara terintegrasi:
- **Auto-Bootstrapping**: Menghasilkan self-signed keystore PKCS#12 secara otomatis saat inisialisasi awal.
- **Auto-Detection**: Menyesuaikan konfigurasi `server.xml` secara otomatis antara PKCS#12 dan PEM.
- **Sertifikat Sendiri (BYO Cert)**: Memvalidasi dan memasang sertifikat eksternal milik organisasi.
- **Health & Expiry Check**: Memantau masa aktif sertifikat untuk mencegah insiden downtime akibat sertifikat kedaluwarsa.

---

## 2. Skenario Operasional

### Skenario 1: Deploy Instance Baru (Self-Signed PKCS#12 Otomatis)

Saat melakukan deployment instance baru, `tcctl` otomatis membuat struktur direktori, men-generate sertifikat self-signed PKCS#12 (`keystore.p12`), dan mengonfigurasi `server.xml`.

```powershell
# Jalankan perintah deploy di Windows Server
tcctl.exe deploy run --name tomcat-lab --port 8080 --https-port 8443
```

**Hasil yang terbentuk pada host:**
- `C:\tomcats\tomcat-lab\conf\ssl\keystore.p12` (Password default: `changeit`)
- `C:\tomcats\tomcat-lab\conf\ssl\cert.pem` (Ekspor publik untuk monitoring)
- `C:\tomcats\tomcat-lab\conf\ssl\server.crt` (Kompatibilitas tooling eksternal)

Konfigurasi pada `server.xml` otomatis terpasang:
```xml
<Certificate certificateKeystoreFile="conf/ssl/keystore.p12"
             certificateKeystorePassword="changeit"
             certificateKeystoreType="PKCS12"
             type="RSA" />
```

**Deploy Result Summary:**
```text
✔ Tomcat instance 'tomcat-lab' is up, running, and fully hardened!

 Runtime Environment:
   - Container Image : tomcat:9.0-jdk11
   - Tomcat Version  : Apache Tomcat/9.0.98
   - Java / JDK      : 11.0.32+9 (Eclipse Adoptium)

 Endpoints:
   - HTTP    : http://localhost:8080/
   - HTTPS   : https://localhost:8443/

 Host Bind Mounts (TC-ADR-0009):
   - Base Dir : C:\tomcats
   - Conf     : C:\tomcats\tomcat-lab\conf (Read-Only :ro)
   - Webapps  : C:\tomcats\tomcat-lab\webapps
   - Logs     : C:\tomcats\tomcat-lab\logs
```

---

### Skenario 2: Menggunakan Sertifikat Sendiri (Commercial / Corporate CA PKCS#12)

Jika Anda telah memiliki file sertifikat PKCS#12 dari Corporate PKI (Active Directory Certificate Services, DigiCert, GlobalSign, dsb.):

#### Metode A: Menggunakan Perintah `tcctl ssl setup` (Direkomendasikan)
Perintah ini akan memvalidasi password dan integritas sertifikat terlebih dahulu sebelum memasangnya ke instance Tomcat:

```powershell
tcctl.exe ssl setup `
  --keystore "C:\certs\mycompany_app.pfx" `
  --password "PasswordKeystoreAnda" `
  --out-dir "C:\tomcats\tomcat-lab\conf\ssl" `
  --server-xml "C:\tomcats\tomcat-lab\conf\server.xml"
```

#### Metode B: Penempatan File Manual
1. Salin file `.p12` atau `.pfx` Anda ke folder instance:
   ```powershell
   Copy-Item "C:\certs\mycompany_app.pfx" "C:\tomcats\tomcat-lab\conf\ssl\keystore.p12"
   ```
2. Pastikan password pada `C:\tomcats\tomcat-lab\conf\server.xml` sesuai:
   ```xml
   <Certificate certificateKeystoreFile="conf/ssl/keystore.p12"
                certificateKeystorePassword="PasswordKeystoreAnda"
                certificateKeystoreType="PKCS12"
                type="RSA" />
   ```
3. Restart container untuk menerapkan sertifikat baru:
   ```powershell
   docker restart tomcat-lab
   ```

---

### Skenario 3: Memeriksa Masa Berlaku Sertifikat (Expiry Healthcheck)

Untuk mencegah insiden gangguan layanan akibat sertifikat expired, gunakan subperintah `tcctl ssl check`.

#### Pengecekan Human-Readable (Console Table):
```powershell
tcctl.exe ssl check --cert C:\tomcats\tomcat-lab\conf\ssl\keystore.p12
```

**Contoh Output:**
```
===============================================================
                  SSL/TLS CERTIFICATE STATUS                   
===============================================================
File Path       : C:\tomcats\tomcat-lab\conf\ssl\keystore.p12
Subject CN      : tomcat-lab.corp.internal
Issuer          : Corporate Issuing CA
DNS SANs        : tomcat-lab.corp.internal, localhost
Valid From      : 2026-01-01 00:00:00 UTC
Valid Until     : 2027-01-01 23:59:59 UTC
Days Remaining  : 100 days
Health Status   : [OK]
===============================================================
Result: PASS - Certificate is valid and not nearing expiration.
===============================================================
```

#### Pengecekan Otomatis (JSON Mode untuk CI/CD atau Zabbix/Prometheus):
```powershell
tcctl.exe ssl check --cert C:\tomcats\tomcat-lab\conf\ssl\keystore.p12 --json
```

**Contoh Output JSON:**
```json
{
  "subject": "tomcat-lab.corp.internal",
  "issuer": "Corporate Issuing CA",
  "dns_names": ["tomcat-lab.corp.internal", "localhost"],
  "ip_addresses": ["127.0.0.1"],
  "not_before": "2026-01-01T00:00:00Z",
  "not_after": "2027-01-01T23:59:59Z",
  "days_remaining": 100,
  "status": "OK",
  "file_path": "C:\\tomcats\\tomcat-lab\\conf\\ssl\\keystore.p12"
}
```

> [!TIP]
> Nilai status dapat berupa:
> - `OK`: Sertifikat valid (> 30 hari).
> - `WARNING`: Sertifikat kedaluwarsa dalam <= 30 hari (dapat disesuaikan via `--warn-days`).
> - `CRITICAL`: Sertifikat kedaluwarsa dalam <= 7 hari (dapat disesuaikan via `--crit-days`).
> - `EXPIRED`: Sertifikat telah melewati masa berlaku.

---

### Skenario 4: Konversi Sertifikat dari Format PEM ke PKCS#12

Jika CA Anda hanya menerbitkan file PEM (`certificate.crt`, `private.key`, dan `ca-bundle.crt`), Anda dapat menggabungkannya ke dalam format PKCS#12 menggunakan perintah OpenSSL standar:

```bash
openssl pkcs12 -export \
  -in certificate.crt \
  -inkey private.key \
  -certfile ca-bundle.crt \
  -out keystore.p12 \
  -name tomcat \
  -password pass:changeit
```

Setelah file `keystore.p12` terbentuk, pindahkan ke folder `C:\tomcats\<instance>\conf\ssl\keystore.p12`.

---

### Skenario 5: Migrasi Instance Eksisting dari PEM ke PKCS#12

Jika instance Tomcat Anda sebelumnya diinisialisasi menggunakan format PEM dan ingin dimigrasikan ke PKCS#12:

1. Buat keystore PKCS#12 di folder SSL instance:
   ```powershell
   tcctl.exe ssl generate --out-dir C:\tomcats\tomcat-lab\conf\ssl --domain localhost
   ```
2. Jalankan konfigurasi HTTPS connector:
   ```powershell
   tcctl.exe ssl setup --keystore C:\tomcats\tomcat-lab\conf\ssl\keystore.p12 --server-xml C:\tomcats\tomcat-lab\conf\server.xml
   ```
3. Lakukan audit static compliance untuk memastikan kepatuhan standar CIS:
   ```powershell
   tcctl.exe hardening audit --conf C:\tomcats\tomcat-lab\conf
   ```
4. Restart container:
   ```powershell
   docker restart tomcat-lab
   ```

---

## 3. Rangkuman Flag Perintah `tcctl ssl`

| Perintah | Flag | Deskripsi | Default |
|---|---|---|---|
| `check` | `--cert <path>` | Path ke file sertifikat (`.pem`, `.crt`, `.p12`, `.pfx`) | - |
| `check` | `--keystore <path>` | Path spesifik ke file PKCS#12 | - |
| `check` | `--password <pass>` | Password untuk membuka file PKCS#12 | `changeit` |
| `check` | `--warn-days <int>` | Ambang batas peringatan (hari) | `30` |
| `check` | `--crit-days <int>` | Ambang batas kritis (hari) | `7` |
| `check` | `--json` | Menampilkan output dalam format JSON | `false` |
| `generate` | `--out-dir <path>` | Direktori output penyimpanan file | `conf/ssl` |
| `generate` | `--domain <fqdn>` | Common Name (CN) dan DNS SAN | `localhost` |
| `generate` | `--days <int>` | Masa berlaku sertifikat (hari) | `365` |
| `generate` | `--password <pass>` | Password keystore PKCS#12 | `changeit` |
| `setup` | `--keystore <path>` | File sertifikat PKCS#12 eksternal | - |
| `setup` | `--cert <path>` | File sertifikat publik PEM eksternal | - |
| `setup` | `--key <path>` | File kunci privat PEM eksternal | - |
| `setup` | `--server-xml <path>` | Path ke `server.xml` untuk inject konfigurasi | - |

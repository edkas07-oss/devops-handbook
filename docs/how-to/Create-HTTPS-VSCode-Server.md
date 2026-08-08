# Create HTTPS for VS Code Server

## Overview

**code-server** memungkinkan Visual Studio Code dijalankan melalui browser.

Secara default, code-server dapat berjalan menggunakan HTTP.

```text
Browser
   │
   │ HTTP
   ▼
code-server
   │
   ▼
VS Code
```

Untuk environment yang membutuhkan **HTTPS** dan **Secure Context**, code-server dapat dikonfigurasi menggunakan SSL/TLS Certificate.

```text
Browser
   │
   │ HTTPS
   ▼
code-server
   │
   ▼
VS Code
```

Dokumen ini menggunakan certificate yang dibuat menggunakan **OpenSSL Private Certificate Authority (CA)**.

Certificate dibuat menggunakan prosedur:

```text
Create SSL Certificate
```

---

## Architecture

```text
                    Internal Root CA
                          │
                          │ Signs
                          ▼
                    Server Certificate
                          │
                          ▼
                    code-server
                          │
                          │ HTTPS
                          ▼
                       Browser
                          │
                          ▼
                     VS Code Web
```

---

## Prerequisites

Pastikan software berikut tersedia:

| Software | Purpose |
| -------- | ------- |
| code-server | Menjalankan VS Code melalui browser |
| OpenSSL | Membuat dan memverifikasi certificate |
| systemd | Mengelola code-server service |

---

## Verify code-server

Periksa versi code-server:

```bash
code-server --version
```

Contoh:

```text
1.130.0
197ef3e8da8ee99ed6ca8f1a630157527e6d448f
x64
```

---

## Verify OpenSSL

Pastikan OpenSSL tersedia:

```bash
openssl version
```

Contoh:

```text
OpenSSL 3.0.x
```

---

# SSL/TLS Certificate

## Certificate Files

Dokumen ini menggunakan Server Certificate yang telah dibuat menggunakan OpenSSL.

Contoh struktur:

```text
~/ssl/
├── ca/
│   ├── ca.key
│   ├── ca.crt
│   └── ca.srl
│
└── server/
    ├── server.key
    ├── server.csr
    ├── server.crt
    └── server.ext
```

Certificate yang digunakan oleh code-server:

```text
~/ssl/server/server.crt
```

Private Key:

```text
~/ssl/server/server.key
```

Certificate Authority:

```text
~/ssl/ca/ca.crt
```

---

## Verify Server Certificate

Sebelum digunakan oleh code-server, verify certificate:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -subject \
  -issuer \
  -dates \
  -ext subjectAltName
```

Contoh:

```text
subject=C = ID, O = Internal, CN = edkas-pc1

issuer=C = ID, O = Internal CA, CN = Internal Root CA

X509v3 Subject Alternative Name:
    DNS:edkas-pc1
    DNS:localhost
    IP Address:127.0.0.1
```

---

## Verify Certificate Chain

Verify certificate menggunakan CA:

```bash
openssl verify \
  -CAfile ~/ssl/ca/ca.crt \
  ~/ssl/server/server.crt
```

Expected:

```text
server.crt: OK
```

---

## Verify Private Key

Pastikan Private Key tersedia:

```bash
ls -lah ~/ssl/server/server.key
```

Protect Private Key:

```bash
chmod 600 ~/ssl/server/server.key
```

Verify:

```bash
ls -l ~/ssl/server/server.key
```

Expected:

```text
-rw------- ... server.key
```

---

# code-server Configuration

## Configuration Directory

Default configuration code-server berada pada:

```text
~/.config/code-server/
```

Periksa:

```bash
ls -lah ~/.config/code-server/
```

---

## Configuration File

File configuration:

```text
~/.config/code-server/config.yaml
```

Periksa:

```bash
cat ~/.config/code-server/config.yaml
```

---

## Example HTTP Configuration

Sebelum menggunakan HTTPS, konfigurasi dapat berupa:

```yaml
bind-addr: 0.0.0.0:8787
auth: password
password: <password>
cert: false
```

---

# Backup Configuration

Sebelum melakukan perubahan configuration, buat backup terlebih dahulu.

## Create Backup Directory

```bash
BACKUP_DIR="$HOME/backup/code-server/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"
```

---

## Backup Configuration

```bash
cp -a \
  "$HOME/.config/code-server/config.yaml" \
  "$BACKUP_DIR/config.yaml"
```

Tampilkan lokasi backup:

```bash
echo "$BACKUP_DIR"
```

Contoh:

```text
/home/<username>/backup/code-server/20260808_140000
```

---

## Verify Backup

```bash
diff -u \
  "$HOME/.config/code-server/config.yaml" \
  "$BACKUP_DIR/config.yaml"
```

Tidak adanya output menunjukkan bahwa file current dan backup identik.

---

# Configure HTTPS

## Update Configuration

Ubah:

```yaml
cert: false
```

menjadi path certificate:

```yaml
cert: /home/<username>/ssl/server/server.crt
```

Kemudian tambahkan:

```yaml
cert-key: /home/<username>/ssl/server/server.key
```

---

## HTTPS Configuration

Contoh konfigurasi lengkap:

```yaml
bind-addr: 0.0.0.0:8787
auth: password
password: <password>
cert: /home/<username>/ssl/server/server.crt
cert-key: /home/<username>/ssl/server/server.key
```

Contoh menggunakan user `eddywiyatno`:

```yaml
bind-addr: 0.0.0.0:8787
auth: password
password: <password>
cert: /home/eddywiyatno/ssl/server/server.crt
cert-key: /home/eddywiyatno/ssl/server/server.key
```

---

## Configuration Parameters

| Parameter | Description |
| --------- | ----------- |
| `bind-addr` | Address dan port code-server |
| `auth` | Authentication method |
| `password` | Password authentication |
| `cert` | Path SSL/TLS Certificate |
| `cert-key` | Path SSL/TLS Private Key |

---

## Verify Configuration

```bash
cat ~/.config/code-server/config.yaml
```

Pastikan konfigurasi HTTPS terdapat:

```yaml
cert: /home/<username>/ssl/server/server.crt
cert-key: /home/<username>/ssl/server/server.key
```

---

# code-server Service

## Check Service

code-server dapat dijalankan menggunakan systemd template service.

Periksa:

```bash
sudo systemctl status code-server@$USER
```

Contoh:

```text
● code-server@eddywiyatno.service - code-server
     Loaded: loaded
     Active: active (running)
```

---

## Restart code-server

Restart service:

```bash
sudo systemctl restart code-server@$USER
```

---

## Verify Service Status

```bash
sudo systemctl status code-server@$USER --no-pager
```

Expected:

```text
Active: active (running)
```

---

# Verify HTTPS

## Verify Listening Port

Periksa port code-server:

```bash
ss -ltnp | grep 8787
```

Expected:

```text
LISTEN
0.0.0.0:8787
```

---

## Verify TLS Certificate

Periksa certificate yang benar-benar disajikan oleh code-server:

```bash
openssl s_client \
  -connect edkas-pc1:8787 \
  -servername edkas-pc1 \
  </dev/null 2>/dev/null |
openssl x509 \
  -noout \
  -subject \
  -issuer \
  -dates \
  -ext subjectAltName
```

Pastikan certificate yang ditampilkan sesuai dengan:

```text
~/ssl/server/server.crt
```

---

## Verify Certificate Chain

Gunakan CA untuk melakukan verification:

```bash
openssl s_client \
  -connect edkas-pc1:8787 \
  -servername edkas-pc1 \
  -CAfile ~/ssl/ca/ca.crt \
  </dev/null
```

Cari bagian:

```text
Verify return code: 0 (ok)
```

---

# Access VS Code Server

Buka browser menggunakan:

```text
https://edkas-pc1:8787
```

Kemudian login menggunakan authentication yang telah dikonfigurasi:

```yaml
auth: password
```

---

# Certificate Trust

Browser harus mempercayai Certificate Authority yang menerbitkan Server Certificate.

Dalam konfigurasi ini:

```text
Certificate Authority:

~/ssl/ca/ca.crt
```

Server menggunakan:

```text
~/ssl/server/server.crt
~/ssl/server/server.key
```

Client hanya perlu mempercayai:

```text
ca.crt
```

---

## Certificate Trust Architecture

```text
                    Internal Root CA
                          │
                          │ Trust
                          ▼
                       Client
                          │
                          │ HTTPS
                          ▼
                    code-server
                          │
                    ┌─────┴─────┐
                    │           │
              server.crt   server.key
```

---

## Client Certificate Trust

Apabila code-server diakses dari perangkat lain seperti:

- Laptop
- Desktop
- Tablet
- Mobile Device

maka perangkat tersebut harus mempercayai:

```text
ca.crt
```

Jangan memindahkan:

```text
ca.key
```

ke client.

---

# VS Code Webview

VS Code Server menggunakan **Webview** untuk beberapa fitur dan extension.

Webview membutuhkan browser environment yang mendukung **Secure Context**.

HTTP:

```text
HTTP
 │
 ▼
Insecure Context
 │
 └── Webview limitations
```

HTTPS:

```text
HTTPS
 │
 ▼
Secure Context
 │
 ▼
VS Code Webview
 │
 ▼
VS Code Extensions
```

---

# Codex Extension

Extension seperti **OpenAI Codex** menggunakan Webview untuk menyediakan interface pada VS Code.

Architecture:

```text
Browser
   │
   │ HTTPS
   ▼
code-server
   │
   ▼
VS Code Webview
   │
   ▼
Codex Extension
   │
   ▼
Codex App Server
```

---

# Webview Service Worker

VS Code Webview menggunakan Service Worker untuk beberapa fungsi internal.

Browser akan melakukan validasi certificate ketika resource Webview diakses.

```text
Browser
   │
   ▼
VS Code Webview
   │
   ▼
Service Worker
   │
   ▼
TLS Certificate Validation
   │
   ├── Trusted
   │      │
   │      ▼
   │   Webview Loaded
   │
   └── Not Trusted
          │
          ▼
       Webview Failed
```

---

# Troubleshooting

## Error Loading Webview

Salah satu error yang dapat muncul:

```text
Error loading webview:
Error: Could not register service worker
```

Contoh error:

```text
SecurityError:
Failed to register a ServiceWorker
```

atau:

```text
An SSL certificate error occurred when fetching the script.
```

---

## Certificate Not Trusted

Periksa certificate yang disajikan:

```bash
openssl s_client \
  -connect edkas-pc1:8787 \
  -servername edkas-pc1 \
  </dev/null 2>/dev/null |
openssl x509 \
  -noout \
  -subject \
  -issuer \
  -dates \
  -ext subjectAltName
```

Pastikan:

1. Certificate masih valid.
2. Hostname terdapat pada SAN.
3. Certificate diterbitkan oleh CA yang benar.
4. Client mempercayai `ca.crt`.

---

## Hostname Does Not Match

Jika code-server diakses:

```text
https://edkas-pc1:8787
```

maka certificate harus memiliki:

```text
DNS:edkas-pc1
```

Periksa:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -ext subjectAltName
```

Expected:

```text
X509v3 Subject Alternative Name:
    DNS:edkas-pc1
```

---

## Certificate Expired

Periksa validity:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -dates
```

Jika `notAfter` telah melewati waktu saat ini, certificate harus diperbarui.

---

## Wrong Certificate Served

Periksa certificate pada filesystem:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -subject \
  -issuer \
  -dates
```

Kemudian periksa certificate yang disajikan code-server:

```bash
openssl s_client \
  -connect edkas-pc1:8787 \
  -servername edkas-pc1 \
  </dev/null 2>/dev/null |
openssl x509 \
  -noout \
  -subject \
  -issuer \
  -dates
```

Kedua output harus sesuai.

---

# Verify HTTPS with curl

Test HTTPS:

```bash
curl https://edkas-pc1:8787
```

Jika CA belum tersedia pada system trust store:

```bash
curl \
  --cacert ~/ssl/ca/ca.crt \
  https://edkas-pc1:8787
```

Untuk troubleshooting saja, certificate verification dapat dilewati menggunakan:

```bash
curl -k https://edkas-pc1:8787
```

> `-k` hanya digunakan untuk troubleshooting. Jangan digunakan sebagai konfigurasi normal.

---

# Verify TLS Connection

Gunakan:

```bash
openssl s_client \
  -connect edkas-pc1:8787 \
  -servername edkas-pc1
```

Perintah tersebut menampilkan:

- TLS handshake
- Certificate
- Certificate chain
- Cipher
- Verification result

Keluar dari session:

```text
Ctrl+C
```

---

# Verify Port

Periksa code-server:

```bash
ss -ltnp | grep 8787
```

Expected:

```text
LISTEN
0.0.0.0:8787
```

---

# HTTPS Architecture

```text
                         Internal Root CA
                                │
                                │ Sign
                                ▼
                         server.crt
                                │
                                │
                         server.key
                                │
                                ▼
┌──────────────┐          HTTPS          ┌──────────────────┐
│    Client    │ ─────────────────────► │   code-server    │
│              │                         │                  │
│ Browser      │                         │ VS Code Server   │
│ Tablet       │                         │ Port 8787        │
└──────────────┘                         └────────┬─────────┘
                                                 │
                                                 ▼
                                          VS Code Webview
                                                 │
                                                 ▼
                                          VS Code Extension
                                                 │
                                                 ▼
                                             Codex
```

---

# Backup and Recovery

Setiap perubahan configuration harus didahului backup.

## Backup

```bash
BACKUP_DIR="$HOME/backup/code-server/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

cp -a \
  "$HOME/.config/code-server/config.yaml" \
  "$BACKUP_DIR/config.yaml"

echo "Backup: $BACKUP_DIR"
```

---

## Restore Configuration

Apabila konfigurasi HTTPS menyebabkan masalah:

```bash
cp -a \
  "$BACKUP_DIR/config.yaml" \
  "$HOME/.config/code-server/config.yaml"
```

Restart:

```bash
sudo systemctl restart code-server@$USER
```

Verify:

```bash
sudo systemctl status code-server@$USER --no-pager
```

---

# Verification Checklist

| Check | Expected Result |
| ----- | --------------- |
| code-server installed | ✅ |
| OpenSSL installed | ✅ |
| CA available | ✅ |
| Server Certificate available | ✅ |
| Server Private Key available | ✅ |
| Certificate SAN correct | ✅ |
| Certificate chain valid | ✅ |
| Private Key protected | ✅ |
| Configuration backed up | ✅ |
| `config.yaml` configured | ✅ |
| code-server restarted | ✅ |
| Port `8787` listening | ✅ |
| HTTPS accessible | ✅ |
| CA trusted by client | ✅ |
| VS Code Webview working | ✅ |
| VS Code Extensions working | ✅ |
| Codex Webview working | ✅ |

---

# Final Configuration

Example:

```yaml
bind-addr: 0.0.0.0:8787
auth: password
password: <password>
cert: /home/<username>/ssl/server/server.crt
cert-key: /home/<username>/ssl/server/server.key
```

Access:

```text
https://edkas-pc1:8787
```

---

# Final Architecture

```text
                    Internal Root CA
                          │
                          │
                          ▼
                    server.crt
                          │
                          │
                    server.key
                          │
                          ▼
                    code-server
                          │
                          │ HTTPS
                          ▼
                       Browser
                          │
                          ▼
                    VS Code Webview
                          │
                          ▼
                    Codex Extension
                          │
                          ▼
                       Codex
```

---

# Summary

```text
Create Internal CA
       │
       ▼
Create Server Private Key
       │
       ▼
Create SAN Configuration
       │
       ▼
Create CSR
       │
       ▼
Sign CSR with CA
       │
       ▼
Create Server Certificate
       │
       ▼
Verify Certificate
       │
       ▼
Backup code-server Configuration
       │
       ▼
Configure HTTPS
       │
       ▼
Restart code-server
       │
       ▼
Verify HTTPS
       │
       ▼
Trust CA on Client
       │
       ▼
VS Code Webview
       │
       ▼
VS Code Extensions
       │
       ▼
Codex
```
# Create SSL Certificate

## Overview

SSL/TLS Certificate digunakan untuk mengenkripsi komunikasi antara **Client** dan **Server** menggunakan protokol HTTPS.

Pada environment development, lab, maupun internal infrastructure, SSL/TLS Certificate dapat dibuat menggunakan **OpenSSL**.

Dokumen ini menggunakan pendekatan **Private Certificate Authority (CA)** untuk menerbitkan Server Certificate.

```text
                    Internal Root CA
                          │
                          │ Signs
                          ▼
                  Server Certificate
                          │
                          ▼
                       Server
                          │
                          │ HTTPS
                          ▼
                       Client
```

---

## Prerequisites

Pastikan OpenSSL tersedia.

```bash
openssl version
```

Contoh:

```text
OpenSSL 3.0.x
```

---

## SSL/TLS Components

Dalam konfigurasi ini terdapat beberapa komponen:

| Component | Description |
| --------- | ----------- |
| `ca.key` | Private Key Certificate Authority |
| `ca.crt` | Certificate Authority Certificate |
| `server.key` | Server Private Key |
| `server.csr` | Certificate Signing Request |
| `server.crt` | Server SSL/TLS Certificate |
| `server.ext` | Certificate Extension Configuration |

---

## Certificate Architecture

```text
                    Certificate Authority
                              │
                    ┌─────────┴─────────┐
                    │                   │
                 ca.key               ca.crt
               Private Key          CA Certificate
                    │                   │
                    │                   │
                    └─────────┬─────────┘
                              │
                              │ Sign
                              ▼
                       Server Certificate
                              │
                    ┌─────────┴─────────┐
                    │                   │
              server.key          server.crt
              Private Key        Server Certificate
```

---

## Create SSL Directory

Buat directory untuk menyimpan CA dan Server Certificate.

```bash
mkdir -p ~/ssl/{ca,server}
```

Struktur directory:

```text
~/ssl/
├── ca/
└── server/
```

---

# Certificate Authority

## Generate CA Private Key

Generate Private Key untuk Certificate Authority.

```bash
openssl genrsa \
  -out ~/ssl/ca/ca.key \
  4096
```

Verify:

```bash
ls -lah ~/ssl/ca/
```

Expected:

```text
ca.key
```

---

## Protect CA Private Key

CA Private Key harus dilindungi.

```bash
chmod 600 ~/ssl/ca/ca.key
```

Verify:

```bash
ls -l ~/ssl/ca/ca.key
```

Expected:

```text
-rw------- ... ca.key
```

---

## Generate CA Certificate

Buat Certificate Authority Certificate:

```bash
openssl req \
  -x509 \
  -new \
  -nodes \
  -key ~/ssl/ca/ca.key \
  -sha256 \
  -days 3650 \
  -out ~/ssl/ca/ca.crt \
  -subj "/C=ID/O=Internal CA/CN=Internal Root CA"
```

Certificate berlaku selama:

```text
3650 days
```

atau sekitar 10 tahun.

---

## Verify CA Certificate

```bash
openssl x509 \
  -in ~/ssl/ca/ca.crt \
  -noout \
  -subject \
  -issuer \
  -dates
```

Contoh:

```text
subject=C = ID, O = Internal CA, CN = Internal Root CA
issuer=C = ID, O = Internal CA, CN = Internal Root CA
```

Karena ini merupakan Root CA:

```text
Subject = Issuer
```

---

## CA Files

Setelah CA dibuat:

```text
~/ssl/ca/
├── ca.key
└── ca.crt
```

| File | Description |
| ---- | ----------- |
| `ca.key` | CA Private Key |
| `ca.crt` | CA Certificate |

---

## CA Security

`ca.key` merupakan **Private Key Certificate Authority**.

File tersebut sangat sensitif.

```text
ca.key
```

Tidak boleh:

- Dibagikan ke client.
- Disimpan pada web server.
- Dimasukkan ke repository Git.
- Dikirim melalui email.
- Diberikan kepada user yang tidak membutuhkan akses.

Apabila `ca.key` compromised, attacker dapat menerbitkan certificate baru yang dipercaya oleh seluruh client yang mempercayai CA tersebut.

---

# Server Certificate

## Generate Server Private Key

Generate Private Key untuk server.

```bash
openssl genrsa \
  -out ~/ssl/server/server.key \
  2048
```

Verify:

```bash
ls -lah ~/ssl/server/server.key
```

---

## Protect Server Private Key

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

## Create Certificate Extension File

Certificate modern membutuhkan **Subject Alternative Name (SAN)**.

Buat file:

```bash
nano ~/ssl/server/server.ext
```

Isi:

```ini
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1=edkas-pc1
DNS.2=localhost
IP.1=127.0.0.1
```

---

## Subject Alternative Name

SAN menentukan hostname dan IP Address yang valid untuk certificate.

Pada contoh di atas:

```text
DNS:edkas-pc1
DNS:localhost
IP:127.0.0.1
```

Certificate valid apabila server diakses menggunakan:

```text
https://edkas-pc1
```

atau:

```text
https://localhost
```

atau:

```text
https://127.0.0.1
```

---

## Certificate Extension

Penjelasan parameter:

| Parameter | Purpose |
| --------- | ------- |
| `basicConstraints=CA:FALSE` | Certificate bukan Certificate Authority |
| `keyUsage=digitalSignature,keyEncipherment` | Key digunakan untuk TLS |
| `extendedKeyUsage=serverAuth` | Certificate digunakan untuk Server Authentication |
| `subjectAltName` | Menentukan hostname/IP yang valid |

---

## Generate Certificate Signing Request

Generate Certificate Signing Request (CSR):

```bash
openssl req \
  -new \
  -key ~/ssl/server/server.key \
  -out ~/ssl/server/server.csr \
  -subj "/C=ID/O=Internal/CN=edkas-pc1"
```

---

## Verify CSR

```bash
openssl req \
  -in ~/ssl/server/server.csr \
  -noout \
  -subject
```

Expected:

```text
subject=C = ID, O = Internal, CN = edkas-pc1
```

---

## Sign Server Certificate

Sign CSR menggunakan Certificate Authority:

```bash
openssl x509 \
  -req \
  -in ~/ssl/server/server.csr \
  -CA ~/ssl/ca/ca.crt \
  -CAkey ~/ssl/ca/ca.key \
  -CAcreateserial \
  -out ~/ssl/server/server.crt \
  -days 825 \
  -sha256 \
  -extfile ~/ssl/server/server.ext
```

Certificate berlaku selama:

```text
825 days
```

---

## Server Certificate Files

Setelah certificate berhasil dibuat:

```text
~/ssl/server/
├── server.key
├── server.csr
├── server.crt
└── server.ext
```

---

## Verify Server Certificate

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

Verify Server Certificate menggunakan CA:

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

# Certificate Trust

## Install CA Certificate on Client

Agar browser atau client mempercayai Server Certificate, client harus mempercayai:

```text
ca.crt
```

Contoh:

```text
Server
│
├── server.crt
└── server.key

Client
│
└── ca.crt
```

---

## CA Certificate Distribution

`ca.crt` dapat didistribusikan kepada client yang membutuhkan akses ke internal HTTPS service.

Contoh:

```text
Internal CA
     │
     ├── Laptop
     ├── Desktop
     ├── Tablet
     └── Server
```

Jangan distribusikan:

```text
ca.key
```

---

# Certificate Verification

## Verify Certificate Subject

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -subject
```

---

## Verify Certificate Issuer

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -issuer
```

Expected:

```text
issuer=... Internal Root CA
```

---

## Verify Certificate Validity

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -dates
```

Example:

```text
notBefore=Aug  8 08:00:00 2026 GMT
notAfter=Nov 10 08:00:00 2028 GMT
```

---

## Verify SAN

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
    DNS:localhost
    IP Address:127.0.0.1
```

---

## Verify Certificate Chain

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

# Verify Certificate From Running HTTPS Service

Apabila certificate telah digunakan oleh HTTPS service, certificate yang benar-benar disajikan oleh service dapat diperiksa menggunakan:

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

Command ini berguna untuk memastikan certificate yang digunakan oleh service sesuai dengan certificate yang telah dibuat.

---

# Common SSL/TLS Problems

## Certificate Does Not Match Hostname

Misalnya certificate hanya memiliki:

```text
DNS:localhost
```

tetapi service diakses menggunakan:

```text
https://edkas-pc1:8787
```

Certificate tidak valid untuk hostname tersebut.

Tambahkan hostname ke SAN:

```ini
[alt_names]
DNS.1=edkas-pc1
DNS.2=localhost
IP.1=127.0.0.1
```

Kemudian generate ulang certificate.

---

## Certificate Authority Is Not Trusted

Error yang dapat muncul:

```text
NET::ERR_CERT_AUTHORITY_INVALID
```

atau:

```text
SSL certificate error
```

Pastikan client mempercayai:

```text
ca.crt
```

---

## Certificate Expired

Periksa:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -dates
```

Jika `notAfter` sudah melewati waktu saat ini, certificate harus diperbarui.

---

## Wrong Certificate Is Being Served

Periksa certificate dari service:

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

Bandingkan dengan:

```bash
openssl x509 \
  -in ~/ssl/server/server.crt \
  -noout \
  -subject \
  -issuer \
  -dates
```

---

# Security Consideration

## Private Key

Private Key harus dilindungi.

Server:

```text
server.key
```

Certificate Authority:

```text
ca.key
```

Permission:

```bash
chmod 600 ~/ssl/server/server.key
chmod 600 ~/ssl/ca/ca.key
```

---

## Never Commit Private Keys

Jangan memasukkan private key ke Git repository.

Contoh `.gitignore`:

```text
*.key
*.csr
*.srl
```

---

## Certificate Authority Private Key

`ca.key` memiliki risiko paling tinggi.

```text
ca.key
```

Jika CA Private Key compromised, attacker dapat membuat certificate baru yang dipercaya oleh client yang mempercayai CA tersebut.

Oleh karena itu:

```text
ca.key
```

sebaiknya hanya tersedia pada sistem yang bertugas melakukan certificate signing.

---

# Certificate Directory Structure

Contoh struktur final:

```text
~/ssl/
│
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

---

# Certificate Lifecycle

```text
Generate CA Private Key
          │
          ▼
Generate CA Certificate
          │
          ▼
Generate Server Private Key
          │
          ▼
Create SAN Configuration
          │
          ▼
Generate CSR
          │
          ▼
Sign CSR with CA
          │
          ▼
Generate Server Certificate
          │
          ▼
Verify Certificate
          │
          ▼
Install CA Certificate on Client
          │
          ▼
Configure HTTPS Service
          │
          ▼
Verify HTTPS
```

---

# Summary

```text
                    Internal Root CA
                          │
                    ca.key / ca.crt
                          │
                          │ Sign
                          ▼
                    server.crt
                          │
                          │
                    server.key
                          │
                          ▼
                    HTTPS Server
                          │
                          │ HTTPS
                          ▼
                        Client
                          │
                          │ Trust
                          ▼
                        ca.crt
```
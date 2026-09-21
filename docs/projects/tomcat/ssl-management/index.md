# SSL & TLS Certificate Management

## 🔍 Overview

Spesifikasi **Manajemen SSL Certificate** menjamin komunikasi terenkripsi yang aman (*in-transit encryption*) dengan otomasi penerbitan, perpanjangan (*renewal*), dan pemantauan masa aktif sertifikat tanpa menyebabkan *downtime*.

---

## 🔒 Pola Arsitektur SSL

### Pola A: Edge TLS Termination (Disarankan)
Sertifikat publik dikelola terpusat pada Reverse Proxy (Nginx).
* **Otomasi**: Menggunakan Certbot / ACME protocol (Let's Encrypt / Internal CA).
* **Hot-Reload**: Perpanjangan sertifikat dieksekusi dengan `nginx -s reload` tanpa menyentuh container Tomcat maupun merestart JVM.

### Pola B: Native End-to-End TLS di Tomcat
Jika kepatuhan regulasi mewajibkan enkripsi hingga ke level engine Tomcat:
Tomcat 9.0+ mendukung konektor OpenSSL berbasis file PEM standar tanpa perlu konversi format Java Keystore (`.jks`):
```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true">
    <SSLHostConfig protocols="TLSv1.2+TLSv1.3"
                   ciphers="HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK">
        <Certificate certificateFile="/etc/ssl/tomcat/cert.pem"
                     certificateKeyFile="/etc/ssl/tomcat/privkey.pem"
                     certificateChainFile="/etc/ssl/tomcat/chain.pem"
                     type="RSA" />
    </SSLHostConfig>
</Connector>
```

---

## 🚨 Pemantauan & Peringatan Kadaluarsa (Expiry Alerting)

Integrasi pemantauan masa berlaku sertifikat dilakukan melalui Prometheus dan Alertmanager:
* **Threshold Warning**: Memicu notifikasi saat sisa masa berlaku sertifikat `< 30 hari`.
* **Threshold Critical**: Memicu eskalasi prioritas tinggi saat sisa masa berlaku `< 7 hari`.

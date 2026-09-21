# Security Hardening Specification

## 🔍 Overview

Spesifikasi **Security Hardening** menetapkan kontrol keamanan berlapis (*defense-in-depth*) untuk Apache Tomcat dan container runtime. Implementasi mengacu pada pedoman **CIS Apache Tomcat Benchmark** dan **CIS Docker/Container Benchmark**.

---

## 🛡️ Kontrol Keamanan Level Container (Podman)

1. **Non-Root Execution**:
   Container tidak boleh dieksekusi sebagai user `root`. Image dikonfigurasi dengan user unprivileged `tomcat` (UID `1001`, GID `1001`).
2. **Read-Only Root Filesystem**:
   Container dijalankan dengan flag `--read-only`. Hal ini mencegah penulisan backdoor atau modifikasi biner oleh penyerang jika terjadi eksploitasi code execution.
3. **Penghapusan Hak Akses Linux (*Capabilities Drop*)**:
   Seluruh capability Linux standar dicabut menggunakan `--cap-drop=ALL`.
4. **Pencegahan Eskalasi Privilege**:
   Parameter `--security-opt=no-new-privileges:true` diaktifkan untuk mencegah proses child memperoleh hak akses lebih tinggi melalui bit SUID/SGID.

---

## ⚙️ Kontrol Keamanan Level Tomcat Engine

### 1. Penonaktifan Shutdown Port
Pada `conf/server.xml`, ubah port shutdown menjadi `-1`:
```xml
<Server port="-1" shutdown="SHUTDOWN">
```

### 2. Penghapusan Default Webapps
Seluruh aplikasi bawaan yang tidak diperlukan wajib dihapus saat proses build image:
- `ROOT` (default welcome page)
- `docs` (dokumentasi Tomcat)
- `examples` (contoh servlet dan JSP)
- `manager` (Tomcat Web Application Manager)
- `host-manager` (Virtual Host Manager)

### 3. Server Header Masking & Error Suppression
Mencegah *information leakage* mengenai versi runtime:
```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           server="ApplicationServer"
           xpoweredBy="false" />

<Valve className="org.apache.catalina.valves.ErrorReportValve"
       showReport="false"
       showServerInfo="false" />
```

### 4. Enforce HTTP Security Headers
Menyisipkan header keamanan standar industri secara global pada respons HTTP:
```xml
<Valve className="org.apache.catalina.valves.HttpHeaderSecurityValve"
       antiClickJackingOption="DENY"
       antiClickJackingEnabled="true"
       blockContentTypeSniffingEnabled="true"
       xssProtectionEnabled="true"
       hstsEnabled="true"
       hstsMaxAgeSeconds="31536000" />
```

### 5. Secure Session & Cookie Processor (`conf/context.xml`)
Memastikan session cookie (`JSESSIONID`) terlindungi dari serangan XSS dan CSRF:
```xml
<Context useHttpOnly="true">
    <CookieProcessor sameSiteCookies="lax" />
</Context>
```

# Architecture Specification

## 🔍 Overview

Halaman ini mendefinisikan arsitektur sistem dan topologi runtime untuk **Apache Tomcat Enterprise Solution** berbasis Podman. Desain mengadopsi prinsip isolasi proses, minimal footprint container, dan decoupled state.

---

## 🏛️ Desain Runtime & Topologi Container

Tomcat dijalankan sebagai container OCI independen di atas jaringan terisolasi (`devops-lab`). Container ini beroperasi di belakang Reverse Proxy Nginx untuk terminasi TLS publik.

```
 +---------------------------------------------------------------------------------+
 | HOST ENVIRONMENT (Linux / Podman Runtime)                                       |
 |                                                                                 |
 |  [Bridge Network: devops-lab]                                                   |
 |                                                                                 |
 |   +----------------------------+             +------------------------------+   |
 |   | Nginx Reverse Proxy        |             | Tomcat Application Container |   |
 |   | - Port 80 / 443 (Host)     |             | - Non-root: tomcat (1001)    |   |
 |   | - TLS Termination          |             | - Read-Only Root Filesystem  |   |
 |   | - Upstream keepalive       |             | - Port 8080 (Internal HTTP)  |   |
 |   +-------------+--------------+             | - Port 9404 (JMX Metrics)    |   |
 |                 |                            +--------------+---------------+   |
 |                 +----- proxy_pass :8080 --------------------+                   |
 |                                                             |                   |
 |   +----------------------------+                            |                   |
 |   | Prometheus Monitoring      |                            |                   |
 |   | - Scrapes :9404 metrics    |<---------------------------+                   |
 |   +----------------------------+                                                |
 +---------------------------------------------------------------------------------+
```

---

## 💾 Model Penyimpanan & Volume Separation

Sesuai standar containerisasi cloud-native, root filesystem container dibuat *immutable* (*read-only*). Data persisten dan direktori kerja dialokasikan secara eksplisit:

| Target Path di Container | Jenis Mount | Izin Akses | Deskripsi & Tujuan |
| :--- | :--- | :--- | :--- |
| `/usr/local/tomcat/conf` | Podman Named Volume (`conf_vol`) | Read-Only / Strict | Menyimpan konfigurasi `server.xml`, `web.xml`, `context.xml`. |
| `/usr/local/tomcat/webapps` | Podman Named Volume (`webapps_vol`)| Read-Write (`tomcat:1001`) | Lokasi penyimpanan artefak aplikasi (`ROOT.war`). |
| `/usr/local/tomcat/logs` | Podman Named Volume (`logs_vol`) | Read-Write (`tomcat:1001`) | Log rotasi catalina dan access log (retensi 14-30 hari). |
| `/usr/local/tomcat/temp` | `tmpfs` RAM Mount | Read-Write (`tomcat:1001`) | Direktori temporary JVM dan I/O Tomcat. |
| `/usr/local/tomcat/work` | `tmpfs` RAM Mount | Read-Write (`tomcat:1001`) | Kompilasi file JSP dan runtime context scratch. |
| `/tmp` & `/run` | `tmpfs` RAM Mount | Read-Write (`nosuid,nodev`) | File sementara sistem operasi. |

---

## 🌐 Alokasi Port & Jaringan

* **Port 8080 (HTTP)**: Konektor web aplikasi Tomcat utama. Hanya diekspos ke jaringan internal container (`devops-lab`), tidak dibuka langsung ke publik tanpa reverse proxy.
* **Port 8009 (AJP)**: **Dinonaktifkan (*Disabled*)**. Konektor AJP dihilangkan untuk memitigasi celah eksploitasi Ghostcat.
* **Port 8005 (Shutdown)**: **Dinonaktifkan (*Port -1*)**. Perintah shutdown via socket TCP dimatikan; lifecycle container dikontrol penuh via sinyal OS (`SIGTERM`/`SIGKILL`).
* **Port 9404 (Monitoring)**: Endpoint internal HTTP untuk Prometheus JMX Exporter agent.

# Update Management Specification

## 🔍 Overview

Spesifikasi **Manajemen Update** mengatur tata kelola patching berkala, pembaruan base image, dan rilis versi aplikasi tanpa menghentikan ketersediaan layanan (*zero-downtime deployment*).

---

## 🔄 Strategi Rilis Blue-Green (Podman & Nginx)

Untuk lingkungan container berbasis Podman, pembaruan dilakukan dengan strategi **Blue-Green Deployment**:

```
 1. Initial State:
    [Nginx Proxy] ----> [Tomcat-Blue (Active :8081)]

 2. Deploy Green & Warmup:
    [Nginx Proxy] ----> [Tomcat-Blue (Active :8081)]
                        [Tomcat-Green (Standby :8082)] <--- Run Healthcheck / Smoke Test

 3. Traffic Cutover:
    [Nginx Proxy] ----> [Tomcat-Green (Active :8082)] (via nginx -s reload)
                        [Tomcat-Blue (Draining...)]

 4. Cleanup:
    [Tomcat-Blue] terminated gracefully.
```

---

## 🛑 Penanganan Graceful Shutdown

Saat container dihentikan atau di-update, proses Tomcat tidak boleh dimatikan secara mendadak (`kill -9`). 

* **Konfigurasi `server.xml`**:
  ```xml
  <Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true" unloadDelay="10000">
  ```
  `unloadDelay="10000"` memberi toleransi waktu hingga 10 detik bagi servlet untuk menyelesaikan request yang sedang berjalan sebelum context di-destroy.
* **Penanganan Sinyal di `entrypoint.sh`**:
  Entrypoint script mengimplementasikan perangkap sinyal (`trap 'kill -TERM $PID' TERM INT`) sehingga sinyal `SIGTERM` dari Podman diteruskan dengan aman ke JVM Tomcat.

---

## ⏪ Mekanisme Instant Rollback

Jika container versi baru (`Green`) gagal merespons HTTP 200 pada interval verifikasi (misal: 60 detik pasca-start):
1. Script deployment mendeteksi kegagalan healthcheck.
2. Alur rilis dibatalkan secara otomatis.
3. Upstream Nginx tetap mengarah ke container versi lama (`Blue`).
4. Container baru dihentikan dan log error disimpan untuk keperluan investigasi.

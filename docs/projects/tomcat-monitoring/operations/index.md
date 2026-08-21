# Operations

## Overview

Bagian ini menjelaskan informasi monitoring yang dibutuhkan operator untuk
menilai availability, kesehatan JVM, dan kemampuan Tomcat menangani beban
aplikasi.

## Monitoring Coverage

### Apakah Tomcat tersedia?

- Memastikan Prometheus dapat mengambil metrics dari JMX Exporter.
- Memastikan Telegraf menerima response dari HTTP health endpoint aplikasi.
- Mendeteksi timeout, unexpected HTTP status, atau response body yang tidak
  sesuai.
- Memastikan HTTP health metrics tetap diterima oleh Prometheus.

### Apakah JVM dalam kondisi sehat?

- Memantau penggunaan heap, non-heap, dan memory pool.
- Memantau frekuensi dan durasi garbage collection.
- Memantau jumlah thread serta perubahan status thread.
- Memantau aktivitas class loading dan unloading.

### Apakah Tomcat mampu menangani beban aplikasi?

- Memantau penggunaan thread pada connector Tomcat.
- Membandingkan active thread dengan kapasitas maximum thread.
- Memantau jumlah request, error, waktu pemrosesan, dan throughput.
- Memantau session yang aktif, dibuat, kedaluwarsa, atau ditolak.

### Apa yang terjadi sebelumnya?

Prometheus menyimpan time-series metrics agar operator dapat menganalisis
kejadian, mengenali pola, dan membandingkan kondisi sebelum dan sesudah masalah
terjadi.

!!! note "Memahami Status Monitoring"

    Metric `up` hanya menunjukkan bahwa Prometheus berhasil mengambil metrics
    dari JMX Exporter. Nilai tersebut belum membuktikan bahwa aplikasi dapat
    melayani request dengan benar.

    Telegraf memeriksa HTTP health endpoint aplikasi melalui container network
    yang sama dengan Tomcat. Health check gagal ketika terjadi timeout,
    unexpected HTTP status, atau response body tidak sesuai.

## Status Interpretation

| JMX Exporter | Local HTTP Health | Initial Interpretation |
| --- | --- | --- |
| Available | Healthy | JVM, Tomcat, dan aplikasi sehat dari sisi lokal |
| Available | Failed | JVM hidup, tetapi aplikasi gagal atau hang ketika melayani request |
| Unavailable | Healthy | Aplikasi merespons, tetapi exporter, TLS, atau scrape configuration bermasalah |
| Unavailable | Failed | Container, JVM, exporter, TLS, atau internal network bermasalah |
| Available | Metric missing | Telegraf atau alur pengumpulan health metrics bermasalah |

Tidak adanya alert HTTP hanya dapat dipercaya jika health metrics Telegraf
masih diterima. Karena itu, alert untuk missing metrics harus tersedia selain
alert untuk hasil health check yang gagal.

Jika local HTTP health tetap normal tetapi aplikasi tidak dapat diakses oleh
pengguna, investigasi dilanjutkan pada jalur eksternal seperti reverse proxy,
load balancer, DNS, firewall, atau network. Jalur eksternal tersebut berada di
luar scope Tomcat Monitoring.

## Current Status

Monitoring end-to-end belum diimplementasikan. JMX Exporter dan endpoint HTTPS
`9404/metrics` telah diverifikasi secara lokal, tetapi belum diintegrasikan
dengan Prometheus. Health check Telegraf, dashboard, alerting, dan external
integration masih menjadi target capability project.

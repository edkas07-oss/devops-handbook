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

Monitoring end-to-end belum diimplementasikan. Persistent lab Prometheus telah
lulus semantic configuration dan readiness verification, serta dashboard dapat
dibuka dari tablet melalui VPN menggunakan `http://edkas-pc1:9090`.

Persistent generic JMX target berjalan pada `devops-lab` tanpa host-published
metrics port. Prometheus mengambil metrics melalui HTTPS dengan hostname
verification dan `insecure_skip_verify: false`; target menghasilkan `up=1`.
Pre-cutover strict verification menolak certificate yang belum dipercaya dengan
`up=0` dan error unknown authority. Setelah public certificate dipasang pada
persistent truststore, target pulih menjadi `up=1`.

Persistent Prometheus menggunakan `prometheus_data` yang sama, menemukan
healthy TSDB blocks, menyelesaikan WAL replay, dan mencapai readiness tanpa
restart. JVM heap metric tersedia sebagai `jvm_memory_heap_used_bytes`.
Tomcat MBean tersedia sebagai canonical series `tomcat_server` setelah
reconciliation TN-017. Full operational metric catalog belum
diimplementasikan.

Persistent lab Telegraf memeriksa JSP application endpoint
`http://tomcat-jmx-exporter:8080/health` melalui `devops-lab`. Direct endpoint
menghasilkan HTTP `200` dan JSON `{"status":"UP"}`. Telegraf menghasilkan
status-code match `1`, string match `1`, dan result code `0`; Prometheus scrape
pool `telegraf-health` menghasilkan `up=1`. Endpoint, Telegraf metrics, dan JMX
metrics pulih setelah controlled restart tanpa host-published port baru.

Health result ini membuktikan lab fixture diproses Tomcat dari local container
network. Ia tidak membuktikan production application dependencies atau jalur
akses eksternal. Application-health alert rules telah dimuat pada persistent
Prometheus dan lulus isolated firing/resolved verification untuk non-zero
result, missing health series, dan Telegraf scrape unavailable. Persistent
Prometheus mengirim real Telegraf scrape-unavailable firing/resolved state ke
persistent Alertmanager pada 2026-08-28; lab-only Mailpit menangkap kedua email
dan baseline Telegraf, JMX, rules, serta health metric pulih. External
notification dan Integration Bridge masih menjadi target capability project.

## Diagnostic MVP Operational Status

The accepted `TomcatDown` pilot will treat JMX `up=0` as a trigger and correlate
application health, logs, crash artifacts, and restricted runtime/host evidence
for the same target. Application health can show that Tomcat still serves the
lab application while the JMX/TLS/scrape path fails; it does not become a
separate diagnostic rule.

Diagnostic Service health/metrics endpoints, durable queue, SQLite migrations,
canonical-result persistence, and graceful shutdown exist in source and passed
disposable image verification. They are not deployed as an operator-visible
runtime. SMTP worker orchestration dan resolved correlation telah lulus
source/socket tests, tetapi rebuilt image, actual diagnostic email in Mailpit,
housekeeping/capacity behavior, and end-to-end evidence remain unavailable.
Operators must continue using the verified monitoring and direct Mailpit flow
until persistent diagnostic deployment is explicitly approved and verified.

## Operational Runbooks & AI Knowledge Management

Untuk prosedur operasional pengelolaan basis pengetahuan diagnosis (*declarative rulepacks*), impor/ekspor katalog master, dan alur pengayaan berbasis AI secara proaktif maupun reaktif, silakan merujuk ke:

* [Runbook: AI Knowledge Enrichment & Declarative Rule Management](ai-knowledge-enrichment-and-rule-management-runbook.md)
* [Tomcat Diagnostic Service REST API Reference](../references/diagnostic-service-rest-api-reference.md)
* [Prometheus Metrics Catalog & PromQL Reference](../references/prometheus-metrics-catalog.md)


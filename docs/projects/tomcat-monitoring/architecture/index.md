# Architecture

## Overview

Arsitektur Tomcat Monitoring menempatkan JMX Exporter sebagai Java Agent di
dalam JVM Tomcat. Prometheus berjalan sebagai container terpisah di dalam
monitoring stack project dan mengambil metrics melalui endpoint HTTPS. Telegraf
memeriksa HTTP health endpoint aplikasi melalui container network yang sama
dengan Tomcat. TrueSight berada di luar deployment boundary project sebagai
event management integration.

## Deployment Topology

```mermaid
flowchart TB
    DB["Monitoring Platform<br/>Dashboard and Alert"]
    PM["Monitoring Platform<br/>Prometheus Container"]
    TG["Monitoring Platform<br/>Telegraf Container"]
    AM["Monitoring Platform<br/>Alertmanager"]

    TC["Tomcat Container<br/>Apache Tomcat JVM"]
    JM["Tomcat Container<br/>JMX Exporter Java Agent"]
    APP["Tomcat Container<br/>Application HTTP Health Endpoint"]

    NC["External Integration<br/>Notification Channel"]
    BR["External Integration<br/>Integration Bridge"]
    TS["External Integration<br/>TrueSight"]

    DB -->|"1. Query current and historical metrics"| PM

    PM -->|"2. HTTPS GET /metrics<br/>Server-side TLS"| JM
    TC -->|"Expose JVM and Tomcat metrics"| JM

    PM -->|"3. Scrape HTTP health metrics"| TG
    TG -->|"4. Local HTTP GET /health"| APP
    TC -->|"Serve application health"| APP

    PM -->|"5. Send firing and resolved alerts"| AM
    AM -->|"6a. Route alert"| NC
    AM -.->|"6b. Webhook JSON"| BR
    BR -.->|"7. SNMP Trap / msend"| TS
```

Nomor pada diagram menunjukkan hubungan komunikasi, bukan urutan startup
container. Nama lokasi ditulis langsung pada setiap komponen agar arah
komunikasi tidak bergantung pada posisi atau batas subgraph. Prometheus dan
Telegraf menjalankan pemeriksaan secara berkala sesuai interval yang akan
ditetapkan.

## Monitoring Flow

```mermaid
sequenceDiagram
    autonumber
    participant APP as Tomcat Application
    participant TG as Telegraf
    participant JM as JMX Exporter
    participant PM as Prometheus
    participant DB as Dashboard and Alert
    participant AM as Alertmanager
    participant NC as Notification Channel
    participant BR as Integration Bridge
    participant TS as TrueSight

    loop Local application health interval
        TG->>APP: HTTP GET /health
        APP-->>TG: Status code, response body, response time
    end

    loop Prometheus scrape interval
        PM->>JM: HTTPS GET /metrics
        JM-->>PM: JVM and Tomcat metrics
        PM->>TG: Scrape HTTP health metrics
        TG-->>PM: Health result and response time
    end

    DB->>PM: Query current and historical metrics
    PM-->>DB: Time-series data

    alt Alert rule is firing or resolved
        PM->>AM: Send alert state
        par Generic notification route
            AM->>NC: Route alert
        and Current TrueSight integration
            AM->>BR: Webhook JSON
            BR->>TS: SNMP Trap or msend
        end
    end
```

Sequence diagram menegaskan bahwa Prometheus dan Telegraf menggunakan model
pull. Telegraf memulai HTTP health check terhadap aplikasi, sedangkan Prometheus
melakukan scrape terhadap JMX Exporter dan Telegraf.

## Architecture Components

| Component | Responsibility |
| --- | --- |
| Tomcat Container | Menjalankan application runtime dan JVM yang dimonitor |
| JMX Exporter | Membaca MBean secara lokal dan menyajikan Prometheus metrics |
| Prometheus | Melakukan scrape, menyimpan time-series, dan mengevaluasi alert rules |
| Telegraf | Memeriksa HTTP status, response time, timeout, dan response body aplikasi |
| Dashboard and Alert | Melakukan query ke Prometheus serta menampilkan metrics dan status alert |
| Alertmanager | Mengelompokkan, melakukan deduplication, dan meneruskan alert |
| Integration Bridge | Mengubah webhook menjadi event yang diterima TrueSight |

## Security Controls

- Remote JMX tidak diaktifkan atau diekspos melalui jaringan.
- JMX Exporter menyajikan endpoint metrics menggunakan server-side TLS.
- Prometheus memverifikasi sertifikat JMX Exporter menggunakan Certificate
  Authority yang dipercaya.
- JMX Exporter tidak meminta client certificate dari Prometheus.
- Endpoint metrics hanya menerima koneksi dari network source Prometheus yang
  diizinkan.
- Telegraf hanya memeriksa HTTP health endpoint melalui container network lokal
  yang diizinkan.
- Certificate, private key, dan trust material dipasang sebagai read-only
  secret dan tidak disimpan di dalam image atau repository.

## Current Status

Deployment topology belum diverifikasi melalui implementasi end-to-end.
Persistent lab Prometheus telah memverifikasi strict HTTPS scrape terhadap JMX
Exporter dan mempertahankan named data volume selama controlled replacement.
Persistent Telegraf memeriksa lab-only Tomcat JSP health endpoint melalui
container network; Prometheus menerima application-health metrics melalui
internal target `telegraf:9273`. Application dan metrics ports tidak
dipublikasikan pada host, sedangkan dashboard Prometheus lab tersedia melalui
host port `9090`.

Tiga application-health alert rules telah diimplementasikan, dimuat pada
persistent Prometheus, dan lulus `promtool`, synthetic rule-unit test, serta
isolated firing/resolved verification. Application failed, missing metric, dan
Telegraf scrape unavailable terbukti menjadi state yang terpisah. Production
application semantics, persistent Alertmanager, receiver behavior, TrueSight
integration, serta end-to-end notification flow belum diverifikasi.

Alertmanager runtime akan dimiliki repository generik terpisah, sedangkan
configuration, routing, validation, Prometheus delivery, dan orchestration
tetap dimiliki `tomcat-monitoring`. Lab contract menggunakan internal
`alertmanager:9093`, stable alert labels, grouping baseline, dan webhook
`send_resolved: true` menuju Integration Bridge dengan endpoint dari runtime
secret file. Generic runtime source telah dibentuk dengan upstream pin
`v0.34.0`; local image build, Alertmanager dan `amtool` version, serta official
non-root contract telah diverifikasi. Non-secret routing configuration dan
Prometheus API v2 reference telah diimplementasikan dan lulus `amtool` serta
`promtool`. Receiver behavior, persistent runtime, dan external flow belum
diimplementasikan atau diverifikasi.

# Architecture

## Overview

Arsitektur Tomcat Monitoring menempatkan JMX Exporter sebagai Java Agent di
dalam JVM Tomcat. Prometheus berjalan sebagai container terpisah di dalam
monitoring stack project dan mengambil metrics melalui endpoint HTTPS. Telegraf
memeriksa HTTP health endpoint aplikasi melalui container network yang sama
dengan Tomcat. Mailpit lokal menjadi persistent lab-only email capture target
tanpa external delivery. TrueSight berada di luar deployment boundary project
sebagai future event-management integration dan tidak tersedia pada lab saat
ini.

Diagnostic MVP menambahkan target arsitektur untuk diagnosis deterministik
`TomcatDown`. Diagnostic Service source dan local image tersedia serta lulus
disposable verification; integration-owned runtime contract juga diterima.
Restricted event collector, routing, persistent SQLite, rebuilt application
image, dan alur diagnostic belum diimplementasikan atau diverifikasi end to
end. SMTP orchestration telah lulus source/socket tests.

## Deployment Topology

### A. Topology Utama

```mermaid
flowchart TB
    DB["Platform Monitoring<br/>Dashboard dan Alert"]
    PM["Platform Monitoring<br/>Container Prometheus"]
    TG["Platform Monitoring<br/>Container Telegraf"]
    AM["Platform Monitoring<br/>Alertmanager"]

    TC["Container Tomcat<br/>Apache Tomcat JVM"]
    JM["Container Tomcat<br/>JMX Exporter Java Agent"]
    APP["Container Tomcat<br/>Endpoint HTTP Health Aplikasi"]

    NC["Utility Verifikasi<br/>Mailpit SMTP Capture"]
    DS["Platform Monitoring<br/>Diagnostic Service"]
    BR["Integrasi Eksternal<br/>Integration Bridge"]
    TS["Integrasi Eksternal<br/>TrueSight"]

    DB -->|"1. Query metrics current dan historical"| PM

    PM -->|"2. HTTPS GET /metrics<br/>Server-side TLS"| JM
    TC -->|"Mengekspos metrics JVM dan Tomcat"| JM

    PM -->|"3. Scrape metrics health"| TG
    TG -->|"4. HTTP GET /health internal"| APP
    TC -->|"Menyediakan health aplikasi"| APP

    PM -->|"5. Mengirim alert firing dan resolved"| AM
    AM -->|"6a. Mengirim alert monitoring"| NC
    AM -.->|"6b. TomcatDown firing/resolved<br/>HTTPS internal — direncanakan"| DS
    DS -.->|"7a. Email hasil diagnostic"| NC
    DS -.->|"7b. Proyeksi dinonaktifkan"| BR
    BR -.->|"8. Transport dinonaktifkan"| TS
```

Nomor pada diagram menunjukkan hubungan komunikasi, bukan urutan startup
container. Garis penuh menunjukkan alur persistent lab yang sudah diverifikasi;
garis putus-putus menunjukkan target Diagnostic MVP dan external integration
yang belum diimplementasikan. Topology utama hanya menambahkan Diagnostic
Service setelah Alertmanager; component internal dan evidence flow dijelaskan
pada topology detail berikutnya.

### B. Detail Alur Diagnostic

```mermaid
flowchart LR
    PM["Platform Monitoring<br/>Prometheus"]
    AM["Platform Monitoring<br/>Alertmanager"]

    DS["Platform Monitoring<br/>Diagnostic Service"]
    SQ[("Host Tomcat<br/>SQLite diagnostic_data")]
    LOG["Host Tomcat<br/>Log dan crash artifact"]
    HE["Host Tomcat<br/>Event host dan container"]
    HC["Host Tomcat<br/>Restricted Event Collector"]
    SP["Host Tomcat<br/>Spool event ternormalisasi"]

    NC["Utility Verifikasi<br/>Mailpit SMTP Capture"]
    BR["Integrasi Eksternal<br/>Integration Bridge — disabled"]
    TS["Integrasi Eksternal<br/>TrueSight — disabled"]

    PM -->|"1. TomcatDown<br/>firing/resolved"| AM
    AM -->|"2. HTTPS webhook<br/>internal"| DS
    DS -->|"3. Event dan<br/>state"| SQ
    DS -->|"4. Query<br/>metrics"| PM
    LOG -->|"5a. Read-only"| DS
    HE -->|"5b. Input<br/>allowlist"| HC
    HC -->|"5c. Record<br/>ternormalisasi"| SP
    SP -->|"5d. Spool<br/>read-only"| DS
    DS -->|"6. Email hasil<br/>canonical"| NC
    DS -.->|"Dinonaktifkan"| BR
    BR -.->|"Dinonaktifkan"| TS
```

Seluruh alur pada topology detail telah diterima sebagai desain. Service
component dan temporary SQLite behavior telah diverifikasi secara disposable,
tetapi hubungan lintas component belum dijalankan. Satu Diagnostic Service dan
satu local state volume direncanakan per host Tomcat. Hanya `TomcatDown` yang
masuk ke diagnostic routing; application-health dan high-heap diagnostic rules
tetap disabled.

## Monitoring Flow

```mermaid
sequenceDiagram
    autonumber
    participant APP as Aplikasi Tomcat
    participant TG as Telegraf
    participant JM as JMX Exporter
    participant PM as Prometheus
    participant DB as Dashboard dan Alert
    participant AM as Alertmanager
    participant DS as Diagnostic Service
    participant SQ as SQLite
    participant EV as Evidence hanya-baca
    participant NC as Mailpit

    loop Interval health aplikasi lokal
        TG->>APP: HTTP GET /health
        APP-->>TG: Status code, response body, dan response time
    end

    loop Interval scrape Prometheus
        PM->>JM: HTTPS GET /metrics
        JM-->>PM: Metrics JVM dan Tomcat
        PM->>TG: Scrape metrics health HTTP
        TG-->>PM: Hasil health dan response time
    end

    DB->>PM: Query metrics current dan historical
    PM-->>DB: Data time-series

    PM->>AM: Mengirim state firing atau resolved
    alt Alert monitoring existing — saat ini dan terverifikasi
        AM->>NC: Mengirim email untuk capture lokal
    else TomcatDown — target direncanakan
        AM->>DS: Webhook firing/resolved melalui HTTPS internal
        DS->>SQ: Menyimpan event tervalidasi
        SQ-->>DS: Commit durable
        DS-->>AM: HTTP 202 setelah commit
        par Pengumpulan evidence terbatas
            DS->>PM: Query metrics
        and Evidence host-local
            DS->>EV: Membaca log, artifact, dan spool
        end
        DS->>SQ: Menyimpan canonical result dan delivery state
        DS->>NC: Mengirim email diagnostic atau resolved
    end
```

Sequence diagram menegaskan bahwa Prometheus dan Telegraf menggunakan model
pull. Telegraf memulai HTTP health check terhadap aplikasi, sedangkan Prometheus
melakukan scrape terhadap JMX Exporter dan Telegraf. Cabang Diagnostic MVP
menunjukkan target yang belum diimplementasikan; webhook tidak mengembalikan
`202` sebelum event tersimpan secara durable di SQLite.

## Architecture Components

| Component | Responsibility |
| --- | --- |
| Tomcat Container | Menjalankan application runtime dan JVM yang dimonitor |
| JMX Exporter | Membaca MBean secara lokal dan menyajikan Prometheus metrics |
| Prometheus | Melakukan scrape, menyimpan time-series, dan mengevaluasi alert rules |
| Telegraf | Memeriksa HTTP status, response time, timeout, dan response body aplikasi |
| Dashboard and Alert | Melakukan query ke Prometheus serta menampilkan metrics dan status alert |
| Alertmanager | Mengelompokkan, melakukan deduplication, dan meneruskan alert |
| Mailpit | Menangkap email firing dan resolved pada persistent lab-only topology tanpa external delivery |
| Diagnostic Service | Menerima `TomcatDown`, menyimpan event, mengumpulkan evidence terbatas, menghasilkan canonical result, dan membentuk lifecycle notification; source, secure interfaces, configuration, `0.1.1` image, SQLite reopen, dan Mailpit aktual telah diuji secara disposable; persistent runtime belum tersedia |
| SQLite | Menyimpan event, incident, deduplication, canonical result, dan delivery state lokal; source migration/adapter serta ephemeral lifecycle verification tersedia, persistent restart belum diverifikasi |
| Restricted Event Collector | Menulis event host dan container yang telah dinormalisasi ke spool terbatas tanpa memberi Diagnostic Service akses kontrol host; belum diimplementasikan |
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
- Target webhook Diagnostic Service menggunakan strict TLS, bearer
  authentication, dedicated internal network, dan tidak memublikasikan host
  port.
- Identity target berasal dari local allowlist; payload webhook tidak boleh
  memilih path, command, container, atau evidence source.
- Diagnostic Service tidak memiliki akses ke broad Podman socket, host
  namespace, arbitrary command, runtime control, atau arbitrary path.
- Tomcat evidence mounts dan normalized collector spool hanya dapat dibaca oleh
  Diagnostic Service. Secret serta TLS material tetap berada di non-Git storage
  dan dipasang read-only.

## Related Architecture Decisions

| ADR | Decision Summary |
| --- | --- |
| [TM-ADR-0001](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0001.md) | Menggunakan embedded JMX instrumentation dan containerized monitoring stack. |
| [TM-ADR-0002](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0002.md) | Memisahkan image runtime generik dari konfigurasi integrasi project. |
| [TM-ADR-0003](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0003.md) | Menyimpan material TLS persistent lab di luar Git dan image. |
| [TM-ADR-0004](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0004.md) | Memisahkan application failure dari kehilangan signal monitoring. |
| [TM-ADR-0005](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0005.md) | Menggunakan Mailpit sebagai target verifikasi notifikasi persistent lab. |
| [TM-ADR-0006](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0006.md) | Menggunakan deterministic multi-source evidence. |
| [TM-ADR-0007](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0007.md) | Memperlakukan `TomcatDown` sebagai composite trigger. |
| [TM-ADR-0008](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0008.md) | Membatasi host evidence melalui normalized collector spool. |
| [TM-ADR-0009](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0009.md) | Menggunakan SQLite untuk local diagnostic state. |
| [TM-ADR-0010](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0010.md) | Menempatkan satu bounded service per Tomcat host. |
| [TM-ADR-0011](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0011.md) | Menetapkan confidence melalui per-rule decision table. |
| [TM-ADR-0012](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0012.md) | Menjaga Integration Bridge dan TrueSight disabled serta terpisah. |

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
application semantics, actual Integration Bridge, TrueSight integration, serta
external end-to-end notification flow belum diverifikasi.

Alertmanager runtime dimiliki repository generik terpisah, sedangkan
configuration, routing, validation, Prometheus delivery, dan orchestration
tetap dimiliki `tomcat-monitoring`. Lab contract menggunakan internal
`alertmanager:9093`, stable alert labels, grouping baseline, dan active
`send_resolved: true` email receiver menuju Mailpit lokal. Generic runtime
source telah dibentuk dengan upstream pin
`v0.34.0`; local image build, Alertmanager dan `amtool` version, serta official
non-root contract telah diverifikasi. Non-secret routing configuration dan
Prometheus API v2 reference telah diimplementasikan dan lulus `amtool` serta
`promtool`. Historical webhook receiver menangkap payload firing dan resolved
dengan lima stable group labels. Active Mailpit receiver kemudian menangkap
email firing dan resolved dengan sender serta recipient synthetic pada
2026-08-27. Pada 2026-08-28, persistent Prometheus mengirim real
`TelegrafHealthScrapeUnavailable` firing/resolved state ke persistent
Alertmanager dan Mailpit menangkap kedua matching email. Prometheus serta
Alertmanager kembali ready setelah controlled replacement dan restart;
Telegraf, JMX scrape, rules, dan health metric juga pulih ke baseline. Actual
Integration Bridge dan external flow belum diimplementasikan atau
diverifikasi.

Desain Diagnostic MVP telah diterima. `TomcatDown` engine, durable SQLite
ingestion, bounded worker, secure service boundary, versioned configuration,
dan digest-pinned Diagnostic Service image telah diimplementasikan dan lulus
source atau disposable verification. TN-011 juga menetapkan integration-owned
runtime paths, permissions, ownership, dan multi-component verification
contract. SMTP worker orchestration kemudian lulus source/socket tests pada
TN-012. Alertmanager routing, rebuilt image, persistent SQLite, restricted
collector, environment target allowlist, evidence integration, dan end-to-end
diagnostic flow belum diimplementasikan atau diverifikasi. Alur
Alertmanager langsung ke Mailpit tetap menjadi current verified runtime sampai
target Diagnostic MVP benar-benar diterapkan dan diuji.

## Alert Notification Presentation Contract

Internal Prometheus alert identity tetap stabil selama firing/resolved
lifecycle untuk menjaga grouping, deduplication, dan correlation. Email
operator menerjemahkan lifecycle tersebut menjadi `normal`, `warning`, atau
`critical` tanpa mengubah source labels.

| Internal State | Operator Severity | Visual |
| --- | --- | --- |
| Resolved | `normal` | Green |
| Firing dengan rule severity warning | `warning` | Orange |
| Firing dengan rule severity critical | `critical` | Red |

Subject wajib mengikuti format Enterprise SRE `[<RESOLVED|CRITICAL|WARNING>]
[LAB] Tomcat Service: <presentation-alert-name> (Instance: <instance>)`.
Sebagai contoh, internal `TelegrafHealthScrapeUnavailable` ditampilkan dengan
nama yang sama saat critical, tetapi menjadi `TelegrafHealthScrapeAvailable` saat
normal / recovery.

Body mengadopsi format Modern SRE & Incident Operations yang terstruktur dalam
beberapa bagian:

1. **Header Banner**: Menampilkan level status, judul layanan, dan badge
   `LAB Environment`.
2. **Alert / Recovery Summary**: Kotak ringkasan insiden atau pemulihan dengan
   aksen warna status.
3. **Technical Details**: Grid key-value rapi untuk `Alert Name`, `Service / Check`,
   `Target Instance`, `Severity`, dan `Status` (`FIRING / ACTIVE` atau
   `RESOLVED / HEALTHY`).
4. **Impact & Recommended Actions**: Informasi dampak operasional dan langkah
   penanganan/diagnosis cepat bagi operator on-call.
5. **Footer Metadata**: Keterangan notifikasi otomatis platform tanpa link
   internal yang tidak dapat diakses.

Source contract menetapkan Telegraf scrape unavailable sebagai critical karena
monitoring target mati dan application-health state tidak dapat ditentukan.
Seluruh application-health rules menyediakan stable `service` dan `check` labels
agar email tidak memiliki field kosong. Disposable template rendering dan
Prometheus config/rule tests telah lulus. Contract dipromosikan ke persistent
runtime dan real scrape-down/recovery cycle menghasilkan matching
critical/resolved email enterprise baru. Project owner menerima exact
Enterprise SRE visual evidence pada 2026-08-28 setelah critical dan resolved
rendering diperiksa melalui Mailpit.

Project owner sempat menetapkan direct Gmail email sebagai next lab
notification path, kemudian menggantinya dengan Mailpit lokal pada 2026-08-27
agar email capture tidak memerlukan Google credential atau external delivery.
Mailpit menjadi persistent lab-only verification utility dan tidak menggantikan
future notification-channel architecture. Direct-upstream exception,
immutable `v1.31.0` pin, no-volume storage boundary, loopback-only API, dan
exact persistent resources telah diterima. SMTP tetap internal pada
`mailpit:1025`; message history bukan source of truth dan host-reboot recovery
belum diklaim.

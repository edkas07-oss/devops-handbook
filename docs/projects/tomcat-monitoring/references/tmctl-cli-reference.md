# Tomcat Monitoring Operator CLI (tmctl) Reference

## 🔍 Overview

Dokumen ini merupakan spesifikasi referensi resmi (*Authoritative CLI Reference*) untuk kakas baris perintah terpadu **`tmctl`** (*Unified Cross-Platform Operator CLI*).

`tmctl` bertindak sebagai antarmuka tunggal (*Single Source of Operations*) untuk orkestrasi armada kontainer, manajemen aturan diagnostik AI, autentikasi registri kontainer enterprise, dan audit validasi kepatuhan platform Tomcat Monitoring. Kakas ini berinteraksi langsung dengan **Container Engine Socket REST API** (Podman / Docker) tanpa memerlukan interpreter Bash atau dependensi runtime eksternal pada workstation operator (Linux & Windows native).

---

## 🏛️ Karakteristik & Batasan Arsitektur

1. **Single Static Binary (`CGO_ENABLED=0`):**
   Dikompilasi sebagai biner statis murni mandiri untuk Linux (`tmctl`, `x86_64` dan `aarch64`) dan Windows (`tmctl.exe`, `x86_64`).
2. **OS-Agnostic Socket Transport:**
   Mendukung auto-discovery dan koneksi langsung ke:
   - Unix Domain Socket di Linux/macOS: `/run/user/<uid>/podman/podman.sock` atau `/var/run/docker.sock`.
   - Windows Named Pipe di Windows: `\\.\pipe\docker_engine`.
   - TCP mTLS Socket untuk peladen jarak jauh: `tcp://<host>:2375` atau `tcp://<host>:2376`.
3. **Zero-Downtime Rollback Mechanism:**
   Saat melakukan pembaruan beban kerja kontainer (`tmctl stack deploy`), `tmctl` membuat snapshot kontainer aktif (`<name>-rollback-snapshot`), menyalakan kontainer baru, dan menjalankan *multi-endpoint readiness probe*. Jika probe gagal, snapshot lama dipulihkan secara otomatis tanpa *downtime*.
4. **Isolasi Kredensial Registri:**
   Operasi login/logout registri kontainer dikelola pada berkas otentikasi terisolasi (`--auth-file`) tanpa memodifikasi kredensial global pengguna host.

---

## 📋 Matriks Subperintah `tmctl`

| Perintah Utama | Subperintah | Deskripsi Fungsional | Parameter Utama |
| :--- | :--- | :--- | :--- |
| **`stack`** | `deploy` | Membuat dan menyalakan beban kerja kontainer dengan rekonsiliasi bridge network, persistent volume, dan auto-rollback. | `--target`, `--env`, `--engine`, `--config` |
| | `status` | Menampilkan tabel status seluruh kontainer armada monitoring, port bindings, dan status kesehatan (*health status*). | `--config` |
| | `clean` | Menghentikan dan menghapus kontainer platform. Opsi `--all` menghapus volume persisten dan bridge network. | `--all`, `--config` |
| **`rules`** | `ingest` | Mendaftarkan berkas aturan diagnosis AI (format objek tunggal atau batch array) ke Diagnostic Service dengan otentikasi Bearer Token. | `<file.json>`, `--token`, `--url` |
| | `export` | Mengambil dan mengekspor katalog aturan aktif dari Diagnostic Service. Mendukung filter kategori. | `--category`, `--output`, `--categories`, `--token` |
| **`registry`** | `login` | Melakukan autentikasi ke registri kontainer enterprise (Harbor/Nexus/Quay) pada berkas kredensial terisolasi. | `<host:port>`, `<user>`, `--token-file`, `--auth-file` |
| | `logout` | Menghapus kredensial registri dari berkas otentikasi terisolasi. | `[host:port]`, `--auth-file` |
| **`validate`** | - | Mengaudit kepatuhan tata kelola repositori, integritas skema JSON, dan mendeteksi kebocoran materi rahasia. | `--layout`, `--schemas`, `--ansible`, `--dir` |
| **`version`** | - | Menampilkan versi rilis semantik, commit SHA, tanggal build UTC, dan arsitektur OS/Arch. | `-v`, `--version` |

---

## ⚙️ Variabel Konfigurasi & Lingkungan (`CONFIG`)

`tmctl` memuat konfigurasi melalui urutan prioritas: **Nilai Bawaan (*Defaults*) $\rightarrow$ Berkas `CONFIG` $\rightarrow$ *Environment Variables* $\rightarrow$ Opsi CLI (*Flags*)**.

| Variabel Konfigurasi | Environment Variable | Nilai Bawaan | Deskripsi |
| :--- | :--- | :--- | :--- |
| `PLATFORM_NAME` | `PLATFORM_NAME` | `tomcat-monitoring` | Nama platform monitoring |
| `NETWORK_NAME` | `NETWORK_NAME` | `devops-lab` | Nama bridge network OCI |
| `CONTAINER_ENGINE` | `CONTAINER_ENGINE` | *(Auto-detect)* | Override engine (`podman` atau `docker`) |
| `SOCKET_PATH` | `SOCKET_PATH` | *(Auto-detect)* | Jalur soket REST API atau Named Pipe |
| `DIAGNOSTIC_URL` | `DIAGNOSTIC_URL` | `https://localhost:8443` | Endpoint HTTPS Diagnostic Service |
| `BEARER_TOKEN` | `BEARER_TOKEN` | `test-token-12345` | Token otentikasi API Diagnostic Service |
| `REGISTRY_URL` | `REGISTRY_URL` | `localhost` | Host registri kontainer enterprise |
| `REGISTRY_NAMESPACE` | `REGISTRY_NAMESPACE` | `""` | Namespace / Project path registri |
| `REGISTRY_TLS_VERIFY` | `REGISTRY_TLS_VERIFY` | `true` | Verifikasi TLS registri |
| `IMAGE_PULL_POLICY` | `IMAGE_PULL_POLICY` | `IfNotPresent` | Kebijakan penarikan citra (`Always`, `IfNotPresent`, `Never`) |
| `REGISTRY_AUTH_FILE` | `REGISTRY_AUTH_FILE` | `""` | Jalur berkas autentikasi OCI terisolasi |

---

## 🔌 Spesifikasi Detail Subperintah & Contoh Penggunaan

### 1. Manajemen Siklus Hidup Stack (`tmctl stack`)

#### `tmctl stack deploy`
Melakukan rekonsiliasi state armada kontainer secara idempoten:
```bash
# Men-deploy seluruh tumpukan kontainer monitoring
tmctl stack deploy --target all

# Men-deploy kontainer Tomcat JMX Exporter pada lingkungan lab menggunakan engine Podman
tmctl stack deploy --target tomcat --env lab --engine podman

# Men-deploy Diagnostic Service menggunakan konfigurasi kustom
tmctl stack deploy --target diagnostic --config /etc/tomcat-monitoring/CONFIG
```

#### `tmctl stack status`
Menampilkan tabel status seluruh kontainer armada monitoring:
```bash
$ tmctl stack status
ℹ INFO: Inspecting platform containers on podman (/run/user/1000/podman/podman.sock)...

SERVICE NAME                   CONTAINER NAME       IMAGE                                                                                            STATUS                    PORTS
--------------                 ----------------     -------                                                                                          --------                  -------
Tomcat JMX Exporter            tomcat-jmx-exporter  localhost/tomcat-jmx-exporter:1.0.0                                                              Up 2 hours                8083->8080/tcp, 9404->9404/tcp
Prometheus TSDB                prometheus           localhost/prometheus:1.0.0                                                                       Up 2 hours                9090->9090/tcp
Alertmanager                   alertmanager         localhost/alertmanager:1.0.0                                                                     Up 2 hours                9093->9093/tcp
Tomcat Diagnostic Service      diagnostic-service   localhost/tomcat-diagnostic-service:latest                                                       Up 2 hours                8443->8443/tcp
Mailpit Test Inbox             mailpit              ghcr.io/axllent/mailpit@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24  Up 2 hours                1025->1025/tcp, 8025->8025/tcp
Postfix Enterprise SMTP Relay  postfix-relay        localhost/postfix-relay:latest                                                                   Up 2 hours                -
```

#### `tmctl stack clean`
Menghentikan dan membersihkan armada kontainer:
```bash
# Menghentikan dan menghapus seluruh kontainer monitoring
tmctl stack clean

# Membersihkan kontainer, volume persisten, dan bridge network
tmctl stack clean --all
```

---

### 2. Manajemen Aturan Diagnostik AI (`tmctl rules`)

#### `tmctl rules ingest`
Mendaftarkan berkas rulepack JSON ke database SQLite Diagnostic Service secara instan (*hot-reload*):
```bash
# Mendaftarkan rulepack custom
tmctl rules ingest config/rules/custom-rules.json

# Mendaftarkan dengan token dan endpoint eksplisit
tmctl rules ingest rules/jvm-degradation.json --token $(cat /path/to/token) --url https://10.0.1.15:8443
```

#### `tmctl rules export`
Mengekspor katalog aturan aktif dari Diagnostic Service:
```bash
# Menampilkan ringkasan seluruh kategori aturan aktif
tmctl rules export --categories

# Mengekspor seluruh aturan kategori runtime availability ke berkas JSON
tmctl rules export --category runtime_availability --output exported-rules.json
```

---

### 3. Autentikasi Registri Kontainer Enterprise (`tmctl registry`)

```bash
# Login ke Harbor registry dengan file token terisolasi
tmctl registry login harbor.corp.internal:5000 admin --token-file /run/secrets/registry-token --auth-file ~/.local/share/auth.json

# Logout dari registri
tmctl registry logout harbor.corp.internal:5000 --auth-file ~/.local/share/auth.json
```

---

### 4. Validasi & Audit Kepatuhan (`tmctl validate`)

```bash
# Menjalankan validasi kepatuhan pada repositori saat ini
tmctl validate

# Menjalankan audit spesifik pada direktori target
tmctl validate --dir /home/eddywiyatno/git/tomcat-monitoring
```

---

## 🔗 Referensi Terkait

* [Tomcat Monitoring Architecture](../architecture/index.md)
* [Tomcat Diagnostic Event Collector Daemon Reference](tm-agent-daemon-reference.md)
* [Tomcat Diagnostic Service REST API Reference](diagnostic-service-rest-api-reference.md)
* [TM-ADR-0027 — Adopt Container Engine Socket API and Unified Cross-Platform Tooling](../../../adr/tomcat-monitoring/adr-records/TM-ADR-0027.md)
* [TN-012 — Implement Unified Cross-Platform Operator CLI tmctl](../engineering-journal/continuous-integration-and-deployment/TN-012-implement-unified-cross-platform-operator-cli-tmctl.md)

# TN-010 — Establish Prometheus Runtime Repository

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Implementation |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-22 |
| Recorded Date | 2026-08-22 |
| Owner | Project owner |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-22 |

## 🎯 Objective

Membentuk repository `prometheus` sebagai OCI runtime generik terpisah sebelum configuration scrape dan integrasi Prometheus dimulai pada `tomcat-monitoring`.

## ⚖️ Runtime Component Ownership Gate

| Question | Decision |
| --- | --- |
| Reusable image lifecycle? | Ya: upstream pinning, build, smoke test, entrypoint, run, dan cleanup. |
| Existing generic runtime? | Tidak ada; repository `/home/eddywiyatno/git/prometheus` baru tersedia dan kosong. |
| Generic runtime owner | Repository `prometheus`. |
| Project configuration owner | Repository `tomcat-monitoring`. |
| Upstream pin | `docker.io/prom/prometheus:v3.13.2`, LTS terbaru pada halaman download resmi saat assessment. |

## 📚 Scope

Repository `prometheus` hanya akan berisi metadata image, Containerfile, entrypoint generik, README, dan script local lifecycle. `prometheus.yml`, scrape target JMX Exporter/Telegraf, alert rules, credentials, TLS material, data volume, port host, target deployment, dan publication berada di luar scope TN ini.

## ⚙️ Execution Plan

1. Catat discovery repository dan sumber upstream resmi.
2. Tambahkan governance repository dan metadata upstream pin.
3. Tambahkan Containerfile, entrypoint, serta build/test/run/clean interface generik tanpa configuration project.
4. Jalankan static syntax dan integrity checks saja.
5. Catat hasil aktual dan handoff untuk build/smoke test terpisah.

## 📝 Commands Executed

### 1. Inspect repository availability and runtime pattern

**Purpose.** Memastikan repository target tersedia serta membandingkan contract generik Telegraf tanpa menyalin configuration integration.

**Command actually executed.**

```bash
test -d /home/eddywiyatno/git/prometheus && printf 'directory=present\n' || printf 'directory=absent\n'
git -C /home/eddywiyatno/git/prometheus status --short --branch
rg --files /home/eddywiyatno/git/prometheus -g 'AGENTS.md' -g 'README.md' -g 'Containerfile' -g 'CONFIG' -g 'PROJECT' -g 'VERSION' -g 'entrypoint.sh' -g 'scripts/*' | sort
sed -n '1,240p' /home/eddywiyatno/git/telegraf/README.md
sed -n '1,220p' /home/eddywiyatno/git/telegraf/Containerfile
sed -n '1,240p' /home/eddywiyatno/git/telegraf/scripts/run.sh
sed -n '1,220p' /home/eddywiyatno/git/telegraf/scripts/test.sh
```

**Expected result.** Repository Prometheus tersedia, tidak ada source awal, dan pattern runtime generik dapat direview.

**Actual result and evidence.** Directory tersedia. Git menyatakan `No commits yet on main...origin/main [gone]`; pencarian tidak menemukan source atau `AGENTS.md` pada repository baru. Telegraf direview hanya sebagai pattern lifecycle, bukan sebagai source yang disalin.

### 2. Verify official upstream selection

**Purpose.** Memilih versi upstream yang stabil dan dipin sebelum source image dibuat.

**Method actually used.** Halaman Download dan Installation Prometheus resmi direview pada 2026-08-22.

**Expected result.** Versi upstream dan contract mount configuration/data dapat dibuktikan tanpa menjalankan image.

**Actual result and evidence.** Halaman Download resmi mencantumkan `3.13.2` sebagai Latest LTS dan `3.14.0` sebagai Latest. Halaman Installation resmi menyatakan image tersedia melalui registry, configuration dapat di-bind-mount ke `/etc/prometheus/prometheus.yml`, dan data berada di `/prometheus`. TN ini memilih LTS `v3.13.2` dan tidak membuat mount atau volume apapun.

### 3. Implement generic runtime source

**Purpose.** Menyediakan lifecycle image reusable tanpa memasukkan configuration atau deployment contract milik solution monitoring.

**Implementation actually performed.** Source berikut ditambahkan pada repository `/home/eddywiyatno/git/prometheus`: `AGENTS.md`, `PROJECT`, `VERSION`, `CONFIG`, `.containerignore`, `Containerfile`, `entrypoint.sh`, `README.md`, serta `scripts/build.sh`, `scripts/test.sh`, `scripts/run.sh`, dan `scripts/clean.sh`.

**Expected result.** Runtime pin, image identity, entrypoint, dan lifecycle interface tersedia; scrape configuration, alert rule, credential, TLS, port host, dan data runtime project tidak ikut masuk source.

**Actual result and evidence.** `CONFIG` mem-pin `docker.io/prom/prometheus:v3.13.2`. Entrypoint hanya meneruskan argumen ke `/bin/prometheus`. `run.sh` mewajibkan caller memberikan path `prometheus.yml` dan direktori data yang sudah ada; ia tidak memiliki target scrape, retention, port publish, atau volume default. `clean.sh` hanya menargetkan nama container dan tidak menghapus direktori data atau volume.

### 4. Apply executable mode and run static validation

**Purpose.** Memastikan entrypoint dan lifecycle scripts dapat dijalankan dan memiliki sintaks shell yang valid sebelum image build diotorisasi.

**Command actually executed.**

```bash
chmod 0755 /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/build.sh /home/eddywiyatno/git/prometheus/scripts/test.sh /home/eddywiyatno/git/prometheus/scripts/run.sh /home/eddywiyatno/git/prometheus/scripts/clean.sh
bash -n /home/eddywiyatno/git/prometheus/entrypoint.sh /home/eddywiyatno/git/prometheus/scripts/*.sh
git -C /home/eddywiyatno/git/prometheus diff --check
git -C /home/eddywiyatno/git/prometheus status --short
```

**Expected result.** Files executable; tidak ada syntax atau whitespace error; status hanya menampilkan source runtime baru yang belum di-commit.

**Actual result and evidence.** `chmod`, `bash -n`, dan `git diff --check` lulus tanpa output error. Status menampilkan tepat `.containerignore`, `AGENTS.md`, `CONFIG`, `Containerfile`, `PROJECT`, `README.md`, `VERSION`, `entrypoint.sh`, dan `scripts/` sebagai untracked source baru.

## ✅ Outcome

Repository Prometheus generik telah tersedia dan lolos static validation. Ia belum dibangun, dipull, diuji sebagai image, dijalankan, diintegrasikan ke `tomcat-monitoring`, di-commit, atau dipush. Karena itu tidak ada klaim bahwa binary Prometheus, permission data runtime, scrape, storage, atau monitoring end-to-end sudah terverifikasi.

## ⏭️ Next Steps

Langkah paling dekat adalah local build dan smoke test image Prometheus pada scope terpisah. Setelah runtime image lulus, configuration `prometheus.yml` dan scrape target JMX Exporter/Telegraf dapat dimulai sebagai Technical Note integration berikutnya. Commit dan push tetap memerlukan authorization terpisah.

## 🔗 Related Documentation

- [Prometheus Download](https://prometheus.io/download/)
- [Prometheus Installation](https://prometheus.io/docs/prometheus/latest/installation/)
- [TN-006 — Establish Telegraf Runtime Repository](TN-006-establish-telegraf-runtime-repository.md)

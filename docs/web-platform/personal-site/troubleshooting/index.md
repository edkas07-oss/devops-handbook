# Troubleshooting

## Overview

Panduan ini merangkum masalah yang ditemukan selama implementasi CI/CD dan
langkah diagnosis yang relevan untuk kondisi sistem saat ini. Detail historis
tetap tersedia pada Engineering Journal.

## Jenkins Job Waits for Agent

**Symptom**

```text
Still waiting to schedule task
‘builder-01’ is offline
```

**Checks**

- Pastikan node benar-benar connected pada Jenkins.
- Pastikan label job sama dengan label node `builder-01`.
- Periksa agent service, SSH connectivity, Java process, dan executor count.
- Build yang sudah masuk antrean saat agent offline dapat dibatalkan dan
  dijalankan ulang setelah agent terhubung.

## ARTIFACT_NAME Is Empty or Invalid

**Symptom**

```text
ARTIFACT_NAME: parameter not set
```

Jalankan job melalui **Build with Parameters** dan isi field bernama
`ARTIFACT_NAME`, bukan mengganti nama parameter dengan nama artifact.

Contoh nilai:

```text
personal-site-59.tar.gz
```

## MinIO Client Receives an Empty Alias

**Symptom**

```text
mc: <ERROR> Invalid alias. Alias `` ...
```

Pastikan variable dari `deployment/CONFIG` diekspor sebelum diteruskan melalui
opsi `podman run --env`. Secret tetap berasal dari Jenkins Credentials.

## Artifact Does Not Contain Hugo Site

**Symptom**

```text
test -s deploy-staging/public/index.html
script returned exit code 1
```

- Pastikan Hugo theme submodule telah diinisialisasi.
- Pastikan CI menggunakan versi Hugo yang kompatibel.
- Pastikan CI memvalidasi `public/index.html` sebelum membuat dan mengunggah
  archive.
- Jalankan kembali CI dan deploy artifact baru; jangan gunakan artifact rusak.

## Existing Podman Volume Causes Failure

**Symptom**

```text
volume with name www-personal-site already exists
```

Gunakan pemeriksaan idempotent:

```bash
if ! podman volume exists www-personal-site; then
    podman volume create www-personal-site >/dev/null
fi
```

## Health Status Is Empty

**Symptom**

HTTP berhasil tetapi `.State.Health.Status` kosong.

Periksa healthcheck configuration:

```bash
podman inspect personal-site-web \
  --format '{{if .Config.Healthcheck}}configured{{else}}none{{end}}'
```

Container harus dibuat dengan health command HTTP. Tanpa healthcheck metadata,
Podman tidak akan menghasilkan status `healthy` atau `unhealthy`.

## Deployment Succeeds but Website Is Unreachable

Periksa status container dan port terlebih dahulu:

```bash
podman ps --all --filter name=personal-site-web
podman port personal-site-web
curl --fail --show-error http://127.0.0.1:8091/
```

Jika container berstatus `Exited (0)` sesaat setelah Jenkins selesai,
pastikan deployment menjalankan Podman dengan cookie yang tidak dibersihkan
oleh Jenkins ProcessTreeKiller:

```bash
JENKINS_NODE_COOKIE=dontKillMe podman run --detach ...
```

Jika HTTP lokal berhasil tetapi browser dari perangkat lain gagal, periksa IP
runtime host, bind address `0.0.0.0:8091`, route jaringan, dan firewall.

## Escalation Path

1. Catat Jenkins build number dan `ARTIFACT_NAME`.
2. Simpan error stage terkait.
3. Periksa `podman ps --all`, `podman inspect`, dan `podman logs`.
4. Pastikan artifact yang sama masih tersedia di MinIO.
5. Deploy ulang last-known-good artifact jika recovery diperlukan.

Detail root cause dan perubahan implementasi tersedia pada
[TN-003 — Create Jenkins Continuous Deployment Pipeline](../engineering-journal/continuous-deployment/TN-003-create-jenkins-continuous-deployment-pipeline.md).

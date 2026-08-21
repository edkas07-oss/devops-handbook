# Operations

## Overview

Bagian ini berisi prosedur operasional current-state untuk memeriksa dan
memelihara runtime Personal Site pada host `builder-01`.

Seluruh perintah Podman dijalankan sebagai user yang sama dengan Jenkins agent
dan pemilik rootless Podman storage.

## Runtime Inventory

```text
Container : personal-site-web
Image     : localhost/nginx-image:1.0
Network   : web
Volume    : www-personal-site
HTTP      : 8091 → 80
HTTPS     : 8443 → 443
SSH       : 2224 → 22
```

## Verify Runtime

```bash
podman ps --filter name=personal-site-web
podman inspect personal-site-web --format '{{.State.Status}}'
podman inspect personal-site-web --format '{{.State.Health.Status}}'
podman port personal-site-web
curl --fail --silent --show-error http://127.0.0.1:8091/ >/dev/null
```

Expected result:

- container berstatus `running`;
- health status bernilai `healthy`;
- port `8091` dipetakan ke container port `80`; dan
- HTTP probe selesai dengan exit code `0`.

## Inspect Logs

```bash
podman logs --tail 100 personal-site-web
```

Gunakan log untuk memeriksa validasi konfigurasi NGINX, startup SSH, dan proses
inisialisasi container.

## Start, Stop, and Restart

```bash
podman start personal-site-web
podman stop personal-site-web
podman restart personal-site-web
```

Deployment release baru tetap dilakukan melalui Jenkins CD agar artifact,
backup, metadata, dan validation tercatat secara konsisten.

## Verify Content Volume

```bash
podman volume inspect www-personal-site

podman run --rm \
  --volume www-personal-site:/content:ro \
  --entrypoint /bin/sh \
  localhost/nginx-image:1.0 \
  -ec 'test -s /content/index.html; cat /content/.artifact-name'
```

## Deploy a Release

1. Pastikan CI untuk commit yang dituju berhasil.
2. Catat nama artifact `personal-site-<BUILD_NUMBER>.tar.gz`.
3. Buka Jenkins job `personal-site-cd`.
4. Pilih **Build with Parameters**.
5. Isi `ARTIFACT_NAME` dengan nama artifact lengkap.
6. Jalankan build dan pastikan seluruh validation stage berhasil.
7. Verifikasi website dari browser melalui `http://<runtime-host>:8091/`.

## Recovery

- Jika CD gagal setelah volume diperbarui, periksa hasil rollback pada console
  Jenkins dan log container.
- Jika container berhenti tetapi deployment terakhir valid, jalankan
  `podman start personal-site-web` dan ulangi HTTP probe.
- Jika content tidak valid, deploy ulang artifact CI terakhir yang diketahui
  berhasil melalui job CD.
- Jangan mengedit file langsung di dalam `www-personal-site`; perubahan manual
  tidak dapat ditelusuri ke artifact.

## Planned Improvements

- Menjalankan runtime melalui systemd user service atau Podman Quadlet.
- Menambahkan automatic startup setelah host reboot.
- Menambahkan monitoring, alerting, dan log retention.
- Menguji rollback secara berkala dengan controlled failure.

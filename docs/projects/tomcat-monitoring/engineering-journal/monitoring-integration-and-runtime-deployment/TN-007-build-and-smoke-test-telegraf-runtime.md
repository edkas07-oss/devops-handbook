# TN-007 — Build and Smoke Test Telegraf Runtime

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Verification or Audit |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Monitoring Integration and Runtime Deployment |
| Activity Date | 2026-08-21 |
| Recorded Date | 2026-08-21 |
| Owner | Project owner |
| Working Mode | Mixed |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-21 |

## 🎯 Objective

Membangun image Telegraf dari source repository saat ini dan memverifikasi
binary serta user non-root melalui container sementara.

## 📋 Criteria

| Criterion | Expected result |
| --- | --- |
| Shell syntax | `entrypoint.sh` dan seluruh script valid. |
| Build | Tag `localhost/telegraf:1.0.0` dan `:latest` terbentuk dari source saat ini. |
| Binary | Container sementara menampilkan versi Telegraf yang dipin. |
| User | Container sementara menjalankan `id -u` selain `0`. |
| Cleanup | Container smoke test memakai `--rm`; tidak ada persistent runtime. |

## ⚙️ Execution Plan

1. Jalankan `bash -n entrypoint.sh scripts/*.sh`.
2. Jalankan `./scripts/build.sh` dengan base image lokal yang telah tersedia.
3. Jalankan `./scripts/test.sh`; script membuat container sementara dengan
   `--rm` untuk verifikasi versi dan user runtime.
4. Catat command, actual result, image identity, dan exception jika ada.

## ⚙️ Execution Record

| Sequence | Purpose | Command actually executed | Expected / actual result |
| --- | --- | --- | --- |
| 1 | Validate shell source | `bash -n entrypoint.sh scripts/*.sh` | Expected valid syntax; actual passed without output. |
| 2 | Build local image | `./scripts/build.sh` | Expected tags `localhost/telegraf:1.0.0` and `:latest`; actual both tags point to image `4f8c425e8fd8fd412b25ba0aa8489c3e668e75560f48fd114d09cb9cf9d67cae`. |
| 3 | Run smoke test | `./scripts/test.sh` | Expected Telegraf version and non-root user; actual output `Telegraf 1.39.3 (git: HEAD@eb37a442)` and command exited `0`, so non-root assertion passed. |
| 4 | Record image and container evidence | `podman image inspect localhost/telegraf:1.0.0 --format 'ID={{.Id}} User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}}'`; `podman ps --all --filter name=telegraf --format '{{.Names}} {{.Status}}'` | Expected image user `telegraf`, custom entrypoint, and no test container; actual inspect reports `User=telegraf`, entrypoint `/usr/local/bin/telegraf-entrypoint`, and container list is empty. |
| 5 | Check source and journal whitespace | `git -C /home/eddywiyatno/git/telegraf diff --check`; `git -C /home/eddywiyatno/git/devops-handbook diff --check -- docs/projects/tomcat-monitoring` | Expected no whitespace error; actual passed without output. |

## 🧾 Outcome

Telegraf runtime source revision saat ini berhasil dibangun sebagai
`localhost/telegraf:1.0.0` dan lulus smoke test binary/non-root. Klaim ini
terbatas pada image lokal dan container sementara; tidak membuktikan runtime
configuration, Telegraf health check, Prometheus scrape, deployment, registry
publication, commit, atau push.

## ⏭️ Next Steps

Source siap untuk review, commit, dan publication hanya bila project owner
memberikan authorization Git terpisah. Component integration menggunakan image
baru memerlukan scope verification baru dan harus lebih dahulu menyelesaikan
blocker network client pada TN-004.

## 🔗 Related Documentation

- [TN-006 — Establish Telegraf Runtime Repository](TN-006-establish-telegraf-runtime-repository.md)
- [TN-004 — Verify Telegraf Health Check Component](TN-004-verify-telegraf-health-check-component.md)

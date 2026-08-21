# TN-001 — Initialize Jenkins Controller & Environment

## Objective

Menjalankan container Jenkins, memverifikasi lingkungan Jenkins, dan menginstal plugin yang diperlukan untuk mendukung Build Pipeline.

## Background

Jenkins dijalankan sebagai container Podman. Sebelum pipeline dibuat, lingkungan Jenkins harus siap dengan startup container, verifikasi service, dan instalasi plugin yang diperlukan.

## Scope

Mencakup startup dan verifikasi Jenkins Controller serta instalasi plugin yang
dibutuhkan pipeline. Konfigurasi agent, SCM, dan pipeline dicatat terpisah.

## Prerequisites

N/A

## Execution Decision

### PS-ADR-0001 — Use Jenkins as Automation Server

Refer to:

- **[PS-ADR-0001 — Use Jenkins as Automation Server](../../../../adr/personal-site/adr-records/PS-ADR-0001.md){ target="_blank" rel="noopener" }**

**Decision**

Personal Site menggunakan Jenkins sebagai automation server utama untuk
mengorkestrasi pipeline CI/CD.

**Reason**

- Mendukung Pipeline as Code melalui Jenkinsfile.
- Terintegrasi dengan Gitea dan containerized build environment.
- Menyediakan orkestrasi build, packaging, dan publikasi artefak secara
  konsisten.

## Implementation

<div class="procedure" markdown>

<div class="procedure-step" markdown>

### Start Jenkins Container

Jalankan kembali container Jenkins jika sudah tersedia.

```bash
podman ps -a
podman start jenkins
podman ps
podman logs --tail 20 jenkins
```

!!! success "Expected Result"

    Container Jenkins berjalan dan log tidak menunjukkan kegagalan startup.

</div>

<div class="procedure-step" markdown>

### Verify Jenkins Environment

1. Akses Jenkins melalui web browser.
2. Login menggunakan akun administrator.
3. Pastikan Dashboard Jenkins dapat ditampilkan tanpa error.
4. Buka menu **Manage Jenkins**.
5. Verifikasi informasi instalasi Jenkins.
6. Pastikan tidak terdapat peringatan atau konfigurasi yang bermasalah.
7. Verifikasi direktori `JENKINS_HOME`.
8. Pastikan Jenkins siap digunakan untuk membuat Pipeline.

!!! success "Expected Result"

    Dashboard Jenkins dapat diakses dan controller siap dikonfigurasi.

</div>

<div class="procedure-step" markdown>

### Install Required Plugins

1. Login ke Jenkins menggunakan akun administrator.
2. Buka menu **Manage Jenkins → Plugins**.
3. Instal plugin berikut:
    - Git
    - Pipeline
    - GitHub Branch Source
    - Credentials
    - SSH Agent
4. Restart Jenkins apabila diminta.
5. Setelah restart, jalankan kembali container jika status berubah menjadi **Exited**:

    ```bash
    podman start jenkins
    ```

6. Login kembali ke Jenkins.
7. Verifikasi seluruh plugin berhasil diinstal dan aktif.

!!! success "Expected Result"

    Seluruh plugin yang dibutuhkan berstatus aktif tanpa dependency error.

</div>

</div>

## Verification

- Container Jenkins berhasil dijalankan.
- Jenkins Web UI dapat diakses.
- Login administrator berhasil.
- Dashboard tampil normal tanpa error.
- `JENKINS_HOME` terinisialisasi.
- Plugin Git, Pipeline, GitHub Branch Source, Credentials, dan SSH Agent berhasil diinstal.
- Jenkins dapat diakses kembali setelah restart.

## Notes

Technical Note ini menggabungkan startup Jenkins, verifikasi environment, dan instalasi plugin dalam satu catatan ringkas.

## Related Documentation

- [Continuous Integration Engineering Journal](index.md)
- [TN-002 — Deploy & Configure SSH Agent Node](TN-002-deploy-configure-ssh-agent-node.md)
- [Personal Site CI/CD](../../ci-cd/index.md)

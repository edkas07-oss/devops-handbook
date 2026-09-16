# TN-022 — Standardize Host Monitoring Directory to `tm_data`, Parameterized Drive Mounting, and Pure Container Logging Model

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Host Storage Architecture, Drive Parametrization & Container Observability |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Continuous Integration and Deployment |
| Activity Date | 2026-09-16 |
| Recorded Date | 2026-09-16 |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-16 |

---

## 🎯 Objective

Mengimplementasikan standardisasi arsitektural penyimpanan host untuk platform Tomcat Monitoring:
1. **Renaming Direktori Monitoring**: Mengganti penamaan direktori generik `C:\monitoring` menjadi **`C:\tm_data`** (Windows) dan **`/opt/tm_data`** (Linux, mengikuti FHS standard `/opt` untuk aplikasi opsional).
2. **Parameterisasi Drive & Mount Storage**: Menjadikan seluruh root path direktori dapat ditentukan secara dinamis melalui inventory `.ini`, file `CONFIG`, maupun Jenkins parameter.
3. **Pembersihan Direktori Log**: Mengeliminasi folder `logs/` dari direktori monitoring dan menerapkan model *Pure Container Logging* berbasis `docker logs` / `podman logs`.

Aktivitas ini menuntaskan **TASK-TM-036** dan merealisasikan keputusan arsitektur [TM-ADR-0030](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0030.md).

---

## 🏗️ Implementation Details

### 1. Perubahan Matriks Konfigurasi & Playbook

| File | Perubahan yang Dilakukan |
| :--- | :--- |
| `inventories/aws-staging.ini` | Mengupdate variabel `windows_nodes` ke `tm_root_dir=C:\tm_data`, `project_root=C:\tm_data`, dan subpath `spool`, `secrets`, `tls`, `bin`. |
| `inventories/group_vars/all.yml` | Mendefinisikan default `tm_root_dir_windows: "C:\tm_data"`, `tm_root_dir_linux: "/opt/tm_data"`, dan relasi dinamis `project_root: "{{ custom_project_root \| default(tm_root_dir) }}"`. |
| `roles/role_host_prep/tasks/windows/directories.yml` | Menggunakan `{{ project_root }}` secara dinamis, menghapus `logs` dari pembuatan direktori, dan menyelaraskan task pembersihan skrip/biner. |
| `roles/role_host_prep/tasks/windows/secrets_and_tls.yml` | Mengarahkan pembuatan secrets Alertmanager dan Prometheus ke `{{ project_root }}\config\...`. |
| `roles/role_host_prep/tasks/linux/directories.yml` | Menghapus direktori `logs/` dari daftar pembuatan folder Linux. |
| `roles/role_container_stack/tasks/windows/diagnostic_service.yml` | Mengubah mount bind ke `{{ project_root }}\config...`, `{{ project_root }}\spool...`, dan menghapus mount volume `logs`. |
| `roles/role_container_stack/tasks/windows/prometheus.yml` | Mengubah mount bind config ke `{{ project_root }}\config\prometheus`. |
| `roles/role_container_stack/tasks/windows/alertmanager.yml` | Mengubah mount bind config ke `{{ project_root }}\config\alertmanager`. |
| `roles/role_container_stack/tasks/windows/build_images.yml` | Mengarahkan build context ke `{{ project_root }}\docker\windows`. |
| `roles/role_event_collector/tasks/windows/main.yml` | Mengarahkan staging binary dan spool mount ke `{{ project_root }}\spool`. |
| `config/diagnostic-service/application.win.json` | Memperbarui path sertifikat, token, dan target file ke `C:\tm_data\...`. |
| `config/diagnostic-service/targets.win.json` | Memperbarui path `collectorSpool` ke `C:\tm_data\spool`. |
| `CONFIG` & `CONFIG.example` | Menambahkan parameter `TM_ROOT_DIR`. |
| `Jenkinsfile` | Menambahkan parameter `TM_ROOT_DIR` dan menginjeksi `-e custom_tm_root_dir`. |

---

## 🧪 Verification & Results

1. **Static Validation Baseline**:
   - `bash scripts/validate.sh` $\rightarrow$ **100% Passed**.
2. **Live AWS EC2 Windows Deployment**:
   - Playbook `playbooks/deploy-windows.yml` sukses diterapkan pada `aws-ec2-win-01` (`ok=86 changed=38 failed=0`).
   - Direktori `C:\tm_data\` terbentuk dengan subfolder `bin`, `config`, `data`, `docker`, `secrets`, `spool`, `tls` tanpa folder `logs`.
   - Seluruh container NanoServer berjalan sehat di `C:\tm_data`.
   - Linux default path dikonfirmasi sebagai `/opt/tm_data` (FHS `/opt` compliant).
3. **Container Logging Inspection**:
   - Operator SRE menginspeksi log langsung melalui `docker logs <container_name> --tail 50`.

---

## 📌 Conclusion

Standardisasi direktori host ke `tm_data`, fleksibilitas konfigurasi drive/mount storage, dan eliminasi direktori log statis telah berhasil diterapkan secara simetris dan terverifikasi penuh pada platform.

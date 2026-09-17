# TN-022 — Standardize Host Workspace Directory to `tm-home`, Two-Tier Storage Architecture, and Pure Container Logging Model

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Host Storage Architecture, Two-Tier Storage & Container Observability |
| Record Type | Live |
| Project | Tomcat Monitoring |
| Phase | Continuous Integration and Deployment |
| Activity Date | 2026-09-16 |
| Recorded Date | 2026-09-16 (Updated: 2026-09-17) |
| Owner | Eddy Wiyatno |
| Working Mode | Write |
| Authorization Status | Approved |
| Approved By | Eddy Wiyatno |
| Approval Date | 2026-09-16 |

---

## 🎯 Objective

Mengimplementasikan standardisasi arsitektural penyimpanan host dan storage model untuk platform Tomcat Monitoring:
1. **Renaming Direktori Workspace Host**: Mengganti penamaan direktori menjadi **`C:\tm-home`** (Windows) dan **`/opt/tm-home`** (Linux, mengikuti standar Tomcat `*_HOME` dan FHS `/opt` untuk aplikasi pihak ketiga).
2. **Penerapan Model Dua Mekanisme Penyimpanan (*Two-Tier Storage Architecture*)**:
   - **Tier 1 (Container Engine Named Volumes)**: Database stateful ber-I/O tinggi (`prometheus_data`, `diagnostic_data`, `alertmanager_data`, `mailpit_data`, `tomcat_logs`) dikelola oleh Docker/Podman engine.
   - **Tier 2 (Host Home Directory `tm-home`)**: Direktori kontrol host untuk konfigurasi deklaratif (`config/`), kredensial (`secrets/`), sertifikat TLS (`tls/`), event buffer (`spool/`), dan biner operator (`bin/`, `scripts/`).
3. **Parameterisasi Drive & Mount Storage**: Menjadikan seluruh root path direktori dapat ditentukan secara dinamis melalui inventory `.ini`, file `CONFIG`, maupun Jenkins parameter.
4. **Pembersihan Direktori Log**: Mengeliminasi folder `logs/` dari direktori monitoring dan menerapkan model *Pure Container Logging* berbasis `docker logs` / `podman logs`.

Aktivitas ini menuntaskan **TASK-TM-036** dan merealisasikan keputusan arsitektur [TM-ADR-0030](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0030.md).

---

## 🏗️ Implementation Details

### 1. Perubahan Matriks Konfigurasi & Playbook

| File | Perubahan yang Dilakukan |
| :--- | :--- |
| `inventories/aws-staging.ini` | Mengupdate variabel `windows_nodes` ke `tm_root_dir=C:\tm-home`, `project_root=C:\tm-home`, dan subpath `spool`, `secrets`, `tls`, `bin`, serta Linux ke `tm_root_dir=/opt/tm-home`. |
| `inventories/group_vars/all.yml` | Mendefinisikan default `tm_root_dir_windows: "C:\tm-home"`, `tm_root_dir_linux: "/opt/tm-home"`, dan relasi dinamis `project_root: "{{ custom_project_root \| default(tm_root_dir) }}"`. |
| `roles/role_host_prep/tasks/windows/directories.yml` | Menggunakan `{{ project_root }}` secara dinamis, menghapus `logs` dari pembuatan direktori, dan menyelaraskan task pembersihan skrip/biner. |
| `roles/role_host_prep/tasks/windows/secrets_and_tls.yml` | Mengarahkan pembuatan secrets Alertmanager dan Prometheus ke `{{ project_root }}\config\...`. |
| `roles/role_host_prep/tasks/linux/directories.yml` | Menghapus direktori `logs/` dari daftar pembuatan folder Linux. |
| `roles/role_container_stack/tasks/windows/diagnostic_service.yml` | Mengubah mount bind ke `{{ project_root }}\config...`, `{{ project_root }}\spool...`, dan mount DB ke Named Volume `diagnostic_data`. |
| `roles/role_container_stack/tasks/windows/prometheus.yml` | Mengubah mount bind config ke `{{ project_root }}\config\prometheus` dan DB ke Named Volume `prometheus_data`. |
| `roles/role_container_stack/tasks/windows/alertmanager.yml` | Mengubah mount bind config ke `{{ project_root }}\config\alertmanager` dan data ke Named Volume `alertmanager_data`. |
| `roles/role_container_stack/tasks/windows/build_images.yml` | Mengarahkan build context ke `{{ project_root }}\docker\windows`. |
| `roles/role_event_collector/tasks/windows/main.yml` | Mengarahkan staging binary dan spool mount ke `{{ project_root }}\spool`. |
| `config/diagnostic-service/application.win.json` | Memperbarui path sertifikat, token, dan target file ke `C:\tm-home\...`. |
| `config/diagnostic-service/targets.win.json` | Memperbarui path `collectorSpool` ke `C:\tm-home\spool`. |
| `CONFIG` & `CONFIG.example` | Menambahkan parameter `TM_ROOT_DIR` dengan contoh `C:\tm-home` dan `/opt/tm-home`. |
| `Jenkinsfile` | Menambahkan parameter `TM_ROOT_DIR` dan menginjeksi `-e custom_tm_root_dir`. |

---

## 🧪 Verification & Results

1. **Static Validation Baseline**:
   - `bash scripts/validate.sh` $\rightarrow$ **100% Passed**.
2. **Live AWS EC2 Windows Deployment**:
   - Playbook `playbooks/deploy-windows.yml` sukses diterapkan pada `aws-ec2-win-01` (`ok=86 changed=38 failed=0`).
   - Direktori `C:\tm-home\` terbentuk dengan subfolder `bin`, `config`, `docker`, `secrets`, `spool`, `tls` tanpa folder `logs`.
   - Seluruh container NanoServer berjalan sehat mengacu ke `C:\tm-home`.
   - Linux default path dikonfirmasi sebagai `/opt/tm-home` (FHS `/opt` compliant).
3. **Container Logging Inspection**:
   - Operator SRE menginspeksi log langsung melalui `docker logs <container_name> --tail 50`.

---

## 📌 Conclusion

Standardisasi direktori host ke `tm-home`, pemisahan tegas Two-Tier Storage (Container Named Volumes untuk DB + Host `tm-home` untuk config/tools), fleksibilitas konfigurasi drive/mount storage, dan eliminasi direktori log statis telah berhasil diterapkan secara simetris dan terverifikasi penuh pada platform.

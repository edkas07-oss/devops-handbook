---
title: "TN-015: Deploy Persistent Monitoring Runtime"
date: "2026-09-02"
status: "Completed"
author: "Antigravity Agent"
tags: ["prometheus", "alertmanager", "deployment", "persistent", "diagnostic-service"]
---

# TN-015: Deploy Persistent Monitoring Runtime

## Objective
Mengimplementasikan script persistent runtime (pod/container/volume deployment scripts) untuk Prometheus, Alertmanager, dan Diagnostic Service di repositori `tomcat-monitoring`. Selanjutnya, melakukan deployment konfigurasi `TomcatDown` yang divalidasi pada TN-014 ke environment persisten dan memverifikasi integrasi end-to-end webhook `firing` dan `resolved` ke Diagnostic Service.

## Implementasi
1. **Pembaruan Repositori `alertmanager`:**
   - Memodifikasi `scripts/run.sh` pada repositori runtime generic `git/alertmanager` untuk mendukung 3 parameter volume persisten: `<config-volume>`, `<truststore-volume>`, dan `<data-volume>`, menjadikannya konsisten dengan Prometheus.
2. **Pembuatan Script Deployment di `tomcat-monitoring`:**
   - `scripts/deploy-prometheus.sh`: Mengorkestrasi backup container, inisialisasi volume via `initialize-prometheus-volumes.sh`, dan deployment via referensi image pada repositori generic `prometheus`.
   - `scripts/deploy-alertmanager.sh`: Mengorkestrasi inisialisasi volume, setup file dummy secrets (`diagnostic-service-webhook-url` yang mengarah ke `https://diagnostic-service:8443` beserta self-signed cert truststore), dan mendeploy runtime persisten.
   - `scripts/deploy-diagnostic-service.sh`: Menjalankan service dengan konfigurasi `application.json` spesifik untuk lab dan membuat volume `diagnostic_data`. Pembuatan self-signed cert secara otomatis ditangani di script ini agar dapat dipercaya oleh Alertmanager.
3. **Pembaruan Static Contract:**
   - Menambahkan ketiga skrip deployment di atas ke `REQUIRED_FILES` pada `scripts/validate.sh`.
   - Proses validasi berhasil dilewati tanpa error.

## Verifikasi End-to-End
Skenario Tomcat down di-test di environment persisten menggunakan Podman network `devops-lab`:
1. `podman stop tomcat-jmx-exporter` dieksekusi.
2. Prometheus Rule `TomcatDown` dievaluasi selama 2 menit.
3. Alertmanager berhasil mem-forward alert `firing` ke Diagnostic Service menggunakan endpoint TLS.
4. Data di volume persisten (`diagnostic_data`) diambil melalui proses gracefully stop dan probe query (`probe.js`) memverifikasi payload SQLite. (`sqlite_firing=1`).
5. `podman start tomcat-jmx-exporter` dieksekusi.
6. Alert manager mengirimkan status `resolved`. Probe mengkonfirmasi penyimpanan `sqlite_resolved=1`.

Semua layanan sekarang terpasang dan berjalan secara persisten di lab environment.

## Keputusan Arsitektural (ADR)
- Orchestration script tetap di `tomcat-monitoring/scripts/`, sedangkan *run command* spesifik container tetap memanggil `run.sh` dari repositori runtime.
- Alertmanager diperbarui untuk memiliki *truststore mount*, memastikan semua integrasi TLS internal terisolasi dan mudah dirotasi via orchestrator script.

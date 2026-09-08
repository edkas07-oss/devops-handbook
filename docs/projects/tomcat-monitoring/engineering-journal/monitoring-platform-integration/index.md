# Monitoring Platform Integration Engineering Journal

## 🔍 Overview

Phase ini mencatat perjalanan engineering lanjutan setelah fase Diagnostic MVP Pilot selesai. Fokus utama fase ini adalah penguatan ketahanan arsitektur (*resilience*), peniadaan titik buta notifikasi (*Zero Silent Failure*), pengelolaan siklus hidup database SQLite lokal, penyediaan dashboard observabilitas terpusat, serta persiapan kesiapan operasional menuju lingkungan produksi (*production readiness*).

## 🎯 Objective

Mengintegrasikan seluruh subsistem monitoring dan diagnostik ke dalam satu kesatuan platform observabilitas yang tangguh, mandiri, dan bebas dari titik kegagalan tunggal:

```text
+-----------------------------------------------------------------------------+
|                     Monitoring Platform Integration Scope                   |
+-----------------------------------------------------------------------------+
| 1. Resilience & Zero Silent Failure (Scrape Mandiri & Direct Emergency SMTP)|
| 2. SQLite Engine Resilience (Stale Lock Recovery & Housekeeping Retention)  |
| 3. Operator Audit Trail & Action Feedback Logging (TM-ADR-0014)             |
| 4. Rulepack Expansion (Thread Starvation & Memory Pressure / GC)            |
| 5. Observability & Deployment Automation (Grafana, Log Aggregation, Ansible)|
+-----------------------------------------------------------------------------+
```

## 🛠️ Implementation Result

| Component | Implementation | Status |
| --- | --- | --- |
| **Diagnostic Service Self-Monitoring** | Scrape target HTTPS `/health` di Prometheus dengan TLS CA verification dan Alert rule `DiagnosticServiceDown` | Completed (TN-001) |
| **Emergency Direct SMTP Routing** | Alertmanager sub-route `direct-email-emergency` mem-bypass webhook ke Mailpit | Completed (TN-001) |
| **Container Auto-Healing Policy** | Standarisasi flag `--restart=on-failure:5` pada seluruh skrip deployment container monitoring | Completed (TN-002) |
| **Systemd Restart Supervisor** | Aktivasi daemon pengawas restart `podman-restart.service` pada level user session | Completed (TN-002) |
| **Layered Failure Resilience Architecture** | Adopsi model ketahanan berlapis 3 tingkat dan pemisahan domain monitoring (TM-ADR-0021) | Completed (TN-002) |

## 📄 Technical Notes

1. **[TN-001 — Implement and Verify Diagnostic Service Self-Monitoring and Direct Emergency SMTP Routing](TN-001-implement-and-verify-diagnostic-service-self-monitoring-and-emergency-smtp-routing.md)**

    Mengimplementasikan mitigasi arsitektur TM-ADR-0016 (Zero Silent Failure): menambahkan scrape target HTTPS `/health` Diagnostic Service di Prometheus, membuat alert rule `DiagnosticServiceDown` (`for: 1m`, `critical`), mengonfigurasi sub-route dan receiver `direct-email-emergency` di Alertmanager (bypass webhook ke Mailpit), serta memverifikasi siklus firing dan resolved secara live di `devops-lab`.

2. **[TN-002 — Implement Container Auto-Healing Policy and Multi-Layer Failure Resilience Architecture](TN-002-implement-container-auto-healing-and-crashloop-resilience-policy.md)**

    Menetapkan arsitektur ketahanan sistem berlapis (TM-ADR-0021), pemisahan domain monitoring antara host NMS (SolarWinds/NOC) dan observabilitas aplikasi (Prometheus/SRE), standarisasi container restart policy (`--restart=on-failure:5`), serta pemetaan komprehensif mitigasi 5 vektor kegagalan startup (CrashLoop Prevention).

## 🎓 Lessons Learned

1. **Harmonisasi Auto-Healing dan Alerting:** Auto-healing pada level runtime container menangani pemulihan gangguan sesaat (*transient blip*) dalam hitungan detik tanpa membebani operator dengan alarm palsu. Sebaliknya, alert rule dengan jeda evaluasi 1 menit (`for: 1m`) menjadi jaring pengaman utama saat terjadi kegagalan sistemik.
2. **Pentingnya Bounded Retry pada Container:** Membatasi jumlah restart maksimum (`MaxRetries=5`) mencegah skenario *CrashLoop* yang berpotensi menghabiskan sumber daya CPU dan merusak persistensi volume data saat container mengalami kegagalan fatal.

---

## 🔗 Related Documentation

- [Diagnostic MVP Pilot](../diagnostic-mvp-pilot/index.md)
- [Monitoring Integration and Runtime Deployment](../monitoring-integration-and-runtime-deployment/index.md)
- [Follow-up Tasks Backlog](../../follow-up-tasks.md)
- [Architecture Index](../../architecture/index.md)
- [TM-ADR-0016 — Designate Diagnostic Service as Canonical Incident Notification Authority](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0016.md)
- [TM-ADR-0021 — Adopt Layered Failure Resilience, Container Auto-Healing, and Monitoring Domain Separation](../../../../adr/tomcat-monitoring/adr-records/TM-ADR-0021.md)


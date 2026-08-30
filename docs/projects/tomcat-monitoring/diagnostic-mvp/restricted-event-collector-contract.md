# Restricted Event Collector Contract

## 🔍 Overview

Restricted Event Collector menyediakan evidence container dan host tanpa
memberikan Diagnostic Service akses ke Podman socket atau host-control API.
Desain pilot memakai host-side rootless service dan one-way normalized spool.

## 🏛️ Ownership and Form

Source, packaging, lifecycle, dan component test collector dimiliki repository
baru `tomcat-diagnostic-event-collector`. Repository `tomcat-monitoring`
memiliki allowlist, deployment configuration, read-only spool integration, dan
end-to-end verification. Repository tersebut belum dibuat.

Collector berjalan sebagai host-side rootless service. Ia menulis record JSON
berversi melalui temporary file dan atomic rename ke partition target. Spool
dipasang read-only pada Diagnostic Service. Tidak ada request API dari webhook
ke collector.

## 🔐 Allowlist

Collector hanya boleh membaca:

- lifecycle dan state container yang cocok dengan configured target identity;
- exit code, start/finish time, restart, dan OOM indicator;
- approved cgroup memory events;
- approved user-service result dan bounded journal/kernel OOM events; serta
- capacity metadata untuk approved diagnostic paths.

Ia menolak arbitrary container identity, command, filter, filesystem path,
runtime mutation, exec, start, stop, restart, remove, dan create operation.
Evidence yang membutuhkan privilege yang belum disetujui dilaporkan
`unavailable`; collector tidak menaikkan privilege otomatis.

## 📦 Record Contract

Setiap record memuat schema version, canonical target identity, runtime
generation, normalized event type, UTC event time, source, bounded typed value,
redaction state, dan collection status. Satu record maksimum 16 KiB. Retention,
file count, total spool size, dan read window harus dibatasi dan divalidasi.

## ✅ Acceptance

Verification wajib membuktikan identity isolation, atomic read behavior,
bounded retention, malformed-record rejection, symlink/path-escape rejection,
unavailable-source behavior, dan tidak adanya control surface.

## 📌 Status

**Accepted contract — repository and runtime not implemented.**

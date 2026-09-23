# TC-ADR-0008

| Property | Value |
| --- | --- |
| **ADR ID** | TC-ADR-0008 |
| **Title** | Zero-Touch Day-1 Host Bootstrapping via Self-Destructing Ephemeral SSH Access |
| **Project** | Apache Tomcat Enterprise |
| **Section** | Infrastructure Security and Provisioning |
| **Status** | Accepted |
| **Date** | 2026-09-22 |

---

## 🔍 Overview

Apache Tomcat Enterprise menetapkan pola **Self-Destructing Ephemeral SSH Access** untuk menyelesaikan paradoks *Day-1 Bootstrapping* pada armada VM yang sudah ada (*brownfield hosts*). Pola ini memastikan bahwa kredensial SSH yang digunakan untuk memasang biner `tcctl` dan menginisialisasi GitOps timer pada hari pertama secara otomatis memusnahkan dirinya sendiri (*self-destruct*) dari `~/.ssh/authorized_keys` seketika saat proses bootstrap selesai. Pendekatan ini mengeliminasi risiko celah keamanan (*backdoor*) dan membebaskan administrator dari kewajiban membersihkan kunci secara manual di puluhan host target.

---

## 🌍 Context

Untuk menjalankan model Pure GitOps ([TC-ADR-0007](TC-ADR-0007.md)), host target harus memiliki biner `tcctl` dan unit systemd timer yang terpasang. Dalam perancangannya, muncul dua pertanyaan arsitektur mendasar dari tim:

> **Pertanyaan 1**: *"Tapi lucunya adalah tcctl itu di deploy-nya sepertinya harus menggunakan CI/CD tradisional, kecuali sudah embedded di image VM. Tapi itu sulit karena VM sudah terbentuk (brownfield). Betul begitu?"*

> **Pertanyaan 2**: *"Apakah ada mekanisme SSH yang disediakan hanya 1 kali penggunaannya? Soalnya kalau tidak, maka PR sekali harus menghapus key di semua host. Betulkah demikian?"*

### Analisis Dilema Arsitektur:

1. **The Chicken-and-Egg Bootstrapping Paradox (Greenfield vs Brownfield)**:
   - Pada VM baru (*greenfield*), biner `tcctl` dapat langsung di-bake ke dalam *Golden Image* (Packer/AMI).
   - Namun pada armada VM eksisting (*brownfield*) yang sudah lama beroperasi di enterprise, biner operator tidak bisa muncul secara mandiri tanpa ada intervensi awal.
   - **Kesimpulan**: Diperlukan akses awal satu kali (*Day-1 Provisioning*) menyerupai mekanisme tradisional (SSH push / Ansible) untuk menanam biner operator. Namun intervensi ini **hanya terjadi 1 kali seumur hidup server**, bukan menjadi metode deployment harian (Day-2 Ongoing).
2. **Risiko Tertinggalnya Kunci Statis (*Static Credential Leakage*)**:
   - Jika administrator menambahkan SSH public key ke `~/.ssh/authorized_keys` di 50+ server untuk keperluan bootstrap, kunci tersebut kerap tertinggal dan menjadi celah keamanan laten (*dormant backdoor*).
3. **Beban Operasional Penghapusan Manual (PR Besar yang Terbengkalai)**:
   - Mengandalkan "PR sekali untuk menghapus key di semua host" secara manual setelah bootstrap selesai adalah pekerjaan yang memakan waktu dan rawan kelalaian manusia (*human error*).

---

## ⚖️ Decision

Project memutuskan untuk mengadopsi pola **Self-Destructing Ephemeral SSH Access** untuk seluruh aktivitas Day-1 Bootstrapping dengan ketentuan:

1. **Penandaan Tag Kunci Sementara**:
   - Public key yang diinjeksi untuk bootstrap diberi tanda komentar metadata khusus:
     ```text
     ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... # ephemeral-day1-bootstrap
     ```
2. **Otomasi Pembersihan Diri (*Self-Purge Execution*)**:
   - Skrip bootstrap atau playbook Ansible Day-1 diprogram untuk mengeksekusi pemusnahan dirinya sendiri pada baris paling akhir sebelum sesi SSH ditutup:
     ```bash
     # Menghapus baris kunci bootstrap dari authorized_keys sebelum koneksi berakhir
     sed -i '/# ephemeral-day1-bootstrap/d' ~/.ssh/authorized_keys
     ```
   - Pada Ansible:
     ```yaml
     - name: Self-Destruct Bootstrap SSH Key
       ansible.posix.authorized_key:
         user: "{{ ansible_user }}"
         state: absent
         key: "{{ lookup('file', 'files/bootstrap_key.pub') }}"
     ```
3. **Jaminan Waktu Hangus Instan**:
   - Begitu proses `tcctl gitops init` selesai (~15-30 detik), akses SSH tersebut langsung hangus secara permanen. Kunci privat bootstrap yang ada di workstation operator tidak dapat digunakan lagi untuk login. Upaya koneksi kedua langsung ditolak (`Permission denied (publickey)`).
4. **Zero Manual Cleanup & Zero Leftover Credentials**:
   - Administrator tidak perlu membuat jadwal pembersihan atau PR terpisah untuk menghapus kunci di puluhan server. Host target secara mandiri berada dalam kondisi bersih (*clean state*).
5. **Transisi Penuh ke GitOps (Day-2)**:
   - Setelah kunci bootstrap terhapus, seluruh kendali operasional server resmi beralih 100% ke GitOps Pull Reconciler otonom (`tcctl gitops sync`). Host produksi tidak lagi membutuhkan port inbound SSH terbuka untuk rilis aplikasi.

---

## 🏛️ Architecture & Self-Destruction Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Admin as DevOps Engineer / Ansible
    participant SSH as SSH Daemon / authorized_keys
    participant Host as Target Host (VM)
    participant GitOps as tcctl GitOps Timer

    Note over Admin,Host: DAY-1: ONE-TIME BOOTSTRAP
    Admin->>SSH: 1. Login menggunakan Ephemeral Bootstrap Key
    Admin->>Host: 2. Salin biner tcctl ke /usr/local/bin/tcctl
    Admin->>Host: 3. loginctl enable-linger tomcat
    Admin->>GitOps: 4. tcctl gitops init (Start systemd timer)
    GitOps-->>Admin: 5. GitOps Ready (Timer Active)
    
    Note over Admin,SSH: TAHAP SELF-DESTRUCTION (Pembersihan Otomatis)
    Admin->>SSH: 6. Execute: sed -i '/bootstrap-key/d' authorized_keys
    Note over SSH: Kunci terhapus seketika dari file!
    Admin->>SSH: 7. Close SSH Session
    
    Note over Admin,Host: DAY-2: ACCESS PERMANENTLY REVOKED
    Admin-xSSH: 8. Login ditolak! (Permission Denied - No Key)
    Note over GitOps: Host otonom 100% melayani GitOps tanpa SSH!
```

---

## 🌟 Consequences

### Positive
- **Beban Operasional Nol**: Tidak ada tiket perbaikan atau PR untuk menghapus kunci di puluhan server.
- **Kepatuhan Audit Ketat**: Tidak ada akun atau kunci SSH sisa instalasi yang tertinggal di lingkungan produksi.
- **Transisi Sempurna**: Menjamin transisi bersih dari era *Push Deployment* ke era *Pure Pull-Based GitOps*.

### Negative / Trade-offs
- Jika eksekusi bootstrap terputus sebelum mencapai baris penghapusan (misal putus koneksi mendadak), kunci mungkin masih tersisa. Hal ini dimitigasi dengan membungkus skrip ke dalam trap sinyal Bash (`trap 'cleanup' EXIT`).

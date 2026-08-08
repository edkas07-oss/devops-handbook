# 📦 Podman Cheat Sheet

## 🔍 Overview

Halaman ini berisi kumpulan perintah **Podman** yang paling sering digunakan selama proses **development**, **build**, **deployment**, **troubleshooting**, dan **maintenance**.

Dokumen ini berfungsi sebagai **Quick Reference** sehingga hanya menjelaskan fungsi, sintaks, contoh penggunaan, dan kapan perintah tersebut digunakan.

Untuk pembahasan yang lebih lengkap, lihat dokumentasi **How-To → Podman**.

---

## 🔥 Frequently Used

### List Running Containers

Menampilkan seluruh container yang sedang berjalan.

**Syntax**

```bash
podman ps
```

!!! tip "When to Use"

    Digunakan untuk memastikan container telah berhasil dijalankan.

---

### Show Container Logs

Menampilkan log container secara real-time.

**Syntax**

```bash
podman logs -f CONTAINER
```

**Example**

```bash
podman logs -f personal-site
```

!!! tip "When to Use"

    Digunakan saat troubleshooting atau memverifikasi startup aplikasi.

---

### Build Image

Membangun container image dari **Containerfile**.

**Syntax**

```bash
podman build -t IMAGE:TAG .
```

**Example**

```bash
podman build -t personal-site:1.0 .
```

!!! tip "When to Use"

    Digunakan setelah melakukan perubahan pada Containerfile.

---

### Run Container

Menjalankan container baru.

**Syntax**

```bash
podman run -d IMAGE
```

**Example**

```bash
podman run \
-d \
--name personal-site \
-p 8080:80 \
personal-site:1.0
```

!!! tip "When to Use"

    Digunakan untuk menjalankan container hasil build.

---

### Open Interactive Shell

Masuk ke dalam container.

**Syntax**

```bash
podman exec -it CONTAINER bash
```

**Example**

```bash
podman exec -it personal-site bash
```

!!! tip "When to Use"

    Digunakan untuk melakukan troubleshooting di dalam container.

---

## 📦 Images

### List Images

Menampilkan seluruh image yang tersedia.

**Syntax**

```bash
podman images
```

---

### Search Image

Mencari image pada registry.

**Syntax**

```bash
podman search nginx
```

---

### Pull Image

Mengunduh image dari registry.

**Syntax**

```bash
podman pull IMAGE
```

**Example**

```bash
podman pull nginx:latest
```

---

### Remove Image

Menghapus image.

**Syntax**

```bash
podman rmi IMAGE
```

**Example**

```bash
podman rmi nginx:latest
```

---

### Remove Unused Images

Menghapus seluruh image yang tidak digunakan.

**Syntax**

```bash
podman image prune
```

---

## 🏗️ Build

### Build Image

Membangun image dari **Containerfile**.

**Syntax**

```bash
podman build -t IMAGE:TAG .
```

**Common Options**

| Option | Description |
|---------|-------------|
| `-t` | Image Name dan Tag |
| `-f` | Containerfile |
| `--no-cache` | Tidak menggunakan cache |

**Example**

```bash
podman build -t personal-site:1.0 .
```

---

### Build Without Cache

Melakukan build tanpa menggunakan cache.

**Syntax**

```bash
podman build --no-cache -t IMAGE:TAG .
```

---

### Build Using Containerfile

Menentukan Containerfile secara eksplisit.

**Syntax**

```bash
podman build -f Containerfile -t IMAGE:TAG .
```

---

## 🚀 Containers

### List Running Containers

Menampilkan container yang sedang berjalan.

**Syntax**

```bash
podman ps
```

---

### List All Containers

Menampilkan seluruh container.

**Syntax**

```bash
podman ps -a
```

---

### Run Container

Menjalankan container baru.

**Syntax**

```bash
podman run IMAGE
```

**Common Options**

| Option | Description |
|---------|-------------|
| `-d` | Background Mode |
| `-it` | Interactive Mode |
| `--name` | Nama Container |
| `-p` | Publish Port |
| `-v` | Mount Volume |
| `--network` | Network |

---

### Start Container

Menjalankan container yang berhenti.

**Syntax**

```bash
podman start CONTAINER
```

---

### Stop Container

Menghentikan container.

**Syntax**

```bash
podman stop CONTAINER
```

---

### Restart Container

Restart container.

**Syntax**

```bash
podman restart CONTAINER
```

---

### Remove Container

Menghapus container.

**Syntax**

```bash
podman rm CONTAINER
```

---

### Force Remove Container

Menghapus container secara paksa.

**Syntax**

```bash
podman rm -f CONTAINER
```

---

## 💻 Execute Commands

### Open Interactive Shell

Masuk ke shell container.

**Syntax**

```bash
podman exec -it CONTAINER bash
```

---

### Execute Command

Menjalankan command tanpa masuk shell.

**Syntax**

```bash
podman exec CONTAINER COMMAND
```

**Example**

```bash
podman exec nginx01 ls /etc/nginx
```

---

## 📄 Logs

### Show Logs

Menampilkan seluruh log container.

**Syntax**

```bash
podman logs CONTAINER
```

---

### Follow Logs

Menampilkan log secara real-time.

**Syntax**

```bash
podman logs -f CONTAINER
```

---

### Show Last Logs

Menampilkan sejumlah log terakhir.

**Syntax**

```bash
podman logs --tail 100 CONTAINER
```

---

## 🔎 Inspect

### Inspect Container

Menampilkan informasi lengkap container.

**Syntax**

```bash
podman inspect CONTAINER
```

---

### Inspect Image

Menampilkan informasi image.

**Syntax**

```bash
podman inspect IMAGE
```

Jika ingin inspect ingin difilter, misal berdasarkan `label`.

**Syntax**

```bash
podman inspect localhost/jenkins-podman:1.0 \
  --format '{{ .Labels }}'
```

Atau jika ingin yang lebih mudah dibaca.

**Syntax**

```bash
podman inspect localhost/jenkins-podman:1.0 | less
```

---

### Show Health Status

Menampilkan status Health Check.

**Syntax**

```bash
podman inspect CONTAINER --format '{{ .State.Health.Status }}'
```

---

### Show Container IP

Menampilkan alamat IP container.

**Syntax**

```bash
podman inspect CONTAINER --format '{{ .NetworkSettings.IPAddress }}'
```

---

## 🌐 Networks

### List Networks

```bash
podman network ls
```

---

### Create Network

```bash
podman network create NETWORK
```

---

### Inspect Network

```bash
podman network inspect NETWORK
```

---

### Remove Network

```bash
podman network rm NETWORK
```

---

## 💾 Volumes

### List Volumes

```bash
podman volume ls
```

---

### Create Volume

```bash
podman volume create VOLUME
```

---

### Inspect Volume

```bash
podman volume inspect VOLUME
```

---

### Remove Volume

```bash
podman volume rm VOLUME
```

---

## 📦 Registry

### Login

```bash
podman login REGISTRY
```

---

### Push Image

```bash
podman push IMAGE
```

---

### Tag Image

```bash
podman tag SOURCE_IMAGE TARGET_IMAGE
```

---

## 📊 Monitoring

### Show Resource Usage

```bash
podman stats
```

---

### Show Container Statistics

```bash
podman stats CONTAINER
```

---

## 📁 File Operations

### Copy File to Container

```bash
podman cp FILE CONTAINER:/PATH
```

---

### Copy File from Container

```bash
podman cp CONTAINER:/PATH FILE
```

---

## 🧹 Cleanup

### Remove Stopped Containers

```bash
podman container prune
```

---

### Remove Unused Images

```bash
podman image prune
```

---

### Remove Unused Volumes

```bash
podman volume prune
```

---

### Remove Unused Resources

```bash
podman system prune
```

---

### Deep Cleanup

```bash
podman system prune -a
```

---

## 🚀 Project Commands

### Build Project

Membangun image menggunakan konfigurasi project.

```bash
./build.sh
```

---

### Run Project

Menjalankan container menggunakan konfigurasi project.

```bash
./run.sh
```

---

### Stop Project

Menghentikan container.

```bash
./stop.sh
```

---

## 🔗 Related Documentation

| Documentation | Description |
|---------------|-------------|
| **How-To → Podman** | Dokumentasi lengkap penggunaan Podman. |
| **Deployment** | Implementasi deployment menggunakan Podman. |
| **Automation** | Otomatisasi deployment menggunakan Jenkins Pipeline. |
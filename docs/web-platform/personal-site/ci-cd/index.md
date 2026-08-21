# CI/CD

## Overview

Personal Site menggunakan dua Jenkins pipeline terpisah. CI mengubah source
Hugo menjadi immutable artifact, sedangkan CD memilih dan menjalankan artifact
tersebut pada NGINX runtime. CD tidak melakukan build Hugo ulang.

## Pipeline Definitions

| Pipeline | Definition | Responsibility |
| --- | --- | --- |
| Continuous Integration | `personal-site/Jenkinsfile` | Build, validate, package, dan publish artifact |
| Continuous Deployment | `personal-site/Jenkinsfile.cd` | Download, validate, deploy, dan verify release |

Keduanya membaca konfigurasi non-secret dari `deployment/CONFIG`. Secret MinIO
tetap dikelola oleh Jenkins Credentials dengan ID `minio-root`.

## Continuous Integration

![Personal Site CI Pipeline](../assets/images/personal-site-ci-pipeline.svg)

```text
Checkout source
  → initialize Hugo submodule
  → build Hugo
  → validate public/index.html
  → package public/
  → upload artifact to MinIO
```

Artifact contract:

```text
Name    : personal-site-<BUILD_NUMBER>.tar.gz
Root    : public/
Storage : MinIO bucket personal-site
```

## Continuous Deployment

![Personal Site CD Pipeline](../assets/images/personal-site-cd-pipeline.svg)

Operator menjalankan job melalui **Build with Parameters** dan mengisi
`ARTIFACT_NAME` dengan nama artifact dari CI yang berhasil.

```text
Validate ARTIFACT_NAME
  → download from MinIO
  → validate archive paths and public/index.html
  → back up active volume content
  → populate www-personal-site
  → deploy personal-site-web
  → validate HTTP, health, and read-only mount
```

## Runtime Configuration

| Setting | Value |
| --- | --- |
| Jenkins agent label | `builder-01` |
| MinIO URL | `http://host.containers.internal:9000` |
| MinIO bucket | `personal-site` |
| NGINX container | `personal-site-web` |
| NGINX image | `localhost/nginx-image:1.0` |
| Podman network | `web` |
| Content volume | `www-personal-site` |
| HTTP host port | `8091` |
| HTTPS host port | `8443` |
| SSH host port | `2224` |

## Validation

Deployment dinyatakan berhasil ketika:

- HTTP `http://127.0.0.1:8091/` memberikan respons sukses;
- healthcheck container berstatus `healthy`;
- `/var/www/html` berasal dari `www-personal-site`; dan
- mount content memiliki `RW=false`.

## Failure and Rollback

Kegagalan sebelum volume diperbarui tidak mengubah runtime. Setelah volume
mulai diperbarui, pipeline memulihkan `previous-content.tar.gz` jika backup
tersedia, lalu menjalankan kembali deployment script.

Temporary loader container, staging directory, deployment state, dan archive
lokal dibersihkan pada post action.

## Engineering History

- [Continuous Integration Journal](../engineering-journal/continuous-integration/index.md)
- [Continuous Deployment Journal](../engineering-journal/continuous-deployment/index.md)

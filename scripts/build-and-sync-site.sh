#!/usr/bin/env bash
#
# Script untuk membangun dokumentasi MkDocs dan menyinkronkan
# secara aman ke repository deployment devops-handbook-site.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDBOOK_ROOT="$(dirname "${SCRIPT_DIR}")"
DEPLOY_REPO="/home/eddywiyatno/git/devops-handbook-site"
DEPLOY_TARGET="${DEPLOY_REPO}/site"
MKDOCS_BIN="/home/eddywiyatno/venv/mkdocs/bin/mkdocs"

if [[ ! -x "${MKDOCS_BIN}" ]]; then
    echo "ERROR: MkDocs binary tidak ditemukan pada ${MKDOCS_BIN}" >&2
    exit 1
fi

echo "[1/4] Membangun dokumentasi MkDocs..."
"${MKDOCS_BIN}" build --config-file "${HANDBOOK_ROOT}/mkdocs.yml"

echo "[2/4] Menyiapkan target direktori deployment..."
mkdir -p "${DEPLOY_TARGET}"

echo "[3/4] Menyinkronkan artefak ke ${DEPLOY_TARGET}/ ..."
rsync -av --delete "${HANDBOOK_ROOT}/site/" "${DEPLOY_TARGET}/"

echo "[4/4] Mencatat commit dan memastikan web server berjalan..."
if [[ -d "${DEPLOY_REPO}/.git" ]]; then
    git -C "${DEPLOY_REPO}" add site/
    if ! git -C "${DEPLOY_REPO}" diff --cached --quiet; then
        git -C "${DEPLOY_REPO}" commit -m "docs(site): auto-sync handbook build $(date -u +'%Y-%m-%d %H:%M:%SZ')"
    fi
fi

if podman container exists devops-handbook-site; then
    if ! podman ps --filter name=devops-handbook-site --filter status=running --quiet | grep -q .; then
        echo "Starting devops-handbook-site container..."
        podman start devops-handbook-site
    fi
fi

status_code="$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8282 || true)"
if [[ "${status_code}" == "200" ]]; then
    echo "SUCCESS: Handbook site berhasil dibangun dan dapat diakses di http://localhost:8282"
else
    echo "WARNING: HTTP status dari http://localhost:8282 adalah ${status_code}"
fi

#!/usr/bin/env bash
# ============================================================
# brseqtb - Initial pipeline setup
# - Create directory structure
# - Run one-time preparation scripts
# ============================================================

set -euo pipefail

ROOT_DIR="$(pwd)"

echo "[INFO] Initializing brseqtb pipeline in:"
echo "       ${ROOT_DIR}"
echo

# ------------------------------------------------------------
# 1. Create directory structure
# ------------------------------------------------------------
echo "[INFO] Creating directory structure..."

mkdir -p \
    bin \
    database/kaiju/db \
    database/omsCatalog \
    database/mtbRef \
    assets/demo \
    assets/templates \
    assets/tools \
    reads \
    input \
    logs


echo "[OK] Directories created"




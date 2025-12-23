#!/usr/bin/env bash
# ============================================================
# brseqtb - Initial pipeline setup
#
# This script:
#  - Creates the persistent directory structure
#  - Is safe to run multiple times (idempotent)
#  - Intentionally writes outside Nextflow work/
#
# This script is the single source of truth for filesystem
# state during the installation phase.
# ============================================================

set -euo pipefail

ROOT_DIR="$(pwd)"

echo "[INFO] Initializing brseqtb pipeline in:"
echo "       ${ROOT_DIR}"
echo

# ------------------------------------------------------------
# Create directory structure (persistent, user-visible)
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
    results \
    logs

echo "[OK] Directory structure ensured"
echo



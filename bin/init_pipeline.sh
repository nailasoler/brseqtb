#!/usr/bin/env bash
# ============================================================
# brseqtb - Initial pipeline setup
#
# This script prepares the runtime environment only.
# All distributed resources (assets, references, templates)
# are versioned in the Git repository and MUST already exist.
#
# This script is safe to run multiple times (idempotent).
# ============================================================

set -euo pipefail

ROOT_DIR="$(pwd)"

echo "[INFO] Initializing brseqtb runtime environment in:"
echo "       ${ROOT_DIR}"
echo

# ------------------------------------------------------------
# Sanity checks — required versioned resources
# ------------------------------------------------------------
echo "[INFO] Checking required versioned resources..."

required_paths=(
    "database/omsCatalog/WHO-UCN-TB-2023.7-eng.xlsx"
    "database/mtbRef/NC0009623.fasta"
    "database/mtbRef/forbidden_genes.txt"
    "assets/templates/report_template.docx"
    "input/input_table.xlsx"
)

for p in "${required_paths[@]}"; do
    if [[ ! -e "$p" ]]; then
        echo "[ERROR] Required file not found: $p"
        echo "        Did you clone the repository correctly?"
        exit 1
    fi
done

echo "[OK] All required versioned resources found"
echo

# ------------------------------------------------------------
# Create runtime directories (NOT versioned)
# ------------------------------------------------------------
echo "[INFO] Creating runtime directories..."

mkdir -p \
    database/kaiju/db \
    assets/tools \
    reads \
    logs

echo "[OK] Runtime directories ready"
echo

echo "[SUCCESS] brseqtb runtime initialization completed"



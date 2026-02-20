#!/usr/bin/env bash
# ============================================================
# Prepare BWA reference (check + index only)
# Usage: ./bwaref.sh
# Requires: database/mtbRef/NC0009623.fasta
#
# Compatible with Nextflow Conda/Mamba environment
# (uses bwa from PATH)
# ============================================================

set -euo pipefail

REF_DIR="database/mtbRef"
REF="${REF_DIR}/NC0009623.fasta"

# ===================== CHECK REFERENCE =====================
if [[ ! -f "$REF" ]]; then
    echo "[ERROR] Reference genome not found: ${REF}"
    exit 1
fi

# ===================== LOCATE BWA (FROM CONDA ENV) =====================
if ! command -v bwa >/dev/null 2>&1; then
    echo "[ERROR] bwa not found in PATH (Conda environment not active?)"
    exit 1
fi

BWA_BIN="$(which bwa)"

echo "[INFO] Using bwa binary: ${BWA_BIN}"

# ===================== CHECK INDEX =====================
INDEX_FILES=(
    "${REF}.bwt"
    "${REF}.pac"
    "${REF}.ann"
    "${REF}.amb"
    "${REF}.sa"
)

if [[ -f "${INDEX_FILES[0]}" ]]; then
    echo "[OK] BWA index already present for ${REF}"
else
    echo "[INFO] Building BWA index..."
    bwa index "$REF"
    echo "[OK] BWA index created."
fi

echo "[DONE] Reference ready."

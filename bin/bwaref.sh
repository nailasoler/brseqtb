#!/usr/bin/env bash
# ============================================================
# Prepare BWA reference (check + index only)
# Usage: ./bwaref.sh
# Requires: database/mtbRef/NC0009623.fasta
# ============================================================

set -euo pipefail

REF_DIR="database/mtbRef"
REF="${REF_DIR}/NC0009623.fasta"

# ===================== CHECK REFERENCE =====================
if [[ ! -f "$REF" ]]; then
    echo "[ERROR] Reference genome not found: ${REF}"
    echo "[HINT] The reference FASTA must already exist in the project."
    exit 1
fi

# ===================== DEPENDENCY CHECK =====================
if ! command -v bwa >/dev/null 2>&1; then
    echo "[ERROR] bwa not found in PATH."
    exit 1
fi

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
    echo "[INFO] BWA index not found. Building index..."
    bwa index "$REF"
    echo "[OK] BWA index created."
fi

echo "[DONE] Reference is ready for BWA."


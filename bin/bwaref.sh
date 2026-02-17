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
    exit 1
fi

# ===================== BWA ABSOLUTE PATH =====================
BWA="$(pwd)/.micromamba/envs/brseqtb/bin/bwa"

if [[ ! -x "$BWA" ]]; then
    echo "[ERROR] bwa binary not found at: $BWA"
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
    echo "[INFO] Building BWA index..."
    "$BWA" index "$REF"
    echo "[OK] BWA index created."
fi

echo "[DONE] Reference ready."



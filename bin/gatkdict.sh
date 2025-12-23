#!/usr/bin/env bash
# ============================================================
# Prepare reference for GATK (FAI + sequence dictionary)
# Usage: ./gatkdict.sh
# Requires: database/mtbRef/NC0009623.fasta
# ============================================================

set -euo pipefail

REF="database/mtbRef/NC0009623.fasta"
DICT="database/mtbRef/NC0009623.dict"

# ===================== CHECK REFERENCE =====================
if [[ ! -f "$REF" ]]; then
    echo "[ERROR] Reference genome not found: ${REF}"
    exit 1
fi

# ===================== DEPENDENCIES =====================
for cmd in gatk samtools; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd"
        exit 1
    fi
done

# ===================== FASTA INDEX =====================
if [[ ! -f "${REF}.fai" ]]; then
    echo "[INFO] Creating FASTA index (.fai)..."
    samtools faidx "$REF"
else
    echo "[OK] FASTA index already exists."
fi

# ===================== SEQUENCE DICTIONARY =====================
if [[ ! -f "$DICT" ]]; then
    echo "[INFO] Creating sequence dictionary (.dict)..."
    gatk CreateSequenceDictionary \
        -R "$REF" \
        -O "$DICT"
else
    echo "[OK] Sequence dictionary already exists."
fi

echo "[DONE] GATK reference preparation completed."


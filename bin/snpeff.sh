#!/usr/bin/env bash
# ============================================================
# Variant annotation with SnpEff per biosample
# Usage: ./snpeff.sh <biosample>
#
# Uses:
#   - Custom DB: NC_0009623
#   - snpEff.config from micromamba environment
# ============================================================

set -euo pipefail

BIOSAMPLE="${1:-}"

if [[ -z "$BIOSAMPLE" ]]; then
    echo "Usage: ./snpeff.sh <biosample>"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# -------------------- Locate SnpEff --------------------
SNPEFF_JAR=$(ls "${PROJECT_DIR}/.micromamba/envs/brseqtb/share"/snpeff-*/snpEff.jar 2>/dev/null | head -n 1)
SNPEFF_BASE_DIR="$(dirname "$SNPEFF_JAR")"
SNPEFF_CONFIG="${SNPEFF_BASE_DIR}/snpEff.config"

GENOME_DB="NC_0009623"

# Callers obrigatórios (1 VCF por caller)
CALLERS=("gatk" "lofreq" "norm" "delly")

# -------------------- DEPENDENCY CHECKS --------------------
for cmd in java bgzip tabix; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd"
        exit 1
    fi
done

[[ -f "$SNPEFF_JAR" ]] || {
    echo "[ERROR] snpEff.jar not found in micromamba env:"
    echo "        ${PROJECT_DIR}/.micromamba/envs/brseqtb/share/snpeff-*/snpEff.jar"
    exit 1
}

[[ -f "$SNPEFF_CONFIG" ]] || {
    echo "[ERROR] snpEff.config not found:"
    echo "        ${SNPEFF_CONFIG}"
    exit 1
}

OUTPUT_DIR="${PROJECT_DIR}/snpeff/${BIOSAMPLE}"
mkdir -p "$OUTPUT_DIR"

# ============================================================
# STRICT INPUT CHECK — all 4 callers MUST exist
# ============================================================
declare -A CALLER_VCF

for CALLER in "${CALLERS[@]}"; do
    INPUT_DIR="${PROJECT_DIR}/${CALLER}/${BIOSAMPLE}"

    [[ -d "$INPUT_DIR" ]] || {
        echo "[ERROR] Missing caller directory: ${INPUT_DIR}"
        exit 1
    }

    mapfile -t VCF_FILES < <(
        find "$INPUT_DIR" -type f -name "*.vcf.gz" ! -name "*.g.vcf.gz" | sort
    )

    [[ ${#VCF_FILES[@]} -gt 0 ]] || {
        echo "[ERROR] No VCF found for caller '${CALLER}' in ${INPUT_DIR}"
        exit 1
    }

    # Assume 1 VCF por caller (pipeline controlado)
    CALLER_VCF["$CALLER"]="${VCF_FILES[0]}"
done

# ============================================================
# GLOBAL SKIP — only if ALL 4 are already annotated
# ============================================================
ALL_DONE=true

for CALLER in "${CALLERS[@]}"; do
    VCF_FILE="${CALLER_VCF[$CALLER]}"
    VCF_NAME=$(basename "$VCF_FILE")
    ANNOTATED="${OUTPUT_DIR}/${VCF_NAME}"

    if [[ ! -f "$ANNOTATED" || ! -f "${ANNOTATED}.tbi" ]]; then
        ALL_DONE=false
        break
    fi
done

if [[ "$ALL_DONE" == true ]]; then
    echo "[SKIP] All 4 callers already annotated for ${BIOSAMPLE}"
    exit 0
fi

echo "[RUN] Starting SnpEff annotation for biosample: ${BIOSAMPLE}"
echo "[DB]     Using database : ${GENOME_DB}"
echo "[JAR]    Using snpEff   : ${SNPEFF_JAR}"
echo "[CONFIG] Using config   : ${SNPEFF_CONFIG}"
echo "---------------------------------------------"

# ============================================================
# PROCESS — annotate only what is missing
# ============================================================
for CALLER in "${CALLERS[@]}"; do
    VCF_FILE="${CALLER_VCF[$CALLER]}"
    VCF_NAME=$(basename "$VCF_FILE")

    OUTPUT_FILE="${OUTPUT_DIR}/${VCF_NAME}"
    LOG_FILE="${OUTPUT_DIR}/${VCF_NAME%.vcf.gz}_snpeff.log"

    if [[ -f "$OUTPUT_FILE" && -f "${OUTPUT_FILE}.tbi" ]]; then
        echo "[SKIP] Already annotated (${CALLER}): ${VCF_NAME}"
        continue
    fi

    echo "[RUN] Annotating (${CALLER}): ${VCF_NAME}"

    TMP_VCF=$(mktemp --suffix=".vcf")
    gunzip -c "$VCF_FILE" > "$TMP_VCF"

    java -Xmx4g -jar "$SNPEFF_JAR" eff \
        -c "$SNPEFF_CONFIG" \
        -v \
        -ud 100 \
        "$GENOME_DB" \
        "$TMP_VCF" \
        2> "$LOG_FILE" | bgzip -c > "$OUTPUT_FILE"

    tabix -f -p vcf "$OUTPUT_FILE"
    rm -f "$TMP_VCF"

    echo "[OK] Annotated: ${OUTPUT_FILE}"
    echo "---------------------------------------------"
done

echo "[DONE] SnpEff annotation completed for biosample: ${BIOSAMPLE}"
echo "[OUT]  Results in: ${OUTPUT_DIR}/"


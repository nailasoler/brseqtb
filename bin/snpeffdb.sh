#!/usr/bin/env bash
# ============================================================
# Build custom SnpEff database for M. tuberculosis (H37Rv)
# Database ID: NC_0009623
#
# Uses ONLY:
#   - genes.gff
#   - sequences.fa
#
# Explicitly disables CDS / protein validation
# Safe to run multiple times (SKIP if already built)
# ============================================================

set -euo pipefail

START_TIME=$SECONDS
GENOME_DB="NC_0009623"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# -------------------- Locate SnpEff --------------------
SNPEFF_JAR=$(ls "${PROJECT_DIR}/.micromamba/envs/brseqtb/share"/snpeff-*/snpEff.jar 2>/dev/null | head -n 1)
SNPEFF_BASE_DIR="$(dirname "$SNPEFF_JAR")"
SNPEFF_CONFIG="${SNPEFF_BASE_DIR}/snpEff.config"
SNPEFF_DATA_DIR="${SNPEFF_BASE_DIR}/data/${GENOME_DB}"

# -------------------- Reference inputs --------------------
REF_DIR="${PROJECT_DIR}/database/mtbRef"
GFF="${REF_DIR}/genes.gff"
FASTA="${REF_DIR}/sequences.fa"

# -------------------- Checks --------------------
[[ -f "$SNPEFF_JAR" ]]     || { echo "[ERROR] snpEff.jar not found"; exit 1; }
[[ -f "$SNPEFF_CONFIG" ]] || { echo "[ERROR] snpEff.config not found"; exit 1; }
[[ -f "$GFF" ]]           || { echo "[ERROR] genes.gff not found: $GFF"; exit 1; }
[[ -f "$FASTA" ]]         || { echo "[ERROR] sequences.fa not found: $FASTA"; exit 1; }

# -------------------- SKIP IF ALREADY BUILT --------------------
BIN_FILE="${SNPEFF_DATA_DIR}/snpEffectPredictor.bin"

if [[ -f "$BIN_FILE" ]]; then
    echo "[SKIP] SnpEff database already exists for ${GENOME_DB}"
    echo "[OK]   ${BIN_FILE}"
    exit 0
fi

echo "[RUN] Building SnpEff database: ${GENOME_DB}"
echo "[INFO] SnpEff jar : ${SNPEFF_JAR}"
echo "[INFO] Config     : ${SNPEFF_CONFIG}"
echo "[INFO] Data dir   : ${SNPEFF_DATA_DIR}"
echo "---------------------------------------------"

# -------------------- Prepare data directory --------------------
mkdir -p "$SNPEFF_DATA_DIR"

cp -f "$GFF"   "${SNPEFF_DATA_DIR}/genes.gff"
cp -f "$FASTA" "${SNPEFF_DATA_DIR}/sequences.fa"

# -------------------- Register genome --------------------
if ! grep -q "^${GENOME_DB}\.genome" "$SNPEFF_CONFIG"; then
    echo "[INFO] Registering genome in snpEff.config"
    echo "${GENOME_DB}.genome : Mycobacterium_tuberculosis_H37Rv" >> "$SNPEFF_CONFIG"
else
    echo "[INFO] Genome already registered in snpEff.config"
fi

# -------------------- Build database (EXPLICIT CONFIG) --------------------
java -Xmx4g -jar "$SNPEFF_JAR" build \
    -c "$SNPEFF_CONFIG" \
    -gff3 \
    -noCheckCds \
    -noCheckProtein \
    -v "$GENOME_DB"

# -------------------- Validate --------------------
[[ -f "$BIN_FILE" ]] || { echo "[ERROR] Build failed: ${BIN_FILE} not found"; exit 1; }

ELAPSED=$(( SECONDS - START_TIME ))
printf "[DONE] SnpEff DB built for %s (%02d min %02d sec)\n" \
    "$GENOME_DB" $((ELAPSED/60)) $((ELAPSED%60))

echo "[OK]  ${BIN_FILE}"


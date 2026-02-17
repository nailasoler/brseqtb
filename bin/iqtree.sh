#!/usr/bin/env bash
# ============================================================
# Run IQ-TREE 2 for phylogenetic inference from SNP alignment
# Usage: ./iqtree.sh
# Input:  snpMatrix/snpmatrix.fasta
# Output: iqtree/
# ============================================================

set -euo pipefail

# ============================================================
# PARAMETERS
# ============================================================
THREADS="${THREADS:-1}"
MODEL="HKY+I+G"
BOOTSTRAP=1000

# ============================================================
# PROJECT STRUCTURE
# IMPORTANT:
# When executed by Nextflow, cwd = work/<hash>
# So all paths must be resolved from project root
# ============================================================
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INPUT_DIR="${PROJECT_DIR}/snpMatrix"
INPUT_FASTA="${INPUT_DIR}/snpmatrix.fasta"
OUTPUT_DIR="${PROJECT_DIR}/iqtree"

# ============================================================
# Check dependencies and input
# ============================================================
if ! command -v iqtree2 >/dev/null 2>&1; then
    echo "[ERROR] 'iqtree2' not found in PATH."
    exit 1
fi

if [[ ! -f "$INPUT_FASTA" ]]; then
    echo "[ERROR] Input FASTA not found: $INPUT_FASTA"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ============================================================
# Run IQ-TREE
# ============================================================
echo "[RUN] IQ-TREE analysis"
echo "[IN]  Input matrix: $INPUT_FASTA"
echo "[OUT] Output directory: $OUTPUT_DIR"
echo "[SET] Model=$MODEL | Bootstraps=$BOOTSTRAP | Threads=$THREADS"
echo "---------------------------------------------"

iqtree2 \
    -s "$INPUT_FASTA" \
    -m "$MODEL" \
    -B "$BOOTSTRAP" \
    -T "$THREADS" \
    -pre "${OUTPUT_DIR}/snpmatrix" \
    -redo \
    > "${OUTPUT_DIR}/iqtree_run.log" 2>&1

echo "---------------------------------------------"
echo "[OK] IQ-TREE completed successfully."
echo "[OUT] Results saved in: $OUTPUT_DIR"
echo "[LOG] Detailed log: ${OUTPUT_DIR}/iqtree_run.log"
echo "[TREE] Main tree: ${OUTPUT_DIR}/snpmatrix.treefile"
echo "[DONE] Phylogenetic inference completed."


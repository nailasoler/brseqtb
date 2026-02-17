#!/usr/bin/env bash
# ============================================================
# micromamba bootstrap + create environment (LOCAL ONLY)
# Usage: bash bin/micromamba_setup.sh
#
# Guarantees:
#   - micromamba binary inside project (bin/micromamba)
#   - isolated root prefix (.micromamba/)
#   - environment "brseqtb" created from YAML
#
# Does NOT use global micromamba, even if available.
#
# Requires (only for first run):
#   - curl OR wget
#   - tar
#   - bzip2
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Resolve project root
# ------------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ------------------------------------------------------------
# Paths and names (project-local only)
# ------------------------------------------------------------
MICROMAMBA_BIN_LOCAL="${PROJECT_DIR}/bin/micromamba"
MICROMAMBA_ROOT_DIR="${PROJECT_DIR}/.micromamba"
ENV_NAME="brseqtb"
ENV_YAML="${PROJECT_DIR}/envs/brseqtb.yml"

MICROMAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"

# ------------------------------------------------------------
# Prepare directories
# ------------------------------------------------------------
mkdir -p "${PROJECT_DIR}/bin" "${MICROMAMBA_ROOT_DIR}"

# ------------------------------------------------------------
# Force use of LOCAL micromamba
# ------------------------------------------------------------
MICROMAMBA_BIN="${MICROMAMBA_BIN_LOCAL}"

# ------------------------------------------------------------
# Download micromamba if not present locally
# ------------------------------------------------------------
if [[ ! -x "${MICROMAMBA_BIN_LOCAL}" ]]; then
  echo "[MICROMAMBA] micromamba not found locally. Installing to:"
  echo "             ${MICROMAMBA_BIN_LOCAL}"

  # minimal dependency checks
  if ! command -v tar >/dev/null 2>&1; then
    echo "[ERROR] tar not found. Please install tar."
    exit 1
  fi
  if ! command -v bzip2 >/dev/null 2>&1; then
    echo "[ERROR] bzip2 not found. Please install bzip2."
    exit 1
  fi
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "[ERROR] Need curl or wget to download micromamba."
    exit 1
  fi

  TMP_TARBALL="$(mktemp -p "${PROJECT_DIR}/bin" micromamba.XXXXXX.tar.bz2)"

  if command -v curl >/dev/null 2>&1; then
    curl -Ls "${MICROMAMBA_URL}" -o "${TMP_TARBALL}"
  else
    wget -qO "${TMP_TARBALL}" "${MICROMAMBA_URL}"
  fi

  # extract only the binary
  tar -xjf "${TMP_TARBALL}" -C "${PROJECT_DIR}/bin" "bin/micromamba"

  # fix path (avoid bin/bin/micromamba)
  mv -f "${PROJECT_DIR}/bin/bin/micromamba" "${MICROMAMBA_BIN_LOCAL}"
  rmdir "${PROJECT_DIR}/bin/bin" 2>/dev/null || true

  chmod +x "${MICROMAMBA_BIN_LOCAL}"
  rm -f "${TMP_TARBALL}"
fi

# ------------------------------------------------------------
# Configure micromamba root prefix (MANDATORY)
# ------------------------------------------------------------
export MAMBA_ROOT_PREFIX="${MICROMAMBA_ROOT_DIR}"

# ------------------------------------------------------------
# Log environment info
# ------------------------------------------------------------
echo "[MICROMAMBA] micromamba version : $("${MICROMAMBA_BIN}" --version)"
echo "[MICROMAMBA] root prefix        : ${MAMBA_ROOT_PREFIX}"
echo "[MICROMAMBA] env yaml           : ${ENV_YAML}"

# ------------------------------------------------------------
# Validate environment YAML
# ------------------------------------------------------------
if [[ ! -f "${ENV_YAML}" ]]; then
  echo "[ERROR] Missing environment YAML:"
  echo "        ${ENV_YAML}"
  exit 1
fi

# ------------------------------------------------------------
# Create or update environment (idempotent)
# ------------------------------------------------------------
if "${MICROMAMBA_BIN}" env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  echo "[MICROMAMBA] Environment exists: ${ENV_NAME} — reusing (no update)"
else
  echo "[MICROMAMBA] Creating environment: ${ENV_NAME}"
  "${MICROMAMBA_BIN}" create -n "${ENV_NAME}" -f "${ENV_YAML}" -y
fi

echo "[MICROMAMBA] Done."


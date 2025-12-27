#!/usr/bin/env bash
# ============================================================
# micromamba bootstrap + create/update environment
# Usage: bash bin/micromamba_setup.sh
# Creates:
#   - bin/micromamba (if missing)
#   - .micromamba/ (root prefix)
#   - env: brseqtb
# Requires:
#   - curl OR wget (only for downloading micromamba)
#   - tar, bzip2 (to extract micromamba tar.bz2)
# ============================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MICROMAMBA_BIN_LOCAL="${PROJECT_DIR}/bin/micromamba"
MICROMAMBA_ROOT_DIR="${PROJECT_DIR}/.micromamba"
ENV_NAME="brseqtb"
ENV_YAML="${PROJECT_DIR}/envs/brseqtb.yml"

# This URL returns a tar.bz2 that contains bin/micromamba
MICROMAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"

mkdir -p "${PROJECT_DIR}/bin" "${MICROMAMBA_ROOT_DIR}"

# pick micromamba
if command -v micromamba >/dev/null 2>&1; then
  MICROMAMBA_BIN="$(command -v micromamba)"
else
  MICROMAMBA_BIN="${MICROMAMBA_BIN_LOCAL}"
fi

# download+extract micromamba if needed (local bin missing or not executable)
if [[ "${MICROMAMBA_BIN}" == "${MICROMAMBA_BIN_LOCAL}" && ! -x "${MICROMAMBA_BIN_LOCAL}" ]]; then
  echo "[MICROMAMBA] micromamba not found. Downloading+extracting to: ${MICROMAMBA_BIN_LOCAL}"

  if ! command -v tar >/dev/null 2>&1; then
    echo "[ERROR] tar not found. Please install tar."
    exit 1
  fi
  if ! command -v bzip2 >/dev/null 2>&1; then
    echo "[ERROR] bzip2 not found. Please install bzip2."
    exit 1
  fi

  TMP_TARBALL="$(mktemp -p "${PROJECT_DIR}/bin" micromamba.XXXXXX.tar.bz2)"

  if command -v curl >/dev/null 2>&1; then
    curl -Ls "${MICROMAMBA_URL}" -o "${TMP_TARBALL}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${TMP_TARBALL}" "${MICROMAMBA_URL}"
  else
    echo "[ERROR] Need curl or wget to download micromamba."
    exit 1
  fi

  # Extract only bin/micromamba from the tarball into project bin/
  tar -xjf "${TMP_TARBALL}" -C "${PROJECT_DIR}/bin" "bin/micromamba"

  # Move to desired path (avoid bin/bin/micromamba nesting)
  mv -f "${PROJECT_DIR}/bin/bin/micromamba" "${MICROMAMBA_BIN_LOCAL}"
  rmdir "${PROJECT_DIR}/bin/bin" 2>/dev/null || true

  chmod +x "${MICROMAMBA_BIN_LOCAL}"
  rm -f "${TMP_TARBALL}"

  MICROMAMBA_BIN="${MICROMAMBA_BIN_LOCAL}"
fi

# micromamba expects this variable name
export MAMBA_ROOT_PREFIX="${MICROMAMBA_ROOT_DIR}"

echo "[MICROMAMBA] micromamba: $("${MICROMAMBA_BIN}" --version)"
echo "[MICROMAMBA] root prefix: ${MAMBA_ROOT_PREFIX}"
echo "[MICROMAMBA] env yaml: ${ENV_YAML}"

if [[ ! -f "${ENV_YAML}" ]]; then
  echo "[ERROR] Missing env yaml: ${ENV_YAML}"
  exit 1
fi

# create/update environment
if "${MICROMAMBA_BIN}" env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  echo "[MICROMAMBA] Environment exists: ${ENV_NAME} -> updating"
  "${MICROMAMBA_BIN}" env update -n "${ENV_NAME}" -f "${ENV_YAML}" -y
else
  echo "[MICROMAMBA] Creating environment: ${ENV_NAME}"
  "${MICROMAMBA_BIN}" create -n "${ENV_NAME}" -f "${ENV_YAML}" -y
fi

echo "[MICROMAMBA] Done."


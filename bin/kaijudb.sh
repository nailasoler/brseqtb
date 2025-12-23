#!/usr/bin/env bash
# ============================================================
# Prepare Kaiju database (download, extract, verify)
#
# Usage:
#   ./kaijudb.sh               -> automatic mode (download if needed)
#   ./kaijudb.sh true          -> manual mode (use existing archive)
#
# Expected archive location (manual or automatic):
#   database/kaiju/kaiju_mycobacterium.tar.gz
#
# Output:
#   database/kaiju/db/
# ============================================================

set -euo pipefail

ADD_MANUAL="${1:-false}"

DB_DIR="database/kaiju/db"
DB_TAR="database/kaiju/kaiju_mycobacterium.tar.gz"
ZENODO_URL="https://zenodo.org/records/17554952/files/kaiju_mycobacterium.tar.gz"

EXPECTED_SHA256="e74e76382f189ec87abd294000f17a044d367f971b665807f2b7e5ce7cc795e2"

mkdir -p "$DB_DIR"
mkdir -p "$(dirname "$DB_TAR")"

# ------------------ VERIFY DATABASE -------------------------
verify_database() {
    echo "[DB] Verifying Kaiju database integrity..."

    local required=("nodes.dmp" "names.dmp")
    local fmi_file

    fmi_file=$(find "$DB_DIR" -maxdepth 1 -name "*.fmi" | head -n 1 || true)

    for f in "${required[@]}"; do
        [[ -s "${DB_DIR}/${f}" ]] || {
            echo "[DB] Missing ${f}"
            return 1
        }
    done

    [[ -n "${fmi_file:-}" && -s "$fmi_file" ]] || {
        echo "[DB] Missing FMI index"
        return 1
    }

    head -c 8 "$fmi_file" >/dev/null 2>&1 || {
        echo "[DB] FMI appears corrupted"
        return 1
    }

    echo "[DB] Database OK."
    return 0
}

# ------------------ VERIFY ARCHIVE --------------------------
verify_archive() {
    [[ -f "$DB_TAR" && -s "$DB_TAR" ]] || {
        echo "[DB] Archive missing: $DB_TAR"
        return 1
    }

    echo "[DB] Verifying archive checksum..."

    local sha
    sha=$(sha256sum "$DB_TAR" | awk '{print $1}')

    [[ "$sha" == "$EXPECTED_SHA256" ]] || {
        echo "[DB] Checksum mismatch"
        echo "     Expected: $EXPECTED_SHA256"
        echo "     Found:    $sha"
        return 1
    }

    echo "[DB] Archive checksum OK."
    return 0
}

# ------------------ DOWNLOAD DATABASE -----------------------
download_database() {
    echo "[DB] Downloading Kaiju DB from Zenodo..."

    if command -v wget >/dev/null; then
        wget -O "$DB_TAR" "$ZENODO_URL"
    else
        curl -L -o "$DB_TAR" "$ZENODO_URL"
    fi
}

# ------------------ EXTRACT DATABASE ------------------------
extract_database() {
    echo "[DB] Extracting Kaiju DB..."

    rm -rf "${DB_DIR:?}"/*

    tar --strip-components=5 -xzf "$DB_TAR" -C "$DB_DIR" 2>/dev/null || \
    tar --strip-components=4 -xzf "$DB_TAR" -C "$DB_DIR" 2>/dev/null || \
    tar -xzf "$DB_TAR" -C "$DB_DIR"
    
    # Remove temporary extraction artifacts
    rm -rf "${DB_DIR}/_tmp"

    echo "[DB] Extraction complete."
}

# ---------------------- MAIN --------------------------------
echo "[DB] Checking Kaiju database..."

if verify_database; then
    echo "[DB] Database already prepared. Skipping."
    exit 0
fi

if [[ "$ADD_MANUAL" == "true" ]]; then
    echo "[DB] Manual mode enabled."

    if ! verify_archive; then
        echo "[DB] Manual archive not found or invalid."
        echo "     Expected at: $DB_TAR"
        exit 1
    fi
else
    if ! verify_archive; then
        rm -f "$DB_TAR"
        download_database
        verify_archive || {
            echo "[DB] Archive verification failed after download."
            exit 1
        }
    fi
fi

extract_database
verify_database || {
    echo "[DB] Database preparation failed."
    exit 1
}

echo "[DB] Kaiju database ready:"
ls -lh "$DB_DIR"


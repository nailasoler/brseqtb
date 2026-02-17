#!/usr/bin/env python3

# ============================================================
# TB Resistance Final Report Generator
#
# Usage:
#   python3 resistanceReport.py <biosample ID>
#
# Input:
#   resistance/<biosample ID>/<biosample ID>_OMStarget.xlsx
#       → merged variant list from all callers (GATK, NORM, LOFREQ, DELLY)
#         including PASS/FAIL, AF, zygosity, annotation, and OMS catalog matches
#
# Output:
#   results/resistance/<biosample ID>.xlsx
#       → Final deduplicated and curated resistance report
#
# Rules:
#   1. Keep both PASS/FAIL variants.
#   2. Remove decomposed SNPs inside the span of a MNP
#         (e.g. CA→TG vs C→T and A→G after vt norm).
#   3. If multiple variants overlap a position:
#         - If any is HET → keep all.
#         - If MNP vs SNP → keep MNP, remove SNP.
#   4. Caller priority for duplicates:
#         GATK > NORM > LOFREQ > DELLY
#   5. Evidence values converted to:
#         R / r / u / s / S
#
# ============================================================

import sys
import pandas as pd
from pathlib import Path

# ============================================================
# PROJECT STRUCTURE (projectDir-aware)
# ============================================================
PROJECT_DIR = Path(__file__).resolve().parent.parent

INPUT_DIR  = PROJECT_DIR / "resistance"
OUTPUT_DIR = PROJECT_DIR / "results" / "resistance"

CALLER_PRIORITY = ["GATK", "NORM", "LOFREQ", "DELLY"]

FINAL_COLUMNS = [
    "Drug","Gene","Tier","Variant","Effect","Evidence","Comment",
    "AF","ALT_READS","Heteroresistance","Caller",
    "Filter_Status","Filter_Method"
]

EVIDENCE_MAP = {
    "Assoc w R": "R",
    "Assoc w R - Interim": "r",
    "Uncertain significance": "u",
    "Not assoc w R - Interim": "s",
    "Not assoc w R": "S"
}

# ============================================================
# HELPERS
# ============================================================
def convert_evidence(raw):
    if not isinstance(raw, str):
        return "S"
    if ") " in raw:
        raw = raw.split(") ", 1)[1].strip()
    return EVIDENCE_MAP.get(raw, "S")

def choose_best_caller(group):
    for caller in CALLER_PRIORITY:
        sel = group[group["caller"] == caller]
        if not sel.empty:
            return sel.iloc[0]
    return group.iloc[0]

def is_mnp(ref, alt):
    return len(str(ref)) > 1 or len(str(alt)) > 1

# ============================================================
# MNP RESOLUTION LOGIC
# ============================================================
def resolve_mnp_span(df):

    to_remove = set()
    mnp_rows = df[df.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1)]

    for idx, mnp in mnp_rows.iterrows():
        start = mnp["position"]
        end   = start + len(str(mnp["ref"])) - 1
        mnp_het = (mnp["zygosity"] == "HET")

        snps = df[
            (df["position"] >= start) &
            (df["position"] <= end) &
            (~df.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1))
        ]

        if snps.empty:
            continue

        if not mnp_het and not any(snps["zygosity"] == "HET"):
            to_remove.update(snps.index)
        elif mnp_het:
            to_remove.update(snps.index)

    return df.drop(index=to_remove)

def resolve_mnp_vs_snp(df):
    out = []
    for pos, group in df.groupby("position"):
        if any(group["zygosity"] == "HET"):
            out.append(group)
            continue

        mnp = group[group.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1)]
        snp = group[~group.index.isin(mnp.index)]

        if not mnp.empty and not snp.empty:
            out.append(mnp)
        else:
            out.append(group)

    return pd.concat(out, ignore_index=True)

# ============================================================
# CORE PROCESS
# ============================================================
def process_biosample(biosample):

    input_xlsx  = INPUT_DIR / biosample / f"{biosample}_OMStarget.xlsx"
    output_xlsx = OUTPUT_DIR / f"{biosample}.xlsx"

    # ===================== SKIP =====================
    if output_xlsx.exists():
        print(f"[SKIP] Final resistance report already exists → {output_xlsx}")
        return

    # ===================== FAIL FAST =====================
    if not input_xlsx.exists():
        print(f"[ERROR] Required input not found: {input_xlsx}")
        sys.exit(1)

    print(f"[RUN] Generating resistance report for {biosample}")
    df = pd.read_excel(input_xlsx)

    if df.empty:
        print(f"[ERROR] OMStarget is empty: {input_xlsx}")
        sys.exit(1)

    # ===================== CLEANING =====================
    df = resolve_mnp_span(df)
    df = resolve_mnp_vs_snp(df)

    # ===================== COLUMN MAPPING =====================
    df["Drug"]  = df["drug"].astype(str)
    df["Gene"]  = df["gene"].astype(str)
    df["Tier"]  = df["tier"]
    df["Variant"] = df["master_change"]
    df["Effect"]  = df["effect"]
    df["Evidence"] = df["FINAL CONFIDENCE GRADING"].apply(convert_evidence)
    df["Comment"]  = df["Comment"]
    df["AF"]       = df["AF"]
    df["ALT_READS"] = df["ALT_reads"]
    df["Heteroresistance"] = df["zygosity"]
    df["Caller"]   = df["caller"]
    df["Filter_Status"] = df["Filter_Status"]
    df["Filter_Method"] = df["Filter_Method"]

    # ===================== DEDUPLICATION =====================
    final_rows = []
    for _, group in df.groupby(["Drug", "Variant"]):
        final_rows.append(choose_best_caller(group))

    final = pd.DataFrame(final_rows)[FINAL_COLUMNS]

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    final.to_excel(output_xlsx, index=False)

    print(f"[OK] Final resistance report written → {output_xlsx}")

# ============================================================
def main():
    if len(sys.argv) != 2:
        print("Usage: python3 resistanceReport.py <biosample>")
        sys.exit(1)

    process_biosample(sys.argv[1])

if __name__ == "__main__":
    main()



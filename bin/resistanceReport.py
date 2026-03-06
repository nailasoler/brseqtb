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

import os
import pandas as pd

INPUT_DIR = "resistance"
OUTPUT_DIR = "results/resistance"

CALLER_PRIORITY = ["GATK", "NORM", "LOFREQ", "DELLY"]

FINAL_COLUMNS = [
    "Drug","Gene","Tier","Variant","Effect","Evidence","Comment",
    "AF","ALT_READS","Heteroresistance","Caller","Filter_Status","Filter_Method"
]

patterns = {
    "Assoc w R": "R",
    "Assoc w R - Interim": "r",
    "Uncertain significance": "u",
    "Not assoc w R - Interim": "s",
    "Not assoc w R": "S"
}

def convert_evidence(raw):
    if not isinstance(raw, str):
        return "S"
    if ") " in raw:
        raw = raw.split(") ", 1)[1].strip()
    return patterns.get(raw, "S")

def load_OMStarget(path):
    if not os.path.exists(path):
        return None
    return pd.read_excel(path)

def choose_best_caller(group):
    for caller in CALLER_PRIORITY:
        sel = group[group["caller"] == caller]
        if not sel.empty:
            return sel.iloc[0]
    return group.iloc[0]

def is_mnp(ref, alt):
    return len(str(ref)) > 1 or len(str(alt)) > 1

def resolve_mnp_span(df):

    to_keep = set()
    to_remove = set()

    #mnp_rows = df[df.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1)]
    mnp_rows = df[(df["ref"].str.len() > 1) | (df["alt"].str.len() > 1)]

    for mnp_idx, mnp in mnp_rows.iterrows():
        mnp_start = mnp["position"]
        mnp_end = mnp["position"] + len(str(mnp["ref"])) - 1
        mnp_is_het = (mnp["zygosity"] == "HET")

        snps = df[
            (df["position"] >= mnp_start) &
            (df["position"] <= mnp_end) &
            ~((df["ref"].str.len() > 1) | (df["alt"].str.len() > 1))
            #(~df.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1))
        ]

        if snps.empty:
            to_keep.add(mnp_idx)
            continue

        snps_het = snps[snps["zygosity"] == "HET"]
        snps_hom = snps[snps["zygosity"] == "HOM"]

        if not mnp_is_het and not snps_hom.empty and snps_het.empty:
            to_keep.add(mnp_idx)
            to_remove.update(snps.index)

        elif mnp_is_het and not snps_hom.empty and snps_het.empty:
            to_keep.add(mnp_idx)
            to_remove.update(snps.index)

        elif not mnp_is_het and not snps_het.empty and snps_hom.empty:
            to_keep.add(mnp_idx)
            to_keep.update(snps_het.index)
            to_remove.update(snps_hom.index)

        elif mnp_is_het and not snps_het.empty:
            to_keep.add(mnp_idx)
            to_remove.update(snps.index)

        else:
            to_keep.add(mnp_idx)
            if not mnp_is_het:
                to_keep.update(snps_het.index)
            to_remove.update(snps_hom.index)

    final_idx = set(df.index) - to_remove
    return df.loc[sorted(final_idx)].copy()

def resolve_mnp_vs_snp(df):
    result = []
    for pos, group in df.groupby("position"):
        if any(group["zygosity"] == "HET"):
            result.append(group)
            continue

        #mnp_mask = group.apply(lambda r: is_mnp(r["ref"], r["alt"]), axis=1)
        mnp_mask = (group["ref"].str.len() > 1) | (group["alt"].str.len() > 1)
        snp_mask = ~mnp_mask

        if mnp_mask.any() and snp_mask.any():
            result.append(group[mnp_mask])
        else:
            result.append(group)

    return pd.concat(result, ignore_index=True)

def process_biosample(biosample):

    path = os.path.join(INPUT_DIR, biosample, f"{biosample}_OMStarget.xlsx")
    df = load_OMStarget(path)
    if df is None or df.empty:
        print(f"[WARN] No OMStarget for {biosample}")
        return

    if df.empty:
        print(f"[WARN] No variants for {biosample}")
        return

    df = resolve_mnp_span(df)
    df = resolve_mnp_vs_snp(df)

    df["Drug"] = df["drug"].astype(str)
    df["Gene"] = df["gene"].astype(str)
    df["Tier"] = df["tier"]


    # --------------------------------------------------------
    # Normalize NA
    # --------------------------------------------------------
    df[["aa_change","master_change","nt_change"]] = df[
        ["aa_change","master_change","nt_change"]
    ].fillna("NA")

    # --------------------------------------------------------
    # Variant priority
    # aa_change > master_change > nt_change
    # --------------------------------------------------------
    df["Variant"] = df["aa_change"]

    mask = df["Variant"] == "NA"
    df.loc[mask, "Variant"] = df.loc[mask, "master_change"]

    mask = df["Variant"] == "NA"
    df.loc[mask, "Variant"] = df.loc[mask, "nt_change"]

    df["Effect"] = df["effect"]
    df["Evidence"] = df["FINAL CONFIDENCE GRADING"].apply(convert_evidence)
    df["Comment"] = df["Comment"]
    df["AF"] = df["AF"]
    df["ALT_READS"] = df["ALT_reads"]
    df["Heteroresistance"] = df["zygosity"]
    df["Caller"] = df["caller"]
    df["Filter_Status"] = df["Filter_Status"]
    df["Filter_Method"] = df["Filter_Method"]

    final_rows = []
    for _, group in df.groupby(["Drug", "Gene", "Variant"], dropna=False):
        best = choose_best_caller(group)
        final_rows.append(best)

    final = pd.DataFrame(final_rows)[FINAL_COLUMNS]

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    outfile = os.path.join(OUTPUT_DIR, f"{biosample}.xlsx")
    final.to_excel(outfile, index=False)

    print(f"[OK] {outfile}")

def main():

    import sys
    if len(sys.argv) != 2:
        print("Usage: python3 resistanceReport.py <biosample>")
        return

    biosample = sys.argv[1]
    process_biosample(biosample)

if __name__ == "__main__":
    main()



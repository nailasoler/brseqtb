#!/usr/bin/env python3

# ============================================================
# TB Resistance Profiling from VCFs (GATK / norm / LoFreq / Delly)
# Usage: python3 resistanceTarget.py <biosample ID>
# Input:  snpeff/<biosample ID>/<biosample ID>_{gatk,norm,lofreq,delly}.vcf.gz
# Output: resistance/<biosample ID>/*_{caller}_{ANN,target}.xlsx
# Reference: database/omsCatalog/tbdr_genomic_coordinates.csv + tbdr_catalogue_master_file.csv
# ============================================================


import pandas as pd
import pysam
import os
import sys

REFERENCE_NAME = "NC_000962.3"
CATALOG_DIR = "database/omsCatalog"
CATALOG_GENOMIC_COORDS = os.path.join(CATALOG_DIR, "tbdr_genomic_coordinates.csv")
CATALOG_MASTER = os.path.join(CATALOG_DIR, "tbdr_catalogue_master_file.csv")
FILTER_EXCEL = "cohort/filter/filter.xlsx"
SNPEFF_BASE = "snpeff"
RESULTS_BASE = "resistance"

VCF_CALLERS = {
    "gatk": "_gatk.vcf.gz",
    "norm": "_norm.vcf.gz",
    "lofreq": "_lofreq.vcf.gz",
    "delly": "_delly.vcf.gz"
}

# ============================================================
# ANNOTATION
# ============================================================

def recover_annotation(vcf_file, caller):
    vcf = pysam.VariantFile(vcf_file)
    annotations = []

    is_delly = caller == "delly"
    is_lofreq = caller == "lofreq"
    is_gatk = caller in ("gatk","norm")

    for record in vcf:
        position = record.pos
        ref = record.ref
        alt_alleles = record.alts or []

        AF_list = []
        ALT_reads_list = []
        TOTAL_depth = None
        zygosity_list = []

        # --------- DELLY ---------
        if is_delly:
            AF_list = [None] * len(alt_alleles)
            ALT_reads_list = [None] * len(alt_alleles)
            TOTAL_depth = None
            zygosity_list = ["NA"] * len(alt_alleles)

        # --------- GATK / NORM -----
        elif is_gatk:
            sample_name = list(vcf.header.samples)[0]
            fmt = record.samples[sample_name]
            AD = fmt.get("AD", None)
            DP = fmt.get("DP", None)

            if AD and len(AD) >= 1:
                REF_reads = AD[0]
                ALT_reads_list = AD[1:]
                TOTAL_depth = sum(AD)

                AF_list = [
                    (ar / TOTAL_depth if TOTAL_depth > 0 else None)
                    for ar in ALT_reads_list
                ]

                zygosity_list = [
                    ("HOM" if af is not None and af >= 0.90 else "HET")
                    if af is not None else "NA"
                    for af in AF_list
                ]
            else:
                TOTAL_depth = DP
                ALT_reads_list = [None] * len(alt_alleles)
                AF_list = [None] * len(alt_alleles)
                zygosity_list = ["NA"] * len(alt_alleles)

        # --------- LOFREQ ----------
        elif is_lofreq:
            dp4 = record.info.get("DP4", None)
            if dp4 and len(dp4) == 4:
                REF_reads = dp4[0] + dp4[1]
                ALT_reads = dp4[2] + dp4[3]
                TOTAL_depth = REF_reads + ALT_reads
                ALT_reads_list = [ALT_reads]
                af = ALT_reads / TOTAL_depth if TOTAL_depth > 0 else None
                AF_list = [af]
                zygosity_list = ["HOM" if af and af >= 0.90 else "HET"]
            else:
                TOTAL_depth = record.info.get("DP", None)
                ALT_reads_list = [None] * len(alt_alleles)
                AF_list = [None] * len(alt_alleles)
                zygosity_list = ["NA"] * len(alt_alleles)

        # ============================================================
        # ANN parsing
        # ============================================================
        ann_list_raw = record.info.get("ANN", [])
        ann_by_alt = {alt: [] for alt in alt_alleles}

        for ann in ann_list_raw:
            fields = ann.split("|")
            ann_alt = fields[0]
            if ann_alt in ann_by_alt:
                ann_by_alt[ann_alt].append(fields)

        parsed_ann = []
        for alt in alt_alleles:
            entries = ann_by_alt.get(alt, [])
            if not entries:
                parsed_ann.append(("NA","NA"))
                continue

            selected = None
            for f in entries:
                if f[3] or f[9] or f[10]:
                    selected = f
                    break

            if not selected:
                parsed_ann.append(("NA","NA"))
                continue

            gene = selected[3] if selected[3] else "NA"
            genic = selected[9] if selected[9] else "NA"
            prot = selected[10] if selected[10] else "NA"

            nt = f"{gene}_{genic}" if genic != "NA" else "NA"
            aa = f"{gene}_{prot}" if prot != "NA" else "NA"

            parsed_ann.append((nt, aa))

        # ============================================================
        # OUTPUT ROWS
        # ============================================================
        for i, alt in enumerate(alt_alleles):
            nt, aa = parsed_ann[i]
            af = AF_list[i] if i < len(AF_list) else None
            ar = ALT_reads_list[i] if i < len(ALT_reads_list) else None
            zy = zygosity_list[i] if i < len(zygosity_list) else "NA"

            annotations.append([
                position, ref, alt, nt, aa,
                zy, af, ar, TOTAL_depth
            ])

    return pd.DataFrame(annotations, columns=[
        "position","ref","alt","nt_change","aa_change",
        "zygosity","AF","ALT_reads","TOTAL_depth"
    ])

# ============================================================
# NORMALIZATION
# ============================================================

def normalize_ann(df):
    df["ref"] = df["ref"].str.upper().str.strip()
    df["alt"] = df["alt"].str.upper().str.strip()
    df["position"] = df["position"].astype(int)
    return df

def normalize_catalog(df):
    df["position"] = df["position"].astype(float).astype(int)
    df["reference_nucleotide"] = df["reference_nucleotide"].str.upper().str.strip()
    df["alternative_nucleotide"] = df["alternative_nucleotide"].str.upper().str.strip()
    return df

# ============================================================
# MATCHING
# ============================================================

def matching(df_ann, coord_file_path, master_file_path):
    coord_file = normalize_catalog(pd.read_csv(coord_file_path))
    master = pd.read_csv(master_file_path)
    df_ann = normalize_ann(df_ann)

    coord_match = df_ann.merge(
        coord_file[["position","reference_nucleotide","alternative_nucleotide","variant"]],
        left_on=["position","ref","alt"],
        right_on=["position","reference_nucleotide","alternative_nucleotide"],
        how="left"
    ).rename(columns={"variant":"master_change"})

    coord_match = coord_match.merge(
        master,
        left_on="master_change",
        right_on="variant",
        how="left"
    )
    coord_match["match_method"] = None
    coord_match.loc[coord_match["drug"].notna(),"match_method"] = "coord"

    nt_match = df_ann.merge(master, left_on="nt_change", right_on="variant", how="left")
    nt_match["match_method"] = None
    nt_match.loc[
        nt_match["drug"].notna(),
        "match_method"
    ] = "nt_change"

    aa_match = df_ann.merge(master, left_on="aa_change", right_on="variant", how="left")
    aa_match["match_method"] = None
    aa_match.loc[
        aa_match["drug"].notna(),
        "match_method"
    ] = "aa_change"

    final = pd.concat([
        coord_match[coord_match["match_method"]=="coord"],
        nt_match[nt_match["match_method"]=="nt_change"],
        aa_match[aa_match["match_method"]=="aa_change"]
    ])

    final["master_change"] = final["master_change"].fillna("NA")

    final = final.dropna(subset=[
        "drug","variant","tier","effect","FINAL CONFIDENCE GRADING"
    ])

    return final[[
        "position","ref","alt","nt_change","aa_change","zygosity",
        "AF","ALT_reads","TOTAL_depth",
        "drug","variant","gene","tier","effect",
        "FINAL CONFIDENCE GRADING","Comment",
        "master_change","match_method"
    ]]

# ============================================================
# FILTER HELPERS
# ============================================================

def gatk_norm_failures(record):
    failures = []
    DP = record.info.get("DP") or record.samples[0].get("DP") or 0
    QUAL = record.qual if record.qual else 0
    QD = QUAL / DP if DP > 0 else 0
    if DP < 10: failures.append("DP_FAIL")
    if QUAL < 30: failures.append("QUAL_FAIL")
    if QD < 2: failures.append("QD_FAIL")
    return failures

def lofreq_failures(AF, ALT_reads, DP, QUAL):
    failures = []
    if DP is None or DP < 10: failures.append("DP_FAIL")
    if AF is None or AF < 0.05: failures.append("AF_FAIL")
    if ALT_reads is None or ALT_reads < 3: failures.append("ALT_FAIL")
    if QUAL is None or QUAL < 30: failures.append("QUAL_FAIL")
    return failures

def delly_failures(record):
    failures = []
    if record.filter.keys() != {"PASS"}:
        failures.append("FILTER_FAIL")
    MAPQ = record.info.get("MAPQ", 0)
    if MAPQ < 20:
        failures.append("MAPQ_FAIL")
    return failures

def get_cohort_filter(filter_df, pos):
    row = filter_df[filter_df["POS"] == pos]
    if row.empty:
        return None
    return row.iloc[0]["FILTER"]

# ============================================================
# FILTERING
# ============================================================

def filtering(df_res, filter_excel, vcf_path):
    filter_df = pd.read_excel(filter_excel)
    vcf = pysam.VariantFile(vcf_path)

    final_status = []
    final_method = []

    caller = None
    for c, suf in VCF_CALLERS.items():
        if vcf_path.endswith(suf):
            caller = c
            break

    for _, row in df_res.iterrows():
        pos = row["position"]
        alt = row["alt"]

        cohort_val = None
        if caller in ("gatk","norm"):
            cohort_val = get_cohort_filter(filter_df, pos)

        if caller in ("gatk","norm") and cohort_val == "PASS":
            final_status.append("PASS")
            final_method.append("COHORT")
            continue

        record = None
        for r in vcf.fetch(REFERENCE_NAME, pos-1, pos):
            if r.pos == pos and alt in (r.alts or []):
                record = r
                break

        # ===== TEST DP =====
        #if record is not None:
        #    DP_test = record.info.get("DP") or record.samples[0].get("DP") or 0
        #    print(f"DEBUG DP TEST pos={pos} alt={alt} DP={DP_test}")
        #    print("INFO_DP:", record.info.get("DP"), "FORMAT_DP:", record.samples[0].get("DP"))
        # ====================

        if record is None:
            fail = "NO_RECORD"
            if cohort_val and cohort_val not in ("PASS",None):
                final_status.append(f"{cohort_val};{fail}")
                final_method.append("COHORT+PER_SAMPLE")
            else:
                final_status.append(fail)
                final_method.append("PER_SAMPLE")
            continue

        if caller in ("gatk","norm"):
            per_sample_fails = gatk_norm_failures(record)
        elif caller == "lofreq":
            per_sample_fails = lofreq_failures(
                AF=row.get("AF"),
                ALT_reads=row.get("ALT_reads"),
                DP=row.get("TOTAL_depth"),
                QUAL=record.qual
            )
        elif caller == "delly":
            per_sample_fails = delly_failures(record)
        else:
            per_sample_fails = ["UNKNOWN_CALLER"]

        if (not per_sample_fails) and (caller not in ("gatk","norm") or cohort_val not in ("PASS",None)):
            final_status.append("PASS")
            final_method.append("PER_SAMPLE")
            continue

        if caller in ("gatk","norm") and cohort_val not in ("PASS",None) and per_sample_fails:
            combined = [cohort_val] + per_sample_fails
            final_status.append(";".join(combined))
            final_method.append("COHORT+PER_SAMPLE")
            continue

        if per_sample_fails:
            final_status.append(";".join(per_sample_fails))
            final_method.append("PER_SAMPLE")
            continue

        final_status.append("PASS")
        final_method.append("PER_SAMPLE")

    df_res["Filter_Status"] = final_status
    df_res["Filter_Method"] = final_method
    return df_res

# ============================================================
# PROCESS ONE VCF — returns the target output
# ============================================================

def process_one_vcf(biosample, vcf_path):

    caller = os.path.basename(vcf_path).replace(f"{biosample}_","").replace(".vcf.gz","")
    results_dir = os.path.join(RESULTS_BASE, biosample)
    os.makedirs(results_dir, exist_ok=True)

    ann_out = os.path.join(results_dir, f"{biosample}_{caller}_ANN.xlsx")

    print(f"[RUN] Profiling caller: {caller}")
    print(f"   VCF   : {vcf_path}")
    print(f"   ANN   : {ann_out}")
    print("---------------------------------------------")

    df_ann = recover_annotation(vcf_path, caller)
    df_ann.to_excel(ann_out, index=False)   # ANN is kept per caller

    df_match = matching(df_ann, CATALOG_GENOMIC_COORDS, CATALOG_MASTER)
    df_final = filtering(df_match, FILTER_EXCEL, vcf_path)

    df_final["caller"] = caller.upper()

    print(f"[OK] Completed caller: {caller}\n")

    return df_final


# ============================================================
# MAIN — GENERATE THE SINGLE FINAL TARGET FILE
# ============================================================

def main():

    if len(sys.argv) != 2:
        print("Usage: python3 resistanceProfile.py <biosample>")
        sys.exit(1)

    biosample = sys.argv[1]
    sample_dir = os.path.join(SNPEFF_BASE, biosample)

    print(f"[INFO] Scanning VCFs in {sample_dir}")

    merged_targets = []

    for caller, suffix in VCF_CALLERS.items():
        vcf_path = os.path.join(sample_dir, f"{biosample}{suffix}")
        if os.path.exists(vcf_path):
            df_target = process_one_vcf(biosample, vcf_path)
            merged_targets.append(df_target)
        else:
            print(f"[SKIP] {caller}: {vcf_path} not found")

    # ============================================================
    # GENERATE THE SINGLE COMBINED TARGET
    # ============================================================
    if merged_targets:
        final_df = pd.concat(merged_targets, ignore_index=True)

        results_dir = os.path.join(RESULTS_BASE, biosample)
        os.makedirs(results_dir, exist_ok=True)

        final_target_path = os.path.join(results_dir, f"{biosample}_OMStarget.xlsx")
        final_df.to_excel(final_target_path, index=False)

        print(f"[OK] Combined OMStarget saved → {final_target_path}")

    print("[DONE] All callers processed.")


if __name__ == "__main__":
    main()


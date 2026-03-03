# BrSeqTB — A pipeline for antimicrobial resistance inference from Mycobacterium tuberculosis WGS

**BrSeqTB** is a fully modular Nextflow DSL2 pipeline designed for comprehensive Mycobacterium tuberculosis whole-genome sequencing (WGS) analysis. Starting from Illumina paired-end FASTQ files, it produces analysis-ready outputs through an end-to-end workflow that includes:

- **Quality control and reporting**
- **Taxonomic contamination screening (Kaiju)**
- **Reference alignment (BWA-MEM)**
- **Multi-caller variant detection (GATK HaplotypeCaller, LoFreq, Delly)**
- **Variant functional annotation (SnpEff)**
- **Drug-resistance prediction based on the WHO catalogue**
- **Mixed infection inference**
- **Phylogenetic reconstruction and transmission network inference**
- **Variant summary (per sample and cohort-level)**
- **Clinical report**

BrSeqTB supports scalable execution (local, HPC, or cloud), environment isolation via Conda, and modular execution of individual workflow components. The pipeline generates standardized, clinically interpretable outputs, including integrated QC reports, resistance summaries, and cohort-level analyses — enabling robust genomic surveillance and research applications in tuberculosis.

## BrSeqTB Workflow DAG

```
INITIALIZATION
 ├─ KAIJU_DB
 ├─ OMS_CATALOG
 ├─ BWA_REF
 ├─ GATK_DICT
 └─ SNPEFF_DB
        ↓
MAKE_MANIFEST_VALIDATE
        ↓
SAMPLES (fan-out per biosample)

BLOCK 1 — PER BIOSAMPLE

SAMPLE
 ├─ FASTQC
 └─ TRIMMOMATIC
       ├─ KAIJU
       └─ BWA
            ├─ DELLY
            ├─ LOFREQ
            ├─ GATK_GVCF ── TBDR_RCOV
            ├─ GATK_VCF ── NORM ── LINEAGE
            ├─ LOFREQ + GATK_GVCF ── NTM_FILTER
            └─ LOFREQ + GATK_GVCF + GATK_VCF + NORM ── SNPEFF

BLOCK 2 — COHORT LEVEL

COHORT
   ↓
COHORT_FILTER
   ↓
SNP_MATRIX
   ├─ TRANSMISSION
   └─ IQTREE

BLOCK 3 — PER BIOSAMPLE

SAMPLE
 ├─ MIX_INFECTION
 ├─ RESISTANCE_TARGET
 │      ↓
 │  RESISTANCE_REPORT

BLOCK 4 — GLOBAL REPORTS

 ├─ RESISTANCE_SUMMARY
 └─ QC_SUMMARY

FINAL — PER BIOSAMPLE

SAMPLE
 └─ CLINICAL_REPORT

```

# BrSeqTB — Installation and Execution Guide

## Requirements

- **Java (OpenJDK 17)**
- **Nextflow (≥ 25.10.2)**
- **Micromamba** (used by Nextflow to create environments)

Linux or macOS is recommended.

---

# Installation

## 1️⃣ Install Java (OpenJDK 17)

Java is required to run Nextflow.

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install openjdk-17-jdk -y
```

### macOS (Homebrew)

```bash
brew install openjdk@17
```

Verify installation:

```bash
java -version
```

You should see version 17.

---

## 2️⃣ Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

Verify installation:

```bash
nextflow -version
```

---

---

## 3️⃣ Install Conda (Miniconda Recommended)

BrSeqTB uses **Conda** to automatically create the software environment defined in:

```
envs/brseqtb.yml
```

We recommend installing **Miniconda**, a lightweight Conda distribution.

### Install Miniconda

Download and install:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### During Installation

When running the Miniconda installer:

- Accept the license agreement
- Accept the default installation path (`~/miniconda3`)
- When prompted:

  ```
  Proceed with initialization? [yes|no]
  ```

  Type **`yes`**.

  This step is important because it ensures that `conda` is added to your shell environment and is available to Nextflow.


Restart your terminal or run:

```bash
source ~/.bashrc
```

At this point, Conda is correctly configured and available system-wide.

---

### (Optional) Disable Automatic Base Activation

By default, Conda activates the `base` environment every time you open a new terminal.

If you prefer not to auto-activate `base`, run:

```bash
conda config --set auto_activate_base false
```

Then reload your shell:

```bash
source ~/.bashrc
```

This keeps Conda available to Nextflow while preventing automatic activation of the `base` environment.

---

### Verify Installation

```bash
which conda
conda --version
```

You should see the path to `miniconda3` and a Conda version number.

---

## ⚠ Important — Accept Conda Terms of Service

Recent versions of Conda require accepting the Anaconda channel Terms of Service before creating environments in non-interactive mode (such as when running Nextflow).

If you do not accept these terms, environment creation may fail.

Run the following commands **once per machine**:

```bash
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
```

This step enables automated environment creation by Nextflow.

---

## 4️⃣ Clone the Repository

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

## Running



---


---

## Profiles Summary

| Profile  | Intended Use             | CPU Strategy         |
| -------- | ------------------------ | -------------------- |
| standard | Local laptop/workstation | Auto-scaled (~65%)   |
| hpc      | Cluster environments     | Scheduler-controlled |


## Running on HPC (Scheduler-Driven)


## Environment Creation

On first execution, Nextflow will automatically create the Conda environment defined in `envs/brseqtb.yml`. The environment will be stored in `~/.nextflow_conda_cache/`. Subsequent runs will reuse the cached environment.


## Optional: Clean Environment and Work Directory

If needed:

```bash
nextflow clean -f
rm -rf ~/.nextflow_conda_cache
rm -rf work
```

Then rerun:

```bash
nextflow run main.nf
```


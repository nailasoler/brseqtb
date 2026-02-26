# brseqtb

**brseqtb** is a modular Nextflow pipeline for *Mycobacterium tuberculosis* whole-genome sequencing analysis, with a clear separation between:

- **One-time environment preparation (INIT stage)**
- **Per-sample analytical workflows**

The pipeline is designed to be:

- Modular  
- Idempotent  
- Reproducible  
- Suitable for local workstations or HPC environments  

---

## Table of Contents

- Overview  
- Requirements  
- Installation  
- One-Time Setup Modules (Block 1)  
- Running the Full Pipeline  
- Selective Module Execution  
- Parameters  
- Output Structure  
- Idempotency and Reproducibility  
- Cleaning the Work Directory  
- License  

---

## Overview

The initialization stage of **brseqtb** prepares all shared resources required by the pipeline, including:

- Kaiju taxonomic database  
- WHO TB Drug Resistance Catalogue processing  
- Reference genome indexing for BWA  
- Reference preparation for GATK  
- Custom SnpEff database  
- Manifest generation and FASTQ validation  

All setup steps are **idempotent** and safe to run multiple times.

---

## Requirements

The following tools must be installed:

- **Nextflow** (≥ 24.x recommended)
- **Conda** or **Micromamba**

Linux or macOS is recommended.

---

## Installation

### 1️⃣ Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

Verify installation:

```bash
nextflow -version
```

---

### 2️⃣ Install Conda (Miniconda)

Download and install Miniconda:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

Restart your shell and verify:

```bash
conda --version
```

---

### Alternative: Install Micromamba (lightweight option)

```bash
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/
```

---

### 3️⃣ Clone the repository

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

---

## One-Time Setup Modules (Block 1)

The initialization chain prepares:

* Kaiju DB
* OMS Catalogue
* BWA index
* GATK reference files
* SnpEff DB
* `manifest.tsv`

Run:

```bash
nextflow run main.nf -resume
```

This will:

1. Prepare all databases
2. Validate `input_table.xlsx`
3. Validate FASTQ naming
4. Generate `manifest.tsv`

You only need to rerun this if:

* You change the reference
* You update the OMS catalogue
* You modify `input_table.xlsx`
* You change FASTQs

---

## Running the Full Pipeline

To execute the complete analysis:

```bash
nextflow run main.nf -resume
```

The pipeline will:

* Perform preprocessing
* Run alignment
* Call variants
* Annotate variants
* Generate resistance reports
* Build phylogeny
* Produce final clinical outputs

---

## Selective Module Execution

You can run specific modules using `--run`.

Example:

Run only BWA and LOFREQ:

```bash
nextflow run main.nf --run bwa,lofreq -resume
```

Run only LOFREQ using manually provided BAM files:

```bash
nextflow run main.nf \
  --run lofreq \
  --input_bams results/bwa \
  -resume
```

If `--input_bams` is provided, BWA will be skipped and LOFREQ will use those BAM files directly.

---

## Parameters

Common parameters:

| Parameter              | Description                                     |
| ---------------------- | ----------------------------------------------- |
| `--run`                | Comma-separated list of modules to execute      |
| `--add_kaiju_manually` | Skip Kaiju download (use existing archive)      |
| `--input_table`        | Path to `input_table.xlsx`                      |
| `--reads_dir`          | Directory containing FASTQ files                |
| `--input_bams`         | Directory containing BAMs for modular execution |

Example:

```bash
nextflow run main.nf \
  --reads_dir custom_reads \
  --input_table custom_input.xlsx \
  -resume
```

---

## Output Structure

```
project/
│
├── work/                 # Nextflow temporary working directory
├── results/              # Published analysis outputs
├── database/             # Prepared reference data
├── manifest.tsv
├── logs/
│   ├── trace.txt
│   ├── timeline.html
│   ├── report.html
│   └── dag.html
```

All analysis outputs are copied to `results/`.

The `work/` directory contains intermediate files and can be safely deleted after completion if not resuming.

---

## Idempotency and Reproducibility

All initialization scripts:

* Verify file integrity
* Skip execution if outputs already exist
* Validate checksums when applicable
* Stop execution on error

The pipeline uses:

* Declarative Nextflow channels
* Controlled resource management
* Reproducible Conda environments

---

## Cleaning the Work Directory

After a successful run:

```bash
rm -rf work/
```

This does **not** remove final results (they are stored in `results/`).

To force re-execution:

```bash
nextflow run main.nf -resume false
```

---

## License

This project is released under the MIT License.

```
```


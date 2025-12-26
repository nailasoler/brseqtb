# brseqtb

**brseqtb** is a modular Nextflow pipeline for *Mycobacterium tuberculosis* whole-genome sequencing analysis, with a clear separation between **one-time environment preparation** and **per-sample analytical workflows**.

This repository currently implements the **initial setup stage**, responsible for preparing reference data, databases, and auxiliary files required by downstream analysis modules.

---

## Table of Contents

- Overview  
- Requirements  
- Installation  
- One-Time Setup Modules  
- Running the Pipeline  
- Selective Module Execution  
- Parameters  
- Output Structure  
- Notes on Idempotency  
- License  

---

## Overview

The initialization stage of **brseqtb** prepares all shared resources required by the pipeline, including:

- Directory structure  
- Kaiju taxonomic database  
- WHO TB Drug Resistance Catalogue processing  
- Reference genome indexing for BWA  
- Reference preparation for GATK  

All setup steps are **idempotent** and safe to run multiple times.

---

## Requirements

The following tools must be available in the environment:

- **Nextflow** (≥ 24.x)  
- **Java** (for GATK)  
- **Python 3** with:
  - pandas  
  - numpy  
- **bwa**  
- **samtools**  
- **gatk**  

> Tool installation is intentionally left to the user or environment (local, HPC, container).

---

## Installation

Clone the repository:

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

## One-Time Setup Modules

The following modules do not depend on biosamples and are designed to run once per project.  
All modules are idempotent and can be safely re-executed if needed.

- **init_pipeline.sh**  
  Creates the runtime directory structure and validates the presence of versioned reference files.  
  This is always the first step of the pipeline.

- **kaijudb**  
  Prepares the Kaiju Mycobacterium database.  
  By default, the database is downloaded automatically from Zenodo, verified by checksum, and extracted.  
  A manual mode is available for offline or HPC environments.

- **omsCatalog**  
  Processes the WHO TB Drug Resistance Catalogue Excel file and generates derived BED and CSV files used by downstream analyses.  
  If all expected output files already exist, execution is skipped.

- **bwaref**  
  Prepares the reference genome for BWA by building the required index files if they are missing.

- **gatkdict**  
  Prepares the reference genome for GATK by creating the FASTA index (.fai) and the sequence dictionary (.dict) if they are missing.

---

## Running the Pipeline

### Full initialization (default)

Running the pipeline without additional parameters executes all setup modules in the correct order:

```bash
nextflow run main.nf
```

## Pipeline Parameters

The initialization stage of **brseqtb** can be executed fully or partially using command-line parameters.  
All parameters are optional unless explicitly stated.

### Module Selection Parameters

These parameters control which setup modules are executed.

- **--run_init**  
  Runs the `init_pipeline` module.  
  This module creates the runtime directory structure and validates versioned resources.  
  Default: true

- **--run_kaijudb**  
  Runs the `kaijudb` module to prepare the Kaiju Mycobacterium database.  
  Default: true

- **--run_omsCatalog**  
  Runs the OMS TB Drug Resistance Catalogue processing module.  
  Default: true

- **--run_bwaref**  
  Runs the BWA reference preparation module (BWA index creation).  
  Default: true

- **--run_gatkdict**  
  Runs the GATK reference preparation module (FASTA index and sequence dictionary).  
  Default: true

Any module can be disabled by explicitly setting its parameter to `false`.

---

### Kaiju Database Parameters

- **--add_kaiju_manually**  
  Controls how the Kaiju database is prepared.

  - false (default):  
    The Kaiju database is downloaded automatically from Zenodo, verified by checksum, and extracted.

  - true:  
    Indicates that the user has manually placed the Kaiju database archive or files in the expected directory.  
    The pipeline will validate and extract the database without attempting a download.

---

### Examples

Run all initialization modules (default behavior):

```bash
nextflow run main.nf
```

Run only the initial directory setup:

```bash
nextflow run main.nf --run init
```

Run only the Kaiju database preparation (automatic download):

```bash
nextflow run main.nf --run kaiju
```

Run only the Kaiju database preparation using a manually provided database:

```bash
nextflow run main.nf --run kaiju --add_kaiju_manually true
```

Run only the OMS TB Drug Resistance Catalogue processing:

```bash
nextflow run main.nf --run oms
```

Run only reference preparation for BWA:

```bash
nextflow run main.nf --run bwaref
```

Run only reference preparation for GATK:

```bash
nextflow run main.nf --run gatkdict
```

Run multiple modules in a custom combination:

```bash
nextflow run main.nf --run init,oms,bwaref
```

Run reference-related modules only (BWA + GATK):

```bash
nextflow run main.nf --run bwaref,gatkdict
```

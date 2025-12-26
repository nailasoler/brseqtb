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

- **kaijudb.sh**  
  Prepares the Kaiju Mycobacterium database.  
  By default, the database is downloaded automatically from Zenodo, verified by checksum, and extracted.  
  A manual mode is available for offline or HPC environments.

- **omsCatalog.py**  
  Processes the WHO TB Drug Resistance Catalogue Excel file and generates derived BED and CSV files used by downstream analyses.  
  If all expected output files already exist, execution is skipped.

- **bwaref.sh**  
  Prepares the reference genome for BWA by building the required index files if they are missing.

- **gatkdict.sh**  
  Prepares the reference genome for GATK by creating the FASTA index (.fai) and the sequence dictionary (.dict) if they are missing.

---

## Running the Pipeline

### Full initialization (default)

Running the pipeline without additional parameters executes all setup modules in the correct order:

```bash
nextflow run main.nf


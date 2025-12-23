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

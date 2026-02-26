# brseqtb

**brseqtb** is a modular Nextflow pipeline for *Mycobacterium tuberculosis* whole-genome sequencing analysis, with a clear separation between:

- **One-time environment preparation (INIT stage)**
- **Per-sample analytical workflows**

# brseqtb — Installation and Execution Guide

## Requirements

The following tools must be installed:

- **Nextflow** (≥ 24.x recommended)  
- **Conda (Miniconda)**  

Linux or macOS is recommended.

---

# Installation

## 1️⃣ Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

Verify installation:

```bash
nextflow -version
```

---

## 2️⃣ Install Miniconda

Download and install Miniconda:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

During installation:

- Accept the default installation path (`~/miniconda3`)
- You may choose **not** to auto-activate the base environment

---

If you answered "yes" to `conda init` during installation,
you do NOT need to run `conda init` again.

If you answered "no" to `conda init` during installation, follow the steps below. 

### Initialize Conda (Required for Nextflow)

Nextflow runs in non-interactive shells.  
To ensure `conda` is available system-wide, initialize it:

```bash
conda init
```

Then reload your shell:

```bash
source ~/.bashrc
```

If you prefer **not** to auto-activate the base environment at terminal startup:

```bash
conda config --set auto_activate_base false
```

Verify installation:

```bash
which conda
conda --version
```

---

### ⚠ Important — Accept Conda Terms of Service

Recent versions of Conda require accepting the Anaconda channel Terms of Service before creating environments in non-interactive mode (e.g., when running Nextflow).

Run the following commands **once per machine**:

```bash
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
```

This step is required to allow automated environment creation by Nextflow.

---

## 3️⃣ Clone the repository

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

---

````markdown
# Running brseqtb (Default: Auto-Scaled Local)

Run the pipeline:

```bash
nextflow run main.nf
````

By default, brseqtb uses the `standard` profile, which automatically detects available CPUs, uses approximately 65% of the machine capacity, balances threads per process and parallel samples, and prevents system overload on laptops and workstations. No profile specification is required for local execution.

## Running on HPC (Scheduler-Driven)

To run on an HPC cluster (e.g., SLURM):

```bash
nextflow run main.nf -profile hpc
```

The `hpc` profile does not auto-detect CPU percentage, fully respects scheduler resource allocation, uses declared `cpus` and `memory` per process, and follows best practices for cluster environments. You may need to adjust the executor (e.g., `slurm`, `pbs`, etc.) in `nextflow.config` to match your HPC system.

## Environment Creation (First Run)

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

## Profiles Summary

| Profile  | Intended Use             | CPU Strategy         |
| -------- | ------------------------ | -------------------- |
| standard | Local laptop/workstation | Auto-scaled (~65%)   |
| hpc      | Cluster environments     | Scheduler-controlled |

## Notes

The pipeline is idempotent. Databases and indexes are not rebuilt if already present. Environments are cached under `~/.nextflow_conda_cache/`. Logs are generated under `logs/`. Outputs are published in the project root and module-specific directories. Resource allocation scales automatically in local mode. HPC execution strictly respects scheduler resource allocation.


---

This setup uses **only Conda** as the environment manager and matches the current `nextflow.config`.


# Notes

- The pipeline is idempotent.
- Databases and indexes are not rebuilt if already present.
- Environments are cached under `work/conda/`.
- Logs are generated under `logs/`.
- Outputs are published in the project root and module-specific directories.

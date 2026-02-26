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

# Running brseqtb (Conda Default)

Run the pipeline:

```bash
nextflow run main.nf
```

On first execution:

- Nextflow will automatically create the environment defined in:

```
envs/brseqtb.yml
```

- The environment will be stored in:

```
~/.nextflow_conda_cache/
```

Subsequent runs will reuse the cached environment.

---

## Optional: Clean environment and work directory

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

---

This setup uses **only Conda** as the environment manager and matches the current `nextflow.config`.


# Notes

- The pipeline is idempotent.
- Databases and indexes are not rebuilt if already present.
- Environments are cached under `work/conda/`.
- Logs are generated under `logs/`.
- Outputs are published in the project root and module-specific directories.

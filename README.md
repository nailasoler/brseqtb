# brseqtb

**brseqtb** is a modular Nextflow pipeline for *Mycobacterium tuberculosis* whole-genome sequencing analysis, with a clear separation between:

- **One-time environment preparation (INIT stage)**
- **Per-sample analytical workflows**


## Requirements

The following tools must be installed:

- **Nextflow** (≥ 24.x recommended)
- **Conda** or **Micromamba**

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

## 2️⃣ Install Miniconda (required – default environment manager)

Download and install Miniconda:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

After installation, restart your terminal or run:

```bash
source ~/.bashrc
```

Verify:

```bash
conda --version
```

---

## 3️⃣ (Optional) Install micromamba (faster alternative)

Micromamba is lighter and significantly faster than conda.

```bash
curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/
```

Verify:

```bash
micromamba --version
```

### ⚠ Important (Nextflow compatibility)

Nextflow calls the binary `mamba` when `useMamba = true`.

To allow Nextflow to use micromamba, create a compatibility link:

```bash
sudo ln -s $(which micromamba) /usr/local/bin/mamba
```

Verify:

```bash
which mamba
mamba --version
```

This does **not** replace micromamba.  
It only allows Nextflow to call it correctly.

---

## 4️⃣ Clone the repository

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

---

# Running brseqtb

## ▶ Default execution (Conda)

Conda is the default environment manager.

```bash
nextflow run main.nf
```

On first execution, the environment will be created automatically from:

```
envs/brseqtb.yml
```

---

## ⚡ Optional execution with micromamba

If micromamba is installed and linked as described above:

```bash
nextflow run main.nf -profile micromamba
```

Micromamba significantly reduces environment creation time.

---

# Notes

- The pipeline is idempotent.
- Databases and indexes are not rebuilt if already present.
- Environments are cached under `work/conda/`.
- Logs are generated under `logs/`.
- Outputs are published in the project root and module-specific directories.

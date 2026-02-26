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

## Installation

### 1️⃣ Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

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

## 🚀 Running brseqtb

### 1️⃣ Clone the repository

```bash
git clone https://github.com/nailasoler/brseqtb.git
cd brseqtb
```

---

### 2️⃣ Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
nextflow -version
```

---

### 3️⃣ Install micromamba (recommended)

Micromamba is faster and lighter than conda.

```bash
# Linux x86_64
curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/
micromamba --version
```

---

### 4️⃣ Run the pipeline (default: micromamba)

```bash
nextflow run main.nf
```

On first execution, the environment will be created automatically from:

```
envs/brseqtb.yml
```

---

### 🔁 Optional: Run using Conda instead of micromamba

If you prefer traditional Conda:

```bash
nextflow run main.nf -profile conda_profile
```

Make sure Conda is installed:

```bash
conda --version
```

---

### 📌 Re-running

The pipeline is fully idempotent:

- Existing databases are not rebuilt  
- Reference indexes are reused  
- `manifest.tsv` is regenerated only after successful validation  
- Nextflow cache avoids re-running completed steps  

Outputs are published in the project root and module-specific directories.

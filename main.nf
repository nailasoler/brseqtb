nextflow.enable.dsl = 2

/*
 * ============================================================
 * Parameters
 * ============================================================
 */

/*
 * ----------------------------
 * EXECUTION CONTROL
 * ----------------------------
 */
params.run                = null      // lista de módulos a executar (ex: bwa,lofreq)
params.add_kaiju_manually = false     // kaiju DB já existe localmente
params.cohort_demo        = false     // modo demo para cohort


/*
 * ============================================================
 * BLOCK 2 — PREPROCESS (fan-out per biosample)
 * ============================================================
 */
params.fastqc_cpus        = 1
params.trimmomatic_cpus   = 1
params.bwa_cpus           = 1
params.kaiju_cpus         = 1


/*
 * ============================================================
 * BLOCK 3 — VARIANT CALLING (fan-out per biosample)
 * ============================================================
 */
params.lofreq_cpus        = 1
params.gatk_gvcf_cpus     = 1
params.gatk_vcf_cpus      = 1
params.norm_cpus          = 1
params.delly_cpus         = 1


/*
 * ============================================================
 * BLOCK 4 — ANNOTATION + COHORT
 * ============================================================
 */
params.snpeff_cpus        = 1
params.tbdrRcov_cpus      = 1
params.ntmfilter_cpus     = 1

params.cohort_cpus        = 1          // roda uma vez (fan-in)
params.cohort_filter_cpus = 1          // roda uma vez


/*
 * ============================================================
 * BLOCK 5 — PHYLOGENY / TRANSMISSION
 * ============================================================
 */
params.lineage_cpus       = 1
params.snp_matrix_cpus    = 1          // fan-in
params.mixinfection_cpus = 1
params.transmission_cpus = 1           // fan-in
params.iqtree_cpus        = 1           // fan-in pesado


/*
 * ============================================================
 * BLOCK 6 — RESISTANCE (fan-out per biosample)
 * ============================================================
 */
params.resistance_target_cpus = 1
params.resistance_report_cpus = 1


/*
 * ============================================================
 * BLOCK 7 — FINAL REPORTS
 * ============================================================
 */
params.resistance_summary_cpus = 1      // fan-in
params.qc_summary_cpus         = 1      // fan-in
params.clinical_report_cpus   = 1       // fan-out



/*
 * ============================================================
 * BLOCK 1 - INIT CHAIN — ALWAYS RUN ONCE (CACHED)
 * ============================================================
 */

process KAIJU_DB {
    tag "kaiju-db"
    input: val token
    output: val true
    script:
    """
    cd "${projectDir}"
    bash bin/kaijudb.sh ${params.add_kaiju_manually}
    """
}

process OMS_CATALOG {
    tag "oms-catalog"
    input: val token
    output: val true
    script:
    """
    cd "${projectDir}"
    python bin/omsCatalog.py
    """
}

process BWA_REF {
    tag "bwa-ref"
    input: val token
    output: val true
    script:
    """
    cd "${projectDir}"
    bash bin/bwaref.sh
    """
}

process GATK_DICT {
    tag "gatk-dict"
    input: val token
    output: val true
    script:
    """
    cd "${projectDir}"
    bash bin/gatkdict.sh
    """
}

process SNPEFF_DB {
    tag "snpeff-db"
    input: val token
    output: val true
    script:
    """
    cd "${projectDir}"
    bash bin/snpeffdb.sh
    """
}

process MAKE_MANIFEST_VALIDATE {

    input:
        val token
        path input_table
        path reads_dir

    output:
        path "manifest.tsv"

    script:
    """
    python ${projectDir}/bin/make_manifest_validate.py \
        --xlsx ${input_table} \
        --reads ${reads_dir} \
        --out manifest.tsv

    # COPIA PARA PROJECTDIR (igual aos outros scripts)
    cp manifest.tsv ${projectDir}/manifest.tsv
    """
}



/*
 * ============================================================
 * BLOCK 2 - CACHED
 * ============================================================
 */

process FASTQC {
    tag { biosample }
    cpus { params.fastqc_cpus }

    input:
        tuple val(biosample), val(token)

    output:
        tuple val(biosample), path("fastqc/${biosample}")

    script:
    """
    bash ${projectDir}/bin/fastqc.sh "${biosample}"
    mkdir -p fastqc
    cp -r ${projectDir}/fastqc/${biosample} fastqc/
    """
}

process TRIMMOMATIC {
    tag { biosample }
    cpus { params.trimmomatic_cpus }

    input:
        tuple val(biosample), val(token)

    output:
        tuple val(biosample), path("trimmomatic/${biosample}")

    script:
    """
    bash ${projectDir}/bin/trimmomatic.sh "${biosample}"
    mkdir -p trimmomatic
    cp -r ${projectDir}/trimmomatic/${biosample} trimmomatic/
    """
}

process BWA {
    tag { biosample }
    cpus { params.bwa_cpus }

    input:
        tuple val(biosample), path(trim_dir)

    output:
        tuple val(biosample), path("bwa/${biosample}")
        path "bwa/${biosample}/${biosample}_bwa_summary.csv"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/bwa.sh "${biosample}"
    mkdir -p bwa
    cp -r ${projectDir}/bwa/${biosample} bwa/
    """
}

process KAIJU {
    tag { biosample }
    cpus { params.kaiju_cpus }

    input:
        tuple val(biosample), path(trim_dir)

    output:
        path "kaiju/${biosample}"
        path "kaiju/${biosample}/${biosample}_kaiju_summary.csv"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/kaiju.sh "${biosample}"
    mkdir -p kaiju
    cp -r ${projectDir}/kaiju/${biosample} kaiju/
    """
}

/*
 * ============================================================
 * Block 3
 * ============================================================
 */

process DELLY {
    tag { biosample }
    cpus { params.delly_cpus }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        path "delly/${biosample}"
        path "delly/${biosample}/${biosample}_delly.vcf.gz"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/delly.sh "${biosample}"
    mkdir -p delly
    cp -r ${projectDir}/delly/${biosample} delly/
    """
}

process LOFREQ {
    tag { biosample }
    cpus { params.lofreq_cpus }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        path "lofreq/${biosample}"
        path "lofreq/${biosample}/${biosample}_lofreq.vcf.gz"

    script:
    """
    bash ${projectDir}/bin/lofreq.sh "${biosample}"
    mkdir -p lofreq
    cp -r ${projectDir}/lofreq/${biosample} lofreq/
    """
}

process GATK_GVCF {
    tag { biosample }
    cpus { params.gatk_gvcf_cpus }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        path "gatk/${biosample}"
        path "gatk/${biosample}/${biosample}.g.vcf.gz"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/gatkGvcf.sh "${biosample}"
    mkdir -p gatk
    cp -r ${projectDir}/gatk/${biosample} gatk/
    """
}

process GATK_VCF {
    tag { biosample }
    cpus { params.gatk_vcf_cpus }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        path "gatk/${biosample}"
        path "gatk/${biosample}/${biosample}_gatk.vcf.gz"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/gatkVcf.sh "${biosample}"
    mkdir -p gatk
    cp -r ${projectDir}/gatk/${biosample} gatk/
    """
}

process NORM {
    tag { gatk_dir.baseName }

    input:
        path gatk_dir
        path vcf_file

    output:
        path "norm/${gatk_dir.baseName}"

    script:
    """
    BIOSAMPLE=\$(basename "${gatk_dir}")
    bash ${projectDir}/bin/norm.sh "\${BIOSAMPLE}"
    mkdir -p norm
    cp -r ${projectDir}/norm/\${BIOSAMPLE} norm/
    """
}

/*
 * ============================================================
 * Block 4
 * ============================================================
 */
 
process SNPEFF {
    tag { biosample }
    cpus { params.snpeff_cpus }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        path "snpeff/${biosample}"

    script:
    """
    bash ${projectDir}/bin/snpeff.sh "${biosample}"
    mkdir -p snpeff
    cp -r ${projectDir}/snpeff/${biosample} snpeff/
    """
}

process TBDR_RCOV {
    tag { biosample }
    cpus { params.tbdr_rcov_cpus ?: 1 }

    input:
        val biosample

    output:
        path "tbdrRCov/${biosample}"

    script:
    """
    python ${projectDir}/bin/tbdrRCov.py "${biosample}"

    mkdir -p tbdrRCov
    cp -r ${projectDir}/tbdrRCov/${biosample} tbdrRCov/
    """
}


process NTM_FILTER {
    tag { biosample }
    cpus { params.ntm_filter_cpus ?: 1 }

    input:
        val biosample

    output:
        path "ntmFilter/${biosample}"

    script:
    """
    bash ${projectDir}/bin/ntmFilter.sh "${biosample}"

    mkdir -p ntmFilter
    cp -r ${projectDir}/ntmFilter/${biosample} ntmFilter/
    """
}


process LINEAGE {
    tag { biosample }

    input:
        val biosample

    output:
        path "lineage/${biosample}"

    script:
    """
    python ${projectDir}/bin/lineage.py "${biosample}"

    mkdir -p lineage
    cp -r ${projectDir}/lineage/${biosample} lineage/
    """
}


process COHORT {
    tag "cohort"

    input:
        val trigger

    output:
        path "cohort"

    script:
    """
    DEMO_FLAG=""
    if ${params.cohort_demo}; then DEMO_FLAG="--demo"; fi

    bash ${projectDir}/bin/cohort.sh ${projectDir}/manifest.tsv \$DEMO_FLAG

    mkdir -p cohort
    cp -r ${projectDir}/cohort/* cohort/ || true
    """
}


process COHORT_FILTER {
    tag "cohort-filter"

    input:
        path cohort_dir

    output:
        path "cohort_filtered"

    script:
    """
    python ${projectDir}/bin/cohortFilter.py

    mkdir -p cohort_filtered
    cp -r ${projectDir}/cohort_filtered/* cohort_filtered/ || true
    """
}

/*
 * ============================================================
 * Block 5 — PHYLOGENY / TRANSMISSION
 * ============================================================
 */

/*
 * SNP_MATRIX
 * - Roda UMA vez (coorte)
 * - Gera snpMatrix + mixInfection base
 */
process SNP_MATRIX {
    tag "snp-matrix"

    input:
        val trigger

    output:
        val true

    script:
    """
    python ${projectDir}/bin/snpMatrix.py
    """
}

/*
 * TRANSMISSION
 * - Roda UMA vez (coorte)
 * - OBRIGATORIAMENTE após SNP_MATRIX
 */
process TRANSMISSION {
    tag "transmission"

    input:
        val trigger

    output:
        path "transmission"

    script:
    """
    python ${projectDir}/bin/transmission.py

    mkdir -p transmission
    cp -r ${projectDir}/transmission/* transmission/ || true
    """
}


/*
 * IQTREE
 * - Roda UMA vez (coorte)
 * - OBRIGATORIAMENTE após SNP_MATRIX
 */
process IQTREE {
    tag "iqtree"
    cpus { params.iqtree_cpus }

    input:
        val trigger

    output:
        path "iqtree"

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/iqtree.sh

    mkdir -p iqtree
    cp -r ${projectDir}/iqtree/* iqtree/ || true
    """
}

/*
 * ============================================================
 * Block 6 — Reports
 * ============================================================
 */

process MIXINFECTION {
    tag { biosample }

    input:
        val biosample

    output:
        path "mixInfection/${biosample}"

    script:
    """
    python ${projectDir}/bin/mixInfection.py ${biosample}

    mkdir -p mixInfection/${biosample}
    cp -r ${projectDir}/mixInfection/${biosample}/* mixInfection/${biosample}/ || true
    """
}

process RESISTANCE_TARGET {
    tag { biosample }
    cpus { params.resistance_target_cpus }

    input:
        val biosample

    output:
        path "${biosample}_OMStarget.xlsx"

    script:
    """
    python ${projectDir}/bin/resistanceTarget.py "${biosample}"

    cp ${projectDir}/resistance/${biosample}/${biosample}_OMStarget.xlsx .
    """
}



process RESISTANCE_REPORT {
    tag { omstarget.baseName }
    cpus { params.resistance_report_cpus }

    input:
        path omstarget

    output:
        path "${omstarget.baseName}.xlsx"

    script:
    """
    BIOSAMPLE=\$(basename "${omstarget}" _OMStarget.xlsx)

    python ${projectDir}/bin/resistanceReport.py "\$BIOSAMPLE"

    cp ${projectDir}/results/resistance/\$BIOSAMPLE.xlsx .
    """
}

/*
 * ============================================================
 * Block 7 — Summary
 * ============================================================
 */

process RESISTANCE_SUMMARY {

    tag "resistance-summary"

    input:
    val token

    output:
    val true

    script:
    """
    python ${projectDir}/bin/resistanceSummary.py
    """
}

process QC_SUMMARY {

    tag "qc-summary"

    input:
    val token

    output:
    val true

    script:
    """
    python ${projectDir}/bin/qcSummary.py
    """
}


/*
 * ============================================================
 * Block 8 — Clinical Report
 * ============================================================
 */

process CLINICAL_REPORT {

    tag { biosample }

    input:
    val biosample

    output:
    path "clinicalReport/${biosample}.docx"

    script:
    """
    python ${projectDir}/bin/clinicalReport.py ${biosample}

    mkdir -p clinicalReport
    cp ${projectDir}/results/clinicalReport/${biosample}.docx clinicalReport/
    """
}

/*
 * ============================================================
 * WORKFLOW — DEFINITIVO
 * ============================================================
 */

workflow {

    /*
     * ========================================================
     * BLOCO 1 — INIT (RUN ONCE)
     * ========================================================
     */

    def ch_init = Channel.value(true)

    ch_init = KAIJU_DB(ch_init)
    ch_init = OMS_CATALOG(ch_init)
    ch_init = BWA_REF(ch_init)
    ch_init = GATK_DICT(ch_init)
    ch_init = SNPEFF_DB(ch_init)

    def ch_input_table = Channel.fromPath("${projectDir}/input/input_table.xlsx")
    def ch_reads_dir   = Channel.fromPath("${projectDir}/reads")

    def ch_manifest = MAKE_MANIFEST_VALIDATE(
        ch_init,
        ch_input_table,
        ch_reads_dir
    )

    /*
     * ========================================================
     * EXTRAIR BIOSAMPLES
     * ========================================================
     */

    def ch_biosamples = ch_manifest
        .splitCsv(header: true, sep: '\t')
        .map { row -> row.biosample }

    /*
     * ========================================================
     * BLOCO 2 — PREPROCESS
     * ========================================================
     */

    ch_biosamples | FASTQC

    def ch_trim = ch_biosamples | TRIMMOMATIC

    def ch_bwa   = ch_trim | BWA
    def ch_kaiju = ch_trim | KAIJU

    def ch_block2_done = ch_trim.collect().map { true }

    /*
     * ========================================================
     * BLOCO 3 — VARIANT CALLING
     * ========================================================
     */

    // 🔧 FIX AQUI — DELLY agora recebe 2 canais
    def ch_delly = ch_biosamples
        .combine(ch_block2_done)
        .map { it[0] }
        | DELLY

    def ch_lofreq     = ch_biosamples | LOFREQ
    def ch_gatk_gvcf  = ch_biosamples | GATK_GVCF
    def ch_gatk_vcf   = ch_biosamples | GATK_VCF

    def ch_norm       = ch_biosamples | NORM

    def ch_block3_done = ch_norm.collect().map { true }

    /*
     * ========================================================
     * BLOCO 4 — ANNOTATION + COHORT
     * ========================================================
     */

    def ch_snpeff     = ch_biosamples | SNPEFF
    def ch_tbdr_rcov  = ch_biosamples | TBDR_RCOV
    def ch_ntm_filter = ch_biosamples | NTM_FILTER
    def ch_lineage    = ch_biosamples | LINEAGE

    def ch_block4_samples_done = ch_biosamples.collect().map { true }

    def ch_cohort = ch_block4_samples_done | COHORT
    def ch_cohort_filtered = ch_cohort | COHORT_FILTER

    def ch_block4_done = ch_cohort_filtered.map { true }

    /*
     * ========================================================
     * BLOCO 5 — PHYLOGENY
     * ========================================================
     */

    def ch_snp_matrix = ch_block4_done | SNP_MATRIX

    def ch_transmission = ch_snp_matrix | TRANSMISSION
    def ch_iqtree       = ch_snp_matrix | IQTREE

    def ch_block5_done = ch_snp_matrix.map { true }

    /*
     * ========================================================
     * BLOCO 6 — RESISTANCE
     * ========================================================
     */

    def ch_mixinfection = ch_biosamples
        .combine(ch_block5_done)
        .map { it[0] }
        | MIXINFECTION

    def ch_resistance_target = ch_biosamples
        .combine(ch_block5_done)
        .map { it[0] }
        | RESISTANCE_TARGET

    def ch_resistance_report = ch_resistance_target
        | RESISTANCE_REPORT

    def ch_block6_done = ch_resistance_report.collect().map { true }

    /*
     * ========================================================
     * BLOCO 7 — SUMMARY
     * ========================================================
     */

    def ch_resistance_summary = ch_block6_done | RESISTANCE_SUMMARY
    def ch_qc_summary         = ch_resistance_summary | QC_SUMMARY

    def ch_block7_done = ch_qc_summary.map { true }

    /*
     * ========================================================
     * BLOCO 8 — CLINICAL REPORT
     * ========================================================
     */

    def ch_clinical_report = ch_biosamples
        .combine(ch_block7_done)
        .map { it[0] }
        | CLINICAL_REPORT

    def ch_block8_done = ch_clinical_report.collect().map { true }

}


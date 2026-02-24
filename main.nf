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
        val biosample

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

workflow {

    /*
     * ========================================================
     * BLOCO 1 — INIT (UM APÓS O OUTRO)
     * ========================================================
     */

    ch_init = Channel.value(true)

    ch_init = KAIJU_DB(ch_init)
    ch_init = OMS_CATALOG(ch_init)
    ch_init = BWA_REF(ch_init)
    ch_init = GATK_DICT(ch_init)
    ch_init = SNPEFF_DB(ch_init)

    ch_manifest = MAKE_MANIFEST_VALIDATE(
        ch_init,
        file("${projectDir}/input/input_table.xlsx"),
        file("${projectDir}/reads")
    )

    /*
     * Barreira BLOCO 1
     */
    ch_block1_done = ch_manifest.collect()



    /*
     * ========================================================
     * BLOCO 2 — SEQUENCIAL POR BIOSAMPLE
     * fastqc → trimmomatic → kaiju → bwa
     * ========================================================
     */

    ch_biosamples = ch_manifest
        .splitCsv(header:true, sep:'\t')
        .map { row -> row.biosample }

    ch_fastqc_input = ch_biosamples
        .combine(ch_block1_done)
        .map { id, _ -> tuple(id, true) }

    ch_fastqc = FASTQC(ch_fastqc_input)

    ch_trim = TRIMMOMATIC(ch_fastqc_input)

    ch_kaiju_input = ch_trim.map { id, trim_dir ->
        tuple(id, trim_dir)
    }

    (ch_kaiju_dir, ch_kaiju_summary) = KAIJU(ch_kaiju_input)

    ch_bwa_input = ch_trim.map { id, trim_dir ->
        tuple(id, trim_dir)
    }

    (ch_bwa_tuple, ch_bwa_summary) = BWA(ch_bwa_input)

    /*
     * Barreira BLOCO 2
     */
    ch_block2_done = ch_bwa_tuple
        .map { true }
        .collect()



    /*
     * ========================================================
     * BLOCO 3 — SEQUENCIAL POR BIOSAMPLE
     * delly → lofreq → gatkGvcf → gatkVcf → norm
     * ========================================================
     */

    ch_bwa_tuple_ready = ch_bwa_tuple
        .combine(ch_block2_done)
        .map { t, _ -> t }

    ch_bwa_summary_ready = ch_bwa_summary
        .combine(ch_block2_done)
        .map { s, _ -> s }

    (ch_delly_dir, ch_delly_vcf) =
        DELLY(ch_bwa_tuple_ready, ch_bwa_summary_ready)

    (ch_lofreq_dir, ch_lofreq_vcf) =
        LOFREQ(ch_delly_dir, ch_delly_vcf)

    (ch_gatk_dir_gvcf, ch_gatk_gvcf) =
        GATK_GVCF(ch_lofreq_dir, ch_lofreq_vcf)

    (ch_gatk_dir_vcf, ch_gatk_vcf) =
        GATK_VCF(ch_gatk_dir_gvcf, ch_gatk_gvcf)

    ch_norm =
        NORM(ch_gatk_dir_vcf, ch_gatk_vcf)

    /*
     * Barreira BLOCO 3
     */
    ch_block3_done = ch_norm
        .map { true }
        .collect()



    /*
     * ========================================================
     * BLOCO 4 — SEQUENCIAL POR BIOSAMPLE
     * snpeff → tbdr → ntm → lineage
     * ========================================================
     */

    ch_block4_bios = ch_biosamples
        .combine(ch_block3_done)
        .map { id, _ -> id }

    ch_snpeff = SNPEFF(ch_block4_bios)

    ch_tbdr = TBDR_RCOV(ch_snpeff)

    ch_ntm = NTM_FILTER(ch_tbdr)

    ch_lineage = LINEAGE(ch_ntm)

    /*
     * Barreira BLOCO 4 (todas amostras terminaram)
     */
    ch_block4_done = ch_lineage
        .map { true }
        .collect()



    /*
     * ========================================================
     * COHORT (UMA VEZ)
     * ========================================================
     */

    ch_cohort = COHORT(ch_block4_done)

    ch_cohort_filtered = COHORT_FILTER(ch_cohort)

}
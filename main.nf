nextflow.enable.dsl = 2

/*
 * ============================================================
 * PARAMETERS
 * ============================================================
 */

params.run                = null
params.add_kaiju_manually = false
params.input_table        = "input/input_table.xlsx"
params.reads_dir          = "reads"

/*
 * ============================================================
 * BLOCK - INIT CHAIN (SEQUENTIAL + CACHED)
 * ============================================================
 */

process KAIJU_DB {

    tag "kaiju-db"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/kaijudb.sh ${params.add_kaiju_manually}
    """
}


process OMS_CATALOG {

    tag "oms-catalog"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    python bin/omsCatalog.py
    """
}


process BWA_REF {

    tag "bwa-ref"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/bwaref.sh
    """
}


process GATK_DICT {

    tag "gatk-dict"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/gatkdict.sh
    """
}


process SNPEFF_DB {

    tag "snpeff-db"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/snpeffdb.sh
    """
}


process MAKE_MANIFEST_VALIDATE {

    tag "manifest"

    input:
        val token
        path input_table
        path reads_dir

    output:
        path "manifest.tsv"

    publishDir "${projectDir}", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/make_manifest_validate.py \
        --xlsx ${input_table} \
        --reads ${reads_dir} \
        --out manifest.tsv
    """
}

/*
 * ============================================================
 * BLOCK 1 - PER SAMPLE (PARALLEL)
 * ============================================================
 */

process FASTQC {

    tag { biosample }

    input:
        tuple val(biosample), path(reads)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/fastqc", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/fastqc.sh "${biosample}"
    cp -r ${projectDir}/fastqc/${biosample} .
    """
}


process TRIMMOMATIC {

    tag { biosample }

    input:
        tuple val(biosample), path(reads)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/trimmomatic", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/trimmomatic.sh "${biosample}"
    cp -r ${projectDir}/trimmomatic/${biosample} .
    """
}


process KAIJU {

    tag { biosample }

    input:
        tuple val(biosample), path(trim_dir)

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}_kaiju_summary.csv"

    publishDir "${projectDir}/kaiju", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/kaiju.sh "${biosample}"
    cp -r ${projectDir}/kaiju/${biosample} .
    cp ${projectDir}/kaiju/${biosample}/${biosample}_kaiju_summary.csv .
    """
}


process BWA {

    tag { biosample }

    input:
        tuple val(biosample), path(trim_dir)

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}_bwa_summary.csv"

    publishDir "${projectDir}/bwa", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/bwa.sh "${biosample}"
    cp -r ${projectDir}/bwa/${biosample} .
    cp ${projectDir}/bwa/${biosample}/${biosample}_bwa_summary.csv .
    """
}


process DELLY {

    tag { biosample }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}_delly.vcf.gz"

    publishDir "${projectDir}/delly", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/delly.sh "${biosample}"
    cp -r ${projectDir}/delly/${biosample} .
    cp ${projectDir}/delly/${biosample}/${biosample}_delly.vcf.gz .
    """
}


process LOFREQ {

    tag { biosample }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}_lofreq.vcf.gz"

    publishDir "${projectDir}/lofreq", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/lofreq.sh "${biosample}"
    cp -r ${projectDir}/lofreq/${biosample} .
    cp ${projectDir}/lofreq/${biosample}/${biosample}_lofreq.vcf.gz .
    """
}


process GATK_GVCF {

    tag { biosample }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}.g.vcf.gz"

    publishDir "${projectDir}/gatk", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/gatkGvcf.sh "${biosample}"
    cp -r ${projectDir}/gatk/${biosample} .
    cp ${projectDir}/gatk/${biosample}/${biosample}.g.vcf.gz .
    """
}


process GATK_VCF {

    tag { biosample }

    input:
        tuple val(biosample), path(bwa_dir)
        path bwa_summary

    output:
        tuple val(biosample), path("${biosample}")
        path "${biosample}_gatk.vcf.gz"

    publishDir "${projectDir}/gatk", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/gatkVcf.sh "${biosample}"
    cp -r ${projectDir}/gatk/${biosample} .
    cp ${projectDir}/gatk/${biosample}/${biosample}_gatk.vcf.gz .
    """
}


process NORM {

    tag { biosample }

    input:
        tuple val(biosample), path(gatk_dir)
        path vcf_file

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/norm", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/norm.sh "${biosample}"
    cp -r ${projectDir}/norm/${biosample} .
    """
}


process SNPEFF {

    tag { biosample }

    input:
        tuple val(biosample), path(norm_dir)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/snpeff", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/snpeff.sh "${biosample}"
    cp -r ${projectDir}/snpeff/${biosample} .
    """
}


process TBDR_RCOV {

    tag { biosample }

    input:
        tuple val(biosample), path(gvcf_dir)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/tbdrRCov", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/tbdrRCov.py "${biosample}"
    cp -r ${projectDir}/tbdrRCov/${biosample} .
    """
}


process NTM_FILTER {

    tag { biosample }

    input:
        tuple val(biosample), path(gvcf_dir)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/ntmFilter", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/ntmFilter.sh "${biosample}"
    cp -r ${projectDir}/ntmFilter/${biosample} .
    """
}


process LINEAGE {

    tag { biosample }

    input:
        tuple val(biosample), path(norm_dir)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/lineage", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/lineage.py "${biosample}"
    cp -r ${projectDir}/lineage/${biosample} .
    """
}

/*
 * ============================================================
 * BLOCK 2 - GLOBAL (AFTER ALL SAMPLES COMPLETE BLOCK 1)
 * ============================================================
 */

process COHORT {

    tag "cohort"

    input:
        val trigger

    output:
        path "cohort"

    publishDir "${projectDir}/cohort", mode: 'copy'

    script:
    """
    bash ${projectDir}/bin/cohort.sh ${projectDir}/manifest.tsv
    cp -r ${projectDir}/cohort/* cohort/ || true
    """
}


process COHORT_FILTER {

    tag "cohort-filter"

    input:
        path cohort_dir

    output:
        path "cohort_filtered"

    publishDir "${projectDir}/cohort_filtered", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/cohortFilter.py
    cp -r ${projectDir}/cohort_filtered/* cohort_filtered/ || true
    """
}


process SNP_MATRIX {

    tag "snp-matrix"

    input:
        val trigger

    output:
        path "snpMatrix"

    publishDir "${projectDir}/snpMatrix", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/snpMatrix.py
    cp -r ${projectDir}/snpMatrix/* snpMatrix/ || true
    """
}


process TRANSMISSION {

    tag "transmission"

    input:
        path snp_matrix_dir

    output:
        path "transmission"

    publishDir "${projectDir}/transmission", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/transmission.py
    cp -r ${projectDir}/transmission/* transmission/ || true
    """
}


process IQTREE {

    tag "iqtree"

    input:
        path snp_matrix_dir

    output:
        path "iqtree"

    publishDir "${projectDir}/iqtree", mode: 'copy'

    script:
    """
    export THREADS=${task.cpus}
    bash ${projectDir}/bin/iqtree.sh
    cp -r ${projectDir}/iqtree/* iqtree/ || true
    """
}

/*
 * ============================================================
 * BLOCK 3 - AFTER BLOCK 2 (GLOBAL SYNC)
 * ============================================================
 */

process MIXINFECTION {

    tag { biosample }

    input:
        tuple val(biosample), path(snp_matrix_dir)

    output:
        tuple val(biosample), path("${biosample}")

    publishDir "${projectDir}/mixInfection", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/mixInfection.py "${biosample}"
    cp -r ${projectDir}/mixInfection/${biosample} .
    """
}


process RESISTANCE_TARGET {

    tag { biosample }

    input:
        tuple val(biosample), path(snpeff_dir)

    output:
        path "${biosample}_OMStarget.xlsx"

    publishDir "${projectDir}/resistance", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/resistanceTarget.py "${biosample}"
    cp ${projectDir}/resistance/${biosample}/${biosample}_OMStarget.xlsx .
    """
}


process RESISTANCE_REPORT {

    tag { omstarget.baseName }

    input:
        path omstarget

    output:
        path "${omstarget.baseName}.xlsx"

    publishDir "${projectDir}/results/resistance", mode: 'copy'

    script:
    """
    BIOSAMPLE=\$(basename "${omstarget}" _OMStarget.xlsx)
    python ${projectDir}/bin/resistanceReport.py "\$BIOSAMPLE"
    cp ${projectDir}/results/resistance/\$BIOSAMPLE.xlsx .
    """
}


/*
 * ============================================================
 * BLOCK 4 - AFTER BLOCK 3 (GLOBAL SYNC)
 * ============================================================
 */

process RESISTANCE_SUMMARY {

    tag "resistance-summary"

    input:
        val trigger

    output:
        path "resistanceSummary"

    publishDir "${projectDir}/results", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/resistanceSummary.py
    cp -r ${projectDir}/results/resistanceSummary/* resistanceSummary/ || true
    """
}


process QC_SUMMARY {

    tag "qc-summary"

    input:
        val trigger

    output:
        path "qcSummary"

    publishDir "${projectDir}/results", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/qcSummary.py
    cp -r ${projectDir}/results/qcSummary/* qcSummary/ || true
    """
}


/*
 * ============================================================
 * BLOCK 5 - FINAL
 * ============================================================
 */

process CLINICAL_REPORT {

    tag { biosample }

    input:
        val biosample

    output:
        path "${biosample}.docx"

    publishDir "${projectDir}/results/clinicalReport", mode: 'copy'

    script:
    """
    python ${projectDir}/bin/clinicalReport.py "${biosample}"
    cp ${projectDir}/results/clinicalReport/${biosample}.docx .
    """
}

workflow {

    /*
     * ============================================================
     * INIT (GLOBAL - roda 1x)
     * ============================================================
     */

    init_done = Channel.value(true)
        | KAIJU_DB
        | OMS_CATALOG
        | BWA_REF
        | GATK_DICT
        | SNPEFF_DB

    manifest_ch = MAKE_MANIFEST_VALIDATE(
        init_done,
        file(params.input_table),
        file(params.reads_dir)
    )

    /*
     * ============================================================
     * SPLIT MANIFEST → POR BIOSAMPLE
     * ============================================================
     */

    samples_ch = manifest_ch
        .splitCsv(header:true, sep:'\t')
        .map { row ->
            tuple(row.biosample, file("${params.reads_dir}/${row.biosample}"))
        }

    /*
     * ============================================================
     * BLOCO 1 — PARALELO POR AMOSTRA
     * ============================================================
     */

    fastqc_out    = FASTQC(samples_ch)

    trim_out      = TRIMMOMATIC(samples_ch)

    kaiju_out     = KAIJU(trim_out)

    bwa_out       = BWA(trim_out)

    delly_out     = DELLY(bwa_out)

    lofreq_out    = LOFREQ(bwa_out)

    gatk_gvcf_out = GATK_GVCF(bwa_out)

    gatk_vcf_out  = GATK_VCF(bwa_out)

    norm_out      = NORM(gatk_vcf_out)

    /*
     * ---- SNPEFF depende de TODOS os chamadores ----
     */

    snpeff_trigger = lofreq_out
        .join(gatk_gvcf_out)
        .join(gatk_vcf_out)
        .join(norm_out)

    snpeff_out = SNPEFF(snpeff_trigger)

    /*
     * ---- Dependências específicas ----
     */

    tbdr_out   = TBDR_RCOV(gatk_gvcf_out)

    ntm_trigger = lofreq_out.join(gatk_gvcf_out)
    ntm_out     = NTM_FILTER(ntm_trigger)

    lineage_out = LINEAGE(norm_out)

    /*
     * ============================================================
     * SINCRONIZAÇÃO GLOBAL BLOCO 1
     * ============================================================
     */

    block1_done = Channel
        .merge(
            snpeff_out,
            tbdr_out,
            ntm_out,
            lineage_out,
            delly_out
        )
        .collect()

    /*
     * ============================================================
     * BLOCO 2 — GLOBAL
     * ============================================================
     */

    cohort_out = COHORT(block1_done)

    cohort_filter_out = COHORT_FILTER(cohort_out)

    snp_matrix_out = SNP_MATRIX(cohort_filter_out)

    transmission_out = TRANSMISSION(snp_matrix_out)

    iqtree_out = IQTREE(snp_matrix_out)

    /*
     * ============================================================
     * SINCRONIZAÇÃO GLOBAL BLOCO 2
     * ============================================================
     */

    block2_done = Channel
        .merge(
            transmission_out,
            iqtree_out
        )
        .collect()

    /*
     * ============================================================
     * BLOCO 3
     * ============================================================
     */

    mix_out = MIXINFECTION(
        samples_ch.combine(block2_done)
    )

    resistance_tgt = RESISTANCE_TARGET(snpeff_out)

    resistance_rep = RESISTANCE_REPORT(resistance_tgt)

    /*
     * ============================================================
     * SINCRONIZAÇÃO GLOBAL BLOCO 3
     * ============================================================
     */

    block3_done = Channel
        .merge(
            mix_out,
            resistance_rep
        )
        .collect()

    /*
     * ============================================================
     * BLOCO 4 — GLOBAL
     * ============================================================
     */

    resistance_sum = RESISTANCE_SUMMARY(block3_done)

    qc_sum = QC_SUMMARY(block3_done)

    /*
     * ============================================================
     * SINCRONIZAÇÃO GLOBAL BLOCO 4
     * ============================================================
     */

    block4_done = Channel
        .merge(
            resistance_sum,
            qc_sum
        )
        .collect()

    /*
     * ============================================================
     * BLOCO 5 — FINAL
     * ============================================================
     */

    CLINICAL_REPORT(
        samples_ch.combine(block4_done)
    )
}



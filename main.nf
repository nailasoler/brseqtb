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
 * BLOCK 1 — PER BIOSAMPLE
 * ============================================================
 */

process FASTQC {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/fastqc.sh ${biosample} ${params.reads_dir}
    """
}


process TRIMMOMATIC {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/trimmomatic.sh ${biosample} ${params.reads_dir}
    """
}


process KAIJU {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/kaiju.sh ${biosample}
    """
}


process BWA {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/bwa.sh ${biosample}
    """
}


process DELLY {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/delly.sh ${biosample}
    """
}


process LOFREQ {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/lofreq.sh ${biosample}
    """
}


process GATK_GVCF {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/gatkGvcf.sh ${biosample}
    """
}


process GATK_VCF {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/gatkVcf.sh ${biosample}
    """
}


process NORM {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/norm.sh ${biosample}
    """
}

process TBDR_RCOV {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/tbdrRCov.py ${biosample}
    """
}

process LINEAGE {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/lineage.py ${biosample}
    """
}

process NTM_FILTER {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/ntmFilter.sh ${biosample}
    """
}

process SNPEFF {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    bash bin/snpeff.sh ${biosample}
    """
}

/*
 * ============================================================
 * BLOCO 2 — COHORT (GLOBAL)
 * Inicia apenas após sincronização global do BLOCO 1
 * ============================================================
 */

process COHORT {

    tag "cohort"

    input:
        val token
        path manifest

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/cohort.sh ${manifest}
    """
}

process COHORT_FILTER {

    tag "cohort-filter"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    python bin/cohortFilter.py
    """
}

process SNP_MATRIX {

    tag "snp-matrix"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    python bin/snpMatrix.py
    """
}

process TRANSMISSION {

    tag "transmission"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    python bin/transmission.py
    """
}

process IQTREE {

    tag "iqtree"

    input:
        val token

    output:
        val true

    script:
    """
    cd "${projectDir}"
    bash bin/iqtree.sh
    """
}

/*
 * ============================================================
 * BLOCO 3 — PER BIOSAMPLE
 * Inicia apenas após sincronização global do BLOCO 2
 * ============================================================
 */

process MIX_INFECTION {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/mixInfection.py ${biosample}
    """
}


process RESISTANCE_TARGET {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/resistanceTarget.py ${biosample}
    """
}


process RESISTANCE_REPORT {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/resistanceReport.py ${biosample}
    """
}

/*
 * ============================================================
 * BLOCO  — COHORT e PER BIOSAMPLE
 * Inicia apenas após sincronização global do BLOCO 3
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
    cd "${projectDir}"
    python bin/resistanceSummary.py
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
    cd "${projectDir}"
    python bin/qcSummary.py
    """
}

process CLINICAL_REPORT {

    tag { biosample }

    input:
        val biosample

    output:
        val biosample

    script:
    """
    cd "${projectDir}"
    python bin/clinicalReport.py ${biosample}
    """
}

workflow {

    /*
     * ============================================================
     * INIT (SEQUENTIAL)
     * ============================================================
     */

    init_done = Channel.value(true)
        | KAIJU_DB
        | OMS_CATALOG
        | BWA_REF
        | GATK_DICT
        | SNPEFF_DB

    /*
     * ============================================================
     * MANIFEST
     * ============================================================
     */

    manifest_ch = MAKE_MANIFEST_VALIDATE(
        init_done,
        file(params.input_table),
        file(params.reads_dir)
    )

    /*
     * ============================================================
     * SAMPLES CHANNEL
     * ============================================================
     */

    samples_ch = manifest_ch
        .splitCsv(header:true, sep:'\t')
        .map { row -> row.biosample }

    /*
     * ============================================================
     * BLOCO 1 — PER BIOSAMPLE
     * ============================================================
     */

    // Independente
    fastqc_ch = FASTQC(samples_ch)

    // Pré-processamento
    trimmomatic_ch = TRIMMOMATIC(samples_ch)

    // Após trimmomatic
    kaiju_ch = KAIJU(trimmomatic_ch)
    bwa_ch   = BWA(trimmomatic_ch)

    // Após BWA
    delly_ch      = DELLY(bwa_ch)
    lofreq_ch     = LOFREQ(bwa_ch)
    gatk_gvcf_ch  = GATK_GVCF(bwa_ch)
    gatk_vcf_ch   = GATK_VCF(bwa_ch)

    // Após GATK_VCF
    norm_ch = NORM(gatk_vcf_ch)
    tbdr_rcov_ch = TBDR_RCOV(gatk_gvcf_ch)

    // Após NORM
    lineage_ch = LINEAGE(norm_ch)
    
        // Após LOFREQ + GATK_GVCF
    ntm_input_ch = lofreq_ch
        .join(gatk_gvcf_ch)

    ntm_filter_ch = NTM_FILTER(ntm_input_ch)

    // SNPEFF após todos chamadores principais
    snpeff_input_ch = lofreq_ch
        .join(gatk_gvcf_ch)
        .join(gatk_vcf_ch)
        .join(norm_ch)

    snpeff_ch = SNPEFF(snpeff_input_ch)
    
        /*
     * ============================================================
     * GLOBAL SYNC — FIM BLOCO 1
     * Espera TODAS biosamples finalizarem SNPEFF
     * ============================================================
     */

    bloco1_sync = snpeff_ch
        .collect()
        .map { true }

    /*
     * ============================================================
     * BLOCO 2 — COORTE
     * ============================================================
     */

    cohort_ch = COHORT(
    	bloco1_sync,
    	manifest_ch
	)
    cohort_filter_ch = COHORT_FILTER(cohort_ch)

    snp_matrix_ch = SNP_MATRIX(cohort_ch)

    /*
     * ============================================================
     * RAMIFICAÇÃO FINAL DO BLOCO 2
     * Ambos dependem de SNP_MATRIX
     * ============================================================
     */

    transmission_ch = TRANSMISSION(snp_matrix_ch)

    iqtree_ch = IQTREE(snp_matrix_ch)
    
        /*
     * ============================================================
     * GLOBAL SYNC — FIM BLOCO 2
     * Espera finalização completa de TRANSMISSION e IQTREE
     * ============================================================
     */

    bloco2_sync = transmission_ch
        .join(iqtree_ch)
        .collect()
        .map { true }

    /*
     * ============================================================
     * BLOCO 3 — PER BIOSAMPLE
     * Inicia apenas após sincronização global do BLOCO 2
     * ============================================================
     */

    bloco3_samples_ch = samples_ch
        .combine(bloco2_sync)
        .map { biosample, _ -> biosample }

    // Independente
    mix_infection_ch = MIX_INFECTION(bloco3_samples_ch)

    // Resistance target
    resistance_target_ch = RESISTANCE_TARGET(bloco3_samples_ch)

    // Resistance report depende obrigatoriamente de resistance_target
    resistance_report_ch = RESISTANCE_REPORT(resistance_target_ch)
    
        /*
     * ============================================================
     * GLOBAL SYNC — FIM BLOCO 3
     * Espera TODAS biosamples finalizarem RESISTANCE_REPORT
     * ============================================================
     */

    bloco3_sync = resistance_report_ch
        .collect()
        .map { true }

    /*
     * ============================================================
     * BLOCO 4 — COORTE (REPORTS GLOBAIS)
     * Inicia apenas após sincronização global do BLOCO 3
     * ============================================================
     */

    resistance_summary_ch = RESISTANCE_SUMMARY(bloco3_sync)

    qc_summary_ch = QC_SUMMARY(bloco3_sync)

    /*
     * ============================================================
     * GLOBAL SYNC — FIM SUMMARIES
     * Espera RESISTANCE_SUMMARY e QC_SUMMARY finalizarem
     * ============================================================
     */

    bloco4_sync = resistance_summary_ch
        .join(qc_summary_ch)
        .collect()
        .map { true }

    /*
     * ============================================================
     * CLINICAL REPORT — PER BIOSAMPLE
     * Só inicia após TODOS os summaries finalizarem
     * ============================================================
     */

    clinical_samples_ch = samples_ch
        .combine(bloco4_sync)
        .map { biosample, _ -> biosample }

    clinical_report_ch = CLINICAL_REPORT(clinical_samples_ch)

}

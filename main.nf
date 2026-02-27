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
        tuple val(biosample), path(reads_dir)

    output:
        tuple val(biosample), path(reads_dir)

    script:
    """
    cd "${projectDir}"
    bash bin/fastqc.sh ${biosample} ${reads_dir}
    """
}


process TRIMMOMATIC {

    tag { biosample }

    input:
        tuple val(biosample), path(reads_dir)

    output:
        tuple val(biosample), path(reads_dir)

    script:
    """
    cd "${projectDir}"
    bash bin/trimmomatic.sh ${biosample} ${reads_dir}
    """
}


process KAIJU {

    tag { biosample }

    input:
        tuple val(biosample), path(reads_dir)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/kaiju.sh ${biosample}
    """
}


process BWA {

    tag { biosample }

    input:
        tuple val(biosample), path(reads_dir)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/bwa.sh ${biosample}
    """
}

process DELLY {

    tag { biosample }

    input:
        tuple val(biosample)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/delly.sh ${biosample}
    """
}


process LOFREQ {

    tag { biosample }

    input:
        tuple val(biosample)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/lofreq.sh ${biosample}
    """
}


process GATK_GVCF {

    tag { biosample }

    input:
        tuple val(biosample)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/gatkGvcf.sh ${biosample}
    """
}


process GATK_VCF {

    tag { biosample }

    input:
        tuple val(biosample)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/gatkVcf.sh ${biosample}
    """
}


process NORM {

    tag { biosample }

    input:
        tuple val(biosample)

    output:
        tuple val(biosample)

    script:
    """
    cd "${projectDir}"
    bash bin/norm.sh ${biosample}
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
        .map { row ->
            tuple(row.biosample, file(params.reads_dir))
        }

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

}

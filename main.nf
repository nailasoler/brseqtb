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
 * BLOCK 1 - INIT CHAIN (SEQUENTIAL + CACHED)
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
 * WORKFLOW
 * ============================================================
 */

workflow {

    init_done = Channel.value(true)
        | KAIJU_DB
        | OMS_CATALOG
        | BWA_REF
        | GATK_DICT
        | SNPEFF_DB

    MAKE_MANIFEST_VALIDATE(
        init_done,
        file(params.input_table),
        file(params.reads_dir)
    )
}

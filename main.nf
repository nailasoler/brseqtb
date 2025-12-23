nextflow.enable.dsl = 2

params.add_kaiju_manually = false

process INIT_PIPELINE {

    tag "init"

    script:
    """
    cd ${projectDir}
    bash bin/init_pipeline.sh
    """
}

process KAIJU_DB {

    tag "kaiju-db"

    script:
    """
    cd ${projectDir}
    bash bin/kaijudb.sh ${params.add_kaiju_manually}
    """
}

workflow {
    INIT_PIPELINE()
    KAIJU_DB()
}


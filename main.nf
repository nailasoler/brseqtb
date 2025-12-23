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

process OMS_CATALOG {

    tag "oms-catalog"

    script:
    """
    cd ${projectDir}
    python3 bin/omsCatalog.py
    """
}

workflow {

    /*
     * Mandatory initialization order
     */
    INIT_PIPELINE()
    KAIJU_DB()
    OMS_CATALOG()
}


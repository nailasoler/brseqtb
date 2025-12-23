nextflow.enable.dsl = 2

process INIT_PIPELINE {

    tag "init"

    output:
    path "database/.init.done"

    script:
    """
    bash ${projectDir}/bin/init_pipeline.sh
    touch database/.init.done
    """
}

workflow {
    INIT_PIPELINE()
}


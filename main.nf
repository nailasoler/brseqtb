nextflow.enable.dsl = 2

/*
 * brseqtb — installation / preparation workflow
 *
 * This workflow intentionally performs side-effects
 * in the project root directory (outside work/).
 *
 * Nextflow is used only as an orchestrator.
 */

process INIT_PIPELINE {

    tag "init"

    script:
    """
    cd ${projectDir}
    bash bin/init_pipeline.sh
    """
}

workflow {
    INIT_PIPELINE()
}


nextflow.enable.dsl = 2

/*
 * brseqtb — installation / preparation pipeline
 * This workflow runs only the initial setup script.
 */

process INIT_PIPELINE {

    tag "init"

    /*
     * We use a sentinel file to allow resume
     * and avoid re-running the setup unnecessarily.
     */
    output:
    path "database/.init.done"

    script:
    """
    bash bin/init_pipeline.sh
    touch database/.init.done
    """
}

workflow {
    INIT_PIPELINE()
}


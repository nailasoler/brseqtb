nextflow.enable.dsl = 2

/*
 * Parameters
 */
params.run = null
params.add_kaiju_manually = false
params.setup_micromamba = true   // default: instala/atualiza env antes do resto

/*
 * Processes
 */

process MICROMAMBA_SETUP {

    tag "micromamba-setup"

    output:
        path "micromamba_ready.txt"

    script:
    """
    WORKDIR="\$PWD"
    cd ${projectDir}
    bash bin/micromamba_setup.sh
    echo OK > "\$WORKDIR/micromamba_ready.txt"
    """
}

process KAIJU_DB {

    tag "kaiju-db"

    input:
        path micromamba_ready

    script:
    """
    cd ${projectDir}
    bash bin/kaijudb.sh ${params.add_kaiju_manually}
    """
}

process OMS_CATALOG {

    tag "oms-catalog"

    input:
        path micromamba_ready

    script:
    """
    cd ${projectDir}
    "${projectDir}/.micromamba/envs/brseqtb/bin/python" bin/omsCatalog.py
    """
}


process BWA_REF {

    tag "bwa-ref"

    input:
        path micromamba_ready

    script:
    """
    cd ${projectDir}
    bash bin/bwaref.sh
    """
}

process GATK_DICT {

    tag "gatk-dict"

    input:
        path micromamba_ready

    script:
    """
    cd ${projectDir}
    bash bin/gatkdict.sh
    """
}

/*
 * Workflow logic
 */
workflow {

    // Default full chain
    def full = ['micromamba', 'kaiju', 'oms', 'bwaref', 'gatkdict']

    // Parse user selection
    def steps = params.run
        ? params.run.split(',')*.trim()
        : full

    // Validate requested modules
    def valid = ['micromamba', 'kaiju', 'oms', 'bwaref', 'gatkdict']
    def invalid = steps.findAll { !valid.contains(it) }

    if ( invalid ) {
        error "Invalid module(s) in --run: ${invalid.join(', ')}"
    }

    // Always run micromamba setup first (unless disabled)
    def micromamba_ready_ch = null
    if ( params.setup_micromamba ) {
        micromamba_ready_ch = MICROMAMBA_SETUP()
    } else {
        micromamba_ready_ch = Channel.fromPath("${projectDir}/micromamba_ready.txt", checkIfExists: false)
    }

    // Execute requested modules in order
    steps.each { step ->
        switch ( step ) {
            case 'micromamba':
                // already handled above; keep for user visibility
                break
            case 'kaiju':
                KAIJU_DB(micromamba_ready_ch)
                break
            case 'oms':
                OMS_CATALOG(micromamba_ready_ch)
                break
            case 'bwaref':
                BWA_REF(micromamba_ready_ch)
                break
            case 'gatkdict':
                GATK_DICT(micromamba_ready_ch)
                break
        }
    }
}


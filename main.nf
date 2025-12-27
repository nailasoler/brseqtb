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

    script:
    """
    cd ${projectDir}
    bash bin/micromamba_setup.sh
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

process BWA_REF {

    tag "bwa-ref"

    script:
    """
    cd ${projectDir}
    bash bin/bwaref.sh
    """
}

process GATK_DICT {

    tag "gatk-dict"

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
    if ( params.setup_micromamba ) {
        MICROMAMBA_SETUP()
    }

    // Execute requested modules in order
    steps.each { step ->
        switch ( step ) {
            case 'micromamba':
                // already handled above; keep for user visibility
                break
            case 'kaiju':
                KAIJU_DB()
                break
            case 'oms':
                OMS_CATALOG()
                break
            case 'bwaref':
                BWA_REF()
                break
            case 'gatkdict':
                GATK_DICT()
                break
        }
    }
}


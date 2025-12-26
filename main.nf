nextflow.enable.dsl = 2

/*
 * Parameters
 */
params.run = null                  // e.g. kaiju,oms,bwaref
params.add_kaiju_manually = false

/*
 * Processes
 */

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
    def full = ['kaiju', 'oms', 'bwaref', 'gatkdict']

    // Parse user selection
    def steps = params.run
        ? params.run.split(',')*.trim()
        : full

    // Validate requested modules
    def valid = ['kaiju', 'oms', 'bwaref', 'gatkdict']
    def invalid = steps.findAll { !valid.contains(it) }

    if ( invalid ) {
        error "Invalid module(s) in --run: ${invalid.join(', ')}"
    }

    // Execute requested modules in order
    steps.each { step ->
        switch ( step ) {
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


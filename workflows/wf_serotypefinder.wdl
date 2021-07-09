version 1.0

import "../tasks/task_taxon_id.wdl" as taxon_ID

workflow serotypefinder {
    input {
        String  samplename
        File    ecoli_assembly
    }
    call taxon_ID.serotypefinder_one_sample {
    input:
        samplename = samplename,
        ecoli_assembly = ecoli_assembly
    }
    output {
        String serotypefinder_report  = serotypefinder_one_sample.serotypefinder_report
        String serotypefinder_docker  = serotypefinder_one_sample.serotypefinder_docker
    }
}

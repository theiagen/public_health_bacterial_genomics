version 1.0

import "../tasks/task_taxon_id.wdl" as taxon_ID
import "../tasks/task_versioning.wdl" as versioning

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
    call versioning.version_capture{
      input:
    }
    output {
        String serotypefinder_report  = serotypefinder_one_sample.serotypefinder_report
        String serotypefinder_docker  = serotypefinder_one_sample.serotypefinder_docker
        
        String  titan_illumina_pe_version            = version_capture.phbg_version
        String  titan_illumina_pe_analysis_date      = version_capture.date
        
    }
}

version 1.0

import "../tasks/task_taxon_id.wdl" as taxon_id
import "../tasks/task_versioning.wdl" as versioning

workflow gambit_query {
	input {
		File assembly_fasta
    String samplename
	}
	call taxon_id.gambit {
		input:
			assembly = assembly_fasta,
      samplename = samplename,
	}
	call versioning.version_capture{
    input:
  }
  output {
    String gambit_query_wf_version = version_capture.phbg_version
    String gambit_query_wf_analysis_date = version_capture.date
		
		File gambit_report = gambit.gambit_report
		String gambit_docker = gambit.gambit_docker
		Float gambit_distance = gambit.gambit_distance
		String gambit_taxon = gambit.gambit_taxon
		String gambit_rank = gambit.gambit_rank
		String gambit_db_genomes_version = gambit.gambit_db_genomes_version
		String gambit_db_signatures_version = gambit.gambit_db_signatures_version
    }
}
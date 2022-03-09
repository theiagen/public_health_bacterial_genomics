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
  call versioning.version_capture {
    input:
  }
  output {
    String gambit_query_wf_version = version_capture.phbg_version
    String gambit_query_wf_analysis_date = version_capture.date

    File gambit_report = gambit.report_file
    String gambit_docker = gambit.docker_image
    Float gambit_closest_distance = gambit.closest_distance
    String gambit_predicted_taxon = gambit.predicted_taxon
    String gambit_predicted_rank = gambit.predicted_rank
    String gambit_predicted_threshold = gambit.predicted_threshold
    String gambit_next_taxon = gambit.next_taxon
    String gambit_next_rank = gambit.next_rank
    String gambit_next_threshold = gambit.next_threshold
    File gambit_closest_genomes = gambit.closest_genomes_file
  }
}
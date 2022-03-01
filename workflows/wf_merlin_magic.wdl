version 1.0

import "../tasks/species_typing/task_serotypefinder.wdl" as serotypefinder
import "../tasks/species_typing/task_ectyper.wdl" as ectyper

workflow merlin_magic {
  meta {
    description: "Workflow for bacterial species typing; based on the Bactopia subworkflow Merlin (https://bactopia.github.io/bactopia-tools/merlin/)"
  }
  input {
    String samplename
    String merlin_tag
    File assembly
    File read1
    File read2
  }
  if (merlin_tag == "Escherichia") {
    call serotypefinder.serotypefinder {
      input:
        assembly = assembly,
        samplename = samplename
    }
    call ectyper.ectyper {
      input:
        assembly = assembly,
        samplename = samplename
    }
  }
  output {
  # Ecoli Typing
  File? serotypefinder_report = serotypefinder.serotypefinder_report
  String? serotypefinder_docker = serotypefinder.serotypefinder_docker
  String? serotypefinder_serotype = serotypefinder.serotypefinder_serotype
  File? ectyper_results = ectyper.ectyper_results
  String? ectyper_version = ectyper.ectyper_version
 }
}
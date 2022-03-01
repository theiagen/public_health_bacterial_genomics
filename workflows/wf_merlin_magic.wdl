version 1.0

import "../tasks/species_typing/task_serotypefinder.wdl" as serotypefinder
import "../tasks/species_typing/task_ectyper.wdl" as ectyper
import "../tasks/species_typing/task_lissero.wdl" as lissero
import "../tasks/species_typing/task_sistr.wdl" as sistr
import "../tasks/species_typing/task_seqsero2.wdl" as seqsero2
import "../tasks/species_typing/task_kleborate.wdl" as kleborate

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
  if (merlin_tag == "Listeria") {
    call lissero.lissero {
      input:
        assembly = assembly,
        samplename = samplename
    }
  }
  if (merlin_tag == "Salmonella") {
    call sistr.sistr {
      input: 
        assembly = assembly,
        samplename = samplename
    }
    call seqsero2.seqsero2_pe {
      input: 
        read1 = read1,
        read2 = read2,
        samplename = samplename
    }
  }
  if (merlin_tag == "Klebsiella") {
    call kleborate.kleborate {
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
  # Listeria Typing
  File? lissero_results = lissero.lissero_results
  String? lissero_version = lissero.lissero_version
  # Salmonella Typing
  File? sistr_results = sistr.sistr_results
  File? sistr_allele_json = sistr.sistr_allele_json
  File? sistr_allele_fasta = sistr.sistr_allele_fasta
  File? sistr_cgmlst = sistr.sistr_cgmlst
  String? sistr_version = sistr.sistr_version
  File? seqsero2_report = seqsero2_pe.seqsero2_report
  String? seqsero2_version = seqsero2_pe.seqsero2_version
  String? seqsero2_predicted_antigenic_profile = seqsero2_pe.seqsero2_predicted_antigenic_profile
  String? seqsero2_predicted_serotype = seqsero2_pe.seqsero2_predicted_serotype
  String? seqsero2_predicted_contamination = seqsero2_pe.seqsero2_predicted_contamination
  # Klebsiella Typing
  File? kleborate_output_file = kleborate.kleborate_output_file
  String? kleborate_version = kleborate.kleborate_version
  String? kleborate_key_resistance_genes = kleborate.kleborate_key_resistance_genes
  String? kleborate_genomic_resistance_mutations = kleborate.kleborate_genomic_resistance_mutations
 }
}
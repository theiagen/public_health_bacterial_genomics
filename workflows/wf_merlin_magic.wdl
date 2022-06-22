version 1.0

import "../tasks/species_typing/task_serotypefinder.wdl" as serotypefinder
import "../tasks/species_typing/task_ectyper.wdl" as ectyper
import "../tasks/species_typing/task_lissero.wdl" as lissero
import "../tasks/species_typing/task_sistr.wdl" as sistr
import "../tasks/species_typing/task_seqsero2.wdl" as seqsero2
import "../tasks/species_typing/task_kleborate.wdl" as kleborate
import "../tasks/species_typing/task_tbprofiler.wdl" as tbprofiler
import "../tasks/species_typing/task_legsta.wdl" as legsta

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
    call seqsero2.seqsero2_pe as seqsero2 {
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
  if (merlin_tag == "Mycobacterium") {
    call tbprofiler.tbprofiler_pe as tbprofiler {
      input:
        read1 = read1,
        read2 = read2,
        samplename = samplename
    }
  }
  if (merlin_tag == "Legionella pneumophila") {
    call legsta.legsta {
      input:
        assembly = assembly,
        samplename = samplename
    }
  }
  # Ecoli Typing
  File? serotypefinder_report = serotypefinder.serotypefinder_report
  String? serotypefinder_docker = serotypefinder.serotypefinder_docker
  String? serotypefinder_serotype = serotypefinder.serotypefinder_serotype
  File? ectyper_results = ectyper.ectyper_results
  String? ectyper_version = ectyper.ectyper_version
  String? ectyper_predicted_serotype = ectyper.ectyper_predicted_serotype
  # Listeria Typing
  File? lissero_results = lissero.lissero_results
  String? lissero_version = lissero.lissero_version
  # Salmonella Typing
  File? sistr_results = sistr.sistr_results
  File? sistr_allele_json = sistr.sistr_allele_json
  File? sistr_allele_fasta = sistr.sistr_allele_fasta
  File? sistr_cgmlst = sistr.sistr_cgmlst
  String? sistr_version = sistr.sistr_version
  String? sistr_predicted_serotype = sistr.sistr_predicted_serotype
  File? seqsero2_report = seqsero2.seqsero2_report
  String? seqsero2_version = seqsero2.seqsero2_version
  String? seqsero2_predicted_antigenic_profile = seqsero2.seqsero2_predicted_antigenic_profile
  String? seqsero2_predicted_serotype = seqsero2.seqsero2_predicted_serotype
  String? seqsero2_predicted_contamination = seqsero2.seqsero2_predicted_contamination
  # Klebsiella Typing
  File? kleborate_output_file = kleborate.kleborate_output_file
  String? kleborate_version = kleborate.kleborate_version
  String? kleborate_key_resistance_genes = kleborate.kleborate_key_resistance_genes
  String? kleborate_genomic_resistance_mutations = kleborate.kleborate_genomic_resistance_mutations
  String? kleborate_mlst_sequence_type = kleborate.kleborate_mlst_sequence_type
  # Mycobacterium Typing
  File? tbprofiler_output_file = tbprofiler.tbprofiler_output_csv
  File? tbprofiler_output_bam = tbprofiler.tbprofiler_output_bam
  File? tbprofiler_output_bai = tbprofiler.tbprofiler_output_bai
  String? tbprofiler_version = tbprofiler.version
  String? tbprofiler_main_lineage = tbprofiler.tbprofiler_main_lineage
  String? tbprofiler_sub_lineage = tbprofiler.tbprofiler_sub_lineage
  String? tbprofiler_dr_type = tbprofiler.tbprofiler_dr_type
  String? tbprofiler_resistance_genes = tbprofiler.tbprofiler_resistance_genes
  # Legionella pneumophila Typing
  File? legsta_results = legsta.legsta_results
  String? legsta_version = legsta.legsta_version
 }
}
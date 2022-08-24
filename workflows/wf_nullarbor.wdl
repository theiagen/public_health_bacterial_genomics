version 1.0

import "../tasks/task_nullarbor.wdl" as nullarbor


workflow nullarbor_workflow {
  meta {
    description: "Nullarbor workflow"
  }
  input {
    String? run_name
    File ref_genome
    File read_paths_file
    String? tree_builder
    String? assembler
    String? taxoner
    String? mode
    String? docker
    Int? memory
    Int? cpu
    String? kraken1_db
    String? kraken2_db
    String? centrifuge_db
  }
  call nullarbor.nullarbor_tsv {
    input:
      run_name = run_name,
      ref_genome = ref_genome,
      read_paths_file = read_paths_file,
      tree_builder = tree_builder,
      assembler = assembler,
      taxoner = taxoner,
      mode = mode,
      docker = docker,
      memory = memory,
      cpu = cpu,
      kraken1_db = kraken1_db,
      kraken2_db = kraken2_db,
      centrifuge_db = centrifuge_db

  }
  output {
    # Version Capture
    String theiacov_illumina_pe_version = version_capture.phvg_version
    String theiacov_illumina_pe_analysis_date = version_capture.date
    # Read Metadata
    String  seq_platform = seq_method
    # Read QC
    File read1_dehosted = read_QC_trim.read1_dehosted
  # Quasitools
    String quasitools_version = quasitools.quasitools_version
    String quasitools_date = quasitools.quasitools_date
    File quasitools_coverage_file = quasitools.coverage_file
    File quasitools_dr_report = quasitools.dr_report
    File quasitools_hydra_vcf = quasitools.hydra_vcf
    File quasitools_mutations_report = quasitools.mutations_report
  }
}
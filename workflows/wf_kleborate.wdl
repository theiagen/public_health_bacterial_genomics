version 1.0


import "../tasks/task_kleborate.wdl" as task_kleborate

workflow kleborate_wf {

  input {
      File assembly
      String samplename
    }

  call task_kleborate.kleborate_one_sample {
    input:
      assembly = assembly,
      samplename = samplename
    }

  output {
    File kleborate_report = kleborate_one_sample.kleborate_output_file
    String kleborate_version = kleborate_one_sample.version
    String version = kleborate_one_sample.version
    String pipeline_date = kleborate_one_sample.pipeline_date
    String mlst_sequence_type = kleborate_one_sample.mlst_sequence_type
    String virulence_score = kleborate_one_sample.virulence_score
    String resistance_score = kleborate_one_sample.resistance_score
    String num_resistance_genes = kleborate_one_sample.num_resistance_genes
    String bla_resistance_genes = kleborate_one_sample.bla_resistance_genes
    String esbl_resistance_genes = kleborate_one_sample.esbl_resistance_genes
    String key_resistance_genes = kleborate_one_sample.key_resistance_genes
    String resistance_mutations = kleborate_one_sample.resistance_mutations
    }
 }

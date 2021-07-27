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
    File kleborate_wf_report = kleborate_one_sample.kleborate_output_file
    String kleborate_wf_version = kleborate_one_sample.version
    String kleborate_wf_mlst_sequence_type = kleborate_one_sample.mlst_sequence_type
    String kleborate_wf_virulence_score = kleborate_one_sample.virulence_score
    String kleborate_wf_resistance_score = kleborate_one_sample.resistance_score
    String kleborate_wf_num_resistance_genes = kleborate_one_sample.num_resistance_genes
    String kleborate_wf_bla_resistance_genes = kleborate_one_sample.bla_resistance_genes
    String kleborate_wf_esbl_resistance_genes = kleborate_one_sample.esbl_resistance_genes
    String kleborate_wf_key_resistance_genes = kleborate_one_sample.key_resistance_genes
    String kleborate_wf_resistance_mutations = kleborate_one_sample.resistance_mutations
    }
 }

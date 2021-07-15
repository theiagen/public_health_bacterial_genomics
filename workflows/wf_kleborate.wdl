version 1.0


import "../tasks/task_kleborate.wdl" as task_kleborate

workflow kleborate_wf {

  input {
      File assembly
      String samplename
    }

  call task_kleborate.kleborate_one_sample {
    input:
      kleb_assembly = assembly,
      samplename = samplename
    }

  output {
    File kleborate_report = kleborate_one_sample.kleborate_output_file
    String kleborate_version = kleborate_one_sample.version
    File kleborate_key_resistance_file = kleborate_one_sample.key_resistance_factors_file 
    File kleborate_acquired_resistance_file = kleborate_one_sample.acquired_resistance_factors_file
    File kleborate_bla_resistance_file = kleborate_one_sample.bla_resistance_factors_file
    File kleborate_esbl_resistance_file = kleborate_one_sample.esbl_resistance_factors_file
    String kleborate_key_resistance = kleborate_one_sample.key_resistance_factors
    String kleborate_acquired_resistance = kleborate_one_sample.acquired_resistance_factors
    String kleborate_bla_resistance = kleborate_one_sample.bla_resistance_factors
    String kleborate_esbl_resistance = kleborate_one_sample.esbl_resistance_factors

    }
 }

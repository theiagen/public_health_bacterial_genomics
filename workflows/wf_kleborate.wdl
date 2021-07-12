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
    }
 }

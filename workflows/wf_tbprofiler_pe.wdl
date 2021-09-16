version 1.0


import "../tasks/task_taxon_id.wdl" as taxon
import "../tasks/task_versioning.wdl" as versioning

workflow tbprofiler_wf {
  input {
      File read1
      File read2
      String samplename
      String? mapper = "bwa"
      String? caller = "bcftools"
      String? min_depth = 10
      String? min_af = 0.1
      String? min_af_pred = 0.1
      String? cov_frac_threshold = 0
    }
  call taxon.tbprofiler_one_sample_pe {
    input:
      File read1 = read1,
      File read2 = read2,
      String samplename = samplename,
      String mapper = mapper,
      String caller = caller,
      String min_depth = min_depth,
      String min_af = min_af,
      String min_af_pred = min_af_pred,
      String cov_frac_threshold = cov_frac_threshold
    }
  call versioning.version_capture{
    input:
  }
  output {
    String tb_profiler_wf_version = version_capture.phbg_version
    String tb_profiler_wf_analysis_date = version_capture.date

    File tb_profiler_report_csv = tbprofiler_one_sample_pe.tbprofiler_output_csv
    File tb_profiler_report_tsv =tbprofiler_one_sample_pe.tbprofiler_output_tsv
    String tb_profiler_version = tbprofiler_one_sample_pe.version
    String tb_profiler_main_lineage = tbprofiler_one_sample_pe.tb_profiler_main_lineage
    String tb_profiler_sub_lineage = tbprofiler_one_sample_pe.tb_profiler_sub_lineage
    String tb_profiler_dr_type = tbprofiler_one_sample_pe.tb_profiler_dr_type
    String tb_profiler_num_dr_variants = tbprofiler_one_sample_pe.tb_profiler_num_dr_variants
    String tb_profiler_num_other_variants = tbprofiler_one_sample_pe.tb_profiler_num_other_variants
    String tb_profiler_resistance_genes = tbprofiler_one_sample_pe.tb_profiler_resistance_genes
    }
 }

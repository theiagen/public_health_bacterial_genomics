version 1.0

import "../tasks/task_versioning.wdl" as versioning
import "../tasks/task_pub_repo_prep.wdl" as submission_prep

workflow mercury_batch {
  input {
    Array[File] sra_metadata
    Array[String] sra_reads
    Array[File] biosample_attributes
    Array[String] samplename
    Array[String] submission_id
    Int cpu = 4
    Int disk_size = 100
    Int memory = 8
    String? gcp_bucket
  }

  call submission_prep.compile_biosamp_n_sra {
    input:
      single_submission_biosample_attirbutes = biosample_attributes,
      single_submission_sra_metadata = sra_metadata,
      single_submission_sra_reads = sra_reads,
      gcp_bucket = gcp_bucket,
      date = version_capture.date,
      cpu = cpu,
      disk_size = disk_size,
      memory = memory
  }

  call versioning.version_capture{
    input:
  }
  
  output {
    # Version Capture
    String mercury_batch_version = version_capture.phbg_version
    String mercury_batch_analysis_date = version_capture.date
    # BioSample and SRA Submission Files
    File BioSample_attributes = compile_biosamp_n_sra.biosample_attributes
    File SRA_metadata = compile_biosamp_n_sra.sra_metadata
    File? SRA_zipped_reads = compile_biosamp_n_sra.sra_zipped
    String? SRA_gcp_bucket = gcp_bucket
  }
}
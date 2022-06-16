version 1.0

import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3
import "../tasks/phylogenetic_inference/task_snp_dists.wdl" as snp_dists
import "../tasks/task_versioning.wdl" as versioning

workflow ksnp3_workflow {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    String cluster_name
	}
	call ksnp3.ksnp3 as ksnp3_task {
		input:
			assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name
  }
  call snp_dists.snp_dists {
    input:
      cluster_name = cluster_name,
      alignment = ksnp3_task.ksnp3_matrix
  }
  call versioning.version_capture{
    input:
  }
  output {
    String ksnp3_wf_version = version_capture.phbg_version
    String knsp3_wf_analysis_date = version_capture.date

    File ksnp3_snp_matrix = snp_dists.snp_matrix
    File ksnp3_tree = ksnp3_task.ksnp3_tree
    File ksnp3_vcf = ksnp3_task.ksnp3_vcf
    String ksnp3_docker = ksnp3_task.ksnp3_docker_image
  }
}
version 1.0

import "../tasks/task_phylo.wdl" as phylo

workflow ksnp3 {
	input {
		Array[File] assembly_fasta
    Array[String] samplename
    String cluster_name
	}
	call phylo.ksnp3 as ksnp3_task {
		input:
			assembly_fasta=assembly_fasta,
      samplename=samplename,
      cluster_name=cluster_name
	}
  call phylo.snp_dists {
    input:
      cluster_name = cluster_name,
      alignment = ksnp3_task.ksnp3_matrix
  }
  
    output {
      File    snp_matrix   = snp_dists.snp_matrix
      File    ksnp3_tree  = ksnp3_task.ksnp3_tree
      String   ksnp3_docker = ksnp3_task.ksnp3_docker_image
    }
}
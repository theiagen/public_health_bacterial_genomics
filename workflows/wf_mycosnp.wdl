version 1.0

import "../tasks/phylogenetic_inference/task_mycosnp.wdl" as mycosnp_nf

workflow mycosnp {
  meta {
    description: "A WDL wrapper around mycosnp-nf, for whole genome sequencing analysis of fungal organisms, including Candida auris."
  }
  input {
    File    read1
    File    read2
    String  samplename
  }
  call mycosnp_nf.mycosnp {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename
  }
  output {
    String mycosnp_version = mycosnp.mycosnp_version
    String mycosnp_docker = mycosnp.mycosnp_docker
    String analysis_date = mycosnp.analysis_date
    String reference_genome = mycosnp.reference_genome
    File assembly_fasta = mycosnp.assembly_fasta
    File full_results = mycosnp.full_results
  }
}

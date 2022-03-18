version 1.0

import "../tasks/phylogenetic_inference/task_mycosnptree.wdl" as mycosnptree_nf
import "../tasks/task_versioning.wdl" as versioning

workflow mycosnp_consensus_assembly {
  meta {
    description: "A WDL wrapper around the phylogeny components of mycosnp-nf, for whole genome sequencing analysis of fungal organisms, including Candida auris."
  }
  input {
    Array[String] samplename
    Array[File] assembly_fasta
	}
  call mycosnptree_nf.mycosnptree {
    input:
      assembly_fasta = assembly_fasta,
      samplename = samplename
  }
  call versioning.version_capture{
    input:
  }
  output {
    #Version Captures
    String mycosnptree_consensus_assembly_version = version_capture.phbg_version
    String mycosnptree_consensus_assembly_analysis_date = version_capture.date
    #MycoSNP QC and Assembly
    String mycosnptree_version = mycosnptree.mycosnptree_version
    String mycosnptree_docker = mycosnptree.mycosnptree_docker
    String analysis_date = mycosnptree.analysis_date
    String reference_strain = mycosnptree.reference_strain
    String reference_accession = mycosnptree.reference_accession
    File mycosnptree_tree = mycosnptree.mycosnptree_tree
    File mycosnptree_iqtree_log = mycosnptree.mycosnptree_iqtree_log
    File mycosnptree_full_results = mycosnptree.mycosnptree_full_results
  }
}

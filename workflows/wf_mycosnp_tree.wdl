version 1.0

import "../tasks/phylogenetic_inference/task_mycosnp_tree.wdl" as mycosnptree_nf
import "../tasks/task_versioning.wdl" as versioning

workflow mycosnp_tree {
  meta {
    description: "A WDL wrapper around the phylogeny components of mycosnp-nf, for whole genome sequencing analysis of fungal organisms, including Candida auris."
  }
  input {
    Array[File] vcf
    Array[File] vcf_index
  }
  call mycosnptree_nf.mycosnptree {
    input:
      vcf = vcf,
      vcf_index = vcf_index
  }
  call versioning.version_capture{
    input:
  }
  output {
    #Version Captures
    String mycosnp_tree_version = version_capture.phbg_version
    String mycosnp_tree_analysis_date = version_capture.date
    #MycoSNP QC and Assembly
    String mycosnp_version = mycosnptree.mycosnptree_version
    String mycosnp_docker = mycosnptree.mycosnptree_docker
    String analysis_date = mycosnptree.analysis_date
    String reference_strain = mycosnptree.reference_strain
    String reference_accession = mycosnptree.reference_accession
    File mycosnp_rapidnj_tree = mycosnptree.mycosnptree_rapidnj_tree 
    File mycosnp_fastree_tree = mycosnptree.mycosnptree_fasttree_tree
    File mycosnp_alignment = mycosnptree.mycosnptree_alignment
    File mycosnp_tree_full_results = mycosnptree.mycosnptree_full_results
  }
}

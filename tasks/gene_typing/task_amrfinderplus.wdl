version 1.0

task amrfinderplus {
  input {
    File assembly
    String samplename
    # Parameters 
    # --indent_min Minimum DNA %identity [0-1]; default is 0.9 (90%) or curated threshold if it exists
    # --mincov Minimum DNA %coverage [0-1]; default is 0.5 (50%)
    String? organism # keep as optional?
    Int? minid
    Int? mincov
    Int cpu = 4
  }
  command <<<
    date | tee DATE
    amrfinder --version | tee AMRFINDER_VERSION
    
    amrfinder --plus \
      ~{'--name ' + samplename} \
      ~{'--nucleotide ' + assembly} \
      ~{'--organism ' + organism} \# optional MUST HAVE CORRECT SYNTAX
      ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
      ~{'--threads ' + cpu} \
      ~{'--coverage_min ' + mincov} \
      ~{'--ident_min ' + minid} 
    
    # TODO add python code to parse out different types of results based on 'Element Type' column
    # Element Type possibilities: AMR, STRESS, and VIRULENCE 
  >>>
  output {
    File amrfinder_results = "~{samplename}_amrfinder_all.tsv"
    String amrfinder_organism = organism
    String amrfinder_version = read_string("AMRFINDER_VERSION")
  }
  runtime {
    memory: "8 GB"
    cpu: cpu
    docker: "quay.io/staphb/ncbi-amrfinderplus:3.10.20" # will eventually change to 3.10.24
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}

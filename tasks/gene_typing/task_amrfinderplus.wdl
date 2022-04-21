version 1.0

task amrfinderplus {
  input {
    File assembly
    String samplename
    # Parameters 
    # --indent_min Minimum DNA %identity [0-1]; default is 0.9 (90%) or curated threshold if it exists
    # --mincov Minimum DNA %coverage [0-1]; default is 0.5 (50%)
    String? organism # make optional?
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
    
    # create headers for 3 output files; tee to 3 files and redirect STDOUT to dev null so it doesn't print to log file
    head -n 1 ~{samplename}_amrfinder_all.tsv | tee ~{samplename}_amrfinder_stress.tsv ~{samplename}_amrfinder_virulence.tsv ~{samplename}_amrfinder_amr.tsv >/dev/null
    # looks for all rows with STRESS, AMR, or VIRULENCE and append to TSVs
    grep 'STRESS' ~{samplename}_amrfinder_all.tsv >>~{samplename}_amrfinder_stress.tsv
    grep 'VIRULENCE' ~{samplename}_amrfinder_all.tsv >>~{samplename}_amrfinder_virulence.tsv
    grep 'AMR' ~{samplename}_amrfinder_all.tsv >>~{samplename}_amrfinder_amr.tsv
  >>>
  output {
    File amrfinderplus_all_report = "~{samplename}_amrfinder_all.tsv"
    File amrfinderplus_amr_report = "~{samplename}_amrfinder_amr.tsv"
    File amrfinderplus_stress_report = "~{samplename}_amrfinder_stress.tsv"
    File amrfinderplus_virulence_report = "~{samplename}_amrfinder_virulence.tsv"
    #### commented out for now. Not sure how to output what organism was used if it was not defined as an input paramter
    # String amrfinder_organism = organism 
    String amrfinderplus_version = read_string("AMRFINDER_VERSION")
  }
  runtime {
    memory: "8 GB"
    cpu: cpu
    docker: "quay.io/staphb/ncbi-amrfinderplus:3.10.20" # will eventually change to 3.10.24
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}

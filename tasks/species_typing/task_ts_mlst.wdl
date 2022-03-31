version 1.0

task ts_mlst {
  meta {
    description: "Torsten Seeman's (TS) automatic MLST calling from assembled contigs"
  }
  input {
    File assembly
    String samplename
    String docker = "staphb/mlst:2.19.0"
    Int? cpu = 4
    # Parameters
    # --nopath          Strip filename paths from FILE column (default OFF)
    # --scheme [X]      Don't autodetect, force this scheme on all inputs (default '')
    # --minid [n.n]     DNA %identity of full allelle to consider 'similar' [~] (default '95')
    # --mincov [n.n]    DNA %cov to report partial allele at all [?] (default '10')
    # --minscore [n.n]  Minumum score out of 100 to match a scheme (when auto --scheme) (default '50')
    Boolean nopath = false
    String? scheme
    Float minid = 95.0
    Float mincov = 10.0
    Float minscore = 50.0
  }
  command <<<
    echo $(mlst --version 2>&1) | sed 's/mlst //' | tee VERSION
    
    #create output header
    echo -e "Filename\tPubMLST_Scheme_name\tSequence_Type_(ST)\tAllele_IDs" > ~{samplename}_ts_mlst.tsv
    
    mlst \
      --threads ~{cpu} \
      ~{true="--nopath" false="" nopath} \
      ~{'--scheme' + scheme} \
      ~{'--minid' + minid} \
      ~{'--mincov' + mincov} \
      ~{'--minscore' + minscore} \
      !{assembly} \
      >> ~{samplename}_ts_mlst.tsv
      
    # parse ts mlst tsv
    echo "ST$(cut -f 3 ~{samplename}_ts_mlst.tsv | tail -n 1)" > PREDICTED_MLST
    cut -f 2 ~{samplename}_ts_mlst.tsv | tail -n 1 | tee PUBMLST_SCHEME
  >>>
  output {
    File ts_mlst_results = "~{samplename}_ts_mlst.tsv"
    String ts_mlst_predicted_st = read_string("PREDICTED_MLST")
    String ts_mlst_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}

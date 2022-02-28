version 1.0

task abricate {
  input {
    File assembly
    String samplename
    String database
  }
  command <<<
    date | tee DATE
    abricate -v | tee ABRICATE_VERSION
    
    abricate --db ~{database} ~{assembly} > ~{samplename}_abricate_hits.tsv
    
  >>>
  output {
    File abricate_results = "~{samplename}_abricate_hits.tsv"
    String abricate_database = database
    String abricate_version = read_string("ABRICATE_VERSION")
  }
  runtime {
    memory: "8 GB"
    cpu: 4
    docker: "quay.io/staphb/abricate:1.0.0"
    disks: "local-disk 100 HDD"
  }
}

version 1.0

task shigatyper {
  meta {
    description: "ShigaTyper is a quick and easy tool designed to determine Shigella serotype using Illumina (single or paired-end) or Oxford Nanopore reads with low computation requirement. https://github.com/CFSAN-Biostatistics/shigatyper"
  }
  input {
    File read1 
    File? read2
    String samplename
    String docker = "staphb/shigatyper:2.0.1"
    Int cpus = 4
  }
  command <<<
    # get version information
    pbptyper --version | sed 's/pbptyper, //' | tee VERSION
    
    # run shigatyper
    shigatyper \
      ~{'--R1 ' + read1} \ 
      ~{'--R2 ' + read2} \
      ~{'--ont --SE ' + read1}
      -n ~{samplename}

    # run pbptyper
    pbptyper \
      --assembly ~{assembly} \
      ~{'--db ' + db} \
      ~{'--min_pident ' + min_pident} \
      ~{'--min_coverage ' + min_coverage} \
      --prefix "~{samplename}" \
      --outdir ./ 

    # parse output tsv for pbptype
    cut -f 2 ~{samplename}.tsv | tail -n 1 > pbptype.txt

  >>>
  output {
    String pbptyper_predicted_1A_2B_2X = read_string("pbptype.txt")
    File pbptyper_pbptype_predicted_tsv = "~{samplename}.tsv" # A tab-delimited file with the predicted PBP type
    File pbptyper_pbptype_1A_tsv = "~{samplename}-1A.tblastn.tsv" # A tab-delimited file of all blast hits against 1A
    File pbptyper_pbptype_2B_tsv = "~{samplename}-2B.tblastn.tsv" # A tab-delimited file of all blast hits against 2B
    File pbptyper_pbptype_2X_tsv = "~{samplename}-2X.tblastn.tsv" # A tab-delimited file of all blast hits against 2X
    String pbptyper_version = read_string("VERSION")
    String pbptyper_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: cpus
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

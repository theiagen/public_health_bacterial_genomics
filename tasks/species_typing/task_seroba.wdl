version 1.0

task seroba {
  input {
    File read1
    File? read2
    String samplename
  }
  command <<<
    # grab version
    seroba version > VERSION

    # database path will need to be changed if/when docker image is updated. 
    seroba runSerotyping /seroba-1.0.2/database/ ~{read1} ~{read2} ~{samplename}

    cut -f2 ~{samplename}/pred.tsv > SEROTYPE
    cut -f3 ~{samplename}/pred.tsv > CONTAMINATION
  >>>
  output {
    String seroba_version = read_string("VERSION")
    String seroba_serotype = read_string("SEROTYPE")
    String seroba_contamination = read_string("CONTAMINATION")
  }
  runtime {
    docker: "staphb/seroba:1.0.2"
    memory: "16 GB"
    cpu: 8
    disks: "local-disk 100 SSD"
  }
}
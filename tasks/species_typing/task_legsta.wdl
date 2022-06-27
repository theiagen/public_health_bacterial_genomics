version 1.0

task legsta {
  meta {
    description: "Typing of Legionella pneumophila assemblies"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/legsta:0.5.1--hdfd78af_2"
    Int? cpu = 2
  }
  command <<<
    echo $(legsta --version 2>&1) | sed 's/^.*legsta //; s/ .*\$//;' | tee VERSION
    legsta \
      ~{assembly} > ~{samplename}.tsv
    
    # parse outputs
    for i in 2 3 4 5 6 7 8 9 ; do
      ALLELE="$(head -n 1 ~{samplename}.tsv | cut -f $i)"
      ALLELE_NUM="$(tail -n 1 ~{samplename}.tsv | cut -f $i)"
      ALLELE_STRING+="${ALLELE}:${ALLELE_NUM},"
    done
    LEGSTA_ALLELES="$(echo $ALLELE_STRING | cut -d',' -f -8)"

  >>>
  output {
    File legsta_results = "~{samplename}.tsv"
    String legsta_alleles = read_string("LEGSTA_ALLELES")
    String legsta_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}

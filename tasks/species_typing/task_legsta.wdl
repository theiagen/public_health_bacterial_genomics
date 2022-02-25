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
      ~{assmebly} > ~{samplename}.tsv
  >>>
  output {
    File legsta_results = "~{samplename}.tsv"
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

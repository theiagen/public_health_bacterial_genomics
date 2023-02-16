version 1.0

task staphopiasccmec {
  meta {
    description: "Primer based SCCmec typing of Staphylococcus aureus genomes"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/staphopia-sccmec:1.0.0--hdfd78af_0"
    Int disk_size = 100
    Int cpu = 2
  }
  command <<<
    # get version
    staphopia-sccmec --version 2>&1 | sed 's/^.*staphopia-sccmec //' | tee VERSION

    # run staphopia-sccmec on input assembly; hamming option OFF; outputs are true/false
    staphopia-sccmec \
      --assembly ~{assembly} > ~{samplename}.staphopia-sccmec.summary.tsv

    # run staphopia-sccmec on input assembly; hamming option ON; outputs are the hamming distance; 0 is exact match
    staphopia-sccmec \
      --hamming \
      --assembly ~{assembly} > ~{samplename}.staphopia-sccmec.hamming.tsv

    # parse output summary TSV for true matches
    #~{samplename}.staphopia-sccmec.summary.tsv

  >>>
  output {
    File staphopiasccmec_results_tsv = "~{samplename}.staphopia-sccmec.summary.tsv"
    File staphopiasccmec_hamming_distance_tsv = "~{samplename}.staphopia-sccmec.hamming.tsv"
    #String staphopiasccmec_types_and_mecA_presence = readstring("")
    String staphopiasccmec_version = read_string("VERSION")
    String staphopiasccmec_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: cpu
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    maxRetries: 3
    preemptible: 0
  }
}

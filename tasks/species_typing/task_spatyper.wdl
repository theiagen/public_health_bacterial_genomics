version 1.0

task spatyper {
  meta {
    description: "Computational method for finding spa types in Staphylococcus aureus"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/spatyper:0.3.3--pyhdfd78af_3"
    Int disk_size = 100
    Int cpu = 4

    # Parameters
    # --do_enrich Do PCR product enrichment
    Boolean do_enrich = false
  }
  command <<<
    spaTyper --version 2>&1 | sed 's/^.*spaTyper //' | tee VERSION
    spaTyper \
      ~{true="--do_enrich" false="" do_enrich} \
      --fasta ~{assembly} \
      --output ~{samplename}.tsv
    
    cat ~{samplename}.tsv | tail -n1 | cut -f2 > REPEATS
    cat ~{samplename}.tsv | tail -n1 | cut -f3 > TYPE
  >>>
  output {
      File spatyper_tsv = "~{samplename}.tsv"
      String spatyper_repeats = read_string("REPEATS")
      String spatyper_type = read_string("TYPE")
      String spatyper_version = read_string("VERSION")
      String spatyper_docker = "~{docker}"
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

version 1.0

task busco {
  meta {
    description: "Run BUSCO on assemblies"
  }
  input {
    File assembly
    String samplename
    String docker = "ezlabgva/busco:v5.3.2_cv1"
    Boolean eukaryote = false

  }
  command <<<
    busco --version | tee "VERSION"

    busco \
      -i ~{assembly} \
      -m geno \
      -o ~{samplename} \
      ~{true='--auto-lineage-euk' false='--auto-lineage-prok' eukaryote}

    echo short_summary.specific.*.~{samplename}.txt | awk -F'.' '{ print $3 }' | tee DATABASE




  >>>
  output {
    String busco_version = read_string("VERSION")
    String busco_database = read_string("DATABASE")
    File busco_output = "short_summary.specific.*.~{samplename}.txt"

  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}
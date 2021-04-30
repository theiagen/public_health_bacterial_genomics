version 1.0

task midas_nsphl {
  input {
    File assembly
    String samplename
    String docker="theiagen/midas_nsphl:1.0.0"
  }
  command <<<
    # capture date and version
    date | tee DATE

    midas query ~{assembly} | tail -n2 > ~{samplename}_midas_nsphl.csv

  >>>
  output {
    File midas_nsphl_report = "~{samplename}_midas_nsphl.csv"
    String  midas_nsphl_docker   = docker
    String  pipeline_date = read_string("DATE")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "16 GB"
    cpu:   8
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

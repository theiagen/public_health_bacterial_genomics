version 1.0

task snp_dists {
  input {
    File alignment
    String cluster_name
  }
  command <<<
    # date and version control
    date | tee DATE
    snp-dists -v | tee VERSION

    snp-dists ~{alignment} > ~{cluster_name}_snp_distance_matrix.tsv
  >>>
  output {
    String date = read_string("DATE")
    String version = read_string("VERSION")
    File snp_matrix = "${cluster_name}_snp_distance_matrix.tsv"
  }
  runtime {
    docker: "quay.io/staphb/snp-dists:0.6.2"
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
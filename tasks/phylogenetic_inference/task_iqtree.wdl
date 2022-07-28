version 1.0

task iqtree {
  input {
    File alignment
    String cluster_name
    String iqtree_model = "HKY" # match bactopia, use GTR+F+I to match grandeur
    String iqtree_bootstraps = 1000 #  Ultrafast bootstrap replicates
    String alrt = 1000 # SH-like approximate likelihood ratio test (SH-aLRT) replicates
    Boolean asr = false # Ancestral state reconstruction by empirical Bayes
    String? iqtree_opts = ""
    String docker = "quay.io/biocontainers/iqtree:2.1.4_beta--hdcc8f71_0"
  }
  command <<<
    # date and version control
    date | tee DATE
    iqtree --version | grep version | sed 's/.*version/version/;s/ for Linux.*//' | tee VERSION

    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      cp ~{alignment} ./msa.fasta
      iqtree \
      -nt AUTO \
      -s msa.fasta \
      -m ~{iqtree_model} \
      -bb ~{iqtree_bootstraps} \
      -alrt ~{alrt} \
      ~{true="--asr" false="" asr} \
      iqtree_opts

      cp msa.fasta.contree ~{cluster_name}_msa.tree
    fi
  >>>
  output {
    String date = read_string("DATE")
    String version = read_string("VERSION")
    File ml_tree = "~{cluster_name}_msa.tree"
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

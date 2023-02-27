version 1.0

task srst2_vibrio {
  meta {
    description: "Computational method for finding spa types in Staphylococcus aureus"
  }
  input {
    File reads1
    File reads2
    String samplename
    String docker = "quay.io/kapsakcj/srst2:0.2.0-vcholerae" # TODO: Update with container including vibrio db
    Int disk_size = 100
    Int cpu = 4
  }
  command <<<
    srst2 --version 2>&1 | tee VERSION
    srst2 \
      --input_pe ~{reads1} ~{reads2} \
      --gene_db /vibrio-cholerae-db/vibrio_230224.fasta \
      --output ~{samplename}
    
    mv ~{samplename}__genes__*__results.txt ~{samplename}.tsv

    tail -n1 ~{samplename}.tsv | cut -f2 | cut -d_ -f2 > ctxA
    tail -n1 ~{samplename}.tsv | cut -f3 | cut -d_ -f2 > ompW
    tail -n1 ~{samplename}.tsv | cut -f4 | cut -d_ -f3 > tcpA_ElTor
    tail -n1 ~{samplename}.tsv | cut -f5 | cut -d_ -f2 > toxR
    tail -n1 ~{samplename}.tsv | cut -f6 | cut -d_ -f3 > wbeN_O1

  >>>
  output {
      File srst2_tsv = "~{samplename}.tsv"
      String srst2_version = read_string("VERSION")
      String srst2_vibrio_ctxA = read_string("ctxA")
      String srst2_vibrio_ompW = read_string("ompW")
      String srst2_vibrio_tcpA_ElTor = read_string("tcpA_ElTor")
      String srst2_vibrio_toxR = read_string("toxR")
      String srst2_vibrio_wbeN_O1 = read_string("wbeN_O1")
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
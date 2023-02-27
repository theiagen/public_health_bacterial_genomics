version 1.0

task srst2_vibrio {
  meta {
    description: "Computational method for finding spa types in Staphylococcus aureus"
  }
  input {
    File reads1
    File reads2
    String samplename
    String docker = "srst2-vibrio:latest" # TODO: Update with container including vibrio db
    Int disk_size = 100
    Int cpu = 4
  }
  command <<<
    srst2 --version 2>&1 | tee VERSION
    srst2 \
      --input_pe ~{reads1} ~{reads2} \
      --gene_db /data/vibrio_230224.fasta \
      --output ~{samplename}
    
    mv ~{samplename}__genes__*__results.txt ~{samplename}.tsv

    tail -n1 ~{samplename}.tsv | cut -f2 > ctxA
    tail -n1 ~{samplename}.tsv | cut -f3 > ompW
    tail -n1 ~{samplename}.tsv | cut -f4 > tcpA_ElTor
    tail -n1 ~{samplename}.tsv | cut -f5 > toxR
    tail -n1 ~{samplename}.tsv | cut -f5 > wbeN_O1

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
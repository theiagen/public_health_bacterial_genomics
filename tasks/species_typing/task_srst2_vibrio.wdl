version 1.0

task srst2_vibrio {
  meta {
    description: "Computational method for finding spa types in Staphylococcus aureus"
  }
  input {
    File reads1
    File? reads2
    String samplename
    String docker = "quay.io/kapsakcj/srst2:0.2.0-vcholerae" # TODO: Update with container including vibrio db
    Int disk_size = 100
    Int cpu = 4
  }
  command <<<
    if [ -z "~{reads2}" ] ; then
      INPUT_READS="--input_se ~{reads1}"
    else
      # This task expects/requires that input FASTQ files end in "_1.clean.fastq.gz" and "_2.clean.fastq.gz"
      # which is the syntax from TheiaProk read cleaning tasks
      INPUT_READS="--input_pe ~{reads1} ~{reads2} --forward _1.clean --reverse _2.clean"
    fi

    srst2 --version 2>&1 | tee VERSION
    srst2 \
      ${INPUT_READS} \
      --gene_db /vibrio-cholerae-db/vibrio_230224.fasta \
      --output ~{samplename}
    
    mv ~{samplename}__genes__*__results.txt ~{samplename}.tsv

    # change this parsing block to account for when output columns do not exist
    tail -n1 ~{samplename}.tsv | cut -f2 | cut -d_ -f2 > ctxA
    tail -n1 ~{samplename}.tsv | cut -f3 | cut -d_ -f2 > ompW
    tail -n1 ~{samplename}.tsv | cut -f4 | cut -d_ -f3 > tcpA_ElTor
    tail -n1 ~{samplename}.tsv | cut -f5 | cut -d_ -f2 > toxR
    tail -n1 ~{samplename}.tsv | cut -f6 | cut -d_ -f3 > wbeN_O1

    # capture detailed output TSV
    mv ~{samplename}__fullgenes__*__results.txt ~{samplename}.detailed.tsv
  >>>
  output {
      File srst2_tsv = "~{samplename}.tsv"
      File srst2_detailed_tsv = "~{samplename}.detailed.tsv"
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
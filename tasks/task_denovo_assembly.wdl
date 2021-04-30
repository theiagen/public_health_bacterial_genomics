version 1.0

task shovill_pe {
  input {
    File  read1_cleaned
    File  read2_cleaned
    String  samplename
    String  docker="staphb/shovill:1.1.0"
  }

  command <<<
    shovill --version | head -1 | tee VERSION
    shovill \
    --outdir out \
    --R1 ~{read1_cleaned} \
    --R2 ~{read2_cleaned}
    mv out/contigs.fa out/${samplename}_contigs.fasta
    mv out/contigs.gfa out/${samplename}_contigs.gfa
  >>>
  output {
	  File assembly_fasta = "out/~{samplename}_contigs.fasta"
	  File contigs_gfa = "out/{samplename}_contigs.gfa"
    String  shovill_version = read_string("VERSION")
  }

  runtime {
      docker: "~{docker}"
      memory: "16 GB"
      cpu: 4
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}

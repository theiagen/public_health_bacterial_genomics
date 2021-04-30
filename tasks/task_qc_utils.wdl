version 1.0

task fastqc_pe {
  input {
    File read1
    File read2
    String read1_name = basename(basename(basename(read1, ".gz"), ".fastq"), ".fq")
    String read2_name = basename(basename(basename(read2, ".gz"), ".fastq"), ".fq")
    Int? cpus = 2
    String docker="staphb/fastqc:0.11.8"
  }
  command <<<
    # capture date and version
    date | tee DATE
    fastqc --version | grep FastQC | tee VERSION

    fastqc --outdir $PWD --threads ~{cpus} ~{read1} ~{read2}

    unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ1_SEQS
    unzip -p ~{read2_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ2_SEQS

    READ1_SEQS=$(unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 )
    READ2_SEQS=$(unzip -p ~{read2_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 )

    if [ $READ1_SEQS == $READ2_SEQS ]; then
      read_pairs=$READ1_SEQS
    else
      read_pairs="Uneven pairs: R1=$READ1_SEQS, R2=$READ2_SEQS"
    fi
    echo $read_pairs | tee READ_PAIRS
  >>>
  output {
    File fastqc1_html = "~{read1_name}_fastqc.html"
    File fastqc1_zip = "~{read1_name}_fastqc.zip"
    File fastqc2_html = "~{read2_name}_fastqc.html"
    File fastqc2_zip = "~{read2_name}_fastqc.zip"
    Int read1_seq = read_string("READ1_SEQS")
    Int read2_seq = read_string("READ2_SEQS")
    String read_pairs = read_string("READ_PAIRS")
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "4 GB"
    cpu:   2
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}
task fastqc_se {
  input {
    File read1
    String read1_name = basename(basename(basename(read1, ".gz"), ".fastq"), ".fq")
    Int? cpus = 2
    String docker="staphb/fastqc:0.11.8"
  }
  command <<<
    # capture date and version
    date | tee DATE
    fastqc --version | grep FastQC | tee VERSION

    fastqc --outdir $PWD --threads ~{cpus} ~{read1}

    unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ1_SEQS

    READ_SEQS=$(unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 )
  >>>
  output {
    File fastqc_html = "~{read1_name}_fastqc.html"
    File fastqc_zip = "~{read1_name}_fastqc.zip"
    Int number_reads = read_string("READ1_SEQS")
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "4 GB"
    cpu:   2
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}
task quast {
  input {
    File assembly
    String samplename
    String docker="staphb/quast:5.0.2"
  }
  command <<<
    # capture date and version
    date | tee DATE
    quast.py --version | grep QUAST | tee VERSION

    quast.py ~{assembly} -o .
    mv report.tsv ~{samplename}_report.tsv

  >>>
  output {
    File quast_report = "${samplename}_report.tsv"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "2 GB"
    cpu:   2
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}
task cg_pipeline {
  input {
    File  read1
    File  read2
    String  samplename
    String  docker="staphb/lyveset:1.1.4f"
    String  cg_pipe_opts="--fast"
    Int genome_length
  }
  command <<<
    # date and version control
    date | tee DATE

    run_assembly_readMetrics.pl ~{cg_pipe_opts} ~{read1} ~{read2} -e ~{genome_length} > ~{samplename}_readMetrics.tsv
  >>>
  output {
    File  cg_pipe_readMetrics = "${samplename}_readMetrics.tsv"
    String  cg_pipe_docker   = docker
    String  pipeline_date = read_string("DATE")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}

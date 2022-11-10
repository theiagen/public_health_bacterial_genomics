version 1.0

task fastp {
  input {
    File read1
    File read2
    String samplename
    String docker = "quay.io/staphb/fastp:0.23.2"
    Int fastp_minlen =50
    Int fastp_window_size=20
    Int fastp_quality_trim_score=30
    # -g enables polyg trimming with default value of 10
    String? fastp_args = "--detect_adapter_for_pe -g -5 20 -3 20"
    Int? threads = 4
  }
  command <<<
    # date 
    date | tee DATE

    fastp \
    --in1 ~{read1} --in2 ~{read2} \
    --out1 ~{samplename}_1P.fastq.gz --out2 ~{samplename}_2P.fastq.gz \
    --unpaired1 ~{samplename}_1.fail.fastq.gz --unpaired2 ~{samplename}_2.fail.fastq.gz \
    --cut_right --cut_right_window_size ~{fastp_window_size} --cut_right_mean_quality ~{fastp_quality_trim_score} \
    --length_required ~{fastp_minlen} \
    --thread ~{threads} \
    ~{fastp_args} \
    --html ~{samplename}_fastp.html --json ~{samplename}_fastp.json
  >>>
  output {
    File read1_trimmed = "~{samplename}_1P.fastq.gz"
    File read2_trimmed = "~{samplename}_2P.fastq.gz"
    File read1_trimmed_unpaired = "~{samplename}_1U.fastq.gz"
    File read2_trimmed_unpaired = "~{samplename}_2U.fastq.gz"
    File fastp_stats = "~{samplename}_fastp.html"
    String version = "~{docker}"
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker: "quay.io/staphb/fastp:0.23.2"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
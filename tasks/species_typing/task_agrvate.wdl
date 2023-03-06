version 1.0

task agrvate {
  meta {
    description: "Rapid identification of Staphylococcus aureus agr locus type and agr operon variants."
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/agrvate:1.0.2--hdfd78af_0"
    Int disk_size = 50
    Int cpu = 1

    # Parameters
    # --typing_only    agr typing only. Skips agr operon extraction and frameshift detection
    Boolean typing_only = false
  }
  command <<<
    # get version info
    agrvate -v 2>&1 | sed 's/agrvate v//;' | tee VERSION

    # run agrvate on assembly; usearch not available in biocontainer, cannot use that option
    # using -m flag for mummer frameshift detection since usearch is not available
    agrvate \
        ~{true="--typing_only" false="" typing_only} \
        -i ~{assembly} \
        -m 
        
    # agrvate names output directory and file based on name of .fasta file, so <prefix>.fasta as input results in <prefix>-results/ outdir
    # and results in <prefix>-results/<prefix>-summary.tab files 
    basename=$(basename ~{assembly})
    # strip off anything after the period
    fasta_prefix=${basename%.*}
    
    # rename outputs summary TSV to include samplename
    mv -v "${fasta_prefix}-results/${fasta_prefix}-summary.tab" ~{samplename}.tsv

    # create tarball of all output files
    tar -czvf ~{samplename}.tar.gz "${fasta_prefix}-results/"
  >>>
  output {
    File agrvate_summary = "~{samplename}.tsv"
    File agrvate_results = "~{samplename}.tar.gz"
    String agrvate_version = read_string("VERSION")
    String agrvate_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "4 GB"
    cpu: cpu
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    maxRetries: 3
    preemptible: 0
  }
}

version 1.0

task mycosnp {
  input {
    File read1
    File read2
    String samplename
    String docker = "quay.io/theiagen/mycosnp:dev"
    String strain = "B11205"
    String accession = "GCA_016772135"
    Int memory = 16
    Int cpu = 4
  }
  command <<<
    date | tee DATE
    echo $(nextflow pull rpetit3/mycosnp-nf 2>&1) | sed 's/^.*revision: //;' | tee MYCOSNP_VERSION

    # Make sample FOFN
    echo "sample,fastq_1,fastq_2" > sample.csv
    echo "~{samplename},~{read1},~{read2}" >> sample.csv

    # Run MycoSNP
    mkdir ~{samplename}
    cd ~{samplename}
    if nextflow run rpetit3/mycosnp-nf --input ../sample.csv --ref_dir /reference/~{accession} --publish_dir_mode copy --skip_phylogeny; then
      # Everything finished, pack up the results and clean up
      rm -rf .nextflow/ work/
      cd ..
      tar -cf - ~{samplename}/ | gzip -n --best > ~{samplename}.tar.gz
    else
      # Run failed
      exit 1
    fi

    # QC Metrics
    csvtk transpose -t ~{samplename}/results/stats/qc_report/qc_report.txt > tqc_report.txt
    grep "^# Reads Before Trimming" tqc_report.txt | cut -f2 | tee MYCOSNP_READS_RAW
    grep "^GC Before Trimming" tqc_report.txt | cut -f2 | sed 's/%//' | tee MYCOSNP_GC_RAW
    grep "^Average Phred Before Trimming" tqc_report.txt | cut -f2 | tee MYCOSNP_PHRED_RAW
    grep "^Coverage Before Trimming" tqc_report.txt | cut -f2 | tee MYCOSNP_COVERAGE_RAW
    grep "^# Reads After Trimming" tqc_report.txt | cut -f2 | cut -f1 -d " " | tee MYCOSNP_READS_CLEAN
    grep "^# Paired Reads After Trimming" tqc_report.txt | cut -f2 | cut -f1 -d " " | tee MYCOSNP_READ_PAIRS_CLEAN
    grep "^# Unpaired Reads After Trimming" tqc_report.txt | cut -f2 | cut -f1 -d " " | tee MYCOSNP_READ_UNPAIRED_CLEAN
    grep "^GC After Trimming" tqc_report.txt | cut -f2 | sed 's/%//' | tee MYCOSNP_GC_CLEAN
    grep "^Average Phred After Trimming" tqc_report.txt | cut -f2 | tee MYCOSNP_PHRED_CLEAN
    grep "^Coverage After Trimming" tqc_report.txt | cut -f2 | tee MYCOSNP_COVERAGE_CLEAN

    # Assembly Metrics
    zcat ~{samplename}/results/combined/consensus/~{samplename}.fasta.gz | grep -v "^>" | grep -o "N" | wc -l | tee NUMBER_NS
    zcat ~{samplename}/results/combined/consensus/~{samplename}.fasta.gz | grep -v "^>" | grep -o "." | wc -l | tee ASSEMBLY_SIZE
  >>>
  output {
    String mycosnp_version = read_string("MYCOSNP_VERSION")
    String mycosnp_docker = docker
    String analysis_date = read_string("DATE")
    String reference_strain = strain
    String reference_accession = accession
    Int read_raw = read_int("MYCOSNP_READS_RAW")
    Float gc_raw = read_float("MYCOSNP_GC_RAW")
    Float phred_raw = read_float("MYCOSNP_PHRED_RAW")
    Float coverage_raw = read_float("MYCOSNP_COVERAGE_RAW")
    Int read_clean = read_int("MYCOSNP_READS_CLEAN")
    Int read_pairs_clean = read_int("MYCOSNP_READ_PAIRS_CLEAN")
    Int read_unpaired_clean = read_int("MYCOSNP_READ_UNPAIRED_CLEAN")
    Float gc_clean = read_float("MYCOSNP_GC_CLEAN")
    Float phred_clean = read_float("MYCOSNP_PHRED_CLEAN")
    Float coverage_clean = read_float("MYCOSNP_COVERAGE_CLEAN")
    Int number_n = read_int("NUMBER_NS")
    Int assembly_size = read_int("ASSEMBLY_SIZE")
    File assembly_fasta = "~{samplename}/results/combined/consensus/~{samplename}.fasta.gz"
    File vcf = "~{samplename}/results/samples/~{samplename}/variant_calling/haplotypecaller/~{samplename}.g.vcf.gz"
    File vcf_index = "~{samplename}/results/samples/~{samplename}/variant_calling/haplotypecaller/~{samplename}.g.vcf.gz.tbi"
    File multiqc = "~{samplename}/results/multiqc/multiqc_report.html"
    File full_results = "~{samplename}.tar.gz"
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks:  "local-disk 50 SSD"
    maxRetries: 3
    preemptible: 0
  }
}

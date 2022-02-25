version 1.0

task kleborate {
  meta {
    description: "Screening Klebsiella genome assemblies for MLST, sub-species, and other Klebsiella related genes of interest"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/kleborate:2.1.0--pyhdfd78af_1"
    Int? cpu = 4

    # Parameters
    # --resistance                      Turn on resistance genes screening (default: no resistance gene screening)
    # --kaptive                         Equivalent to --kaptive_k --kaptive_
    # --min_identity MIN_IDENTITY           Minimum alignment percent identity for main results (default: 90.0)
    # --min_coverage MIN_COVERAGE           Minimum alignment percent coverage for main results (default: 80.0)
    # --min_spurious_identity MIN_SPURIOUS_IDENTITY  Minimum alignment percent identity for spurious results (default: 80.0)
    # --min_spurious_coverage MIN_SPURIOUS_COVERAGE  Minimum alignment percent coverage for spurious results (default: 40.0)
    # --min_kaptive_confidence {None,Low,Good,High,Very_high,Perfect}  Minimum Kaptive confidence to call K/O loci - confidence levels below this will be reported as unknown (default: Good)
    Boolean skip_resistance = false
    Boolean skip_kaptive = false
    Float min_identity = 90.0
    Float min_coverage = 80.0
    Float min_spurious_identity = 80.0
    Float min_spurious_coverage = 40.0
    String min_kaptive_confidence = "Good"
  }
  command <<<
    kleborate --version | sed 's/Kleborate v//;' | tee VERSION
    kleborate \
      ${true="" false="--resistance" skip_resistance} \
      ${true="" false="--kaptive" skip_kaptive} \
      ${'--min_identity' + min_identity} \
      ${'--min_coverage' + min_coverage} \
      ${'--min_spurious_identity' + min_spurious_identity} \
      ${'--min_spurious_coverage' + min_spurious_coverage} \
      ${'--min_kaptive_confidence' + min_kaptive_confidence} \
      --outfile ~{samplename}.tsv \
      --assemblies ~{assembly}
  >>>
  output {
    File kleborate_results = "~{samplename}.tsv"
    String kleborate_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}

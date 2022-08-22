version 1.0

task kaptive {
  # Inputs
  input {
    File assembly
    String reference_loci_k = "/kaptive/reference_database/Acinetobacter_baumannii_k_locus_primary_reference.gbk"
    String reference_loci_oc = "/kaptive/reference_database/Acinetobacter_baumannii_OC_locus_primary_reference.gbk"
    String samplename
    String kaptive_docker_image = "quay.io/staphb/kaptive:2.0.3"
    # Parameters
    # --resistance                      Turn on resistance genes screening (default: no resistance gene screening)
    # --min_identity MIN_IDENTITY           Minimum alignment percent identity for main results (default: 80.0)
    # --min_coverage MIN_COVERAGE           Minimum alignment percent coverage for main results (default: 90.0)
    Float min_identity = 90.0
    Float min_coverage = 80.0
  }

  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    kaptive --version | tee VERSION 
    # Run Kaptive on the input assembly with the --all flag and output with samplename prefix
    kaptive \
    ~{'--min_identity ' + min_identity} \
    ~{'--min_coverage ' + min_coverage} \
    --no_seq_out \
    --no_json \
    --out ~{samplename}_kaptive_out_k \
    --assembly ~{assembly} \
    --k_refs ~{reference_loci_k}
    # parse outputs
    python3 <<CODE
    import csv
    with open("./~{samplename}_kaptive_out_k_table.txt",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("BEST_MATCH_LOCUS_K", 'wt') as Best_Match_Locus_K:
        kaptive_locus_k=tsv_dict['Best match locus']
        Best_Match_Locus_K.write(kaptive_locus_k)
      with open ("MATCH_CONFIDENCE_K", 'wt') as Match_Confidence_K:
        kaptive_confidence_k=tsv_dict['Match confidence']
        Match_Confidence_K.write(kaptive_confidence_k)
      with open ("NUM_EXPECTED_INSIDE_K", 'wt') as Num_Expected_Inside_K:
        expected_count_inside_k=tsv_dict['Expected genes in locus']
        Num_Expected_Inside_K.write(expected_count_inside_k)
      with open ("EXPECTED_GENES_IN_LOCUS_K", 'wt') as Expected_Inside_K:
        expected_in_k=tsv_dict['Expected genes in locus, details']
        Expected_Inside_K.write(expected_in_k)
      with open ("NUM_EXPECTED_OUTSIDE_K", 'wt') as Num_Expected_Outside_K:
        expected_count_outside_k=tsv_dict['Expected genes outside locus']
        Num_Expected_Outside_K.write(expected_count_outside_k)
      with open ("EXPECTED_GENES_OUT_LOCUS_K", 'wt') as Expected_Outside_K:
        expected_out_k=tsv_dict['Expected genes outside locus, details']
        Expected_Outside_K.write(expected_out_k)
      with open ("NUM_OTHER_INSIDE_K", 'wt') as Num_Other_Inside_K:
        other_count_inside_k=tsv_dict['Other genes in locus']
        Num_Other_Inside_K.write(other_count_inside_k)
      with open ("OTHER_GENES_IN_LOCUS_K", 'wt') as Other_Inside_K:
        other_in_k=tsv_dict['Other genes in locus, details']
        Other_Inside_K.write(other_in_k)
      with open ("NUM_OTHER_OUTSIDE_K", 'wt') as Num_Other_Outside_K:
        other_count_outside_k=tsv_dict['Other genes outside locus']
        Num_Other_Outside_K.write(other_count_outside_k)
      with open ("OTHER_GENES_OUT_LOCUS_K", 'wt') as Other_Outside_K:
        other_out_k=tsv_dict['Expected genes outside locus, details']
        Other_Outside_K.write(other_out_k)
    CODE
  >>>
  output {
    File kaptive_output_file = "{samplename}_kaptive_out_k_table.txt"
    String kaptive_version = read_string("VERSION")
    String kaptive_k_match = read_string("BEST_MATCH_LOCUS_K")
    String kaptive_k_confidence = read_string("MATCH_CONFIDENCE")
    String kaptive_k_expected_inside_count = read_string("NUM_EXPECTED_INSIDE_K")
    String kaptive_k_expected_inside_genes = read_string("EXPECTED_GENES_IN_LOCUS_K")
    String kaptive_k_expected_outside_count = read_string("NUM_EXPECTED_OUTSIDE_K")
    String kaptive_k_expected_outside_genes = read_string("EXPECTED_GENES_OUT_LOCUS_K")
    String kaptive_k_other_inside_count = read_string("NUM_OTHER_INSIDE_K")
    String kaptive_k_other_inside_genes = read_string("OTHER_GENES_IN_LOCUS_K")
    String kaptive_k_other_outside_count = read_string("NUM_OTHER_OUTSIDE_K")
    String kaptive_k_other_outside_genes = read_string("OTHER_GENES_OUT_LOCUS_K")
  }
  runtime {
    docker:       "~{kaptive_docker_image}"
    memory:       "16 GB"
    cpu:          8
    disks:        "local-disk 100 SSD"
  }
}
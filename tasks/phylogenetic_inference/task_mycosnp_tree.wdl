version 1.0

task mycosnptree {
  input {
    Array[File] vcf
    Array[File] vcf_index
    String docker="quay.io/theiagen/mycosnp:dev"
    String strain="B11205"
    String accession="GCA_016772135"
  }
  command <<<
    date | tee DATE
    echo $(nextflow pull rpetit3/mycosnp-nf 2>&1) | sed 's/^.*revision: //;' | tee MYCOSNPTREE_VERSION

    vcf_array=(~{sep=' ' vcf})
    vcf_array_len=$(echo "${#vcf[@]}")
    vcf_index_array=(~{sep=' ' vcf_index})
    vcf_index_array_len=$(echo "${#vcf_index[@]}")

    # Ensure vcf, vcf_index, and samplename arrays are of equal length
    if [ "$vcf_array_len" -ne "$vcf_index_array_len" ]; then
      echo "VCF array (length: $vcf_array_len) and VCF index array (length: $vcf_index_array_len) are of unequal length." >&2
      exit 1
    fi

    # Make sample FOFN
    touch samples.csv
    for index in ${!vcf_array[@]}; do
      vcf=${vcf_array[$index]}
      echo -e "${vcf}" >> samples.csv
    done

    # Run MycoSNP
    mkdir mycosnptree
    cd mycosnptree
    if nextflow run rpetit3/mycosnp-nf --add_vcf_file ../samples.csv --ref_dir /reference/~{accession} --publish_dir_mode copy; then
      # Everything finished, pack up the results and clean up
      rm -rf .nextflow/ work/
      cd ..
      tar -cf - mycosnptree/ | gzip -n --best  > mycosnptree.tar.gz
    else
      # Run failed
      exit 1
    fi
  >>>
  output {
    String mycosnptree_version = read_string("MYCOSNPTREE_VERSION")
    String mycosnptree_docker = docker
    String analysis_date = read_string("DATE")
    String reference_strain = strain
    String reference_accession = accession
    File mycosnptree_rapidnj_tree = "mycosnptree/results/combined/phylogeny/rapidnj/rapidnj_phylogeny.tre"
    File mycosnptree_fasttree_tree = "mycosnptree/results/combined/phylogeny/fasttree/fasttree_phylogeny.tre"
    File mycosnptree_alignment = "mycosnptree/results/combined/vcf-to-fasta/combined-tree_vcf-to-fasta.fasta"
    File mycosnptree_full_results = "mycosnptree.tar.gz"
  }
  runtime {
    docker: "~{docker}"
    memory: "32 GB"
    cpu: 4
    disks:  "local-disk 50 SSD"
    maxRetries: 3
    preemptible: 0
  }
}

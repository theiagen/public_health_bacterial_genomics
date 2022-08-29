version 1.0

task nullarbor_tsv {
  #Inputs
  input { 
    String run_name = "run1"
    File ref_genome
    Array[File] read1
    Array[File] read2
    Array[String] samplename
    String tree_builder = "iqtree_fast"
    String assembler = "skesa"
    String taxoner = "kraken2"
    String docker = "quay.io/biocontainers/nullarbor:2.0.20191013--hdfd78af_3"
    Int memory = 128
    Int cpu = 16
    File kraken1_db = "gs://theiagen-public-files/terra/theiaprok-files/minikraken_20171019_8GB_kraken1.tgz"
    File kraken2_db = "gs://theiagen-public-files/terra/theiaprok-files/k2_standard_8gb_20210517.tar.gz"
    File centrifuge_db = "gs://theiagen-public-files/terra/theiaprok-files/p_compressed+h+v.tar.gz"
  }
  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    nullarbor.pl --version | tee VERSION 
    #untar taxoner
    mkdir k1_db
    mkdir k2_db
    mkdir cent_db

    echo one
    tar -C k1_db -xzvf ~{kraken1_db}
    tar -C k2_db -xzvf ~{kraken2_db}
    tar -C cent_db -xzvf ~{centrifuge_db}
    mv cent_db/p_compressed+h+v.1.cf cent_db.1.cf
    mv cent_db/p_compressed+h+v.2.cf cent_db.2.cf
    mv cent_db/p_compressed+h+v.3.cf cent_db.3.cf
    mv k1_db/minikraken_20171019_8GB/* k1_db/

    echo two
    
    echo three
    echo pwd
    pwd
    #assign dbs for taxoners
    export KRAKEN_DEFAULT_DB=k1_db
    export KRAKEN2_DEFAULT_DB=k2_db
    export KRAKEN2_DB_PATH=k2_db
    export CENTRIFUGE_DEFAULT_DB=cent_db
    echo four
    read1_array=(~{sep=' ' read1})
    read1_array_len=$(echo "${#read1_array[@]}")
    read2_array=(~{sep=' ' read2})
    read2_array_len=$(echo "${#read2_array[@]}")
    samplename_array=(~{sep=' ' samplename})
    samplename_array_len=$(echo "${#samplename_array[@]}")
    
    # Ensure assembly, and samplename arrays are of equal length
    if [ "$read1_array_len" -ne "$samplename_array_len" ]; then
      echo "Read1 array array (length: $read1_array_len) and samplename array (length: $samplename_array_len) are of unequal length." >&2
      exit 1
    fi

    if [ "$read2_array_len" -ne "$samplename_array_len" ]; then
      echo "Read2 array (length: $read2_array_len) and samplename array (length: $samplename_array_len) are of unequal length." >&2
      exit 1
    fi

  # create file of filenames for kSNP3 input
  touch nullarbor_input.tsv
    for index in ${!read1_array[@]}; do
    read1=${read1_array[$index]}
    read2=${read2_array[$index]}
    samplename=${samplename_array[$index]}
    
    echo -e "${samplename}\t${read1}\t${read2}" >> nullarbor_input.tsv
  done
    # Run check for the log
    touch ~{run_name}.nullarbor_check.txt
    nullarbor.pl --check >> ~{run_name}.nullarbor_check.txt
    # Run Nullarbor on the input assembly with the --all flag
    nullarbor.pl \
        --name ~{run_name} \
        --ref ~{ref_genome} \
        --input nullarbor_input.tsv \
        --outdir nullarbor_outdir \
        --assembler ~{assembler} \
        --treebuilder ~{tree_builder} \
        --taxoner ~{taxoner} \
        --summary \
        --verbose
    #Run makefile
    make preview -C nullarbor_outdir/
    nice make all -j 2 -l 4 -C nullarbor_outdir/ 2>&1 | tee -a nullarbor_outdir/nullarbor.log

    echo "nullarbor complete,tarballing results now"

    tar -cf - nullarbor_outdir/ | gzip -n best > ~{run_name}.tar.gz

  >>>
   output {
    String nullarbor_version = read_string("VERSION")
    String nullarbor_docker = "~{docker}"
    String analysis_date = read_string("DATE")
    File nullarbor_components = "nullarbor_outdir/~{run_name}.nullarbor_check.txt"
    File nullarbor_report = "nullarbor_outdir/report/~{run_name}.html"
    File nullarbor_output_dir = "~{run_name}.tar.gz"
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 500 SSD"
      preemptible: 0
  }
}

version 1.0

task nullarbor_tsv {
  #Inputs
  input { 
    String run_name = "run1"
    File ref_genome
    File read_paths_file
    String tree_builder = "iqtree_fast"
    String assembler = "skesa"
    String taxoner = "kraken2"
    String docker = "quay.io/biocontainers/nullarbor:2.0.20191013--hdfd78af_3"
    String mode = "all"
    Int memory = 128
    Int cpu = 16
    String kraken1_db = "gs://theiagen-public-files/terra/theiaprok-files/minikraken2_v2_8GB_201904.tgz"
    String kraken2_db = "gs://theiagen-public-files/terra/theiaprok-files/k2_eupathdb48_20201113.tar.gz"
    String centrifuge_db = "gs://theiagen-public-files/terra/theiaprok-files/p_compressed+h+v.tar.gz"
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
    tar -C ./k1_db/ -xzvf ~{kraken1_db}
    tar -C ./k2_db/ -xzvf ~{kraken2_db}
    tar -C ./cent_db/ -xzvf ~{centrifuge_db}
    #assign dbs for taxoners
    export KRAKEN_DEFAULT_DB=./k1_db/
    export KRAKEN2_DEFAULT_DB=./k2_db/
    export CENTRIFUGE_DEFAULT_DB=./cent_db/
    # Run check for the log
    nullarbor.pl --check > ~{run_name}.nullarbor_check.txt
    # Run Nullarbor on the input assembly with the --all flag
    nullarbor.pl \
        --name ~{run_name} \
        --ref ~{ref_genome} \
        --input ~{read_paths_file} \
        --outdir ./nullarbor_outdir/ \
        --treebuilder ~{treebuilder} \
        --taxoner ~{taxoner} \
        --mode ~{mode}
    nice make all -j 2 -l 4 -C ~{outdir} 2>&1 | tee -a ~{outdir}/nullarbor.log
    make preview -C ~{outdir}
        # add line to zip entire output dir and save as ~{run_name}.output_dir.zip
  >>>
   output {
    String nullarbor_version = read_string("VERSION")
    String nullarbor_docker = docker
    String analysis_date = read_string("DATE")
    File nullarbor_components = "./nullarbor_outdir/~{run_name}.nullarbor_check.txt"
    File nullarbor_report = "./nullarbor_outdir/report/~{run_name}.html"
    #File nullarbor_output_dir = " ~{run_name}.output_dir.zip"
    
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}

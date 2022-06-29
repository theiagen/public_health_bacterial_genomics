version 1.0

task nullarbor {
  #Inputs
  input {
    String run_name = "run1"
    File ref_genome
    File read_paths_file
    String tree_builder = "iqtree_fast"
    String assembler = "skesa"
    String taxoner = "kraken2"
    String nullarbor_docker_image = "staphb/nullarbor:latest"
    String kraken_db = "gsutil_uri"
    String kraken2_db = "gsutil_uri"
    String centrifuge_db = "gsutil_uri"
  }
  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    nullarbor.pl --version | tee VERSION 
    #assign dbs for taxoners
    KRAKEN_DEFAULT_DB="/kraken-db"
    KRAKEN2_DEFAULT_DB="/kraken2-db"
    CENTRIFUGE_DEFAULT_DB="/centrifuge-db"
    # Run Nullarbor on the input assembly with the --all flag
    nullarbor.pl \
    --name ~{run_name} \
    --ref ~{ref_genome} \
    --input ~{read_paths_file} \
    --outdir ./path/to/target/outdir/nullarbor_outdir/ \
    --treebuilder iqtree_slow \
    --taxoner kraken2 \
    --mode all \
    --run
    # parse outputs
}
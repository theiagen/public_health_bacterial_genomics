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
  }
  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    nullarbor.pl --version | tee VERSION 
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
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
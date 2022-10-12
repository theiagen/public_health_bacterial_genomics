version 1.0

task midas {
  input {
    File read1
    File read2
    File midas_db = "gs://theiagen-public-files-rp/terra/theiaprok-files/midas/midas_db_v1.2.tar.gz"
    String samplename
    String docker = "quay.io/fhcrc-microbiome/midas:v1.3.2--6"
    Int? memory = 32
    Int? cpu = 4
  }
  command <<<
    date | tee DATE

    # Decompress the Midas database
    mkdir db
    tar -C ./db/ -xzvf ~{midas_db}  

    # Run Midas
    run_midas.py species ~{samplename} -1 ~{read1} -2 ~{read2} -d db/midas_db_v1.2/ -t ~{cpu} 

    # rename output files
    mv ~{samplename}/species/species_profile.txt ~{samplename}/species/~{samplename}_species_profile.txt
    mv ~{samplename}/species/log.txt ~{samplename}/species/~{samplename}_log.txt

    # determine if secondary species
    # filter rows where coverage is less than 1.0
    awk -F "\t" '{ if(($3 >1.0)) { print } }' ~{samplename}/species/~{samplename}_species_profile.txt > output.tsv

    # get primary species: sort by coverage (descending), get top non-header row, cut for species_ID column, parse column to get only species name
    primary_species=$(cat output.tsv | sort -k 3 -r | awk 'NR==2' | cut -f1 | cut -f1-2 -d"_")

    # filter to remove lines with primary species
    grep -v -F "$primary_species" output.tsv > output1.tsv

    # get secondary species: sort by coverage again to be safe, get top non-header row, cut for species_ID column, parse column to get only species name
    secondary_species=$(cat output1.tsv | sort -k 3 -r | awk 'NR==2' | cut -f1 | cut -f1-2 -d"_")
    # get coverage of secondary species
    secondary_species_coverage=$(cat output1.tsv | sort -k 3 -r | awk 'NR==2' | cut -f3 )

    # indicate if no secondary species was detected
    if [ -z "${secondary_species}" ]; then
       secondary_species="No secondary species detected (>1.0X coverage)"
       secondary_species_coverage="No secondary species detected (>1.0X coverage)"
    fi
    
    # create final output strings
    echo "${primary_species}" > PRIMARY_SPECIES
    echo "${secondary_species}" > SECONDARY_SPECIES
    echo "${secondary_species_coverage}" > SECONDARY_SPECIES_COVERAGE

  >>>
  output {
    String midas_docker = docker
    String midas_analysis_date = read_string("DATE")
    File midas_report = "~{samplename}/species/~{samplename}_species_profile.txt"
    File midas_log = "~{samplename}/species/~{samplename}_log.txt"
    String midas_primary_species = read_string("PRIMARY_SPECIES")
    String midas_secondary_species = read_string("SECONDARY_SPECIES")
    String midas_secondary_species_coverage = read_string("SECONDARY_SPECIES_COVERAGE")
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}
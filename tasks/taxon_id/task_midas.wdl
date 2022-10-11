version 1.0

task midas {
  input {
    File read1
    File read2
    File midas_db = "gs://theiagen-public-files-rp/terra/theiaprok-files/midas"
    String samplename
    String docker = "quay.io/biocontainers/midas:1.3.2--pyh5e36f6f_6"
    Int? memory = 32
    Int? cpu = 4
  }
  command <<<
    date | tee DATE

    # Decompress the Midas database
    mkdir db
    tar -C ./db/ -xzvf ~{midas_db}  

    # Run Midas
    run_midas.py species \
        ~{samplename} \ # output directory
        -d ./db/midas_db_v1.2/ \
        -1 ~{read1} \
        -2 ~{read2} \
        -t ~{cpu} 

    # rename output files
    mv ~{samplename}/species/species_profile.txt ~{samplename}/species/~{samplename}_species_profile.txt
    mv ~{samplename}/species/log.txt ~{samplename}/species/~{samplename}_log.txt

    # parse output files to primary and secondary species abundance strings
    primary_species=$(awk -F '\t' '{ print $1 }' species_profile.txt | head -2 | tail -1 )
    primary_species_abundance=$(awk -F '\t' '{ print $4 }' species_profile.txt | head -2 | tail -1 )
    secondary_species=$(awk -F '\t' '{ print $1 }' species_profile.txt | head -3 | tail -1 )
    secondary_species_abundance=$(awk -F '\t' '{ print $4 }' species_profile.txt | head -3 | tail -1 )

    # create final output strings
    echo "${primary_species}" > PRIMARY_SPECIES
    echo "${primary_species_abundance}" > PRIMARY_SPECIES_ABUNDANCE
    echo "${secondary_species}" > SECONDARY_SPECIES
    echo "${secondary_species_abundance}" > SECONDARY_SPECIES_ABUNDANCE

  >>>
  output {
    String midas_docker = docker
    String midas_analysis_date = read_string("DATE")
    File midas_report = "~{samplename}/species/~{samplename}_species_profile.txt"
    File midas_log = "~{samplename}/species/~{samplename}_log.txt"
    String midas_primary_species = read_string("PRIMARY_SPECIES")
    String midas_primary_species_abundance = read_string("PRIMARY_SPECIES_ABUNDANCE")
    String midas_secondary_species = read_string("SECONDARY_SPECIES")
    String midas_secondary_species_abundance = read_string("SECONDARY_SPECIES_ABUNDANCE")
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}
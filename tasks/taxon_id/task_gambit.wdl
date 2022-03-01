version 1.0

task gambit {
  input {
    File assembly
    String samplename
    String docker = "quay.io/staphb/gambit:0.3.0"
    File? gambit_db_genomes
    File? gambit_db_signatures
  }
  
  command <<<
    # capture date and version
    date | tee DATE
    gambit --version | tee GAMBIT_VERSION
    
    # set gambit reference dir; will assume that gambit genomes and signatures will be provided by user in tandem or not at all
    if [[ ! -z "~{gambit_db_genomes}" ]]; then 
      echo "User gabmit db identified; ~{gambit_db_genomes} will be utilized for alignment"
      gambit_db_version="$(basename -- '~{gambit_db_genomes}'); $(basename -- '~{gambit_db_signatures}')"
      gambit_db_dir="${PWD}/gambit_database"
      mkdir ${gambit_db_dir}
      cp ~{gambit_db_genomes} ${gambit_db_dir}
      cp ~{gambit_db_signatures} ${gambit_db_dir}
    else
     gambit_db_dir="/gambit-db" 
     gambit_db_version="unmodified from freyja container: ~{docker}"
    fi
    
    echo ${gambit_db_version} | tee GAMBIT_DB_VERSION
    
    gambit -d ${gambit_db_dir} query -o ~{samplename}_gambit.csv ~{assembly} 
    
    python3 <<CODE
    import csv
    #grab output genome length and number contigs by column header
    with open("~{samplename}_gambit.csv",'r') as csv_file:
      csv_reader = list(csv.DictReader(csv_file, delimiter=","))
      for line in csv_reader:
        with open ("CLOSEST_DISTANCE", 'wt') as gambit_distance:
          top_score=float(line["closest.distance"])
          top_score="{:.4f}".format(top_score)
          gambit_distance.write(str(top_score))
        with open("PREDICTED_RANK", 'wt') as gambit_rank:
          predicted_rank=line["predicted.rank"]
          if not predicted_rank:
            predicted_rank="None"
          gambit_rank.write(predicted_rank)
        with open("PREDICTED_TAXON", 'wt') as gambit_taxon:
          predicted_taxon=line["predicted.name"]
          if not predicted_taxon:
            predicted_taxon="None"
          gambit_taxon.write(predicted_taxon)
    CODE
    # set merlin tags
    predicted_taxon=$(cat PREDICTED_TAXON)
    if [[ ${predicted_taxon} == *"Escherichia"* ]] || [[ ${predicted_taxon} == *"Shigella"* ]] ; then 
      merlin_tag="Escherichia"
    elif [[ ${predicted_taxon} == *"Haemophilus"* ]]; then 
      merlin_tag="Haemophilus"
    elif [[ ${predicted_taxon} == *"Klebsiella"* ]]; then 
      merlin_tag="Klebsiella"
    elif [[ ${predicted_taxon} == *"Legionella"* ]]; then 
      merlin_tag="Legionella"
    elif [[ ${predicted_taxon} == *"Listeria"* ]]; then 
      merlin_tag="Listeria"
    elif [[ ${predicted_taxon} == *"Mycobacterium"* ]]; then 
      merlin_tag="Mycobacterium"
    elif [[ ${predicted_taxon} == *"Neisseria"* ]]; then 
      merlin_tag="Neisseria"
    elif [[ ${predicted_taxon} == *"Salmonella"* ]]; then 
      merlin_tag="Salmonella"
    elif [[ ${predicted_taxon} == *"Staphylococcus"* ]]; then 
      merlin_tag="Staphylococcus"
    elif [[ ${predicted_taxon} == *"Streptococcus"* ]]; then 
      merlin_tag="Streptococcus"
    else 
      merlin_tag="None"
    fi
    echo ${merlin_tag} | tee MERLIN_TAG
  >>>
  output {
    File gambit_report_file = "~{samplename}_gambit.csv"
    Float gambit_closest_distance = read_float("CLOSEST_DISTANCE") 
    String gambit_predicted_taxon = read_string("PREDICTED_TAXON")
    String gambit_predicted_rank = read_string("PREDICTED_RANK")
    String gambit_version = read_string("GAMBIT_VERSION")
    String gambit_db_version = read_string("GAMBIT_DB_VERSION")
    String merlin_tag = read_string("MERLIN_TAG")
    String gambit_docker = docker
  }
  runtime {
    docker:  "~{docker}"
    memory:  "16 GB"
    cpu:   8
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

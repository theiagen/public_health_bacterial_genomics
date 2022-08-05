version 1.0

task resfinder {
  input {
    File assembly # Input fasta file
    String samplename
    String? organism # Species in the sample, species should be entered with their full scientific names (e.g. "escherichia coli"), using quotation marks
    Boolean acquired = true # Run resfinder for acquired resistance genes
    Float? min_cov = 0.6 # Minimum (breadth-of) coverage of ResFinder
    Float? threshold = 0.9 # Threshold for identity of ResFinder
    Boolean point = false # Run pointfinder for chromosomal mutations
    String docker = "staphb/resfinder:4.1.11"

  }
  command <<<
    date | tee DATE
    run_resfinder.py --version | tee RESFINDER_VERSION
    echo "unmodified from resfinder docker container" > RESFINDER_DB_VERSION

    # set $resfinder_organism BASH variable based on gambit_predicted_taxon or user-defined input string
    if [[ "~{organism}" == *"Campylobacter"* ]]; then
      resfinder_organism="Campylobacter"
    elif [[ "~{organism}" == *"Enterococcus"*"faecalis"* ]]; then 
      resfinder_organism="Enterococcus faecalis"
    elif [[ "~{organism}" == *"Enterococcus"*"faecium"* ]]; then 
      resfinder_organism="Enterococcus faecium"
    elif [[ "~{organism}" == *"Escherichia"*"coli"* ]]; then 
      resfinder_organism="Escherichia coli"
    elif [[ "~{organism}" == *"Klebsiella"* ]]; then 
      resfinder_organism="Klebsiella"
    # because some people spell the species 'gonorrhea' differently
    elif [[ "~{organism}" == *"Neisseria"*"gonorrhea"* ]] || [[ "~{organism}" == *"Neisseria"*"gonorrhoeae"* ]]; then 
      resfinder_organism="Neisseria gonorrhoeae"
    elif [[ "~{organism}" == *"Salmonella"* ]]; then 
      resfinder_organism="Salmonella"
    elif [[ "~{organism}" == *"Staphylococcus"*"aureus"* ]]; then 
      resfinder_organism="Staphylococcus aureus"
    elif [[ "~{organism}" == *"Mycobacterium"*"tuberculosis"* ]]; then 
      resfinder_organism="Mycobacterium tuberculosis"
    else 
      echo "Either Gambit predicted taxon is not supported by resfinder or the user did not supply an organism as input."
      echo "Skipping the use of resfinder --species optional parameter."
    fi

    # checking bash variable
    echo "resfinder_organism is set to:" ${resfinder_organism}

    # if resfinder_organism variable is set, use --species flag, otherwise do not use --species flag
    if [[ -v resfinder_organism ]] ; then
      run_resfinder.py \
        --inputfasta ~{assembly} \
        --outputPath . \
        --species ${resfinder_organism} \
        ~{true="--acquired" false="" acquired} \
        ~{'--min_cov ' + min_cov} \
        ~{'--threshold ' + threshold} \
        ~{true="--point" false="" point} 
    else 
      run_resfinder.py \
        --inputfasta ~{assembly} \
        --outputPath . \
        --species "other" \
        ~{true="--acquired" false="" acquired} \
        ~{'--min_cov ' + min_cov} \
        ~{'--threshold ' + threshold} 
    fi

    # rename files
    mv pheno_table.txt ~{samplename}_pheno_table.txt
    mv ResFinder_Hit_in_genome_seq.fsa ~{samplename}_ResFinder_Hit_in_genome_seq.fsa
    mv ResFinder_Resistance_gene_seq.fsa ~{samplename}_ResFinder_Resistance_gene_seq.fsa
    mv ResFinder_results_tab.txt ~{samplename}_ResFinder_results_tab.txt
    if [ -f PointFinder_prediction.txt ]; then
      mv PointFinder_prediction.txt ~{samplename}_PointFinder_prediction.txt
      mv PointFinder_results.txt ~{samplename}_PointFinder_results.txt
    fi

  >>>
  output {
    File resfinder_pheno_table = "~{samplename}_pheno_table.txt"
    File resfinder_hit_in_genome_seq = "~{samplename}_ResFinder_Hit_in_genome_seq.fsa"
    File resfinder_resistance_gene_seq = "~{samplename}_ResFinder_Resistance_gene_seq.fsa"
    File resfinder_results_tab = "~{samplename}_ResFinder_results_tab.txt"
    File? pointfinder_pheno_table = "~{samplename}_PointFinder_prediction.txt"
    File? pointfinder_results = "~{samplename}_PointFinder_results.txt"
    String resfinder_docker = "~{docker}"
    String resfinder_version = read_string("RESFINDER_VERSION")
    String resfinder_db_version = read_string("RESFINDER_DB_VERSION")
  }
  runtime {
    memory: "8 GB"
    cpu: 4
    docker: docker
    disks: "local-disk 100 HDD"
  }
}

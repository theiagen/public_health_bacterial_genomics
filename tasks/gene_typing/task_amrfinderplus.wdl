version 1.0

task amrfinderplus_nuc {
  input {
    File assembly
    String samplename
    # Parameters 
    # --indent_min Minimum DNA %identity [0-1]; default is 0.9 (90%) or curated threshold if it exists
    # --mincov Minimum DNA %coverage [0-1]; default is 0.5 (50%)
    String? organism # make optional?
    Int? minid
    Int? mincov
    Int cpu = 4
  }
  command <<<
    # logging info
    date | tee DATE
    amrfinder --version | tee AMRFINDER_VERSION
    
    ### set $amrfinder_organism BASH variable based on gambit_predicted_taxon or user-defined input string
    ### final variable has strict syntax/spelling based on list from amrfinder --list_organisms
    # there may be other Acinetobacter species to add later, like those in the A. baumannii-calcoaceticus species complex
    if [[ "~{organism}" == *"Acinetobacter_baumannii"* ]] || [[ "~{organism}" == *"Acinetobacter baumannii"* ]]; then
      amrfinder_organism="Acinetobacter_baumannii"
    elif [[ "~{organism}" == *"Campylobacter"* ]] || [[ "~{organism}" == *"Campylobacter coli"* ]] || [[ "~{organism}" == *"Campylobacter jejuni"* ]]; then
      amrfinder_organism="Campylobacter"
    elif [[ "~{organism}" == *"Clostridioides_difficile"* ]] || [[ "~{organism}" == *"Clostridioides difficile"* ]]; then
      amrfinder_organism="Clostridioides_difficile"
    elif [[ "~{organism}" == *"Enterococcus_faecalis"* ]] || [[ "~{organism}" == *"Enterococcus faecalis"* ]] ; then 
      amrfinder_organism="Enterococcus_faecalis"
    elif [[ "~{organism}" == *"Enterococcus_faecium"* ]] || [[ "~{organism}" == *"Enterococcus faecium"* ]] || [[ "~{organism}" == *"Enterococcus hirae"* ]]; then 
      amrfinder_organism="Enterococcus_faecium"
    # should capture all Shigella and Escherichia species
    elif [[ "~{organism}" == *"Escherichia"* ]] || [[ "~{organism}" == *"Shigella"* ]] ; then 
      amrfinder_organism="Escherichia"
    # add other Klebsiella species? Cannot use K. oxytoca as per amrfinderplus wiki
    elif [[ "~{organism}" == *"Klebsiella aerogenes"* ]] || [[ "~{organism}" == *"Klebsiella pnemoniae"* ]]; then 
      amrfinder_organism="Klebsiella"
    elif [[ "~{organism}" == *"Neisseria gonorrhoeae"* ]] || [[ "~{organism}" == *"Neisseria meningitidis"* ]]; then 
      amrfinder_organism="Neisseria"
    elif [[ "~{organism}" == *"Pseudomonas_aeruginosa"* ]] || [[ "~{organism}" == *"Pseudomonas aeruginosa"* ]]; then 
      amrfinder_organism="Pseudomonas_aeruginosa"
    # pretty broad, could work on Salmonella bongori and other species
    elif [[ "~{organism}" == *"Salmonella"* ]] || [[ "~{organism}" == *"Salmonella enterica"* ]]; then 
      amrfinder_organism="Salmonella"
    elif [[ "~{organism}" == *"Staphylococcus_aureus"* ]] || [[ "~{organism}" == *"Staphylococcus aureus"* ]]; then 
      amrfinder_organism="Staphylococcus_aureus"
    elif [[ "~{organism}" == *"Staphylococcus_pseudintermedius"* ]] || [[ "~{organism}" == *"Staphylococcus pseudintermedius"* ]]; then 
      amrfinder_organism="Staphylococcus_pseudintermedius"
    elif [[ "~{organism}" == *"Streptococcus_agalactiae"* ]] || [[ "~{organism}" == *"Streptococcus agalactiae"* ]]; then 
      amrfinder_organism="Streptococcus_agalactiae"
    elif [[ "~{organism}" == *"Streptococcus_pneumoniae"* ]] || [[ "~{organism}" == *"Streptococcus pneumoniae"* ]]; then 
      amrfinder_organism="Streptococcus_pneumoniae"
    elif [[ "~{organism}" == *"Streptococcus_pyogenes"* ]] || [[ "~{organism}" == *"Streptococcus pyogenes"* ]]; then 
      amrfinder_organism="Streptococcus_pyogenes"
    elif [[ "~{organism}" == *"Vibrio_cholerae"* ]] || [[ "~{organism}" == *"Vibrio cholerae"* ]]; then 
      amrfinder_organism="Vibrio_cholerae"
    else 
      echo "Either Gambit predicted taxon is not supported by NCBI-AMRFinderPlus or the user did not supply an organism as input."
      echo "Skipping the use of amrfinder --organism optional parameter."
    fi

    # checking bash variable
    echo "amrfinder_organism is set to:" ${amrfinder_organism}
    
    # if amrfinder_organism variable is set, use --organism flag, otherwise do not use --organism flag
    if [[ -v amrfinder_organism ]] ; then
      # always use --plus flag, others may be left out if param is optional and not supplied 
      amrfinder --plus \
        --organism ${amrfinder_organism} \
        ~{'--name ' + samplename} \
        ~{'--nucleotide ' + assembly} \
        ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
        ~{'--threads ' + cpu} \
        ~{'--coverage_min ' + mincov} \
        ~{'--ident_min ' + minid} 
    else 
      # always use --plus flag, others may be left out if param is optional and not supplied 
      amrfinder --plus \
        ~{'--name ' + samplename} \
        ~{'--nucleotide ' + assembly} \
        ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
        ~{'--threads ' + cpu} \
        ~{'--coverage_min ' + mincov} \
        ~{'--ident_min ' + minid}
    fi 
      
    # Element Type possibilities: AMR, STRESS, and VIRULENCE 
    # create headers for 3 output files; tee to 3 files and redirect STDOUT to dev null so it doesn't print to log file
    head -n 1 ~{samplename}_amrfinder_all.tsv | tee ~{samplename}_amrfinder_stress.tsv ~{samplename}_amrfinder_virulence.tsv ~{samplename}_amrfinder_amr.tsv >/dev/null
    # looks for all rows with STRESS, AMR, or VIRULENCE and append to TSVs
    grep 'STRESS' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_stress.tsv
    grep 'VIRULENCE' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_virulence.tsv
    # || true is so that the final grep exits with code 0, preventing failures
    grep 'AMR' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_amr.tsv || true
  >>>
  output {
    File amrfinderplus_all_report = "~{samplename}_amrfinder_all.tsv"
    File amrfinderplus_amr_report = "~{samplename}_amrfinder_amr.tsv"
    File amrfinderplus_stress_report = "~{samplename}_amrfinder_stress.tsv"
    File amrfinderplus_virulence_report = "~{samplename}_amrfinder_virulence.tsv"
    #### commented out for now. Not sure how to output what organism was used if it was not defined as an input paramter
    # String amrfinder_organism = organism 
    String amrfinderplus_version = read_string("AMRFINDER_VERSION")
  }
  runtime {
    memory: "8 GB"
    cpu: cpu
    docker: "quay.io/staphb/ncbi-amrfinderplus:3.10.24"
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

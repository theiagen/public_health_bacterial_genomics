version 1.0

task gambit {
  input {
    File assembly
    String samplename
    String docker = "quay.io/staphb/gambit:0.3.0"
    File gambit_db_genomes
    File gambit_db_signatures
  }
  String gambit_db_genomes_name = basename(gambit_db_genomes, ".db")
  String gambit_db_signatures_name = basename(gambit_db_signatures, ".h5")
  
  command <<<
    # capture date and version
    date | tee DATE
    
    # create gambit database dir
    mkdir ./gambit_database
    cp ~{gambit_db_genomes} ./gambit_database
    cp ~{gambit_db_signatures} ./gambit_database
    
    gambit -d .//gambit_database query -o ~{samplename}_gambit.csv ~{assembly} 
    
    python3 <<CODE
    import csv
    #grab output genome length and number contigs by column header
    with open("~{samplename}_gambit.csv",'r') as csv_file:
      csv_reader = list(csv.DictReader(csv_file, delimiter=","))
      for line in csv_reader:
        with open ("GAMBIT_DISTANCE", 'wt') as gambit_distance:
          top_score=float(line["closest.distance"])
          top_score="{:.4f}".format(top_score)
          gambit_distance.write(str(top_score))
        with open("GAMBIT_RANK", 'wt') as gambit_rank:
          predicted_rank=line["predicted.rank"]
          if not predicted_rank:
            predicted_rank="None"
          gambit_rank.write(predicted_rank)
        with open("GAMBIT_TAXON", 'wt') as gambit_taxon:
          predicted_taxon=line["predicted.name"]
          if not predicted_taxon:
            predicted_taxon="None"
          gambit_taxon.write(predicted_taxon)
    CODE
  >>>
  output {
    File gambit_report = "~{samplename}_gambit.csv"
    String gambit_docker = docker
    String pipeline_date = read_string("DATE")
    Float gambit_distance = read_float("GAMBIT_DISTANCE") 
    String gambit_taxon = read_string("GAMBIT_TAXON")
    String gambit_rank = read_string("GAMBIT_RANK")
    String gambit_db_genomes_version = gambit_db_genomes_name
    String gambit_db_signatures_version = gambit_db_signatures_name
  }
  runtime {
    docker:  "~{docker}"
    memory:  "16 GB"
    cpu:   8
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}
task kleborate_one_sample {
  # Inputs
  input {
    File assembly
    String samplename
    String kleborate_docker_image = "staphb/kleborate:2.0.4"
  }
  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    kleborate --version > VERSION && sed -i -e 's/^/Kleborate /' VERSION
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
    kleborate -a ~{assembly} --all -o ~{samplename}_kleborate_output_file.tsv

    python3 <<CODE
    import csv
    with open("./~{samplename}_kleborate_output_file.tsv",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("SPECIES", 'wt') as Species:
        kleb_species=tsv_dict['species']
        Species.write(kleb_species)
      with open ("MLST_SEQUENCE_TYPE", 'wt') as MLST_Sequence_Type:
        mlst=tsv_dict['ST']
        MLST_Sequence_Type.write(mlst)
      with open ("VIRULENCE_SCORE", 'wt') as Virulence_Score:
        virulence_level=tsv_dict['virulence_score']
        Virulence_Score.write(virulence_level)
      with open ("RESISTANCE_SCORE", 'wt') as Resistance_Score:
        resistance_level=tsv_dict['resistance_score']
        Resistance_Score.write(resistance_level)
      with open ("NUM_RESISTANCE_GENES", 'wt') as Num_Resistance_Genes:
        resistance_genes_count=tsv_dict['num_resistance_genes']
        Num_Resistance_Genes.write(resistance_genes_count)
      with open ("BLA_RESISTANCE_GENES", 'wt') as BLA_Resistance_Genes:
        bla_res_genes_list=['Bla_acquired', 'Bla_inhR_acquired', 'Bla_ESBL_acquired', 'Bla_ESBL_inhR_acquired', 'Bla_Carb_acquired']
        bla_res_genes=[]
        for i in bla_res_genes_list:
          if tsv_dict[i] != '-':
            bla_res_genes.append(tsv_dict[i])
        bla_res_genes_string=';'.join(bla_res_genes)
        BLA_Resistance_Genes.write(bla_res_genes_string)
      with open ("ESBL_RESISTANCE_GENES", 'wt') as ESBL_Resistance_Genes:
        esbl_res_genes_list=['Bla_ESBL_acquired', 'Bla_ESBL_inhR_acquired']
        esbl_res_genes=[]
        for i in esbl_res_genes_list:
          if tsv_dict[i] != '-':
            bla_res_genes.append(tsv_dict[i])
        esbl_res_genes_string=';'.join(esbl_res_genes)
        ESBL_Resistance_Genes.write(esbl_res_genes_string)
      with open ("KEY_RESISTANCE_GENES", 'wt') as Key_Resistance_Genes:
        key_res_genes_list= ['Col_acquired', 'Fcyn_acquired', 'Flq_acquired', 'Rif_acquired', 'Bla_acquired', 'Bla_inhR_acquired', 'Bla_ESBL_acquired', 'Bla_ESBL_inhR_acquired', 'Bla_Carb_acquired']
        key_res_genes=[]
        for i in key_res_genes_list:
          if tsv_dict[i] != '-':
            key_res_genes.append(tsv_dict[i])
        key_res_genes_string=';'.join(key_res_genes)
        Key_Resistance_Genes.write(key_res_genes_string)
      with open ("GENOMIC_RESISTANCE_MUTATIONS", 'wt') as Resistance_Mutations:
        res_mutations_list= ['Bla_chr', 'SHV_mutations', 'Omp_mutations', 'Col_mutations', 'Flq_mutations']
        res_mutations=[]
        for i in res_mutations_list:
          if tsv_dict[i] != '-':
            res_mutations.append(tsv_dict[i])
        res_mutations_string=';'.join(res_mutations)
        Resistance_Mutations.write(res_mutations_string)
    CODE
  >>>
  output {
    File kleborate_output_file = "~{samplename}_kleborate_output_file.tsv"
    String version = read_string("VERSION")
    String mlst_sequence_type = read_string("MLST_SEQUENCE_TYPE")
    String virulence_score = read_string("VIRULENCE_SCORE")
    String resistance_score = read_string("RESISTANCE_SCORE")
    String num_resistance_genes = read_string("NUM_RESISTANCE_GENES")
    String bla_resistance_genes = read_string("BLA_RESISTANCE_GENES")
    String esbl_resistance_genes = read_string("ESBL_RESISTANCE_GENES")
    String key_resistance_genes = read_string("KEY_RESISTANCE_GENES")
    String resistance_mutations = read_string("GENOMIC_RESISTANCE_MUTATIONS")
  }
  runtime {
    docker:       "~{kleborate_docker_image}"
    memory:       "16 GB"
    cpu:          8
    disks:        "local-disk 100 SSD"
  }
}
task serotypefinder_one_sample {
  input {
    File ecoli_assembly
    String samplename
    String docker = "quay.io/staphb/serotypefinder:2.0.1"
  }
  command <<<
    # capture date and version
    date | tee DATE

    serotypefinder.py -i ~{ecoli_assembly}  -x -o . 
    mv results_tab.tsv ~{samplename}_results_tab.tsv
    
    # set H and O type based on serotypefinder ourputs
    python3 <<CODE
    import csv
    import re
    
    antigens = []
    h_re = re.compile("H[0-9]*")
    o_re = re.compile("O[0-9]*")
    
    with open("~{samplename}_results_tab.tsv",'r') as tsv_file:
      tsv_reader = csv.DictReader(tsv_file, delimiter="\t")
      for row in tsv_reader:
          if row.get('Serotype') not in antigens:
            antigens.append(row.get('Serotype'))            
    print("Antigens: " + str(antigens))
    
    h_type = "/".join(set("/".join(list(filter(h_re.match, antigens))).split('/')))
    print("H-type: " + h_type)
    o_type = "/".join(set("/".join(list(filter(o_re.match,antigens))).split('/')))
    print("O-type: " + o_type)

    serotype = "{}:{}".format(o_type,h_type)
    if serotype == ":":
      serotype = "NA"
    print("Serotype: " + serotype)
    
    with open ("STF_SEROTYPE", 'wt') as stf_serotype:
      stf_serotype.write(str(serotype))
    CODE
  >>>
  output {
    File serotypefinder_report = "~{samplename}_results_tab.tsv"
    String serotypefinder_docker = docker
    String serotypefinder_serotype = read_string("STF_SEROTYPE")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

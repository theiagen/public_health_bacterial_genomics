version 1.0

task kaptive {
  # Inputs
  input {
    File assembly
    String reference_loci_k = "/kaptive/reference_database/Acinetobacter_baumannii_k_locus_primary_reference.gbk"
    String reference_loci_oc = "/kaptive/reference_database/Acinetobacter_baumannii_OC_locus_primary_reference.gbk"
    String samplename
    String kaptive_docker_image = "quay.io/staphb/kaptive:2.0.3"
    # Parameters
    # --resistance                      Turn on resistance genes screening (default: no resistance gene screening)
    # --min_identity MIN_IDENTITY           Minimum alignment percent identity for main results (default: 80.0)
    # --min_coverage MIN_COVERAGE           Minimum alignment percent coverage for main results (default: 90.0)
    Float min_identity = 90.0
    Float min_coverage = 80.0
  }

  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    kaptive --version | tee VERSION 
    # Run Kaptive on the input assembly with the --all flag and output with samplename prefix
    kaptive \
    ~{'--min_identity ' + min_identity} \
    ~{'--min_coverage ' + min_coverage} \
    --no_seq_out \
    --no_json \
    --out ~{samplename}_kaptive_out \
    --assembly ~{assembly} \
    --k_refs ~{reference_loci}
    # parse outputs
    python3 <<CODE
    import csv
    with open("./~{samplename}_kaptive_out_table.txt",'r') as tsv_file:
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
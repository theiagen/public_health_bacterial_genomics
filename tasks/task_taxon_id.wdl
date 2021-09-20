version 1.0

task gambit {
  input {
    File assembly
    String samplename
    String docker = "theiagen/midas_nsphl:1.0.0"
  }
  command <<<
    # capture date and version
    date | tee DATE

    midas query ~{assembly} | tail -n2 > ~{samplename}_gambit.csv

    python3 <<CODE
    import csv
    #grab output genome length and number contigs by column header
    with open("~{samplename}_gambit.csv",'r') as csv_file:
      csv_reader = list(csv.DictReader(csv_file, delimiter=","))
      for line in csv_reader:
        with open ("GAMBIT_SCORE", 'wt') as gambit_score:
          top_score=float(line["top_score"])
          top_score="{:.2f}".format(top_score)
          gambit_score.write(str(top_score))
        with open("GAMBIT_DELTA", 'wt') as gambit_delta:
          top_score=float(line["top_score"])
          species_threshold=float(line["species_threshold"])
          delta=top_score - species_threshold
          #format delta to two decimal placesn
          delta="{:.2f}".format(delta)
          gambit_delta.write(str(delta))
        with open("PREDICTED_GENUS", 'wt') as predicted_genus:
          genus=line["predicted_genus"]
          if not genus:
            genus="None"
          predicted_genus.write(genus)
        with open("PREDICTED_SPECIES", 'wt') as predicted_species:
          species=line["predicted_species"]
          if not species:
            species="None"
          predicted_species.write(species)
    CODE
  >>>
  output {
    File gambit_report = "~{samplename}_gambit.csv"
    String gambit_docker = docker
    String pipeline_date = read_string("DATE")
    Float gambit_score = read_float("GAMBIT_SCORE")
    Float gambit_delta = read_float("GAMBIT_DELTA")
    String gambit_genus = read_string("PREDICTED_GENUS")
    String gambit_species = read_string("PREDICTED_SPECIES")
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
task tbprofiler_one_sample_pe {
  # Inputs
  input {
    File read1
    File read2
    String samplename
    String tbprofiler_docker_image = "quay.io/biocontainers/tb-profiler:3.0.8--pypyh5e36f6f_0"
    String? mapper
    String? caller
    Int? min_depth
    Float? min_af
    Float? min_af_pred
    Int? cov_frac_threshold
  }
  command <<<
    # update TBDB
    # tb-profiler update_tbdb
    # Print and save date
    date | tee DATE
    # Print and save version
    tb-profiler --version > VERSION && sed -i -e 's/^/TBProfiler version /' VERSION
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
    tb-profiler profile -1 ~{read1} -2 ~{read2} --call_whole_genome --prefix ~{samplename} --mapper ~{mapper} --caller ~{caller} --min_depth ~{min_depth} --af ~{min_af} --reporting_af ~{min_af_pred} --coverage_fraction_threshold ~{cov_frac_threshold} --csv --txt

    #Collate results
    tb-profiler collate --prefix ~{samplename}

    python3 <<CODE
    import csv
    with open("./~{samplename}.txt",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("MAIN_LINEAGE", 'wt') as Main_Lineage:
        main_lin=tsv_dict['main_lineage']
        Main_Lineage.write(main_lin)
      with open ("SUB_LINEAGE", 'wt') as Sub_Lineage:
        sub_lin=tsv_dict['sub_lineage']
        Sub_Lineage.write(sub_lin)
      with open ("DR_TYPE", 'wt') as DR_Type:
        dr_type=tsv_dict['DR_type']
        DR_Type.write(dr_type)
      with open ("NUM_DR_VARIANTS", 'wt') as Num_DR_Variants:
        num_dr_vars=tsv_dict['num_dr_variants']
        Num_DR_Variants.write(num_dr_vars)
      with open ("NUM_OTHER_VARIANTS", 'wt') as Num_Other_Variants:
        num_other_vars=tsv_dict['num_other_variants']
        Num_Other_Variants.write(num_other_vars)
      with open ("RESISTANCE_GENES", 'wt') as Resistance_Genes:
        res_genes_list=['rifampicin', 'isoniazid', 'pyrazinamide', 'ethambutol', 'streptomycin', 'fluoroquinolones', 'moxifloxacin', 'ofloxacin', 'levofloxacin', 'ciprofloxacin', 'aminoglycosides', 'amikacin', 'kanamycin', 'capreomycin', 'ethionamide', 'para-aminosalicylic_acid', 'cycloserine', 'linezolid', 'bedaquiline', 'clofazimine', 'delamanid']
        res_genes=[]
        for i in res_genes_list:
          if tsv_dict[i] != '-':
            res_genes.append(tsv_dict[i])
        res_genes_string=';'.join(res_genes)
        Resistance_Genes.write(res_genes_string)
    CODE
  >>>
  output {
    File tbprofiler_output_csv = "./results/~{samplename}.results.csv"
    File tbprofiler_output_tsv = "./results/~{samplename}.results.txt"
    String version = read_string("VERSION")
    String tb_profiler_main_lineage = read_string("MAIN_LINEAGE")
    String tb_profiler_sub_lineage = read_string("SUB_LINEAGE")
    String tb_profiler_dr_type = read_string("DR_TYPE")
    String tb_profiler_num_dr_variants = read_string("NUM_DR_VARIANTS")
    String tb_profiler_num_other_variants = read_string("NUM_OTHER_VARIANTS")
    String tb_profiler_resistance_genes = read_string("RESISTANCE_GENES")
  }
  runtime {
    docker:       "~{tbprofiler_docker_image}"
    memory:       "16 GB"
    cpu:          8
    disks:        "local-disk 100 SSD"
  }
}
task tbprofiler_one_sample_ont {
  # Inputs
  input {
    File reads
    String samplename
    String tbprofiler_docker_image = "quay.io/biocontainers/tb-profiler:3.0.8--pypyh5e36f6f_0"
    String? mapper
    String? caller
    Int? min_depth
    Float? min_af
    Float? min_af_pred
    Int? cov_frac_threshold
  }
  command <<<
    # update TBDB
    # tb-profiler update_tbdb
    # Print and save date
    date | tee DATE
    # Print and save version
    tb-profiler --version > VERSION && sed -i -e 's/^/TBProfiler version /' VERSION
    # Run TBProfiler on the input sample
    tb-profiler profile --platform nanopore -1 ~{reads} --call_whole_genome --prefix ~{samplename} --mapper ~{mapper} --caller ~{caller} --min_depth ~{min_depth} --af ~{min_af} --reporting_af ~{min_af_pred} --coverage_fraction_threshold ~{cov_frac_threshold} --csv --txt

    #Collate results
    tb-profiler collate --prefix ~{samplename}

    python3 <<CODE
    import csv
    with open("./~{samplename}.txt",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("MAIN_LINEAGE", 'wt') as Main_Lineage:
        main_lin=tsv_dict['main_lineage']
        Main_Lineage.write(main_lin)
      with open ("SUB_LINEAGE", 'wt') as Sub_Lineage:
        sub_lin=tsv_dict['sub_lineage']
        Sub_Lineage.write(sub_lin)
      with open ("DR_TYPE", 'wt') as DR_Type:
        dr_type=tsv_dict['DR_type']
        DR_Type.write(dr_type)
      with open ("NUM_DR_VARIANTS", 'wt') as Num_DR_Variants:
        num_dr_vars=tsv_dict['num_dr_variants']
        Num_DR_Variants.write(num_dr_vars)
      with open ("NUM_OTHER_VARIANTS", 'wt') as Num_Other_Variants:
        num_other_vars=tsv_dict['num_other_variants']
        Num_Other_Variants.write(num_other_vars)
      with open ("RESISTANCE_GENES", 'wt') as Resistance_Genes:
        res_genes_list=['rifampicin', 'isoniazid', 'pyrazinamide', 'ethambutol', 'streptomycin', 'fluoroquinolones', 'moxifloxacin', 'ofloxacin', 'levofloxacin', 'ciprofloxacin', 'aminoglycosides', 'amikacin', 'kanamycin', 'capreomycin', 'ethionamide', 'para-aminosalicylic_acid', 'cycloserine', 'linezolid', 'bedaquiline', 'clofazimine', 'delamanid']
        res_genes=[]
        for i in res_genes_list:
          if tsv_dict[i] != '-':
            res_genes.append(tsv_dict[i])
        res_genes_string=';'.join(res_genes)
        Resistance_Genes.write(res_genes_string)
    CODE
  >>>
  output {
    File tbprofiler_output_csv = "./results/~{samplename}.results.csv"
    File tbprofiler_output_tsv = "./results/~{samplename}.results.txt"
    String version = read_string("VERSION")
    String tb_profiler_main_lineage = read_string("MAIN_LINEAGE")
    String tb_profiler_sub_lineage = read_string("SUB_LINEAGE")
    String tb_profiler_dr_type = read_string("DR_TYPE")
    String tb_profiler_num_dr_variants = read_string("NUM_DR_VARIANTS")
    String tb_profiler_num_other_variants = read_string("NUM_OTHER_VARIANTS")
    String tb_profiler_resistance_genes = read_string("RESISTANCE_GENES")
  }
  runtime {
    docker:       "~{tbprofiler_docker_image}"
    memory:       "16 GB"
    cpu:          8
    disks:        "local-disk 100 SSD"
  }
}

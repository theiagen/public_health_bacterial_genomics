version 1.0

task kleborate_one_sample {
  # Inputs
  input {
    File kleb_assembly
    String samplename
    String kleborate_docker_image = "staphb/kleborate:2.0.4"
  }

  # Command
  # Included --all (which includes --resistance and --kaptive)
  command<<<
    # Print and save date
    date | tee DATE
    # Print and save version
    kleborate --version > VERSION && sed -i -e 's/^/Kleborate /' VERSION
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
    kleborate -a ~{kleb_assembly} --all -o ~{samplename}_kleborate_output_file.tsv \ 
    #####mv Kleborate_results.txt ${samplename}_kleborate_output_file.tsv

    python3 <<CODE

      import pandas as pd
      import numpy as np
      import re
      import csv

      with open('Kleborate_results.txt','r') as kleb_tsv:
        kleb_df_input = pd.read_csv(kleb_tsv, sep='\t', header=0)
        kleb_df_nans = kleb_df_input.replace(to_replace ='^-', value = np.NaN, regex = True)
        kleb_df = kleb_df_nans.dropna(axis=1, how='all')
        kleb_cols = list(kleb_df)
       
        # Acquired Resistance
        acqiredRes_list = []
        for i in kleb_cols:
          if i.endswith('_acquired'):
            acqiredRes_list.append(i)
          else:
            next
        acquiredRes_count = len(acqiredRes_list)
        acquiredRes_df = pd.DataFrame(columns=acqiredRes_list)
        for i in acqiredRes_list:
          acquiredRes_df[i] = kleb_df[i]

        # Beta Lactamases
        blaRes_list = []
        for i in kleb_cols:
          if i.startswith('Bla_'):
            blaRes_list.append(i)
          else:
            next
        blaRes_count = len(blaRes_list)
        blaRes_df = pd.DataFrame(columns=blaRes_list)
        for i in blaRes_list:
          blaRes_df[i] = kleb_df[i]

        # Extened Spectrum Beta Lactamases
        esblRes_list = []
        for i in kleb_cols:
          if i.startswith('Bla_ESBL_'):
            esblRes_list.append(i)
          else:
            next
        esblRes_count = len(esblRes_list)
        esblRes_df = pd.DataFrame(columns=esblRes_list)
        for i in esblRes_list:
          esblRes_df[i] = kleb_df[i]

        # Key Factors
        keyFactors_selection = ['Col_acquired', 'Fcyn_acquired', 'Flq_acquired', 'Rif_acquired', 'Bla_acquired', 'Bla_inhR_acquired', 'Bla_ESBL_acquired', 'Bla_ESBL_inhR_acquired', 'Bla_Carb_acquired']
        keyFactors_list = []
        for i in kleb_cols:
          if i in keyFactors_selection:
            keyFactors_list.append(i)
          else:
            next
        keyFactors_count = len(keyFactors_list)
        keyFactors_df = pd.DataFrame(columns=keyFactors_list)
        for i in keyFactors_list:
          keyFactors_df[i] = kleb_df[i]

        # Create Concatonations
        acquiredRes_df['acquired_resistance'] = acquiredRes_df.sum(axis=1).astype(str)
        blaRes_df['bla_resistance'] = blaRes_df.sum(axis=1).astype(str)
        esblRes_df['esbl_resistance'] = esblRes_df.sum(axis=1).astype(str)

        # Print Dataframes to TSV Files
        keyFactors_df.to_csv('~{samplename}_key_resistance_factors.tsv', sep = '\t')
        acquiredRes_df.to_csv('~{samplename}_acquired_resistance_factors.tsv', sep = '\t')
        blaRes_df.to_csv('~{samplename}_bla_resistance_factors.tsv', sep = '\t')
        esblRes_df.to_csv('~{samplename}_esbl_resistance_factors.tsv', sep = '\t')

        #Output Strings
        with open("KEY_RESISTANCE_FACTORS", 'wt') as key_resistance_factors:
          keyResFacs=keyFactors_df.head(1).to_string()
          key_resistance_factors.write(keyResFacs)

        with open("ACQUIRED_RESISTANCE", 'wt') as acquired_resistance_factors:
          acqResFacs=keyFactors_df.head(1).to_string()
          acquired_resistance_factors.write(acqResFacs)

        with open("BLA_RESISTANCE", 'wt') as bla_resistance_factors:
          blaResFacs=keyFactors_df.head(1).to_string()
          bla_resistance_factors.write(blaResFacs)

        with open("ESBL_RESISTANCE", 'wt') as esbl_resistance_factors:
         esblResFacs=keyFactors_df.head(1).to_string()
          esbl_resistance_factors.write(esblResFacs)

    CODE

  >>>
  #Add output variables
  # Outputs
  output {
    File kleborate_output_file = "~{samplename}_kleborate_output_file.tsv"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
    File key_resistance_factors_file = "~{samplename}_key_resistance_factors.tsv"
    File acquired_resistance_factors_file = "~{samplename}_key_resistance_factors.tsv"
    File bla_resistance_factors_file = "~{samplename}_bla_resistance_factors.tsv"
    File esbl_resistance_factors_file = "~{samplename}_esbl_resistance_factors.tsv"
    String key_resistance_factors = read_string("KEY_RESISTANCE_FACTORS")
    String acquired_resistance_factors = read_string("ACQUIRED_RESISTANCE")
    String bla_resistance_factors = read_string("BLA_RESISTANCE")
    String esbl_resistance_factors = read_string("ESBL_RESISTANCE")


  }

  runtime {
    docker:       "~{kleborate_docker_image}"
    memory:       "4 GB"
    cpu:          2
    disks:        "local-disk 64 SSD"
    preemptible:  0
  }
}



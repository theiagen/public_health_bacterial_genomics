version 1.0

task gambit {
  input {
    File    assembly
    String  samplename
    String  docker="theiagen/midas_nsphl:1.0.0"
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
    File   gambit_report     = "~{samplename}_gambit.csv"
    String gambit_docker     = docker
    String pipeline_date     = read_string("DATE")
    Float  gambit_score      = read_float("GAMBIT_SCORE") 
    Float  gambit_delta      = read_float("GAMBIT_DELTA")
    String predicted_genus   = read_string("PREDICTED_GENUS")
    String predicted_species = read_string("PREDICTED_SPECIES")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "16 GB"
    cpu:   8
    disks: "local-disk 100 SSD"
    preemptible:  0
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
            
    print(antigens)
    h_type = "/".join(set("/".join(list(filter(h_re.match, antigens))).split('/')))
    print("H_type 1: "+ h_type)
    print(h_type)
    o_type = "/".join(set("/".join(list(filter(o_re.match,antigens))).split('/')))
    print(o_type)
    serotype = "{}:{}".format(h_type,o_type)
    if serotype == ":":
      serotype = "NA"
    print(serotype)
    
    with open ("STF_SEROTYPE", 'wt') as stf_serotype:
      stf_serotype.write(str(serotype))
    CODE
  >>>
  output {
    File   serotypefinder_report = "~{samplename}_results_tab.tsv"
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

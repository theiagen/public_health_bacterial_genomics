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
    File    ecoli_assembly
    String  samplename
    String  docker="quay.io/staphb/serotypefinder:2.0.1"
  }
  command <<<
    # capture date and version
    date | tee DATE

    serotypefinder.py -i ~{ecoli_assembly}  -x -o . 
    mv results_tab.tsv ~{samplename}_results_tab.tsv
    
    
  >>>
  output {
    File   serotypefinder_report     = "~{samplename}_results_tab.tsv"
    String serotypefinder_docker     = docker
  }
  runtime {
    docker:  "~{docker}"
    memory:  "8 GB"
    cpu:   2
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

version 1.0

task midas_nsphl {
  input {
    File assembly
    String samplename
    String docker="theiagen/midas_nsphl:1.0.0"
  }
  command <<<
    # capture date and version
    date | tee DATE

    midas query ~{assembly} | tail -n2 > ~{samplename}_midas_nsphl.csv
    
    python3 <<CODE
    import csv
    #grab output genome length and number contigs by column header
    with open("~{samplename}_midas_nsphl.csv",'r') as csv_file:
      csv_reader = list(csv.DictReader(csv_file, delimiter=","))
      for line in csv_reader:
        with open("MIDAS_DELTA", 'wt') as midas_delta:
          top_score=float(line["top_score"])
          species_threshold=float(line["species_threshold"])
          delta=top_score - species_threshold
          #format delta to two decimal places
          delta="{:.2f}".format(delta)
          midas_delta.write(str(delta))
        with open("PREDICTED_GENUS", 'wt') as predicted_genus:
          genus=line["predicted_genus"]
          if not genus:
            genus="None"
          predicted_genus.write(f"{genus}")
        with open("PREDICTED_SPECIES", 'wt') as predicted_species:
          species=line["predicted_species"]
          if not species:
            species="None"
          predicted_species.write(f"{species}")
    CODE
  >>>
  output {
    File midas_nsphl_report = "~{samplename}_midas_nsphl.csv"
    String  midas_nsphl_docker   = docker
    String  pipeline_date = read_string("DATE")
    Float midas_delta = read_float("MIDAS_DELTA")
    String predicted_genus = read_string("PREDICTED_GENUS")
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

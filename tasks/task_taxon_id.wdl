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
        with open("PREDICTED_TAXON", 'wt') as predicted_taxon:
          predicted_genus=line["predicted_genus"]
          predicted_species=line["predicted_species"]
          if not predicted_species:
            predicted_species="No species prediction made"
          predicted_taxon.write(f"{predicted_genus} {predicted_species}")
    CODE
  >>>
  output {
    File midas_nsphl_report = "~{samplename}_midas_nsphl.csv"
    String  midas_nsphl_docker   = docker
    String  pipeline_date = read_string("DATE")
    Float midas_delta = read_float("MIDAS_DELTA")
    String predicted_taxon = read_string("PREDICTED_TAXON")
  }
  runtime {
    docker:  "~{docker}"
    memory:  "16 GB"
    cpu:   8
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

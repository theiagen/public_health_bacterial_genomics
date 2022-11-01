version 1.0

task mykrobe {
  # Inputs
  input {
    File read1
    File? read2
    Boolean ont_data=false
    String samplename
    String genotyphi_docker_image = "staphb/mykrobe:0.11.0"
    String mykrobe_species 
    String? myrkobe_opts
    Int cpu = 4
  }
  command <<<
    # Print and save versions
     mykrobe --version | sed 's|mykrobe v||g' | tee MYKROBE_VERSION.txt
     # super ugly oneliner since "python /genotyphi/genotyphi.py --version" does NOT work due to python syntax error
     #grep '__version__ =' /genotyphi/genotyphi.py | sed "s|__version__ = '||" | sed "s|'||" | tee GENOTYPHI_VERSION

    # Run Mykrobe on the input read data
    mykrobe predict \
    -t ~{cpu} \
    --sample ~{samplename} \
    --species ~{mykrobe_species} \
    --format json_and_csv \
    --out ~{samplename}.mykrobe \
    ~{true='--ont' false='' ont_data} \
    --seq ~{read1} ~{read2} \
    ~{myrkobe_opts}

    # Run a python block to parse output file for terra data tables
    python3 <<CODE
    import csv
    with open("./~{samplename}.mykrobe",'r') as tsv_file:
      tsv_reader = list(csv.DictReader(tsv_file, delimiter=","))
      for line in tsv_reader:
        with open ("SPECIES.txt", 'wt') as genotyphi_species:
          species=line["species"]
          genotyphi_species.write(species)
        with open ("SPP_PERCENT", 'wt') as species_percent:
          spp_percent=line["spp_percent"]
          species_percent.write(spp_percent)
        with open ("FINAL_GENOTYPE", 'wt') as final_genotype:
          genotype=line["final genotype"]
          final_genotype.write(genotype)
        with open ("CONFIDENCE", 'wt') as genotyphi_confidence:
          confidence=line["confidence"]
          genotyphi_confidence.write(confidence)
    CODE
  >>>
  output {
    File mykrobe_report_csv = "./~{samplename}_mykrobe_genotyphi_predictResults.tsv"
    File mykrobe_report_json = "./~{samplename}.mykrobe_genotyphi.json"
    String mykrobe_version = read_string("MYKROBE_VERSION.txt")
    String mykrobe_species = read_string("SPECIES.txt")
    #Float genotyphi_st_probes_percent_coverage = read_string("SPP_PERCENT")
    String mykrobe_lineage = read_string("LINEAGE.txt")
    #String genotyphi_genotype_confidence = read_string("CONFIDENCE")
  }
  runtime {
    docker:       "~{genotyphi_docker_image}"
    memory:       "8 GB"
    cpu:          cpu
    disks:        "local-disk 100 SSD"
    preemptible:  0
    maxRetries:   3
  }
}
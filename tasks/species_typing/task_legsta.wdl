version 1.0

task legsta {
  meta {
    description: "Typing of Legionella pneumophila assemblies"
  }
  input {
    File assembly
    String samplename
    String docker = "quay.io/biocontainers/legsta:0.5.1--hdfd78af_2"
    Int? cpu = 2
  }
  command <<<
    echo $(legsta --version 2>&1) | sed 's/^.*legsta //; s/ .*\$//;' | tee VERSION
    legsta \
      ~{assembly} > ~{samplename}.tsv
    
    # parse outputs
    python3 <<CODE
    import csv
    with open("./~{samplename}.tsv",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("LEGSTA_ALLELES", 'wt') as Alleles:
        alleles_list= ['SBT', 'flaA', 'pilE', 'asd', 'mip', 'mompS', 'proA', 'neuA']
        alleles=[]
        for i in alleles_list:
          if tsv_dict[i] != '':
            alleles.append(i + ":" + tsv_dict[i])
        alleles_string=','.join(alleles)
        Alleles.write(alleles_string)
    CODE
  >>>
  output {
    File legsta_results = "~{samplename}.tsv"
    String legsta_alleles = read_string("LEGSTA_ALLELES")
    String legsta_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}

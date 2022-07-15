version 1.0

task plasmidfinder {
  input {
    File assembly
    String samplename
    Int cpu = 8
    Int memory = 16
    String docker = "staphb/plasmidfinder:2.1.6"
    String? database
    String? database_path
    String? method_path
    # minimum coverage threshold
    Int? min_cov 
    # minimum blast identity threshold
    Int? threshold

  }
  command <<<
  date | tee DATE

  plasmidfinder.py \
  -i ~{assembly} \
  -x \
  ~{'-d ' + database} \
  ~{'-p ' + database_path} \
  ~{'-mp ' + method_path} \
  ~{'-l ' + min_cov} \
  ~{'-t ' + threshold} 

  # parse outputs
  if [ ! -f results_tab.tsv ]; then
    PF="No plasmids detected"
  else
    PF="$(tail -n +2 results_tab.tsv | cut -f 2 | sort | uniq -u | paste -s -d, - )"
      if [ "$PF" == "" ]; then
        PF="No plasmids detected"
      fi  
  fi
  echo $PF | tee PLASMIDS

  mv results_tab.tsv ~{samplename}_results.tsv
  mv Hit_in_genome_seq.fsa ~{samplename}_seqs.fsa

  >>>
  output {
    String plasmidfinder_plasmids = read_string("PLASMIDS")
    File plasmidfinder_results = "~{samplename}_results.tsv"
    File plasmidfinder_seqs = "~{samplename}_seqs.fsa"
    String plasmidfinder_docker = docker
  }
  runtime {
    memory: "~{memory} GB"
    cpu: cpu
    docker: "~{docker}"
    disks: "local-disk 100 HDD"
  }
}
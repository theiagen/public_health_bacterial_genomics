version 1.0

task shigatyper {
  meta {
    description: "ShigaTyper is a quick and easy tool designed to determine Shigella serotype using Illumina (single or paired-end) or Oxford Nanopore reads with low computation requirement. https://github.com/CFSAN-Biostatistics/shigatyper"
  }
  input {
    File read1 
    File? read2
    String samplename
    String docker = "staphb/shigatyper:2.0.1"
    Int cpus = 4
    Boolean read1_is_ont = false
  }
  command <<<
    # get version information
    shigatyper --version | sed 's/ShigaTyper //' | tee VERSION

    # if read2 DOES NOT EXIST, ASSUME SINGLE END OR ONT
    if [ -z "~{read2}" ] ; then
      INPUT_READS="--SE ~{read1}"
      # if read1_is_ont is set to TRUE, then use ONT flags
      if [ "~{read1_is_ont}" == "true" ]; then
        INPUT_READS="--SE ~{read1} --ont"
      fi
    # else read2 DOES EXIST, ASSUME PAIRED END
    else
      INPUT_READS="--R1 ~{read1} --R2 ~{read2}"
    fi
    echo "INPUT_READS set to: ${INPUT_READS}"
    echo 

    # run shigatyper
    echo "Running ShigaTyper..."
    shigatyper \
      ${INPUT_READS} \
      -n ~{samplename}

    # rename *-hits.tsv to differentiate from summary .tsv AND deal with not being able to name output files
    mv -v ./*-hits.tsv ~{samplename}_hits.tsv

    # take read1, use it's name to predict output of shigatyper, similar to how shigatyper.py does it:
    # see code here: https://github.com/CFSAN-Biostatistics/shigatyper/blob/conda-package-2.0.1/shigatyper/shigatyper.py#L476
    SHIGATYPER_OUT_SAMPLENAME_PREFIX=$(basename ~{read1} | cut -d '_' -f1 |cut -d '.' -f 1)

    # rename summary TSV 
    mv -v ./${SHIGATYPER_OUT_SAMPLENAME_PREFIX}*.tsv ~{samplename}_summary.tsv

    # parse summary tsv for prediction, ipaB absence/presence, and notes
    cut -f 2 ~{samplename}_summary.tsv | tail -n 1 > shigatyper_prediction.txt
    cut -f 3 ~{samplename}_summary.tsv | tail -n 1 > shigatyper_ipaB_presence_absence.txt
    cut -f 4 ~{samplename}_summary.tsv | tail -n 1 > shigatyper_notes.txt

    # if variable for shigatyper notes is EMPTY, write string saying it is empty to float to Terra table
    if [ "$(cat shigatyper_notes.txt)" == "" ]; then
       echo "ShigaTyper notes field was empty" > shigatyper_notes.txt
    fi

  >>>
  output {
    String shigatyper_predicted_serotype = read_string("shigatyper_prediction.txt")
    String shigatyper_ipaB_presence_absence = read_string("shigatyper_ipaB_presence_absence.txt")
    String shigatyper_notes = read_string("shigatyper_notes.txt")
    File shigatyper_hits_tsv = "~{samplename}_hits.tsv" # A tab-delimited detailed report file
    File shigatyper_summary_tsv = "~{samplename}_summary.tsv" # A tab-delimited summary report file
    String shigatyper_version = read_string("VERSION")
    String shigatyper_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: cpus
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 0
  }
}

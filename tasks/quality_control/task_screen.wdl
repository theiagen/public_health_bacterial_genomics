version 1.0

task check_reads {
  input {
    File read1
    File read2
    Int? min_reads = 7472
  }
  command <<<
    # set cat command based on compression
    if [[ "~{read1}" == *".gz" ]] ; then
      cat_reads="zcat"
    else
      cat_reads="cat"
    fi

    # count number of reads
    read1_num=`eval "$cat_reads ~{read1}" | awk '{s++}END{print s/4}'`
    read2_num=`eval "$cat_reads ~{read2}" | awk '{s++}END{print s/4}'`

    # if below the min_read number, set pass/fail flag
    if [ "${read1_num}" -le "~{min_reads}" ] || [ "${read2_num}" -le "~{min_reads}" ]; then
      flag="FAIL; the number of reads is below the minimum of ~{min_reads}"
    else
      flag="PASS"
    fi

    echo $flag | tee FLAG
  >>>
  output {
    String pass_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: ""
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task check_basepairs {
  input {
    File read1
    File read2
    Int? min_basepairs = 2241820
  }
  command <<<
    # set cat command based on compression
    if [[ "~{read1}" == *".gz" ]] ; then
      cat_reads="zcat"
    else
      cat_reads="cat"
    fi

    read1_bp=`eval "${cat_reads} ~{read1}" | paste - - - - | cut -f2 | tr -d '\n' | wc -c`
    read2_bp=`eval "${cat_reads} ~{read2}" | paste - - - - | cut -f2 | tr -d '\n' | wc -c`

    if [ "${read1_bp}" -le "~{min_basepairs}" ] || [ "${read2_bp}" -le "~{min_basepairs}" ] ; then
      flag="FAIL; the number of basepairs is below the minimum of ~{min_basepairs}"
    else
      flag="PASS"
    fi

    echo $flag | tee FLAG
  >>>
  output {
    String pass_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: ""
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task check_genome_size {
  input {
    File assembly_Fasta
    Int? min_genome_size = 100000
    Int? max_genome_size = 18040666
  }
  command <<<
  # Robert used mash sketch to estimate genome size here.
  echo "test"
  >>>
  output {
    String pass_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: ""
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task check_coverage {
  input {
    File read1
    File read2
    Int? min_coverage = 10
  }
  command <<<
  echo "test"
  >>>
  # was this done before or after?
  output {
    String pass_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: ""
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  } 
}

task check_proportion {
  input {
    File read1
    File read2
    Float? min_proportion = 0.5
  }
  command <<<
  echo "test"
  >>>
  # i can't remember what this was used for
  output {
    String pass_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: ""
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}


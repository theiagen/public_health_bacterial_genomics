version 1.0

workflow compile_results {

  input {
    Array[String]    SRR_array
    Array[File]      serotypefinder_array
    Array[File]      abricate_array
    Array[File]      amrfinderplus_array
  }

  call compile_serotypefinder{
    input:
      array1=SRR_array
      array2=serotypefinder_array
  }

  call compile_abricate {
    input:
      array1=SRR_array
      array2=abricate_array
  }

  call compile_amrfinderplus {
    input:
      array1=SRR_array
      array2=amrfinderplus_array
  }

  output {
    File      compiled_serotypefinder_results=compile_serotypefinder.
    File      compiled_abricate_results=compile_abricate.
    File      compiled_amrfinderplus_results=compile_amrfinderplus.
  }
}

task compile_serotypefinder {
  input {
    Array[String]     array_srr
    Array[File]       array_stf
  }

  command {
    for index in ${!array_[*]}
    do

    echo "${array[$index]} is in ${array2[$index]}"
    done
  }

  output {

  }

  runtime {

  }

}






task fastANI {
  input {
    Array[File]   fasta_genomes
  }

  command {
    fastANI --version | head -1 | tee VERSION
    touch genomes.txt
    mkdir fasta_files
    cp ${sep=" " fasta_genomes} ./fasta_files/
    ls ./fasta_files >> genomes.txt
    mv ./fasta_files/* .

    fastANI \
    ${"--ql genomes.txt"} \
    ${"--rl genomes.txt"} \
    -o fastANI_results.txt
  }

  output {
    File        fastANI_results="fastANI_results.txt"
    File        genomes="genomes.txt"
  }

  runtime {
    docker:       "staphb/fastani:1.1"
    memory:       "128 GB"
    cpu:          32
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}

version 1.0

task kleborate_one_sample {
  # Inputs
  input {
    File kleb_assembly
    String samplename
    String kleborate_docker_image = "staphb/kleborate:2.0.4"
  }

  # Command
  # Included --all (which includes --resistance and --kaptive)
  command<<<
    # Print and save date
    date | tee DATE
    # Print and save version
    kleborate --version > VERSION && sed -i -e 's/^/Kleborate /' VERSION
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
    kleborate -a ~{kleb_assembly} --all -o ~{samplename}_kleborate_output_file.tsv \
    #####mv Kleborate_results.txt ${samplename}_kleborate_output_file.tsv
  >>>

  # Outputs
  output {
    File kleborate_output_file = "~{samplename}_kleborate_output_file.tsv"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }

  runtime {
    docker:       "~{kleborate_docker_image}"
    memory:       "4 GB"
    cpu:          2
    disks:        "local-disk 64 SSD"
    preemptible:  0
  }
}

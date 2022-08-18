version 1.0

task seroba {
  input {
    File read1
    File? read2
    String samplename
  }
  command <<<
    echo "hi"
  >>>
  output {

  }
  runtime {
    docker: "staphb/seroba:1.0.2"
    memory: "16 GB"
    cpu: 8
    disks: "local-disk 100 SSD"
  }
}
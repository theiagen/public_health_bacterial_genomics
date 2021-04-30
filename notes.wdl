task test {
  input {
    ....
  }
  command {
    ....
    ls >> directory.txt
  }
  output {
    File    dir_output="directory.txt"
  }
  runtime{
    ....
  }
}


java -jar ~/Downloads/womtool-53.1.jar validate ~/git/bacterial-characterization/ecoli_char.wdl

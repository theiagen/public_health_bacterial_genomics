version 1.0

task check_reads {
  input {
    File read1
    File read2
    Int? min_reads = 7472
    Int? min_basepairs = 2241820
    Int? min_genome_size = 100000
    Int? max_genome_size = 18040666
    Int? min_coverage = 10
    Int? min_proportion = 50
    Boolean? skip_screen = false 
  }
  command <<<
    flag="PASS"

    if [[ "~{skip_screen}" = "false" ]] ; then
      
      # set cat command based on compression
      if [[ "~{read1}" == *".gz" ]] ; then
        cat_reads="zcat"
      else
        cat_reads="cat"
      fi

      # count number of reads
      # sometimes fastqs do not have 4 lines per read, so this might fail one day
      read1_num=`eval "$cat_reads ~{read1}" | awk '{s++}END{print s/4}'`
      read2_num=`eval "$cat_reads ~{read2}" | awk '{s++}END{print s/4}'`
      # awk '{s++}END{print s/4' counts the number of lines and divides them by 4
      # key assumption: in fastq there will be four lines per read

      # if below the min_read number, set pass/fail flag
      if [ "${read1_num}" -le "~{min_reads}" ] || [ "${read2_num}" -le "~{min_reads}" ]; then
        flag="FAIL; the number of reads is below the minimum of ~{min_reads}"
      else
        flag="PASS"
      fi

      # set proportion variables for easy comparison
      percent_read1=$((read1_num / read2_num * 100))
      percent_read2=$((read2_num / read1_num * 100))

      # compare proportion here 
      if [ "$flag" = "PASS" ] ; then
        if [ "percent_read1" -lt "~min_proportion" ] ; then
          flag="FAIL; more than 50 percent of the reads are present in ~{read2} than ~{read1}"
        elif [ "$percent_read2" -lt "~min_proportion" ] ; then
          flag="FAIL; more than 50 percent of the reads are present in ~{read1} than ~{read2}"
        else
          flag="PASS"
        fi
      fi

      # if passes first check, continue to second check
      if [ "${flag}" = "PASS" ]; then
        # count number of basepairs
        # this only works if the fastq has 4 lines per read, so this might fail one day
        read1_bp=`eval "${cat_reads} ~{read1}" | paste - - - - | cut -f2 | tr -d '\n' | wc -c`
        read2_bp=`eval "${cat_reads} ~{read2}" | paste - - - - | cut -f2 | tr -d '\n' | wc -c`
        # paste - - - - (print 4 consecutive lines in one row, tab delimited)
        # cut -f2 print only the second column (the second line of the fastq 4-line)
        # tr -d '\n' removes line endings
        # wc -c counts characters

        # if below the min_basepairs number, set pass/fail flag
        if [ "${read1_bp}" -le "~{min_basepairs}" ] || [ "${read2_bp}" -le "~{min_basepairs}" ] ; then
          flag="FAIL; the number of basepairs is below the minimum of ~{min_basepairs}"
        else
          flag="PASS"
        fi    
      fi # closes second check

      #if passes second check, continue to third check
      if [ "${flag}" = "PASS" ]; then
        # determine genome size
              
        # First Pass
        mash sketch -o test -k 31 -m 3 -r ~{read1} ~{read2} > mash-output.txt 2>&1
        grep "Estimated genome size:" mash-output.txt | \
          awk '{if($4){printf("%d", $4)}} END {if (!NR) print "0"}' > genome_size_output
        grep "Estimated coverage:" mash-output.txt | \
          awk '{if($3){printf("%d", $3)}} END {if (!NR) print "0"}' > coverage_output
        rm -rf test.msh
        rm -rf mash-output.txt
        estimated_genome_size=`head -n1 genome_size_output`
        estimated_coverage=`head -n1 coverage_output`

        # Check if second pass is needed
        if [ ${estimated_genome_size} -gt "~{max_genome_size}" ] || [ ${estimated_genome_size} -lt "~{min_genome_size}" ] ; then
          # Probably high coverage, try increasing number of kmer copies to 10
          M="-m 10"
          if [ ${estimated_genome_size} -lt "~{min_genome_size}" ]; then
            # Probably low coverage, try decreasing the number of kmer copies to 1
            M="-m 1"
          fi
          mash sketch -o test -k 31 ${M} -r ~{read1} ~{read2} > mash-output.txt 2>&1
          grep "Estimated genome size:" mash-output.txt | \
            awk '{if($4){printf("%d", $4)}} END {if (!NR) print "0"}' > genome_size_output
          grep "Estimated coverage:" mash-output.txt | \
            awk '{if($3){printf("%d", $3)}} END {if (!NR) print "0"}' > coverage_output
          rm -rf test.msh
          rm -rf mash-output.txt
        fi
        
        estimated_genome_size=`head -n1 genome_size_output`
        estimated_coverage=`head -n1 coverage_output`

        # if below/above min/max genome size, set pass/fail flag
        if [ "${estimated_genome_size}" -ge "~{max_genome_size}" ] ; then
          flag="FAIL; the genome size is estimated to be larger than the maximum of ~{max_genome_size} bps"
        elif [ "${estimated_genome_size}" -le "~{min_genome_size}" ] ; then
          flag="FAIL; the genome size is estimated to be smaller than the minimum of ~{min_genome_size} bps"
        else
          flag="PASS"   
          if [ "${estimated_coverage}" -le "~{min_coverage}" ] ; then
            flag="FAIL; the estimated coverage is less than the minimum of ~{min_coverage}x"
          else
            flag="PASS"
          fi    
        fi    

    
      fi # third and fourth check close

    fi # closes if skip_screen == "False" check
    echo $flag | tee FLAG
  >>>
  output {
    # do something fancy to only output one variable
    String read_screen = read_string("FLAG")
  }
  runtime { ### NOT SURE
    docker: "quay.io/bactopia/gather_samples:2.0.2"
    memory: "2 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

# proportion : 100 in R1 20 in R2, R2 needs to be at least 50% of R1 and/or vice versa
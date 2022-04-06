version 1.0

task ncbi_prep_one_sample {
  input {
    File read1
    File read2
    # Required Metadata (TheiaCoV GC Outputs)
    String sample_id
    # Required Metadata (User Inputs)
    #String collection_date
    String filetype = "fastq"
    String instrument_model = "Illumina MiSeq"
    String library_layout = "paired"
    String library_selection = "RANDOM"
    String library_source = "GENOMIC"
    String library_strategy = "WGS"
    String organism
    String seq_platform = "ILLUMINA"
    String geo_loc_name = "USA:CA"
    String lat_lon = "missing"
    String county_id = "CA-Contra Costa"
    String design_description = "MiSeq Nextera XT shotgun sequencing of cultured isolate"
    #optional metadata
    String? serovar
    String? biosample_accession = "{populate_with_bioSample_accession}"
    #runtime
    String docker_image = "quay.io/staphb/vadr:1.3"
    Int  memory = 1
    Int cpu = 1
    Int disk_size = 25
    Int preemptible_tries = 0
  }

  command <<<
    if (echo "${sample_id}" | grep -i "GB";)
    then
      ISOLATION_SOURCE="Ground Beef"
    elif (echo "${sample_id}" | grep -i "CB";)
    then
      ISOLATION_SOURCE="Chicken Breast"
    else
      ISOLATION_SOURCE="error"
    fi

    if (echo "${sample_id}" | grep -i -- "-S";)
    then
      BIOPROJECT_ACCESSION="PRJNA292661"
    elif (echo "${sample_id}" | grep -i -- "-C";)
    then
      BIOPROJECT_ACCESSION="PRJNA292664"
    else
      BIOPROJECT_ACCESSION="error"
    fi

    COLLECTION_DATE=($(echo "${sample_id}" | grep -o '[0-9]\+' | tr -d '\n' | head -c 4))
    COLLECTION_DATE=($(echo 20${COLLECTION_DATE:0:2}-${COLLECTION_DATE:2:4}))

    #echo "${sample_id}" | grep -o '[0-9]\+' | tr -d '\n' | head -c 4 | tee COLLECTION_DATE
    #echo 20${COLLECTION_DATE:0:2}-${COLLECTION_DATE:2:4} | tee COLLECTION_DATE
    
    #Format BioSample Attributes
    echo -e "*sample_name\tsample_title\tbioproject_accession\t*organism\tstrain\tisolate\t*collected_by\t*collection_date\t*geo_loc_name\t*isolation_source\t*lat_lon\tculture_collection\tgenotype\tpassage_history\tpathotype\tserotype\tserovar\tsubgroup\tsubtype\tdescription" > ~{sample_id}_biosample_attributes.tsv    
    echo -e "~{sample_id}\t\t${BIOPROJECT_ACCESSION}\t~{organism}\t~{sample_id}\t\t~{county_id}\t${COLLECTION_DATE}\t~{geo_loc_name}\t${ISOLATION_SOURCE}\t~{lat_lon}\t\t\t\t\t\t~{serovar}\t\t\t" >> ~{sample_id}_biosample_attributes.tsv    
    #Format SRA Reads & Metadata
    cp ~{read1} ~{sample_id}_R1.fastq.gz
    cp ~{read2} ~{sample_id}_R2.fastq.gz

    echo -e "bioproject_accession\tlibrary_ID\ttitle\tlibrary_strategy\tlibrary_source\tlibrary_selection\tlibrary_layout\tplatform\tinstrument_model\tdesign_description\tfiletype\tfilename\tfilename2\tfilename3\tfilename4\tassembly\tfasta_file" > ~{sample_id}_sra_metadata.tsv    
    echo -e "${BIOPROJECT_ACCESSION}\t~{sample_id}\tGenomic sequencing of ~{organism}: ${ISOLATION_SOURCE}\t~{library_strategy}\t~{library_source}\t~{library_selection}\t~{library_layout}\t~{seq_platform}\t~{instrument_model}\t~{design_description}\t~{filetype}\t~{sample_id}_R1.fastq.gz\t~{sample_id}_R2.fastq.gz\t\t\t\t" >> ~{sample_id}_sra_metadata.tsv
  >>>
  output {
    File biosample_attributes = "~{sample_id}_biosample_attributes.tsv"
    File sra_metadata = "~{sample_id}_sra_metadata.tsv"
    File sra_read1 = "~{sample_id}_R1.fastq.gz"
    File sra_read2 = "~{sample_id}_R2.fastq.gz"
    Array[File] sra_reads = ["~{sample_id}_R1.fastq.gz","~{sample_id}_R2.fastq.gz"]
  }
  runtime {
    docker: "~{docker_image}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: preemptible_tries
    maxRetries: 3
  }
}

task compile_biosamp_n_sra {
  input {
    Array[File] single_submission_biosample_attirbutes
    Array[File] single_submission_sra_metadata
    Array[String] single_submission_sra_reads
    String date
    String? gcp_bucket
    String docker = "quay.io/theiagen/utility:1.1"
    Int memory = 16
    Int cpu = 4
    Int disk_size = 100
    Int preemptible = 0
}
  command <<<
  biosample_attributes_array=(~{sep=' ' single_submission_biosample_attirbutes})
  biosample_attributes_array_len=$(echo "${#biosample_attributes_array[@]}")
  sra_metadata_array=(~{sep=' ' single_submission_sra_metadata})
  sra_metadata_array_len=$(echo "${#sra_metadata_array[@]}")
  sra_reads_array="~{sep=' ' single_submission_sra_reads}"
  sra_reads_arra_len=$(echo "${#sra_reads_arra[@]}")
  
  # Compile BioSample attributes
  biosamp_count=0
  for i in ${biosample_attributes_array[*]}; do
      # grab header from first sample in meta_array
      while [ "${biosamp_count}" -lt 1 ]; do
        head -n -1 $i > biosample_attributes_~{date}.tsv
        biosamp_count+=1
      done
      #populate csv with each samples metadata
      tail -n1 $i >> biosample_attributes_~{date}.tsv
  done
  
  # Compile SRA metadata
  sra_count=0
  for i in ${sra_metadata_array[*]}; do
      # grab header from first sample in meta_array
      while [ "${sra_count}" -lt 1 ]; do
        head -n -1 $i > sra_metadata_~{date}.tsv
        sra_count+=1
      done
      #populate csv with each samples metadata
      tail -n1 $i >> sra_metadata_~{date}.tsv
  done
  
  # move sra read data to gcp bucket if one is specified; zip into single file if not
  if [[ ! -z "~{gcp_bucket}" ]]
  then 
    echo "Moving read data to provided GCP Bucket ~{gcp_bucket}"
    echo "Running: gsutil -m cp -n ${sra_reads_array[@]} ~{gcp_bucket}"
    gsutil -m cp -n ${sra_reads_array[@]} ~{gcp_bucket}       
  else 
    echo "Preparing SRA read data into single zipped-file"
    mkdir sra_reads_~{date} 
    for i in ${sra_reads_array[*]}; do
      mv $i sra_reads_~{date}
    done  
    zip -r sra_reads_~{date}.zip sra_reads_~{date}
  fi
  >>>
  output {
    File biosample_attributes = "biosample_attributes_~{date}.tsv"
    File sra_metadata = "sra_metadata_~{date}.tsv"
    File? sra_zipped = "sra_reads_~{date}.zip"
  }
  runtime {
    docker: docker
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: preemptible
    maxRetries: 3
  }
}
version 1.0

task export_taxon_tables {
  input {
    String terra_project
    String terra_workspace
    String sample_taxon
    File taxon_tables
    String samplename = samplename
  }
  command <<<
    # capture taxon and corresponding table names from input taxon_tables
    taxon_array=($(cut -f1 ${taxon_tables} | tail +2))
    table_array=($(cut -f2 ${taxon_tables} | tail +2))
    # remove whitespace from sample_taxon
    sample_taxon=$(echo ~{sample_taxon} | tr ' ' '_')
    # set taxon and table vars
    for index in ${!taxon_array[@]}; do
      taxon=${taxon_array[$index]}
      table=${table_array[$index]}
      if [[ "${sample_taxon}" == *"${taxon}"* ]]; then
        sample_table=${table}
        echo "Sample"
      
  
    python3 /scripts/export_large_tsv/export_large_tsv.py --project ~{terra_project} --workspace ~{terra_workspace} --entity_type ~{datatable1} --tsv_filename ~{datatable1}

    python3 /scripts/export_large_tsv/export_large_tsv.py --project ~{terra_project} --workspace ~{terra_workspace} --entity_type ~{datatable2} --tsv_filename ~{datatable2}
  >>>
  runtime {
    docker: "broadinstitute/terra-tools:tqdm"
    memory: "1 GB"
    cpu: 1
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
  output {
    File datatable1_tsv = "~{datatable1}"
    File datatable2_tsv = "~{datatable2}"
  }
}

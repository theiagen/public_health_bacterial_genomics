version 1.0

task export_taxon_tables {
  input {
    String terra_project
    String terra_workspace
    String sample_taxon
    File? taxon_tables
    String samplename 
    # TheiaProk Outputs
    File? reads
    File? read1
    File? read2
    String theiaprok_illumina_pe_version
    String theiaprok_illumina_pe_analysis_date
    String seq_platform
    Int num_reads_raw1
    Int num_reads_raw2
    String num_reads_raw_pairs
    String fastq_scan_version
    Int num_reads_clean1
    Int num_reads_clean2
    String num_reads_clean_pairs
    String trimmomatic_version
    String bbduk_docker
    Float r1_mean_q
    Float? r2_mean_q
    File assembly_fasta
    File contigs_gfa
    String shovill_pe_version
    File quast_report
    String quast_version
    Int genome_length
    Int number_contigs
    File cg_pipeline_report
    String cg_pipeline_docker
    Float est_coverage
    File gambit_report
    Float gambit_closest_distance
    String gambit_predicted_taxon
    String gambit_predicted_rank
    String gambit_version
    String gambit_db_version
    String gambit_docker
    File abricate_amr_results
    String abricate_amr_database
    String abricate_amr_version
    File? serotypefinder_report
    String? serotypefinder_docker
    String? serotypefinder_serotype
    File? ectyper_results
    String? ectyper_version
    File? lissero_results
    String? lissero_version
    File? sistr_results
    File? sistr_allele_json
    File? sister_allele_fasta
    File? sistr_cgmlst
    String? sistr_version
    File? seqsero2_report
    String? seqsero2_version
    String? seqsero2_predicted_antigenic_profile
    String? seqsero2_predicted_serotype
    String? seqsero2_predicted_contamination
    File? kleborate_output_file
    String? kleborate_version
    String? kleborate_key_resistance_genes
    String? kleborate_genomic_resistance_mutations
    
  }
  command <<<
  
    # capture taxon and corresponding table names from input taxon_tables
    taxon_array=($(cut -f1 ~{taxon_tables} | tail +2))
    echo "Taxon array: ${taxon_array[*]}"
    table_array=($(cut -f2 ~{taxon_tables} | tail +2))
    echo "Table array: ${table_array[*]}"
    # remove whitespace from sample_taxon
    sample_taxon=$(echo ~{sample_taxon} | tr ' ' '_')
    echo "Sample taxon: ${sample_taxon}"
    # set taxon and table vars
    echo "Checking if sample taxon should be exported to user-specified taxon table..."
    for index in ${!taxon_array[@]}; do
      taxon=${taxon_array[$index]}
      echo "Taxon: ${taxon}"
      table=${table_array[$index]}
      echo "Table: ${table}"
      if [[ "${sample_taxon}" == *"${taxon}"* ]]; then
        sample_table=${table}
        echo "Sample ~{samplename} identified as ~{sample_taxon}. As per user-defined taxon tables, ${taxon} samples will be exported to the ${table} terra data table"
        break
      else 
        echo "${sample_taxon} does not match ${taxon}."
      fi
    done
    if [ ! -z ${sample_table} ]; then
       # create single-entity sample data table
       ## header
      echo -e "entity:${sample_table}_id\treads\tread1\tread2\ttheiaprok_illumina_pe_version\ttheiaprok_illumina_pe_analysis_date\tseq_platform\tnum_reads_raw1\tnum_reads_raw2\tnum_reads_raw_pairs\tfastq_scan_version\tnum_reads_clean1\tnum_reads_clean2\tnum_reads_clean_pairs\ttrimmomatic_version\tbbduk_docker\tr1_mean_q\tr2_mean_q\tassembly_fasta\tcontigs_gfa\tshovill_pe_version\tquast_report\tquast_version\tgenome_length\tnumber_contigs\tcg_pipeline_report\tcg_pipeline_docker\test_coverage\tgambit_report\tgambit_closest_distance\tgambit_predicted_taxon\tgambit_predicted_rank\tgambit_version\tgambit_db_version\tgambit_docker\tabricate_amr_results\tabricate_amr_database\tabricate_amr_version\tserotypefinder_report\tserotypefinder_docker\tserotypefinder_serotype\tectyper_results\tectyper_version\tlissero_results\tlissero_version\tsistr_results\tsistr_allele_json\tsister_allele_fasta\tsistr_cgmlst\tsistr_version\tseqsero2_report\tseqsero2_version\tseqsero2_predicted_antigenic_profile\tseqsero2_predicted_serotype\tseqsero2_predicted_contamination\tkleborate_output_file\tkleborate_version\tkleborate_key_resistance_genes\tkleborate_genomic_resistance_mutations" > ~{samplename}_terra_table.tsv
      ## TheiaProk Outs
      echo -e "~{samplename}\t~{reads}\t~{read1}\t~{read2}\t~{theiaprok_illumina_pe_version}\t~{theiaprok_illumina_pe_analysis_date}\t~{seq_platform}\t~{num_reads_raw1}\t~{num_reads_raw2}\t~{num_reads_raw_pairs}\t~{fastq_scan_version}\t~{num_reads_clean1}\t~{num_reads_clean2}\t~{num_reads_clean_pairs}\t~{trimmomatic_version}\t~{bbduk_docker}\t~{r1_mean_q}\t~{r2_mean_q}\t~{assembly_fasta}\t~{contigs_gfa}\t~{shovill_pe_version}\t~{quast_report}\t~{quast_version}\t~{genome_length}\t~{number_contigs}\t~{cg_pipeline_report}\t~{cg_pipeline_docker}\t~{est_coverage}\t~{gambit_report}\t~{gambit_closest_distance}\t~{gambit_predicted_taxon}\t~{gambit_predicted_rank}\t~{gambit_version}\t~{gambit_db_version}\t~{gambit_docker}\t~{abricate_amr_results}\t~{abricate_amr_database}\t~{abricate_amr_version}\t~{serotypefinder_report}\t~{serotypefinder_docker}\t~{serotypefinder_serotype}\t~{ectyper_results}\t~{ectyper_version}\t~{lissero_results}\t~{lissero_version}\t~{sistr_results}\t~{sistr_allele_json}\t~{sister_allele_fasta}\t~{sistr_cgmlst}\t~{sistr_version}\t~{seqsero2_report}\t~{seqsero2_version}\t~{seqsero2_predicted_antigenic_profile}\t~{seqsero2_predicted_serotype}\t~{seqsero2_predicted_contamination}\t~{kleborate_output_file}\t~{kleborate_version}\t~{kleborate_key_resistance_genes}\t~{kleborate_genomic_resistance_mutations}"  >> ~{samplename}_terra_table.tsv
      # modify file paths to GCP URIs
      sed -i 's/\/cromwell_root\//gs:\/\//g' ~{samplename}_terra_table.tsv
      # export table 
      python3 /scripts/import_large_tsv/import_large_tsv.py --project ~{terra_project} --workspace ~{terra_workspace} --tsv ~{samplename}_terra_table.tsv
    else
      echo "Table not defined for ~{sample_taxon}"
    fi
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
    File? datatable1_tsv = "~{samplename}_terra_table.tsv"
  }
}

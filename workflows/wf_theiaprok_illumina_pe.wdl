version 1.0

import "wf_read_QC_trim.wdl" as read_qc
import "wf_merlin_magic.wdl" as merlin_magic
import "../tasks/assembly/task_shovill.wdl" as shovill
import "../tasks/quality_control/task_quast.wdl" as quast
import "../tasks/quality_control/task_cg_pipeline.wdl" as cg_pipeline
import "../tasks/taxon_id/task_gambit.wdl" as gambit
import "../tasks/gene_typing/task_abricate.wdl" as abricate
import "../tasks/species_typing/task_serotypefinder.wdl" as serotypefinder
import "../tasks/task_versioning.wdl" as versioning

workflow theiaprok_illumina_pe {
  meta {
    description: "De-novo genome assembly, taxonomic ID, and QC of paired-end bacterial NGS data"
  }
  input {
    String samplename
    String seq_method = "ILLUMINA"
    File read1_raw
    File read2_raw
  }
  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw = read1_raw,
      read2_raw = read2_raw
  }
  call shovill.shovill_pe {
    input:
      samplename = samplename,
      read1_cleaned = read_QC_trim.read1_clean,
      read2_cleaned = read_QC_trim.read2_clean
  }
  call quast.quast {
    input:
      assembly = shovill_pe.assembly_fasta,
      samplename = samplename
  }
  call cg_pipeline.cg_pipeline {
    input:
      read1 = read1_raw,
      read2 = read2_raw,
      samplename = samplename,
      genome_length = quast.genome_length
  }
  call gambit.gambit {
    input:
      assembly = shovill_pe.assembly_fasta,
      samplename = samplename
  }
  call abricate.abricate as abricate_amr {
    input:
      assembly = shovill_pe.assembly_fasta,
      samplename = samplename,
      database = "ncbi"
  }
  call merlin_magic.merlin_magic {
    input:
      merlin_tag = gambit.merlin_tag,
      assembly = shovill_pe.assembly_fasta,
      samplename = samplename,
      read1 = read_QC_trim.read1_clean,
      read2 = read_QC_trim.read2_clean
  }
  call versioning.version_capture{
    input:
  }
  output {
    # Version Capture
    String apollo_illumina_pe_version = version_capture.phbg_version
    String apollo_illumina_pe_analysis_date = version_capture.date
   # Read Metadata
    String seq_platform	=	seq_method
    # Read QC
    Int num_reads_raw1 = read_QC_trim.fastq_scan_raw1
    Int num_reads_raw2 = read_QC_trim.fastq_scan_raw2
    String num_reads_raw_pairs = read_QC_trim.fastq_scan_raw_pairs
    String fastq_scan_version = read_QC_trim.fastq_scan_version
    Int num_reads_clean1 = read_QC_trim.fastq_scan_clean1
    Int num_reads_clean2 = read_QC_trim.fastq_scan_clean2
    String num_reads_clean_pairs = read_QC_trim.fastq_scan_clean_pairs
    String trimmomatic_version = read_QC_trim.trimmomatic_version
    String bbduk_docker = read_QC_trim.bbduk_docker
    Float r1_mean_q = cg_pipeline.r1_mean_q
    Float? r2_mean_q = cg_pipeline.r2_mean_q
    # Assembly and Assembly QC
    File assembly_fasta = shovill_pe.assembly_fasta
    File contigs_gfa = shovill_pe.contigs_gfa
    String shovill_pe_version = shovill_pe.shovill_version
    File quast_report = quast.quast_report
    String quast_version = quast.version
    Int genome_length = quast.genome_length
    Int number_contigs = quast.number_contigs
    File cg_pipeline_report = cg_pipeline.cg_pipeline_report
    String cg_pipeline_docker = cg_pipeline.cg_pipeline_docker
    Float est_coverage = cg_pipeline.est_coverage
    # Taxon ID
    File gambit_report = gambit.gambit_report_file
    Float gambit_closest_distance = gambit.gambit_closest_distance
    String gambit_predicted_taxon = gambit.gambit_predicted_taxon
    String gambit_predicted_rank = gambit.gambit_predicted_rank
    String gambit_version = gambit.gambit_version
    String gambit_db_version = gambit.gambit_db_version
    String gambit_docker = gambit.gambit_docker
    # AMR Screening
    File abricate_amr_results = abricate_amr.abricate_results
    String abricate_amr_database = abricate_amr.abricate_database
    String abricate_amr_version = abricate_amr.abricate_version
    # Ecoli Typing
    File? serotypefinder_report = merlin_magic.serotypefinder_report
    String? serotypefinder_docker = merlin_magic.serotypefinder_docker
    String? serotypefinder_serotype = merlin_magic.serotypefinder_serotype
    File? ectyper_results = merlin_magic.ectyper_results
    String? ectyper_version = merlin_magic.ectyper_version
    # Listeria Typing
    File? lissero_results = merlin_magic.lissero_results
    String lissero_version = merlin_magic.lissero_version
    # Salmonella Typing
    File? sistr_results = merlin_magic.sistr_results
    File? sistr_allele_json = merlin_magic.sistr_allele_json
    File? sister_allele_fasta = merlin_magic.sistr_allele_fasta
    File? sistr_cgmlst = merlin_magic.sistr_cgmlst
    String? sistr_version = merlin_magic.sistr_version
    File? seqsero2_report = merlin_magic.seqsero2_report
    String? seqsero2_version = merlin_magic.seqsero2_version
    String? seqsero2_predicted_antigenic_profile = merlin_magic.seqsero2_predicted_antigenic_profile
    String? seqsero2_predicted_serotype = merlin_magic.seqsero2_predicted_serotype
    String? seqsero2_predicted_contamination = merlin_magic.seqsero2_predicted_contamination
  }
}
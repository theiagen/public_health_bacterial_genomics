version 1.0

import "wf_read_QC_trim_se.wdl" as read_qc
import "../tasks/task_qc_utils.wdl" as qc
import "../tasks/task_taxon_id.wdl" as taxon_id
import "../tasks/task_denovo_assembly.wdl" as assembly
import "../tasks/task_versioning.wdl" as versioning

workflow apollo_illumina_pe {
  meta {
    description: "De-novo genome assembly, taxonomic ID, and QC of paired-end bacterial NGS data"
  }

  input {
    String samplename
    String seq_method = "ILLUMINA"
    File read1_raw
  }

  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw = read1_raw,
  }
  call assembly.shovill_se {
    input:
      samplename = samplename,
      read1_cleaned = read_QC_trim.read1_clean
  }
  call qc.quast {
    input:
      assembly = shovill_se.assembly_fasta,
      samplename = samplename
  }
  call qc.cg_pipeline {
    input:
      read1 = read1_raw,
      samplename = samplename,
      genome_length = quast.genome_length
  }
  call taxon_id.gambit {
    input:
      assembly = shovill_se.assembly_fasta,
      samplename = samplename
  }
  call versioning.version_capture{
    input:
  }
  output {
    String apollo_illumina_pe_version = version_capture.phbg_version
    String apollo_illumina_pe_analysis_date = version_capture.date
        
    String seq_platform	=	seq_method

    Int fastqc_raw = read_QC_trim.fastqc_number_reads
    String fastqc_version = read_QC_trim.fastqc_version
    Int fastqc_clean = read_QC_trim.fastqc_clean_number_reads
    
    String trimmomatic_version = read_QC_trim.trimmomatic_version
    String bbduk_docker = read_QC_trim.bbduk_docker

    File assembly_fasta = shovill_se.assembly_fasta
    File contigs_gfa = shovill_se.contigs_gfa
    String shovill_se_version = shovill_se.shovill_version
    
    File quast_report = quast.quast_report
    String quast_version = quast.version
    Int genome_length = quast.genome_length
    Int number_contigs = quast.number_contigs
    
    File cg_pipeline_report = cg_pipeline.cg_pipeline_report
    String cg_pipeline_docker = cg_pipeline.cg_pipeline_docker
    Float r1_mean_q = cg_pipeline.r1_mean_q
    Float est_coverage = cg_pipeline.est_coverage
    
    File gambit_report = gambit.gambit_report
    String gambit_docker = gambit.gambit_docker
    Float gambit_distance = gambit.gambit_distance
    String gambit_taxon = gambit.gambit_taxon
    String gambit_rank = gambit.gambit_rank

  }
}

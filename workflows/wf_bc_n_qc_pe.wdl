version 1.0

import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_qc_utils.wdl" as qc
import "../tasks/task_taxon_id.wdl" as taxon_id
import "../tasks/task_denovo_assembly.wdl" as assembly

workflow bc_n_qc_pe {
  meta {
    description: "De-novo genome assembly, taxonomic ID, and QC of paired-end bacterial NGS data"
  }

  input {
    String  samplename
    String  seq_method="Illumina paired-end"
    File    read1_raw
    File    read2_raw
  }

  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw  = read1_raw,
      read2_raw  = read2_raw
  }
  call assembly.shovill_pe {
    input:
      samplename=samplename,
      read1_cleaned=read_QC_trim.read1_clean,
      read2_cleaned=read_QC_trim.read2_clean
  }
  call qc.quast {
    input:
      assembly =  shovill_pe.assembly_fasta,
      samplename = samplename
  }
  call qc.cg_pipeline {
    input:
      read1 = read1_raw,
      read2 = read2_raw,
      samplename = samplename,
      genome_length = quast.genome_length
  }
  call taxon_id.midas_nsphl {
    input:
      assembly = shovill_pe.assembly_fasta,
      samplename = samplename
  }
  output {
  String	seq_platform	=	seq_method

  Int fastqc_raw1	=	read_QC_trim.fastqc_raw1
  Int	fastqc_raw2	=	read_QC_trim.fastqc_raw2
  String	fastqc_raw_pairs	=	read_QC_trim.fastqc_raw_pairs
  String	fastqc_version	=	read_QC_trim.fastqc_version

  Int	fastqc_clean1	=	read_QC_trim.fastqc_clean1
  Int	fastqc_clean2	=	read_QC_trim.fastqc_clean2
  String	fastqc_clean_pairs	=	read_QC_trim.fastqc_clean_pairs
  String	trimmomatic_version	=	read_QC_trim.trimmomatic_version
  String	bbduk_docker	=	read_QC_trim.bbduk_docker

  File  assembly_fasta =  shovill_pe.assembly_fasta
  File  contigs_gfa =  shovill_pe.contigs_gfa
  String   shovill_pe_version =  shovill_pe.shovill_version
  
  File quast_report = quast.quast_report
  String quast_version = quast.version
  Int genome_length = quast.genome_length
  Int number_contigs = quast.number_contigs
  
  File  cg_pipeline_report = cg_pipeline.cg_pipeline_report
  String  cg_pipeline_docker = cg_pipeline.cg_pipeline_docker
  Float r1_mean_q = cg_pipeline.r1_mean_q
  Float r2_mean_q = cg_pipeline.r2_mean_q
  Float est_coverage = cg_pipeline.est_coverage
  
  File  midas_nsphl_report = midas_nsphl.midas_nsphl_report
  String  midas_nsphl_docker = midas_nsphl.midas_nsphl_docker
  Float midas_delta = midas_nsphl.midas_delta
  String predicted_genus = midas_nsphl.predicted_genus
  String predicted_species = midas_nsphl.predicted_species

  }
}

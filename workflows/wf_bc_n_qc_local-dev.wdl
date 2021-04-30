version 1.0

import "wf_bc_n_qc_pe.wdl" as assembly

workflow bc_n_qc_local {
  input {
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
  }

  scatter (sample in inputSamples) {
    call assembly.bc_n_qc_pe {
      input:
        samplename = sample.left[0],
        read1_raw  = sample.right.left,
        read2_raw  = sample.right.right
    }
  }

  output {
    Array[String]	seq_platform	=	bc_n_qc_pe.seq_platform
    Array[File]	read1_clean	=	bc_n_qc_pe.read1_clean
    Array[File ]	read2_clean	=	bc_n_qc_pe.read2_clean
    Array[Int]	fastqc_raw1	=	bc_n_qc_pe.fastqc_raw1
    Array[Int]	fastqc_raw2	=	bc_n_qc_pe.fastqc_raw2
    Array[String]	fastqc_raw_pairs	=	bc_n_qc_pe.fastqc_raw_pairs
    Array[String]	fastqc_version	=	bc_n_qc_pe.fastqc_version
    Array[Int]	fastqc_clean1	=	bc_n_qc_pe.fastqc_clean1
    Array[Int]	fastqc_clean2	=	bc_n_qc_pe.fastqc_clean2
    Array[String]	fastqc_clean_pairs	=	bc_n_qc_pe.fastqc_clean_pairs
    Array[String]	trimmomatic_version	=	bc_n_qc_pe.trimmomatic_version
    Array[String]	bbduk_docker	=	bc_n_qc_pe.bbduk_docker
    Array[File]	assembly_fasta	=	bc_n_qc_pe.assembly_fasta
    Array[File]	contigs_gfa	=	bc_n_qc_pe.contigs_gfa
    Array[String]	shovill_pe_version	=	bc_n_qc_pe.shovill_pe_version
    Array[File]	cg_pipe_readMetrics	=	bc_n_qc_pe.cg_pipe_readMetrics
    Array[String]	cg_pipe_docker	=	bc_n_qc_pe.cg_pipe_docker
    Array[File]	midas_nsphl_report	=	bc_n_qc_pe.midas_nsphl_report
    Array[String]	midas_nsphl_docker	=	bc_n_qc_pe.midas_nsphl_docker

  }
}

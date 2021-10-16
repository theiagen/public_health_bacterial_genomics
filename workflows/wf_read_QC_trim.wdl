version 1.0

import "../tasks/task_qc_utils.wdl" as qc_utils
import "../tasks/task_read_clean.wdl" as read_clean

workflow read_QC_trim {
  meta {
    description: "Runs basic QC (FastQC), trimming (Trimmomatic), and adapter removal (bbduk) on illumina PE reads"
  }

  input {
    String  samplename
    File    read1_raw
    File    read2_raw
    Int?    trimmomatic_minlen = 75
    Int?    trimmomatic_quality_trim_score = 30
    Int?    trimmomatic_window_size = 4
    Int     bbduk_mem = 8
  }
  call read_clean.trimmomatic_pe {
    input:
      samplename = samplename,
      read1 = read1_raw,
      read2 = read2_raw,
      trimmomatic_minlen = trimmomatic_minlen,
      trimmomatic_quality_trim_score = trimmomatic_quality_trim_score,
      trimmomatic_window_size = trimmomatic_window_size
  }
  call read_clean.bbduk_pe {
    input:
      samplename = samplename,
      read1_trimmed = trimmomatic_pe.read1_trimmed,
      read2_trimmed = trimmomatic_pe.read2_trimmed,
      mem_size_gb = bbduk_mem
  }
  call qc_utils.fastqc_pe as fastqc_raw {
    input:
      read1 = read1_raw,
      read2 = read2_raw,
  }
  call qc_utils.fastqc_pe as fastqc_clean {
    input:
      read1 = bbduk_pe.read1_clean,
      read2 = bbduk_pe.read2_clean
  }

  output {
    File	read1_clean	=	bbduk_pe.read1_clean
    File	read2_clean	=	bbduk_pe.read2_clean

    Int	fastqc_raw1	=	fastqc_raw.read1_seq
    Int	fastqc_raw2	=	fastqc_raw.read2_seq
    String	fastqc_raw_pairs	=	fastqc_raw.read_pairs

    Int	fastqc_clean1	=	fastqc_clean.read1_seq
    Int	fastqc_clean2	=	fastqc_clean.read2_seq
    String	fastqc_clean_pairs	=	fastqc_clean.read_pairs

    String	fastqc_version	=	fastqc_raw.version
    String	bbduk_docker	=	bbduk_pe.bbduk_docker
    String	trimmomatic_version	=	trimmomatic_pe.version
  }
}

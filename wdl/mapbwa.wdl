version 1.0

workflow map_fastq_to_reference {
  input {
    File reference_fasta
    File fastq_read1
    File? fastq_read2
    String sample_name
    File bwa_index_amb
    File bwa_index_ann
    File bwa_index_bwt
    File bwa_index_pac
    File bwa_index_sa
    Int bwa_threads = 8
    Int samtools_threads = 4
  }

  # Task 1: Align FASTQ reads to the reference using bwa mem
  call align_reads {
    input:
      reference_fasta = reference_fasta,
      fastq_read1 = fastq_read1,
      fastq_read2 = fastq_read2,
      bwa_index_amb = bwa_index_amb,
      bwa_index_ann = bwa_index_ann,
      bwa_index_bwt = bwa_index_bwt,
      bwa_index_pac = bwa_index_pac,
      bwa_index_sa = bwa_index_sa,
      sample_name = sample_name,
      bwa_threads = bwa_threads
  }
}

task align_reads {
  input {
    File reference_fasta
    File fastq_read1
    File? fastq_read2
    File bwa_index_amb
    File bwa_index_ann
    File bwa_index_bwt
    File bwa_index_pac
    File bwa_index_sa
    String sample_name
    Int bwa_threads
  }

  # `bwa mem` requires the reference index files to be in the same directory as the FASTA.
  # The 'inputs' block ensures these files are localized together.
  command <<<
    bwa mem -t ~{bwa_threads} ~{reference_fasta} ~{fastq_read1} ~{fastq_read2} > ~{sample_name}.sam
  >>>

  output {
    File aligned_sam = "~{sample_name}.sam"
  }

  runtime {
    docker: "quay.io/biocontainers/bwa:0.7.19--h577a1d6_1"
    cpu: bwa_threads
  }
}


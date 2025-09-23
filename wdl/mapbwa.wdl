version 1.0

workflow map_fastq_to_reference {
  input {
    File reference_fasta
    File fastq_read1
    File? fastq_read2
    String sample_name
    Int bwa_threads = 8
    Int samtools_threads = 4
  }

  # Task 1: Index the reference genome
  # This task only needs to be run once for a given reference.
  call index_reference {
    input:
      reference_fasta = reference_fasta,
      bwa_threads = bwa_threads
  }

  # Task 2: Align FASTQ reads to the reference using bwa mem
  call align_reads {
    input:
      reference_fasta = reference_fasta,
      fastq_read1 = fastq_read1,
      fastq_read2 = fastq_read2,
      bwa_index_amb = index_reference.reference_amb,
      bwa_index_ann = index_reference.reference_ann,
      bwa_index_bwt = index_reference.reference_bwt,
      bwa_index_pac = index_reference.reference_pac,
      bwa_index_sa = index_reference.reference_sa,
      sample_name = sample_name,
      bwa_threads = bwa_threads
  }

  # Task 3: Sort and index the aligned BAM file
  call sort_and_index_bam {
    input:
      input_sam = align_reads.aligned_sam,
      sample_name = sample_name,
      samtools_threads = samtools_threads
  }

  output {
    File sorted_bam = sort_and_index_bam.sorted_bam
    File sorted_bam_index = sort_and_index_bam.sorted_bam_index
  }
}

task index_reference {
  input {
    File reference_fasta
    Int bwa_threads
  }

  command <<<
    bwa index -p reference ~{reference_fasta}
  >>>

  output {
    File reference_amb = "reference.fasta.amb"
    File reference_ann = "reference.fasta.ann"
    File reference_bwt = "reference.fasta.bwt"
    File reference_pac = "reference.fasta.pac"
    File reference_sa = "reference.fasta.sa"
  }

  runtime {
    docker: "biocontainers/bwa:v0.7.17-4-deb_cv1"
    cpu: bwa_threads
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
    docker: "biocontainers/bwa:v0.7.17-4-deb_cv1"
    cpu: bwa_threads
  }
}

task sort_and_index_bam {
  input {
    File input_sam
    String sample_name
    Int samtools_threads
  }

  command <<<
    samtools sort -@ ~{samtools_threads} -O bam -o ~{sample_name}.sorted.bam ~{input_sam}
    samtools index ~{sample_name}.sorted.bam
  >>>

  output {
    File sorted_bam = "~{sample_name}.sorted.bam"
    File sorted_bam_index = "~{sample_name}.sorted.bam.bai"
  }

  runtime {
    docker: "biocontainers/samtools:v1.18-2-deb_cv1"
    cpu: samtools_threads
  }
}

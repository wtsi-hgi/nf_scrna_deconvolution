process souporcell {
    // cf. https://github.com/wheaton5/souporcell
    tag "${samplename}"
    publishDir "${params.outdir}/souporcell/",
	mode: "${params.souporcell.copy_mode}",
	pattern: "souporcell_${samplename}",
	overwrite: true
    
    when: 
    params.souporcell.run

    input: 
    tuple val(samplename), path(bam_file), path(bai_file), path(barcodes_tsv_gz)
    file(reference_fastq)
    val(souporcell_n_clusters)
    
    output:
    tuple val(samplename), file("souporcell_${samplename}"), emit: souporcell_output_dir

    script:
    """
umask 2 # make files group_writable

if [[ ${barcodes_tsv_gz} =~ \\.gz\$ ]]; then
  echo \"${barcodes_tsv_gz} is gzipped\"
  zcat ${barcodes_tsv_gz} > bar_codes.txt
else
  echo \"${barcodes_tsv_gz} is not gzipped\"
  ln -s ${barcodes_tsv_gz} bar_codes.txt
fi

souporcell_pipeline.py \\
  -i ${bam_file} \\
  -b bar_codes.txt \\
  -f ${reference_fasta} \\
  -t ${task.cpus} \\ 
  -o \$PWD \\
  -k ${souporcell_n_clusters}
    """
}

//  -i ${bam_file} \\  /path/to/possorted_genome_bam.bam -b /path/to/barcodes.tsv -f /path/to/reference.fasta -t num_threads_to_use -o output_dir_name -k num_clusters

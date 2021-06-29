process souporcell {
    // cf. https://github.com/wheaton5/souporcell
    tag "${samplename}"
    publishDir "${params.outdir}/souporcell/",
	mode: "${params.souporcell.copy_mode}",
	pattern: "${samplename}",
	overwrite: true
    
    when: 
    params.souporcell.run

    input: 
    tuple val(samplename), path(bam_file), path(bai_file), path(barcodes_tsv_gz)
    val(souporcell_n_clusters)
    file(reference_fasta)
    
    output:
    tuple val(samplename), file("${samplename}"), emit: souporcell_output_dir
    tuple val(samplename), file("${samplename}/clusters.tsv"), file("${samplename}/cluster_genotypes.vcf"), file("${samplename}/ambient_rna.txt"), emit: souporcell_output_files

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
  -o ${samplename} \\
  -k ${souporcell_n_clusters}

# debug only, to remove:
ls -ltra > /lustre/scratch123/pipelines/Pilot_UKB/deconv/dev_souporcell/tmp/${samplename}.list
ls -ltra ${samplename} > /lustre/scratch123/pipelines/Pilot_UKB/deconv/dev_souporcell/tmp/${samplename}.list2
find . > /lustre/scratch123/pipelines/Pilot_UKB/deconv/dev_souporcell/tmp/${samplename}.list3
    """
}

//  -i ${bam_file} \\  /path/to/possorted_genome_bam.bam -b /path/to/barcodes.tsv -f /path/to/reference.fasta -t num_threads_to_use -o output_dir_name -k num_clusters

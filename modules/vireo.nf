process vireo {
    tag "${samplename}"
    publishDir "${params.outdir}/vireo/${samplename}/", mode: "${params.vireo.copy_mode}", overwrite: true
    
    when: 
    params.vireo.run
    
    input:
    tuple val(samplename), path(cell_data), val(n_pooled)
    
    output:
    tuple val(samplename), path("vireo_${samplename}/*"), emit: output_dir
    tuple val(samplename), path("vireo_${samplename}/donor_ids.tsv"), emit: sample_donor_ids 
    path("vireo_${samplename}/${samplename}.sample_summary.txt"), emit: sample_summary_tsv

    script:
    """
umask 2 # make files group_writable

vireo -c $cell_data -N $n_pooled -o vireo_${samplename}

# add samplename to summary.tsv,
# to then have Nextflow concat summary.tsv of all samples into a single file:

cat vireo_${samplename}/summary.tsv | \\
  tail -n +2 | \\
  sed s\"/^/${samplename}\\t/\"g > vireo_${samplename}/${samplename}.sample_summary.txt
    """
}

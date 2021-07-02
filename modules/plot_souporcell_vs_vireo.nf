process plot_souporcell_vs_vireo {
    tag "${samplename}"
    publishDir "${params.outdir}/souporcell_vs_vireo/",
	mode: "${params.plot_souporcell_vs_vireo.copy_mode}",
	pattern: "${samplename}",
	overwrite: true
    
    when: 
    params.plot_souporcell_vs_vireo.run

    input: 
    tuple val(samplename), path(donor_ids_tsv), path(clusters_tsv)
    
    output:
    tuple val(samplename), file("${samplename}_souporcell_vs_vireo.pdf"), emit: plot_pdf

    script:
    """
umask 2 # make files group_writable

plot_souporcell_vs_vireo.R ${samplename} ${donor_ids_tsv} ${clusters_tsv}
    """
}

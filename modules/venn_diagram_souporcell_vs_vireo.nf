process venn_diagram_souporcell_vs_vireo {
    tag "${samplename}"
    publishDir "${params.outdir}/venn_diagram_souporcell_vs_vireo/",
	mode: "${params.venn_diagram_souporcell_vs_vireo.copy_mode}",
	pattern: "${samplename}",
	overwrite: true
    
    when: 
    params.venn_diagram_souporcell_vs_vireo.run

    input: 
    tuple val(samplename), path(donor_ids_tsv), path(clusters_tsv)
    
    output:
    tuple val(samplename), file("venn_diagram.pdf"), emit: venn_diagram_pdf

    script:
    """
umask 2 # make files group_writable

${samplename}
${donor_ids_tsv}
${clusters_tsv}
    """
}

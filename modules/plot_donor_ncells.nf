process plot_donor_ncells {
    tag "${sample_donor_summary_tsv}"
    
    publishDir "${params.outdir}/plots/", mode: "${params.plot_donor_ncells.copy_mode}", overwrite: true
    
    when: 
    params.plot_donor_ncells.run

    input: 
    path(sample_donor_summary_tsv)

    output: 
    path("outputs/*.pdf"), emit: sample_pdf

    script:
    """
python $workflow.projectDir/../bin/plot_donor_ncells.py \\
  --output_dir \$PWD/outputs \\
  --sample_donor_summary_tsv ${sample_donor_summary_tsv} \\
  --plotnine_dpi ${params.plot_donor_ncells.plotnine_dpi}
    """
}

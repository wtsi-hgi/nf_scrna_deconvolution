process split_donor_h5ad {
    tag "${sample}"

    publishDir "${params.outdir}/split_donor_h5ad/${sample}/", mode: "${params.split_h5ad_per_donor.copy_mode}", overwrite: true
    
    when: 
    params.split_h5ad_per_donor.run

    input: 
    tuple val(sample), path(donor_ids_tsv), path(filtered_matrix_h5)

    output: 
    tuple val(sample), path("outputs/vireo_annot.${sample}.h5ad"), emit: sample_vireo_annot_h5ad
    tuple val(sample), path("outputs/*.pdf"), emit: sample_pdf
    tuple val(sample), path("outputs/donor_level_anndata/*.h5ad"), emit: sample_donor_level_anndata 
    
    script:
    """
mkdir -p outputs

python $workflow.projectDir/../bin/split_h5ad_per_donor.py \\
  --vireo_donor_ids_tsv ${donor_ids_tsv} \\
  --filtered_matrix_h5 ${filtered_matrix_h5} \\
  --samplename ${sample} \\
  --output_dir \$PWD/outputs \\
  --print_modules_version ${params.split_h5ad_per_donor.print_modules_version} \\
  --plot_n_cells_per_vireo_donor ${params.split_h5ad_per_donor.plot_n_cells_per_vireo_donor} \\
  --write_donor_level_filtered_cells_h5 ${params.split_h5ad_per_donor.write_donor_level_filtered_cells_h5} \\
  --plotnine_dpi ${params.split_h5ad_per_donor.plotnine_dpi} \\
  --anndata_compression_level ${params.split_h5ad_per_donor.anndata_compression_level}
    """
}

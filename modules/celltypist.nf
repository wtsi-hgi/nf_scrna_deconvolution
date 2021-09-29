process celltypist {
    tag "${sample}"

    publishDir "${params.outdir}/celltypist/${sample}/", mode: "${params.split_h5ad_per_donor.copy_mode}", overwrite: true,
	saveAs: {filename -> filename.replaceFirst("outputs/","") }
    
    when: 
    params.celltypist.run

    input: 
    tuple val(sample), path(donor_ids_tsv), path(filtered_matrix_h5)

    output: 
    tuple val(sample), path("outputs/vireo_annot.${sample}.h5ad"), emit: sample_vireo_annot_h5ad
    tuple val(sample), path("outputs/*.pdf"), emit: sample_pdf
    tuple val(sample), path("outputs/donor_level_anndata/*.h5ad"), emit: sample_donor_level_anndata 
    
    script:
    """
mkdir -p outputs

python $workflow.projectDir/../bin/prep_cellranger_filt_h5_for_celltypist.py \\
  --samplename ${sample} \\
  --filtered_matrix_h5 ${filtered_matrix_h5} \\
  --output_dir \$PWD/outputs

python $workflow.projectDir/../bin/run_celltypist.py \\
  --samplename ${sample} \\
  --filtered_matrix_h5 ${filtered_matrix_h5} \\
  --output_dir \$PWD/outputs
    """
}

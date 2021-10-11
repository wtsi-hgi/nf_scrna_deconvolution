process celltypist {
    tag "${sample}"

    publishDir "${params.outdir}/celltypist/${model}/${sample}/", mode: "${params.celltypist.copy_mode}", overwrite: true,
	saveAs: {filename -> filename.replaceFirst("outputs/","").replaceFirst("figres/","") }
    
    when: 
    params.celltypist.run

    input: 
    tuple val(sample), path(filtered_matrix_h5), val(celltypist_model)
      // sample is an ID for cellranger run
      // filtered_matrix_h5 is cellranger output - filtered_feature_bc_matrix.h5)
      // celltypist_models is elltypist default models to use:
      //     e.g. Immune_All_High.pkl

    output: 
    tuple val(sample), path("outputs/${sample}_celltypist.csv"), emit: sample_celltypist_csv
    tuple val(sample), path("figures/umap_${sample}_celltypist.pdf"), emit: sample_umap_pdf
    
    script:
    model="${celltypist_model}".replaceFirst(".pkl","")
    """
umask 2 # make files group_writable 

mkdir -p outputs

python $workflow.projectDir/../bin/run_celltypist.py \\
  --samplename ${sample} \\
  --filtered_matrix_h5 ${filtered_matrix_h5} \\
  --celltypist_model ${celltypist_model}  \\
  --output_dir \$PWD/outputs
    """
}

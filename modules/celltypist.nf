process celltypist {
    tag "${sample}"

    publishDir "${params.outdir}/celltypist/${model}/${sample}/", mode: "${params.celltypist.copy_mode}", overwrite: true,
	saveAs: {filename -> filename.replaceFirst("outputs/","").replaceFirst("figures/","") }
    
    when: 
    params.celltypist.run

    input: 
    tuple val(sample), val(filtered_matrix_h5), val(celltypist_model)
      // sample is an ID for cellranger run
      // filtered_matrix_h5 is cellranger output - filtered_feature_bc_matrix.h5)
      // either - filtered_feature_bc_matrix.h5 or cellbender_FPR_0pt05_filtered.h5
      // celltypist_models is elltypist default models to use:
      //     e.g. Immune_All_High.pkl

    output: 
      tuple val(sample), path("outputs/${sample}_predicted_labels.csv"), emit: sample_predicted_labels_csv
      tuple val(sample), path("outputs/${sample}_probability_matrix.csv"), emit: sample_probability_matrix_csv
      tuple val(sample), path("outputs/${sample}_decision_matrix.csv"), emit: sample_decision_matrix_csv
      tuple val(sample), path("outputs/${sample}_*.pdf"), emit: sample_plots_pdf
      tuple val(sample), path("outputs/plot_prob/${sample}_*.pdf"), emit: sample_plots_prob_pdf
      
    script:
      model="${celltypist_model}".replaceFirst(".pkl","")

      filtered_matrix_h5_path = file("${filtered_matrix_h5}/../filtered_feature_bc_matrix.h5")
      if (filtered_matrix_h5_path.exists()){
        _=""
        
      }else{
        filtered_matrix_h5_path = file("${filtered_matrix_h5}/../cellbender_FPR_0pt05_filtered.h5")
        
      }


      """
        umask 2 # make files group_writable 

        mkdir -p outputs
        echo ${filtered_matrix_h5}
        python $workflow.projectDir/../bin/run_celltypist.py \\
          --samplename ${sample} \\
          --filtered_matrix_h5 ${filtered_matrix_h5_path} \\
          --celltypist_model ${celltypist_model}  \\
          --output_dir \$PWD/outputs  \\
          --input_h5_genome_version ${params.split_h5ad_per_donor.input_h5_genome_version}
      """
}

params {

    // This pipeline can run with cellSNP inputs provided in either of 3 possible formats.
    // Set cellsnp_input_table_mode to 'from_cellranger_filt_directory' or 'from_h5' or 'from_barcodes':
    // TODO: only 'from_barcodes' is coded and fully functional (Jan 26th 2021) (coded at nextflow_ci/pipelines/prepare_inputs/from_barcodes.nf): 
    // TODO:  'from_cellranger_filt_directory' mode is not ready yet: see current progress at nextflow_ci/pipelines/prepare_inputs/from_cellranger_filt_directory.nf
    // TODO:  'from_h5' mode is not ready yet: see current progress at nextflow_ci/pipelines/prepare_inputs/from_h5.nf 
    


    celltypist { // cf. https://github.com/Teichlab/celltypist 
        run = true // whether to run 'celltypist' task

        // run celltypist on filtered barcodes straight from cellranger outputs:
        //   must have columns 'experiment_id' (ID of cellranger run) and 'data_path_filt_h5d' (absolute path to cellranger filtered filtered_feature_bc_matrix.h5)
        // path_filtered_h5 = '/lustre/scratch123/pipelines/Pilot_UKB/fetch/wbc_mult_donor/results/Submission_Data_Pilot_UKB.file_paths_10x.tsv'
        path_filtered_h5 = '/lustre/scratch123/pipelines/Pilot_UKB/cellbender/franke_data/outputs/qc_cluster_input_files/file_paths_10x-cellbender_params__epochs_250__learnrt_1pt0Eneg7__zdim_100__zlayer_500__lowcount_10-FPR_0pt01.tsv'
        
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true

        // specify models to use,
        //   from default available models from 'models.download_models(force_update = True)'
        //   cf. https://github.com/Teichlab/celltypist 
        //   comma separated list of celltypist default models to use:
        models = ['Immune_All_High.pkl','Immune_All_Low.pkl',
            'Immune_Blood_High.pkl','Immune_Blood_Low.pkl']
    }

    ///////////////////////
    ///////////////////////
    // cellsnp_input_table_mode = "from_barcodes"
    // input_data_table colums: experiment_id   data_path_10x_format
    ///////////////////////
    ///////////////////////

    
    ///////////////////////
    /////////////////
    cellsnp_input_table_mode = "from_cellbender"
    // input_data_table colums: experiment_id   data_path_10x_format
    // hgi note: from nf_cellbender pipeline

    ///////////////////////
    // Cellbender output
    input_data_table = '/lustre/scratch123/pipelines/Pilot_UKB/cellbender/franke_data/outputs/qc_cluster_input_files/file_paths_10x-cellbender_params__epochs_250__learnrt_1pt0Eneg7__zdim_100__zlayer_500__lowcount_10-FPR_0pt05.tsv'
    // input_n_pooled_table colums: experiment_id   n_pooled
    // hgi note: from nf_fetch pipeline
    // input_data_path_filt_h5_table:
    // currently same table as input_data_table: deduces filtered cellbender h5 output file from column data_path_10x_format to create columns: experiment_id  data_path_filt_h5
    // hgi note: from nf_cellbender pipeline
    input_data_path_filt_h5_table = '/lustre/scratch123/pipelines/Pilot_UKB/cellbender/franke_data/outputs/qc_cluster_input_files/file_paths_10x-cellbender_params__epochs_250__learnrt_1pt0Eneg7__zdim_100__zlayer_500__lowcount_10-FPR_0pt05.tsv'
 
    ///////////////////////
    ///////////////////////
        //Pools table should be manually defined or estimated using Vireo
    ///////////////////////
    ///////////////////////
    input_n_pooled_table = '/lustre/scratch123/pipelines/Pilot_UKB/deconv/Franke_with_genotypes/inputs/vcf_names_pooled.tsv'
    // input_bam_table colums: experiment_id  data_path_bam_file
    // hgi note: from nf_fetch pipeline

    ///////////////////////
    ///////////////////////
        //This is the raw output matrix grom fetch pipeline
    ///////////////////////
    ///////////////////////
    input_bam_table = '/lustre/scratch123/pipelines/Pilot_UKB/deconv/Franke_with_genotypes/inputs/franke_data.Pilot_3.raw.file_paths_10x.tsv'

    input_tables_column_delimiter = '\t' // set 'tsv' or 'csv': whether input_data_table (and other input tables) have tab-separted ('tsv') or comma-separated columns ('csv').
    
    run_with_genotype_input=true
	genotype_input {
        subset_genotypes = true
	    // path to donor vcfs:
        full_vcf_file = '/lustre/scratch123/pipelines/Pilot_UKB/deconv/Franke_with_genotypes/inputs/franke_gt.vcf.gz'
        // path_donor_vcfs_table = '/lustre/scratch123/pipelines/nf_ci_deconv_inputs/donors_stephen_watts/donors_input.tsv'
	    // 'path_donor_vcfs_table' must have these 3 columns :
	    //   - 'experiment_id': samplename for each convoluted input (to be deconvoluted into donors by the pipeline)
	    //   - 'donors_vcf': for each 'experiment_id', path to VCF file that has the donors GT data for Vireo deconvolution.
	    //   - 'donors_list': for each 'experiment_id', path to file that has list of donors names (one per line) to deconvolute: used to subset VCFs using bcftools -S argument.
	}

    // if 'from_barcodes', then input_data_table must have 4 columns (+ 1 optional to annotate H5 file):
    //       - 'experiment_id': samplename for each convoluted input (to be deconvoluted into donors by the pipeline)
    //       - 'n_pooled':  number of pooled samples in each experiment to deconvolute into.
    //       - 'data_path_barcodes': path to cellranger barcodes file for each 'experiment_id' (for cellSNP, can be gzipped or not)
    //       - 'data_path_bam_file': path to bam file for each 'experiment_id' (for cellSNP)
    //       - 'data_path_filt_h5': path to scanpy h5 file for each 'experiment_id', to annotate with donor cell assigments and split into donor-level h5 files ('split_h5ad_donor' task)
    // in that mode, if 'data_path_filt_h5' is not there, then you can't run task 'split_h5ad_per_donor', so set it to run=false below.

    // if 'from_h5', then input_data_table must have these 4 columns:
    //  'path_to_h5_table' must have 2 columns : 
    //       - 'experiment_id': samplename for each convoluted input (to be deconvoluted into donors by the pipeline)
    //       - 'n_pooled':  number of pooled samples in each experiment to deconvolute into.
    //       - 'data_path_h5_file': path to scanpy h5 file that hold the cell barcodes (for cellSNP)
    //       - 'data_path_bam_file': path to bam file for each 'experiment_id' (for cellSNP)

    // if 'from_cellranger_filt_directory', then input_data_table must have these 3 columns :
    //       - 'experiment_id': samplename for each convoluted input (to be deconvoluted into donors by the pipeline)
    //       - 'n_pooled':  number of pooled samples in each experiment to deconvolute into.
    //       - 'data_path_10x_filtered_dir': path to filtered_feature_bc_matrix or filtered_gene_bc_matrix directory generated by "cellranger count" on 10X data;
    //                                       Nextflow will find in that directory the required barcodes and bam files for cellSNP/Vireo.


    // Next, set other inputs and parameters specfic to each pipeline task:

    cellsnp {
        run = true // whether to run 'cellsnp' task
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true
        
        vcf_candidate_snps = "/lustre/scratch123/pipelines/nf_ci_deconv_inputs/genome1K.phase3.SNP_AF5e2.chr1toX.hg38.vcf.gz"
        // this list of candidate SNPs for cellSNP comes from link at https://github.com/single-cell-genetics/cellSNP
        // i.e., https://sourceforge.net/projects/cellsnp/files/SNPlist/genome1K.phase3.SNP_AF5e2.chr1toX.hg38.vcf.gz/download

        // cellSNP CLI parameters:
        min_maf = "0.1" // cellSNP --minMAF
        min_count = "60" // cellSNP --minCOUNT
        p = "20" // cellSNP -p
    }
    
    vireo {
        // choose either run=true or run_with_genotype_input=true (to run Vireo without or with genotype input VCF). 
        run = true // whether to run 'vireo' task
        
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true

        // with_genotype_input = true // set to true or false. If true, will need the following two inputs:
    }

    plot_donor_ncells {
        run = true // whether to run 'plot_donor_ncells' task (multi-pages pdf for all samples Vireo deconvolutions)
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true
        plotnine_dpi = "100" 
    }
    
    split_h5ad_per_donor {
        run = true // whether to run 'split_h5ad_donor' task 
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true

        // next, optional arguments for python script split_h5ad_per_donor.py (cf. bin directory)
        input_h5_genome_version = "GRCh38"
        print_modules_version = "True"
        plot_n_cells_per_vireo_donor = "True"
        write_donor_level_filtered_cells_h5 = "True"
        plotnine_dpi = "100" 
        anndata_compression_level = "6" // with gzip: compression_opts sets the compression level and may be an integer from 0 to 9, default is 4.

        // temporary fix:
        // specify manually absolute /lustre path to nextflow results directory
        // this will be used for generating absolute paths to h5ad deconvoluted objects,as listed in output tsv tables..
        // must append / with \\ as this string will be used by sed replacement.
        absolute_results_path = "\\/lustre\\/scratch123\\/hgi\\/projects\\/ukbb_scrna\\/pipelines\\/Pilot_UKB\\/deconv\\/Franke_with_genotypes\\/results"
        // absolute_results_path = "/lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/Pilot_UKB/deconv/Franke_with_genotypes/results"
    }
    
    subset_genotype {
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true
    }
    souporcell {
        run = false // whether to run 'souporcell' task

        // run souporcell on raw or filtered barcodes:
        use_raw_barcodes = false

        // provides RAW cellranger barcodes as input to souporcell:
        //  must have columns experiment_id and data_path_barcodes
        path_raw_barcodes_table = '/lustre/scratch123/pipelines/Pilot_UKB/fetch/Franke_with_genotypes/results/raw.Submission_Data_Pilot_UKB.file_paths_10x.tsv'

        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
        // Make sure copy_mode is either "copy" or "move" when remove_workdir = true

        // to get this ref file, cf. script inputs/get_souporcell_ref.sh
        reference_fasta = '/lustre/scratch123/pipelines/pipeline_inputs/deconv/refdata-cellranger-GRCh38-3.0.0/fasta/genome.fa'
        // path is secure lustre path from openstack instance, not Sanger farm path
        //   reference_fasta = '/lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/pipeline_inputs/deconv/refdata-cellranger-GRCh38-3.0.0'
    }
    
    plot_souporcell_vs_vireo {
        // if both souporcell and vireo are set to run,
        // then a Venn diagram can be made to compare cell assignements (to deconvoluted donor/cluster, doublet or unassigned)
        run = false // whether to run 'venn_diagram_souporcell_vs_vireo' task
        remove_workdir = false // // whether to remove all work dirs of this task when workflow{} is finished. 
        copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy".
    }

    // other input parameters common to all input modes:

    // The following is used if any module above has replace_in_path = true.
    // use if runnning in Sanger FCE/Openstack (not necessary for Sanger LSF farm) :
    replace_in_path = true // if true, will replace the /lustre path to data_path_10x_format for FCE mapping of /lustre:
    replace_in_path_from = '/lustre/scratch123/hgi/mdt1/projects/ukbb_scrna' // part of path in real /lustre
    replace_in_path_to = '/lustre/scratch123' // to replace for Openstack mapping of /lustre path


    // TODO: the following two options are not fully coded yet, so setting them to true won't do anything (as of Jan 26th 2021).
    // the following are for one-off tasks run after workflow completion to clean-up work directories:
    on_complete_remove_workdirs = false // will remove work dirs (effectively un-caching) of selected tasks even if completed successfully. Make sure that copy_mode is also set to copy or move.
    on_complete_remove_workdir_failed_tasks = false // will remove work dirs of failed tasks (.exitcode file not 0)

}

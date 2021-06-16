nextflow.enable.dsl=2

include { from_barcodes } from './prepare_inputs/from_barcodes.nf'
include { from_cellranger_filt_directory } from './prepare_inputs/from_cellranger_filt_directory.nf'
include { from_h5 } from './prepare_inputs/from_h5.nf'

workflow prepare_inputs {
    take: channel_input_data_table
    main:

    log.info "running workflow prepare_inputs() ..."
    log.info "input parameter 'cellsnp_input_table_mode' set to: ${params.cellsnp_input_table_mode}"

    if (params.input_tables_column_delimiter == ',' | params.input_tables_column_delimiter == '\t') {
	log.info "input table ${params.input_data_table} will read as a ${params.input_tables_column_delimiter}-delimited table."
    }
    else {
	log.info "ERROR: input parameter 'params.input_tables_column_delimiter' should be set to either ',' or '\\t' (for comma or tab separated columns)."
	exit 1
    }

    if (params.cellsnp.run & file(params.cellsnp.vcf_candidate_snps).isEmpty()) {
	log.info "ERROR: input parameter 'params.vcf_candidate_snps' should be a valid path to a non-empty file that lists common SNPs for CellSNP."
	log.info "current 'params.vcf_candidate_snps': ${params.cellsnp.vcf_candidate_snps}"
	exit 1
    }
    
    if (params.cellsnp_input_table_mode == 'from_barcodes') {

	log.info "input mode: from_barcodes"
	from_barcodes(channel_input_data_table)
	
	ch_experiment_bam_bai_barcodes = from_barcodes.out.ch_experiment_bam_bai_barcodes
	ch_experiment_npooled = from_barcodes.out.ch_experiment_npooled
	ch_experiment_filth5 = from_barcodes.out.ch_experiment_filth5
	ch_experiment_donorsvcf_donorslist = from_barcodes.out.ch_experiment_donorsvcf_donorslist

    } else if(params.cellsnp_input_table_mode == 'from_h5') {

	log.info "input mode: from_h5"
	from_h5(channel_input_data_table)
	
	ch_experiment_bam_bai_barcodes = from_h5.out.ch_experiment_bam_bai_barcodes
	ch_experiment_npooled = from_h5.out.ch_experiment_npooled
	ch_experiment_filth5 = from_h5.out.ch_experiment_filth5
	ch_experiment_donorsvcf_donorslist = from_h5.out.ch_experiment_donorsvcf_donorslist

    } else if(params.cellsnp_input_table_mode == 'from_cellranger_filt_directory') {
	
	log.info "input mode: from_cellranger_filt_directory"
	from_cellranger_filt_directory(channel_input_data_table)

	ch_experiment_bam_bai_barcodes = from_cellranger_filt_directory.out.ch_experiment_bam_bai_barcodes
	ch_experiment_npooled = from_cellranger_filt_directory.out.ch_experiment_npooled
	ch_experiment_filth5 = from_cellranger_filt_directory.out.ch_experiment_filth5
	ch_experiment_donorsvcf_donorslist = from_cellranger_filt_directory.out.ch_experiment_donorsvcf_donorslist
	
    } else {
	log.info "Error: input parameter 'cellsnp_input_table_mode' should be set to either 'from_barcodes' or 'from_h5' or 'from_cellranger_filt_directory'"
	exit 1
    }
    
    emit:
    ch_experiment_bam_bai_barcodes
    ch_experiment_npooled
    ch_experiment_filth5
    ch_experiment_donorsvcf_donorslist
}

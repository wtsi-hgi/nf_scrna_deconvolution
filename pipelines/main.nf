nextflow.enable.dsl=2

// All inputs are read from Nextflow config file "inputs.nf",
//  which is located in upstream Gitlab "nextflow_ci" repo (at same branch name).
// Meaning that if you wish to run pipeline with different parameters,
// you have to edit+commit+push that "inputs.nf" file, then rerun the pipeline.

// module to prepare input channels depending on which params.cellsnp_input_table_mode was set:
include { prepare_inputs } from './prepare_inputs.nf'  

// main deconvolution pipeline once inputs channels are prepared:
include { main_deconvolution } from './main_deconvolution.nf'  

// celltypist module, independent from deconvolution tasks
include { celltypist } from '../modules/celltypist.nf'

workflow {

    log.info "inputs parameters are: $params"

    // prepare input channels, depending on which input mode was chosen:
    //if (! file(params.input_data_table).isEmpty()) {

    if (params.cellsnp.run | params.vireo.run |  params.souporcell.run) {
	prepare_inputs(Channel.fromPath(params.input_data_table, followLinks: true, checkIfExists: true))
	
	// run main deconvolution pipeline on prepared input channels:
	main_deconvolution(prepare_inputs.out.ch_experiment_bam_bai_barcodes,
			   prepare_inputs.out.ch_experiment_npooled,
			   prepare_inputs.out.ch_experiment_filth5,
			   prepare_inputs.out.ch_experiment_donorsvcf_donorslist)
    }
    
    //} else {
//	log.info "ERROR: params.input_data_table should be valid path to a (non-empty) input table file."
//	log.info "Please fix input param 'input_data_table' (currently set to $params.input_data_table)"
//	exit 1
  //  }
    

    if (params.celltypist.run) {
	// read filtered barcodes straight from cellranger outputs

		log.info "params.celltypist.path_filtered_h5: ${params.celltypist.path_filtered_h5}"

		channel.fromPath(params.celltypist.path_filtered_h5)
				.splitCsv(header: true, sep: params.input_tables_column_delimiter)
			.map{row->tuple(row.experiment_id, row.data_path_filt_h5.replaceFirst(/${params.replace_in_path_from}/, params.replace_in_path_to))}
			.set{ch_experiment_filth5}

		// to finish implementing
		channel.fromList(params.celltypist.models)
			.set{ch_celltypist_models}

		// ch_experiment_filth5.combine(ch_celltypist_models).view()
		celltypist(ch_experiment_filth5.combine(ch_celltypist_models))
    }
    
}

workflow.onError {
    log.info "Pipeline execution stopped with the following message: ${workflow.errorMessage}" }

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Command line: $workflow.commandLine"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    
    if (params.on_complete_remove_workdirs) {
	log.info "You have selected \"on_complete_remove_workdirs = true\"; will therefore attempt to remove work dirs of selected tasks (even if completed successfully.)"
	if (! file("${params.outdir}/work_dirs_to_remove.csv").isEmpty()) {
	    log.info "file ${params.outdir}/work_dirs_to_remove.csv exists and not empty ..."
	    file("${params.outdir}/work_dirs_to_remove.csv")
		.eachLine {  work_dir ->
		if (file(work_dir).isDirectory()) {
		    log.info "removing in work dir $work_dir ..."
		    file(work_dir).deleteDir()   
		} } } }
    
    if (params.on_complete_remove_workdir_failed_tasks) {
	log.info "You have selected \"on_complete_remove_workdir_failed_tasks = true\"; will therefore remove work dirs of all tasks that failed (.exitcode file not 0)."
	// work dir and other paths are hardcoded here ... :
	def proc = "bash ${projectDir}/../bin/del_work_dirs_failed.sh ${workDir}".execute()
	def b = new StringBuffer()
	proc.consumeProcessErrorStream(b)
	log.info proc.text
	log.info b.toString() }
}

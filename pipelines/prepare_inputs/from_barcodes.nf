nextflow.enable.dsl=2

workflow from_barcodes {
    take: channel_input_data_table
    main:
    log.info "running workflow from_barcodes() ..."
    
    channel_input_data_table
        .splitCsv(header: true, sep: params.input_tables_column_delimiter)
	.map{row->tuple(row.experiment_id, row.n_pooled)}
	.set{ch_experiment_npooled}
    
    channel_input_data_table
        .splitCsv(header: true, sep: params.input_tables_column_delimiter)
	.map{row->tuple(row.experiment_id, row.data_path_bam_file ,row.data_path_barcodes)}
	.set{pre_ch_experiment_bam_barcodes}


    if (params.split_h5ad_per_donor.run) {
	log.info "params.split_h5ad_per_donor.run=true: create pre_ch_experiment_filth5 from params.input_tables_column_delimiter"
    channel_input_data_table
        .splitCsv(header: true, sep: params.input_tables_column_delimiter)
	.map{row->tuple(row.experiment_id, row.data_path_filt_h5)}
	.set{pre_ch_experiment_filth5} // this channel is used for task 'split_donor_h5ad'
    } else {
	// create dummy channel
	log.info "using dummy channel for pre_ch_experiment_filth5, because unused."
	pre_ch_experiment_filth5 = Channel.from("foo").map { foo -> tuple("foo1","foo2") }
    }
    

    if (params.vireo.run_with_genotype_input) {
	log.info "You have selected params.vireo.run_with_genotype_input=true -> will run Vireo with genotype input. Input VCF and list of donors per experiment_id gathered from params.vireo.genotype_input.path_donor_vcfs_table)"
	if (! file(params.vireo.genotype_input.path_donor_vcfs_table).isEmpty()) {
	    
	    log.info("Channel.fromPath(params.vireo.genotype_input.path_donor_vcfs_table)")
	    Channel.fromPath(params.vireo.genotype_input.path_donor_vcfs_table)
		.splitCsv(header: true, sep: params.input_tables_column_delimiter)
		.map{row->tuple(row.experiment_id, row.donors_vcf, row.donors_list)}
		.set{pre_ch_experiment_donorsvcf_donorslist}
	    
	} else {
	    log.info "ERROR: params.vireo.genotype_input.path_donor_vcfs_table should be valid path to a (non-empty) input table file."
	    log.info "Please fix input table (currently set to ${params.vireo.genotype_input.path_donor_vcfs_table})"
	    exit 1
	}
    } else {
	// create dummy channel
	log.info "using dummy channel for pre_ch_experiment_donorsvcf_donorslist, because unused."
	pre_ch_experiment_donorsvcf_donorslist = Channel.from("foo").map { foo -> tuple("foo1","foo2","foo3") }
    }
    

    // if params.replace_in_path set to true:
    // used if path to input files are mounted differently on the file-system
    // (e.g. if /lustre is mounted in Openstack on a different absolute path in nextflow  worker nodes)
    if (params.replace_in_path) {
	log.info "replace in path."

	pre_ch_experiment_filth5
	    .map{experiment, path -> tuple(experiment, path.replaceFirst(/${params.replace_in_path_from}/,
									 params.replace_in_path_to))}
	    .set{ch_experiment_filth5}

	pre_ch_experiment_bam_barcodes
	    .map{experiment, pathbam, pathbarcodes -> tuple(experiment, 
							    pathbam.replaceFirst(/${params.replace_in_path_from}/,
										 params.replace_in_path_to),
							    pathbam.replaceFirst(/${params.replace_in_path_from}/,
										 params.replace_in_path_to).replaceFirst(/$/, ".bai"),
							    pathbarcodes.replaceFirst(/${params.replace_in_path_from}/,
										      params.replace_in_path_to))}
	    .set{ch_experiment_bam_bai_barcodes}
	
	pre_ch_experiment_donorsvcf_donorslist
	    .map{experiment, donorsvcf, donorslist -> tuple(experiment, 
							    donorsvcf.replaceFirst(/${params.replace_in_path_from}/,
										 params.replace_in_path_to),
							    donorslist.replaceFirst(/${params.replace_in_path_from}/,
										      params.replace_in_path_to))}
	    .set{ch_experiment_donorsvcf_donorslist}
	
    } else {
	log.info "no replace in path."

	pre_ch_experiment_filth5
	    .set{ch_experiment_filth5}
	    
	pre_ch_experiment_bam_barcodes
	    .map { a,b,c -> tuple(a, file(b), file("${b}.bai"), file(c))}
	    .set {ch_experiment_bam_bai_barcodes}

	pre_ch_experiment_donorsvcf_donorslist
	    .set{ch_experiment_donorsvcf_donorslist}
    }


    emit:
    ch_experiment_bam_bai_barcodes
    ch_experiment_npooled
    ch_experiment_filth5
    ch_experiment_donorsvcf_donorslist
}

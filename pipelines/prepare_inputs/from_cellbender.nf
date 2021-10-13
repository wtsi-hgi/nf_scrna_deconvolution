nextflow.enable.dsl=2

workflow from_cellbender {
    take:
		channel_input_data_table
		

    main:
		log.info "running workflow from_cellbenders() ..."

		channel_input_n_pooled_table = Channel.fromPath(params.input_n_pooled_table, followLinks: true, checkIfExists: true)
		channel_input_bam_table = Channel.fromPath(params.input_bam_table, followLinks: true, checkIfExists: true)
		channel_input_data_path_filt_h5_table = Channel.fromPath(params.input_data_path_filt_h5_table, followLinks: true, checkIfExists: true)

		channel_input_n_pooled_table
			.splitCsv(header: true, sep: params.input_tables_column_delimiter)
			.map{row->tuple(row.experiment_id, row.n_pooled)}
			.set{ch_experiment_npooled}
		
		channel_input_data_table
			.splitCsv(header: true, sep: params.input_tables_column_delimiter)
			.map{row->tuple(row.experiment_id, row.data_path_10x_format)}
			.map{a,b->tuple(a, "${b}/barcodes.tsv.gz")}
			.set{pre_ch_experiment_barcodes}

		channel_input_bam_table
			.splitCsv(header: true, sep: params.input_tables_column_delimiter)
		.map{row->tuple(row.experiment_id, row.data_path_bam_file)}
		.set{ch_experiment_bam}

		ch_experiment_bam
		.join(pre_ch_experiment_barcodes, by: 0)
		.set{pre_ch_experiment_bam_barcodes}

		
		if (params.split_h5ad_per_donor.run) {
			log.info "params.split_h5ad_per_donor.run=true: create pre_ch_experiment_filth5 from channel_input_data_path_filt_h5_table and delim params.input_tables_column_delimiter"
			
			//channel_input_data_path_filt_h5_table
			//   .splitCsv(header: true, sep: params.input_tables_column_delimiter)
			//	.map{row->tuple(row.experiment_id, row.data_path_filt_h5)}
			
			channel_input_data_table
				.splitCsv(header: true, sep: params.input_tables_column_delimiter)
				.map{row->tuple(row.experiment_id, row.data_path_10x_format)}
				.map{experiment, path -> tuple(experiment, path.replaceFirst(/_10x_mtx/,".h5"))}
				.map{experiment, path -> tuple(experiment, path.replaceFirst(/cellbender-FPR/,"cellbender_FPR"))}
				.map{experiment, path -> tuple(experiment, path.replaceFirst(/-filtered.h5/,"_filtered.h5"))}
				.set{pre_ch_experiment_filth5} // this channel is used for task 'split_donor_h5ad'

		} else {
			// create dummy channel
			log.info "using dummy channel for pre_ch_experiment_filth5, because unused."
			pre_ch_experiment_filth5 = Channel.from("foo").map { foo -> tuple("foo1","foo2") }
		}


		if (params.run_with_genotype_input) {
			log.info "You have selected params.vireo.run_with_genotype_input=true -> will run Vireo with genotype input. Input VCF and list of donors per experiment_id gathered from params.input_n_pooled_table)"
				// here should check if the CSV is provided as per specs
				// the data has to have a format -> row.experiment_id, row.donors_vcf, row.donors_list

				if (params.genotype_input.subset_genotypes){
					log.info("----Using an input table: "+params.input_n_pooled_table+"----")
					// in this case we have to be avare that the last col is a IDs but not number of donors pooled as per bellow
					
					Channel.fromPath(params.input_n_pooled_table)
					.splitCsv(header: true, sep: params.input_tables_column_delimiter)
					.map{row->tuple(row.experiment_id, params.genotype_input.full_vcf_file, row.donor_vcf_ids)}
					.set{pre_ch_experiment_donorsvcf_donorslist}

				}else{
					log.info('----We are using full VCF for each donor without subsetting----')
					// in this case we have to be avare that the last number is a number of donors pooled instead of IDs as per above
					channel_input_n_pooled_table
						.splitCsv(header: true, sep: params.input_tables_column_delimiter)
						.map{row->tuple(row.experiment_id, params.genotype_input.full_vcf_file, row.n_pooled)}
						.set{pre_ch_experiment_donorsvcf_donorslist}
				}

		} else {
			// create dummy channel since we are not using VCFs, hence no genotype input
			log.info "using dummy channel for pre_ch_experiment_donorsvcf_donorslist, because unused with inputs: experiment_id,donors_vcf,donors_list"
			pre_ch_experiment_donorsvcf_donorslist = Channel.from("foo").map { foo -> tuple("foo1","foo2","foo3") }
		}
		

		// if params.replace_in_path set to true:
		// used if path to input files are mounted differently on the file-system
		// (e.g. if /lustre is mounted in Openstack on a different absolute path in nextflow  worker nodes)
		if (params.replace_in_path) {
			log.info "---replace in path.---"
			// this is necessary to map the lustre paths to FCE

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
			log.info "---no replace in path.----"

			pre_ch_experiment_filth5
				.set{ch_experiment_filth5}
				
			pre_ch_experiment_bam_barcodes
				.map { a,b,c -> tuple(a, file(b), file("${b}.bai"), file(c))}
				.set {ch_experiment_bam_bai_barcodes}

			pre_ch_experiment_donorsvcf_donorslist
				.set{ch_experiment_donorsvcf_donorslist}
		}


    // // must emit these output channels:
    emit:
		ch_experiment_bam_bai_barcodes
		ch_experiment_npooled
		ch_experiment_filth5
		ch_experiment_donorsvcf_donorslist
}

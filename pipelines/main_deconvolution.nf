nextflow.enable.dsl=2

// main deconvolution modules, common to all input modes:
include { cellsnp } from '../modules/cellsnp.nf'
include { split_donor_h5ad } from '../modules/split_donor_h5ad.nf'
include { plot_donor_ncells } from '../modules/plot_donor_ncells.nf'
include { vireo } from '../modules/vireo.nf'
include { souporcell } from '../modules/souporcell.nf'
include {guzip_vcf} from '../modules/guzip_vcf.nf'
// modules to run Vireo with genotype input:
include { subset_genotype } from '../modules/subset_genotype.nf'
include { vireo_with_genotype } from '../modules/vireo_with_genotype.nf'
// if souporcell and vireo were both run, compare cell assigments with venn diagram
include { plot_souporcell_vs_vireo } from '../modules/plot_souporcell_vs_vireo.nf'


workflow  main_deconvolution {

    take:
		ch_experiment_bam_bai_barcodes
		ch_experiment_npooled
		ch_experiment_filth5
		ch_experiment_donorsvcf_donorslist

    main:
		log.info "#### running workflow main_deconvolution() ..."

	if (params.run_with_genotype_input) {
		if (params.genotype_input.subset_genotypes){
			log.info "---We are subsetting genotypes----"
			
			subset_genotype(ch_experiment_donorsvcf_donorslist.map { experiment, donorsvcf, donorslist -> tuple(experiment, 
							file(params.cellsnp.vcf_candidate_snps),
							file(donorsvcf),
							donorslist)})
		}

	}
	


	if (params.souporcell.run){
		// This runs the Souporcell Preprocessing
		if (params.souporcell.use_raw_barcodes) {
			// read raw cellranger barcodes per pool for souporcell
			channel.fromPath(params.souporcell.path_raw_barcodes_table)
					.splitCsv(header: true, sep: params.input_tables_column_delimiter)
				.map{row->tuple(row.experiment_id, row.data_path_barcodes.replaceFirst(/${params.replace_in_path_from}/, params.replace_in_path_to))}
				.set{ch_experiment_rawbarcodes}
			ch_experiment_bam_bai_barcodes
				.map {a,b,c,d -> tuple(a,b,c)}
				.combine(ch_experiment_rawbarcodes, by: 0)
				.combine(ch_experiment_npooled, by: 0)
				.set {ch_experiment_bam_bai_barcodes_npooled}
		} else if (! params.souporcell.use_raw_barcodes) {
			ch_experiment_bam_bai_barcodes
				.combine(ch_experiment_npooled, by: 0)
				.set{ch_experiment_bam_bai_barcodes_npooled}
		}

		// This runs the Souporcell
		if (params.run_with_genotype_input) {

			if (params.genotype_input.subset_genotypes){
				log.info "---We are using subset genotypes running Suporcell----"
				// here combine the ch_experiment_bam_bai_barcodes_npooled with the output of subset
				guzip_vcf(subset_genotype.out.samplename_subsetvcf)
				// ch_experiment_bam_bai_barcodes_npooled.combine(subset_genotype.out.samplename_subsetvcf, by: 0).set{full_vcf}
				ch_experiment_bam_bai_barcodes_npooled.combine(guzip_vcf.out.souporcell_vcf, by: 0).set{full_vcf}
				

			}else{
				log.info "---We are using a full genotype input for Suporcell----"
				// this however currently doesnt work and the individuals have to be provided.

				// here just add the full vcf path to each of the ch_experiment_bam_bai_barcodes_npooled
				guzip_vcf(tuple('full_vcf', file(params.genotype_input.full_vcf_file)))
				guzip_vcf.out.souporcell_vcf.map { sample, vcf -> vcf }.set{vcf_file}
				// we would now flatten this and take the the file of the tuple to be used next. 
				ch_experiment_bam_bai_barcodes_npooled.map { 
					samplename, bam_file, bai_file, barcodes_tsv_gz, souporcell_n_clusters -> 
					tuple(samplename, bam_file, bai_file, barcodes_tsv_gz, souporcell_n_clusters)
					}.set{full_vcf}
				full_vcf.combine(vcf_file).set{full_vcf}
				
			}
		}
		else{
			log.info "-----running Suporcell without genotype input----"
			// here make add an empty entry [] to the ch_experiment_bam_bai_barcodes_npooled
			ch_experiment_bam_bai_barcodes_npooled.map { 
				samplename, bam_file, bai_file, barcodes_tsv_gz, souporcell_n_clusters -> 
				tuple(samplename, bam_file, bai_file, barcodes_tsv_gz, souporcell_n_clusters,[])
				}.set{full_vcf}

		}
		// full_vcf.view()
		// Now that channel is created run suporcell
		souporcell(full_vcf,
			Channel.fromPath(params.souporcell.reference_fasta).collect())
		
	}


	

    // cellsnp() outputs -> vireo():
	if (params.vireo.run){

		//cellsnp() from pipeline provided inputs:
		cellsnp(ch_experiment_bam_bai_barcodes,
			Channel.fromPath(params.cellsnp.vcf_candidate_snps).collect())
			

		// Vireo:
		if (params.run_with_genotype_input) {
			log.info "---running Vireo with genotype input----"
			// for each experiment_id to deconvolute, subset donors vcf to its donors and subset genomic regions. 
			if (params.genotype_input.subset_genotypes){
				log.info "---We are using subset genotypes running Vireo----"
			
				vireo_with_genotype(cellsnp.out.cellsnp_output_dir
					.combine(subset_genotype.out.samplename_subsetvcf, by: 0))
			}else{
				log.info "---We are using a full genotype input for Vireo----"

				// cellsnp.out.cellsnp_output_dir.combine(cellsnp.out.cellsnp_output_dir, by:0).view()
				cellsnp.out.cellsnp_output_dir.map { experiment, cellsnpvcf -> tuple(experiment,cellsnpvcf,file(params.genotype_input.full_vcf_file))}.set {full_vcf}
				vireo_with_genotype(full_vcf)
				
			}

			vireo_out_sample_summary_tsv = vireo_with_genotype.out.sample_summary_tsv
			vireo_out_sample__exp_summary_tsv = vireo_with_genotype.out.sample__exp_summary_tsv
			vireo_out_sample_donor_ids = vireo_with_genotype.out.sample_donor_ids
		}
		// Vireo without genotype input:
		else {
			log.info "-----running Vireo without genotype input----"
			vireo(cellsnp.out.cellsnp_output_dir.combine(ch_experiment_npooled, by: 0))
			vireo_out_sample_summary_tsv = vireo.out.sample_summary_tsv
			vireo_out_sample__exp_summary_tsv = vireo.out.sample__exp_summary_tsv
			vireo_out_sample_donor_ids = vireo.out.sample_donor_ids
		}
	}

	
	if (params.vireo.run){
		// Currently splitting of donors happens using Vireo, but an option should be added to make it utilis Suporcel if selected.
		// vireo() outputs -> split_donor_h5ad():
		split_donor_h5ad(vireo_out_sample_donor_ids.combine(ch_experiment_filth5, by: 0))
		
		// collect file paths to h5ad files in tsv tables:
		split_donor_h5ad.out.donors_h5ad_tsv
		.collectFile(name: "donors_h5ad.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\tdonor\th5ad_filepath\n",
				storeDir:params.outdir)
		
		// paste experiment_id and donor ID columns with __ separator
		split_donor_h5ad.out.exp__donors_h5ad_tsv
		.collectFile(name: "exp__donors_h5ad.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\th5ad_filepath\n",
				storeDir:params.outdir)
		
		split_donor_h5ad.out.donors_h5ad_assigned_tsv
		.collectFile(name: "donors_h5ad_assigned.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\tdonor\th5ad_filepath\n",
				storeDir:params.outdir)
		
		// paste experiment_id and donor ID columns with __ separator
		split_donor_h5ad.out.exp__donors_h5ad_assigned_tsv
		.collectFile(name: "exp__donors_h5ad_assigned.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\th5ad_filepath\n",
				storeDir:params.outdir)

		split_donor_h5ad.out.h5ad_tsv
		.collectFile(name: "cellranger_as_h5ad.tsv", 
				newLine: true, sort: true, // only one line in each file to collate, without ending new line character, so add it here.
				seed: "experiment_id\th5ad_filepath", // don't need \n here since newLine: true 
				storeDir:params.outdir)
		
		// all vireo() outputs collected -> plot_donor_ncells(): 
		vireo_out_sample_summary_tsv
		.collectFile(name: "vireo_donor_n_cells.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\tdonor\tn_cells\n",
				storeDir:params.outdir)
		.set{ch_vireo_donor_n_cells_tsv} // donor column: donor0, .., donorx, doublet, unassigned
		
		// paste experiment_id and donor ID columns with __ separator
		vireo_out_sample__exp_summary_tsv
		.collectFile(name: "vireo_exp__donor_n_cells.tsv", 
				newLine: false, sort: true,
				seed: "experiment_id\tn_cells\n",
				storeDir:params.outdir)

		plot_donor_ncells(ch_vireo_donor_n_cells_tsv)
	}

    
    if (params.souporcell.run && params.vireo.run) {
		log.info "both souporcell and vireo were run."
		log.info "making plot to compare souporcell vs vireo cell deconvolution assignments."
		plot_souporcell_vs_vireo(
			vireo_out_sample_donor_ids // tuple val(samplename), file("${samplename}/donor_ids.tsv")
			// combine with tuple val(samplename), file("${samplename}/clusters.tsv"):
			.combine(souporcell.out.souporcell_output_files.map {a,b,c,d -> tuple(a,b)},
				by: 0))
    } 
    
    // emit:
    // 	vireo_out_sample_summary_tsv
}

nextflow.enable.dsl=2

// main deconvolution modules, common to all input modes:
include { cellsnp } from '../modules/cellsnp.nf'
include { split_donor_h5ad } from '../modules/split_donor_h5ad.nf'
include { plot_donor_ncells } from '../modules/plot_donor_ncells.nf'
include { vireo } from '../modules/vireo.nf'
include { souporcell } from '../modules/souporcell.nf'
// modules to run Vireo with genotype input:
include { subset_genotype } from '../modules/subset_genotype.nf'
include { vireo_with_genotype } from '../modules/vireo_with_genotype.nf'


workflow  main_deconvolution {

    take:
    ch_experiment_bam_bai_barcodes
    ch_experiment_npooled
    ch_experiment_filth5
    ch_experiment_donorsvcf_donorslist

    main:
    log.info "running workflow main_deconvolution() ..."

    souporcell(ch_experiment_bam_bai_barcodes, // tuple val(samplename), path(bam_file), path(bai_file), path(barcodes_tsv_gz)
	       Channel.from(params.souporcell.n_clusters), // val(souporcell_n_clusters)
	       Channel.fromPath(params.souporcell.reference_fasta).collect()) // file(reference_fastq)

    // cellsnp() from pipeline provided inputs:
    cellsnp(ch_experiment_bam_bai_barcodes,
	    Channel.fromPath(params.cellsnp.vcf_candidate_snps).collect())

    // cellsnp() outputs -> vireo():

    // Vireo with genotype input:
    if (params.vireo.run_with_genotype_input) {
        log.info "running Vireo with genotype input"
	// for each experiment_id to deconvolute, subset donors vcf to its donors and subset genomic regions. 
	subset_genotype(
	ch_experiment_donorsvcf_donorslist
	    .map { experiment, donorsvcf, donorslist -> tuple(experiment, 
							      file(params.cellsnp.vcf_candidate_snps),
							      file(donorsvcf),
							      file(donorslist))})

	vireo_with_genotype(cellsnp.out.cellsnp_output_dir
			    .combine(subset_genotype.out.samplename_subsetvcf, by: 0))

	vireo_out_sample_summary_tsv = vireo_with_genotype.out.sample_summary_tsv
	vireo_out_sample__exp_summary_tsv = vireo_with_genotype.out.sample__exp_summary_tsv
	vireo_out_sample_donor_ids = vireo_with_genotype.out.sample_donor_ids
    }

    // Vireo without genotype input:
    else {
        log.info "running Vireo without genotype input"
	vireo(cellsnp.out.cellsnp_output_dir.combine(ch_experiment_npooled, by: 0))

	vireo_out_sample_summary_tsv = vireo.out.sample_summary_tsv
	vireo_out_sample__exp_summary_tsv = vireo.out.sample__exp_summary_tsv
	vireo_out_sample_donor_ids = vireo.out.sample_donor_ids
    }

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


    //emit:
    //vireo.out.sample_summary_tsv
}

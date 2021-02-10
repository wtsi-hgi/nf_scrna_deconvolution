nextflow.enable.dsl=2

workflow from_cellranger_filt_directory {
    take: channel_input_data_table
    main:
    log.info "running workflow from_cellranger_filt_directorys() ..."
    log.info "workflow from_cellranger_filt_directory() is not ready yet."

    // must emit these output channels:
    emit:
    ch_experiment_bam_bai_barcodes
    ch_experiment_npooled
    ch_experiment_filth5
    ch_experiment_donorsvcf_donorslist
}

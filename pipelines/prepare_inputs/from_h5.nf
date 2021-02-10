nextflow.enable.dsl=2

workflow from_h5 {
    take: channel_input_data_table
    main:
    log.info "running workflow from_h5() ..."
    log.info "workflow from_h5() is not ready yet."

    // must emit these output channels:
    emit:
    ch_experiment_bam_bai_barcodes
    ch_experiment_npooled
    ch_experiment_filth5
    ch_experiment_donorsvcf_donorslist
}

#!/usr/bin/env bash

# cf. https://github.com/wheaton5/souporcell
wget http://cf.10xgenomics.com/supp/cell-exp/refdata-cellranger-GRCh38-3.0.0.tar.gz
tar -xzvf refdata-cellranger-GRCh38-3.0.0.tar.gz

# this will create folder refdata-cellranger-GRCh38-3.0.0 in current dir
# Sanger HGI scRNA: run at /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/pipeline_inputs/deconv/nf_scrna_deconvolution/inputs

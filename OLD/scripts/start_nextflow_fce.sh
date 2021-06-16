#!/usr/bin/env bash

# activate Nextflow conda env
conda init bash
eval "$(conda shell.bash hook)"
conda activate base # must be name of conda env that has Nextflow installed

# run nextflow main.nf with inputs and fce config:
export NXF_OPTS="-Xms5G -Xmx5G"
nextflow run ./nf_scrna_deconvolution/pipelines/main.nf \
      -c ./nf_scrna_deconvolution/nextflow.config -c inputs.nf -profile fce \
      --nf_ci_loc $PWD -resume

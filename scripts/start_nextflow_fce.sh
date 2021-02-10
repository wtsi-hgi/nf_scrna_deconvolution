#!/usr/bin/env bash

# activate Nextflow conda env
conda init bash
eval "$(conda shell.bash hook)"
conda activate base # must be name of conda env that has Nextflow installed

# run nextflow main.nf with inputs and fce config:
export NXF_OPTS="-Xms5G -Xmx5G"
nextflow run ./nextflow_ci/pipelines/main.nf \
      -c ./nextflow_ci/nextflow.config -c inputs.nf -profile fce \
      --nf_ci_loc $PWD -resume

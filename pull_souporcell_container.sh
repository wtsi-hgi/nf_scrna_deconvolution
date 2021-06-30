#!/usr/bin/env bash

# for internal Sanger use:
#  this repo is cloned at /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/nf_scrna_deconvolution
#  so that is script pulls image at
#  /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/singularity_images/

tag=latest

registry_path=shub://wheaton5/souporcell:${tag}
image=shub_wheaton5_souporcell_${tag}.img

mkdir -p cache_dir
export SINGULARITY_CACHEDIR=$PWD/cache_dir

mkdir -p tmp_dir
export TMPDIR=$PWD/tmp_dir

echo image $image
singularity pull --name $image $registry_path
cd .. && ln -s ./nf_scrna_deconvolution/$image .

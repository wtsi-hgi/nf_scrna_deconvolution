#!/usr/bin/env bash
set -x

git submodule sync
git submodule update --init --recursive --remote
git add nf_scrna_deconvolution
git commit -m "submodule commit update"
git push

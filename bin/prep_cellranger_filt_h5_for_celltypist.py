#!/usr/bin/env python3
__author__ = 'Guillaume Noell'
__date__ = '2021-09-29'
__version__ = '0.0.1'
# for help, run: python3 prep_h5_for_celltypist.py --help
# command with example inputs arguments: python3 prep_h5_for_celltypist.py.py --samplename ukbb_scrna9479582 --vireo_donor_ids_tsv --filtered_h5ad /lustre/.../filtered_feature_bc_matrix.h5

# import python libraries:
import logging
import click
import sys 
import argparse
import os
import csv
import random
import numpy as np
import pandas as pd
import scanpy as sc

# CLI arguments:
@click.command()

# required arguments:
@click.option('--vireo_donor_ids_tsv', required=True, type=click.Path(exists=True),
              help='path to donor_ids.tsv file, which is an output file of Vireo')

@click.option('--samplename', required=True, type=str,
              help='sample name of cellranger experiment deconvoluted by Vireo')

# arguments that are optional because they have default value:
@click.option('-o','--output_dir', default='./vireo_deconv_out', show_default=True, type=str,
              help='output directory for script output plots and files')


def prep_h5_for_celltypist(vireo_donor_ids_tsv, filtered_matrix_h5, samplename,
                         output_dir, print_modules_version, plot_n_cells_per_vireo_donor,
                         input_h5_genome_version,
                         write_donor_level_filtered_cells_h5, plotnine_dpi,
                         anndata_compression_level):
    """process cellranger output filtered h5 so that it can be fed to Celltypist"""
    logging.info('running prep_h5_for_celltypist() function..')

    # Set seed for reproducibility
    seed_value = 0
    # 0. Set `PYTHONHASHSEED` environment variable at a fixed value
    # os.environ['PYTHONHASHSEED']=str(seed_value)
    # 1. Set `python` built-in pseudo-random generator at a fixed value
    random.seed(seed_value)
    # 2. Set `numpy` pseudo-random generator at a fixed value
    np.random.seed(seed_value)
    sns.set(style='whitegrid')

if __name__ == '__main__':
    # set logging level and handler:
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        handlers=[logging.StreamHandler()]) # logging.FileHandler("debug.log"),
    prep_h5_for_celltypist()


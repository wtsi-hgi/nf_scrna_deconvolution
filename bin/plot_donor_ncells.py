#!/usr/bin/env python3
__author__ = 'Guillaume Noell'
__date__ = '2021-01-15'
__version__ = '0.0.1'
# for help, run: python3 plot_donor_ncells.py --help

# import python libraries:
# on farm5, these libraries are installed in a conda environment: conda activate nextflow
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
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import seaborn as sns
import plotnine as plt9
from plotnine.ggplot import save_as_pdf_pages

# CLI arguments:
@click.command()

# required arguments:
# arguments that are optional because they have default value:
@click.option('-o','--output_dir', default='./outputs/', show_default=True, type=str,
              help='output directory for script output plots and files')

@click.option('--sample_donor_summary_tsv', required=True, type=click.Path(exists=True),
              help='path to multi-samples donor_ids.tsv file, which is a concatenation of multiple donor_ids.tsv with an additional column for sample (10x experiment ID)')

@click.option('-d','--plotnine_dpi', default=100,
              type=click.IntRange(1, 1000, clamp=True), show_default=True,
              help='DPI pdf plots resolution for plotnine plots. Integer in range 1 to 1000')


def plot_donor_ncells(output_dir, sample_donor_summary_tsv, plotnine_dpi):
    """plot_donor_ncells main script"""
    logging.info('running plot_donor_ncells() function..')

    # Set seed for reproducibility
    seed_value = 0
    # 0. Set `PYTHONHASHSEED` environment variable at a fixed value
    # os.environ['PYTHONHASHSEED']=str(seed_value)
    # 1. Set `python` built-in pseudo-random generator at a fixed value
    random.seed(seed_value)
    # 2. Set `numpy` pseudo-random generator at a fixed value
    np.random.seed(seed_value)
    sns.set(style='whitegrid')
    # Set the default dpi
    plt9.options.dpi = plotnine_dpi

    if not os.path.exists(output_dir):
        print('creating directory ' + output_dir)
        os.makedirs(output_dir)
    
    df = pd.read_csv(sample_donor_summary_tsv, sep='\t', index_col=False)

    plots = []

    n_samples = df['experiment_id'].nunique()
    samples_unique = df['experiment_id'].unique()
    for samples in np.array_split(samples_unique, int(n_samples/8)):
        print('samples:')
        print(samples)
        y = df[df['experiment_id'].isin(samples)]
        gplt = plt9.ggplot(y, plt9.aes(
            x='donor',
            y='n_cells',
            fill='donor'
        )) + plt9.facet_wrap('experiment_id', scales = 'free', ncol = 3)
        gplt = gplt + plt9.theme_bw() + plt9.theme(figure_size=(25, 30), 
                                                   legend_position='none', 
                                                   axis_text_x=plt9.element_text(colour="black", angle=45),
                                                   axis_text_y=plt9.element_text(colour="black"))
        gplt = gplt + plt9.geom_bar(stat='identity', position='dodge')
        gplt = gplt + plt9.geom_text(plt9.aes(label='n_cells'))
        gplt = gplt + plt9.labels.ggtitle('CellSNP/Vireo deconvolution\nnumber of cells per deconvoluted donor')
        gplt = gplt + plt9.labels.xlab('deconvoluted donor')
        gplt = gplt + plt9.labels.ylab('Number of cells assigned by Vireo')
        plots.append(gplt)
        
    save_as_pdf_pages(plots, filename=output_dir + '/vireo_plots.pdf')


if __name__ == '__main__':
    # set logging level and handler:
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        handlers=[logging.StreamHandler()]) # logging.FileHandler("debug.log"),
    plot_donor_ncells()

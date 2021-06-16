#!/usr/bin/env python3
__author__ = 'Guillaume Noell'
__date__ = '2021-01-15'
__version__ = '0.0.1'
# for help, run: python3 split_h5ad_per_donor.py --help
# command with example inputs arguments: python3 split_h5ad_per_donor.py --samplename ukbb_scrna9479582 --vireo_donor_ids_tsv /lustre/scratch123/hgi/projects/ukbb_scrna/pipelines/nf_ci_scrna_deconv/results/vireo/vireo_ukbb_scrna9479582/donor_ids.tsv --filtered_matrix_h5 /lustre/scratch123/hgi/mdt1/projects/ukbb_scrna/pipelines/fetch_Submission_Data_Pilot_UKB/nextflow_ci/pipelines/../../results/iget_study_cellranger/5933/ukbb_scrna9479582/cellranger_ukbb_scrna9479582/filtered_feature_bc_matrix.h5

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
@click.option('--vireo_donor_ids_tsv', required=True, type=click.Path(exists=True),
              help='path to donor_ids.tsv file, which is an output file of Vireo')

@click.option('--filtered_matrix_h5', required=True, type=click.Path(exists=True),
              help='path to filtered cells h5 data file created by cellranger count, which was deconvoluted by Vireo')

@click.option('--samplename', required=True, type=str,
              help='sample name of cellranger experiment deconvoluted by Vireo')

# arguments that are optional because they have default value:
@click.option('-o','--output_dir', default='./vireo_deconv_out', show_default=True, type=str,
              help='output directory for script output plots and files')

@click.option('-m','--print_modules_version', default=False, show_default=True, type=bool,
              help='True or False: whetherer to print version of all python module to file.')

@click.option('-p','--plot_n_cells_per_vireo_donor', default=True, show_default=True,  type=bool,
              help='True or False: whetherer to plot number of cells per deconvoluted donor to pdf in --output_dir')

@click.option('-w','--write_donor_level_filtered_cells_h5', default=True, show_default=True, type=bool,
              help='True or False: whetherer to write donor level scanpy hdf5 objects to dir --output_dir')

@click.option('-c','--anndata_compression_level', default=6,
              type=click.IntRange(1, 9, clamp=True), show_default=True,
              help='Gzip compression level for scanpy write of AnnData hdf5 objects. Integer in range 1 to 9')

@click.option('-d','--plotnine_dpi', default=100,
              type=click.IntRange(1, 1000, clamp=True), show_default=True,
              help='DPI pdf plots resolution for plotnine plots. Integer in range 1 to 1000')


def split_h5ad_per_donor(vireo_donor_ids_tsv, filtered_matrix_h5, samplename,
                         output_dir, print_modules_version, plot_n_cells_per_vireo_donor,
                         write_donor_level_filtered_cells_h5, plotnine_dpi,
                         anndata_compression_level):
    """split_h5ad_donor main script"""
    logging.info('running split_h5ad_per_donor() function..')

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

    # print modules version to output file.
    if print_modules_version:
        with open(output_dir + '/module_versions.txt', 'w') as f:
            for name, module in sorted(sys.modules.items()): 
                if hasattr(module, '__version__'): 
                    f.write(str(name) + '=' + str(module.__version__) + '\n') 


    # read-in cellranger 10x data produced by 'cellranger count':
    adata = sc.read_10x_h5(filtered_matrix_h5)
    adata.var['gene_symbols'] = adata.var.index
    adata.var.index = adata.var['gene_ids'].values
    del adata.var['gene_ids']

    # also read-in the cell deconvolution annotation produced by Vireo:
    vireo_anno_deconv_cells = pd.read_csv(vireo_donor_ids_tsv, sep='\t',
                                          index_col='cell')

    # calculate number of cells per deconvoluted donor:
    cells_per_donor_count = vireo_anno_deconv_cells[['donor_id']].value_counts().to_frame('n_cells')
    cells_per_donor_count.reset_index(level=cells_per_donor_count.index.names, inplace=True)

    # check that `adata` and `vireo_anno_deconv_cells` indexes DO match, as expected:
    for cell_in_vireo_index in vireo_anno_deconv_cells.index:
        if cell_in_vireo_index not in adata.obs_names:
            print('error: cell index ' + cell_in_vireo_index + ' is in vireo_anno_deconv_cells but not in adata')

    # add Vireo annotation to adata
    adata.obs['convoluted_samplename'] = samplename
    for new_cell_annotation in ['donor_id','prob_max','prob_doublet','n_vars','best_singlet','best_doublet']:
        if new_cell_annotation in vireo_anno_deconv_cells.columns:
            print('adding vireo annotation ' + new_cell_annotation + ' to AnnData object.')
            adata.obs[new_cell_annotation] = vireo_anno_deconv_cells[new_cell_annotation]
        else:
            print('warning: column ' + new_cell_annotation + ' is not in input Vireo annotation tsv.')        

    # plot n cells per deconvoluted Vireo donor:
    if plot_n_cells_per_vireo_donor:
        gplt = plt9.ggplot(cells_per_donor_count, plt9.aes(
            x='donor_id',
            y='n_cells',
            fill='donor_id'
        ))
        gplt = gplt + plt9.theme_bw() + plt9.theme(legend_position='none', 
                                                   axis_text_x=plt9.element_text(colour="black", angle=45),
                                                   axis_text_y=plt9.element_text(colour="black"))
        gplt = gplt + plt9.geom_bar(stat='identity', position='dodge')
        gplt = gplt + plt9.geom_text(plt9.aes(label='n_cells'))
        gplt = gplt + plt9.labels.ggtitle('CellSNP/Vireo deconvolution\nnumber of cells per deconvoluted donor\nsample: ' + samplename)
        gplt = gplt + plt9.labels.xlab('deconvoluted donor')
        gplt = gplt + plt9.labels.ylab('Number of cells assigned by Vireo')
    
        # save plot(s) as pdf:
        plots = [gplt]
        save_as_pdf_pages(plots, filename=output_dir + '/Vireo_plots.pdf')

    # write AnnData with Vireo cell annotation in .obs
    output_file = output_dir + '/vireo_annot.' + samplename
    print('Write h5ad AnnData with Vireo cell annotation in .obs to ' + output_file)
    adata.write('{}.h5ad'.format(output_file), compression='gzip', compression_opts= anndata_compression_level)
    
    if write_donor_level_filtered_cells_h5:
    
        if not os.path.exists(output_dir + '/donor_level_anndata'):
            print('creating directory ' + output_dir + '/donor_level_anndata')
            os.makedirs(output_dir + '/donor_level_anndata')
        
        adata_donors = []
        for donor_id in adata.obs['donor_id'].unique():
            print('filtering cells of AnnData to donor ' + donor_id)
            adata_donor = adata[adata.obs['donor_id'] == donor_id, :]
            adata_donors.append((donor_id, adata_donor))  
            output_file = output_dir + '/donor_level_anndata/' + donor_id + '.' + samplename
            print('Write h5ad donor AnnData to ' + output_file)
            adata_donor.write('{}.h5ad'.format(output_file), compression='gzip', compression_opts= anndata_compression_level)

if __name__ == '__main__':
    # set logging level and handler:
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        handlers=[logging.StreamHandler()]) # logging.FileHandler("debug.log"),
    split_h5ad_per_donor()


process cellsnp {
    tag "${samplename}"
    publishDir "${params.outdir}/cellsnp/", mode: "${params.cellsnp.copy_mode}", pattern: "cellsnp_${samplename}", overwrite: true
    
    when: 
    params.cellsnp.run

    input: 
    tuple val(samplename), path(bam_file), path(bai_file), path(barcodes_tsv_gz)
    file(region_vcf)
    
    output:
    tuple val(samplename), file("cellsnp_${samplename}"), emit: cellsnp_output_dir

    script:
    """
umask 2 # make files group_writable

if [[ ${barcodes_tsv_gz} =~ \\.gz\$ ]]; then
  echo \"${barcodes_tsv_gz} is gzipped\"
  zcat ${barcodes_tsv_gz} > bar_codes.txt
else
  echo \"${barcodes_tsv_gz} is not gzipped\"
  ln -s ${barcodes_tsv_gz} bar_codes.txt
fi

cellsnp-lite -s ${bam_file} \\
  -b bar_codes.txt \\
  -O cellsnp_${samplename} \\
  -R ${region_vcf} \\
  -p ${params.cellsnp.p} \\
  --minMAF ${params.cellsnp.min_maf} \\
  --minCOUNT ${params.cellsnp.min_count} --gzip
    """
}
// https://github.com/single-cell-genetics/cellSNP
// Mode 1: pileup a list of SNPs for single cells in a big BAM/SAM file
// Require: a single BAM/SAM file, e.g., from cellranger, a VCF file for a list of common SNPs.
// This mode is recommended comparing to mode 2, if a list of common SNP is known, e.g., human (see Candidate SNPs)
// As shown in the above command line, we recommend filtering SNPs with <20UMIs or <10% minor alleles for downstream donor deconvolution, by adding --minMAF 0.1 --minCOUNT 20

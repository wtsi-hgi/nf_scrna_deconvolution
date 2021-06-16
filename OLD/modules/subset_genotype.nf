process subset_genotype {
    tag "${samplename}.${sample_subset_file}"
    publishDir "${params.outdir}/subset_genotype/", mode: "${params.subset_genotype.copy_mode}", pattern: "${samplename}.${sample_subset_file}.subset.vcf.gz"
    
    when: 
    params.vireo.run_with_genotype_input

    input:
    tuple val(samplename), path(cellsnp_vcf), path(donor_vcf), path(sample_subset_file)
    
    output:
    tuple val(samplename), path("${samplename}.${sample_subset_file}.subset.vcf.gz"), emit: samplename_subsetvcf

    script:
    """
tabix -p vcf ${donor_vcf} 
# tabix -p vcf ${cellsnp_vcf}
bcftools view ${donor_vcf} -S ${sample_subset_file} -Oz -o ${samplename}.${sample_subset_file}.subset.vcf.gz
rm ${donor_vcf}.tbi
# rm ${cellsnp_vcf}.tbi
    """
}

// bcftools view ${donor_vcf} -R ${cellsnp_vcf} -S ${sample_subset_file} -Oz -o ${samplename}.subset.vcf.gz

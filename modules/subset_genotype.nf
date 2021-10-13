process subset_genotype {
    tag "${samplename}.${sample_subset_file}"
    publishDir "${params.outdir}/subset_genotype/", mode: "${params.subset_genotype.copy_mode}", pattern: "${samplename}.${sample_subset_file}.subset.vcf.gz"
    
    when: 
    params.genotype_input.subset_genotypes

    input:
    tuple val(samplename), path(cellsnp_vcf), path(donor_vcf), val(sample_subset_file)

    output:
    tuple val(samplename), path("${samplename}.subset.vcf.gz"), emit: samplename_subsetvcf

    script:
    """
        echo ${sample_subset_file}
        tabix -p vcf ${donor_vcf} || echo 'not typical VCF'
        # tabix -p vcf ${cellsnp_vcf}
        bcftools view ${donor_vcf} -s ${sample_subset_file} -Oz -o ${samplename}.subset.vcf.gz
        rm ${donor_vcf}.tbi || echo 'not typical VCF'
        # rm ${cellsnp_vcf}.tbi
    """
}

// bcftools view ${donor_vcf} -R ${cellsnp_vcf} -S ${sample_subset_file} -Oz -o ${samplename}.subset.vcf.gz

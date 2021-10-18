process guzip_vcf {
    tag "${samplename}"

    // when: 
    //     params.celltypist.run

    input: 
        tuple val(samplename), path(genotypes)

    output:
        tuple val(samplename), path("${samplename}.vcf"), emit: souporcell_vcf

    script:
    """
      bcftools view ${genotypes} -O v -o ${samplename}.vcf
    """
}
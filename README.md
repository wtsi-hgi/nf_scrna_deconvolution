# nextflow_ci

scRNA deconvolution

### containers

2 containers are used:
- main container, which is default for all steps:  
https://github.com/wtsi-hgi/scrna_deconvolution_container
-  container for souporcell step:
  ```
  singularity pull shub://wheaton5/souporcell
  ```
  cf. [pull_souporcell_container.sh](pull_souporcell_container.sh)  
  from https://github.com/wheaton5/souporcell
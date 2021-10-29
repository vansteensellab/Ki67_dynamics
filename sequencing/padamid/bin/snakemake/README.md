#### pA-DamID snakemake workflow

The snakemake workflow ("damid.snake") contains processing steps; the config file ("config.yaml") contains sample information.

Executed with snakemake 6.1.0. For most steps, the "conda_[...].yaml" files provide snakemake with the required information to automatically download the required software. For custom R scripts, some libraries are required and should be installed manually:  

Not in R:

  * conda install pandoc
	
In R:

  * install.packages("optparse”)
	* install.packages("GGally")
	* install_github("js229/Vennerable") (using devtools)
	* BiocManager::install(c("BSgenome", "GenomicAlignments", "Rsamtools", "Biostrings","SummarizedExperiment", "DelayedArray", "matrixStats", "Biobase", "rtracklayer", "GenomicRanges", "GenomeInfoDb", "IRanges", "S4Vectors", "BiocGenerics”)) (using bioconductor tools)


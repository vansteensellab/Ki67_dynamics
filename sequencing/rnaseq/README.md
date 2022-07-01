#### RNA-seq scripts

All the scripts for RNA-seq data processing and testing for differential gene expression between normal and depleted Ki-67 levels (with DESeq2).

The Snakemake pipeline can be found in "snakemake_workflow", where "ts210515_rnaseq.wf" contains the actual snakemake pipeline and "ts210514_config..." contains the sample information and parameters. Further processing of the data was done with R markdown files:

  * ts210514_rnaseq_processing: further processing of RNA-seq counts with DESeq2 (Fig S7).
#### pA-DamID scripts

All the scripts for pA-DamID data processing and analyses.

The Snakemake pipeline can be found in "bin", where "snakemake/damid.snake" contains the actual snakemake pipeline and "snakemake/config.yaml" contains the sample information and parameters. Further processing of the data was done with R markdown files:

  * ts220503_1_data_gathering: this script loads data in R and saves this as an object for downstream analyses. Also, this script was used to generate (lots) of example data tracks, some of which were included in the manuscript. Finally, the script was used to assess the data distribution and determine (Pearson) correlations between independent replicates (Fig S1, S2, and data tracks in other figures).
  * ts220503_2_ki67_wildtype_cells: this script contains various analyses on wildtype data tracks: data distribution per chromosome (Fig 1), data correlation between cell lines per chromosome (Fig S4), enrichment near centromeres (Fig 1), comparison with histone modifications (Fig 6), and enrichment of rDNA sequences (Fig S4).
  * ts220503_3_hct116_ki67aid_padamid_vs_chipseq: this script contains comparisons between pA-DamID and ChIP-seq profiles of Ki-67 (Fig S3, S6).
  * ts220503_4_ki67_rpe_cell_cycle: this script contains all cell-cycle related analyses (Fig 3, S6): dynamics between chromosomes, and enrichment at centromeres and telomeres.
  * ts220503_5_osmotic_shock: this script contains analyses of the osmotic shock figure (Fig S6).
  * ts220503_6_ki67_actinomycin: all actinomycin D related information (Fig 2). we generated a lot of data and performed many analyses for the actinomycin D experiments, resulting in a long and somewhat messy script. Results include chromosomal dynamics, enrichment at centromeres and telomeres, and comparisons with Lamin B1 interactions and H3K27me3 and H3K9me3 histone modifications (not included in manuscript). 
  * ts220503_7_hct116_ki67_aid.Rmd: this script contains analysis on auxin-mediated Ki67 depleted HCT116 cells (Fig 5, S7), specifically for Lamin B1 interactions and H3K27me3 and H3K9me3 histone modifications. Results include data tracks, chromosome dynamics, and comparisons of initial Ki67 levels with changes in Lamin B1 interactions and histone modifications.
  * ts220503_8_hct116_ki67_aid_replication_timing: this script contains all comparisons of replication timing with Ki67 and Lamin B1 interactions. Results include overlays of Ki67 and Lamin B1 interactions with replication timing (Fig 4) and gene expression (Fig S7), and analyses of the changes in Ki67 interactions (Fig 5). 
  * ts220503_9_ki67_depletion_expression_rpe_sun_2017: simple comparisons of gene expression differences in hTERT-RPE cells (Sun, 2017) and Ki67 interactions in these cells (Fig S7). 
  * ts220520_11_hct116_ki67_aid_hic: this script contains analyses of the Hi-C data and comparisons with the Ki-67 interaction profiles, and uses the R-package GENOVA {van der Weide, 2021} (Fig S8).
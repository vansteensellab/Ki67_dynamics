#### Version 2022-10-20 - initial bioRxiv submission

#### pA-DamID scripts

All the scripts for pA-DamID data processing and analyses.

The Snakemake pipeline can be found in "bin", where "snakemake/damid.snake" contains the actual snakemake pipeline and "snakemake/config.yaml" contains the sample information and parameters. Further processing of the data was done with R markdown files:

  * ts210413_data_gathering: this script loads data in R and saves this as an object for downstream analyses. Also, this script was used to generate (lots) of example data tracks, some of which were included in the manuscript. Finally, the script was used to assess the data distribution and determine (Pearson) correlations between independent replicates (Fig S1, S2, and data tracks in other figures).
  * ts210520_ki67_wildtype_cells: this script contains various analyses on wildtype data tracks: data distribution per chromosome (Fig 1), data correlation between cell lines per chromosome (Fig S3), enrichment near centromeres (Fig 1), comparison with histone modifications (Fig 6), and enrichment of rDNA sequences (Fig S3).
  * ts210519_ki67_rpe_cell_cycle: this script contains all cell-cycle related analyses (Fig 2): dynamics between chromosomes, and enrichment at centromeres and telomeres.
  * ts210618_osmotic_shock: this script contains all osmotic shock analyses (Fig S4): chromosomal dynamics.
  * ts210621_ki67_actinomycin: all actinomycin D related information (Fig 3). we generated a lot of data and performed many analyses for the actinomycin D experiments, resulting in a long and somewhat messy script. Results include chromosomal dynamics, enrichment at centromeres and telomeres, and comparisons with Lamin B1 interactions and H3K27me3 and H3K9me3 histone modifications (not included in manuscript). 
  * ts210623_hct116_ki67_aid.Rmd: this script contains analysis on auxin-mediated Ki67 depleted HCT116 cells (Fig 5), specifically for Lamin B1 interactions and H3K27me3 and H3K9me3 histone modifications. Results include data tracks, chromosome dynamics, and comparisons of initial Ki67 levels with changes in Lamin B1 interactions and histone modifications.
  * ts210803_hct116_ki67_aid_replication_timing: this script contains all comparisons of replication timing with Ki67 and Lamin B1 interactions. Results include overlays of Ki67 and Lamin B§ interactions with replication timing (Fig 4) and gene expression (Fig S5), and analyses of the changes in Ki67 interactions (Fig 5). 
  * ts210726_ki67_depletion_expression_rpe_sun_2017: simple comparisons of gene expression differences in hTERT-RPE cells (Sun, 2017) and Ki67 interactions in these cells (Fig S5). 
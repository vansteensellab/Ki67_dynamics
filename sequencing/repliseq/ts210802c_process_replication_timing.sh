# ts210802
# User: Tom
# 
# Process replication timing
# This is a wrapper script with function calls to process the replication 
# timing data. This is a one-time thing, so I won't bother creating a real
# script for this.

#############################
### 1) Prepare output
cd /home/t.v.schaik/mydata/proj/3D_nucleus/results/ts210607_repliseq_K562_LaminKO_HCT116_Ki67AID
dir_repliseq="ts210802_repliseq"
mkdir $dir_repliseq

# List files
E=$(ls fastq/*_e_*.fastq.gz)
L=$(ls fastq/*_l_*.fastq.gz)

#############################
### 2) FastQC reports
conda activate fastqc
mkdir $dir_repliseq/fastqc
fastqc fastq/* -o $dir_repliseq/fastqc -t 12

# Reports show good reads, but with lots of over-represented sequences. I will
# need some adapter trimming

#############################
### 3) FastP adapter trimming
conda activate fastp
mkdir $dir_repliseq/fastp

# Process them separately
samples=$(ls fastq/*_R1_*.fastq.gz)

for p1 in $samples; do
  base=$(basename ${p1%_R1*})
  # Run FastP
  echo "processing $base"
  fastp \
    -i fastq/${base}_R1_001.fastq.gz \
    -I fastq/${base}_R2_001.fastq.gz \
    -o $dir_repliseq/fastp/${base}_R1.fastq.gz \
    -O $dir_repliseq/fastp/${base}_R2.fastq.gz \
    --html $dir_repliseq/fastp/${base}_fastp.html \
    --json $dir_repliseq/fastp/${base}_fastp.json \
    -w 3 &> $dir_repliseq/fastp/${base}.log &
done

conda activate fastqc
mkdir $dir_repliseq/fastp_fastqc
fastqc $dir_repliseq/fastp/*fastq.gz -o $dir_repliseq/fastp_fastqc -t 12

#############################
### 4) BWA Alignment
conda activate 4DN_mapper
mkdir $dir_repliseq/mapping

genome_index="/home/t.v.schaik/mydata/data/genomes/GRCh38/ENCODE/GRCh38_rDNA"

# Process the samples - all together
for p1 in $samples; do
  base=$(basename ${p1%_R1*})
  # Run FastP
  echo "processing $base"
  ../ts200921_LaminaNucleolus_AdditionalExperiments/bin/mapping/mapping_bwa.sh \
    -r $dir_repliseq/fastp/${base}_R1.fastq.gz \
    -p $dir_repliseq/fastp/${base}_R2.fastq.gz \
    -i $genome_index \
    -o $dir_repliseq/mapping \
    -d -c 3 -f $dir_repliseq/mapping/${base}_bwa.log &
done


#############################
### 5) bamCoverage from deeptools
conda activate deeptools
mkdir $dir_repliseq/deeptools

bam_files=$(ls $dir_repliseq/mapping/ | grep bam | grep -v bai)

multiBamSummary bins \
  -b $dir_repliseq/mapping/*bam \
  -o $dir_repliseq/deeptools/deeptools_bam_coverage.npz \
  --minMappingQuality 10 \
  -p 30 \
  --ignoreDuplicates \
  --centerReads \
  -bs 50000 \
  --smartLabels \
  --outRawCounts $dir_repliseq/deeptools/deeptools_bam_coverage.tab
  

#############################
### 5) MultiQC
conda activate multiqc
multiqc $dir_repliseq -f -o $dir_repliseq

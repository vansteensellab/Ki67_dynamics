# ts220210
# User: Tom
# 
# Process ChIP-seq
# This is a wrapper script with function calls to process the ChIP-seq 
# data. This is a one-time thing, so I won't bother creating a real
# script for this. Also note that this must be executed manually because
# I run some processes in the background (with &).

# Note that I copied this from the replication timing processing. Should be
# very similar.

#############################
### 1) Prepare output
cd /home/t.v.schaik/mydata/proj/3D_nucleus/results/ts210607_repliseq_K562_LaminKO_HCT116_Ki67AID
dir_chipseq="ts220210_chipseq"
mkdir $dir_chipseq

# List files
samples_dir="/shared/gcf/t.v.schaik/6733/fastq_files/"
samples=$(ls $samples_dir/*HCT116*.fastq.gz)

#############################
### 2) FastQC reports
conda activate fastqc
mkdir $dir_chipseq/fastqc
fastqc $samples -o $dir_chipseq/fastqc -t 12

# Reports show good reads, but with lots of over-represented sequences. I will
# need some adapter trimming

#############################
### 3) FastP adapter trimming
conda activate fastp
mkdir $dir_chipseq/fastp

# Process them separately
# Note that this is single-end instead of the paired-end replication timing
for p1 in $samples; do
  base=$(basename ${p1%_R1*})
  # Run FastP
  echo "processing $base"
  fastp \
    -i ${samples_dir}/${base}_R1_001.fastq.gz \
    -o $dir_chipseq/fastp/${base}_R1.fastq.gz \
    --html $dir_chipseq/fastp/${base}_fastp.html \
    --json $dir_chipseq/fastp/${base}_fastp.json \
    -w 3 &> $dir_chipseq/fastp/${base}.log &
done

conda activate fastqc
mkdir $dir_chipseq/fastp_fastqc
fastqc $dir_chipseq/fastp/*fastq.gz -o $dir_chipseq/fastp_fastqc -t 12

#############################
### 4) BWA Alignment
conda activate 4DN_mapper
mkdir $dir_chipseq/mapping

genome_index="/home/t.v.schaik/mydata/data/genomes/GRCh38/ENCODE/GRCh38_rDNA"

# Process the samples - all together - single-end data
for p1 in $samples; do
  base=$(basename ${p1%_R1*})
  # Run FastP
  echo "processing $base"
  ../ts200921_LaminaNucleolus_AdditionalExperiments/bin/mapping/mapping_bwa.sh \
    -r $dir_chipseq/fastp/${base}_R1.fastq.gz \
    -i $genome_index \
    -o $dir_chipseq/mapping \
    -d -c 3 -f $dir_chipseq/mapping/${base}_bwa.log &
done


#############################
### 5) bamCoverage from deeptools
conda activate deeptools
mkdir $dir_chipseq/deeptools

bam_files=$(ls $dir_chipseq/mapping/ | grep bam | grep -v bai)

multiBamSummary bins \
  -b $dir_chipseq/mapping/*bam \
  -o $dir_chipseq/deeptools/deeptools_bam_coverage.npz \
  --minMappingQuality 10 \
  -p 30 \
  --ignoreDuplicates \
  --centerReads \
  -bs 50000 \
  --smartLabels \
  --outRawCounts $dir_chipseq/deeptools/deeptools_bam_coverage.tab
  

#############################
### 6) MultiQC
conda activate multiqc
multiqc $dir_chipseq -f -o $dir_chipseq

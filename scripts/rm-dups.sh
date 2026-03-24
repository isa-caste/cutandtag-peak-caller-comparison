#!/bin/bash
#SBATCH --job-name=rem-dups
#SBATCH --mail-user=isacaste@iu.edu
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH -o rem-dups.out
#SBATCH -e rem-dups.err
#SBATCH -p gpu
#SBATCH --ntasks-per-node=2
#SBATCH --gpus-per-node=1
#SBATCH --mem=16G
#SBATCH --nodes=2
#SBATCH --time=1-23:59:00
#SBATCH -A r00750

# load libraries and conda environment
module load conda
conda activate align-qc-env
module load picard

BAM_DIR=/N/project/Krolab/isabella/data/bam-files
OUT_DIR=/N/project/Krolab/isabella/data/dedup-bam-files

mkdir -p $OUT_DIR

for BAM in $BAM_DIR/*_sorted.bam; do
    SAMPLE=$(basename $BAM _sorted.bam)

    # Step 1: Add read groups
    picard AddOrReplaceReadGroups \
        I=$BAM \
        O=$OUT_DIR/${SAMPLE}_rg.bam \
        RGID=$SAMPLE \
        RGLB=lib1 \
        RGPL=illumina \
        RGPU=unit1 \
        RGSM=$SAMPLE \
        VALIDATION_STRINGENCY=LENIENT

    # Step 2: Mark duplicates
    picard MarkDuplicates \
        I=$OUT_DIR/${SAMPLE}_rg.bam \
        O=$OUT_DIR/${SAMPLE}_dedup.bam \
        M=$OUT_DIR/${SAMPLE}_dedup_metrics.txt \
        REMOVE_DUPLICATES=true \
        VALIDATION_STRINGENCY=LENIENT

    # Step 3: Index
    samtools index $OUT_DIR/${SAMPLE}_dedup.bam

    # Cleanup intermediate file
    rm $OUT_DIR/${SAMPLE}_rg.bam

    echo "Done: $SAMPLE"
done

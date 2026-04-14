#!/bin/bash
#SBATCH --job-name=gopeaks_peak_calling
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=isacaste@iu.edu
#SBATCH --output=gopeaks_%A_%a.out
#SBATCH --error=gopeaks_%A_%a.err
#SBATCH --array=0-37%5
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=4:00:00
#SBATCH -A r00750
#SBATCH -p general

module load conda
source ~/.bashrc
conda activate gopeaks_env

# --- Paths ---
DEDUP_DIR=/N/project/Krolab/isabella/data/dedup-bam-files
OUT_DIR=/N/project/Krolab/isabella/cutandtag-peak-caller-comparison/results/peak-calling/gopeaks
BLACKLIST=/N/project/Krolab/isabella/data/encode-files/hg38/ENCFF000KJP_hg38.bed

mkdir -p "${OUT_DIR}/logs"

# --- Build sample list ---
mapfile -t SAMPLES < <(ls "${DEDUP_DIR}"/*.bam | xargs -n1 basename | sed 's/\.bam$//')

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"
BAM="${DEDUP_DIR}/${SAMPLE}.bam"

echo "============================="
echo "Sample:     ${SAMPLE}"
echo "Input BAM:  ${BAM}"
echo "Array ID:   ${SLURM_ARRAY_TASK_ID}"
echo "Date:       $(date)"
echo "============================="

mkdir -p "${OUT_DIR}/${SAMPLE}"

# --- Detect histone mark from sample name & set parameters ---
# GoPeaks recommends different settings per mark:
#   H3K27ac  (narrow, active enhancers): minwidth 200  — default
#   H3K27me3 (broad, repressive):        minwidth 1000 — broader domains
# EDIT: update patterns below if your sample names use different conventions
if [[ "${SAMPLE}" == *"H3K27me3"* ]] || [[ "${SAMPLE}" == *"me3"* ]]; then
    echo "Detected H3K27me3 — using broad mark settings (minwidth 1000)"
    GOPEAKS_EXTRA="--step 100 --minwidth 1000"
elif [[ "${SAMPLE}" == *"H3K27ac"* ]] || [[ "${SAMPLE}" == *"ac"* ]]; then
    echo "Detected H3K27ac — using narrow mark settings (minwidth 200)"
    GOPEAKS_EXTRA="--step 100 --minwidth 200"
else
    echo "WARNING: Could not detect histone mark from sample name '${SAMPLE}'"
    echo "Using default GoPeaks settings"
    GOPEAKS_EXTRA=""
fi

# --- Ensure BAM is indexed ---
if [ ! -f "${BAM}.bai" ]; then
    echo "Index not found — indexing BAM..."
    samtools index "${BAM}"
fi

# --- GoPeaks peak calling ---
gopeaks \
    --bam "${BAM}" \
    --blacklist "${BLACKLIST}" \
    --prefix "${OUT_DIR}/${SAMPLE}/${SAMPLE}" \
    ${GOPEAKS_EXTRA}

echo "GoPeaks done for ${SAMPLE} — $(date)"

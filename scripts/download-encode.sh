# --- Directories ---
ENCODE_DIR="/N/project/Krolab/isabella/data/encode-files"
LIFTOVER_DIR="${ENCODE_DIR}/hg38"
LOGS_DIR="${ENCODE_DIR}/logs"

mkdir -p "${ENCODE_DIR}" "${LIFTOVER_DIR}" "${LOGS_DIR}"

echo "========================================="
echo "Step 1: Download ENCODE files"
echo "========================================="

cd "${ENCODE_DIR}"

# Blacklist regions (bigBed)
if [ ! -f "ENCFF000KJP.bigBed" ]; then
    echo "Downloading ENCFF000KJP (blacklist)..."
    wget -q --show-progress \
        https://www.encodeproject.org/files/ENCFF000KJP/@@download/ENCFF000KJP.bigBed
else
    echo "ENCFF000KJP.bigBed already exists, skipping."
fi

# H3K27me3 ChIP-seq peaks (bigBed)
if [ ! -f "ENCFF000BXB.bigBed" ]; then
    echo "Downloading ENCFF000BXB (H3K27me3 peaks)..."
    wget -q --show-progress \
        https://www.encodeproject.org/files/ENCFF000BXB/@@download/ENCFF000BXB.bigBed
else
    echo "ENCFF000BXB.bigBed already exists, skipping."
fi

# H3K27ac ChIP-seq peaks (bed.gz)
if [ ! -f "ENCFF044JNJ.bed" ]; then
    echo "Downloading ENCFF044JNJ (H3K27ac peaks)..."
    wget -q --show-progress \
        https://www.encodeproject.org/files/ENCFF044JNJ/@@download/ENCFF044JNJ.bed.gz
    gunzip ENCFF044JNJ.bed.gz
else
    echo "ENCFF044JNJ.bed already exists, skipping."
fi

echo ""
echo "========================================="
echo "Step 2: Convert bigBed → BED"
echo "========================================="

# Load UCSC tools if available as a module (adjust module name for your HPC)
module load ucsc 2>/dev/null || module load kentutils 2>/dev/null || true

# Check bigBedToBed is available
if ! command -v bigBedToBed &> /dev/null; then
    echo "ERROR: bigBedToBed not found. Try: module spider ucsc or module spider kentutils"
    exit 1
fi

echo "Converting ENCFF000KJP.bigBed → ENCFF000KJP.bed..."
bigBedToBed ENCFF000KJP.bigBed ENCFF000KJP.bed

echo "Converting ENCFF000BXB.bigBed → ENCFF000BXB.bed..."
bigBedToBed ENCFF000BXB.bigBed ENCFF000BXB.bed

echo ""
echo "========================================="
echo "Step 3: Download hg19 → hg38 liftOver chain file"
echo "========================================="

CHAIN_FILE="${ENCODE_DIR}/hg19ToHg38.over.chain.gz"

if [ ! -f "${CHAIN_FILE}" ]; then
    echo "Downloading liftOver chain file..."
    wget -q --show-progress \
        https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
else
    echo "Chain file already exists, skipping."
fi

echo ""
echo "========================================="
echo "Step 4: LiftOver all files to hg38"
echo "========================================="

# Check liftOver is available
module load liftover 2>/dev/null || true

if ! command -v liftOver &> /dev/null; then
    echo "ERROR: liftOver not found. Try: module spider liftover or module spider ucsc"
    exit 1
fi

# liftOver blacklist
echo "LiftOver: ENCFF000KJP (blacklist) hg19 → hg38..."
liftOver \
    ENCFF000KJP.bed \
    "${CHAIN_FILE}" \
    "${LIFTOVER_DIR}/ENCFF000KJP_hg38.bed" \
    "${LIFTOVER_DIR}/ENCFF000KJP_unmapped.bed"

# liftOver H3K27me3 peaks
echo "LiftOver: ENCFF000BXB (H3K27me3) hg19 → hg38..."
liftOver \
    ENCFF000BXB.bed \
    "${CHAIN_FILE}" \
    "${LIFTOVER_DIR}/ENCFF000BXB_hg38.bed" \
    "${LIFTOVER_DIR}/ENCFF000BXB_unmapped.bed"

# liftOver H3K27ac peaks
echo "LiftOver: ENCFF044JNJ (H3K27ac) hg19 → hg38..."
liftOver \
    ENCFF044JNJ.bed \
    "${CHAIN_FILE}" \
    "${LIFTOVER_DIR}/ENCFF044JNJ_hg38.bed" \
    "${LIFTOVER_DIR}/ENCFF044JNJ_unmapped.bed"

echo ""
echo "========================================="
echo "Step 5: Summary"
echo "========================================="

for f in "${LIFTOVER_DIR}"/*_hg38.bed; do
    name=$(basename "$f")
    mapped=$(wc -l < "$f")
    unmapped_file="${LIFTOVER_DIR}/$(basename "$f" _hg38.bed)_unmapped.bed"
    unmapped=$(grep -v "^#" "$unmapped_file" | wc -l || echo "0")
    echo "${name}: ${mapped} peaks mapped, ${unmapped} unmapped"
done

echo ""
echo "Done! hg38 files are in: ${LIFTOVER_DIR}"
echo "Use these files for ENCODE comparisons in your pipeline:"
echo "  Blacklist:    ${LIFTOVER_DIR}/ENCFF000KJP_hg38.bed"
echo "  H3K27me3:     ${LIFTOVER_DIR}/ENCFF000BXB_hg38.bed"
echo "  H3K27ac:      ${LIFTOVER_DIR}/ENCFF044JNJ_hg38.bed"

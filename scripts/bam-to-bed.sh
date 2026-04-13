#!/bin/bash

BAM_DIR=/N/project/Krolab/isabella/data/dedup-bam-files
BED_DIR=/N/project/Krolab/isabella/data/bed-files

mkdir -p "$BED_DIR"

echo "=========================================="
echo "Converting BAM to BED (fragments)"
echo "=========================================="
# Count input BAMs
BAM_COUNT=$(ls -1 "$BAM_DIR"/*_dedup.bam 2>/dev/null | wc -l)
echo "Found $BAM_COUNT deduplicated BAM files to process"
echo ""

PROCESSED=0
FAILED=0

for BAM in "$BAM_DIR"/*_dedup.bam; do
    if [[ ! -f "$BAM" ]]; then
        continue
    fi

    SAMPLE=$(basename "$BAM" _dedup.bam)
    BED_FILE="$BED_DIR/${SAMPLE}_fragments.bed"

    echo -n "Processing: $SAMPLE ... "
    
    # Convert BAM to BED (fragment format)
    # Use subshell with || to catch errors without stopping script
    if (bedtools bamtobed -i "$BAM" -bedpe 2>/dev/null | \
        awk 'BEGIN {OFS="\t"} {print $1, $2, $6}' | \
        sort -k1,1 -k2,2n > "$BED_FILE" 2>/dev/null); then
        
        BED_LINES=$(wc -l < "$BED_FILE" 2>/dev/null)
        BED_SIZE=$(du -h "$BED_FILE" 2>/dev/null | awk '{print $1}')
        echo "✓ ($BED_LINES fragments, $BED_SIZE)"
        ((PROCESSED++))
    else
        echo "❌ FAILED"
        ((FAILED++))
        # Remove incomplete file
        rm -f "$BED_FILE"
    fi
done

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Successfully processed: $PROCESSED / $BAM_COUNT"
if [[ $FAILED -gt 0 ]]; then
    echo "Failed: $FAILED"
fi
BED conversion complete!"
echo "Output location: $BED_DIR"

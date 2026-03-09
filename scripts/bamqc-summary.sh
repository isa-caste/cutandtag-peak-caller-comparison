#!/bin/bash
#SBATCH --mail-user=isacaste@iu.edu
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --job-name=align
#SBATCH -o align.out
#SBATCH -e align.err
#SBATCH --nodes=2
#SBATCH --mem=16g
#SBATCH -p gpu
#SBATCH --ntasks-per-node=2
#SBATCH --gpus-per-node=1
#SBATCH --time=1-23:59:00
#SBATCH -A r00750

set -e

QC_OUTDIR="/N/project/Krolab/isabella/data/bam-qc"
SUMMARY_FILE="$QC_OUTDIR/bam_qc_summary.txt"



# Create summary file with header
echo "Sample Name | Total Reads | Mapped Reads | % Mapped | Mean Insert Size | Max Insert Size" > "$SUMMARY_FILE"
echo "=============================================================================" >> "$SUMMARY_FILE"

# Process each flagstat file
for FLAGSTAT in "$QC_OUTDIR"/*_flagstat.txt; do
    if [ -f "$FLAGSTAT" ]; then
        BASENAME=$(basename "$FLAGSTAT" _flagstat.txt)
        
        # Extract stats from flagstat
        TOTAL_READS=$(head -1 "$FLAGSTAT" | awk '{print $1}')
        MAPPED_READS=$(grep "mapped (" "$FLAGSTAT" | head -1 | awk '{print $1}')
        
        if [ "$TOTAL_READS" -gt 0 ]; then
            PERCENT_MAPPED=$(echo "scale=2; ($MAPPED_READS / $TOTAL_READS) * 100" | bc)
        else
            PERCENT_MAPPED="0"
        fi
        
        # Get insert size stats
        INSERT_FILE="$QC_OUTDIR/${BASENAME}_insert_size_dist.txt"
        if [ -f "$INSERT_FILE" ]; then
            # Calculate mean insert size
            MEAN_INSERT=$(awk '{sum += $2 * $1; count += $1} END {if (count > 0) print int(sum/count)}' "$INSERT_FILE")
            MAX_INSERT=$(tail -1 "$INSERT_FILE" | awk '{print $2}')
        else
            MEAN_INSERT="N/A"
            MAX_INSERT="N/A"
        fi
        
        # Print summary line
        printf "%-20s | %12s | %12s | %8s%% | %16s | %15s\n" \
            "$BASENAME" "$TOTAL_READS" "$MAPPED_READS" "$PERCENT_MAPPED" "$MEAN_INSERT bp" "$MAX_INSERT bp" >> "$SUMMARY_FILE"
    fi
done

echo "Summary report saved to: $SUMMARY_FILE"

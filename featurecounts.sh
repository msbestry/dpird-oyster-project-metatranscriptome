#!/bin/bash -l

# User defined SLURM commands. #CPUS per task (no. threads program uses) should be a multiple of 8.
#SBATCH --job-name=run_featureCounts
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --partition=work
#SBATCH --output=run_featureCounts.out
#SBATCH --error=run_featureCounts.err

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0149

# SLURM useful commands: sbatch, squeue, scancel
# Run this script using sbatch [slurm].sh

# featureCounts
# Webpage: https://subread.sourceforge.net/featureCounts.html
# Install with conda/mamba
# Run with 32 threads to increase processing speed

# set variables and paths
ANNOTATION="./PO1827_Pinctada_maxima.annotation.clean.gff"
OUTPUT="./Host"
# create a space-separated list of all BAM files
BAM_FILES=$(ls ./*.bam | tr '\n' ' ')

# make sure output dir exists
mkdir -p "$OUTPUT"

echo ""
echo "Running featureCounts on host transcriptome"
echo ""

# run featureCounts
featureCounts -T 32 -s 2 -p -t exon -g Parent -a "$ANNOTATION" \
	-o "$OUTPUT/Gene_counts.txt" $BAM_FILES

echo ""
echo "Done!"
echo ""

#!/bin/bash -l

# Script for running SLURM jobs using multithreaded programs on Pawsey Setonix (2022)
# Copyright statement: Copyright (c) 2022 Applied Bioinformatics Group, UWA, Perth WA, Australia

# Available partitions:
##      Name    Time limit (h)  Cores/node      No. nodes       MEM/node (Gb)   Mem/core (Gb)
##      work    24              128             316             230             ~2
##      long    96              128             8               230             ~2
##      highmem 24              128             8               980             ~8
##      copy    24              64              8               118             ~2
##      debug   1               128             8               230             ~2

# User defined SLURM commands. #CPUS per task (no. threads program uses) should be a multiple of 8.
#SBATCH --job-name=trinity_quantification
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=128
#SBATCH --partition=work
#SBATCH --output=out
#SBATCH --error=err
#SBATCH --mail-user=mitchell.bestry@uwa.edu.au
#SBATCH --mem=120G

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey1224
#SBATCH --mail-type=ALL
#SBATCH --export=NONE

# 128 threads to boost processing speed

# SLURM useful commands: sbatch, squeue, scancel
# Run this script using sbatch [slurm].sh

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
if [ ! -z $SLURM_ARRAY_TASK_ID ]; then
        echo "SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_ID"
fi
echo "========================================="

# Script to run (srun -m command recommended by Pawsey to pack threads)
time srun -m block:block:block

# load the environment
module load singularity/4.1.0-nohost

# set variables and paths
TRINITY_IMAGE="./trinityrnaseq_latest.sif"
SAMPLES="./trinity_samples.txt"
TRANSCRIPTS="./trinity_meta_final.Trinity.fasta"
OUTPUT_DIR="./Metatranscriptome_Final"
GENE_TRANS_MAP="./trinity_meta_final.Trinity.fasta.gene_trans_map"
QUANT_FILES="./quant_files.txt"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Aligning and estimating abundance via RSEM"
echo ""

# prep the reference and run the alignment/estimation
# singularity run $TRINITY_IMAGE /usr/local/bin/util/align_and_estimate_abundance.pl --transcripts $TRANSCRIPTS --seqType fq --samples_file $SAMPLES --est_method RSEM --output_dir $OUTPUT_DIR \
        --aln_method bowtie2 --SS_lib_type RF --gene_trans_map $GENE_TRANS_MAP --coordsort_bam --prep_reference --thread_count 128 --debug

echo ""
echo "Done!"
echo ""
echo ""
echo "Building transcript matrices ..."
echo ""

# build transcript and gene expression matrices
singularity run $TRINITY_IMAGE /usr/local/bin/util/abundance_estimates_to_matrix.pl --est_method RSEM --gene_trans_map $GENE_TRANS_MAP --out_prefix 
RSEM --quant_files $QUANT_FILES --name_sample_by_basedir

echo ""
echo "Done!"
echo ""

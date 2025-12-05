#!/bin/bash -l

# User defined SLURM commands. #CPUS per task (no. threads program uses) should be a multiple of 8.
#SBATCH --job-name=trinity
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=128
#SBATCH --partition=work
#SBATCH --mem=230G
#SBATCH --output=out
#SBATCH --error=err
#SBATCH --mail-user=mitchell.bestry@uwa.edu.au

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey1224
#SBATCH --mail-type=ALL
#SBATCH --export=NONE

# Assembly of RNAseq data with Trinity version 2.15.2
# Github: https://github.com/trinityrnaseq/trinityrnaseq
# Trinity was run in a docker image that was pulled using singularity: https://hub.docker.com/r/trinityrnaseq/trinityrnaseq/
# Max memory limit of 200GB to ensure the package can be run in the work partition
# Sample type: fq (fastq files)
# 128 CPUs to boost processing speed
# Minimum contig length of 300bp

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

# load environment and set variables
module load singularity/4.1.0-nohost
OUTPUT_DIR=trinity_meta_final
SAMPLES=trinity_samples.txt
TRINITY_IMAGE=trinityrnaseq_latest.sif

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# run trinity
singularity run $TRINITY_IMAGE Trinity --seqType fq --max_memory 200G --samples_file "$SAMPLES" --SS_lib_type RF --CPU 128 --min_contig_length 300 --min_kmer_cov 2 --full_cleanup --output "$OUTPUT_DIR"

# check if Trinity completed successfully
if [ $? -eq 0 ]; then
    echo "Trinity completed successfully."
else
    echo "Trinity encountered an error." >&2
    exit 1
fi

#!/bin/bash -l

# User defined SLURM commands. #CPUS per task (no. threads program uses) should be a multiple of 8.
#SBATCH --job-name=run_hisat2_index
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=230G
#SBATCH --partition=work
#SBATCH --output=run_hisat2_index.out
#SBATCH --error=run_hisat2_index.err
#SBATCH --mail-user=youremail@youremail.com

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0149
#SBATCH --mail-type=ALL
#SBATCH --export=NONE
#
# # SLURM useful commands: sbatch, squeue, scancel
# # Run this script using sbatch [slurm].sh
#
echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
if [ ! -z $SLURM_ARRAY_TASK_ID ]; then
	        echo "SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_ID"
fi
echo "========================================="

# Generate index for host removal (mapping) with Hisat2
# Github: https://github.com/DaehwanKimLab/hisat2
# Install Hisat2 using conda/mamba
# Uses 32 threads to increase processing speed

## set paths to genome and to the output
GENOME=./PO1827_Pinctada_maxima.RepeatMasked.fasta
INDEX=./index

## perform the indexing
hisat2-build -p 32 $GENOME $INDEX/Pmaxima

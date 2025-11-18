#!/bin/bash -l

# Script for running SLURM jobs using multithreaded programs on Pawsey Setonix (2022)
# Copyright statement: Copyright (c) 2022 Applied Bioinformatics Group, UWA, Perth WA, Australia

# Available partitions:
##	Name	Time limit (h)	Cores/node	No. nodes	MEM/node (Gb)	Mem/core (Gb)	
## 	work	24		128		316		230		~2
## 	long	96		128		8		230		~2
##	highmem 24		128		8		980		~8
##	copy	24		64		8		118		~2
##	debug	1		128		8		230		~2

# User defined SLURM commands. #CPUS per task (no. threads program uses) should be a multiple of 8.
#SBATCH --job-name=run_kraken2
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=128
#SBATCH --mem=800G
#SBATCH --partition=highmem
#SBATCH --output=run_kraken2.out
#SBATCH --error=run_kraken2.err

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0149

# SLURM useful commands: sbatch, squeue, scancel
# Run this script using sbatch [slurm].sh

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
if [ ! -z $SLURM_ARRAY_TASK_ID ]; then
	echo "SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_ID"
fi
echo "========================================="

# Script

# load environment and set variables
module load singularity/4.1.0-nohost
OUTPUT_DIR=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/Classification
OUTPUT_DIR2=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/Pathogens
SAMPLES_DIR=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/uBAM/filtering
SCRATCH=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome
KRAKEN2_IMAGE=/software/projects/pawsey0149/tbergmann/singularity/kraken2_latest.sif

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR2"

# normal kraken mode
for SAMPLE in $(ls ${SAMPLES_DIR}/*_unmapped_R1.fixed.fastq.gz | sed 's/_unmapped_R1.fixed.fastq.gz//'); do
	SAMPLE_NAME=$(basename $SAMPLE)
	R1="${SAMPLE}_unmapped_R1.fixed.fastq.gz"
	R2="${SAMPLE}_unmapped_R2.fixed.fastq.gz"

	echo "Processing sample: $SAMPLE_NAME"
	echo "R1: $R1"
	echo "R2: $R2"

	# Check if input files exist
	if [[ ! -f $R1 || ! -f $R2 ]]; then
		echo "Error: Missing files for sample $SAMPLE_NAME"
		continue
	fi
	
	singularity exec -B $SCRATCH:${HOME} -e $KRAKEN2_IMAGE kraken2 \
		--db /scratch/references/kraken2/nt_20230502/ \
		--paired $R1 $R2 \
		--output ${OUTPUT_DIR}/${SAMPLE_NAME}.kraken \
		--report ${OUTPUT_DIR}/${SAMPLE_NAME}_report.txt \
		--threads 128 --gzip-compressed \
		--minimum-hit-groups 3
done

# pathogen mode
for SAMPLE in $(ls ${SAMPLES_DIR}/*_unmapped_R1.fixed.fastq.gz | sed 's/_unmapped_R1.fixed.fastq.gz//'); do
        SAMPLE_NAME=$(basename $SAMPLE)
        R1="${SAMPLE}_unmapped_R1.fixed.fastq.gz"
        R2="${SAMPLE}_unmapped_R2.fixed.fastq.gz"

        echo "Processing sample: $SAMPLE_NAME"
        echo "R1: $R1"
        echo "R2: $R2"

        # Check if input files exist
        if [[ ! -f $R1 || ! -f $R2 ]]; then
                echo "Error: Missing files for sample $SAMPLE_NAME"
                continue
        fi

        singularity exec -B $SCRATCH:${HOME} -e $KRAKEN2_IMAGE kraken2 \
                --db /scratch/references/kraken2/nt_20230502/ \
                --paired $R1 $R2 \
                --output ${OUTPUT_DIR2}/${SAMPLE_NAME}.kraken \
                --report ${OUTPUT_DIR2}/${SAMPLE_NAME}_report.txt \
                --threads 128 --gzip-compressed \
                --minimum-hit-groups 3 \
		--report-minimizer-data
done

# unload modules
module unload singularity/4.1.0-nohost




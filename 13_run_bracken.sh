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
#SBATCH --job-name=run_bracken
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=128
#SBATCH --mem=800G
#SBATCH --partition=highmem
#SBATCH --output=run_bracken.out
#SBATCH --error=run_bracken.err

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

# load environment and set variables
module load singularity/4.1.0-nohost
module load python/3.11.6
module load py-matplotlib/3.8.1
module load py-numpy/1.26.1
module load py-scikit-learn/1.3.2

WORK_DIR=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/Classification
SCRATCH=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome
KRAKEN2_IMAGE=/software/projects/pawsey0149/tbergmann/singularity/kraken2_latest.sif

echo ""
echo "Run metratranscriptome comparison"
echo ""

for SAMPLE in $(ls ${WORK_DIR}/*_report.txt); do
	echo ""	
	echo "Running Bracken on: $(basename $SAMPLE)"
	echo ""	

	bracken -d /scratch/references/kraken2/nt_20230502/ -i $SAMPLE -r 150 \
	-l S -t 10 -o ${SAMPLE}.bracken -w ${SAMPLE}.bracken.report
	
	echo ""
	echo "Running diversity analysis on output"
	echo "Calculating alpha-diversity:"
	echo ""
	
	alpha_diversity.py -f ${SAMPLE}.bracken -a BP	
	alpha_diversity.py -f ${SAMPLE}.bracken -a F
	alpha_diversity.py -f ${SAMPLE}.bracken -a Si
	alpha_diversity.py -f ${SAMPLE}.bracken -a ISi
	alpha_diversity.py -f ${SAMPLE}.bracken -a Sh

	echo ""
	echo "Done!"
	echo ""

done

echo ""
echo "Calculate beta-diversity among all samples:"
echo ""

beta_diversity.py -i ${WORK_DIR}/KW2-1_report.txt.bracken ${WORK_DIR}/KW2-2_report.txt.bracken ${WORK_DIR}/KW2-3_report.txt.bracken \
	${WORK_DIR}/KW2-4_report.txt.bracken ${WORK_DIR}/KW2-5_report.txt.bracken ${WORK_DIR}/KW2-6_report.txt.bracken \
	${WORK_DIR}/KW2-7_report.txt.bracken ${WORK_DIR}/KW2-8_report.txt.bracken ${WORK_DIR}/KW2-9_report.txt.bracken \
	${WORK_DIR}/KW2-11_report.txt.bracken ${WORK_DIR}/KW4-1_report.txt.bracken ${WORK_DIR}/KW4-2_report.txt.bracken \
	${WORK_DIR}/KW4-3_report.txt.bracken ${WORK_DIR}/KW4-4_report.txt.bracken ${WORK_DIR}/KW4-5_report.txt.bracken \
	${WORK_DIR}/KW4-6_report.txt.bracken ${WORK_DIR}/KW4-7_report.txt.bracken ${WORK_DIR}/KW4-8_report.txt.bracken \
	${WORK_DIR}/KW4-9_report.txt.bracken ${WORK_DIR}/KW4-10_report.txt.bracken ${WORK_DIR}/KW5-1_report.txt.bracken \
	${WORK_DIR}/KW5-2_report.txt.bracken ${WORK_DIR}/KW5-3_report.txt.bracken ${WORK_DIR}/KW5-4_report.txt.bracken \
	${WORK_DIR}/KW5-5_report.txt.bracken ${WORK_DIR}/KW5-6_report.txt.bracken ${WORK_DIR}/KW5-7_report.txt.bracken \
	${WORK_DIR}/KW5-8_report.txt.bracken ${WORK_DIR}/KW5-9_report.txt.bracken ${WORK_DIR}/KW5-11_report.txt.bracken \
	--type bracken > ${WORK_DIR}/Metatranscriptome_Beta_Diversity.txt

echo ""
echo "Done!"
echo ""

echo ""
echo "Combine reports"
echo ""

combine_kreports.py -r ${WORK_DIR}/KW2-1_report.txt ${WORK_DIR}/KW2-2_report.txt ${WORK_DIR}/KW2-3_report.txt \
	${WORK_DIR}/KW2-4_report.txt ${WORK_DIR}/KW2-5_report.txt ${WORK_DIR}/KW2-6_report.txt \
	${WORK_DIR}/KW2-7_report.txt ${WORK_DIR}/KW2-8_report.txt ${WORK_DIR}/KW2-9_report.txt \
	${WORK_DIR}/KW2-11_report.txt ${WORK_DIR}/KW4-1_report.txt ${WORK_DIR}/KW4-2_report.txt \
	${WORK_DIR}/KW4-3_report.txt ${WORK_DIR}/KW4-4_report.txt ${WORK_DIR}/KW4-5_report.txt \
	${WORK_DIR}/KW4-6_report.txt ${WORK_DIR}/KW4-7_report.txt ${WORK_DIR}/KW4-8_report.txt \
	${WORK_DIR}/KW4-9_report.txt ${WORK_DIR}/KW4-10_report.txt ${WORK_DIR}/KW5-1_report.txt \
	${WORK_DIR}/KW5-2_report.txt ${WORK_DIR}/KW5-3_report.txt ${WORK_DIR}/KW5-4_report.txt \
	${WORK_DIR}/KW5-5_report.txt ${WORK_DIR}/KW5-6_report.txt ${WORK_DIR}/KW5-7_report.txt \
	${WORK_DIR}/KW5-8_report.txt ${WORK_DIR}/KW5-9_report.txt ${WORK_DIR}/KW5-11_report.txt \
        -o ${WORK_DIR}/Metatranscriptome_Report.txt --display-headers

echo ""
echo "Done!"
echo ""

# unload modules
module load python/3.11.6
module unload singularity/4.1.0-nohost

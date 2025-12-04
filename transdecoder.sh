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
#SBATCH --job-name=transdecoder
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=128
#SBATCH --partition=work
#SBATCH --output=transdecoder.out
#SBATCH --error=transdecoder.err
#SBATCH --mail-user=mitchell.bestry@uwa.edu.au
#SBATCH --mem=200G

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey1224
#SBATCH --mail-type=ALL
#SBATCH --export=NONE

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

# Load environment
module load singularity/4.1.0-nohost
module load diamond/2.0.14--hdcc8f71_0

# Set variables
TRANSDECODER_IMAGE=transdecoder_latest.sif
TRINITY_TRANSCRIPTS=trinity_meta_final.Trinity.fasta
OUTPUT="./TransDecoder"
DIAMOND_NR="/scratch/references/diamond/nr.gz"
PFAM=Pfam-A.hmm

# Create output directory
mkdir -p $OUTPUT

echo "--------------------------------------"
echo "Step 1: Identify Long ORFs"
echo "--------------------------------------"
singularity exec -B $OUTPUT:${HOME} -e $TRANSDECODER_IMAGE TransDecoder.LongOrfs \
    -t $TRINITY_TRANSCRIPTS \
    -O $OUTPUT \
    -m 200 \
    --complete_orfs_only || { echo "Error: TransDecoder.LongOrfs failed"; exit 1; }

echo "ORF identification done!"
echo ""

echo "--------------------------------------"
echo "Step 2: Predict coding sequences (without PFAM/BLAST first)"
echo "--------------------------------------"
singularity exec -B $OUTPUT:${HOME} -e $TRANSDECODER_IMAGE TransDecoder.Predict \
    -t $TRINITY_TRANSCRIPTS \
    --no_refine_starts \
    --single_best_only \
    -O $OUTPUT || { echo "Error: TransDecoder.Predict failed"; exit 1; }

echo "Prediction done!"
echo ""

# Optional: Run PFAM scan if database exists
if [[ -f $PFAM ]]; then
    echo "--------------------------------------"
    echo "Step 3: PFAM scan"
    echo "--------------------------------------"
    singularity exec -B $OUTPUT:${HOME} -e $TRANSDECODER_IMAGE hmmpress $PFAM
    singularity exec -B $OUTPUT:${HOME} -e $TRANSDECODER_IMAGE hmmscan \
        --cpu 128 \
        --domtblout $OUTPUT/pfam.domtblout \
        --tblout $OUTPUT/pfam.tblout \
        $PFAM \
        $OUTPUT/$(basename $TRINITY_TRANSCRIPTS).transdecoder_dir/longest_orfs.pep
    echo "PFAM scan done!"
fi

# Optional: Run DIAMOND blastp if database exists
if [[ -f $DIAMOND_NR.dmnd ]]; then
    echo "--------------------------------------"
    echo "Step 4: DIAMOND blastp against NR"
    echo "--------------------------------------"
    diamond blastp -p 128 \
        -d $DIAMOND_NR \
        -q $OUTPUT/$(basename $TRINITY_TRANSCRIPTS).transdecoder_dir/longest_orfs.pep \
        -o $OUTPUT/blastp.outfmt6 \
        --outfmt 6 --max-hsps 1 --max-target-seqs 1 --evalue 1e-5
    echo "DIAMOND blastp done!"
fi

# Optional: Re-run Predict with PFAM/BLAST if files exist
PFAM_FILE="$OUTPUT/pfam.domtblout"
BLAST_FILE="$OUTPUT/blastp.outfmt6"

if [[ -f $PFAM_FILE || -f $BLAST_FILE ]]; then
    echo "--------------------------------------"
    echo "Step 5: Final Predict with PFAM/BLAST"
    echo "--------------------------------------"
    singularity exec -B $OUTPUT:${HOME} -e $TRANSDECODER_IMAGE TransDecoder.Predict \
        -t $TRINITY_TRANSCRIPTS \
        --no_refine_starts \
        --single_best_only \
        $( [[ -f $PFAM_FILE ]] && echo "--retain_pfam_hits $PFAM_FILE" ) \
        $( [[ -f $BLAST_FILE ]] && echo "--retain_blastp_hits $BLAST_FILE" ) \
        -O $OUTPUT
    echo "Final prediction done!"
fi

echo "--------------------------------------"
echo "All done! Check $OUTPUT for .pep, .cds, and .gff3 files."
echo "--------------------------------------"

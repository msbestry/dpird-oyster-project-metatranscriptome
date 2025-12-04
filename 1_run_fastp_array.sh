#!/bin/bash
#SBATCH --job-name=run_FASTP_Array          # Job name
#SBATCH --array=1-30              # Job array index (0 to number of file pairs minus 1)
#SBATCH --cpus-per-task=8                  # Number of CPU cores per task
#SBATCH --mem=16G                          # Memory per CPU core
#SBATCH --time=24:00:00                    # Time limit (hh:mm:ss)
#SBATCH --output=run_FASTP_Array_%A_%a.out           # Standard output (%A = job ID, %a = array index)
#SBATCH --error=run_FASTP_Array_%A_%a.err            # Standard error
#SBATCH --partition=work
#SBATCH --mail-user=email@email.com

# Generic SLURM commands
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0149

# read the file containing the FASTQ pairs
FASTQ_LIST=./fastq_pairs_L005.txt
QC=/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/

# get the corresponding line for the current job array index
READ1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $FASTQ_LIST | awk '{print $1}')
READ2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $FASTQ_LIST | awk '{print $2}')

# define output file names
OUT1=$(basename "$READ1" .fastq.gz)_clean.fastq.gz
OUT2=$(basename "$READ2" .fastq.gz)_clean.fastq.gz

SAMPLE=${OUT1%%_*}
LANE=$(echo "$OUT1" | cut -d '_' -f4)

# run fastp
fastp -i "$READ1" -I "$READ2" -o "$QC/cleanData/$OUT1" -O "$QC/cleanData/$OUT2" -h "$QC/reports/fastp_${SAMPLE}_${LANE}_${SLURM_ARRAY_TASK_ID}.html" -j "$QC/reports/fastp_${SAMPLE}_${LANE}_${SLURM_ARRAY_TASK_ID}.json" --correction --dedup --dup_calc_accuracy 5 -w 8

echo ""
echo "Processed $SAMPLE on lane $LANE"
echo ""
echo "$READ1 and $READ2"
echo ""
echo "Out1: $OUT1"
echo "Out2: $OUT2"
echo ""



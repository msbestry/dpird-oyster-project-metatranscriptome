#!/bin/bash -l

#SBATCH --job-name=run_BLAST_Array              # Job name
#SBATCH --array=1-60                            # Job array index (0 to number of file pairs minus 1)
#SBATCH --ntasks=1                              # Run one task
#SBATCH --cpus-per-task=16                      # Number of CPU cores per task
#SBATCH --mem=32G                               # Memory per CPU core
#SBATCH --time=06:00:00                         # Time limit (hh:mm:ss)
#SBATCH --output=run_BLAST_Array_%A_%a.out      # Standard output (%A = job ID, %a = array index)
#SBATCH --error=run_BLAST_Array_%A_%a.err       # Standard error
#SBATCH --partition=work

# Generic SLURM commands
# #SBATCH --ntasks=1
# #SBATCH --ntasks-per-node=1
# #SBATCH --clusters=setonix
# #SBATCH --account=pawsey0149

# Remove rRNA sequences
# Blast version 2.14.1 is pre-installed on setonix
# Seqkit can be installed with conda/mamba
# Github: https://github.com/shenwei356/seqkit
# repair.sh is a script that is part of BBmap
# BBmap is available as a module on setonix if repair.sh doesn't work otherwise
# rRNA reference database is available on setonix, but may have been replaced with updated version

# read the file containing the clean FASTQ pairs
CLEAN_FQ=~/Scripts/Oyster_Transcriptome/fastq_pairs_clean.txt

# get the corresponding line for the current job array index
READ1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CLEAN_FQ | awk '{print $1}')
READ2=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CLEAN_FQ | awk '{print $2}')

# define output file names
RESULTS1=$(basename "$READ1" _clean.fastq.gz)_fixed_filtered.fastq.gz
RESULTS2=$(basename "$READ2" _clean.fastq.gz)_fixed_filtered.fastq.gz
FASTA1=$(basename "$READ1" .fastq.gz).fasta
FASTA2=$(basename "$READ2" .fastq.gz).fasta
SAMPLE=${RESULTS1%%_*}
LANE=$(echo "$RESULTS1" | cut -d '_' -f4)

# define workdirectories and output for BLAST
WORKDIR="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/rRNA_BLAST"
OPTIONS="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"

# define the NCBI rRNA databases
rRNA16S="/scratch/references/blastdb_update/blast-2025-11-01/db/16S_ribosomal_RNA"
rRNA18S="/scratch/references/blastdb_update/blast-2025-11-01/db/18S_fungal_sequences"
rRNA28S="/scratch/references/blastdb_update/blast-2025-11-01/db/28S_fungal_sequences"
rRNA_DB=("$rRNA16S" "$rRNA18S" "$rRNA28S")

echo ""
echo "Converting ${SAMPLE}_${LANE} to FASTA"
echo ""

seqkit fq2fa "$READ1" -o "$WORKDIR/$FASTA1" -j 16
seqkit fq2fa "$READ2" -o "$WORKDIR/$FASTA2" -j 16

# Combined BLAST results files
COMBINED_HITS1="$WORKDIR/${SAMPLE}_${LANE}_combined_hits_R1.txt"
COMBINED_HITS2="$WORKDIR/${SAMPLE}_${LANE}_combined_hits_R2.txt"

# Clear combined hits files
> "$COMBINED_HITS1"
> "$COMBINED_HITS2"

# BLAST
for DB in "${rRNA_DB[@]}";do
	# define output files for each database
	OUT1="$WORKDIR/${SAMPLE}_${LANE}_R1_$(basename "$DB").txt"
	OUT2="$WORKDIR/${SAMPLE}_${LANE}_R2_$(basename "$DB").txt"
	
	echo "BLASTing $FASTA1 against $DB"
	echo ""
	
	blastn -query "$WORKDIR/$FASTA1" -db "$DB" -out "$OUT1" \
        	-evalue 1e-10 -perc_identity 90 -qcov_hsp_perc 80 \
        	-outfmt "$OPTIONS" -max_target_seqs 1 -max_hsps 1 -num_threads 16   

        echo "BLASTing $FASTA2 against $DB"
        echo ""

        blastn -query "$WORKDIR/$FASTA2" -db "$DB" -out "$OUT2" \
        	-evalue 1e-10 -perc_identity 90 -qcov_hsp_perc 80 \
        	-outfmt "$OPTIONS" -max_target_seqs 1 -max_hsps 1 -num_threads 16

	# Extract hits and append to combined hits files
	awk '{print $1}' "$OUT1" | cut -d ' ' -f1 >> "$COMBINED_HITS1"
	awk '{print $1}' "$OUT2" | cut -d ' ' -f1 >> "$COMBINED_HITS2"
done

# Remove temporary FASTA files after BLASTing
rm "$WORKDIR/$FASTA1" "$WORKDIR/$FASTA2"

echo ""
echo "Filtering the FASTQ"
echo ""

# Filter based on the combined headers in the respective files
seqkit grep -v -f "$COMBINED_HITS1" "$READ1" -o "$WORKDIR/${SAMPLE}_${LANE}_R1_filtered.fastq.gz" -j 16
seqkit grep -v -f "$COMBINED_HITS2" "$READ2" -o "$WORKDIR/${SAMPLE}_${LANE}_R2_filtered.fastq.gz" -j 16

# repair the paired FAST files (write that command in one line otherwise the crap won't work!)
repair.sh in="$WORKDIR/${SAMPLE}_${LANE}_R1_filtered.fastq.gz" in2="$WORKDIR/${SAMPLE}_${LANE}_R2_filtered.fastq.gz" out="$WORKDIR/$RESULTS1" out2="$WORKDIR/$RESULTS2" outs="$WORKDIR/${SAMPLE}_${LANE}_singletons.fastq.gz"

# remove the unrepaired fastqs
rm "$WORKDIR/${SAMPLE}_${LANE}_R1_filtered.fastq.gz" "$WORKDIR/${SAMPLE}_${LANE}_R2_filtered.fastq.gz" "$WORKDIR/${SAMPLE}_${LANE}_singletons.fastq.gz"

echo ""
echo "Done!"
echo ""

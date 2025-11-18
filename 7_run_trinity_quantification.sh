#!/bin/bash -l

#SBATCH --job-name=run_trinity_quantification                # Job name
#SBATCH --cpus-per-task=128                                  # Number of CPU cores per task
#SBATCH --mem=120G                                           # Memory per node
#SBATCH --time=24:00:00                                      # Time limit (hh:mm:ss)
#SBATCH --output=run_trinity_quantification.out              # Standard output (%A = job ID, %a = array index)
#SBATCH --error=run_trinity_quantification.err               # Standard error
#SBATCH --partition=work

# Generic SLURM commands
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0149

# #---

# load the environment
module load singularity/4.1.0-nohost
 
# set variables and paths
TRINITY_IMAGE="/software/projects/pawsey0149/tbergmann/singularity/trinityrnaseq.v2.15.2.simg"
SAMPLES="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/trinity_samples.txt"
TRANSCRIPTS="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/trinity_meta_final.Trinity.fasta"
OUTPUT_DIR="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/Quantification/Metatranscriptome_Final"
GENE_TRANS_MAP="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/trinity_meta_final.Trinity.fasta.gene_trans_map"
SCRATCH="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/"
QUANT_FILES="/scratch/pawsey0149/tbergmann/Oyster_Transcriptome/quant_files.txt"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Aligning and estimating abundance via RSEM"
echo ""

# prep the reference and run the alignment/estimation
singularity exec -B $SCRATCH:${HOME} -e $TRINITY_IMAGE /usr/local/bin/util/align_and_estimate_abundance.pl --transcripts $TRANSCRIPTS --seqType fq --samples_file $SAMPLES --est_method RSEM --output_dir $OUTPUT_DIR \
	--aln_method bowtie2 --SS_lib_type RF --gene_trans_map $GENE_TRANS_MAP --coordsort_bam --prep_reference --thread_count 128 --debug

echo ""
echo "Done!"
echo ""
echo ""
echo "Building transcript matrices ..."
echo ""

# build transcript and gene expression matrices
singularity exec -B $SCRATCH:${HOME} -e $TRINITY_IMAGE /usr/local/bin/util/abundance_estimates_to_matrix.pl --est_method RSEM --gene_trans_map $GENE_TRANS_MAP --out_prefix RSEM --quant_files $QUANT_FILES --name_sample_by_basedir

echo ""
echo "Done!"
echo ""

# unload the modules
module unload singularity/4.1.0-nohost



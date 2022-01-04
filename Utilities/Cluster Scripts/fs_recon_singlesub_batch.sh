#!/bin/bash
#
##SBATCH --job-name=fs_recon_single
#SBATCH --output=res.txt
#SBATCH --ntasks=1
#SBATCH --partition=short
#SBATCH --time=12:00:00
#SBATCH --mem-per-cpu=64G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=irwinz@uab.edu

echo "LOADING FREESURFER"

module load rc/freesurfer/freesurfer-5.3.0

echo "SETTING VARIABLES"

subj=${subject}
subjdir=${subdir}
infile=${subfile}

echo "  subject: $subj"
echo "  directory: $subjdir"
echo "  file: $infile"

echo "STARTING RECON-ALL"

recon-all -i $infile -s $subj -sd $subjdir -all

echo "DONE"
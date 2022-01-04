#!/bin/bash
#
#SBATCH --job-name=fs_recon_single
#SBATCH --output=res.txt
#SBATCH --ntasks=1
#SBATCH --partition=short
#SBATCH --time=8:00:00
#SBATCH --mem-per-cpu=64G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=irwinz@uab.edu

module load rc/freesurfer/freesurfer-5.3.0

echo STARTING AT `date`
echo "running on: "
hostname

#run recon-all here
subj=LFP014
subjdir=/scratch/irwinz/subjects
infile=/scratch/irwinz/LFP014_preop_mri.nii
outfile=/scratch/irwinz/LFP014_preop_mri_out.nii

#mri_convert -c -oc 0 0 0 $infile $outfile

#sleep 15

recon-all -i $infile -s $subj -sd $subjdir -all

echo FINISHED at `date`


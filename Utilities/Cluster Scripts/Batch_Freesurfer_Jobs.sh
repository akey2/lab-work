#!/bin/bash

subjectfolder=$USER_DATA/freesurfer_input
scratchdir=$USER_SCRATCH/freesurfer_scratch
outputfolder=$USER_DATA/freesurfer_output

if [ ! -e "$scratchdir" ]; then
  mkdir -m 777 "$scratchdir"
fi

if [ ! -e "$outputfolder" ]; then
  mkdir -m 777 "$outputfolder"
fi

for subdir in "$subjectfolder"/*/; do

  if [ -d "$subdir" ]; then
  
    echo "$subdir"

    subid=$(basename "$subdir")
    echo "$subid"
    
    cp -r "$subdir" "$scratchdir"/"$subid"
    
    files=("$scratchdir"/"$subid"/*.*)
    
    if [ -f ${files[0]} ]; then
      echo ${files[0]}
      sbatch --job-name=fs_recon_"$subid" --export=subject="$subid",subdir="$outputfolder",subfile=${files[0]} $HOME/jobs/fs_recon_singlesub_batch.sh
    fi
    
    #rm -r "$scratchdir"/"$subid"
    
  fi
  #mkdir "$scratchdir"/"$subid"
  #cp "$subdir" "$scratchdir"/"$subid"
  
  #files=(*.*)

  #sbatch --job-name=fs_recon_"$subid" --export=subject="$subid",subdir="$scratchdir",subfile=${files[0]} fs_recon_singlesub.sh
  
done

# wait until all jobs are done
#while [ $(squeue -u irwinz | grep [[:digit:]] -c) -ne 0 ]; do :; done


# move output files to $USER_DATA
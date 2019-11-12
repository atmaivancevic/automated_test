#!/bin/bash

## Script for adding bigwig tracks with hubload.py
## Date: 28 Oct 2019
##
## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/4_bigwigs/control \
## project=hct116_CUTnRUN_21Oct19 \
## trackdb=~/hub/hg38/trackDb.txt \
## sbatch hubload_bigwig.q

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=1:00:00
#SBATCH --mem=1GB

# Job name and output
#SBATCH -J hubload_bigwig
#SBATCH -o /Users/%u/slurmOut/slurm-%j.out
#SBATCH -e /Users/%u/slurmErr/slurm-%j.err

# commands go here
pwd; hostname; date

echo "Project: "$project
echo "TrackDb: "$trackdb

echo $(date +"[%b %d %H:%M:%S] Adding bigwig tracks to hub...")

for i in $inDir/*.bw 
do
	echo "Processing file: "$i
	hubload.py --input $i --supertrack $project --trackDb $trackdb --autoScale on
	echo $(date +"[%b %d %H:%M:%S] Done")
done

echo $(date +"[%b %d %H:%M:%S] All done!")
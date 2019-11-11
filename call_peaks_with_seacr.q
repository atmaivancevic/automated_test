#!/bin/bash

## Script for running SEACR on bedgraph files
## Date: 28 October 2019 
##
## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/5_seacr_output/histone \
## controlFile=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/5_seacr_output/control/*.bedgraph \
## outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/5_seacr_output/histone \
## stringency=relaxed \
## sbatch --array=0-1 call_peaks_with_seacr.q

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -c 2
#SBATCH --time=3:00:00
#SBATCH --mem=8GB

# Job name and output
#SBATCH -J seacr_call_peaks
#SBATCH -o /Users/%u/slurmOut/slurm-%A_%a.out
#SBATCH -e /Users/%u/slurmErr/slurm-%A_%a.err

# Load modules
module load bedtools R/3.5.1

# Define query files
queries=($(ls ${inDir}/*.bedgraph | xargs -n 1 basename))

# run the thing
pwd; hostname; date

echo "Target file: "${queries[$SLURM_ARRAY_TASK_ID]}
echo "Control file: "${controlFile}
echo $(date +"[%b %d %H:%M:%S] Starting seacr...")

bash /Shares/CL_Shared/programs/SEACR/SEACR_1.1.sh \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]} \
${controlFile} \
norm \
${stringency} \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.bedgraph}

echo $(date +"[%b %d %H:%M:%S] Done!")
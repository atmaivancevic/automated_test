#!/bin/bash

## Script for running macs2 on paired-end data (no input IgG)
## Date: 24 October 2019
##
## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/2_bams/control outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/3_macs2_output/control genome=hs sbatch --array=0-0 call_peaks_with_macs2.q

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --time=12:00:00
#SBATCH --mem=64G

# Job name and output
#SBATCH -J macs2_call_peaks
#SBATCH -o /Users/%u/slurmOut/slurm-%A_%a.out
#SBATCH -e /Users/%u/slurmErr/slurm-%A_%a.err

# Load modules
module load python/2.7.14/MACS/2.1.1

# Define query files
queries=($(ls ${inDir}/*.bam | xargs -n 1 basename))

# Run the thing
pwd; hostname; date

echo "macs2 version: "$(macs2 --version)
echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

echo $(date +"[%b %d %H:%M:%S] Calling peaks with macs2...")

macs2 callpeak \
--format BAMPE \
--treatment ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]} \
--name ${queries[$SLURM_ARRAY_TASK_ID]%.sorted.bam} \
--outdir ${outDir} \
-g ${genome} \
--SPMR -B \
--call-summits

echo $(date +"[%b %d %H:%M:%S] Done!")

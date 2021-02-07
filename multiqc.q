#!/bin/bash

## Script for running multiqc
## Date: 23 Oct 2019
##
## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/reports/raw_fastqc outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/reports/raw_multiqc sbatch multiqc.q

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=0:30:00
#SBATCH --mem=4GB

# Job name and output
#SBATCH -J multiqc
#SBATCH -o /Users/%u/slurmOut/slurm-%j.out
#SBATCH -e /Users/%u/slurmErr/slurm-%j.err

# load modules
module load singularity

# define key variables
multiqc=/scratch/Shares/public/singularity/multiqc-1.7.img

# run MultiQC
pwd; hostname; date

echo "Singularity version: "$(singularity --version)
echo "MultiQC version: "$(singularity exec --bind /scratch/Users ${multiqc} multiqc --version)
echo $(date +"[%b %d %H:%M:%S] Running multiqc...")

singularity exec --bind /scratch/Users ${multiqc} \
multiqc \
${inDir}/*.zip \
--outdir ${outDir}

echo $(date +"[%b %d %H:%M:%S] Done!")

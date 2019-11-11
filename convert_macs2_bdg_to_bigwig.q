#!/bin/bash

## Script for converting macs2 bedgraphs to bigwigs
## Date: 25 Oct 2019 
##
## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/3_macs2_output/control outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/4_bigwigs/control sbatch --array 0-0 convert_macs2_bdg_to_bigwig.q

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time=6:00:00
#SBATCH --mem=32GB

# Job name and output
#SBATCH -J bedgraphToBigwig
#SBATCH -o /Users/%u/slurmOut/slurm-%A_%a.out
#SBATCH -e /Users/%u/slurmErr/slurm-%A_%a.err

# define key variables
chromSizesFile=/Shares/CL_Shared/db/genomes/hg38/fa/hg38.chrom.sizes

# define query files
queries=($(ls $inDir/*treat*.bdg | xargs -n 1 basename))

# run the thing
pwd; hostname; date

echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}
echo $(date +"[%b %d %H:%M:%S] Sorting bedgraph...")

sort -k1,1 -k2,2n ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]} > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.bdg}.sorted.bdg

echo $(date +"[%b %d %H:%M:%S] Converting sorted bedgraph to bigwig...")

bedGraphToBigWig ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.bdg}.sorted.bdg $chromSizesFile ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.bdg}.bw

echo $(date +"[%b %d %H:%M:%S] Removing sorted bedgraph...")

rm ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.bdg}.sorted.bdg

#!/bin/bash

## Script for converting a paired-end bam to a fragment bedgraph file
## Date: 12 Aug 2019 

## Example usage:
## inDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/2_bams/control outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/5_seacr_output/control sbatch --array 0-0 convert_bam_to_fragment_bdg.q

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=02:00:00
#SBATCH --mem=64GB

# Job name and output
#SBATCH -J bam_to_fragment_bdg
#SBATCH -o /Users/%u/slurmOut/slurm-%A_%a.out
#SBATCH -e /Users/%u/slurmErr/slurm-%A_%a.err

# Set query files
queries=($(ls ${inDir}/*.bam | xargs -n 1 basename))

# Load modules
module load samtools/1.8 
module load bedtools/2.28.0

# Set constant variables
genomeChromSizes=/Shares/CL_Shared/db/genomes/hg38/fa/hg38.main.chrom.sizes

# Run samtools
pwd; hostname; date

echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

echo $(date +"[%b %d %H:%M:%S] Sort bam by read name...")
samtools sort -n ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]} -o ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.nameSorted.tmp

echo $(date +"[%b %d %H:%M:%S] Fix read mates...")
samtools fixmate ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.nameSorted.tmp ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.fixed.tmp

echo $(date +"[%b %d %H:%M:%S] Convert bam to bedpe...")
bedtools bamtobed -bedpe -i ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.fixed.tmp > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.tmp

echo $(date +"[%b %d %H:%M:%S] Filter read pairs >1000 bp apart...")
awk '$1==$4 && $6-$2 < 1000 {print $0}' ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.tmp > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.tmp

echo $(date +"[%b %d %H:%M:%S] Extract coordinates...")
cut -f 1,2,6 ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.tmp > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.fragments.tmp

echo $(date +"[%b %d %H:%M:%S] Sort bed file...")
bedtools sort -i ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.fragments.tmp > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.fragments.sorted.tmp

echo $(date +"[%b %d %H:%M:%S] Calculate genome coverage for final bedgraph...")
bedtools genomecov -bg -i ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed.clean.fragments.sorted.tmp -g $genomeChromSizes > ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]%.sorted.bam}.bedgraph

echo $(date +"[%b %d %H:%M:%S] Remove intermediate files...")
rm ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}*.tmp

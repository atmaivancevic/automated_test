#!/bin/bash

## Script for running deeptools 
## Date: 22 Jan 2019 
##
## Example usage:
## bwDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/4_bigwigs \
## bedDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/3_macs2_output/histone \
## outDir=/Shares/CL_Shared/data/atma/pipeline_testing/hct116_CUTnRUN_21Oct19/6_signal_heatmaps \
## sbatch --array 0-1 deeptools_heatmap_from_narrowPeak.q

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --time=1-00:00
#SBATCH --mem=8GB

# Job name and output
#SBATCH -J deeptools
#SBATCH -o /Users/%u/slurmOut/slurm-%A_%a.out
#SBATCH -e /Users/%u/slurmErr/slurm-%A_%a.err

# load modules
module load singularity

# define constant variables
deeptools=/scratch/Shares/public/singularity/deeptools-3.0.1-py35_1.img

# define bed files
queries=($(ls ${bedDir}/*.narrowPeak | xargs -n 1 basename))

# set bigwigs and sample labels
wigs=$(ls $bwDir/*.bw | tr "\n" " ")
samplesLabel=$(ls $bwDir/*.bw | xargs -n 1 basename | sed 's/_treat_pileup.bw//g' | tr "\n" " ")

# run the thing
pwd; hostname; date

echo "Starting deeptools..."
echo $(date +"[%b %d %H:%M:%S] Compute matrix...")

# Use "computeMatrix" to generate data underlying heatmap
windowLeft=4000
windowRight=4000
binSize=10
numCPU=16

singularity exec --bind /Shares/CL_Shared $deeptools \
computeMatrix reference-point \
--referencePoint TSS \
--scoreFileName ${wigs} \
--regionsFileName ${bedDir}/${queries[$SLURM_ARRAY_TASK_ID]} \
--beforeRegionStartLength ${windowLeft} \
--afterRegionStartLength ${windowRight} \
--binSize ${binSize} \
--missingDataAsZero \
-o ${outDir}/"BEDFILE"_${queries[$SLURM_ARRAY_TASK_ID]}.mat.gz \
-p ${numCPU}

echo $(date +"[%b %d %H:%M:%S] Plot heatmap...")

# Use "plotHeatmap" to create a png or pdf
zMin=0
yMin=0

singularity exec --bind /Shares/CL_Shared $deeptools \
plotHeatmap \
-m $outDir/"BEDFILE"_${queries[$SLURM_ARRAY_TASK_ID]}.mat.gz \
--outFileName $outDir/"BEDFILE"_${queries[$SLURM_ARRAY_TASK_ID]}.png \
--outFileSortedRegions $outDir/"BEDFILE"_${queries[$SLURM_ARRAY_TASK_ID]}.dt.bed \
--outFileNameMatrix $outDir/"BEDFILE"_${queries[$SLURM_ARRAY_TASK_ID]}.matrix.tab \
--sortRegions descend \
--colorMap Blues \
--zMin $zMin --yMin $yMin \
--samplesLabel $samplesLabel \
--regionsLabel ${queries[$SLURM_ARRAY_TASK_ID]}

echo $(date +"[%b %d %H:%M:%S] Done!")
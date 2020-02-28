#!/bin/bash

########################################################################################################
# Paired-End CUT n RUN Pipeline for Fiji HPC 
########################################################################################################

## IMPORTANT:
## This script (PIPELINE.sh) should be run in console and NOT submitted to SLURM.

## DESCRIPTION:
## The pipeline consists of several steps (see below). Each step is contained in a 
## separate script which will be run for each paired-end cut and run library in
## parallel using Fiji's SLURM job arrays. When all samples finish that 
## particular step, the next step will begin. If a job fails (e.g. not enough time, 
## missing file, etc.) the job will not have an exit status of COMPLETED on SLURM, 
## and so the subsequent jobs will not run. If this happens, troubleshoot then
## use sbatch in the console to submit the remaining jobs manually. 

## Run CONFIG.sh to import variables (project directory, reference genome, num of files, etc)
source CONFIG.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Create additional directories to organise data						
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

SETUP=`projectDir=$projectDir \
       sbatch setup_workspace.q`
SETUP_SLURM_ID=$(echo "$SETUP" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Generate fastqc reports for raw fastq files 
# Run separately for control, histone and tf						
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# control
RAWQC_CONTROL=`inDir=$projectDir/0_raw_fastq/control outDir=$projectDir/reports/raw_fastqc \
               sbatch --array 0-$(($controlNum-1)) --dependency=afterok:$SETUP_SLURM_ID fastqc.q`
RAWQC_CONTROL_ID=$(echo "$RAWQC_CONTROL" | sed 's/Submitted batch job //')

# histone
RAWQC_HISTONE=`inDir=$projectDir/0_raw_fastq/histone outDir=$projectDir/reports/raw_fastqc \
               sbatch --array 0-$(($histoneNum-1)) --dependency=afterok:$SETUP_SLURM_ID fastqc.q`
RAWQC_HISTONE_ID=$(echo "$RAWQC_HISTONE" | sed 's/Submitted batch job //')

# tf
RAWQC_TF=`inDir=$projectDir/0_raw_fastq/tf outDir=$projectDir/reports/raw_fastqc \
          sbatch --array 0-$(($tfNum-1)) --dependency=afterok:$SETUP_SLURM_ID fastqc.q`
RAWQC_TF_ID=$(echo "$RAWQC_TF" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Generate a collated multiqc report for raw fastqc files 					
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

RAWQC_MULTI=`inDir=$projectDir/reports/raw_fastqc outDir=$projectDir/reports/raw_multiqc \
             sbatch --dependency=afterok:$RAWQC_CONTROL_ID:$RAWQC_HISTONE_ID:$RAWQC_TF_ID multiqc.q`
RAWQC_MULTI_ID=$(echo "$RAWQC_MULTI" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Trim adapters from raw fastq files using bbduck 					
# Note that array numbers here are halved, since bbduk uses both pairs of fastq files  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

TRIM_CONTROL=`inDir=$projectDir/0_raw_fastq/control outDir=$projectDir/1_trimmed_fastq/control \
              sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$SETUP_SLURM_ID bbduk_PE.q`
TRIM_CONTROL_ID=$(echo "$TRIM_CONTROL" | sed 's/Submitted batch job //')

TRIM_HISTONE=`inDir=$projectDir/0_raw_fastq/histone outDir=$projectDir/1_trimmed_fastq/histone \
              sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$SETUP_SLURM_ID bbduk_PE.q`
TRIM_HISTONE_ID=$(echo "$TRIM_HISTONE" | sed 's/Submitted batch job //')

TRIM_TF=`inDir=$projectDir/0_raw_fastq/tf outDir=$projectDir/1_trimmed_fastq/tf \
         sbatch --array 0-$((($tfNum/2)-1)) --dependency=afterok:$SETUP_SLURM_ID bbduk_PE.q`
TRIM_TF_ID=$(echo "$TRIM_TF" | sed 's/Submitted batch job //')     

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Generate fastqc reports for trimmed fastq files	
# Use the same fastqc.q script as above, but change input dir to 1_trimmed_fastq/ 
# and output dir to reports/trimmed_fastqc/					
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

TRIMQC_CONTROL=`inDir=$projectDir/1_trimmed_fastq/control outDir=$projectDir/reports/trimmed_fastqc \
                sbatch --array 0-$(($controlNum-1)) --dependency=afterok:$TRIM_CONTROL_ID fastqc.q`
TRIMQC_CONTROL_ID=$(echo "$TRIMQC_CONTROL" | sed 's/Submitted batch job //')

TRIMQC_HISTONE=`inDir=$projectDir/1_trimmed_fastq/histone outDir=$projectDir/reports/trimmed_fastqc \
                sbatch --array 0-$(($histoneNum-1)) --dependency=afterok:$TRIM_HISTONE_ID fastqc.q`
TRIMQC_HISTONE_ID=$(echo "$TRIMQC_HISTONE" | sed 's/Submitted batch job //')

TRIMQC_TF=`inDir=$projectDir/1_trimmed_fastq/tf outDir=$projectDir/reports/trimmed_fastqc \
           sbatch --array 0-$(($tfNum-1)) --dependency=afterok:$TRIM_TF_ID fastqc.q`
TRIMQC_TF_ID=$(echo "$TRIMQC_TF" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Generate a collated multiqc report for trimmed fastqc files	
# Use the same multiqc.q script as above, but change input dir to trimmed_fastqc/ 
# and output dir to reports/trimmed_multiqc/			
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

TRIMQC_MULTI=`inDir=$projectDir/reports/trimmed_fastqc outDir=$projectDir/reports/trimmed_multiqc \
              sbatch --dependency=afterok:$TRIMQC_CONTROL_ID:$TRIMQC_HISTONE_ID:$TRIMQC_TF_ID multiqc.q`
TRIMQC_MULTI_ID=$(echo "$TRIMQC_MULTI" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Make unique-mapping/sorted/indexed bams (filter out chrM) using bwa
# Note that array numbers are now halved, since only one bam output for each pair of fastq files						
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

ALIGN_CONTROL=`inDir=$projectDir/1_trimmed_fastq/control outDir=$projectDir/2_bams/control \
               sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$TRIM_CONTROL_ID bwa_PE.q`
ALIGN_CONTROL_ID=$(echo "$ALIGN_CONTROL" | sed 's/Submitted batch job //')

ALIGN_HISTONE=`inDir=$projectDir/1_trimmed_fastq/histone outDir=$projectDir/2_bams/histone \
               sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$TRIM_HISTONE_ID bwa_PE.q`
ALIGN_HISTONE_ID=$(echo "$ALIGN_HISTONE" | sed 's/Submitted batch job //')

ALIGN_TF=`inDir=$projectDir/1_trimmed_fastq/tf outDir=$projectDir/2_bams/tf \
          sbatch --array 0-$((($tfNum/2)-1)) --dependency=afterok:$TRIM_TF_ID bwa_PE.q`
ALIGN_TF_ID=$(echo "$ALIGN_TF" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# For TFs, filter bams into total, <120, and >120 sizes
# This script will also automatically sort and index the new bams made						
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

SUBSET_TF=`inDir=$projectDir/2_bams/tf outDir=$projectDir/2_bams/tf \
           sbatch --array 0-$((($tfNum/2)-1)) --dependency=afterok:$ALIGN_TF_ID subset_by_fragment_size.q`
SUBSET_TF_ID=$(echo "$SUBSET_TF" | sed 's/Submitted batch job //')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Calculate bam fragment size, output table and histogram
# Note that the array number for tf bams has increased now that the subsetted bams are in there too					
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

FRAGSIZE_CONTROL=`inDir=$projectDir/2_bams/control outDir=$projectDir/reports/bam_fragment_size \
                  sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$ALIGN_CONTROL_ID get_fragment_size.q`
FRAGSIZE_CONTROL_ID=$(echo "$FRAGSIZE_CONTROL" | sed 's/Submitted batch job //')

FRAGSIZE_HISTONE=`inDir=$projectDir/2_bams/histone outDir=$projectDir/reports/bam_fragment_size \
                  sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$ALIGN_HISTONE_ID get_fragment_size.q`
FRAGSIZE_HISTONE_ID=$(echo "$FRAGSIZE_HISTONE" | sed 's/Submitted batch job //')

FRAGSIZE_TF=`inDir=$projectDir/2_bams/tf outDir=$projectDir/reports/bam_fragment_size \
             sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$SUBSET_TF_ID get_fragment_size.q`
FRAGSIZE_TF_ID=$(echo "$FRAGSIZE_TF" | sed 's/Submitted batch job //')

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Call peaks using macs2
# # So for each bam, run macs2 (without control file input) 
# # to generate narrowPeaks, summits bed, and SPMR normalized bedgraph						
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

MACS2_CONTROL=`inDir=$projectDir/2_bams/control outDir=$projectDir/3_macs2_output/control genome=hs \
               sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$ALIGN_CONTROL_ID call_peaks_with_macs2.q`
MACS2_CONTROL_ID=$(echo "$MACS2_CONTROL" | sed 's/Submitted batch job //')

MACS2_HISTONE=`inDir=$projectDir/2_bams/histone outDir=$projectDir/3_macs2_output/histone genome=hs \
               sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$ALIGN_HISTONE_ID call_peaks_with_macs2.q`
MACS2_HISTONE_ID=$(echo "$MACS2_HISTONE" | sed 's/Submitted batch job //')

MACS2_TF=`inDir=$projectDir/2_bams/tf outDir=$projectDir/3_macs2_output/tf genome=hs \
          sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$SUBSET_TF_ID call_peaks_with_macs2.q`
MACS2_TF_ID=$(echo "$MACS2_TF" | sed 's/Submitted batch job //')

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Calculate FRIP score (requires bams and macs2 peaks)				
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

FRIP_CONTROL=`bamDir=$projectDir/2_bams/control peakDir=$projectDir/3_macs2_output/control \
              outDir=$projectDir/reports/frip_scores sbatch --array 0-$((($controlNum/2)-1)) \
              --dependency=afterok:$MACS2_CONTROL_ID calculate_frip_score.q`
FRIP_CONTROL_ID=$(echo "$FRIP_CONTROL" | sed 's/Submitted batch job //')

FRIP_HISTONE=`bamDir=$projectDir/2_bams/histone peakDir=$projectDir/3_macs2_output/histone \
              outDir=$projectDir/reports/frip_scores sbatch --array 0-$((($histoneNum/2)-1)) \
              --dependency=afterok:$MACS2_HISTONE_ID calculate_frip_score.q`
FRIP_HISTONE_ID=$(echo "$FRIP_HISTONE" | sed 's/Submitted batch job //')

FRIP_TF=`bamDir=$projectDir/2_bams/tf peakDir=$projectDir/3_macs2_output/tf \
         outDir=$projectDir/reports/frip_scores sbatch --array 0-$((($tfNum/2)*3-1)) \
         --dependency=afterok:$MACS2_TF_ID calculate_frip_score.q`
FRIP_TF_ID=$(echo "$FRIP_TF" | sed 's/Submitted batch job //')

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Convert macs2 bedgraphs to bigwigs						
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

BDG2BW_CONTROL=`inDir=$projectDir/3_macs2_output/control outDir=$projectDir/4_bigwigs \
                sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$MACS2_CONTROL_ID convert_macs2_bdg_to_bigwig.q`
BDG2BW_CONTROL_ID=$(echo "$BDG2BW_CONTROL" | sed 's/Submitted batch job //')

BDG2BW_HISTONE=`inDir=$projectDir/3_macs2_output/histone outDir=$projectDir/4_bigwigs \
                sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$MACS2_HISTONE_ID convert_macs2_bdg_to_bigwig.q`
BDG2BW_HISTONE_ID=$(echo "$BDG2BW_HISTONE" | sed 's/Submitted batch job //')

BDG2BW_TF=`inDir=$projectDir/3_macs2_output/tf outDir=$projectDir/4_bigwigs \
           sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$MACS2_TF_ID convert_macs2_bdg_to_bigwig.q`
BDG2BW_TF_ID=$(echo "$BDG2BW_TF" | sed 's/Submitted batch job //')

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Pre-process bams to prepare for running seacr
# # I.e. Sort bams by read name, fix mate pairs, and convert to fragment bedgraphs			
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

PREPROCESS_CONTROL=`inDir=$projectDir/2_bams/control outDir=$projectDir/5_seacr_output/control \
                    sbatch --array 0-$((($controlNum/2)-1)) --dependency=afterok:$ALIGN_CONTROL_ID convert_bam_to_fragment_bdg.q`
PREPROCESS_CONTROL_ID=$(echo "$PREPROCESS_CONTROL" | sed 's/Submitted batch job //')                    

PREPROCESS_HISTONE=`inDir=$projectDir/2_bams/histone outDir=$projectDir/5_seacr_output/histone \
                    sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$ALIGN_HISTONE_ID convert_bam_to_fragment_bdg.q`
PREPROCESS_HISTONE_ID=$(echo "$PREPROCESS_HISTONE" | sed 's/Submitted batch job //')  

PREPROCESS_TF=`inDir=$projectDir/2_bams/tf outDir=$projectDir/5_seacr_output/tf \
               sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$SUBSET_TF_ID convert_bam_to_fragment_bdg.q`
PREPROCESS_TF_ID=$(echo "$PREPROCESS_TF" | sed 's/Submitted batch job //')  

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Call peaks with seacr
# # Make sure to set igg as the control for both histone and tf files
# # In each case, run seacr with both relaxed and stringent settings					
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# seacr relaxed
SEACR_RELAXED_HISTONE=`inDir=$projectDir/5_seacr_output/histone outDir=$projectDir/5_seacr_output/histone \
                       controlFile=$projectDir/5_seacr_output/control/*.bedgraph stringency=relaxed \
                       sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$PREPROCESS_CONTROL_ID:$PREPROCESS_HISTONE_ID call_peaks_with_seacr.q`
SEACR_RELAXED_HISTONE_ID=$(echo "$SEACR_RELAXED_HISTONE" | sed 's/Submitted batch job //') 

SEACR_RELAXED_TF=`inDir=$projectDir/5_seacr_output/tf outDir=$projectDir/5_seacr_output/tf \
                  controlFile=$projectDir/5_seacr_output/control/*.bedgraph stringency=relaxed \
                  sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$PREPROCESS_CONTROL_ID:$PREPROCESS_TF_ID call_peaks_with_seacr.q`
SEACR_RELAXED_TF_ID=$(echo "$SEACR_RELAXED_TF" | sed 's/Submitted batch job //') 

# seacr stringent
SEACR_STRINGENT_HISTONE=`inDir=$projectDir/5_seacr_output/histone outDir=$projectDir/5_seacr_output/histone \
                         controlFile=$projectDir/5_seacr_output/control/*.bedgraph stringency=stringent \
                         sbatch --array 0-$((($histoneNum/2)-1)) --dependency=afterok:$PREPROCESS_CONTROL_ID:$PREPROCESS_HISTONE_ID call_peaks_with_seacr.q`
SEACR_STRINGENT_HISTONE_ID=$(echo "$SEACR_STRINGENT_HISTONE" | sed 's/Submitted batch job //') 

SEACR_STRINGENT_TF=`inDir=$projectDir/5_seacr_output/tf outDir=$projectDir/5_seacr_output/tf \
                    controlFile=$projectDir/5_seacr_output/control/*.bedgraph stringency=stringent \
                    sbatch --array 0-$((($tfNum/2)*3-1)) --dependency=afterok:$PREPROCESS_CONTROL_ID:$PREPROCESS_TF_ID call_peaks_with_seacr.q`
SEACR_STRINGENT_TF_ID=$(echo "$SEACR_STRINGENT_TF" | sed 's/Submitted batch job //') 

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Make deeptools signal heatmaps using all macs2 bigwig files and gencode tss          
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# igg peaks
DEEPTOOLS_CONTROL=`bwDir=$projectDir/4_bigwigs bedDir=$projectDir/3_macs2_output/control \
                   outDir=$projectDir/6_signal_heatmaps sbatch --array 0-$((($controlNum/2)-1)) \
                   --dependency=afterok:$BDG2BW_CONTROL_ID:$BDG2BW_HISTONE_ID:$BDG2BW_TF_ID deeptools_heatmap_from_narrowPeak.q`
DEEPTOOLS_CONTROL_ID=$(echo "$DEEPTOOLS_CONTROL" | sed 's/Submitted batch job //') 

# histone peaks
DEEPTOOLS_HISTONE=`bwDir=$projectDir/4_bigwigs bedDir=$projectDir/3_macs2_output/histone \
                   outDir=$projectDir/6_signal_heatmaps sbatch --array 0-$((($histoneNum/2)-1)) \
                   --dependency=afterok:$BDG2BW_CONTROL_ID:$BDG2BW_HISTONE_ID:$BDG2BW_TF_ID deeptools_heatmap_from_narrowPeak.q`
DEEPTOOLS_HISTONE_ID=$(echo "$DEEPTOOLS_HISTONE" | sed 's/Submitted batch job //') 

# tf peaks
DEEPTOOLS_TF=`bwDir=$projectDir/4_bigwigs bedDir=$projectDir/3_macs2_output/tf \
              outDir=$projectDir/6_signal_heatmaps sbatch --array 0-$((($tfNum/2)*3-1)) \
              --dependency=afterok:$BDG2BW_CONTROL_ID:$BDG2BW_HISTONE_ID:$BDG2BW_TF_ID deeptools_heatmap_from_narrowPeak.q`
DEEPTOOLS_TF_ID=$(echo "$DEEPTOOLS_TF" | sed 's/Submitted batch job //') 

# gencode tss
DEEPTOOLS_GENCODE=`bwDir=$projectDir/4_bigwigs bedDir=/Shares/CL_Shared/db/genomes/hg38/annotations \
                   bedFile=gencode.v28.genes.tss.bed outDir=$projectDir/6_signal_heatmaps \
                   sbatch --dependency=afterok:$BDG2BW_CONTROL_ID:$BDG2BW_HISTONE_ID:$BDG2BW_TF_ID deeptools_heatmap_from_gencode_bed.q`
DEEPTOOLS_GENCODE_ID=$(echo "$DEEPTOOLS_GENCODE" | sed 's/Submitted batch job //') 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Hubload bams and bigwigs as a group    
# IMPORTANT NOTE these jobs should run one after another, NOT at the same time (note dependencies below)       
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# bigwigs first
HUBLOAD_BIGWIGS=`inDir=$projectDir/4_bigwigs trackName=$trackName trackdb=$trackdb \
                 sbatch --dependency=afterok:$BDG2BW_CONTROL_ID:$BDG2BW_HISTONE_ID:$BDG2BW_TF_ID hubload_bigwig.q`
HUBLOAD_BIGWIGS_ID=$(echo "$HUBLOAD_BIGWIGS" | sed 's/Submitted batch job //')

# then bams
HUBLOAD_BAMS_CONTROL=`inDir=$projectDir/2_bams/control trackName=$trackName trackdb=$trackdb \
                      sbatch --dependency=afterok:$HUBLOAD_BIGWIGS_ID hubload_bam.q`
HUBLOAD_BAMS_CONTROL_ID=$(echo "$HUBLOAD_BAMS_CONTROL" | sed 's/Submitted batch job //')

HUBLOAD_BAMS_HISTONE=`inDir=$projectDir/2_bams/histone trackName=$trackName trackdb=$trackdb \
                      sbatch --dependency=afterok:$HUBLOAD_BAMS_CONTROL_ID hubload_bam.q`
HUBLOAD_BAMS_HISTONE_ID=$(echo "$HUBLOAD_BAMS_HISTONE" | sed 's/Submitted batch job //')

HUBLOAD_BAMS_TF=`inDir=$projectDir/2_bams/tf trackName=$trackName trackdb=$trackdb \
                 sbatch --dependency=afterok:$HUBLOAD_BAMS_HISTONE_ID hubload_bam.q`
HUBLOAD_BAMS_TF_ID=$(echo "$HUBLOAD_BAMS_TF" | sed 's/Submitted batch job //')               

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Calculate repeat enrichment with giggle 				
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Find motifs with meme/fimo (optional)						
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Print SLURM JOB IDs to console
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~SLURM Job IDs~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Set up workspace: $SETUP_SLURM_ID"
echo "Quality check raw fastq (igg, histone, tf): $RAWQC_CONTROL_ID, $RAWQC_HISTONE_ID, $RAWQC_TF_ID"
echo "Generate raw multiqc report: $RAWQC_MULTI_ID"
echo "Trim adapters (igg, histone, tf): $TRIM_CONTROL_ID, $TRIM_HISTONE_ID, $TRIM_TF_ID"
echo "Quality check trimmed fastq (igg, histone, tf): $TRIMQC_CONTROL_ID, $TRIMQC_HISTONE_ID, $TRIMQC_TF_ID"
echo "Generate trimmed multiqc report: $TRIMQC_MULTI_ID"
echo "Align reads to generate bams (igg, histone, tf): $ALIGN_CONTROL_ID, $ALIGN_HISTONE_ID, $ALIGN_TF_ID"
echo "Subset TF bams by fragment size: $SUBSET_TF_ID"
echo "Calculate bam fragment size (igg, histone, tf): $FRAGSIZE_CONTROL_ID, $FRAGSIZE_HISTONE_ID, $FRAGSIZE_TF_ID"
echo "Call peaks using MACS2 (igg, histone, tf): $MACS2_CONTROL_ID, $MACS2_HISTONE_ID, $MACS2_TF_ID"
echo "Calculate frip score (igg, histone, tf): $FRIP_CONTROL_ID, $FRIP_HISTONE_ID, $FRIP_TF_ID"
echo "Convert MACS2 bedgraphs to bigwigs (igg, histone, tf): $BDG2BW_CONTROL_ID, $BDG2BW_HISTONE_ID, $BDG2BW_TF_ID"
echo "Preprocess bams for seacr input (igg, histone, tf): $PREPROCESS_CONTROL_ID, $PREPROCESS_HISTONE_ID, $PREPROCESS_TF_ID"
echo "Call peaks using SEACR relaxed (histone, tf): $SEACR_RELAXED_HISTONE_ID, $SEACR_RELAXED_TF_ID"
echo "Call peaks using SEACR stringent (histone, tf): $SEACR_STRINGENT_HISTONE_ID, $SEACR_STRINGENT_TF_ID"
echo "Generate deeptools heatmaps (igg, histone, tf, gencode tss): $DEEPTOOLS_CONTROL_ID, $DEEPTOOLS_HISTONE_ID, $DEEPTOOLS_TF_ID, $DEEPTOOLS_GENCODE_ID"
echo "Hubload all bigwigs: $HUBLOAD_BIGWIGS_ID"
echo "Hubload bams (igg, histone, tf): $HUBLOAD_BAMS_CONTROL_ID, $HUBLOAD_BAMS_HISTONE_ID, $HUBLOAD_BAMS_TF_ID"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


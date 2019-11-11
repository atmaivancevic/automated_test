#########################################################################################
# Paired-End CUT n RUN Pipeline for Fiji HPC 				                     	    #
# Example Configuration File                                    					    #
#########################################################################################

# Specify the dir where all data will be stored
projectDir=/Shares/CL_Shared/data/atma/automated_test/HCT116_Dave_21Oct19 

# Make separate dirs for control, histone and tf
mkdir -p ${projectDir}/0_raw_fastq
mkdir -p ${projectDir}/0_raw_fastq/control
mkdir -p ${projectDir}/0_raw_fastq/histone
mkdir -p ${projectDir}/0_raw_fastq/tf

# Place raw paired-end fastq files in the appropriate dirs
# Paired files should be called `uniqueId_R1.fastq.gz` and `uniqueId_R2.fastq.gz`
# Rename files if necessary, e.g. using mv or rename commands

#########################################################################################
# Example of raw fastq files:

# 0_raw_fastq/control:
# IgG_S20_R1.fastq.gz      IgG_S20_R2.fastq.gz

# 0_raw_fastq/histone:
# K9me3_P_S23_R1.fastq.gz  K9me3_P_S23_R2.fastq.gz  
# K9me3_S_S22_R1.fastq.gz  K9me3_S_S22_R2.fastq.gz

# 0_raw_fastq/tf:
# 4H8_P_S26_R1.fastq.gz    4H8_P_S26_R2.fastq.gz  
# 4H8_S_S25_R1.fastq.gz    4H8_S_S25_R2.fastq.gz  
# 8wG_S24_R1.fastq.gz      8wG_S24_R2.fastq.gz  
# CTCF_S21_R1.fastq.gz     CTCF_S21_R2.fastq.gz
#########################################################################################

# List the number of files in each dir
# Need to know these numbers beforehand in order to set up job arrays in pipeline
controlNum=2
histoneNum=4
tfNum=8

# Also add reference genome info
# Currently everything is set to human (hg38)
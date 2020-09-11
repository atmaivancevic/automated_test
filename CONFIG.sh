#########################################################################################
# Paired-End CUT n RUN Pipeline for Fiji HPC 				                     	    #
# Example Configuration File                                    					    #
#########################################################################################

# Specify the dir where all data will be stored
projectDir=/Shares/CL_Shared/data/atma/1_QUARANTINE/7_SEPT2020/AMC_CutnRun/Jedlicka_t2

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
# IgG_R1.fastq.gz      IgG_R2.fastq.gz

# 0_raw_fastq/histone:
# K9me3_P_R1.fastq.gz  K9me3_P_R2.fastq.gz  
# K9me3_S_R1.fastq.gz  K9me3_S_R2.fastq.gz

# 0_raw_fastq/tf:
# 4H8_P_R1.fastq.gz    4H8_P_R2.fastq.gz  
# 4H8_S_R1.fastq.gz    4H8_S_R2.fastq.gz  
# 8wG_R1.fastq.gz      8wG_R2.fastq.gz  
# CTCF_R1.fastq.gz     CTCF_R2.fastq.gz
#########################################################################################

# List the number of files in each dir
# Need to know these numbers beforehand in order to set up job arrays in pipeline
controlNum=2
histoneNum=8
tfNum=6

# track name for UCSC upload of these samples
# should include cell type and date of seq run
trackName=Jedlicka_t2
trackdb=~/hub/hg38/trackDb.txt # location of your trackDB.txt file

# Also add reference genome info
# Currently everything is set to human (hg38)

# To run the pipeline:
# Change the above variables as needed
# Then at the terminal, in the github repo containing these scripts, run: ./PIPELINE.sh
# After all the jobs have finished (can check by looking at the slurm queue), run "hubsync" to sync all updates to the remote UCSC hub

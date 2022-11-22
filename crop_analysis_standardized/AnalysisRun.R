library(plyr)
library(ggplot2)
library(tidyverse)

# setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/2022-10-19_4thRun/output_seg_14")
setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/2022-10-19_4thRun/output_seg_21")
# ============================================================================
# 
#
#  DESCRIPTION: 
#              
#       AUTHOR: Christopher Schmied, 
#      CONTACT: 
#     INSITUTE: 
#
#         BUGS:
#        NOTES: 
# DEPENDENCIES: plyr - install.packages("plyr")
#
#
#      VERSION: 0.0.1
#      CREATED: 2022-08-01
#     REVISION: 
#
# ============================================================================
# user defined parameters

# =============================================================================
# function for getting the metadata from filename
# =============================================================================
# function that adds metadata as a column
read_table_filename <- function(filename){
  ret <- read.csv(filename, header = TRUE, stringsAsFactors = FALSE )
  # extracts from filename the metadata and adds as column
  ret$date <- regmatches(basename(filename), regexpr('(?<=\\d-)\\d{8}(?=-14-|-21-)', basename(filename), perl=TRUE))
  ret$set <- regmatches(basename(filename), regexpr('(?<=Crop-)\\d(?=-\\d{8})', basename(filename), perl=TRUE))
  ret$timepoint <- regmatches(basename(filename), regexpr('(?<=\\d{8}-)14|21(?=-\\d)', basename(filename), perl=TRUE))
  ret$name <- regmatches(basename(filename), regexpr('(?<=-14-|-21-).+?(?=-\\d\\d\\d-\\d|-\\d\\D.tif)', basename(filename), perl=TRUE))
  ret$stack <- regmatches(basename(filename), regexpr('(?<=\\d-|\\D-)\\d{3}(?=-\\d)', basename(filename), perl=TRUE))
  ret$crop <- regmatches(basename(filename), regexpr('(?<=-\\d\\d\\d-).+?(?=.tif_)', basename(filename), perl=TRUE))
  
  ret
}

# ============================================================================
# only processes shape results
file.list <- list.files(recursive=TRUE, pattern = ".*_Meas.csv", full.names = TRUE )

# llply needs plyr package
filename.table <- llply(file.list, read_table_filename)

# now rbind is combining them all into one list
filename.combine <- do.call("rbind", filename.table)

filename.combine
# reorders columns
filename.combine1 <- filename.combine[,c(13,14,15,16,17,18,1,2,3,4,5,6,7,8,9,10,11,12)]



# read in treatment table
treatment_file <- read.csv("/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/2022-10-08_4th_Run/clean_crops2.csv", header = TRUE)
treatment_file$X <- NULL

# clean up dataframes for join
filename.combine1$stack <- as.numeric(filename.combine1$stack)
filename.combine1$set<- as.numeric(filename.combine1$set)
filename.combine1$timepoint <- as.numeric(filename.combine1$timepoint)
treatment_file$date <- as.character(treatment_file$date)

# join with treatment table
joined_table <- treatment_file %>% inner_join(filename.combine1, by = c("date", "set", "timepoint", "name", "stack", "crop"))

# compute ratios
joined_table$TotalVolumn <- joined_table$TotalpxVolume * joined_table$VoxelSize
joined_table$SizeMap2 <- joined_table$SizePxMap2 * joined_table$VoxelSize
joined_table$SizeSox2 <- joined_table$SizePxSox2 * joined_table$VoxelSize
joined_table$RatioSizeMap2 <- joined_table$SizePxMap2 / joined_table$TotalpxVolume
joined_table$RatioSizeSox2 <- joined_table$SizePxSox2 / joined_table$TotalpxVolume
joined_table$RatioIntMap2 <- joined_table$meanOuterMap2Map2 / joined_table$meanInnerMap2Map2
joined_table$RatioIntSox2 <- joined_table$meanOuterSox2Sox2 / joined_table$meanInnerSox2Sox2 
joined_table$RatioIntSox2Map2 <- joined_table$meanOuterSox2Map2 / joined_table$meanInnerSox2Map2 

ggplot(joined_table, aes(x=Treatment, y=RatioSizeMap2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("RatioSizeMap2")

ggplot(joined_table, aes(x=Treatment, y=RatioSizeSox2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("RatioSizeSox2")

ggplot(joined_table, aes(x=Treatment, y=RatioIntMap2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("RatioIntMap2")

ggplot(joined_table, aes(x=Treatment, y=RatioIntSox2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("RatioIntSox2")

ggplot(joined_table, aes(x=Treatment, y=Dice, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("Dice")

ggplot(joined_table, aes(x=Treatment, y=meanInnerMap2Map2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanInnerMap2Map2")

ggplot(joined_table, aes(x=Treatment, y=meanOuterMap2Map2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanOuterMap2Map2")

ggplot(joined_table, aes(x=Treatment, y=meanInnerSox2Sox2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanInnerSox2Sox2")

ggplot(joined_table, aes(x=Treatment, y=meanOuterSox2Sox2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanOuterSox2Sox2")

ggplot(joined_table, aes(x=Treatment, y=meanInnerSox2Map2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanInnerSox2Map2")

ggplot(joined_table, aes(x=Treatment, y=meanOuterSox2Map2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("meanOuterSox2Map2")

ggplot(joined_table, aes(x=Treatment, y=RatioIntSox2Map2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("RatioIntSox2Map2")

ggplot(joined_table, aes(x=Treatment, y=TotalVolumn, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("TotalVolumn")

ggplot(joined_table, aes(x=Treatment, y=SizeMap2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("SizeMap2")

ggplot(joined_table, aes(x=Treatment, y=SizeSox2, fill=Treatment)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  ggtitle("SizeSox2")

head(joined_table)
a <- subset(joined_table, Treatment == 'A')
b <- subset(joined_table, Treatment == 'B')

test <- wilcox.test(a$RatioIntSox2Map2, b$RatioIntSox2Map2)
test

test <- wilcox.test(a$RatioIntSox2Map2, b$RatioIntSox2Map2)
test

wilcox.test(a$RatioIntMap2, b$RatioIntMap2)

joined_table %>% group_by(Treatment) %>% summarise(
  median = median(RatioIntSox2Map2),
  mean = mean(RatioIntSox2Map2)
)

a_around_median <- a %>% filter(RatioIntSox2Map2 < 0.802 & RatioIntSox2Map2 > 0.801)
b_around_median <- b %>% filter(RatioIntSox2Map2 < 0.742 & RatioIntSox2Map2 > 0.740)

a_around_median
b_around_median

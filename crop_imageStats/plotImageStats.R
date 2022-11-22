library(plyr)
library(ggplot2)
library(tidyverse)

setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/imageStats/")
# setwd("/home/christopher.schmied/Desktop/test_out")
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
  ret$crop <- regmatches(basename(filename), regexpr('(?<=-\\d{3}-).+?(?=_sox2|_map2)', basename(filename), perl=TRUE))
  ret$channel <- regmatches(basename(filename), regexpr('(?<=_)sox2|map2(?=_imgStat.csv)', basename(filename), perl=TRUE))
  ret
}

# ============================================================================
# only processes shape results
file.list <- list.files(recursive=TRUE, pattern = ".*_imgStat.csv", full.names = TRUE )

# llply needs plyr package
filename.table <- llply(file.list, read_table_filename)

# now rbind is combining them all into one list
filename.combine <- do.call("rbind", filename.table)

filename.combine$X <- NULL

# reorders columns
filename.combine1 <- filename.combine[,c(7,8,9,10,11,12,13,1,2,3,4,5,6)]
head(filename.combine1)

# filter channels and split into separate lists
split_dataset <- group_split(filename.combine1 %>% group_by(channel))
map2 <- split_dataset[[1]]
sox2 <- split_dataset[[2]]

# plot mean per timepoint
# Todo: plot StDev and Max per timepoint
# Todo: boxplot with dotplot
ggplot(map2, aes(x=timepoint, y=Mean, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 400)) +
  ggtitle("map2: Mean intensity per timepoint")

ggsave('map2_MeanInt_Tp.png')

ggplot(map2, aes(x=timepoint, y=Max, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1000)) +
  ggtitle("map2: Max intensity per timepoint")

ggsave('map2_MaxInt_Tp.png')

ggplot(map2, aes(x=timepoint, y=StdDev, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 200)) +
  ggtitle("map2: Intensity StdDev per timepoint")

ggsave('map2_IntStdDev_Tp.png')

ggplot(sox2, aes(x=timepoint, y=Mean, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 400)) +
  ggtitle("sox2: Mean intensity per timepoint")

ggsave('sox2_MeanInt_Tp.png')

ggplot(sox2, aes(x=timepoint, y=Max, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1000)) +
  ggtitle("sox2: Max intensity per timepoint")

ggsave('sox2_MaxInt_Tp.png')

ggplot(sox2, aes(x=timepoint, y=StdDev, fill=timepoint)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 200)) +
  ggtitle("sox2: Intensity StdDev per timepoint")

ggsave('sox2_IntStdDev_Tp.png')

# Todo: plot Mean, StDev and Max per sets
# Todo: boxplot with dotplot
ggplot(map2, aes(x=set, y=Mean, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 400)) +
  ggtitle("map2: Mean intensity per set")

ggsave('map2_MeanInt_Set.png')

ggplot(map2, aes(x=set, y=Max, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1000)) +
  ggtitle("map2: Max intensity per set")

ggsave('map2_MaxInt_Set.png')

ggplot(map2, aes(x=set, y=StdDev, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 200)) +
  ggtitle("map2: Intensity StdDev per set")

ggsave('map2_IntStdDev_Set.png')

ggplot(sox2, aes(x=set, y=Mean, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 400)) +
  ggtitle("sox2: Mean intensity per set")

ggsave('sox2_MeanInt_Set.png')

ggplot(sox2, aes(x=set, y=Max, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1000)) +
  ggtitle("sox2: Max intensity per set ")

ggsave('sox2_MaxInt_Set.png')

ggplot(sox2, aes(x=set, y=StdDev, fill=timepoint)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 200)) +
  ggtitle("sox2: Intensity StdDev per set ")

ggsave('sox2_IntStdDev_Set.png')
# Todo: plot Mean and StDev per individual image


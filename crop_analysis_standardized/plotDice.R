library(plyr)
library(ggplot2)
library(tidyverse)

# setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/imageStats/")
setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids//TestFiles/standardized_crops/output_Dice/")
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
  ret$crop <- regmatches(basename(filename), regexpr('(?<=-\\d{3}-).+?(?=_Meas)', basename(filename), perl=TRUE))
  ret$channel <- regmatches(basename(filename), regexpr('(?<=norm-C)\\d(?=-Crop)', basename(filename), perl=TRUE))
  ret
}

# ============================================================================
# only processes shape results
file.list <- list.files(recursive=TRUE, pattern = ".*_Meas.csv", full.names = TRUE )

# llply needs plyr package
filename.table <- llply(file.list, read_table_filename)

# now rbind is combining them all into one list
filename.combine <- do.call("rbind", filename.table)

# reorders columns
filename.combine1 <- filename.combine[,c(1,5,6,7,8,9,10,11,2,3,4)]

filename.combine1$channelName[filename.combine1$channel == 2] <- 'MAP2'
filename.combine1$channelName[filename.combine1$channel == 3] <- 'SOX2'
filename.combine1$channelName[filename.combine1$channel == 4] <- 'SOX2'


ggplot(filename.combine1, aes(x=ID, y=Dice, fill=channelName)) +
  geom_bar(stat="identity") +
  ggtitle("Dice per stack") +
  theme_classic(base_size = 15) +
  scale_y_continuous(limits = c(0, 1)) +
  theme(axis.text.x = element_text(angle = 90))

ggsave('DicePerStack.png')

ggplot(filename.combine1, aes(x=timepoint, y=Dice, fill=channelName)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(limits = c(0, 1)) +
  ggtitle("Dice per timepoint and channel")

ggsave('DicePerTpCh.png')

ggplot(filename.combine1, aes(x=set, y=Dice, fill=set)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(limits = c(0, 1)) +
  ggtitle("Dice per stack and set")

ggsave('DicePerStackSet.png')

# ============================================================================
# filter channels and split into separate lists
split_dataset <- group_split(filename.combine1 %>% group_by(channelName))
map2 <- split_dataset[[1]]
sox2 <- split_dataset[[2]]

# plot mean per timepoint
# Todo: plot StDev and Max per timepoint
# Todo: boxplot with dotplot
ggplot(map2, aes(x=timepoint, y=Dice, fill=set)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(limits = c(0, 1)) +
  ggtitle("map2: Dice per timepoint")

ggsave('DicePerTp_map2.png')

ggplot(sox2, aes(x=timepoint, y=Dice, fill=set)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  scale_y_continuous(limits = c(0, 1)) +
  ggtitle("sox2: Dice per timepoint")

ggsave('DicePerTp_sox2.png')

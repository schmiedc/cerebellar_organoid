library(plyr)
library(ggplot2)
library(tidyverse)

# setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/imageStats/")
# setwd("/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/3rd_Run/")
setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/2022-11-17_5thRun/output/")
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
  ret$channel <- regmatches(basename(filename), regexpr('(?<=norm-).+?(?=-Crop)', basename(filename), perl=TRUE))
  ret$stack <- regmatches(basename(filename), regexpr('(?<=\\d-|\\D-)\\d{3}(?=-\\d)', basename(filename), perl=TRUE))
  ret$crop <- regmatches(basename(filename), regexpr('(?<=-\\d{3}-).+?(?=_Meas)', basename(filename), perl=TRUE))
  ret
}

# ============================================================================
# only processes shape results
file.list <- list.files(recursive=TRUE, pattern = ".*_Meas.csv", full.names = TRUE )

# llply needs plyr package
filename.table <- llply(file.list, read_table_filename)

# now rbind is combining them all into one list
filename.combine <- do.call("rbind", filename.table)

head(filename.combine)

# reorders columns
filename.combine1 <- filename.combine[,c(1,5,6,7,8,9,10,11,2,3,4)]
head(filename.combine1)

filename.combine1$channel[filename.combine1$channel == "C2"] <- "map2"
filename.combine1$channel[filename.combine1$channel == "C3"] <- "sox2"
filename.combine1$channel[filename.combine1$channel == "C4"] <- "sox2"

# filter channels and split into separate lists
split_dataset <- group_split(filename.combine1 %>% group_by(channel))
map2 <- split_dataset[[1]]
sox2 <- split_dataset[[2]]

ggplot(filename.combine1, aes(x=ID, y=Dice, fill=channel)) +
  geom_bar(stat="identity") +
  ggtitle("Dice per stack") +
  theme_classic(base_size = 15) +
  scale_y_continuous(limits = c(0, 1)) +
  theme(axis.text.x = element_text(angle = 90))

ggsave('DicePerStack.png')

ggplot(filename.combine1, aes(x=timepoint, y=Dice, fill=channel)) +
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


map2 %>% group_by(timepoint) %>% summarise(
  median = median(Dice),
  mean = mean(Dice)
)

sox2 %>% group_by(timepoint) %>% summarise(
  median = median(Dice),
  mean = mean(Dice)
)


# filter channels and split into separate lists
split_dataset_map2 <- group_split(map2 %>% group_by(timepoint))
map2_14 <- split_dataset_map2[[1]]
map2_21 <- split_dataset_map2[[2]]

map2_14 %>% filter(Dice < 0.45 & Dice > 0.43)
map2_21 %>% filter(Dice < 0.57 & Dice > 0.47)

# filter channels and split into separate lists
split_dataset_sox2 <- group_split(sox2 %>% group_by(timepoint))
sox2_14 <- split_dataset_sox2[[1]]
sox2_21 <- split_dataset_sox2[[2]]

sox2_14 %>% filter(Dice < 0.66 & Dice > 0.63)
sox2_21 %>% filter(Dice < 0.25 & Dice > 0.19)


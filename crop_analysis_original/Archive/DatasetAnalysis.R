library(ggplot2)
library(tidyverse)

setwd("/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/")
dataset <- read.csv('CleanCrops.csv', header = TRUE,row.names = 1, stringsAsFactors = FALSE )
dataset$timepoint <- as.character(dataset$timepoint)

count <- dataset %>% group_by(timepoint,treatment) %>% count()

colnames(count)[3] <- 'Count'

ggplot(count, aes(x=timepoint, y=Count, fill=treatment)) +
  geom_bar(position = "dodge", stat = "identity") +
  ggtitle("Count") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 70)) +
  theme_classic(base_size = 20)

ggsave('CountTimepoint.png')

countSet <- dataset %>% group_by(set, treatment) %>% count()

colnames(countSet)[3] <- 'Count'

ggplot(countSet, aes(x=set, y=Count, fill=treatment)) +
  geom_bar(position = "dodge", stat = "identity") +
  ggtitle("Count") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 70)) +
  theme_classic(base_size = 20)

ggsave('CountSet.png')


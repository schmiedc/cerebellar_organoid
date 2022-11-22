library(plyr)

setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/cleanCrops/")

# =============================================================================
# function for getting the metadata from filename
# =============================================================================
# function that adds metadata as a column
read_table_filename <- function(filename){
  ret <- data.frame(8)
  # extracts from filename the metadata and adds as column
  ret$date <- regmatches(basename(filename), regexpr('(?<=\\d-)\\d{8}(?=-14-|-21-)', basename(filename), perl=TRUE))
  ret$set <- regmatches(basename(filename), regexpr('(?<=Crop-)\\d(?=-\\d{8})', basename(filename), perl=TRUE))
  ret$timepoint <- regmatches(basename(filename), regexpr('(?<=\\d{8}-)14|21(?=-\\d)', basename(filename), perl=TRUE))
  ret$name <- regmatches(basename(filename), regexpr('(?<=-14-|-21-).+?(?=-\\d\\d\\d-\\d|-\\d\\D.tif)', basename(filename), perl=TRUE))
  ret$stack <- regmatches(basename(filename), regexpr('(?<=\\d-|\\D-)\\d{3}(?=-\\d)', basename(filename), perl=TRUE))
  ret$crop <- regmatches(basename(filename), regexpr('(?<=-\\d{3}-).+?(?=.tif)', basename(filename), perl=TRUE))
  ret
}

# ============================================================================
# only processes shape results
file.list <- list.files(recursive=TRUE, pattern = ".*.tif", full.names = TRUE )

# llply needs plyr package
filename.table <- llply(file.list, read_table_filename)

# now rbind is combining them all into one list
filename.combine <- do.call("rbind", filename.table)

filename.combine$X8 <- NULL
head(filename.combine)

write.csv2(filename.combine, 'clean_crops.csv')

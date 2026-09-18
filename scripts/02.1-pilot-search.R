# Script for pilot analysis for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

library(readr)
library(purrr)

# Initial search results: 8192

# read all files into one large data frame
fl <- list.files(path = "data/pilot/search", full.names = TRUE)
# import and combine search results
import_wos <- function(path) {
  o <- read_delim(path, delim = "\t", quote = "")
  o$VL <- as.character(o$VL)
  o$EP <- as.character(o$EP)
  o
}
d_import <- lapply(fl, import_wos)
d <- purrr::list_rbind(d_import)
nrow(d)
#> 8192
# matches total search results

# rename column names
a <- data.frame(
  authors = d$AU,
  title = d$TI,
  doi = d$DI,
  journal = d$SO,
  year = as.integer(d$PY)
)

# number of duplicates (by DOI matching)
dd <- which(duplicated(a$doi, incomparables = NA))
#> 2 duplicates
dt <- which(duplicated(a$title, incomparables = NA))
#> 2 (different) duplicates

# inspect duplicates
a[which(a$doi == a$doi[dd[[1]]]),]
a[which(a$doi == a$doi[dd[[2]]]),]
a[which(a$title == a$title[dt[[2]]]),]
a[which(a$title == a$title[dt[[2]]]),]
# 4 true duplicates

# perform a random sample of 200 records 
set.seed(4711)
samp <- sample(seq_len(nrow(a)), size = 200)
a_sample <- a[samp, ]

write.csv(a_sample, "data/pilot/sample.csv")

# Script for pilot analysis for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# this script cannot be run on other machines, 
# as it requires access to the downloaded article PDF, which
# cannot be shared because of licensing regulations

library(metacheck)
library(purrr)
source("scripts/functions.R")

# manually extracted items
# total time for extracting data from 200 articles: 175 min
m <- read.csv("data/pilot/manual.csv")
nrow(m)

# automatically extract articles
all <- list.files("data/pilot/all", full.names = TRUE)
# metacheck::convert(all, save_path = "data/pilot/imported", method = "grobid", api_url = "https://grobid.hti.ieis.tue.nl")
# needed approx. 12 minutes to run on my machine

au <- metacheck::read("data/pilot/imported")
avl <- lapply(au, extract_statement)
software <- lapply(au, extract_software)
# runtime both: 45s

automated <- merge(purrr::list_rbind(avl), purrr::list_rbind(software), by = "id", all = TRUE)
write.csv(automated, "data/pilot/automated.csv")

# run metacheck repo check
#rc <- metacheck::module_run(au, "repo_check")
# we need to remove the full text which is part of the metacheck object
rc$paper <- NULL
#saveRDS(rc, "data/pilot/repo_check.Rds")

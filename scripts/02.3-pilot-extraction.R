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
# total time for extracting data from 195 articles: 170 min
m <- read.csv("data/pilot/manual.csv")

nrow(m)

# automatically extract articles
all <- list.files("data/pilot/all", full.names = TRUE)
# metacheck::convert(all[1:119], save_path = "data/pilot/imported")
# needed approx. 12 minutes to run on my machine

au <- metacheck::read("data/pilot/imported")
avl <- lapply(au, flag_article)
software <- lapply(au, extract_software)
# runtime both: 45s

automated <- cbind(data.frame(id = list.files("data/pilot/all")), purrr::list_rbind(avl), purrr::list_rbind(software))
write.csv(automated, "data/pilot/automated.csv")


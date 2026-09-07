# Script for pilot analysis for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# this script cannot be run on other machines, 
# as it requires access to the downloaded article PDF, which
# cannot be shared because of licensing regulations

# import sample data
s <- read.csv("data/pilot/sample.csv")

# Items with DOI
sum(!is.na(s$doi))
#> 193

# create a list of DOIS fro Zotero import
paste(s$doi, collapse = " ")

# add to Zotero library via > Add via identified
# items added: 192
# total time: 5:47 min
# number of articles with text imported: 52

# using the Find Full Text function:
# additional number of found full texts: 
# 1 file added after <20min of processing, this does not seem worth it

# exporting PDF to folder with File > Export PDFs

# read available PDFs
z <- list.files("data/pilot/zotero")
length(z)
#> 53
# matches number in Zotero
# match against DOIs available

# percentage of studies retrieved by Zenodo:
53 / 200
#> 26.5%

match <- gsub('/', '', s$doi) %in% sub('\\.pdf$', '', z)
sum(match)
# match
a <- data.frame(
  doi = s$doi[!match],
  title = s$title[!match]
)

# time needed:

# first batch (needed some technical setup, e.g., setting the
# correct download directory, signin to publishers)
# 63 studies
# could not access: 3
# time: 18:20
# time per study:
60 * (18.33 / 63)
#> 17.5s per study

# second batch:
# 84 studies
# could not access: 2
# time 22:01
# time per study:
60 * (22 / 84)
#> 15.7s per study

length(list.files("data/pilot/studies"))
#> 142

# Zotero retrieved: 53, manually: 142, could not retrieve: 5 
# -> total: 200 (matches sample size)
# total time per study:
60 * ((22 + 18.33) / (63 + 84))
#> 16.5s per study

# create blank csv. file for manual extraction with all 195 studies with full text
#r <- list.files("data/pilot/all")
#data.frame(id = r) |> write.csv("ids.csv")

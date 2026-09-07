# Script for calculations for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# load packages
library(readr)
library(binom)

# expected sample size
i <- 10 # number of years
k <- 25 # number of journals 
n_per_ik <- 175 # number of articles per journal per year
drop <- 0.2 # assumed exclusion rate
N <- i * k * n_per_ik * (1-drop) # expected total sample size
N
#> 35000

# expected time for manual download
pa <- 0.25 # proportion of automatically retrieved studies
t <- 16.5 # time per manual retrieval (in s)
nr <- N * (1 - pa) # studies that need manual retrieval
(nr * t) / (60 * 60)
# 120 hours

# data sharing in Borg et al. (2020) for only original articles
# read data provided on GitHub 
# I use a local copy but due to unclear licensing for reproducibility
# purposes the data is not included in this public repository
# borg <- read.csv("data/prevdata/borg.csv")
borg <- read.csv("https://github.com/SciBorgo/Open-data-in-sports-science/raw/refs/heads/master/random-sample-400-data-extraction.csv")
# filter eligible studies
eli <- borg[borg$Eligble == 1,]
nrow(eli)
#> 299 (matches published numbers)
# exclude all reviews and meta-analyses
emp <- eli[is.na(eli$Meta_analysis) & is.na(eli$Systematic_narrative_scoping_review),]
nrow(emp)
#> 283
# number of articles sharing data
table(emp$Data_shared)
#> 5
# percentage of data sharing
table(emp$Data_shared) |> prop.table()
#> 0.0177
# number of articles sharing code
table(emp$Code_shared)
#> 0
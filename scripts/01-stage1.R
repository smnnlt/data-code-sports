# Script for calculations for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# load packages
library(readr)
library(binom)
library(purrr)
library(tidyr)

# expected time for manual download
N <- 55000
pa <- 0.25 # proportion of automatically retrieved studies
t <- 16.5 # time per manual retrieval (in s)
nr <- N * (1 - pa) # studies that need manual retrieval
(nr * t) / (60 * 60)
# 189 hours

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

# journals included in the article search
# export SCImago journal rank data from website

# read data for years 2017-2026
read_scimago <- function(year) {
  d <- read.csv2(paste0("data/scimago/raw/", year, ".csv"))
  data.frame(
    issn = d$Issn,
    title = d$Title,
    q = d$SJR.Quartile,
    year = year
  )
}
allyears <- lapply(2017:2025, read_scimago) |> list_rbind()

# quartile ranking as factor
allyears$q <- as.numeric(factor(allyears$q, levels = c("Q1", "Q2", "Q3", "Q4", labels = 1:4)))
# to wide format
ranking <- pivot_wider(
  allyears,
  id_cols = c(issn, title),
  names_from = year,
  values_from = q
)

# journals that were at least three years in Q1
sum(rowSums(ranking == 1, na.rm = TRUE) >= 3)
#> 36

# get list of journals
jlist <- ranking$title[rowSums(ranking == 1, na.rm = TRUE) >= 3] 
sort(jlist) |> paste(collapse = "; ")

# exclude the following:
# Exercise and Sport Sciences Reviews (only review articles)
# Exercise Immunology Review (only review articles)
# International Review of Sport and Exercise Psychology (only review articles)
# Qualitative Research in Sport, Exercise and Health (mainly qualitative work)
# Sport, Education and Society (mainly qualitative work)

# precision estimation for error rates (verification set)
# assuming an error rate of 1%
err <- binom.confint(0.01*500, 500, methods = "ac")
err$upper - err$lower # 95% confidence interval width
#> 0.0203

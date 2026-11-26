# Script for pilot analysis for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# import extraction results
m <- read.csv("data/pilot/manual.csv")
a <- read.csv("data/pilot/automated.csv")
rc <- readRDS("data/pilot/repo_check.Rds")
# check that rows are identical
all(m$id == a$id)

##------ Extraction agreement for detecting data availability statements

dst_match <- (m$data_statement != "none") == a$flag_statement_data
dst <- data.frame(id = m$id, manual = (m$data_statement != "none"), automated = a$flag_statement_data, atext = a$statement_data_text, match = dst_match)
dst[!dst$match,]
table(dst$manual, dst$automated)
# 169 TN, 29 TP, 1 FP (is an extraction error), 1 FN 

##------ Extraction agreement for detecting code availability statements
cst_match <- (!m$code_statement %in% c("", "none")) == a$flag_statement_code
cst <- data.frame(id = m$id, manual = (!m$code_statement %in% c("", "none")), automated = a$flag_statement_code, atext = a$statement_code_text, match = cst_match)
cst[!cst$match,]
table(cst$manual, cst$automated)
# 197 TN, 2 TP, 1 FP, 0 FN
# FP -> code is availability upon request, this is in the methods section (overlooked during the manual review)

##------ Extraction agreement for detecting repositories with data actually available
repo_match <- (m$data_available == TRUE & !is.na(m$data_available)) == (rc$summary_table$repo_n > 0)
repo <- data.frame(id = m$id, manual = m$data_available == TRUE & !is.na(m$data_available), automated = rc$summary_table$repo_n > 0, match = repo_match)
rrr <- repo[!repo$match,]
table(repo$manual, repo$automated)
# TN: 193, TP: 5, FP: 2 (one manual extraction error, one code repository flagged)
# so basically no problems

##-------- Extraction agreement for analysis software used
# get software columns
s_m <- m[,10:26]
s_a <- a[,9:25]
all(colnames(s_m) == colnames(s_a)) # order matches
# replace emtpy entries in manual data set with FALSE
s_m[is.na(s_m)] <- FALSE
# compare manual and automated extraction
comp <- s_m == s_a
# overall cross-table
table(comp)
#> FALSE: 45

# see which studies have a not matching entry
ff <- which(rowSums(!comp) >= 1)
ff
length(ff) # how many individual studies
#> 42
# find studies with mutiple mismatches
which(rowSums(!comp) > 1)
s_err <- cbind(a[,c("id", "software_text")], comp)
s_err[ff,]

# errors when not considering manual data extraction errors (n = 28):
# FP: 14 across 14 studies (12 were automatic flags for R)
# FN: 3 across 3 studies (2 when only using full texts not repos)

# see below for more details

# inspect errors:
# 10.1016+j.ptsp.2016.06.010: automated found Medcalc (manual overlook)
# 10.1016+j.ptsp.2018.08.008: automated found Matlab (manual overlook)
# 10.1016+j.ptsp.2019.06.013: automated found SPSS (manual overlook)
# 10.1016+j.ptsp.2022.01.006: manual found SPSS (automated overlook, section was not imported: GROBID issue)
# 10.1016+j.ptsp.2022.03.004: automated found Excel (manual overlook, although it is used for data storage, not analysis)
# 10.1080+00913847.2018.1418592: automated found Excel (manual overlook)
# 10.1080+00913847.2018.1430450: automated found Prism (manual overlook, but visualization software only)
# 10.1080+00913847.2025.2451606: manual found R (automated overlook: SENTENCE IMPORTED AS REF)
# 10.1080+02701367.2020.1726859: manual found R (automated overlook; could only be determined from study repository)
# 10.1080+02701367.2020.1756198: automated found Excel (manual overlook, although it is used for data entry, not analysis)
# 10.1080+02701367.2022.2026865: automated found R (detection error: incorrect reference R R)
# 10.1080+02701367.2024.2409932: automated found Excel (manual overlook)
# 10.1080+02701367.2025.2542816: automated found Excel (manual overlook)
# 10.1080+14763141.2016.1269187: automated found R (detection error: symbol in symbol list)
# 10.1080+14763141.2020.1743744: automated found R (manual overlook)
# 10.1080+14763141.2020.1788630: automated found R (detection error: symbol for radius)
# 10.1080+14763141.2021.1890198: automated found R (manual overlook)
# 10.1080+14763141.2021.1922742: automated found Python (manual overlook); automated found Excel (manual overlook)
# 10.1080+14763141.2022.2086169: automated found R (detection error: symbol in formula)
# 10.1080+14763141.2022.2126326: automated found Matlab (manual overlook)
# 10.1108+IJSMS-03-2026-0193: automated found R (detection error: symbol for currency)
# 10.1177+15270025221148997: automated found Stata (manual overlook)
# 10.1177+1747954117716790: automated found Excel (manual overlook)
# 10.1177+17479541221074992: automated found R (detection error: symbol in formula); automated found Excel (manual overlook)
# 10.1177+17479541221099638: automated found R (manual overlook)
# 10.1177+17479541231155108: automated found Excel (manual overlook)
# 10.1177+17479541231181616: automated found R (detection error: regex failure)
# 10.1177+17479541251317043: automated found Python (detection error: general reference to Python)
# 10.1177+17479541251319477: automated found R (manual overlook)
# 10.1177+17479541251342721: automated found R (detection error: meant the letter R)
# 10.1177+17479541251368751: automated found Excel (detection error: Excel topic not tool of the article)
# 10.1177+17479541251389942: automated found SAS (manual overlook)
# 10.1177+17479541251406508: automated found Excel (manual overlook)
# 10.1177+17479541251411829: automated found Excel (manual overlook)
# 10.1519+SSC.0000000000000719: automated found R (detection error: symbol in formula)
# 10.1519+SSC.0000000000000808: automated found R (detection error: symbol in formula)
# 10.2478+hukin-2019-0032: automated found Excel (manual overlook)
# 10.5114+jhk189425: automated found Matlab (manual overlook)
# 10.5114+jhk205466: automated found Matlab (manual overlook)
# 10.52082+jssm.2022.104: automated found R (detection error: symbol in formula)
# 10.52082+jssm.2025.626: automated found R (detection error: symbol in formula); automated found Excel (manual overlook)
# 10.52082+jssm.2026.691: automated found Excel (manual overlook, although it is used for random number generation)

# Inspection of data/code repositories
repos <- merge(rc$summary_table, rc$repo_metadata, by = "paper_id", all = FALSE)
repo_results <- data.frame(
  id = repos$paper_id,
  url = repos$repo_url,
  n_repos = repos$repo_n,
  checked = repos$repo_unchecked == 0,
  has_data = repos$files_data > 0,
  has_code = repos$files_code > 0,
  has_doi = !is.na(repos$doi),
  has_readme = repos$files_readme > 0,
  has_license = !is.na(repos$license)
)
repo_results
# compare against manual inspection
# 10.1080+02701367.2020.1726859: This is an incorrect repository linked in the article (a T&F placeholder), DOI not detected
# 10.1080+02701367.2024.2409932: all correct (although only one .R file for the sample sitze calculation could hardly be considered open code)
# 10.1080+14763141.2024.2372608: license not detected but available
# 10.1177+17479541221099638: all correct
# 10.1177+17479541251366906: all correct
# 10.1177+17479541251411829: the figshare description could count as a README, otherwise all correct
# 10.1177+17479541261475500: could not check: manually found code, data, license

# Script for pilot analysis for the Registered Report Stage 1:
# "Data and Code Availability in Sports Science: A Registered Report"
# Script written by Simon Nolte
# released under an MIT license

# import extraction results
m <- read.csv("data/pilot/manual.csv")
a <- read.csv("data/pilot/automated.csv")

##------ Extraction agreement for detecting data availability (statements)

# has any statement or sharing
m_flag <- (!is.na(m$data_available) | !is.na(m$code_available)) | (m$data_statement != "none" | m$code_statement != "")
# has any flag that indicates statement or availability
a_flag <- a$flag_statement | a$flag_repo
# find discrepancies
discr <- data.frame(manual = m_flag, automated = a_flag, match = (m_flag == a_flag))
which(!discr$match)
# cross-table
table(m_flag, a_flag)

# compare discrepancies
# 12: FP (private data repository -> flag)
# 21: FP (wrongly detected availability section)
# 62: FP (wrongly flagged "by request")
# 63: FP (wrongly flagged mentioning of "Mendeley")
# 88: FP (wrongly detected availability section)
# 107: FP (wrongly flagged robustness analysis "available on request")
# 110: TP (data and code available upon request)
# 124: TP (data and code available on repository (GitHub))
# 138: FP (wrongly flagges a mention of a public archive)
# 139: FP (wrongly detected availability section in footnote with availability of one material)
# 144: FP (wrongly flagged mentioning of the concept of "data availability")
# 149: TP (data availability statement: data not available, missed by manual extraction)
# 164: FP (wrongly detected availability section)

# overview of discrepancies:
# true positives (manual extraction error): 2
# false positives: 11
# false negatives: 0

# agreements:
# true positives: 29
# false negatives: 153


##-------- Extraction agreement for analysis software used
# get software columns
s_m <- m[,9:25]
s_a <- a[,5:21]
colnames(s_m) == colnames(s_a) # order matches
# replace emtpy entries in manual data set with FALSE
s_m[is.na(s_m)] <- FALSE
# compare manual and automated extraction
comp <- s_m == s_a
# overall cross-table
table(comp)
#> FALSE: 43

# see which studies have a not matching entry
ff <- which(rowSums(!comp) >= 1)
ff
length(ff) # how many individual studies
#> 40
# find studies with mutiple mismatches
which(rowSums(!comp) > 1)

# inspect errors:
# 1: automated found Medcalc (manual overlook)
# 4: automated found Matlab (manual overlook)
# 5: automated found SPSS (manual overlook)
# 13: manual found SPSS (automated overlook, section was not imported: GROBID issue)
# 14: automated found Excel (manual overlook, although it is used for data storage, not analysis)
# 27: automated found Excel (manual overlook)
# 29: automated found Prism (manual overlook, but visualization software only)
# 37: manual found R (automated overlook: SENTENCE IMPORTED AS REF)
# 45: manual found R (automated overlook; could only be determined from study repository)
# 46: automated found Excel (manual overlook)
# 50: automated found R (detection error: incorrect reference R R)
# 56: automated found Excel (manual overlook)
# 57: automated found Excel (manual overlook)
# 60: automated found R (detection error: symbol in symbol list)
# 68: automated found R (manual overlook)
# 69: automated found R (detection error: symbol for radius)
# 71: automated found R (manual overlook)
# 72: automated found Python (manual overlook); automated found Excel (manual overlook)
# 82: automated found R (detection error: symbol in formula)
# 85: automated found Matlab (manual overlook)
# 94: automated found R (detection error: symbol for currency)
# 107: automated found Stata (manual overlook)
# 113: automated found Excel (manual overlook)
# 123: automated found R (detection error: symbol in formula); automated found Excel (manual overlook)
# 124: automated found R (manual overlook)
# 129: automated found Excel (manual overlook)
# 131: automated found R (detection error: regex failure)
# 137: automated found Python (detection error: general reference to Python)
# 138: automated found R (manual overlook)
# 140: automated found R (detection error: meant the letter R)
# 144: automated found Excel (detection error: Excel topic not tool of the article)
# 146: automated found Excel (manual overlook)
# 161: automated found R (detection error: symbol in formula)
# 163: automated found R (detection error: symbol in formula)
# 166: automated found Excel (manual overlook)
# 176: automated found Matlab (manual overlook)
# 178: automated found Matlab (manual overlook)
# 180: automated found R (detection error: symbol in formula)
# 186: automated found R (detection error: symbol in formula); automated found Excel (manual overlook)
# 188: automated found Excel (manual overlook, although it is used for random number generation)

# overview of discrepancies:
# true positive (menual extraction error): 26 (across 25 studies)
# false negatives (automated overlooked software): 3 (across 3 studies)
# false positives (automated incorrectly attributed software): 14 (across 14 studies), of which
# -- 12 cases were FP for R
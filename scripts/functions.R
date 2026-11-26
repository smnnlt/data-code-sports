#' Flag data availability statements
#'
#' Detects whether an article contains a data or code availability statement
#' Availability statements are identified by searching for common phrases 
#' (e.g., "data availability", "code availability", or "available upon 
#' reasonable request").
#'
#' @param article An object with class "scivrs_paper", usually imported
#'   by the metacheck package
#'
#' @return A data frame with one row and five columns:
#' \describe{
#'   \item{id}{The paper id}
#'   \item{flag_statement_data}{`TRUE` if the article contains a data
#'   availability statement}
#'   \item{flag_statement_code}{`TRUE` if the article contains a code
#'   availability statement}
#'   \item{statement_data_text}{A string with the sentence that triggered the 
#'    data availability statment flag. Multiple sentences are separated by " // ".}
#'   \item{statement_data_code}{A string with the sentence that triggered the 
#'    code availability statment flag. Multiple sentences are separated by " // ".}
#' }
#'
extract_statement <- function(article) {
  if (is.null(article$section)) article <- article[[1]] # get list item if needed
  # get paper id
  id <- article$paper_id
  # search for strings that indicate data availability section
  d_st <- sfind(
    article,
    c("^\\W*data\\s+(?:and\\s+\\w+\\s+)?availability",
      "^\\W*availability\\s+of\\s+(?:the\\s+)?data",
      "\\bdata(?:sets?)?\\b.{0,100}?\\b(?:on|upon|by)\\s+(?:reasonable\\s+)?request",
      "\\bdata(?:sets?)?\\b.{0,100}?\\bavailable\\s+(?:from|by)\\s+(?:the\\s+)?(?:corresponding\\s+)?authors?",
      "\\bdata(?:sets?)?\\b.{0,100}?\\bavailable\\s+(?:at|in|on|via)\\s+(?:the\\s+|an?\\s+)?(?:\\w+\\s+)?(?:repository|osf|zenodo|github|figshare|https?://)"
    ),
    search_header = TRUE,
    perl = TRUE
  )
  # search for strings that indicate code availability section
  c_st <- sfind(
    article, 
    c("code availability", 
      "\\bcodes?\\b(?:\\s+[^.\\s]+){0,10}?\\s+(on|by|upon)\\s+(reasonable\\s+)?request\\b", 
      "\\bcodes?\\b(?:\\s+[^.\\s]+){0,10}?\\s+available\\b", 
      "\\bcodes?\\b(?:\\s+[^.\\s]+){0,10}?\\s+available\\s+from\\s+(?:the\\s+)?(?:corresponding\\s+|first\\s+|senior\\s+)?author"
    ),
    search_header = TRUE,
    perl = TRUE
  )
  data.frame(
    id = id,
    flag_statement_data = d_st$detected,
    flag_statement_code = c_st$detected,
    statement_data_text = d_st$text,
    statement_code_text = c_st$text
  )
}

#' Detect statistical software mentioned in an article
#'
#' Searches an article for mentions of commonly used statistical software and
#' programming languages. Detection is based on regular expressions and common
#' alternative names where appropriate (e.g., "Statistical Package for the
#' Social Sciences" for SPSS or "RStudio" for R).
#'
#' @param article An object with class "scivrs_paper", usually imported
#'   by the metacheck package
#'
#' @return A data frame with one row containing logical columns indicating
#'   whether each software package was detected. The returned columns are:
#'   `spss`, `stata`, `jamovi`, `jasp`, `r`, `python`, `prism`, `excel`,
#'   `sas`, `lisrel`, `matlab`, `statistica`, `winbugs`, `bioestat`,
#'   `stan`, `pspp`, and `medcalc`.
#'
extract_software <- function(article) {
  if (is.null(article$section)) article <- article[[1]] # get list item if needed
  # get paper id
  id <- article$paper_id
  # search for software mentions
  spss <- sfind(article, c("\\bspss", "statistical package for the social sciences", "\\bpasw", "\\bamos"))
  stata <- sfind(article, "\\bstata")
  jamovi <- sfind(article, "\\bjamovi")
  jasp <- sfind(article, "\\bjasp")
  r1 <- sfind(article, c("(?<!-)\\bR(?=\\s(?!\\s*=))", "(?:in|software)\\s+R\\b"), ignore.case = FALSE, perl = TRUE)
  r2 <- sfind(article, c("a language and environment for statistical computing", "rstudio", "\\br language"))
  python <- sfind(article, c("python", "scipy"))
  prism <- sfind(article, c("graph pad", "\\bprism\\b"))
  excel <- sfind(article, "excel\\b")
  sas <- sfind(article, "\\bsas\\b")
  lisrel <- sfind(article, "lisrel")
  matlab <- sfind(article, c("matlab", "mathworks"))
  statistica <- sfind(article, "\\bstatistica\\b")
  winbugs <- sfind(article, "winbugs")
  bioestat <- sfind(article, "bioestat")
  stan <- sfind(article, "\\bstan\\b")
  pspp <- sfind(article, "\\bpspp")
  medcalc <- sfind(article, "medcalc")
  # get text sections
  tx <- c(spss$text, stata$text, jamovi$text, jasp$text, r1$text, r2$text, python$text, prism$text, excel$text, sas$text,
    lisrel$text, matlab$text, statistica$text, winbugs$text, bioestat$text, stan$text, pspp$text, medcalc$text)
  tx_string <-  paste(tx[!is.na(tx)], collapse = " // ")
  if(tx_string == "") tx_string <- NA
  data.frame(
    id = id,
    spss = spss$detected, stata = stata$detected, jamovi = jamovi$detected, jasp = jasp$detected,
    r = any(r1$detected, r2$detected), python = python$detected, prism = prism$detected, excel = excel$detected,
    sas = sas$detected, lisrel = lisrel$detected, matlab = matlab$detected, statistica = statistica$detected,
    winbugs = winbugs$detected, bioestat = bioestat$detected, stan = stan$detected, pspp = pspp$detected,
    medcalc = medcalc$detected,
    software_text = tx_string
  )
}
#' Helper function to find matches using metacheck::text_search()
#'
#' Searches an article text via metacheck::text_search() and returns 
#' if any matches were found
#'
#' @param article An object with class "scivrs_paper", usually imported
#'   by the metacheck package
#' @param string Regular expression pattern passed to `pattern` in 
#' metacheck::text_search()
#' @param ... Additional arguments passed to metacheck::text_search()
#'
#' @return TRUE or FALSE, whether a match was found. 
sfind <- function(article, string, ...) {
  t <- metacheck::text_search(paper = article, pattern = string, ...)
  if (nrow(t) == 0) {
    detected = FALSE
    text = NA
  } else if (nrow(t) == 1) {
    detected = TRUE
    text = t$text
  } else if (nrow(t) > 1) {
    detected = TRUE
    text = paste(t$text, collapse = " // ")
  }
  detected <- nrow(t) >= 1
  data.frame(
    detected = detected,
    text = text
  )
}

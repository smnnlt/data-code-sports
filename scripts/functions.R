#' Flag data availability statements and repository mention
#'
#' Detects whether an article contains a data or code availability statement
#' and whether it mentions a data repository. Availability statements are
#' identified either through a dedicated availability section (identified by the grobid import) or by searching
#' for common phrases (e.g., "data availability", "code availability", or
#' "available upon reasonable request"). Repository mentions are detected by
#' searching for references to common repositories such as OSF, Zenodo,
#' GitHub, Figshare, Dryad, Dataverse, and others.
#'
#' @param article An object with class "scivrs_paper", usually imported
#'   by the metacheck package
#'
#' @return A data frame with one row and two logical columns:
#' \describe{
#'   \item{flag_statement}{`TRUE` if the article contains a data/code
#'   availability statement or a dedicated availability section.}
#'   \item{flag_repo}{`TRUE` if the article mentions a supported data
#'   repository.}
#' }
#'
flag_article <- function(article) {
  # search for availability section in grobid import
  if (is.null(article$section)) article <- article[[1]] # get list item if needed
  sec <- any(article$section$section_type == "availability")
  # search for strings that indicate availability section
  st <- sfind(
    article, 
    c("data availability", "code availability", 
    "(on|by|upon)\\s+(reasonable\\s+)?request", 
    "datasets?\\s+(?:is|are)?\\s*(?:not\\s+)?(?:publicly\\s+)?available", 
    "available\\s+from\\s+(?:the\\s+)?(?:corresponding\\s+)?author"
  ), 
    search_header = TRUE
  )
  # search for strings that match data/code repository
  repo <- sfind(
    article,
    c("repositor", "archive", "\\bosf\\b", "osf\\.io",
    "open science framework", "researchbox", "zenodo", "github", 
    "figshare", "datadryad", "kaggle", "mendeley", "ukbiobank", 
    "ukdataservice", "dataverse", "clinicalstudydatarequest", 
    "ourworldindata")
  )
  data.frame(
    flag_statement = any(c(sec, st)),
    flag_repo = repo
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
  data.frame(
    spss = sfind(article, c("\\bspss", "statistical package for the social sciences", "\\bpasw", "\\bamos")),
    stata = sfind(article, "\\bstata"),
    jamovi = sfind(article, "\\bjamovi"),
    jasp = sfind(article, "\\bjasp"),
    r = any(
          sfind(article, c("(?<!-)\\bR(?=\\s(?!\\s*=))", "(?:in|software)\\s+R\\b"), ignore.case = FALSE, perl = TRUE), 
          sfind(article, c("a language and environment for statistical computing", "rstudio", "\\br language"))
    ),
    python = sfind(article, c("python", "scipy")),
    prism = sfind(article, c("graph pad", "\\bprism\\b")),
    excel = sfind(article, "excel\\b"),
    sas = sfind(article, "\\bsas\\b"),
    lisrel = sfind(article, "lisrel"),
    matlab = sfind(article, c("matlab", "mathworks")),
    statistica = sfind(article, "\\bstatistica\\b"),
    winbugs = sfind(article, "winbugs"),
    bioestat = sfind(article, "bioestat"),
    stan = sfind(article, "\\bstan\\b"),
    pspp = sfind(article, "\\bpspp"),
    medcalc = sfind(article, "medcalc")
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
  nrow(t) >= 1
}
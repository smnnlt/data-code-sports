# Compare Elsevier XML download vs. PDF->Grobid path

library(metacheck)
source("scripts/functions.R")

# select OA publications from Elsevier sport science journals that 
# will not be part of the final sample (each n = 5).
# the selection of articles is non-random to include only original articles 
# across different publication years. Included journals:
# Journal of Exercise Science and Fitness
# Science & Sports
# Sports Medicine and Health Science
# Journal of Sport and Health Science

# Selected DOIs
jesf <- c("10.1016/j.jesf.2026.200533", "10.1016/j.jesf.2026.200548", "10.1016/j.jesf.2026.200550", "10.1016/j.jesf.2020.03.001", "10.1016/j.jesf.2020.03.003")
sis <- c("10.1016/j.scispo.2026.08.010", "10.1016/j.scispo.2026.01.011", "10.1016/j.scispo.2021.12.010", "10.1016/j.scispo.2025.09.001", "10.1016/j.scispo.2025.09.002")
smhs <- c("10.1016/j.smhs.2025.08.002", "10.1016/j.smhs.2025.08.001", "10.1016/j.smhs.2025.03.003", "10.1016/j.smhs.2020.08.002", "10.1016/j.smhs.2020.08.004")
jshs <- c("10.1016/j.jshs.2025.101111", "10.1016/j.jshs.2025.101082", "10.1016/j.jshs.2026.101131", "10.1016/j.jshs.2020.06.005", "10.1016/j.jshs.2018.08.006")

# PDFs manually downloaded in data/elseviertest/pdf
# Elsevier XML downloaded via API in data/elseviertest/xml
# Elsevier XML converted to TEI XML in data/elseviertest/xml_tei via scripts/elsevier2tei.py

# convert PDFs with Grobid
metacheck::convert(
  list.files("data/elseviertest/pdf", full.names = TRUE), 
  save_path = "data/elseviertest/grobid", 
  method = "grobid", 
  api_url = "https://grobid.hti.ieis.tue.nl"
)

# read articles
pdf <- metacheck::read("data/elseviertest/grobid")
xml <- metacheck::read("data/elseviertest/xml_tei")

# compare statement detection
st_pdf <- lapply(pdf, extract_statement) |> purrr::list_rbind()
st_xml <- lapply(xml, extract_statement) |> purrr::list_rbind()
st_pdf == st_xml
# identical

# compare software detection
sft_pdf <- lapply(pdf, extract_software) |> purrr::list_rbind()
sft_xml <- lapply(xml, extract_software) |> purrr::list_rbind() 
sft_pdf == sft_xml
# one mismatch (SAS for #14, 10.1016+j.scispo.2026.01.011)
# this is a false positive by the Grobid import
# in two additional cases the same software packages were identified using the same 
# sentences, but software_text shows a mismatch because the Elsevier->XML workflow preserves
# special characters (here ≥ and ≤), while the PDF->Grobid workflow deletes them.

inspect_repos <- function(articles) {
  rc <- metacheck::module_run(pdf, "repo_check")
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
}

mc_pdf <- inspect_repos(pdf)
mc_xml <- inspect_repos(xml)
mc_pdf == mc_xml
# all identical
# Data

This folder contains the data used for the analyses in this project.

## Directory structure

  - `pilot/automated.csv`: Data extracted automatically with `metacheck`.
  - `pilot/manual.csv`: Manually extracted pilot data.
  - `pilot/sample.csv`: Random sample selected from the pilot search results.
  - `pilot/search/`: Raw pilot search-result exports.

## Data dictionary

### `pilot/automated.csv`

| Column | Description |
| --- | --- |
| `""` | Row identifier. |
| `id` | Filename-based identifier for the article full text (DOI without '/', or, if DOI is unavailable, first author name and year). |
| `flag_statement` | Automated indicator that an availability statement or section was detected. |
| `flag_repo` | Automated indicator that a data or code repository was mentioned. |
| `spss`, `stata`, `jamovi`, `jasp`, `r`, `python`, `prism`, `excel`, `sas`, `lisrel`, `matlab`, `statistica`, `winbugs`, `bioestat`, `stan`, `pspp`, `medcalc` | Automated indicators for whether the named statistical software or programming language was detected in the article. |

### `pilot/manual.csv`

| Column | Description |
| --- | --- |
| `id` | Filename-based identifier for the article full text (DOI without '/', or, if DOI is unavailable, first author name and year). |
| `exclude` | Manual exclusion indicator. |
| `data_statement` | Result of the manual assessment of the data availability statement. |
| `data_available` | Manual indicator of whether data are available. |
| `data_link` | Link to the available data. |
| `code_statement` | Categorical result of the manual assessment of the code availability statement. |
| `code_available` | Manual indicator of whether code is available. |
| `code_link` | Link to the available code. |
| `spss`, `stata`, `jamovi`, `jasp`, `r`, `python`, `prism`, `excel`, `sas`, `lisrel`, `matlab`, `statistica`, `winbugs`, `bioestat`, `stan`, `pspp`, `medcalc` | Indicators for whether the named statistical software or programming language is used in the article. |
| `other` | Other software identified during manual extraction. |

### `pilot/sample.csv`

| Column | Description |
| --- | --- |
| `""` | Row identifier. |
| `authors` | Author names. |
| `title` | Article title. |
| `doi` | Digital Object Identifier of the article. |
| `journal` | Journal title. |
| `year` | Publication year. |

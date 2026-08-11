# 04_build_catalogue.R
# Generate data/catalogue.csv automatically from PNG filenames in pages/.
#
# Expected filename format:
#   {species}_{year}.png          e.g. skogsgrasfjaril_1965.png
#   {species}_{year1}-{year2}.png e.g. skogsgrasfjaril_1965-1968.png
#
# Multi-year filenames are treated as single summary entries with
# year = "1965-1968" (character). See docs/decisions.md for rationale.
#
# Usage:
#   source("R/04_build_catalogue.R")
#   build_catalogue()

library(dplyr)
library(readr)

#' Build catalogue.csv from PNG filenames in pages/
#'
#' @param pages_dir  Directory containing PNG map images (default: "pages")
#' @param out_path   Output path for catalogue CSV (default: "data/catalogue.csv")
#' @param overwrite  If TRUE, overwrite existing catalogue (default: FALSE)
#' @return Data frame with columns: filename, species, year
build_catalogue <- function(pages_dir = "pages",
                            out_path  = "data/catalogue.csv",
                            overwrite = FALSE) {

  if (file.exists(out_path) && !overwrite) {
    stop(sprintf(
      "%s already exists. Set overwrite = TRUE to replace it.", out_path
    ))
  }

  files <- list.files(pages_dir, pattern = "\\.png$", full.names = FALSE)

  if (length(files) == 0) {
    stop(sprintf("No PNG files found in %s/", pages_dir))
  }

  # Validate filenames — warn about any that don't match expected pattern
  expected <- grepl("^.+_\\d{4}(-\\d{4})?\\.png$", files)
  if (any(!expected)) {
    warning(sprintf(
      "The following files don't match the expected naming pattern and will be skipped:\n%s",
      paste(files[!expected], collapse = "\n")
    ))
  }

  catalogue <- data.frame(filename = files[expected]) |>
    mutate(
      species = sub("_(\\d{4}(-\\d{4})?)\\.png$", "", filename),
      year    = sub("^.+_(\\d{4}(-\\d{4})?)\\.png$", "\\1", filename)
    ) |>
    select(filename, species, year) |>
    arrange(species, year)

  write_csv(catalogue, out_path)

  message(sprintf(
    "Catalogue written to %s — %d entries (%d species, %d files).",
    out_path,
    nrow(catalogue),
    n_distinct(catalogue$species),
    length(files[expected])
  ))

  invisible(catalogue)
}

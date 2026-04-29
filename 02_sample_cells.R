# 02_sample_cells.R
# For each map page with known corner pixel coordinates, sample pixel
# intensity at every grid cell centroid and classify as present/absent.

library(dplyr)
library(readr)
source("R/utils.R")
source("R/03_build_grid.R")  # for GRID_COLS, GRID_ROWS

#' Process a single map page
#'
#' @param png_path     Path to the PNG image
#' @param corners      Data frame with 4 rows: corner (tl/tr/bl/br), px, py
#' @param threshold    Darkness threshold for presence (0–1, default 0.15)
#' @param sample_radius Pixel radius for cell sampling window
#' @return Data frame: col, row, present, darkness
process_page <- function(png_path,
                         corners,
                         threshold     = 0.15,
                         sample_radius = 8) {

  # Corner pixel coords
  pixel_pts <- corners |>
    arrange(match(corner, c("tl", "tr", "bl", "br"))) |>
    select(px, py)

  # Corresponding grid coords (0-based, col then row)
  grid_pts <- data.frame(
    gx = c(0, GRID_COLS - 1, 0,            GRID_COLS - 1),
    gy = c(0, 0,             GRID_ROWS - 1, GRID_ROWS - 1)
  )

  affine <- fit_affine(pixel_pts, grid_pts)
  mat    <- read_greyscale(png_path)

  # Build cell centroid grid (0-based indices + 0.5 for centroid)
  cells <- expand.grid(
    col_i = seq(0, GRID_COLS - 1),
    row_i = seq(0, GRID_ROWS - 1)
  ) |>
    mutate(
      col = LETTERS[col_i + 1],
      row = row_i + 1
    )

  # Predict pixel location of each cell centroid
  pixel_centroids <- predict_grid(affine,
                                  px = cells$col_i + 0.5,
                                  py = cells$row_i + 0.5)

  cells |>
    mutate(
      px       = pixel_centroids$gx,  # NOTE: predict_grid returns grid→pixel
      py       = pixel_centroids$gy,  # inverse is needed — see note below
      darkness = mapply(sample_window,
                        cx     = px,
                        cy     = py,
                        MoreArgs = list(mat = mat, radius = sample_radius)),
      present  = darkness > threshold
    ) |>
    select(col, row, darkness, present)
}

# NOTE: fit_affine() fits pixel→grid. For sampling we need grid→pixel, which
# requires the inverse transform. TODO: implement inverse_affine() in utils.R.

#' Run cell sampling for all map pages in the catalogue
#'
#' @param catalogue_path Path to data/catalogue.csv
#' @param corners_path   Path to data/corners.csv
#' @param pages_dir      Directory containing PNG page exports
#' @param out_dir        Output directory for per-species CSVs
#' @param threshold      Darkness threshold (tune on a test page first)
run_pipeline <- function(catalogue_path = "data/catalogue.csv",
                         corners_path   = "data/corners.csv",
                         pages_dir      = "pages",
                         out_dir        = "data/output",
                         threshold      = 0.15) {

  catalogue <- read_csv(catalogue_path, show_col_types = FALSE) |>
    filter(type == "map")

  corners <- read_csv(corners_path, show_col_types = FALSE)

  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

  results <- list()

  for (i in seq_len(nrow(catalogue))) {
    row  <- catalogue[i, ]
    page <- sprintf("%03d", row$page)
    message(sprintf("Processing page %s (%s %s)...", page, row$species, row$year))

    page_corners <- corners |> filter(page == as.integer(page))

    if (nrow(page_corners) != 4) {
      warning(sprintf("Page %s: expected 4 corners, found %d — skipping.",
                      page, nrow(page_corners)))
      next
    }

    png_path <- file.path(pages_dir, sprintf("page_%s.png", page))
    if (!file.exists(png_path)) {
      warning(sprintf("Page %s: PNG not found — skipping.", page))
      next
    }

    cells <- process_page(png_path, page_corners, threshold = threshold)
    cells$species <- row$species
    cells$year    <- row$year
    results[[i]]  <- cells
  }

  combined <- bind_rows(results)
  write_csv(combined, file.path(out_dir, "presence_absence_raw.csv"))
  message("Done. Output written to ", file.path(out_dir, "presence_absence_raw.csv"))
  invisible(combined)
}

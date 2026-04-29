# 03_build_grid.R
# Define the grid coordinate system and attach real-world coordinates
# to sampled presence/absence data.
#
# To adapt for a different map, update the constants in the
# GRID CONFIGURATION section below.

library(sf)
library(dplyr)
library(readr)

# ── GRID CONFIGURATION ────────────────────────────────────────────────────────
# Update these values for a different survey grid.

GRID_COLS    <- 16          # Number of columns (A–P)
GRID_ROWS    <- 23          # Number of rows (1–23)
CELL_SIZE    <- 200         # Cell size in metres

# Top-left corner of cell A1 in UTM coordinates
ORIGIN_E     <- 445000      # Easting  (metres)
ORIGIN_N     <- 6235000     # Northing (metres)

# CRS of the source coordinates (UTM zone 33N)
CRS_SOURCE   <- 32633       # EPSG code
# CRS for output (SWEREF99TM — standard for modern Swedish data)
CRS_OUTPUT   <- 3006        # EPSG code

# ── GRID CONSTRUCTION ─────────────────────────────────────────────────────────

#' Build a complete grid of cell centroids with real-world coordinates
#'
#' @return sf object with columns: col, row, easting, northing, geometry (SWEREF99TM)
build_grid <- function() {
  expand.grid(
    col_i = seq(0, GRID_COLS - 1),
    row_i = seq(0, GRID_ROWS - 1)
  ) |>
    mutate(
      col      = LETTERS[col_i + 1],
      row      = row_i + 1,
      # Centroid = origin + (index * cell_size) + half cell
      easting  = ORIGIN_E + col_i * CELL_SIZE + CELL_SIZE / 2,
      northing = ORIGIN_N - row_i * CELL_SIZE - CELL_SIZE / 2
    ) |>
    select(col, row, easting, northing) |>
    st_as_sf(coords = c("easting", "northing"), crs = CRS_SOURCE) |>
    st_transform(CRS_OUTPUT)
}

#' Attach georeferenced coordinates to a presence/absence data frame
#'
#' @param presence_df Data frame from run_pipeline() with col, row, species, year, present
#' @return sf object with all original columns plus geometry in SWEREF99TM
attach_coordinates <- function(presence_df) {
  grid <- build_grid()

  presence_df |>
    left_join(grid, by = c("col", "row")) |>
    st_as_sf()
}

#' Write the final georeferenced dataset
#'
#' @param presence_df Data frame from run_pipeline()
#' @param out_path    Output path (GeoPackage recommended)
write_georeferenced <- function(presence_df,
                                out_path = "data/output/presence_absence.gpkg") {
  geo <- attach_coordinates(presence_df)
  st_write(geo, out_path, delete_dsn = TRUE)
  message("Georeferenced dataset written to ", out_path)
  invisible(geo)
}

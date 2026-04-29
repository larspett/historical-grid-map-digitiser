# utils.R
# Shared helper functions used across the pipeline.

library(magick)

#' Read a PNG page as a greyscale integer matrix
#'
#' @param path Path to PNG file
#' @return Matrix of pixel values 0–255 (0 = black, 255 = white)
read_greyscale <- function(path) {
  img <- image_read(path) |>
    image_convert(colorspace = "Gray")

  # Extract pixel data as numeric matrix
  arr <- as.integer(image_data(img, channels = "gray"))
  info <- image_info(img)
  matrix(arr, nrow = info$height, ncol = info$width, byrow = TRUE)
}

#' Sample mean pixel darkness in a square window around a point
#'
#' @param mat    Greyscale pixel matrix (0=black, 255=white)
#' @param cx     Centre x (column)
#' @param cy     Centre y (row)
#' @param radius Half-width of sampling window in pixels
#' @return Mean darkness (0=white, 1=black) — inverted for intuitive interpretation
sample_window <- function(mat, cx, cy, radius = 8) {
  rows <- max(1, round(cy) - radius) : min(nrow(mat), round(cy) + radius)
  cols <- max(1, round(cx) - radius) : min(ncol(mat), round(cx) + radius)
  mean_intensity <- mean(mat[rows, cols], na.rm = TRUE)
  # Invert: high value = dark = presence
  1 - (mean_intensity / 255)
}

#' Fit a 2D affine transform from pixel coords to grid coords
#'
#' Uses four corner GCPs (ground control points).
#'
#' @param pixel_pts Data frame with columns px, py (pixel coordinates)
#' @param grid_pts  Data frame with columns gx, gy (grid coordinates, 0-based)
#' @return List of two lm models: one for gx, one for gy
fit_affine <- function(pixel_pts, grid_pts) {
  df <- cbind(pixel_pts, grid_pts)
  list(
    fit_gx = lm(gx ~ px + py, data = df),
    fit_gy = lm(gy ~ px + py, data = df)
  )
}

#' Apply affine transform to predict grid coordinates from pixel coordinates
#'
#' @param affine  Output of fit_affine()
#' @param px      Vector of pixel x coordinates
#' @param py      Vector of pixel y coordinates
#' @return Data frame with columns gx, gy
predict_grid <- function(affine, px, py) {
  nd <- data.frame(px = px, py = py)
  data.frame(
    gx = predict(affine$fit_gx, newdata = nd),
    gy = predict(affine$fit_gy, newdata = nd)
  )
}

# 01_extract_pages.R
# Extract individual pages from a PDF as PNG images.
# Output goes to pages/ (gitignored).

library(pdftools)

#' Extract all pages from a PDF as PNG files
#'
#' @param pdf_path Path to the source PDF
#' @param out_dir  Output directory (default: "pages")
#' @param dpi      Resolution in DPI (default: 400 — recommended for cell detection)
extract_pages <- function(pdf_path,
                          out_dir = "pages",
                          dpi     = 400) {

  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

  n_pages <- pdf_info(pdf_path)$pages
  message(sprintf("Extracting %d pages at %d dpi...", n_pages, dpi))

  filenames <- file.path(out_dir,
                         sprintf("page_%03d.png", seq_len(n_pages)))

  pdf_convert(
    pdf      = pdf_path,
    format   = "png",
    dpi      = dpi,
    filenames = filenames,
    verbose  = FALSE
  )

  message(sprintf("Done. Pages written to %s/", out_dir))
  invisible(filenames)
}

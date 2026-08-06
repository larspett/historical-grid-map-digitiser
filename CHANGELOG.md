# Changelog

All notable changes to this project are documented here.
Format: `vMAJOR.MINOR.PATCH — YYYY-MM-DD`

- **MAJOR:** Breaking change or complete redesign
- **MINOR:** New feature or significant improvement
- **PATCH:** Bug fix, data update, or minor tweak

---

## v0.1.0 — 2026-08-06

### Added
- Initial repository scaffold: `R/`, `shiny/`, `data/`, `docs/`, `pages/`
- `R/01_extract_pages.R` — PDF page extraction via `pdftools`
- `R/02_sample_cells.R` — per-cell pixel intensity sampling and presence/absence classification
- `R/03_build_grid.R` — grid coordinate system definition and georeferenced output
- `R/utils.R` — shared helpers: greyscale image reading, window sampling, affine transform fitting
- `shiny/corner_clicker/app.R` — general-purpose app for clicking 4 grid corners per scan page
- `data/catalogue.csv` — template page catalogue (filename, species, year per map)
- `data/corners.csv` — corner pixel coordinate store (output of Shiny app)
- `docs/pipeline.md` — pipeline overview and coordinate system documentation
- `docs/decisions.md` — methodological and technical design decisions
- `CHANGELOG.md` — this file
- `renv.lock` — reproducible R package environment (pdftools, magick, sf, dplyr, shiny, bslib, readr)
- `.gitignore` — excludes raw PNGs, PDFs, renv cache

### Established
- Grid coordinate system: origin 6235000m N, 445000m E (UTM 33N); 200×200m cells;
  16 columns (A–P), 23 rows (1–23); output SWEREF99TM (EPSG:3006)
- Source material: 231 map pages extracted from a 313-page scanned PDF covering
  butterfly distribution surveys in a Swedish parish, 1964–1970
- File naming convention: `{species_swedish}_{year}.png` — lowercase, no spaces, no Swedish characters
- Large files (source PDFs, PNG exports) gitignored; source PDF held separately

### Known issues
- Affine transform in `02_sample_cells.R` is fitted in the pixel→grid direction;
  the inverse (grid→pixel) needed for centroid sampling is not yet implemented
- Presence/absence threshold not yet tuned — requires testing on real pages

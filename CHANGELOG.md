# Changelog

All notable changes to this project are documented here.
Format: `vMAJOR.MINOR.PATCH — YYYY-MM-DD`

- **MAJOR:** Breaking change or complete redesign
- **MINOR:** New feature or significant improvement
- **PATCH:** Bug fix, data update, or minor tweak

---

## v0.1.2 — 2026-08-11

### Added
- `R/04_build_catalogue.R` — generates `data/catalogue.csv` automatically from
  PNG filenames; handles both single-year (`_1965.png`) and multi-year
  (`_1965-1968.png`) filename formats; warns on unexpected filename patterns

### Bug fixes
- Fixed corner clicker app: page identifiers throughout now use filenames
  (`skogsgrasfjaril_1965.png`) rather than zero-padded integers derived from
  `page_001.png` style names — images were not loading after files were renamed
  to the `{species}_{year}.png` convention (reported and diagnosed by Ana,
  Windows testing)
- Updated `corners.csv` page column from integer to filename string accordingly
- Auto-advance and skip button logic updated to match

---

## v0.1.1 — 2026-08-11

### Added
- Updated `README.md` with full installation and usage instructions pitched at
  RStudio-familiar users; RStudio-based clone method listed first as recommended
  approach for both Mac and Windows
- `docs/DECISIONS.md` entry for bleed-through handling via threshold tuning
- `docs/DECISIONS.md` entry for multi-year map filename convention
  (`{species}_{year1}-{year2}.png` treated as single summary entry)
- Catalogue generation code updated to handle both single-year and year-range
  filenames; `year` column is character type to accommodate both

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

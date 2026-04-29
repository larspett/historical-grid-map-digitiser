# historical-grid-map-digitiser

A general-purpose R pipeline for digitising historical presence/absence data from hand-drawn gridded maps into georeferenced datasets.

## Background

Developed to process a collection of butterfly distribution maps from a Swedish parish covering 1964–1970, drawn on a UTM-aligned grid over a Swedish topographic base map. The pipeline is intentionally species- and taxon-agnostic and can be applied to any similar gridded survey map.

## Pipeline overview

```
[Once]        Extract pages from PDF           → pages/*.png
[Once]        Catalogue pages manually          → data/catalogue.csv
[Once]        Define grid coordinate system     → R/03_build_grid.R
[Per scan]    Click 4 grid corners (Shiny app)  → data/corners.csv
[Batch]       Sample cell intensities           → R/02_sample_cells.R
[Batch]       Attach real-world coordinates     → R/03_build_grid.R
[Output]      Tidy presence/absence dataset     → data/output/
```

## Grid coordinate system

This pipeline was developed for a survey grid with the following properties:

- Grid cells are 200 × 200m (1/5 of a UTM kilometre square)
- Columns A–P (west → east), rows 1–23 (north → south)
- Grid origin (top-left corner of A1): **6235000m N, 445000m E**
- UTM zone 33N (EPSG:32633), output transformed to SWEREF99TM (EPSG:3006)

To adapt for a different map, update the constants in `R/03_build_grid.R`.

## Repository structure

```
R/
  01_extract_pages.R     # Extract PNG pages from PDF
  02_sample_cells.R      # Sample pixel intensity per grid cell
  03_build_grid.R        # Build georeferenced cell centroid dataset
  utils.R                # Shared helper functions
shiny/
  corner_clicker/
    app.R                # Minimal app: load image, click 4 corners, save CSV
data/
  catalogue.csv          # Page index: page, type, species, year
  corners.csv            # Corner pixel coordinates per page (output of Shiny app)
  output/                # Gitignored — tidy CSVs per species/year
docs/
  pipeline.md            # Detailed pipeline notes
pages/                   # Gitignored — PNG exports from PDF
```

## Requirements

R packages are managed with `renv`. To restore the environment:

```r
renv::restore()
```

Key packages: `pdftools`, `magick`, `sf`, `dplyr`, `shiny`, `readr`

## Usage

### 1. Extract pages

```r
source("R/01_extract_pages.R")
extract_pages("path/to/your.pdf", dpi = 400)
```

### 2. Catalogue pages

Edit `data/catalogue.csv` manually — one row per page:

```
page,type,species,year
001,text,NA,NA
002,map,skogsgrasfjaril,1965
```

### 3. Click grid corners

```r
shiny::runApp("shiny/corner_clicker")
```

For each map page, load the image and click the 4 grid corners in order:
top-left (A1), top-right (P1), bottom-left (A23), bottom-right (P23).
Coordinates are appended to `data/corners.csv`.

### 4. Sample cells and build output

```r
source("R/02_sample_cells.R")
source("R/03_build_grid.R")
run_pipeline("data/catalogue.csv", "data/corners.csv")
```

## Output format

```
species, year, col, row, easting, northing, x_sweref, y_sweref, present
skogsgrasfjaril, 1965, E, 5, 445800, 6234100, ..., ..., 1
```

## Adapting to other maps

The only map-specific inputs are:

1. Grid origin coordinates and cell size → `R/03_build_grid.R`
2. Number of columns and rows → `R/03_build_grid.R`
3. UTM zone → `R/03_build_grid.R`

Everything else (page extraction, corner clicking, intensity sampling) is fully general.

## License

MIT

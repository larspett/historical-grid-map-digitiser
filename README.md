# historical-grid-map-digitiser

A pipeline for digitising historical presence/absence data from hand-drawn gridded maps into georeferenced datasets. Developed for a collection of butterfly distribution maps from a Swedish parish (1964–1970), but designed to work with any similarly structured gridded survey map.

---

## What this does

The pipeline takes scanned map images where a surveyor has filled in grid squares to indicate species presence, and converts them into a tidy, georeferenced dataset with real-world coordinates for each grid cell.

```
Scanned map images  →  Click 4 corners  →  Automated cell sampling  →  Georeferenced CSV
```

---

## Requirements

- **R** (version 4.1 or later) — [download here](https://cran.r-project.org)
- **RStudio** — [download here](https://posit.co/download/rstudio-desktop/)
- **Git** — [download here](https://git-scm.com/downloads)
  - macOS: can also be installed by running `xcode-select --install` in Terminal
  - Windows: the installer includes Git Bash — use that for any command-line steps

---

## Installation

### 1. Get the code — via RStudio (recommended, works on Mac and Windows)

In RStudio:

1. **File → New Project → Version Control → Git**
2. Paste this URL as the Repository URL:
   `https://github.com/larspett/historical-grid-map-digitiser.git`
3. Choose a folder to save it in
4. Click **Create Project**

RStudio will download the project and open it automatically — no Terminal needed.

You should see the message:
```
Project 'historical-grid-map-digitiser' loaded. [renv x.x.x]
```

### 1. Get the code — via Terminal (alternative)

On macOS (Terminal) or Windows (Git Bash):

```bash
git clone https://github.com/larspett/historical-grid-map-digitiser.git
```

Then open RStudio and go to **File → Open Project**, navigate to the downloaded folder, and open `historical-grid-map-digitiser.Rproj`.

### 2. Install packages

This project uses `renv` to manage R packages, ensuring everyone uses the same package versions. In the RStudio console, run:

```r
renv::restore()
```

This installs all required packages automatically. It may take a few minutes the first time.

---

## Preparing your maps

### Step 1 — Export map images from PDF

If your maps are in a PDF:

1. Open the PDF in Acrobat (or similar)
2. Delete any non-map pages (text, notes, etc.)
3. Export remaining pages as individual PNG files at **300 dpi**
4. Place the PNG files in the `pages/` folder inside the project

### Step 2 — Name the files

Rename each PNG file to describe its contents:

```
{species}_{year}.png
```

Use lowercase, no spaces, and replace Swedish characters (å→a, ä→a, ö→o):

```
skogsgrasfjaril_1965.png
nasselfjaril_1966.png
amiralfjäril_1967.png
```

### Step 3 — Generate the catalogue

Once all files are named, run this in the RStudio console to create `data/catalogue.csv` automatically:

```r
library(dplyr)
library(readr)

files <- list.files("pages", pattern = "\\.png$")

catalogue <- data.frame(filename = files) |>
  mutate(
    species = sub("_\\d{4}\\.png$", "", filename),
    year    = as.integer(sub(".*_(\\d{4})\\.png$", "\\1", filename))
  )

write_csv(catalogue, "data/catalogue.csv")
```

---

## Running the pipeline

### Step 1 — Click grid corners (once per map)

Launch the corner-clicking app from the RStudio console:

```r
shiny::runApp("shiny/corner_clicker")
```

A window opens showing your map images. For each map:

1. Select the page from the dropdown
2. Click the **4 grid corners** in order: top-left, top-right, bottom-left, bottom-right
3. The app saves the coordinates automatically and advances to the next page

Corner coordinates are saved to `data/corners.csv` as you go — you can stop and resume at any time.

### Step 2 — Sample cells and build output

Once corners are recorded for all maps, run:

```r
source("R/02_sample_cells.R")
source("R/03_build_grid.R")
run_pipeline()
```

This samples the pixel darkness at each grid cell centroid, classifies cells as present or absent, attaches real-world coordinates, and writes the output to `data/output/`.

---

## Output

The final dataset is a GeoPackage (`data/output/presence_absence.gpkg`) and CSV (`data/output/presence_absence_raw.csv`) with one row per grid cell per map:

| Column | Description |
|--------|-------------|
| `species` | Species name (from filename) |
| `year` | Survey year (from filename) |
| `col` | Grid column (A–P) |
| `row` | Grid row (1–23) |
| `present` | TRUE/FALSE |
| `darkness` | Raw pixel darkness value (0–1) |
| `geometry` | Cell centroid in SWEREF99TM (EPSG:3006) |

---

## Adapting to a different map

The coordinate system is defined in `R/03_build_grid.R`. Update these values for a different survey grid:

```r
GRID_COLS  <- 16        # number of columns
GRID_ROWS  <- 23        # number of rows
CELL_SIZE  <- 200       # cell size in metres
ORIGIN_E   <- 445000    # easting of top-left corner of cell A1 (UTM metres)
ORIGIN_N   <- 6235000   # northing of top-left corner of cell A1 (UTM metres)
CRS_SOURCE <- 32633     # EPSG code for source CRS (UTM zone 33N)
CRS_OUTPUT <- 3006      # EPSG code for output CRS (SWEREF99TM)
```

Everything else — page extraction, corner clicking, intensity sampling — works without modification.

---

## Troubleshooting

**`renv::restore()` fails** — make sure you opened the project via the `.Rproj` file, not by navigating to the folder in RStudio's file pane.

**Shiny app doesn't show images** — check that PNG files are in the `pages/` folder and named correctly.

**PDF extraction crashes** — export pages individually from Acrobat rather than converting the full PDF in R.

---

## Documentation

- `docs/pipeline.md` — detailed pipeline notes and coordinate system derivation
- `docs/decisions.md` — rationale behind key technical decisions
- `CHANGELOG.md` — version history

## License

MIT

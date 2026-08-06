# Design & Technical Decisions

This file logs significant decisions made during development, with rationale.
Update it whenever a non-obvious choice is made.

## Format
**YYYY-MM-DD — Decision title**
- **What:** Brief description of the decision
- **Why:** Rationale, alternatives considered
- **Impact:** What this affects

---

## 2026-08-06 — Coordinate system: UTM zone 33N, output SWEREF99TM

- **What:** All internal computation uses UTM zone 33N (EPSG:32633); output is
  reprojected to SWEREF99TM (EPSG:3006).
- **Why:** The survey grid was drawn on Fältkarta 3D Kristianstad NO (1:50,000)
  whose printed kilometre grid is UTM zone 33N. Using the same CRS makes coordinate
  derivation purely arithmetic. SWEREF99TM is the current Swedish national standard
  for downstream compatibility with modern datasets.
- **Impact:** All cell centroids are computed in UTM 33N and transformed once at
  output. Any adaptation to a different map sheet should verify the UTM zone first.

---

## 2026-08-06 — Cell size derived as 1/5 UTM kilometre square = 200×200m

- **What:** Each grid cell is 200×200m.
- **Why:** The survey grid subdivides each UTM kilometre square into a 5×5 subgrid,
  confirmed by visual alignment of grid lines to the printed kilometre grid on the
  topographic base map. The grid origin (top-left of A1) was identified as exactly
  6235000m N, 445000m E. The full grid extent (445000–448200m E, 6230400–6235000m N)
  does not fill the complete UTM extent, consistent with a parish boundary.
- **Impact:** Cell centroid coordinates are fully deterministic:
  `easting = 445000 + (col_index - 1) * 200 + 100`
  `northing = 6235000 - (row - 1) * 200 - 100`

---

## 2026-08-06 — No manual georeferencing; algebraic coordinate derivation

- **What:** Cell real-world coordinates are computed arithmetically from the known
  grid origin and cell size, with no GCP-based georeferencing.
- **Why:** Because the survey grid aligns exactly to the printed UTM kilometre grid,
  and the origin is precisely known, every centroid can be derived without error-prone
  manual georeferencing. The 4-corner pixel clicks in the Shiny app serve only to
  establish the pixel→grid affine transform for intensity sampling — not for
  real-world coordinate assignment.
- **Impact:** Eliminates the main source of manual effort and geometric error in
  comparable pipelines. Real-world coordinates are independent of scan alignment quality.

---

## 2026-08-06 — PDF extraction via Acrobat rather than pdftools batch conversion

- **What:** Non-map pages were deleted and maps exported as individual single-page
  PDFs using Acrobat, then converted to PNG in R. The full 313-page PDF was not
  batch-converted in R.
- **Why:** pdftools segfaulted on the full PDF at both 400 and 300 dpi, likely due
  to memory pressure from poppler. Single-page PDFs were stable. Acrobat also allowed
  visual identification and removal of non-map pages (text, notes), reducing 313
  pages to 231 map pages cleanly.
- **Impact:** Page extraction is a one-time manual operation. The source PDF is held
  separately and gitignored. The 231-page reduced set is the working dataset.

---

## 2026-08-06 — Scan resolution set to 300 dpi

- **What:** PNG exports from Acrobat and pdftools use 300 dpi.
- **Why:** 400 dpi caused segfaults when processing the full PDF in pdftools. At
  300 dpi a 200m cell occupies approximately 35×35 pixels at the map scale used,
  providing a comfortable sampling window for intensity detection. Single-page PDFs
  were stable at 300 dpi.
- **Impact:** If cell detection proves unreliable, re-exporting at higher dpi from
  Acrobat is straightforward since the source PDFs are retained.

---

## 2026-08-06 — File naming convention: {species_swedish}_{year}.png

- **What:** Map PNGs are named using the Swedish common name as it appears in the
  original map, lowercased with Swedish characters replaced (å→a, ä→a, ö→o),
  plus the survey year. Example: `skogsgrasfjaril_1965.png`.
- **Why:** Swedish common names are the natural identifier for this dataset and
  match the original maps directly. Scientific name matching is deferred to a
  post-processing join against the vernacular lookup table from the SeBMS Explorer
  project, avoiding the need to resolve 1960s nomenclature at the renaming stage.
  Removing Swedish characters avoids filesystem and scripting edge cases.
- **Impact:** The `catalogue.csv` is generated automatically from filenames.
  Some names in the maps are obsolete; the filename preserves the original name
  and the lookup table handles mapping to current accepted scientific names.

---

## 2026-08-06 — Corner-clicker Shiny app scope limited to 4-point pixel capture

- **What:** The Shiny app clicks only 4 grid corner pixel coordinates per scan.
  It does not handle cell-by-cell presence/absence clicking.
- **Why:** Cell-by-cell clicking would be too bespoke and labour-intensive for
  200+ maps. Automated intensity sampling is more scalable and sufficiently reliable
  given the consistent solid black ink fills. The 4-corner click is the minimal
  manual step needed to establish the pixel→grid transform; everything else is
  computed automatically.
- **Impact:** The app is genuinely general-purpose — nothing in it is specific to
  butterflies or this dataset. It can be reused for any similarly structured gridded
  map scan.

---

## TODO — Affine transform inversion in 02_sample_cells.R

- **What:** `fit_affine()` in `utils.R` fits a pixel→grid transform. Cell centroid
  sampling requires the inverse (grid→pixel). This is not yet implemented.
- **Why deferred:** The coordinate system and pipeline architecture were established
  first; the inversion is straightforward but requires testing on a real page.
- **Impact:** `02_sample_cells.R` will not produce correct results until this is
  resolved. Implement and validate before batch processing.

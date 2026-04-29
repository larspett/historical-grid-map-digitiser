# Pipeline notes

## Coordinate system

The survey grid maps onto UTM zone 33N (EPSG:32633) as follows:

| Grid element | Value |
|---|---|
| Origin (top-left of A1) | 445000m E, 6235000m N |
| Cell size | 200 × 200m |
| Columns | A–P (west → east, 16 total) |
| Rows | 1–23 (north → south) |
| Full E extent | 445000 – 448200m |
| Full N extent | 6230400 – 6235000m |

Cell centroid coordinates:
```
easting  = 445000 + (col_index - 1) * 200 + 100
northing = 6235000 - (row - 1) * 200 - 100
```

Output is reprojected to SWEREF99TM (EPSG:3006).

## Threshold tuning

The presence/absence threshold (default 0.15 on a 0–1 darkness scale) should
be validated on a representative sample of pages before batch processing.

Recommended approach:
1. Run `process_page()` on 3–5 pages covering different species and years
2. Plot the distribution of `darkness` values — expect a clear bimodal distribution
3. Set threshold at the valley between the two modes
4. A k-means with k=2 on the darkness values can automate this if needed

## Scan quality notes

- All maps are from the same notebook scanned as a single PDF
- Filled cells are consistent solid black ink squares
- Grid lines are drawn in blue/teal ink — distinct from the black presence markers
- The underlying topographic base map adds colour noise — the sampling window
  radius should be kept small enough to avoid bleeding into adjacent cells

## Known issues / TODO

- `02_sample_cells.R`: the affine transform currently fits pixel→grid direction;
  the inverse (grid→pixel) needed for centroid sampling is noted as TODO
- Threshold should be exposed as a tunable parameter with a diagnostic plot function

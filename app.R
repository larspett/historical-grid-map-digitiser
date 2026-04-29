# shiny/corner_clicker/app.R
# General-purpose tool for clicking 4 corner points on a scanned grid map.
# Appends pixel coordinates to data/corners.csv.
#
# Usage:
#   shiny::runApp("shiny/corner_clicker")
#
# Click corners in this order:
#   1. Top-left     (A1  — northwest corner of grid)
#   2. Top-right    (P1  — northeast corner of grid)
#   3. Bottom-left  (A23 — southwest corner of grid)
#   4. Bottom-right (P23 — southeast corner of grid)

library(shiny)
library(bslib)
library(magick)
library(readr)
library(dplyr)

CORNERS_PATH <- "data/corners.csv"
PAGES_DIR    <- "pages"
CORNER_LABELS <- c("tl", "tr", "bl", "br")
CORNER_NAMES  <- c("Top-left (A1)", "Top-right (P1)",
                   "Bottom-left (A23)", "Bottom-right (P23)")

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- page_sidebar(
  title = "Grid Corner Clicker",
  theme = bs_theme(bootswatch = "flatly"),

  sidebar = sidebar(
    width = 280,

    selectInput("page_select", "Page",
                choices  = NULL,
                selected = NULL),

    hr(),

    h6("Progress"),
    uiOutput("corner_status"),

    hr(),

    actionButton("undo_btn",  "Undo last click",  class = "btn-warning  w-100 mb-2"),
    actionButton("clear_btn", "Clear this page",  class = "btn-danger   w-100 mb-2"),
    actionButton("skip_btn",  "Skip page",        class = "btn-secondary w-100 mb-4"),

    hr(),
    h6("Already recorded"),
    uiOutput("recorded_summary")
  ),

  card(
    card_header("Click the 4 grid corners in order"),
    plotOutput("map_plot",
               click  = "map_click",
               height = "75vh")
  )
)

# ── SERVER ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Reactive state
  rv <- reactiveValues(
    clicks   = data.frame(corner = character(),
                          px     = numeric(),
                          py     = numeric()),
    img      = NULL,
    img_dims = NULL
  )

  # ── Page list ---------------------------------------------------------------

  observe({
    pngs <- list.files(PAGES_DIR, pattern = "\\.png$", full.names = FALSE)
    pages <- sub("page_0*(\\d+)\\.png", "\\1", pngs)

    # Mark already-completed pages
    if (file.exists(CORNERS_PATH)) {
      done <- read_csv(CORNERS_PATH, show_col_types = FALSE) |>
        group_by(page) |>
        summarise(n = n()) |>
        filter(n == 4) |>
        pull(page)
      labels <- ifelse(pages %in% as.character(done),
                       paste0(pages, " ✓"),
                       pages)
    } else {
      labels <- pages
    }

    updateSelectInput(session, "page_select",
                      choices  = setNames(pages, labels),
                      selected = pages[1])
  })

  # ── Load image when page changes --------------------------------------------

  observeEvent(input$page_select, {
    req(input$page_select)
    path <- file.path(PAGES_DIR,
                      sprintf("page_%03d.png", as.integer(input$page_select)))
    if (!file.exists(path)) return()

    img      <- image_read(path)
    info     <- image_info(img)
    rv$img      <- img
    rv$img_dims <- list(w = info$width, h = info$height)
    rv$clicks   <- data.frame(corner = character(),
                              px     = numeric(),
                              py     = numeric())
  })

  # ── Render image ------------------------------------------------------------

  output$map_plot <- renderPlot({
    req(rv$img)
    arr <- as.raster(rv$img)
    par(mar = c(0, 0, 0, 0))
    plot(arr)

    # Overlay clicks so far
    if (nrow(rv$clicks) > 0) {
      cols_clicked <- c("red", "blue", "green", "purple")
      for (i in seq_len(nrow(rv$clicks))) {
        # Convert pixel coords back to plot coords
        # plot() maps image so x: 0..1, y: 0..1 (top-left origin)
        x_plot <- rv$clicks$px[i] / rv$img_dims$w
        y_plot <- 1 - rv$clicks$py[i] / rv$img_dims$h
        points(x_plot, y_plot,
               pch = 19, cex = 2,
               col = cols_clicked[i])
        text(x_plot, y_plot,
             labels = CORNER_LABELS[i],
             pos    = 4,
             col    = cols_clicked[i],
             cex    = 1.2)
      }
    }
  }, res = 96)

  # ── Handle clicks ----------------------------------------------------------

  observeEvent(input$map_click, {
    req(rv$img_dims)
    n_so_far <- nrow(rv$clicks)
    if (n_so_far >= 4) return()

    # Convert plot click (0..1 range) to pixel coordinates
    px <- input$map_click$x * rv$img_dims$w
    py <- (1 - input$map_click$y) * rv$img_dims$h

    new_row <- data.frame(
      corner = CORNER_LABELS[n_so_far + 1],
      px     = round(px),
      py     = round(py)
    )
    rv$clicks <- bind_rows(rv$clicks, new_row)

    # Auto-save when all 4 corners are clicked
    if (nrow(rv$clicks) == 4) {
      save_corners()
    }
  })

  # ── Save corners -----------------------------------------------------------

  save_corners <- function() {
    page_num <- as.integer(input$page_select)
    new_rows <- rv$clicks |>
      mutate(page = page_num) |>
      select(page, corner, px, py)

    if (file.exists(CORNERS_PATH)) {
      existing <- read_csv(CORNERS_PATH, show_col_types = FALSE) |>
        filter(page != page_num)        # overwrite if re-doing a page
      combined <- bind_rows(existing, new_rows)
    } else {
      combined <- new_rows
    }

    write_csv(combined, CORNERS_PATH)
    showNotification(
      sprintf("Page %03d corners saved.", page_num),
      type     = "message",
      duration = 3
    )

    # Auto-advance to next unfinished page
    Sys.sleep(0.5)
    all_pages <- as.integer(isolate(
      sub("page_0*(\\d+)\\.png", "\\1",
          list.files(PAGES_DIR, pattern = "\\.png$"))
    ))
    done <- read_csv(CORNERS_PATH, show_col_types = FALSE) |>
      group_by(page) |> summarise(n = n()) |> filter(n == 4) |> pull(page)
    remaining <- setdiff(all_pages, done)
    if (length(remaining) > 0) {
      updateSelectInput(session, "page_select",
                        selected = as.character(min(remaining)))
    }
  }

  # ── Undo / clear / skip ---------------------------------------------------

  observeEvent(input$undo_btn, {
    if (nrow(rv$clicks) > 0)
      rv$clicks <- rv$clicks[-nrow(rv$clicks), ]
  })

  observeEvent(input$clear_btn, {
    rv$clicks <- data.frame(corner = character(),
                            px     = numeric(),
                            py     = numeric())
  })

  observeEvent(input$skip_btn, {
    all_pages <- as.integer(
      sub("page_0*(\\d+)\\.png", "\\1",
          list.files(PAGES_DIR, pattern = "\\.png$"))
    )
    current  <- as.integer(input$page_select)
    remaining <- all_pages[all_pages > current]
    if (length(remaining) > 0)
      updateSelectInput(session, "page_select",
                        selected = as.character(min(remaining)))
  })

  # ── Status UI -------------------------------------------------------------

  output$corner_status <- renderUI({
    labels <- CORNER_NAMES
    cols   <- c("danger", "warning", "warning", "warning")
    done   <- nrow(rv$clicks)

    items <- lapply(seq_along(labels), function(i) {
      if (i <= done) {
        tags$p(style = "color: green; margin: 2px 0;",
               paste0("✓ ", labels[i]))
      } else if (i == done + 1) {
        tags$p(style = "color: #e67e22; font-weight: bold; margin: 2px 0;",
               paste0("→ ", labels[i]))
      } else {
        tags$p(style = "color: #aaa; margin: 2px 0;",
               paste0("  ", labels[i]))
      }
    })
    tagList(items)
  })

  output$recorded_summary <- renderUI({
    if (!file.exists(CORNERS_PATH)) return(p("None yet."))
    n_done <- read_csv(CORNERS_PATH, show_col_types = FALSE) |>
      group_by(page) |> summarise(n = n()) |> filter(n == 4) |> nrow()
    p(sprintf("%d page(s) complete", n_done))
  })
}

shinyApp(ui, server)

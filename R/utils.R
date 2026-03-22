# Null-coalescing operator (not exported)
`%||%` = function(a, b) if (!is.null(a)) a else b


# Resolve collection: interactive picker or error
.resolve_collection = function(collection, stac_url) {
  if (!is.null(collection)) return(collection)

  cols = list_collections(stac_url = stac_url)
  if (is.null(cols) || nrow(cols) == 0) {
    stop("No collections found and no collection specified.", call. = FALSE)
  }

  if (interactive()) {
    choices = paste0(cols$id, "  (", cols$title, ")")
    selection = utils::menu(choices, title = "Select a collection:")
    if (selection == 0) stop("No collection selected.", call. = FALSE)
    return(cols$id[selection])
  }

  stop(
    "Argument 'collection' is required in non-interactive mode.\n",
    "Available collections:\n",
    paste0("  - ", cols$id, collapse = "\n"),
    call. = FALSE
  )
}


# Guess file extension from asset href or content type
.guess_extension = function(asset) {
  href = asset$href %||% ""
  type = asset$type %||% ""

  # Try content type first
  if (grepl("netcdf", type, ignore.case = TRUE)) return(".nc")
  if (grepl("geotiff|tiff", type, ignore.case = TRUE)) return(".tif")
  if (grepl("jpeg2000|jp2", type, ignore.case = TRUE)) return(".jp2")
  if (grepl("json", type, ignore.case = TRUE)) return(".json")
  if (grepl("xml", type, ignore.case = TRUE)) return(".xml")

  # Fall back to URL extension
  ext = tools::file_ext(sub("\\?.*$", "", href))
  if (nchar(ext) > 0) return(paste0(".", ext))

  # Default
  ".dat"
}

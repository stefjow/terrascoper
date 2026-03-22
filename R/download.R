#' Download data from Terrascope
#'
#' Searches the Terrascope STAC API and downloads matching files.
#' Existing files are skipped automatically.
#'
#' @param bbox Numeric vector of length 4: `c(xmin, ymin, xmax, ymax)`.
#' @param start_date Date or character coercible to Date.
#' @param end_date Date or character coercible to Date.
#' @param output_dir Character. Directory to save downloaded files.
#' @param collection Character. STAC collection ID, or `NULL` (default).
#'   If `NULL`, presents an interactive picker in interactive sessions
#'   or stops with an error in non-interactive mode.
#' @param asset_key Character or `NULL`. Specific asset key to download.
#'   If `NULL` (default), downloads the first available asset.
#' @param file_prefix Character. Prefix for downloaded file names.
#'   Default: `"terrascope"`.
#' @param credentials List with `user` and `pass`, or `NULL` for no auth.
#'   Default uses [terrascope_credentials()].
#' @param stac_url Character. STAC API endpoint.
#'   Default: `"https://stac.terrascope.be/"`.
#' @return A data.table with columns `filepath`, `filename`, `filesize_mb`,
#'   `item_id`, and `datetime`. Invisibly returns `NULL` if no items found.
#' @export
download_terrascope = function(bbox,
                               start_date,
                               end_date,
                               output_dir,
                               collection = NULL,
                               asset_key = NULL,
                               file_prefix = "terrascope",
                               credentials = terrascope_credentials(),
                               stac_url = "https://stac.terrascope.be/") {

  collection = .resolve_collection(collection, stac_url)

  # Ensure output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Search for items
  items = search_terrascope(
    bbox = bbox,
    start_date = start_date,
    end_date = end_date,
    collection = collection,
    stac_url = stac_url
  )

  n_items = if (!is.null(items) && "features" %in% names(items)) {
    length(items$features)
  } else {
    0L
  }

  if (n_items == 0) {
    warning("No items found. Nothing to download.")
    return(invisible(NULL))
  }

  # Download each item
  results = vector("list", n_items)

  for (i in seq_len(n_items)) {
    item = items$features[[i]]
    item_id = item$id
    item_date = as.Date(item$properties$datetime)

    message("[", i, "/", n_items, "] ", item_id)

    # Resolve which asset to download
    key = .resolve_asset_key(item, asset_key)
    if (is.null(key)) {
      warning("  [SKIP] No downloadable asset found")
      next
    }

    filepath = .download_one(
      item = item,
      asset_key = key,
      output_dir = output_dir,
      file_prefix = file_prefix,
      credentials = credentials
    )

    if (!is.null(filepath)) {
      results[[i]] = data.table::data.table(
        filepath = filepath,
        filename = basename(filepath),
        filesize_mb = round(file.size(filepath) / 1024^2, 2),
        item_id = item_id,
        datetime = as.character(item_date)
      )
    }
  }

  result_dt = data.table::rbindlist(results, fill = TRUE)

  message("\nDownload complete: ", nrow(result_dt), "/", n_items, " files")
  result_dt
}


# Resolve asset key: use specified key, or pick first available
.resolve_asset_key = function(item, asset_key) {
  if (!is.null(asset_key)) {
    if (asset_key %in% names(item$assets)) return(asset_key)
    return(NULL)
  }

  # Filter out metadata-only assets
  keys = names(item$assets)
  for (key in keys) {
    type = item$assets[[key]]$type %||% ""
    if (!grepl("xml|json|text", type, ignore.case = TRUE)) {
      return(key)
    }
  }

  # Fall back to first asset
  if (length(keys) > 0) return(keys[1])
  NULL
}


# Internal: download a single asset
.download_one = function(item, asset_key, output_dir, file_prefix, credentials) {
  item_id = item$id
  item_date = as.Date(item$properties$datetime)
  asset = item$assets[[asset_key]]
  url = asset$href

  ext = .guess_extension(asset)
  filename = sprintf("%s_%s_%s%s",
                     file_prefix,
                     format(item_date, "%Y%m%d"),
                     substr(item_id, 1, 8),
                     ext)
  filepath = file.path(output_dir, filename)

  # Skip existing files
  if (file.exists(filepath)) {
    message("  [SKIP] ", filename)
    return(filepath)
  }

  message("  [DOWN] ", filename)

  result = tryCatch({
    if (!is.null(credentials)) {
      response = httr::GET(
        url,
        httr::authenticate(credentials$user, credentials$pass),
        httr::write_disk(filepath, overwrite = TRUE),
        httr::progress()
      )
    } else {
      response = httr::GET(
        url,
        httr::write_disk(filepath, overwrite = TRUE),
        httr::progress()
      )
    }

    if (httr::status_code(response) == 200) {
      message("  [OK]   ", filename)
      return(filepath)
    } else {
      warning("  [FAIL] HTTP ", httr::status_code(response))
      if (file.exists(filepath)) file.remove(filepath)
      return(NULL)
    }
  }, error = function(e) {
    warning("  [ERROR] ", e$message)
    if (file.exists(filepath)) file.remove(filepath)
    return(NULL)
  })

  result
}

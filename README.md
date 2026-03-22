# terrascoper

R package for downloading Earth observation data from the [Terrascope STAC API](https://stac.terrascope.be/).

Supports all Terrascope collections (Sentinel-5P, Sentinel-2, Sentinel-1, PROBA-V, etc.) with automatic file type detection (NetCDF, GeoTIFF, etc.).

## Installation

```r
remotes::install_github("stefjow/terrascoper")
```

## Setup

Set your Terrascope credentials as environment variables (register at <https://terrascope.be/>):

```
TERRASCOPE_USER=your_username
TERRASCOPE_PASS=your_password
```

Add these to your `~/.Renviron` file, or set them in your session with `Sys.setenv()`.

## Usage

```r
library(terrascoper)

# Browse all collections
list_collections()

# Filter collections by pattern
list_collections("S5P")
list_collections("sentinel-2")

# Search (interactive collection picker if collection is omitted)
items = search_terrascope(
  bbox = c(16.0, 48.0, 16.7, 48.4),
  start_date = "2026-01-01",
  end_date = "2026-03-01",
  collection = "terrascope-s5p-l3-no2-td-v2"
)

# Download
result = download_terrascope(
  bbox = c(16.0, 48.0, 16.7, 48.4),
  start_date = "2026-01-01",
  end_date = "2026-03-01",
  output_dir = "data/raw",
  collection = "terrascope-s5p-l3-no2-td-v2"
)
```

## Functions

| Function | Description |
|---|---|
| `terrascope_credentials()` | Read credentials from environment variables |
| `list_collections()` | List available collections (with optional regex filter) |
| `search_terrascope()` | Search STAC API for items matching bbox/dates |
| `download_terrascope()` | Search and download files |

## Collection selection

The `collection` parameter is required. In interactive R sessions, omitting it will present a picker menu. In scripts, you must specify it explicitly.

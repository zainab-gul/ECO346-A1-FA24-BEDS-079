# 00_helpers.R -- shared by every R script. Run all scripts from the repository root.
# Variant 7 (roll no. 79 = 9*8 + 7): Balochistan (prov_code 4), urban (urban_rural 2).
library(readr); library(dplyr); library(ggplot2); library(scales); library(svglite)

VARIANT_PROV  <- 4
VARIANT_AREA  <- 2
VARIANT_LABEL <- "Balochistan urban"

# Weighted p-th quantile, exactly as in the assignment: sort by x, cumulative share of
# weight, smallest x whose share reaches or exceeds p. (Not R's quantile().)
wquantile <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  share <- cumsum(w) / sum(w)
  x[which(share >= p - 1e-12)[1]]      # 1e-12 only guards floating-point noise
}
wmean <- function(x, w) sum(w * x) / sum(w)

load_earners <- function() {
  person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
  hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE) |>
              select(hhid, hhweight, prov_code, urban_rural)
  person |>
    left_join(hh, by = "hhid") |>                       # attach weight, province, area
    filter(prov_code == VARIANT_PROV, urban_rural == VARIANT_AREA,
           age >= 15, age <= 64, earn_annual > 0)       # earners in my variant
}

rs_labels <- function(x) paste0("Rs ", comma(x))        # 1e4 -> "Rs 10,000"

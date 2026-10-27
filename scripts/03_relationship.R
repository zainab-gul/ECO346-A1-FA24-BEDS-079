# 03_relationship.R -- Question 3: earnings vs age, with weighted band means.
source("scripts/00_helpers.R")
e <- load_earners() |>
  mutate(band_lo = 15 + 5 * ((age - 15) %/% 5),
         band    = paste0(band_lo, "-", band_lo + 4))

bands <- e |>
  group_by(band_lo, band) |>
  summarise(n = n(), wmean = round(wmean(earn_annual, hhweight)), .groups = "drop") |>
  mutate(mid = band_lo + 2, thin = n < 30)
write_csv(bands, "tables/band_table_R.csv")
print(as.data.frame(bands))

top <- bands |> slice_max(wmean, n = 1)
m25 <- bands$wmean[bands$band == "25-29"]; m45 <- bands$wmean[bands$band == "45-49"]
cat("25-29:", m25, " 45-49:", m45, " highest:", top$band, top$wmean, "\n")

set.seed(346)                                   # jitter is random; fixed seed = reproducible
p <- ggplot() +
  geom_point(data = e, aes(age, earn_annual), colour = "grey35", alpha = 0.3, size = 1.2,
             position = position_jitter(width = 0.4, height = 0)) +
  geom_line(data = bands, aes(mid, wmean), colour = "#D55E00", linewidth = 0.8) +
  geom_point(data = bands, aes(mid, wmean, shape = thin), colour = "#D55E00",
             fill = "white", size = 3.5, stroke = 1.2) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), guide = "none") +
  do.call(annotate, c(list("label", x = top$mid - 9, y = 4e6, hjust = 0.5, colour = "#D55E00",
                           fill = "white",
                           label = paste0("Highest band mean: ", top$band, ", ", rs_labels(top$wmean),
                                          "\n(thin band, n = ", top$n, ")")),
                      LABEL_NOBORDER)) +
  annotate("segment", x = top$mid - 4, xend = top$mid - 0.3, y = 3.3e6, yend = top$wmean * 1.12,
           colour = "#D55E00") +
  scale_y_log10(breaks = 10^(4:7), labels = rs_labels(10^(4:7)), limits = c(1e4, 1e7)) +
  scale_x_continuous(breaks = seq(15, 65, 5), limits = c(14, 65)) +
  labs(title = paste(strwrap(sprintf(
         "Earnings rise steeply to the late 20s (mean Rs %s at 25-29), then climb only slowly",
         comma(m25)), 70), collapse = "\n"),
       x = "Age (years)", y = "Annual earnings (log scale)",
       caption = paste0("Source: PSLM 2019-20. Sample: earners aged 15-64, Balochistan urban (n = ", nrow(e),
                        ").\n",
                        "Points: individual earners, jittered horizontally by up to 0.4 years. Large markers: hhweight-weighted\n",
                        "mean earnings by 5-year age band, at the band midpoint. Hollow markers: thin bands (fewer than 30 earners).")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0))
ggsave("figures/relationship.svg", p, width = 8, height = 5.2)

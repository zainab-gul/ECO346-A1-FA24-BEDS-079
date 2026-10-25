# 02_distribution.R -- Question 2: weighted histogram of log10 earnings.
source("scripts/00_helpers.R")
e <- load_earners()

n_earners <- nrow(e)
w_med  <- wquantile(e$earn_annual, e$hhweight, 0.5)
u_med  <- median(e$earn_annual)
p10    <- wquantile(e$earn_annual, e$hhweight, 0.1)
p90    <- wquantile(e$earn_annual, e$hhweight, 0.9)
n_excl <- sum(e$earn_annual < 1e4 | e$earn_annual > 1e7)
cat("Earners:", n_earners, "\nWeighted median:", w_med, "\nUnweighted median:", u_med,
    "\nP10:", p10, "\nP90:", p90, "\nP90/P10:", sprintf("%.2f", p90 / p10),
    "\nExcluded:", n_excl, "\n")

inr <- e |> filter(earn_annual >= 1e4, earn_annual <= 1e7) |>
         mutate(lx = log10(earn_annual))

p <- ggplot(inr, aes(lx, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)), breaks = seq(4, 7, by = 0.1),
                 fill = "#4C78A8", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = log10(c(w_med, p90)), linetype = "dashed") +
  annotate("text", x = log10(w_med) - 0.04, y = Inf, hjust = 1, vjust = 1.5,
           label = paste0("Median\n", rs_labels(w_med))) +
  annotate("text", x = log10(p90) + 0.04, y = Inf, hjust = 0, vjust = 1.5,
           label = paste0("90th percentile\n", rs_labels(p90))) +
  scale_x_continuous(breaks = 4:7, labels = rs_labels(10^(4:7)), limits = c(4, 7)) +
  labs(title = paste(strwrap(sprintf(
         "Half of urban Balochistan's earners make under Rs %s a year; the 90th percentile earns %.1f times the 10th",
         comma(w_med), p90 / p10), 70), collapse = "\n"),
       x = "Annual earnings (log scale)", y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20. Sample: earners aged 15-64, Balochistan urban (n = ", n_earners,
                        "); ", n_excl, " earners outside Rs 10,000-10,000,000 excluded.\n",
                        "Weighted by household weight (hhweight); density per 0.1 log10 bin.")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0))
ggsave("figures/distribution.svg", p, width = 8, height = 5)

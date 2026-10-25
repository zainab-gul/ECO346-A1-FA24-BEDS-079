# 01_default.R -- Question 4: R's defaults, untouched.
source("scripts/00_helpers.R")
earners <- load_earners()
p <- ggplot(earners, aes(age, earn_annual)) + geom_point()
ggsave("figures/default.svg", p, width = 7, height = 5)

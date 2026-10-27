"""04_second_language.py -- Question 5: recompute the Q3 band table and figure in Python.
Run from the repository root AFTER scripts/03_relationship.R (it compares with R's table).
Variant 7 (roll no. 79): Balochistan (prov_code 4), urban (urban_rural 2)."""
import os, sys
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, FixedLocator, NullLocator

matplotlib.rcParams["svg.fonttype"] = "none"     # default is 'path'; keep text as real text

PROV, AREA = 4, 2  # variant 7: Balochistan, urban (same as VARIANT_PROV / VARIANT_AREA in 00_helpers.R)
os.makedirs("figures", exist_ok=True)

person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
d = person.merge(hh, on="hhid", how="left")
e = d[(d.prov_code == PROV) & (d.urban_rural == AREA) & d.age.between(15, 64) & (d.earn_annual > 0)].copy()

e["band_lo"] = 15 + 5 * ((e.age - 15) // 5)
rows = []
for lo, g in e.groupby("band_lo"):
    # np.round rounds halves to even, like R's round(); both give whole rupees here
    rows.append(dict(band_lo=lo, band=f"{lo}-{lo+4}", n=len(g),
                     wmean=int(np.round(np.sum(g.hhweight * g.earn_annual) / g.hhweight.sum())),
                     mid=lo + 2))
bands = pd.DataFrame(rows); bands["thin"] = bands.n < 30
print(bands.to_string(index=False))

if not os.path.exists("tables/band_table_R.csv"):
    sys.exit("tables/band_table_R.csv not found: run Rscript scripts/03_relationship.R first.")
r = pd.read_csv("tables/band_table_R.csv")
# Compare band by band (merge on the band label), not by row position.
cmp = r.merge(bands, on="band", suffixes=("_R", "_py"), how="outer")
assert len(cmp) == len(r) == len(bands), "different set of bands in R and Python!"
assert (cmp.wmean_R == cmp.wmean_py).all() and (cmp.n_R == cmp.n_py).all(), "tables differ!"
print("R and Python band tables agree to the rupee.")

m25 = bands.loc[bands.band == "25-29", "wmean"].iloc[0]
print("25-29 band mean  R:", int(r.loc[r.band == "25-29", "wmean"].iloc[0]), " Python:", int(m25))

rng = np.random.default_rng(346)
fig, ax = plt.subplots(figsize=(8, 5.2))
ax.scatter(e.age + rng.uniform(-0.4, 0.4, len(e)), e.earn_annual, s=8, color="0.35",
           alpha=0.3, linewidths=0)              # matplotlib default s=36 is far larger than ggplot's size 1.2
ax.plot(bands.mid, bands.wmean, color="#D55E00", lw=1.8)
solid, thin = bands[~bands.thin], bands[bands.thin]
ax.scatter(solid.mid, solid.wmean, s=70, color="#D55E00", zorder=3)
ax.scatter(thin.mid, thin.wmean, s=70, facecolors="white", edgecolors="#D55E00", linewidths=2, zorder=3)
top = bands.loc[bands.wmean.idxmax()]
ax.annotate(f"Highest band mean: {top.band}, Rs {int(top.wmean):,}\n(thin band, n = {int(top.n)})",
            xy=(top.mid, top.wmean * 1.12), xytext=(top.mid - 9, 4e6), color="#D55E00",
            ha="center", va="center", arrowprops=dict(arrowstyle="-", color="#D55E00"))
ax.set_yscale("log"); ax.set_ylim(1e4, 1e7); ax.set_xlim(14, 65)
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7])); ax.yaxis.set_minor_locator(NullLocator())
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"Rs {int(v):,}"))
ax.set_xticks(range(15, 66, 5))
ax.set_xlabel("Age (years)"); ax.set_ylabel("Annual earnings (log scale)")
ax.set_title(f"Earnings rise steeply to the late 20s (mean Rs {m25:,} at 25-29),\nthen climb only slowly",
             loc="left", fontsize=11)
for s in ("top", "right"): ax.spines[s].set_visible(False)
ax.grid(True, color="0.92")
fig.text(0.01, 0.01, f"Source: PSLM 2019-20. Sample: earners aged 15-64, Balochistan urban (n = {len(e)}). Weighted by hhweight.\n"
         "Points: individual earners, jittered by up to 0.4 years. Large markers: weighted band means.\n"
         "Hollow markers: thin bands (fewer than 30 earners).", fontsize=8, ha="left", va="bottom")
fig.tight_layout(rect=(0, 0.1, 1, 1))
plt.savefig("figures/relationship_python.svg")

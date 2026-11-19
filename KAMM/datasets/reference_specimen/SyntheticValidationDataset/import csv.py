import csv
import random

# ============================================================
# PARAMETERS — edit these as you like
# ============================================================

# Grid dimensions
NX = 50    # width
NY = 25    # height

# Material properties (meanH, stdH, meanE, stdE)
TOP_LEFT       = (0.2, 0.2, 20, 0.2)
TOP_RIGHT      = (0.75, 0.5, 20, 0.2)
BOTTOM_LEFT    = (2.5, 0.2, 25, 0.2)
BOTTOM_RIGHT   = (5.0, 0.2, 50, 0.2)
CENTER_RECT    = (1.0, 0.2, 10, 0.2)

# Center rectangle size (2/3 of the space)
RECT_W = int(NX * 2/3)
RECT_H = int(NY * 2/3)

# Rectangle bounds (centered)
rect_xmin = (NX - RECT_W) // 2
rect_xmax = rect_xmin + RECT_W - 1
rect_ymin = (NY - RECT_H) // 2
rect_ymax = rect_ymin + RECT_H - 1

# Midpoints
MX = NX // 2
MY = NY // 2

# ============================================================
# HELPER: sample a positive normally distributed property
# ============================================================

def sample(mean, std):
    """Sample from N(mean, std) but ensure strictly positive values."""
    val = random.gauss(mean, std)
    return max(val, 1e-6)   # avoid zero/negative values

# ============================================================
# GENERATE CSV
# ============================================================

with open("five_regions.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["X Position", "Y Position", "MODULUS", "HARDNESS"])

    for y in range(NY):
        for x in range(NX):

            # Determine base region (quadrants)
            if y < MY:
                region = TOP_LEFT if x < MX else TOP_RIGHT
            else:
                region = BOTTOM_LEFT if x < MX else BOTTOM_RIGHT

            # Overwrite if inside the center rectangle
            if rect_xmin <= x <= rect_xmax and rect_ymin <= y <= rect_ymax:
                region = CENTER_RECT

            # Extract parameters
            meanH, stdH, meanE, stdE = region

            hardness = sample(meanH, stdH)
            modulus  = sample(meanE, stdE)

            writer.writerow([x, y, modulus, hardness])

print("CSV successfully generated: five_regions.csv")
# Save a phase map as a png using the same grid structure for reference, using 'viridis' colormap
# Plot and save the phase map
import numpy as np
import matplotlib.pyplot as plt

# -----------------------------------------------------------
# Global larger font
# -----------------------------------------------------------
plt.rcParams.update({
    "font.size": 18,
    "axes.labelsize": 20,
    "xtick.labelsize": 16,
    "ytick.labelsize": 16,
    "legend.fontsize": 16,
    "figure.titlesize": 20,
})

# Create a phase map based on the defined regions
phase_map = np.zeros((NY, NX), dtype=int)
for y in range(NY):
    for x in range(NX):
        if y < MY:
            phase = 0 if x < MX else 1
        else:
            phase = 2 if x < MX else 3
        if rect_xmin <= x <= rect_xmax and rect_ymin <= y <= rect_ymax:
            phase = 4
        phase_map[y, x] = phase

# -----------------------------------------------------------
# Plot with colorbar matching full height
# -----------------------------------------------------------
fig, ax = plt.subplots(figsize=(10, 5))

im = ax.imshow(phase_map, cmap='viridis', origin='lower')

# Colorbar SAME height as image
cbar = fig.colorbar(im, ax=ax, shrink=1.0)   # full height
cbar.set_label("Phase", fontsize=18)
cbar.ax.tick_params(labelsize=16)

# Remove title (consistent with your previous request)
# ax.set_title("Phase Map")

ax.set_xlabel("X Position")
ax.set_ylabel("Y Position")

plt.tight_layout()
plt.savefig("phase_map_5regions.png", dpi=300)
plt.close()

print("Phase map image successfully generated: phase_map.png")

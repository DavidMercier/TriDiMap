# %% RVE generator from experimental CSV (phase map based)

from pathlib import Path
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


# -----------------------------
# User parameters
# -----------------------------
CSV_FILE = Path("input_phase_map.csv")   # <-- change path
Z_THICKNESS_UM = 1.0                      # RVE thickness
NZ = 20                                  # voxels through thickness
USE_CLUSTER = False                      # True = use "Cluster" instead of "Phase"


# -----------------------------
# Load CSV
# -----------------------------
df = pd.read_csv(CSV_FILE)

x = df["X Position_µm"].to_numpy()
y = df["Y Position_µm"].to_numpy()

phase_col = "Cluster" if USE_CLUSTER else "Phase"
phase_labels = df[phase_col].astype(str).to_numpy()


# -----------------------------
# Build phase encoding
# -----------------------------
unique_phases = sorted(set(phase_labels))
phase_to_id = {p: i for i, p in enumerate(unique_phases)}

phase_id = np.array([phase_to_id[p] for p in phase_labels], dtype=int)

print("Phase mapping:")
for k, v in phase_to_id.items():
    print(f"  {k} -> {v}")


# -----------------------------
# Reconstruct 2D grid
# -----------------------------
x_unique = np.unique(x)
y_unique = np.unique(y)

nx = len(x_unique)
ny = len(y_unique)

dx = np.mean(np.diff(x_unique))
dy = np.mean(np.diff(y_unique))

print(f"Grid size: {nx} x {ny}")
print(f"Spacing : dx={dx:.3f} µm, dy={dy:.3f} µm")

# Map points → grid indices
ix = np.searchsorted(x_unique, x)
iy = np.searchsorted(y_unique, y)

phase_2d = np.zeros((nx, ny), dtype=int)
phase_2d[ix, iy] = phase_id


# -----------------------------
# Extrude to 3D RVE
# -----------------------------
phase_3d = np.repeat(phase_2d[:, :, None], NZ, axis=2)

Lx = (x_unique.max() - x_unique.min()) + dx
Ly = (y_unique.max() - y_unique.min()) + dy
Lz = Z_THICKNESS_UM

print(f"RVE size: {Lx:.2f} x {Ly:.2f} x {Lz:.2f} µm")


# -----------------------------
# Visualization
# -----------------------------
plt.figure(figsize=(6, 5))
plt.imshow(
    phase_2d.T,
    origin="lower",
    extent=[0, Lx, 0, Ly],
    interpolation="nearest",
)
plt.xlabel("X (µm)")
plt.ylabel("Y (µm)")
plt.title("2D Phase Map (from CSV)")
plt.colorbar(label="Phase ID")
plt.tight_layout()
plt.show()

plt.figure(figsize=(6, 5))
plt.imshow(
    phase_3d[:, :, NZ // 2].T,
    origin="lower",
    extent=[0, Lx, 0, Ly],
    interpolation="nearest",
)
plt.title("Mid-Z slice of 3D RVE")
plt.colorbar(label="Phase ID")
plt.tight_layout()
plt.show()


# -----------------------------
# Save voxel RVE
# -----------------------------
np.save("rve_phase_id.npy", phase_3d)
print("Saved: rve_phase_id.npy")

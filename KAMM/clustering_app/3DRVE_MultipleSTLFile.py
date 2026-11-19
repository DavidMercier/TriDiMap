import csv
from collections import defaultdict
import os

# ------------------------------
# User parameters
# ------------------------------
csv_path   = r"C:\Users\dmercier\Downloads\phase_map_xy_phase.csv"
output_dir = r"C:\Users\dmercier\Downloads\rve_stl"  # where STLs will be written
thickness  = 1.0   # extrusion thickness in Z, same units as X/Y

# ------------------------------
# Helpers
# ------------------------------
def get_grid_spacing(values, tol=1e-9):
    """Return smallest positive spacing between unique sorted values."""
    vals = sorted(set(values))
    if len(vals) < 2:
        return 1.0
    diffs = [b - a for a, b in zip(vals, vals[1:]) if b - a > tol]
    return min(diffs) if diffs else 1.0

def write_triangle_ascii(f, v1, v2, v3):
    """Write a single triangle (facet) in ASCII STL with dummy normal."""
    f.write("  facet normal 0 0 0\n")
    f.write("    outer loop\n")
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v1))
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v2))
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v3))
    f.write("    endloop\n")
    f.write("  endfacet\n")

def write_voxel_ascii(f, x0, y0, z0, dx, dy, dz):
    """
    Write a voxel (rectangular box) as 12 triangles to STL.
    (x0, y0, z0) is the lower-left-bottom corner.
    """
    x1, y1, z1 = x0 + dx, y0 + dy, z0 + dz

    v000 = (x0, y0, z0)
    v100 = (x1, y0, z0)
    v110 = (x1, y1, z0)
    v010 = (x0, y1, z0)
    v001 = (x0, y0, z1)
    v101 = (x1, y0, z1)
    v111 = (x1, y1, z1)
    v011 = (x0, y1, z1)

    # Bottom (z = z0)
    write_triangle_ascii(f, v000, v100, v110)
    write_triangle_ascii(f, v000, v110, v010)

    # Top (z = z1)
    write_triangle_ascii(f, v001, v011, v111)
    write_triangle_ascii(f, v001, v111, v101)

    # Front (y = y0)
    write_triangle_ascii(f, v000, v001, v101)
    write_triangle_ascii(f, v000, v101, v100)

    # Back (y = y1)
    write_triangle_ascii(f, v010, v110, v111)
    write_triangle_ascii(f, v010, v111, v011)

    # Left (x = x0)
    write_triangle_ascii(f, v000, v010, v011)
    write_triangle_ascii(f, v000, v011, v001)

    # Right (x = x1)
    write_triangle_ascii(f, v100, v101, v111)
    write_triangle_ascii(f, v100, v111, v110)

# ------------------------------
# 1) Load CSV and group by phase
# ------------------------------
points_by_phase = defaultdict(list)
xs, ys = [], []

with open(csv_path, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        x = float(row["X_Position"])
        y = float(row["Y_Position"])
        phase = int(row["Phase"])  # e.g. 0, 1, 2, 3...

        xs.append(x)
        ys.append(y)
        points_by_phase[phase].append((x, y))

if not xs or not ys:
    raise RuntimeError("No data read from CSV – check path and header names.")

dx = get_grid_spacing(xs)
dy = get_grid_spacing(ys)
dz = thickness

print("Detected dx =", dx)
print("Detected dy =", dy)
print("Using dz (thickness) =", dz)
print("Found phases:", sorted(points_by_phase.keys()))

# ------------------------------
# 2) Ensure output directory exists
# ------------------------------
if not os.path.isdir(output_dir):
    os.makedirs(output_dir)

# ------------------------------
# 3) Write one STL per phase
# ------------------------------
for phase, pts in sorted(points_by_phase.items()):
    stl_path = os.path.join(output_dir, f"rve_phase_{phase}.stl")
    print("Writing STL for phase", phase, "->", stl_path)

    with open(stl_path, "w") as f:
        f.write(f"solid phase_{phase}\n")
        for (x, y) in pts:
            write_voxel_ascii(f, x, y, 0.0, dx, dy, dz)
        f.write(f"endsolid phase_{phase}\n")

print("Done. STL files written to:", output_dir)

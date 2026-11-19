import csv
from collections import defaultdict
import os

# ------------------------------
# USER PARAMETERS
# ------------------------------
csv_path   = r"C:\Users\dmercier\Downloads\phase_map_xy_phase.csv"
out_stl    = r"C:\Users\dmercier\Downloads\rve_combined.stl"
thickness  = 1.0     # extrusion in Z (same units as CSV coordinates)

# ------------------------------
# HELPERS
# ------------------------------
def get_grid_spacing(values, tol=1e-12):
    """Return smallest positive spacing between unique sorted values."""
    vals = sorted(set(values))
    diffs = [b - a for a, b in zip(vals, vals[1:]) if (b - a) > tol]
    return min(diffs) if diffs else 1.0

def write_triangle_ascii(f, v1, v2, v3):
    """Write a facet to ASCII STL."""
    f.write("  facet normal 0 0 0\n")
    f.write("    outer loop\n")
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v1))
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v2))
    f.write("      vertex {:.8f} {:.8f} {:.8f}\n".format(*v3))
    f.write("    endloop\n")
    f.write("  endfacet\n")

def write_voxel_ascii(f, x0, y0, z0, dx, dy, dz):
    """
    Write a rectangular voxel (brick) at origin corner (x0,y0,z0)
    with dimensions dx, dy, dz as 12 triangles.
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

    # bottom
    write_triangle_ascii(f, v000, v100, v110)
    write_triangle_ascii(f, v000, v110, v010)
    # top
    write_triangle_ascii(f, v001, v011, v111)
    write_triangle_ascii(f, v001, v111, v101)
    # front
    write_triangle_ascii(f, v000, v001, v101)
    write_triangle_ascii(f, v000, v101, v100)
    # back
    write_triangle_ascii(f, v010, v110, v111)
    write_triangle_ascii(f, v010, v111, v011)
    # left
    write_triangle_ascii(f, v000, v010, v011)
    write_triangle_ascii(f, v000, v011, v001)
    # right
    write_triangle_ascii(f, v100, v101, v111)
    write_triangle_ascii(f, v100, v111, v110)

# ------------------------------
# STEP 1: READ CSV
# ------------------------------
points = []
xs, ys = [], []

with open(csv_path, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        x = float(row["X_Position"])
        y = float(row["Y_Position"])
        phase = int(row["Phase"])   # unused but read for completeness
        points.append((x, y, phase))
        xs.append(x)
        ys.append(y)

if not points:
    raise RuntimeError("No data found in CSV. Check header and file path.")

dx = get_grid_spacing(xs)
dy = get_grid_spacing(ys)
dz = thickness

print("dx =", dx)
print("dy =", dy)
print("dz =", dz)
print("Total voxels:", len(points))

# ------------------------------
# STEP 2: WRITE SINGLE STL
# ------------------------------
with open(out_stl, "w") as f:
    f.write("solid rve\n")

    for x, y, phase in points:
        write_voxel_ascii(f, x, y, 0.0, dx, dy, dz)

    f.write("endsolid rve\n")

print("STL written to", out_stl)

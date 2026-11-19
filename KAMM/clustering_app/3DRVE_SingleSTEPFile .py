import csv
from collections import defaultdict

# -----------------------------
# User parameters
# -----------------------------
csv_path   = r"C:\Users\dmercier\Downloads\phase_map_xy_phase.csv"
out_step   = r"C:\Users\dmercier\Downloads\rve_mesh.step"

thickness_um = 1.0
UM_TO_MM = 1e-3

FIELD_X = "X Position_µm"
FIELD_Y = "Y Position_µm"
FIELD_PHASE = "Phase"

# -----------------------------
# Load points
# -----------------------------
pts = []
xs = []
ys = []

with open(csv_path, newline='', encoding="utf-8-sig") as f:
    rdr = csv.DictReader(f)
    for row in rdr:
        x = float(row[FIELD_X]) * UM_TO_MM
        y = float(row[FIELD_Y]) * UM_TO_MM
        phase = int(row[FIELD_PHASE])
        pts.append((x, y, phase))
        xs.append(x)
        ys.append(y)

# spacing
def spacing(v):
    v = sorted(set(v))
    d = [b - a for a, b in zip(v, v[1:]) if b > a]
    return min(d) if d else 1.0

dx = spacing(xs)
dy = spacing(ys)
dz = thickness_um * UM_TO_MM

# -----------------------------
# Build triangulated cubes
# -----------------------------
triangles = []   # list of (phase, [(x,y,z), (x,y,z), (x,y,z)])

def add_cube(x0, y0, z0, dx, dy, dz, phase):
    # 8 vertices
    v = [
        (x0,      y0,      z0),
        (x0+dx,   y0,      z0),
        (x0+dx,   y0+dy,   z0),
        (x0,      y0+dy,   z0),
        (x0,      y0,      z0+dz),
        (x0+dx,   y0,      z0+dz),
        (x0+dx,   y0+dy,   z0+dz),
        (x0,      y0+dy,   z0+dz)
    ]

    # 12 triangles of a cube
    faces = [
        (0,1,2),(0,2,3),   # bottom
        (4,5,6),(4,6,7),   # top
        (0,1,5),(0,5,4),   # side
        (1,2,6),(1,6,5),
        (2,3,7),(2,7,6),
        (3,0,4),(3,4,7),
    ]

    for a,b,c in faces:
        triangles.append((phase, [v[a], v[b], v[c]]))


for x,y,p in pts:
    add_cube(x, y, 0.0, dx, dy, dz, p)

# -----------------------------------------
# Write minimal STEP AP242 faceted structure
# -----------------------------------------

with open(out_step, "w") as f:
    f.write("ISO-10303-21;\n")
    f.write("HEADER;\n")
    f.write("FILE_DESCRIPTION(('STEP AP242 faceted'),'2;1');\n")
    f.write("FILE_NAME('rve_mesh.step','2025-12-01T00:00:00',('python'),"
            "('none'),'python','python','none');\n")
    f.write("FILE_SCHEMA(('AUTOMOTIVE_DESIGN'));\n")
    f.write("ENDSEC;\n")
    f.write("DATA;\n")

    pid = 1
    point_ids = {}

    # Write all vertices
    for phase, tri in triangles:
        for (x,y,z) in tri:
            if (x,y,z) not in point_ids:
                pid += 1
                point_ids[(x,y,z)] = pid
                f.write(f"#{pid}=CARTESIAN_POINT('',({x},{y},{z}));\n")

    # Write triangles
    for phase, tri in triangles:
        a = point_ids[tri[0]]
        b = point_ids[tri[1]]
        c = point_ids[tri[2]]
        pid += 1
        f.write(f"#{pid}=TRIANGULATED_FACE((#{a},#{b},#{c}));\n")

    f.write("ENDSEC;\n")
    f.write("END-ISO-10303-21;\n")

print("Wrote faceted STEP:", out_step)

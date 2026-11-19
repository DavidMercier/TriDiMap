# Python Script, API Version = V251
"""
Auto RVE reconstruction from CSV (Discovery-compliant)
"""

import csv
from SpaceClaim.Api.V251 import *

#############################################
# USER INPUT
#############################################
csv_file_path = r"C:\Users\dmercier\Downloads\phase_map_xy_phase.csv"
pixel_size = 1.0     # µm
thickness  = 5.0     # extrusion height (µm)

#############################################
# RESET PROJECT AND SET UNITS
#############################################
File.ResetProject()

Window.ActiveWindow.Units.ActiveUnitsSystem = UnitsSystemType.Metric
Window.ActiveWindow.Units.MetricUnits = MetricUnits(
    MetricLengthUnit.Micrometers, MetricMassUnit.Grams, AngleUnit.Degrees
)

#############################################
# STEP 1 — LOAD CSV
#############################################
phase_points = []
max_phase = -1

with open(csv_file_path, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        ph = int(row["Phase"])
        max_phase = max(max_phase, ph)
        phase_points.append({
            "x": float(row["X_Position"]),
            "y": float(row["Y_Position"]),
            "phase": ph
        })

print("Loaded:", len(phase_points), "points")
print("Phases:", max_phase + 1)

#############################################
# STEP 2 — GROUP BY PHASE
#############################################
phases = {i: [] for i in range(max_phase + 1)}
for p in phase_points:
    phases[p["phase"]].append(p)

#############################################
# STEP 3 — SET SKETCH PLANE ONCE
#############################################
ViewHelper.SetSketchPlane(Plane.PlaneXY, None)

#############################################
# HELPER: draw rectangle using Discovery's 2D sketch API
#############################################
def draw_rectangle_2d(x, y, size):
    p1 = Point2D.Create(x, y)
    p2 = Point2D.Create(x + size, y)
    p3 = Point2D.Create(x + size, y + size)
    SketchRectangle.Create(p1, p2, p3)

#############################################
# HELPER: extrude all new faces for a phase
#############################################
def extrude_phase(phase_id, height):

    # Switch to Solid mode
    ViewHelper.SetViewMode(InteractionMode.Solid, None)

    # Collect all faces from all bodies
    all_bodies = Body.GetAll()
    all_faces = []
    for b in all_bodies:
        for f in b.Faces:
            all_faces.append(f)

    # Build the selection
    selection = Selection.Create(all_faces)

    # Extrude
    options = ExtrudeFaceOptions()
    options.ExtrudeType = ExtrudeType.Add
    ExtrudeFaces.Execute(selection, height, options, None)

    # Group for this phase
    DesignBodyGroup.Create(selection, "Phase_" + str(phase_id))

#############################################
# STEP 4 — MAIN LOOP PER PHASE
#############################################
for phase_id, pts in phases.items():
    print("Creating geometry for Phase", phase_id)

    # Draw all pixels for this phase
    for p in pts:
        draw_rectangle_2d(p["x"], p["y"], pixel_size)

    # Extrude them
    extrude_phase(phase_id, thickness)

print("RVE creation completed.")

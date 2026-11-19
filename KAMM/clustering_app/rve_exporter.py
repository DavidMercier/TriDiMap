#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path
from collections import defaultdict
import re

# ---------------------------------------------------------
# GRID SPACING DETECTION
# ---------------------------------------------------------
def detect_grid_spacing(values, tol=1e-9):
    vals = sorted(set(values))
    if len(vals) < 2:
        return 1.0
    diffs = [b - a for a, b in zip(vals, vals[1:]) if (b - a) > tol]
    return min(diffs) if diffs else 1.0


# ---------------------------------------------------------
# PHASE LABEL NORMALISATION
# ---------------------------------------------------------
def normalize_phase(p):
    if isinstance(p, (int, float)):
        return int(p)
    p = str(p).strip()
    m = re.search(r"(\d+)$", p)
    if m:
        return int(m.group(1))
    return abs(hash(p)) % 1000


# ---------------------------------------------------------
# STL WRITER
# ---------------------------------------------------------
def write_triangle(f, v1, v2, v3):
    f.write("  facet normal 0 0 0\n")
    f.write("    outer loop\n")
    f.write(f"      vertex {v1[0]} {v1[1]} {v1[2]}\n")
    f.write(f"      vertex {v2[0]} {v2[1]} {v2[2]}\n")
    f.write(f"      vertex {v3[0]} {v3[1]} {v3[2]}\n")
    f.write("    endloop\n")
    f.write("  endfacet\n")


def write_voxel_stl(f, x0, y0, z0, dx, dy, dz):
    x1, y1, z1 = x0 + dx, y0 + dy, z0 + dz

    v000 = (x0, y0, z0); v100 = (x1, y0, z0)
    v110 = (x1, y1, z0); v010 = (x0, y1, z0)
    v001 = (x0, y0, z1); v101 = (x1, y0, z1)
    v111 = (x1, y1, z1); v011 = (x0, y1, z1)

    faces = [
        (v000, v100, v110), (v000, v110, v010),  # bottom
        (v001, v011, v111), (v001, v111, v101),  # top
        (v000, v001, v101), (v000, v101, v100),  # front
        (v010, v110, v111), (v010, v111, v011),  # back
        (v000, v010, v011), (v000, v011, v001),  # left
        (v100, v101, v111), (v100, v111, v110),  # right
    ]

    for v1, v2, v3 in faces:
        write_triangle(f, v1, v2, v3)


def export_stl(phase_voxels, outdir, dx, dy, dz):
    outdir.mkdir(exist_ok=True)
    for ph, voxels in phase_voxels.items():
        path = outdir / f"rve_phase_{ph}.stl"
        with open(path, "w") as f:
            f.write(f"solid phase_{ph}\n")
            for (x, y) in voxels:
                write_voxel_stl(f, x, y, 0, dx, dy, dz)
            f.write(f"endsolid phase_{ph}\n")
    return outdir

############################################################
#   APDL INPUT FILE WRITER (.inp → convert → .cdb)
############################################################

from pathlib import Path

def build_voxel_nodes_and_elements(voxels, dx, dy, dz):
    node_map = {}
    next_nid = 1
    elements = []
    eid = 1

    for (x0, y0) in voxels:
        x1, y1 = x0 + dx, y0 + dy

        coords = [
            (x0,y0,0),
            (x1,y0,0),
            (x1,y1,0),
            (x0,y1,0),
            (x0,y0,dz),
            (x1,y0,dz),
            (x1,y1,dz),
            (x0,y1,dz),
        ]

        node_ids = []
        for c in coords:
            if c not in node_map:
                node_map[c] = next_nid
                next_nid += 1
            node_ids.append(node_map[c])

        elements.append([eid] + node_ids)
        eid += 1

    return node_map, elements


def write_ansys_input(path: Path, voxels, dx, dy, dz, element_type=185, mat_id=1):
    """
    Writes a VALID ANSYS APDL .inp file.
    Workbench will convert this to a valid blocked CDB.
    """
    node_map, elements = build_voxel_nodes_and_elements(voxels, dx, dy, dz)

    with open(path, "w") as f:
        f.write("/COM, Exported RVE voxel mesh\n")
        f.write("/PREP7\n")
        f.write(f"ET,1,{element_type}\n")

        # dummy material
        f.write(f"MP,EX,{mat_id},210000\n")
        f.write(f"MP,NUXY,{mat_id},0.3\n")

        f.write("\n! --- Nodes ---\n")
        for (x,y,z), nid in sorted(node_map.items(), key=lambda kv: kv[1]):
            f.write(f"N,{nid},{x:.13e},{y:.13e},{z:.13e}\n")

        f.write("\n! --- Elements ---\n")
        f.write("TYPE,1\n")
        f.write(f"MAT,{mat_id}\n")
        f.write("REAL,1\n")

        for elem in elements:
            eid = elem[0]
            n1,n2,n3,n4,n5,n6,n7,n8 = elem[1:]
            f.write(f"EN,{eid},{n1},{n2},{n3},{n4},{n5},{n6},{n7},{n8}\n")

        f.write("\nFINISH\n")

def export_cdb_all(phase_voxels, outdir, dx, dy, dz):
    """
    Actually exports .INP files (NOT CDB)
    The Workbench script will convert them to .cdb
    """
    outdir.mkdir(exist_ok=True)
    for ph, voxels in phase_voxels.items():
        mat_id = int(ph) if ph != 0 else 1
        inp_path = outdir / f"rve_phase_{ph}.inp"
        write_ansys_input(inp_path, voxels, dx, dy, dz, element_type=185, mat_id=mat_id)
    return outdir

import os
import numpy as np
import vtk

# =====================================================================
#  RECTILINEAR VTK WRITER (NO EULER / NO FEATURE IDS)
# =====================================================================

def generate_rectangular_vtk_file(pathname, filename, xVec, yVec, zVec):
    """
    Write a simple ASCII VTK RECTILINEAR_GRID file.

    Only geometry is written (no CELL_DATA). This is enough for
    vtkRectilinearGridReader + rectgrid_to_unstructured + vtk2cdb.

    Parameters
    ----------
    pathname : str
        Directory where the file will be written.
    filename : str
        File name, e.g. "rve_rectilinear.vtk".
    xVec, yVec, zVec : sequence of floats
        Grid coordinates along X, Y, Z in the same units (e.g. µm).
    """
    os.makedirs(pathname, exist_ok=True)
    filepath = os.path.join(pathname, filename)

    nx = len(xVec)
    ny = len(yVec)
    nz = len(zVec)

    with open(filepath, "w") as f:
        f.write("# vtk DataFile Version 2.0\n")
        f.write("RVE Rectilinear Grid\n")
        f.write("ASCII\n\n")

        f.write("DATASET RECTILINEAR_GRID\n")
        f.write(f"DIMENSIONS {nx} {ny} {nz}\n")

        # X coordinates
        f.write(f"X_COORDINATES {nx} float\n")
        f.write(" ".join(f"{x:.6f}" for x in xVec) + "\n")

        # Y coordinates
        f.write(f"Y_COORDINATES {ny} float\n")
        f.write(" ".join(f"{y:.6f}" for y in yVec) + "\n")

        # Z coordinates
        f.write(f"Z_COORDINATES {nz} float\n")
        f.write(" ".join(f"{z:.6f}" for z in zVec) + "\n")

    print(f"[VTK] Rectilinear grid written: {filepath}")


# ---------------------------
# SimpleGridForCDB
# ---------------------------
class SimpleGridForCDB:
    def __init__(self, points, cells):
        self.points = points
        self.cells = cells

    def get_cell(self, i):
        class C: pass
        c = C()
        c.type = 12  # VTK_HEXAHEDRON
        return c


# ---------------------------
# RectGrid → Unstructured
# ---------------------------
def rectgrid_to_unstructured(rect_grid):
    X = rect_grid.GetXCoordinates()
    Y = rect_grid.GetYCoordinates()
    Z = rect_grid.GetZCoordinates()

    nx, ny, nz = X.GetNumberOfValues(), Y.GetNumberOfValues(), Z.GetNumberOfValues()

    pts = [
        (X.GetValue(i), Y.GetValue(j), Z.GetValue(k))
        for k in range(nz)
        for j in range(ny)
        for i in range(nx)
    ]
    points = np.array(pts)

    def node(i, j, k):
        return k * (ny * nx) + j * nx + i

    cells = []
    for k in range(nz - 1):
        for j in range(ny - 1):
            for i in range(nx - 1):
                n0 = node(i, j, k)
                n1 = node(i+1, j, k)
                n2 = node(i+1, j+1, k)
                n3 = node(i, j+1, k)
                n4 = node(i, j, k+1)
                n5 = node(i+1, j, k+1)
                n6 = node(i+1, j+1, k+1)
                n7 = node(i, j+1, k+1)
                cells.extend([8, n0, n1, n2, n3, n4, n5, n6, n7])

    return SimpleGridForCDB(points, np.array(cells, int))


# =====================================================================
#  VTK → CDB (HEX8 + phases → MAT + components)
# =====================================================================
def vtk2cdb(grid, output_name, scale=1.0, elem_phase=None, element_type=185):
    """
    Workbench-compatible CDB writer
    --------------------------------
    - SOLID185 hex elements
    - NBLOCK and EBLOCK formats follow strict WB requirements
    - Each element gets MAT = phase ID
    - Phase-based element components PHASE1, PHASE2, ...
    """

    points = np.array(grid.points, float) * float(scale)
    cells  = np.array(grid.cells,  int)

    if cells.size % 9 != 0:
        raise ValueError("Cells array length must be multiple of 9.")

    n_nodes = points.shape[0]
    n_elem  = cells.size // 9
    conn    = cells.reshape((n_elem, 9))   # [8, n0..n7]

    if elem_phase is None:
        elem_phase = np.ones(n_elem, int)
    else:
        elem_phase = np.asarray(elem_phase, int)
        if elem_phase.size != n_elem:
            raise ValueError("elem_phase size mismatch.")

    # ------------------------------------------------------------------
    #  HEADER
    # ------------------------------------------------------------------
    content  = "/PREP7\n"
    content += f"ET,1,{element_type}\n"

    # ------------------------------------------------------------------
    #  NBLOCK  (Workbench-approved format)
    # ------------------------------------------------------------------
    # Format:
    # NBLOCK,6,SOLID
    # (1i9, 3i9, 3e20.12)
    #
    content += f"NBLOCK,6,SOLID,{n_nodes},{n_nodes}\n"
    content += "(1I9,3I9,3E20.12)\n"

    for nid, (x, y, z) in enumerate(points, start=1):
        # Node record: NID, ?, ?, X, Y, Z
        content += (
            f"{nid:9d}{0:9d}{0:9d}"
            f"{x:20.12E}{y:20.12E}{z:20.12E}\n"
        )

    content += "N,\n"

    # ------------------------------------------------------------------
    #  EBLOCK  (Workbench strict format)
    # ------------------------------------------------------------------
    # Syntax:
    # EBLOCK,8,185,ELEMENTS,ELEMENTS
    # (1I9,1I9,1I9,1I9,8I9)
    #
    # Columns:
    #   EID, MAT, TYP, REAL, n0 n1 n2 n3 n4 n5 n6 n7
    #
    content += f"EBLOCK,8,{element_type},{n_elem},{n_elem}\n"
    content += "(1I9,1I9,1I9,1I9,8I9)\n"

    for eid in range(1, n_elem + 1):
        row = conn[eid - 1]
        if row[0] != 8:
            continue

        node_ids = row[1:] + 1  # convert 0-based → 1-based

        mat_id = int(elem_phase[eid - 1]) or 1
        real   = 0

        content += (
            f"{eid:9d}{mat_id:9d}{1:9d}{real:9d}" +
            "".join(f"{nid:9d}" for nid in node_ids) +
            "\n"
        )

    content += "E,\n"

    # ------------------------------------------------------------------
    #  COMPONENTS (PHASEx)
    # ------------------------------------------------------------------
    unique_mats = sorted(set(int(m) for m in elem_phase if m != 0))

    content += "/PREP7\n"
    for m in unique_mats:
        content += f"ESEL,S,MAT,,{m}\n"
        content += f"CM,PHASE{m},ELEM\n"
    content += "ALLSEL,ALL\n"

    content += "FINISH\n"

    # ------------------------------------------------------------------
    #  WRITE FILE
    # ------------------------------------------------------------------
    out_path = output_name + ".cdb"
    with open(out_path, "w") as f:
        f.write(content)

    print(f"[CDB] Written Workbench-compatible: {out_path}")

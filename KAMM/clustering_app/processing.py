import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from scipy.stats import gaussian_kde, kurtosis
from matplotlib.colors import LogNorm

from sklearn.metrics import (
    silhouette_score,
    calinski_harabasz_score,
    davies_bouldin_score,
)


# ======================================================================
# 1. Excel Import & Processing
# ======================================================================
def import_and_process_data(file_paths, sheet_name, result_dir):
    """
    Import, normalize, and merge indentation data from several Excel files.
    Converts two-row headers into single names and computes derived features.

    Parameters
    ----------
    file_paths : list of str
        Paths to Excel workbooks.
    sheet_name : str
        Name of the sheet to load.
    result_dir : Path or str
        Directory where processed CSV will be saved.

    Returns
    -------
    pd.DataFrame
        Cleaned and feature-augmented dataset.
    """

    # --- 1. Load Excel files ---
    frames = []
    for path in file_paths:
        df = pd.read_excel(path, sheet_name=sheet_name)
        frames.append(df)

    data = pd.concat(frames, ignore_index=True)

    # --- 2. Merge row 0 (units row) into header ---
    data.columns = [
        f"{col}_{unit}" if unit else col
        for col, unit in zip(data.columns, data.iloc[0])
    ]
    data = data.drop(index=0).reset_index(drop=True)

    # Convert numerics where possible
    data = data.apply(pd.to_numeric, errors="ignore")

    # Replace empty cells with NaN
    data.replace("", np.nan, inplace=True)

    # --- 3. Remove instrument-specific junk columns ---
    drop_cols = [
        c for c in data.columns
        if "Markers_nan" in c or "Index_Integer" in c or "Markers" in c
    ]
    data.drop(columns=drop_cols, inplace=True, errors="ignore")

    # --- 4. Derived mechanical features ---
    if "HARDNESS_GPa" in data.columns and "MODULUS_GPa" in data.columns:

        if "H/E_ratio" not in data.columns:
            data["H/E_ratio"] = data["HARDNESS_GPa"] / data["MODULUS_GPa"]

        if "H^3/E^2_ratio" not in data.columns:
            data["H^3/E^2_ratio"] = (
                data["HARDNESS_GPa"] ** 3
            ) / (data["MODULUS_GPa"] ** 2)

    # --- 5. Save ---
    result_path = result_dir / "imported_data.csv"
    data.to_csv(result_path, index=False)
    print(f"✔ Data saved → {result_path}")

    return data


# ======================================================================
# 2. Clustering Metric Evaluation
# ======================================================================
def evaluate_clustering(df, features, label_col):
    """
    Compute clustering quality metrics safely:
    - Silhouette Score
    - Calinski–Harabasz
    - Davies–Bouldin

    Parameters
    ----------
    df : DataFrame
        Dataset.
    features : list of str
        Feature column names.
    label_col : str
        Cluster label column.

    Returns
    -------
    tuple(float, float, float)
        (silhouette, calinski, davies) or (nan, nan, nan) on failure.
    """

    try:
        if not features:
            print("⚠ evaluate_clustering: No usable features provided.")
            return np.nan, np.nan, np.nan

        X = df[features].select_dtypes(include=[np.number]).dropna()
        labels = df.loc[X.index, label_col]

        # Remove rows with NaN labels
        mask = labels.notna()
        X = X.loc[mask]
        labels = labels.loc[mask]

        unique = np.unique(labels)
        if len(unique) < 2:
            print(f"⚠ evaluate_clustering: Only {len(unique)} cluster(s) detected.")
            return np.nan, np.nan, np.nan

        sil = float(silhouette_score(X, labels))
        ch = float(calinski_harabasz_score(X, labels))
        db = float(davies_bouldin_score(X, labels))

        print(
            f"✔ evaluate_clustering: {len(unique)} clusters → "
            f"sil={sil:.3f}, ch={ch:.1f}, db={db:.3f}"
        )
        return sil, ch, db

    except Exception as e:
        print(f"⚠ evaluate_clustering: Failed with exception: {e}")
        return np.nan, np.nan, np.nan

def compute_kam(data, output_folder, order, image_paths=None):
    """
    Compute KAM metrics:
        - KAMM (E*H mismatch)
        - KAEM (E mismatch)
        - KAPM (H mismatch)
        - KAMM_RATIO (E/H mismatch)
        - KAMM_NORMPROD (centered mismatch)
    """

    suffix = "" if order == 1 else f"_{order}"

    # ---- Local helpers -------------------------------------------------
    def make_grids(df, colE, colH):
        dfE = df.pivot_table(
            index="Y Position_µm", columns="X Position_µm",
            values=colE, aggfunc="mean"
        )
        dfH = df.pivot_table(
            index="Y Position_µm", columns="X Position_µm",
            values=colH, aggfunc="mean"
        )
        return dfE, dfH, dfE.values, dfH.values

    def neighbor_offsets(order):
        if order == 1:
            base = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        elif order == 2:
            base = [
                (-2, 0), (2, 0), (0, -2), (0, 2),
                (-1, -1), (-1, 1), (1, -1), (1, 1),
            ]
        else:
            raise ValueError("order must be 1 or 2")

        # ⭐ FIX: Add self-neighbor to avoid corner NaN
        base.append((0, 0))
        return base

    def compute_diff(grid, ref_df, name, offsets):
        rows, cols = grid.shape
        out = np.zeros((rows, cols))   # ⭐ always filled (default 0)

        for i in range(rows):
            for j in range(cols):
                if np.isnan(grid[i, j]):
                    continue

                ctr = grid[i, j]
                vals = []

                for di, dj in offsets:
                    ni, nj = i + di, j + dj
                    if 0 <= ni < rows and 0 <= nj < cols:
                        if not np.isnan(grid[ni, nj]):
                            vals.append(abs(grid[ni, nj] - ctr))

                # ⭐ FIX: fallback applied per pixel
                out[i, j] = np.mean(vals) if vals else 0.0

        df = pd.DataFrame(out, index=ref_df.index, columns=ref_df.columns)
        df = df.reset_index().melt(
            id_vars="Y Position_µm",
            var_name="X Position_µm",
            value_name=name
        )
        return df

    # --------------------------------------------------------------
    # KAMM_RATIO
    # --------------------------------------------------------------
    def compute_kamm_ratio(gridE, gridH, ref_df, offsets, eps=1e-6):
        rows, cols = gridE.shape
        out = np.zeros((rows, cols))  # ⭐ default 0 everywhere

        for i in range(rows):
            for j in range(cols):
                Ei, Hi = gridE[i, j], gridH[i, j]
                if np.isnan(Ei) or np.isnan(Hi):
                    continue

                vals = []
                for di, dj in offsets:
                    ni, nj = i + di, j + dj
                    if 0 <= ni < rows and 0 <= nj < cols:
                        Ej, Hj = gridE[ni, nj], gridH[ni, nj]
                        if not np.isnan(Ej) and not np.isnan(Hj):
                            vals.append(abs((Ei - Ej) / (Hi - Hj + eps)))

                # ⭐ always defined
                out[i, j] = np.mean(vals) if vals else 0.0

        df = pd.DataFrame(out, index=ref_df.index, columns=ref_df.columns)
        df = df.reset_index().melt(
            id_vars="Y Position_µm",
            var_name="X Position_µm",
            value_name="KAMM_RATIO"
        )
        return df

    # --------------------------------------------------------------
    # KAMM_NORMPROD
    # --------------------------------------------------------------
    def compute_kamm_normprod(gridE, gridH, ref_df, offsets):
        rows, cols = gridE.shape
        out = np.zeros((rows, cols))  # ⭐ default 0

        σE = max(np.nanstd(gridE), 1e-12)
        σH = max(np.nanstd(gridH), 1e-12)

        for i in range(rows):
            for j in range(cols):
                Ei, Hi = gridE[i, j], gridH[i, j]
                if np.isnan(Ei) or np.isnan(Hi):
                    continue

                vals = []
                for di, dj in offsets:
                    ni, nj = i + di, j + dj
                    if 0 <= ni < rows and 0 <= nj < cols:
                        Ej, Hj = gridE[ni, nj], gridH[ni, nj]
                        if not np.isnan(Ej) and not np.isnan(Hj):
                            vals.append(((Ei - Ej) * (Hi - Hj)) / (σE * σH))

                out[i, j] = np.mean(vals) if vals else 0.0

        df = pd.DataFrame(out, index=ref_df.index, columns=ref_df.columns)
        df = df.reset_index().melt(
            id_vars="Y Position_µm",
            var_name="X Position_µm",
            value_name="KAMM_NORMPROD"
        )
        return df

    def merge_metric(original, df_metric, name):

        # All spatial coordinates from original dataset
        xs = sorted(original["X Position_µm"].unique())
        ys = sorted(original["Y Position_µm"].unique())

        # Build pivot and force full rectangle
        pivot = df_metric.pivot(
            index="Y Position_µm",
            columns="X Position_µm",
            values=name
        )
        pivot = pivot.reindex(index=ys, columns=xs, fill_value=0.0)

        # Flatten back
        flat = pivot.stack().reset_index()
        flat.columns = ["Y Position_µm", "X Position_µm", name]

        # Ensure numeric
        flat["X Position_µm"] = pd.to_numeric(flat["X Position_µm"], errors="coerce")
        flat["Y Position_µm"] = pd.to_numeric(flat["Y Position_µm"], errors="coerce")
        flat[name] = pd.to_numeric(flat[name], errors="coerce")

        # Merge
        return original.merge(flat, on=["X Position_µm", "Y Position_µm"], how="left")

    # ---------------------------------------------------------------
    # 1. Grids
    # ---------------------------------------------------------------
    colE = "MODULUS_GPa" if "MODULUS_GPa" in data.columns else "young's modulus value"
    colH = "HARDNESS_GPa" if "HARDNESS_GPa" in data.columns else "hardness value"

    dfE, dfH, gridE, gridH = make_grids(data, colE, colH)
    offsets = neighbor_offsets(order)

    # ---------------------------------------------------------------
    # 2. Compute metrics
    # ---------------------------------------------------------------
    df_kamm       = compute_diff(gridE * gridH, dfE, f"KAMM{suffix}", offsets)
    df_kaem       = compute_diff(gridE,          dfE, f"KAEM{suffix}", offsets)
    df_kapm       = compute_diff(gridH,          dfH, f"KAPM{suffix}", offsets)
    df_ratio      = compute_kamm_ratio(gridE, gridH, dfE, offsets)
    df_ratio.rename(columns={"KAMM_RATIO": f"KAMM_RATIO{suffix}"}, inplace=True)
    df_normprod   = compute_kamm_normprod(gridE, gridH, dfE, offsets)
    df_normprod.rename(columns={"KAMM_NORMPROD": f"KAMM_NORMPROD{suffix}"}, inplace=True)

    # ---------------------------------------------------------------
    # 3. Merge
    # ---------------------------------------------------------------
    out = data.copy()
    out = merge_metric(out, df_kamm,     f"KAMM{suffix}")
    out = merge_metric(out, df_kaem,     f"KAEM{suffix}")
    out = merge_metric(out, df_kapm,     f"KAPM{suffix}")
    out = merge_metric(out, df_ratio,    f"KAMM_RATIO{suffix}")
    out = merge_metric(out, df_normprod, f"KAMM_NORMPROD{suffix}")

    return out


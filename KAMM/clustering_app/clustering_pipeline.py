#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ============================================================
# ICME MULTIPHASE CLUSTERING PIPELINE — HARMONIZED VERSION
# ------------------------------------------------------------
"""
ICME Multiphase Clustering Pipeline (single dataset, Streamlit-ready)

Public API (used by the Streamlit app):

    pipeline = clustering_pipeline(...)

    pipeline.load()                  # discover / prepare dataset
    preview_dir = pipeline.preview(preview_root_dir)  # generate preview plots
    pipeline.run_pipeline()          # full preprocessing + clustering + plots + exports
    pipeline.export()                # backward compatibility (no-op)

Main outputs for a clustering run are stored in:

    pipeline.outdir  # Path to result directory
"""

# ============================================================
# IMPORTS
# ============================================================

from pathlib import Path
import json
from typing import List, Optional, Dict, Any
import re
from datetime import datetime

import numpy as np
import pandas as pd

# Matplotlib (non-interactive backend for Streamlit)
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

# -----------------------------------------------------------
# GLOBAL FONT SIZE SETTINGS (publication quality)
# -----------------------------------------------------------
plt.rcParams.update({
    "font.size": 18,
    "axes.labelsize": 20,
    "axes.titlesize": 20,   # still needed but titles removed below
    "xtick.labelsize": 16,
    "ytick.labelsize": 16,
    "legend.fontsize": 16,
    "figure.titlesize": 20,
})
# Scikit-learn
from sklearn.cluster import KMeans, DBSCAN, AgglomerativeClustering, OPTICS
from sklearn.mixture import GaussianMixture
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

# Utilities
from matplotlib.colors import ListedColormap
from kneed import KneeLocator

# Internal imports
from clustering_app.MI_client import MIClient
from clustering_app.mapping import (
    plot_pixel_map,
    plot_map,
    plot_pdf_with_deconvolution_on_axis,
    plot_cdf_with_weibull_fit_on_axis
)
from clustering_app.processing import compute_kam, evaluate_clustering

# Get path to project root (one level up from clustering_app)
APP_DIR = Path(__file__).resolve().parent.parent

print(f"Resolved APP_DIR: {APP_DIR}")
# ============================================================
# MAIN PIPELINE CLASS
# ============================================================

class clustering_pipeline:
    """Main class implementing the ICME multiphase clustering pipeline.

    Responsibilities:
        • File ingestion (CSV/XLS/XLSX → CSV normalization)
        • Header cleanup and numeric sanitization
        • KAMM computation
        • Derived feature creation (H/E, H³/E², etc.)
        • Clustering (KMeans, GMM, DBSCAN, Agglomerative, OPTICS)
        • Phase assignment using hardness ordering
        • Result plotting (maps, PDFs, CDFs, PCA, composite figures)
        • Export of CSV + JSON summaries
        • Optional export of results to Granta MI
    """

    # --------------------------------------------------------
    # INITIALIZATION
    # --------------------------------------------------------
    def __init__(
        self,
        base_dir: Path,
        methods: Optional[List[str]] = None,
        manual_clusters_num: int = 3,
        auto_cluster_num: bool = False,
        enable_pca: bool = True,
        enable_manual_norm: bool = False,
        compute_kamm: bool = True,
        use_kamm_in_features: bool = True,
        sheet_names: Optional[List[str]] = None,
        xdim: int = 4,
        ydim: int = 2,
        cmap: str = "viridis",
        verbose: bool = True,
        selected_features: Optional[List[str]] = None,
        feature_mode: str = "E vs H (recommended)",
        custom_features: Optional[List[str]] = None,
        **kwargs,
    ):
        """Initialize pipeline parameters and bookkeeping attributes."""

        # Primary configuration
        self.base_dir = Path(base_dir)
        self.methods = methods or ["KMeans"]
        self.manual_clusters_num = int(manual_clusters_num)
        self.auto_cluster_num = bool(auto_cluster_num)
        self.enable_pca = bool(enable_pca)
        self.enable_manual_norm = bool(enable_manual_norm)
        self.compute_kamm = bool(compute_kamm)
        self.use_kamm_in_features = bool(use_kamm_in_features)
        self.xdim = xdim
        self.ydim = ydim
        self.cmap_name = cmap
        self.verbose = verbose
        self.selected_features = selected_features
        self.feature_mode = feature_mode
        self.custom_features = custom_features or []
        self.kamm_order = kwargs.get("kamm_order", 1)
        
        # --- Normalize kamm_order to list ---
        if isinstance(self.kamm_order, int):
            if self.kamm_order in [1, 2]:
                self.kamm_order = [self.kamm_order]
            else:
                self.kamm_order = []
        elif not isinstance(self.kamm_order, list):
            self.kamm_order = []

        # Valid Excel sheet name candidates
        self.sheet_names = sheet_names or [
            "Sheet1", "Sheet", "Sample", "Samples",
            "Data", "Dataset", "Summary", "Results",
            "Tabelle1", "Tabelle2", "Feuil1", "Feuil2",
            "Foglio1", "Blad1", "Sheet 1", "Sheet_1",
        ]

        self._pca_model = None
        self._pca_components = None
        self._pca_explained_var = None
        self._pca_explained_var_ratio = None
        self._scaler = None
        self._scaler_feature_cols = None
        self._scaler_mean = None
        self._scaler_std = None

        # Internal bookkeeping
        self.csv_paths: List[Path] = []
        self.stats_paths: List[Path] = []
        self._last_feature_cols: Optional[List[str]] = None

        self.data_cleaned: Optional[pd.DataFrame] = None
        self.data_clustered: Optional[pd.DataFrame] = None

        # Result directories
        self.result_dir: Optional[Path] = None
        self.last_result_dir: Optional[Path] = None
        self.outdir: Optional[Path] = None
        self.preview_dir: Optional[Path] = None

    # ========================================================
    # EXCEL HANDLING
    # ========================================================
    def _read_excel_any_sheet(self, file: Path, engine: str) -> pd.DataFrame:
        """Read an Excel file without altering header rows.

        Picks a sheet name from a priority list and reads with
        ``header=None`` so that header normalization can be done explicitly.
        """
        try:
            xls = pd.ExcelFile(file, engine=engine)
            sheets = xls.sheet_names
            print(f"📄 Sheet names found: {sheets}")

            preferred = None
            for name in ["Sample", "Sheet1", "Data", sheets[0]]:
                if name in sheets:
                    preferred = name
                    break
            if preferred is None:
                preferred = sheets[0]

            print(f"➡️ Reading sheet: {preferred}")

            df = pd.read_excel(
                file,
                sheet_name=preferred,
                engine=engine,
                header=None,
            )
            return df

        except Exception as e:
            print(f"❌ _read_excel_any_sheet failed: {e}")
            raise

    def _normalize_two_row_header(self, df: pd.DataFrame) -> pd.DataFrame:
        """Detect and flatten 2-row MTS headers (name + units).

        Only applies if row 1 does not contain numeric data. Otherwise
        row 0 is treated as the header row and row 1 as the first data row.
        """
        if df.shape[0] < 2:
            return df

        row0 = df.iloc[0]
        row1 = df.iloc[1]

        # if second row is numeric-like → not a unit row
        numeric_like = row1.astype(str).str.contains(r"[0-9]").any()
        if numeric_like:
            print("ℹ️ Second row contains numeric data → NOT a 2-row header.")
            df.columns = row0.astype(str).str.strip()
            return df.iloc[1:].reset_index(drop=True)

        print("🔧 Detected 2-row MTS header → flattening column names")

        header = row0.astype(str).str.strip()
        units = row1.astype(str).str.strip()

        new_cols = []
        for h, u in zip(header, units):
            h = h.replace(" ", "_")
            u = u.replace(" ", "_")
            new_cols.append(f"{h}_{u}" if u else h)

        df = df.iloc[2:].copy()
        df.columns = new_cols
        df.reset_index(drop=True, inplace=True)
        return df

    # ========================================================
    # PUBLIC API (USED BY STREAMLIT APP)
    # ========================================================
    def load(self) -> None:
        """Discover the dataset file and convert XLS/XLSX to CSV if needed."""
        self.load_file_list()

    def preview(self, preview_root: Optional[Path] = None) -> Path:
        """Generate preview-only plots *before* clustering."""
        if preview_root is None:
            preview_root = APP_DIR / "results" / "preview"  # use global APP_DIR

        if not self.csv_paths:
            self.load_file_list()

        csv_path = self.csv_paths[0]
        dataset_name = csv_path.stem
        print(f"📁 Preview root directory: {preview_root}")
        preview_dir = preview_root / dataset_name
        preview_dir.mkdir(parents=True, exist_ok=True)
        print(f"📁 Generating preview plots in: {preview_dir}")

        self.preview_dir = self.generate_preview(preview_dir)
        return self.preview_dir

    def run_pipeline(self) -> None:
        if not self.csv_paths:
            self.load_file_list()

        csv_path = self.csv_paths[0]

        flag_kamm = (
            "KAMM" in self.feature_mode
            or (self.selected_features and "KAMM" in self.selected_features)
            or self.compute_kamm
        )

        # Preprocess
        self._process_single_file(csv_path, self.methods[0], flag_kamm)

        # make sure any downstream step uses the cleaned file path
        csv_path = self.csv_paths[0]

        # Clustering + exports
        self.run_clustering()

    # ========================================================
    # FILE DISCOVERY AND IO
    # ========================================================
    def load_file_list(self) -> None:
        """Locate a single dataset file (CSV/XLS/XLSX) starting from ``base_dir``.

        - If ``base_dir`` is itself a file path, use it directly.
        - Otherwise search for exactly one matching file in the directory.

        Raises
        ------
        FileNotFoundError
            If no suitable file is found.
        ValueError
            If multiple candidate files are found.
        """
        base = self.base_dir

        if base.is_file():
            files = [base]
        else:
            files = (
                list(base.glob("*.csv"))
                + list(base.glob("*.xlsx"))
                + list(base.glob("*.xls"))
            )

        if not files:
            raise FileNotFoundError(
                f"No data file found in {base}. Provide a CSV/XLS/XLSX."
            )

        if len(files) > 1:
            raise ValueError(
                f"Multiple data files found in {base}. "
                f"Keep only one. Found: { [f.name for f in files] }"
            )

        file = files[0]
        print(f"📄 Using dataset: {file.name}")

        # Convert Excel → CSV automatically
        if file.suffix.lower() in [".xlsx", ".xls"]:
            file = self._convert_xls_to_csv(file)

        self.csv_paths = [file]

        # Optional stats JSON
        stats = list(file.parent.glob("*_stats.json"))
        self.stats_paths = stats if stats else []

    def _extract_text_from_biff(self, file: Path) -> pd.DataFrame:
        """Fallback reader for corrupted BIFF8 XLS files (e.g., MTS, NanoSuite).

        Extracts ASCII-like text from OLE2 streams and reconstructs
        a table when normal Excel readers fail.
        """
        import olefile

        ole = olefile.OleFileIO(str(file))
        streams = ole.listdir()
        text_chunks = []

        for stream in streams:
            try:
                data = ole.openstream(stream).read()
                # Keep ASCII + whitespace/tab/newline, convert others to newlines
                ascii_data = re.sub(rb"[^\x09\x0A\x0D\x20-\x7E]+", b"\n", data)
                decoded = ascii_data.decode("ascii", errors="ignore")
                text_chunks.append(decoded)
            except Exception:
                # Skip unreadable streams silently
                pass

        ole.close()

        text = "\n".join(text_chunks)
        lines = [l.strip() for l in text.splitlines() if l.strip()]

        # Heuristic: line with the most tokens is treated as header
        header_line = max(lines, key=lambda l: len(l.split()))
        columns = header_line.split()

        rows = []
        for line in lines:
            parts = line.split()
            if len(parts) == len(columns):
                rows.append(parts)

        df = pd.DataFrame(rows[1:], columns=columns)

        # Convert numeric-like entries
        for col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="ignore")

        return df

    def _convert_xls_to_csv(self, file: Path) -> Path:
        """Robust XLS/XLSX/XML/CSV loader that outputs a clean CSV file."""
        print(f"📄 Converting: {file}")
        out_csv = file.with_suffix(".csv")

        # Read header bytes for sniffing format
        with open(file, "rb") as f:
            header = f.read(4096)

        # ---------- 1) XLSX disguised as XLS ----------
        if header[:2] == b"PK":
            print("ℹ️ Detected XLSX → openpyxl")
            df = pd.read_excel(file, engine="openpyxl", header=None)
            df = self._normalize_two_row_header(df)
            df.to_csv(out_csv, index=False)
            return out_csv

        # ---------- 2) BIFF XLS ----------
        if header.startswith(b"\xD0\xCF\x11\xE0"):
            print("ℹ️ Detected BIFF XLS")
            for engine in ["xlrd", "openpyxl", "odf", "pyxlsb"]:
                try:
                    print(f"📌 Trying {engine}")
                    df = pd.read_excel(file, engine=engine, header=None)
                    raw_cols = df.iloc[0].tolist()
                    second_row = df.iloc[1].tolist()
                    ncols = len(raw_cols)

                    def is_number(x: Any) -> bool:
                        try:
                            float(str(x))
                            return True
                        except Exception:
                            return False

                    # ---- CASE A: true MTS file without header ----
                    if ncols == 6 and all(is_number(v) for v in raw_cols):
                        print("🔧 MTS file with missing header → applying standard names")
                        df.columns = [
                            "Markers",
                            "Index",
                            "X Position_µm",
                            "Y Position_µm",
                            "MODULUS_GPa",
                            "HARDNESS_GPa",
                        ]
                        df = df.iloc[1:].reset_index(drop=True)
                        df.to_csv(out_csv, index=False)
                        return out_csv

                    # ---- CASE B: 2-row header (row0 text, row1 units) ----
                    def is_unit(x: str) -> bool:
                        if not isinstance(x, str):
                            return False
                        x = x.strip().lower()
                        return x in ("gpa", "µm", "um", "μm") or x.endswith("gpa")

                    row0 = [str(v).strip() for v in raw_cols]
                    row1 = [str(v).strip() for v in second_row]
                    unit_count = sum(is_unit(v) for v in row1)

                    if ncols == 6 and unit_count >= 2:
                        print("🔧 TRUE MTS 2-row header detected → flattening")
                        df.columns = [
                            "Markers",
                            "Index",
                            "X Position_µm",
                            "Y Position_µm",
                            "MODULUS_GPa",
                            "HARDNESS_GPa",
                        ]
                        df = df.iloc[2:].reset_index(drop=True)
                        df.to_csv(out_csv, index=False)
                        return out_csv

                    # ---- CASE C: normal header on first row ----
                    print("ℹ️ XLS appears to have real header → using row0")
                    df.columns = row0
                    df = df.iloc[1:].reset_index(drop=True)
                    df.to_csv(out_csv, index=False)
                    return out_csv

                except Exception as e:
                    print(f"⚠️ Engine {engine} failed: {e}")

        # ---------- 3) XML Spreadsheet ----------
        if header.strip().startswith(b"<?xml") or b"<Workbook" in header:
            print("ℹ️ XML 2003 detected")
            try:
                df = pd.read_xml(file)
                df = self._normalize_two_row_header(df)
                df.to_csv(out_csv, index=False)
                return out_csv
            except Exception as e:
                print(f"⚠️ XML load failed: {e}")

        # ---------- 4) CSV ----------
        try:
            print("ℹ️ Trying CSV parser")
            df = pd.read_csv(file, sep=None, engine="python")
            df = self._normalize_two_row_header(df)
            df.to_csv(out_csv, index=False)
            return out_csv
        except Exception as e:
            print(f"⚠️ CSV parse failed: {e}")

        # ---------- 5) whitespace-delimited text ----------
        try:
            print("ℹ️ Trying whitespace-delimited")
            df = pd.read_csv(file, delim_whitespace=True)
            df = self._normalize_two_row_header(df)
            df.to_csv(out_csv, index=False)
            return out_csv
        except Exception:
            pass

        # ---------- 6) BIFF text extraction fallback ----------
        try:
            print("ℹ️ BIFF text extraction")
            df = self._extract_text_from_biff(file)
            df.to_csv(out_csv, index=False)
            return out_csv
        except Exception as e:
            print(f"⚠ BIFF extract failed: {e}")

        raise RuntimeError(f"Cannot convert XLS file: {file}")

    # ========================================================
    # PREPROCESSING: CLEANING, KAMM, DERIVED FEATURES
    # ========================================================
    def _process_single_file(self, csv_path: Path, method: str, flag_kamm: bool) -> None:
        """Load cleaned CSV, normalize headers, derive features, compute KAMM, and deduplicate."""

        # 1. Prepare result directory
        data_name = csv_path.stem
        method_clean = method.replace("Clustering", "").replace(" ", "")
        timestamp = datetime.now().strftime("%Y-%m-%d_%Hh%M")
        folder_name = f"{data_name}_{method_clean}_{timestamp}"

        result_dir = APP_DIR / "results" / "clustering" / folder_name
        result_dir.mkdir(parents=True, exist_ok=True)

        self.result_dir = self.last_result_dir = self.outdir = result_dir

        # 2. Load raw data
        try:
            data = pd.read_csv(csv_path)
        except Exception:
            data = pd.read_excel(csv_path)

        # 3. Header normalization (MTS-style fixes)
        header = list(data.columns)

        if header == ["", "Integer", "µm", "µm", "GPa", "GPa"]:
            print("🔧 Fixing MTS header with missing names → assigning proper column names")
            data.columns = [
                "Markers",
                "Index",
                "X Position_µm",
                "Y Position_µm",
                "MODULUS_GPa",
                "HARDNESS_GPa",
            ]

        col_fix = {
            "HARDNESS_GPa_GPa": "HARDNESS_GPa",
            "MODULUS_GPa_GPa": "MODULUS_GPa",
            "HARDNESS_(GPa)": "HARDNESS_GPa",
            "MODULUS_(GPa)": "MODULUS_GPa",
            "HARDNESS_GPa_(GPa)": "HARDNESS_GPa",
            "MODULUS_GPa_(GPa)": "MODULUS_GPa",
        }
        data.rename(columns=col_fix, inplace=True)

        data.columns = [c.strip() for c in data.columns]

        # Drop bogus first unit row marked as "-"
        if isinstance(data.iloc[0, 0], str) and data.iloc[0, 0].strip() == "-":
            data = data.iloc[1:].reset_index(drop=True)

        # Try numeric conversion where appropriate
        def _safe_to_numeric(df: pd.DataFrame) -> pd.DataFrame:
            for col in df.columns:
                try:
                    df[col] = pd.to_numeric(df[col])
                except Exception:
                    pass
            return df

        data = _safe_to_numeric(data)

        # Avoid collision with PHASE field
        if "PHASE" in data.columns:
            data.rename(columns={"PHASE": "True_Phase"}, inplace=True)

        # 4. Auto-rename common instrument columns
        rename_map = {
            "X Position": "X Position_µm",
            "Y Position": "Y Position_µm",
            "X position": "X Position_µm",
            "Y position": "Y Position_µm",
            "Xpos": "X Position_µm",
            "Ypos": "Y Position_µm",
            "Xposition": "X Position_µm",
            "Yposition": "Y Position_µm",
            "HARDNESS_Gpa": "HARDNESS_GPa",
            "MODULUS_Gpa": "MODULUS_GPa",
            "HARDNESS": "HARDNESS_GPa",
            "MODULUS": "MODULUS_GPa",
            "H": "HARDNESS_GPa",
            "E": "MODULUS_GPa",
        }
        for old, new in rename_map.items():
            if old in data.columns and new not in data.columns:
                data.rename(columns={old: new}, inplace=True)

        # Ensure Markers/Index are strings
        for col in ["Markers", "Index"]:
            if col in data.columns:
                data[col] = data[col].astype(str)

        # 5) Sanitize mechanical & spatial columns FIRST (convert to numeric cleanly)
        for col in ["HARDNESS_GPa", "MODULUS_GPa", "X Position_µm", "Y Position_µm"]:
            if col in data.columns:
                data[col] = (
                    data[col]
                    .astype(str)
                    .str.replace(",", ".", regex=False)
                    .str.replace(r"[^0-9.\-eE]", "", regex=True)
                )
                data[col] = pd.to_numeric(data[col], errors="coerce")

        # 6) Snapshot RAW columns (these are ALWAYS the unnormalized physical values)
        if "HARDNESS_GPa" in data.columns:
            data["HARDNESS_GPa_RAW"] = data["HARDNESS_GPa"].copy()
        if "MODULUS_GPa" in data.columns:
            data["MODULUS_GPa_RAW"] = data["MODULUS_GPa"].copy()

        # 7) Optional manual normalization ONLY affects the working columns (not RAW)
        if self.enable_manual_norm and {"HARDNESS_GPa", "MODULUS_GPa"}.issubset(data.columns):
            hmax = data["HARDNESS_GPa"].max()
            emax = data["MODULUS_GPa"].max()
            if pd.notna(hmax) and hmax != 0:
                data["HARDNESS_GPa"] = data["HARDNESS_GPa"] / hmax
            if pd.notna(emax) and emax != 0:
                data["MODULUS_GPa"] = data["MODULUS_GPa"] / emax

        if {"HARDNESS_GPa_RAW","MODULUS_GPa_RAW"}.issubset(data.columns):
            data["H/E_ratio_RAW"] = data["HARDNESS_GPa_RAW"] / data["MODULUS_GPa_RAW"]
            data["H^3/E^2_ratio_RAW"] = (data["HARDNESS_GPa_RAW"] ** 3) / (data["MODULUS_GPa_RAW"] ** 2)

            valid_mask = (
                np.isfinite(data["H/E_ratio_RAW"])
                & np.isfinite(data["H^3/E^2_ratio_RAW"])
                & (data["H/E_ratio_RAW"] > 0)
                & (data["H^3/E^2_ratio_RAW"] > 0)
            )
            data = data[valid_mask].copy()

        # 7b) Always compute WORKING mechanical ratios (post-normalization if enabled)
        if {"HARDNESS_GPa", "MODULUS_GPa"}.issubset(data.columns):
            data["H/E_ratio"] = data["HARDNESS_GPa"] / data["MODULUS_GPa"]
            data["H^3/E^2_ratio"] = (data["HARDNESS_GPa"] ** 3) / (data["MODULUS_GPa"] ** 2)

            # sanitize
            for c in ["H/E_ratio", "H^3/E^2_ratio"]:
                data[c] = data[c].replace([np.inf, -np.inf], np.nan)

        # 8. De-duplicate (X,Y) grid positions
        if {"X Position_µm", "Y Position_µm"}.issubset(data.columns):
            duplicates = data.duplicated(
                subset=["X Position_µm", "Y Position_µm"],
                keep=False,
            )
            if duplicates.any():
                print("🔎 Resolving duplicate (X,Y) positions...")
                agg: Dict[str, str] = {}
                for col in data.columns:
                    if col in ("X Position_µm", "Y Position_µm"):
                        continue
                    if pd.api.types.is_numeric_dtype(data[col]):
                        agg[col] = "mean"
                    else:
                        agg[col] = "first"

                data = (
                    data.groupby(["X Position_µm", "Y Position_µm"], dropna=False)
                    .agg(agg)
                    .reset_index()
                )

        # ---- KAMM computation (optional, supports multiple orders) ----

        # Remove any existing KAMM-related columns to avoid stale data
        for col in [
            "KAMM","KAEM","KAPM","KAMM_RATIO","KAMM_NORMPROD",
            "KAMM_1","KAEM_1","KAPM_1","KAMM_RATIO_1","KAMM_NORMPROD_1",
            "KAMM_2","KAEM_2","KAPM_2","KAMM_RATIO_2","KAMM_NORMPROD_2",
        ]:
            if col in data.columns:
                data.drop(columns=[col], inplace=True)

        if flag_kamm and isinstance(self.kamm_order, list):
            for order in self.kamm_order:
                try:
                    kam_df = compute_kam(data, result_dir, order=order)

                    # Copy order-specific columns if they exist
                    for col in kam_df.columns:
                        if col.endswith(f"_{order}"):
                            data[col] = kam_df[col]

                    # If order=1 returns unsuffixed columns, keep them too
                    if order == 1:
                        for col in ["KAMM","KAEM","KAPM","KAMM_RATIO","KAMM_NORMPROD"]:
                            if col in kam_df.columns:
                                data[col] = kam_df[col]

                except Exception as e:
                    print(f"⚠ KAMM (order={order}) failed: {e}")

        # Backward compatibility: alias _1 → base names
        if 1 in self.kamm_order:
            rename_1st = {
                "KAMM_1": "KAMM",
                "KAEM_1": "KAEM",
                "KAPM_1": "KAPM",
                "KAMM_RATIO_1": "KAMM_RATIO",
                "KAMM_NORMPROD_1": "KAMM_NORMPROD",
            }
            for old, new in rename_1st.items():
                if old in data.columns and new not in data.columns:
                    data[new] = data[old]

        # Always guarantee presence of KAMM column
        if "KAMM" not in data.columns:
            data["KAMM"] = np.nan

        # 9. Save cleaned CSV
        try:
            clean_csv = result_dir / f"{csv_path.stem}_cleaned.csv"
            data.to_csv(clean_csv, index=False)
            self.csv_paths = [clean_csv]   # optional: make pipeline continue from cleaned copy
            print(f"💾 Saved cleaned CSV → {clean_csv}")
        except Exception as e:
            print(f"⚠️ Failed to overwrite cleaned CSV: {e}")

        self.data_cleaned = data

    # ========================================================
    # CLUSTERING ORCHESTRATION
    # ========================================================
    def run_clustering(self) -> None:
        """Apply clustering to cleaned data, generate plots, evaluate, and export."""
        if self.data_cleaned is None:
            raise RuntimeError(
                "run_clustering(): data_cleaned is None. Preprocessing not completed."
            )

        data = self.data_cleaned.copy()
        method = self.methods[0]
        result_dir = self.result_dir or self.last_result_dir

        if result_dir is None:
            raise RuntimeError("No result directory available for clustering.")

        # 1. Determine number of clusters
        if self.auto_cluster_num:
            k = self._determine_cluster_number(data, method)
        else:
            k = self.manual_clusters_num

        self.best_cluster_number = int(k)

        # 2. Apply clustering
        data = self._apply_clustering(data, method, n_clusters=k, flag_kamm=self.compute_kamm)

        # ✅ enforce nice labels 0..k-1
        data = self._relabel_clusters_consecutive(data)

        # ✅ true number of clusters present
        k_actual = int(data["Cluster"].nunique())
        self.best_cluster_number = k_actual

        if data is None:
            raise RuntimeError("Clustering failed: _apply_clustering returned None.")

        self.data_clustered = data

        # 3. Phase assignment (hardness ordering)
        phase_map, phase_stats = {}, pd.DataFrame()
        try:
            h_col = "HARDNESS_GPa_RAW" if "HARDNESS_GPa_RAW" in data.columns else "HARDNESS_GPa"
            e_col = "MODULUS_GPa_RAW"  if "MODULUS_GPa_RAW"  in data.columns else "MODULUS_GPa"

            stats_cols = []
            for c in ["HARDNESS_GPa_RAW", "MODULUS_GPa_RAW", "H/E_ratio_RAW", "H^3/E^2_ratio_RAW"]:
                if c in data.columns:
                    stats_cols.append(c)

            cluster_stats = data.groupby("Cluster")[[h_col, e_col]].agg(["mean", "std", "count"])

            phase_map, phase_stats = self._map_phases_by_hardness(cluster_stats)

            data["Phase"] = data["Cluster"].map(lambda c: phase_map.get(c, "Phase_unknown"))

            # ✅ Export raw JSON ONCE, after Phase exists
            self._export_raw_clustered_json(data, result_dir)

        except Exception as e:
            print(f"⚠️ Phase mapping failed: {e}")
            # Still ensure Phase exists so downstream plotting/export doesn't crash
            if "Phase" not in data.columns:
                data["Phase"] = "Phase_unknown"

        self.data_clustered = data

        # 4. Generate plots
        self._plot_EH_cluster_scatter(data, result_dir)
        self._plot_spatial_cluster_map(data, result_dir)

        if self.enable_pca:
            self._plot_pca_clusters(data, k_actual, result_dir)
            self._plot_pca_spatial_map(data, k_actual, result_dir)

        self._plot_correlation_matrix(data, result_dir)
        self._plot_composite_figure(data, k_actual, result_dir)

        colors = self._build_color_map(k_actual)

        try:
            self._plot_clustered_pdf(data, "HARDNESS_GPa", colors, result_dir)
            self._plot_clustered_pdf(data, "MODULUS_GPa", colors, result_dir)
        except Exception as e:
            print(f"⚠️ Failed clustered PDF overlay: {e}")


        # 5. Export final CSV + phase statistics
        self._export_results(data, phase_stats, result_dir)

        # 6. Evaluate clustering quality
        silhouette = calinski = davies = np.nan
        try:
            eval_cols = [
                c
                for c in data.columns
                if c
                not in [
                    "X Position_µm",
                    "Y Position_µm",
                    "Cluster",
                    "Phase",
                    "True_Phase",
                ]
                and pd.api.types.is_numeric_dtype(data[c])
                and data[c].std() > 0
            ]
            if len(data["Cluster"].unique()) > 1:
                silhouette, calinski, davies = evaluate_clustering(
                    data, eval_cols, "Cluster"
                )
        except Exception as e:
            print(f"⚠️ Clustering evaluation failed: {e}")

        # 7. JSON summary
        result_json = self._prepare_phase_result_json(
            phase_stats,
            phase_map,
            method,
            silhouette,
            calinski,
            davies,
            n_clusters=k_actual,
            data=data,
        )

        json_path = result_dir / "cluster_statistics_phases.json"
        try:
            with json_path.open("w") as f:
                json.dump(result_json, f, indent=4, default=str, allow_nan=True)
            print(f"💾 Saved clustering summary JSON → {json_path}")
        except Exception as e:
            print(f"❌ Failed to write clustering JSON: {e}")

        self.outdir = result_dir
        self.last_result_dir = result_dir
        print("✔️ Clustering pipeline completed.")

    # ========================================================
    # FEATURE SELECTION AND CLUSTERING INTERNALS
    # ========================================================
    def _resolve_selected_features(self, available_cols: List[str]) -> List[str]:
        """Resolve user-provided feature keywords into actual column names."""
        if not self.selected_features:
            return []

        mapping = {
            "H": "HARDNESS_GPa",
            "E": "MODULUS_GPa",
            "KAMM": "KAMM",
            "KAEM": "KAEM",
            "KAPM": "KAPM",
            "RATIO": "H/E_ratio",
            "H/E": "H/E_ratio",
            "H3/E2": "H^3/E^2_ratio",
        }

        resolved: List[str] = []
        for key in self.selected_features:
            if key in mapping and mapping[key] in available_cols:
                resolved.append(mapping[key])
            elif key in available_cols:
                resolved.append(key)
            else:
                print(f"⚠️ Feature '{key}' not found in dataset. Skipped.")
        return resolved

    def _map_phases_by_hardness(
        self, cluster_stats: pd.DataFrame, ascending: bool = True
    ) -> (Dict[Any, str], pd.DataFrame):
        """Assign phase names by ordering clusters by mean hardness."""
        if cluster_stats.empty:
            return {}, pd.DataFrame()

        # Flatten hierarchical columns
        cluster_stats = cluster_stats.copy()
        cluster_stats.columns = [
            "_".join(c).strip() if isinstance(c, tuple) else c
            for c in cluster_stats.columns
        ]

        hardness_col = next(
            (
                c
                for c in cluster_stats.columns
                if "HARDNESS" in c.upper() and "MEAN" in c.upper()
            ),
            None,
        )
        if not hardness_col:
            return {}, pd.DataFrame()

        phase_stats = cluster_stats.sort_values(by=hardness_col, ascending=ascending)
        n = len(phase_stats)

        phase_stats["Phase_Name"] = [f"Phase_{i+1}" for i in range(n)]
        phase_map = dict(zip(phase_stats.index, phase_stats["Phase_Name"]))

        # Optional physical labels if 2 or 3 phases
        if n == 3:
            phase_stats["Physical_Label"] = ["Matrix", "Interface", "Fiber"]
        elif n == 2:
            phase_stats["Physical_Label"] = ["Matrix", "Fiber"]
        else:
            phase_stats["Physical_Label"] = [f"Phase_{i+1}" for i in range(n)]

        return phase_map, phase_stats

    def _build_color_map(self, n_colors: int):
        """Return colors ordered from lowest to highest hardness."""
        tab10 = sns.color_palette("tab10", n_colors=10)
        ranked_colors = [tab10[0], tab10[2], tab10[1]]
        if n_colors <= 1:
            return ranked_colors[:n_colors]
        if n_colors == 2:
            return [tab10[0], tab10[1]]
        if n_colors == 3:
            return ranked_colors[:n_colors]
        return sns.blend_palette(
            ranked_colors,
            n_colors=n_colors,
        )

    def _cluster_palette(self, data: pd.DataFrame) -> Dict[Any, Any]:
        labels = sorted(data["Cluster"].dropna().unique())
        return dict(zip(labels, self._build_color_map(len(labels))))

    @staticmethod
    def _cluster_rank_labels(n_clusters: int) -> List[str]:
        labels = []
        for rank in range(n_clusters):
            if n_clusters == 1:
                description = "Only"
            elif rank == 0:
                description = "Low H"
            elif rank == n_clusters - 1:
                description = "High H"
            else:
                description = f"Rank {rank + 1}/{n_clusters}"
            labels.append(description)
        return labels

    def _determine_cluster_number(self, data: pd.DataFrame, method: str) -> int:
        """Use KMeans inertia knee detection to estimate optimal cluster count."""
        try:
            X = data.select_dtypes(include=[np.number]).to_numpy()
            X = np.nan_to_num(X, nan=np.nanmean(X))
            X = StandardScaler().fit_transform(X)

            inertias = []
            ks = range(2, 10)
            for k in ks:
                km = KMeans(n_clusters=k, random_state=0, n_init=10)
                km.fit(X)
                inertias.append(km.inertia_)

            knee = KneeLocator(
                ks, inertias, curve="convex", direction="decreasing"
            ).knee
            return int(knee or self.manual_clusters_num)

        except Exception as e:
            print(f"⚠️ Auto cluster number detection failed: {e}. Using manual k.")
            return self.manual_clusters_num

    def _apply_clustering(
        self,
        data: pd.DataFrame,
        method: str,
        n_clusters: int,
        flag_kamm: bool,
    ) -> pd.DataFrame:
        """Internal clustering engine for KMeans/GMM/DBSCAN/Agglomerative/OPTICS."""

        # Normalize repeated naming inconsistencies
        col_fix = {
            "HARDNESS_GPa_GPa": "HARDNESS_GPa",
            "MODULUS_GPa_GPa": "MODULUS_GPa",
            "HARDNESS_(GPa)": "HARDNESS_GPa",
            "MODULUS_(GPa)": "MODULUS_GPa",
            "HARDNESS_GPa_(GPa)": "HARDNESS_GPa",
            "MODULUS_GPa_(GPa)": "MODULUS_GPa",
            "HARDNESS": "HARDNESS_GPa",
            "MODULUS": "MODULUS_GPa",
            "H": "HARDNESS_GPa",
            "E": "MODULUS_GPa",
        }
        for old, new in col_fix.items():
            if old in data.columns:
                data.rename(columns={old: new}, inplace=True)

        # Derived ratios if missing
        if {"HARDNESS_GPa", "MODULUS_GPa"}.issubset(data.columns):
            if "H/E_ratio" not in data.columns:
                data["H/E_ratio"] = data["HARDNESS_GPa"] / data["MODULUS_GPa"]
            if "H^3/E^2_ratio" not in data.columns:
                data["H^3/E^2_ratio"] = (data["HARDNESS_GPa"] ** 3) / (data["MODULUS_GPa"] ** 2)

            for c in ["H/E_ratio", "H^3/E^2_ratio"]:
                data[c] = data[c].replace([np.inf, -np.inf], np.nan)
                data[c] = data[c].fillna(data[c].mean()).fillna(0)

        # Feature selection based on mode
        if self.feature_mode == "E vs H (recommended)":
            feature_cols = ["HARDNESS_GPa", "MODULUS_GPa"]

        elif self.feature_mode == "E vs H vs KAMM":
            feature_cols = ["HARDNESS_GPa", "MODULUS_GPa"]
            if "KAMM" in data.columns:
                feature_cols.append("KAMM")

        elif self.feature_mode == "Mechanical features (H, E, H/E, H³/E²)":
            feature_cols = [
                c
                for c in ["HARDNESS_GPa", "MODULUS_GPa", "H/E_ratio", "H^3/E^2_ratio"]
                if c in data.columns
            ]

        elif self.feature_mode == "All KAMM orders":
            feature_cols = []

            if 1 in self.kamm_order:
                feature_cols += [
                    c for c in ["KAMM","KAEM","KAPM","KAMM_RATIO","KAMM_NORMPROD"]
                    if c in data.columns
                ]
            if 2 in self.kamm_order:
                feature_cols += [
                    c for c in ["KAMM_2","KAEM_2","KAPM_2","KAMM_RATIO_2","KAMM_NORMPROD_2"]
                    if c in data.columns
                ]

        elif self.feature_mode.startswith("All features"):
            feature_cols = []

            # mechanical
            mech = ["HARDNESS_GPa","MODULUS_GPa","H/E_ratio","H^3/E^2_ratio"]
            feature_cols += [c for c in mech if c in data.columns]

            # 1st order KAMM always included
            first_order = ["KAMM","KAEM","KAPM","KAMM_RATIO","KAMM_NORMPROD"]
            feature_cols += [c for c in first_order if c in data.columns]

            # 2nd order always included
            second_order = ["KAMM_2","KAEM_2","KAPM_2","KAMM_RATIO_2","KAMM_NORMPROD_2"]
            feature_cols += [c for c in second_order if c in data.columns]

        elif self.feature_mode == "Custom selection":
            feature_cols = [f for f in self.custom_features if f in data.columns]

        else:
            feature_cols = []

        if not feature_cols:
            print("⚠️ No valid features found. Falling back to H–E.")
            feature_cols = [
                c for c in ["HARDNESS_GPa", "MODULUS_GPa"] if c in data.columns
            ]

        self._last_feature_cols = feature_cols
        print("📌 Features used for clustering:", feature_cols)

        # --- raw (unscaled) features used for clustering ---
        X_raw = data[feature_cols].copy()
        X_raw = X_raw.apply(pd.to_numeric, errors="coerce")
        X_raw = X_raw.replace([np.inf, -np.inf], np.nan)

        # Fill NaNs (choose your policy; this matches your current intent)
        X_raw = X_raw.fillna(X_raw.mean()).fillna(0)

        # --- store scaler stats ---
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X_raw)

        self._scaler = scaler
        self._scaler_feature_cols = feature_cols.copy()
        self._scaler_mean = dict(zip(feature_cols, scaler.mean_.tolist()))
        self._scaler_std  = dict(zip(feature_cols, scaler.scale_.tolist()))

        # Keep for downstream if you want
        self._pca_input_feature_cols = feature_cols.copy()
        self._pca_input_matrix = X_scaled.copy()

        # --- PCA if enabled ---
        if self.enable_pca and len(feature_cols) > 1:
            pca = PCA(n_components=min(3, len(feature_cols)), random_state=0)
            X_scaled = pca.fit_transform(X_scaled)

            self._pca_model = pca
            self._pca_components = pca.components_.tolist()
            self._pca_explained_var = pca.explained_variance_.tolist()
            self._pca_explained_var_ratio = pca.explained_variance_ratio_.tolist()
            print(f"🔷 PCA applied → {pca.n_components_} components")
        else:
            self._pca_model = None
            print("🔷 PCA skipped")

        # Clustering backend selection
        method_lower = method.lower()
        try:
            if "kmeans" in method_lower:
                labels = KMeans(
                    n_clusters=n_clusters,
                    random_state=0,
                    n_init=10,
                ).fit_predict(X_scaled)

            elif "gmm" in method_lower:
                labels = GaussianMixture(
                    n_components=n_clusters,
                    random_state=0,
                ).fit_predict(X_scaled)

            elif "dbscan" in method_lower:
                labels = DBSCAN(eps=0.3, min_samples=10).fit_predict(X_scaled)

            elif "agglomerative" in method_lower:
                labels = AgglomerativeClustering(n_clusters=n_clusters).fit_predict(
                    X_scaled
                )

            elif "optics" in method_lower:
                optics = OPTICS(
                    min_samples=10,
                    xi=0.05,
                    min_cluster_size=0.05,
                ).fit(X_scaled)
                labels = optics.labels_

                # reassign noise label (-1) to a new cluster index
                if -1 in labels:
                    noise_mask = labels == -1
                    labels[noise_mask] = labels.max() + 1

            else:
                raise ValueError(f"Unknown method: {method}")

        except Exception as e:
            print(f"⚠️ {method} failed: {e}. Falling back to KMeans.")
            labels = KMeans(
                n_clusters=n_clusters,
                random_state=0,
                n_init=10,
            ).fit_predict(X_scaled)

        data["Cluster"] = labels
        return data

    # ========================================================
    # JSON SUMMARY PREPARATION
    # ========================================================
    def _prepare_phase_result_json(
        self,
        phase_stats: pd.DataFrame,
        phase_map: Dict[Any, str],
        method: str,
        silhouette: float,
        calinski: float,
        davies: float,
        n_clusters: int,
        data: pd.DataFrame,
    ) -> Dict[str, Any]:
        """Build phase-centric JSON structure for MI export and archiving."""

        cluster_volume = data["Cluster"].value_counts(normalize=True).mul(100).to_dict()

        if phase_stats is None or phase_stats.empty:
            return {
                "Phases": [],
                "Clustering Metadata": {
                    "Method": method,
                    "Cluster Count": int(n_clusters),
                    "Silhouette": silhouette,
                    "Calinski-Harabasz": calinski,
                    "Davies-Bouldin": davies,
                    "Feature Mode": self.feature_mode,
                },
            }

        phase_stats = phase_stats.copy()
        phase_stats.columns = [
            "_".join(col).strip() if isinstance(col, tuple) else col
            for col in phase_stats.columns
        ]

        def _find_col(contains_all: List[str]) -> Optional[str]:
            req = [s.upper() for s in contains_all]
            for c in phase_stats.columns:
                cu = str(c).upper()
                if all(r in cu for r in req):
                    return c
            return None

        hardness_mean_col = _find_col(["HARDNESS", "MEAN"])
        modulus_mean_col  = _find_col(["MODULUS", "MEAN"])
        hardness_std_col  = _find_col(["HARDNESS", "STD"])
        modulus_std_col   = _find_col(["MODULUS", "STD"])

        he_mean_col   = _find_col(["H/E_RATIO_RAW", "MEAN"])
        he_std_col    = _find_col(["H/E_RATIO_RAW", "STD"])
        h3e2_mean_col = _find_col(["H^3/E^2_RATIO_RAW", "MEAN"])
        h3e2_std_col  = _find_col(["H^3/E^2_RATIO_RAW", "STD"])

        required = [hardness_mean_col, modulus_mean_col, hardness_std_col, modulus_std_col]
        if any(c is None for c in required):
            return {
                "Phases": [],
                "Clustering Metadata": {
                    "Method": method,
                    "Cluster Count": int(n_clusters),
                    "Cluster Number Mode": "AUTO" if self.auto_cluster_num else "MANUAL",
                    "Feature Mode": self.feature_mode,
                    "Feature Columns Used": self._last_feature_cols or [],
                    "PCA Enabled": bool(self.enable_pca),
                    "Silhouette": silhouette,
                    "Calinski-Harabasz": calinski,
                    "Davies-Bouldin": davies,
                    "Scaling": {
                        "Method": "StandardScaler",
                        "Feature Columns Used": self._scaler_feature_cols or (self._last_feature_cols or []),
                        "Mean": self._scaler_mean or {},
                        "Std": self._scaler_std or {},
                    },
                    "PCA": (
                        None if self._pca_model is None else {
                            "n_components": int(self._pca_model.n_components_),
                            "explained_variance_ratio": self._pca_explained_var_ratio,
                            "components": self._pca_components,
                        }
                    ),
                },
            }

        phase_rows: List[Dict[str, Any]] = []
        for cluster_id, row in phase_stats.iterrows():
            phase_name = row.get("Phase_Name", f"Phase_{int(cluster_id) + 1}")

            phase_dict: Dict[str, Any] = {
                "Phase": phase_name,
                "Cluster": int(cluster_id),
                "Volume (%)": float(cluster_volume.get(cluster_id, 0.0)),
                "Hardness_Mean": float(row[hardness_mean_col]),
                "Hardness_Std": float(row[hardness_std_col]),
                "Modulus_Mean": float(row[modulus_mean_col]),
                "Modulus_Std": float(row[modulus_std_col]),
            }

            if he_mean_col is not None and he_std_col is not None:
                phase_dict["H/E_Mean"] = float(row[he_mean_col])
                phase_dict["H/E_Std"]  = float(row[he_std_col])

            if h3e2_mean_col is not None and h3e2_std_col is not None:
                phase_dict["H^3/E^2_Mean"] = float(row[h3e2_mean_col])
                phase_dict["H^3/E^2_Std"]  = float(row[h3e2_std_col])

            phase_rows.append(phase_dict)

        return {
        "Phases": phase_rows,
        "Clustering Metadata": {
            "Method": method,
            "Cluster Count": int(n_clusters),
            "Cluster Number Mode": "AUTO" if self.auto_cluster_num else "MANUAL",
            "Feature Mode": self.feature_mode,
            "Feature Columns Used": self._last_feature_cols or [],
            "PCA Enabled": bool(self.enable_pca),
            "Silhouette": silhouette,
            "Calinski-Harabasz": calinski,
            "Davies-Bouldin": davies,
            "Scaling": {
                "Method": "StandardScaler",
                "Feature Columns Used": self._scaler_feature_cols or (self._last_feature_cols or []),
                "Mean": self._scaler_mean or {},
                "Std": self._scaler_std or {},
            },
            "PCA": (
                None if self._pca_model is None else {
                    "n_components": int(self._pca_model.n_components_),
                    "explained_variance_ratio": self._pca_explained_var_ratio,
                    "components": self._pca_components,
                }
            ),
        },
    }
    
    # ========================================================
    # PREVIEW GENERATION (RAW DATA, NO CLUSTERS)
    # ========================================================
    def generate_preview(self, preview_dir: Path) -> Path:
        """Generate raw-data preview plots before clustering.

        Includes spatial maps, PDFs, CDFs, correlation matrix, and
        KAMM-based maps whenever possible.
        """
        if not self.csv_paths:
            self.load_file_list()

        csv_path = self.csv_paths[0]
        print(f"📊 Generating preview plots in: {preview_dir}")

        # Load raw CSV
        data = pd.read_csv(csv_path)

        # Header repair for specific MTS signatures
        header = list(data.columns)
        if header == ["", "Integer", "µm", "µm", "GPa", "GPa"]:
            data.columns = [
                "Markers",
                "Index",
                "X Position_µm",
                "Y Position_µm",
                "MODULUS_GPa",
                "HARDNESS_GPa",
            ]

        # Consolidate two-row artifacts
        col_fix = {
            "HARDNESS_GPa_GPa": "HARDNESS_GPa",
            "MODULUS_GPa_GPa": "MODULUS_GPa",
            "HARDNESS_(GPa)": "HARDNESS_GPa",
            "MODULUS_(GPa)": "MODULUS_GPa",
            "HARDNESS_GPa_(GPa)": "HARDNESS_GPa",
            "MODULUS_GPa_(GPa)": "MODULUS_GPa",
        }
        data.rename(columns=col_fix, inplace=True)

        # Rename common variants
        rename_map = {
            "X Position": "X Position_µm",
            "Y Position": "Y Position_µm",
            "HARDNESS": "HARDNESS_GPa",
            "MODULUS": "MODULUS_GPa",
            "H": "HARDNESS_GPa",
            "E": "MODULUS_GPa",
        }
        for old, new in rename_map.items():
            if old in data.columns and new not in data.columns:
                data.rename(columns={old: new}, inplace=True)

        # Sanitize numeric columns
        sanitize_cols = [
            "X Position_µm",
            "Y Position_µm",
            "HARDNESS_GPa",
            "MODULUS_GPa",
            "H/E_ratio",
            "H^3/E^2_ratio",
        ]
        for col in sanitize_cols:
            if col in data.columns:
                data[col] = (
                    data[col]
                    .astype(str)
                    .str.replace(",", ".", regex=False)
                    .str.replace(r"[^0-9.\-eE]", "", regex=True)
                )
                data[col] = pd.to_numeric(data[col], errors="coerce")

        # Recompute mechanical ratios if possible
        if {"HARDNESS_GPa", "MODULUS_GPa"}.issubset(data.columns):
            data["H/E_ratio"] = data["HARDNESS_GPa"] / data["MODULUS_GPa"]
            data["H^3/E^2_ratio"] = (data["HARDNESS_GPa"] ** 3) / (
                data["MODULUS_GPa"] ** 2
            )

        # Compute KAMM for preview (first order)
        try:
            data = compute_kam(data, preview_dir, order=1)
        except Exception as e:
            print(f"⚠️ KAMM computation failed (preview): {e}")

        # Backward compatibility: copy order=1 values to standard names
        if "KAMM_1" in data.columns:
            data["KAMM"] = data["KAMM_1"]
        if "KAEM_1" in data.columns:
            data["KAEM"] = data["KAEM_1"]
        if "KAPM_1" in data.columns:
            data["KAPM"] = data["KAPM_1"]
        if "KAMM_RATIO_1" in data.columns:
            data["KAMM_RATIO"] = data["KAMM_RATIO_1"]
        if "KAMM_NORMPROD_1" in data.columns:
            data["KAMM_NORMPROD"] = data["KAMM_NORMPROD_1"]

        # Compute KAMM for preview (second order)
        try:
            data_2 = compute_kam(data, preview_dir, order=2)
        except Exception as e:
            print(f"⚠️ KAMM computation failed (preview, 2nd order): {e}")
        else:
            # Merge second-order columns into the same dataframe
            for col in data_2.columns:
                if col.endswith("_2"):   # only the new second-order metrics
                    data[col] = data_2[col]

        x_dim, y_dim = self.xdim, self.ydim
        cmap = self.cmap_name

        # 1. Hardness & Modulus maps + E–H scatter
        # --- PIXEL MAPS FOR HARDNESS AND MODULUS --------------------
        if {
            "X Position_µm",
            "Y Position_µm",
            "HARDNESS_GPa",
            "MODULUS_GPa",
        }.issubset(data.columns):

            # Hardness pixel map
            plot_pixel_map(
                data["X Position_µm"],
                data["Y Position_µm"],
                data["HARDNESS_GPa"],
                title="Hardness (GPa)",
                xlabel="X (µm)",
                ylabel="Y (µm)",
                xDim=self.xdim,
                yDim=self.ydim,
                save_path=preview_dir / "preview_map_hardness.png",
            )

            # Modulus pixel map
            plot_pixel_map(
                data["X Position_µm"],
                data["Y Position_µm"],
                data["MODULUS_GPa"],
                title="Modulus (GPa)",
                xlabel="X (µm)",
                ylabel="Y (µm)",
                xDim=self.xdim,
                yDim=self.ydim,
                save_path=preview_dir / "preview_map_modulus.png",
            )

            # E–H scatter
            plt.figure(figsize=(4 * x_dim, 2 * y_dim))
            plt.scatter(
                data["HARDNESS_GPa"],
                data["MODULUS_GPa"],
                s=8,
                alpha=0.7,
            )
            plt.xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            plt.ylabel(self._mechanical_feature_label("MODULUS_GPa"))
            plt.tight_layout()
            plt.savefig(preview_dir / "preview_E_vs_H_scatter.png", dpi=300)
            plt.close()

        # 2. H/E and H³/E² maps
        if {
            "H/E_ratio",
            "H^3/E^2_ratio",
            "X Position_µm",
            "Y Position_µm",
        }.issubset(data.columns):
            fig, axes = plt.subplots(1, 2, figsize=(4 * x_dim, 2 * y_dim))

            plot_map(
                data["X Position_µm"],
                data["Y Position_µm"],
                data["H/E_ratio"],
                title="H/E ratio",
                xlabel="X",
                ylabel="Y",
                logScale=True,
                ax=axes[0],
                cmap=cmap,
            )
            plot_map(
                data["X Position_µm"],
                data["Y Position_µm"],
                data["H^3/E^2_ratio"],
                title="H³/E² ratio",
                xlabel="X",
                ylabel="Y",
                logScale=True,
                ax=axes[1],
                cmap=cmap,
            )

            plt.tight_layout()
            plt.savefig(preview_dir / "preview_2_ratios.png", dpi=300)
            plt.close()

        # 3. PDFs with GMM (H & E)
        if {"HARDNESS_GPa", "MODULUS_GPa"}.issubset(data.columns):
            fig, axes = plt.subplots(1, 2, figsize=(4 * x_dim, 2 * y_dim))

            plot_pdf_with_deconvolution_on_axis(
                data,
                "HARDNESS_GPa",
                n_components=3,
                ax=axes[0],
            )
            axes[0].set_xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            #axes[0].set_title("Hardness PDF + GMM")

            plot_pdf_with_deconvolution_on_axis(
                data,
                "MODULUS_GPa",
                n_components=3,
                ax=axes[1],
            )
            axes[1].set_xlabel(self._mechanical_feature_label("MODULUS_GPa"))
            #axes[1].set_title("Modulus PDF + GMM")

            plt.tight_layout()
            plt.savefig(preview_dir / "preview_3_pdfs.png", dpi=300)
            plt.close()

        # 4. Weibull CDFs
        fig, axes = plt.subplots(1, 2, figsize=(4 * x_dim, 2 * y_dim))
        try:
            plot_cdf_with_weibull_fit_on_axis(data, "HARDNESS_GPa", ax=axes[0])
            axes[0].set_xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            #axes[0].set_title("Hardness Weibull CDF")
            plot_cdf_with_weibull_fit_on_axis(data, "MODULUS_GPa", ax=axes[1])
            axes[1].set_xlabel(self._mechanical_feature_label("MODULUS_GPa"))
            #axes[1].set_title("Modulus Weibull CDF")
            plt.tight_layout()
            plt.savefig(preview_dir / "preview_4_weibull.png", dpi=300)
        except Exception:
            print("⚠️ Weibull CDF failed (preview).")
        plt.close()

        # 5. KAMM-related maps (if computed)
        if {"X Position_µm", "Y Position_µm"}.issubset(data.columns):

            # ---- KAMM (1st order) and KAMM_2 (2nd order) ----
            map_keys = ["KAMM", "KAMM_2"]
            available_keys = [k for k in map_keys if k in data.columns]

            fig, axes = plt.subplots(1, len(available_keys), figsize=(4 * x_dim, 2 * y_dim))
            if len(available_keys) == 1:
                axes = [axes]

            for idx, key in enumerate(available_keys):
                plot_map(
                    data["X Position_µm"],
                    data["Y Position_µm"],
                    data[key],
                    title=key,
                    xlabel="X",
                    ylabel="Y",
                    logScale=True,
                    ax=axes[idx],
                    cmap="magma",
                )

            plt.tight_layout()
            plt.savefig(preview_dir / "preview_5_kamm_maps.png", dpi=300)
            plt.close()

            # ---- KAEM & KAPM (only 1st order) ----
            ka_keys = [k for k in ["KAEM", "KAPM"] if k in data.columns]
            if ka_keys:
                fig, axes = plt.subplots(1, len(ka_keys), figsize=(4 * x_dim, 2 * y_dim))
                if len(ka_keys) == 1:
                    axes = [axes]

                for idx, key in enumerate(ka_keys):
                    plot_map(
                        data["X Position_µm"],
                        data["Y Position_µm"],
                        data[key],
                        title=key,
                        xlabel="X",
                        ylabel="Y",
                        logScale=True,
                        ax=axes[idx],
                        cmap="magma",
                    )

                plt.tight_layout()
                plt.savefig(preview_dir / "preview_6_kaem_kapm.png", dpi=300)
                plt.close()

            # ---- KAMM ratios (1st order only) ----
            ratio_keys = [k for k in ["KAMM_RATIO", "KAMM_NORMPROD"] if k in data.columns]
            if ratio_keys:
                fig, axes = plt.subplots(1, len(ratio_keys), figsize=(4 * x_dim, 2 * y_dim))
                if len(ratio_keys) == 1:
                    axes = [axes]

                for idx, key in enumerate(ratio_keys):
                    plot_map(
                        data["X Position_µm"],
                        data["Y Position_µm"],
                        data[key],
                        title=key,
                        xlabel="X",
                        ylabel="Y",
                        logScale=True,
                        ax=axes[idx],
                        cmap="magma",
                    )

                plt.tight_layout()
                plt.savefig(preview_dir / "preview_7_kamm_ratios.png", dpi=300)
                plt.close()

        # 6. Correlation matrix
        try:
            corr = data.corr(numeric_only=True)
            corr = corr.dropna(axis=0, how="all").dropna(axis=1, how="all")

            font_scale = max(0.6, min(1.2, 10 / corr.shape[0]))
            sns.set(font_scale=font_scale)

            plt.figure(figsize=(max(6, 2 * x_dim), max(4, 2 * y_dim)))
            sns.heatmap(
                corr,
                annot=True,
                annot_kws={"size": 8},
                fmt=".2f",
                cmap="coolwarm",
                cbar_kws={"shrink": 0.75},
            )
            plt.title("Correlation Matrix")
            plt.tight_layout()

            out = preview_dir / "preview_8_corr_matrix.png"
            plt.savefig(out, dpi=300)
            plt.close()
            print(f"📊 Saved preview correlation matrix → {out}")

        except Exception as e:
            print(f"⚠️ Correlation matrix failed (preview): {e}")

        print("✅ Preview generation completed.")
        return preview_dir

    # ========================================================
    # PLOTTING HELPERS (FINAL RESULTS)
    # ========================================================
    def _mechanical_feature_label(self, feature: str) -> str:
        if self.enable_manual_norm:
            labels = {
                "HARDNESS_GPa": "Normalized Hardness (H/Hmax)",
                "MODULUS_GPa": "Normalized Elastic Modulus (E/Emax)",
            }
        else:
            labels = {
                "HARDNESS_GPa": "Hardness (GPa)",
                "MODULUS_GPa": "Elastic Modulus (GPa)",
            }
        return labels.get(feature, feature)

    def _plot_EH_cluster_scatter(
        self, data: pd.DataFrame, result_dir: Path
    ) -> None:
        """Plot hardness–modulus scatter colored by cluster label."""
        try:
            plt.figure(figsize=(6, 5))
            sns.scatterplot(
                data=data,
                x="HARDNESS_GPa" if "HARDNESS_GPa" in data.columns else "HARDNESS",
                y="MODULUS_GPa" if "MODULUS_GPa" in data.columns else "MODULUS",
                hue="Cluster",
                palette=self._cluster_palette(data),
                s=12,
                alpha=0.8,
                legend=True,
            )
            plt.title("Clusters in E–H Space")
            plt.xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            plt.ylabel(self._mechanical_feature_label("MODULUS_GPa"))
            plt.tight_layout()

            out_path = result_dir / "cluster_scatter_EH.png"
            plt.savefig(out_path, dpi=300)
            plt.close()
            print(f"📊 Saved E–H cluster scatter → {out_path}")
        except Exception as e:
            print(f"⚠️ Failed in _plot_EH_cluster_scatter: {e}")

    def _plot_spatial_cluster_map(
        self, data: pd.DataFrame, result_dir: Path
    ) -> None:
        """Plot spatial cluster map on the indentation grid."""
        try:
            if {"X Position_µm", "Y Position_µm"}.issubset(data.columns):
                plot_pixel_map(
                    data["X Position_µm"],
                    data["Y Position_µm"],
                    data["Cluster"],
                    title="Spatial Cluster Map",
                    xDim=self.xdim,
                    yDim=self.ydim,
                    cluster_colors=self._build_color_map(
                        data["Cluster"].nunique()
                    ),
                    save_path=result_dir / "spatial_clusters.png",
                )
                print(
                    f"📊 Saved spatial cluster map → {result_dir / 'spatial_clusters.png'}"
                )
            else:
                print(
                    "⚠️ Spatial coordinates missing → cannot plot spatial cluster map."
                )
        except Exception as e:
            print(f"⚠️ Failed in _plot_spatial_cluster_map: {e}")

    def _plot_correlation_matrix(self, data: pd.DataFrame, result_dir: Path) -> None:
        """Plot correlation matrix only for the features actually used in clustering."""
        try:
            feature_cols = self._last_feature_cols or []
            feature_cols = [f for f in feature_cols if f in data.columns]

            if len(feature_cols) < 2:
                print("⚠ Not enough valid features for correlation matrix.")
                return

            corr = data[feature_cols].corr(numeric_only=True)

            plt.figure(figsize=(max(6, 2*self.xdim), max(4, 2*self.ydim)))
            sns.heatmap(
                corr,
                annot=True,
                fmt=".2f",
                cmap="coolwarm",
                cbar_kws={"shrink": 0.75}
            )
            plt.title("Correlation Matrix (Clustering Features Only)")
            plt.tight_layout()

            outpath = result_dir / "correlation_matrix.png"
            plt.savefig(outpath, dpi=300)
            plt.close()
            print(f"📊 Saved correlation matrix → {outpath}")

        except Exception as e:
            print(f"⚠ Correlation matrix failed: {e}")

    def _plot_composite_figure(
        self, data: pd.DataFrame, k: int, result_dir: Path
    ) -> None:
        """Plot composite figure: PDFs, pixel map, and E–H scatter."""
        try:
            colors = self._build_color_map(k)
            rank_labels = self._cluster_rank_labels(k)
            rank_by_cluster = dict(enumerate(rank_labels))

            # Pixel map grid
            if {"X Position_µm", "Y Position_µm"}.issubset(data.columns):
                grid_data = (
                    data.pivot_table(
                        index="Y Position_µm",
                        columns="X Position_µm",
                        values="Cluster",
                        aggfunc="median",
                    )
                    .sort_index(ascending=False)
                )
            else:
                grid_data = None

            cluster_cmap = ListedColormap(colors)

            # Figure layout
            fig = plt.figure(figsize=(12, 8))
            grid = fig.add_gridspec(2, 2)
            axes = np.empty((2, 2), dtype=object)
            axes[0, 0] = fig.add_subplot(grid[0, 0])
            axes[0, 1] = fig.add_subplot(grid[0, 1])
            axes[1, 0] = fig.add_subplot(grid[1, 0])
            axes[1, 1] = fig.add_subplot(grid[1, 1])

            # ============================================================
            # HARDNESS KDE: global + scaled cluster KDEs
            # ============================================================
            ax = axes[0, 0]
            feature = "HARDNESS_GPa"
            vals = data[feature].dropna()

            # Global KDE
            sns.kdeplot(
                vals,
                ax=ax,
                fill=True,
                alpha=0.25,
                color="gray",
                linewidth=2.0,
                label="Global KDE",
            )

            # Consistent grid
            x = np.linspace(vals.min(), vals.max(), 1200)

            # Cluster weights
            cluster_counts = data["Cluster"].value_counts(normalize=True).to_dict()

            # Cluster KDEs
            for i in range(k):
                subset = data.loc[data["Cluster"] == i, feature].dropna()
                if subset.shape[0] < 3:
                    continue

                # Temporary KDE on this axis
                tmp_ax = sns.kdeplot(subset, bw_method="scott", ax=ax)
                line = ax.get_lines()[-1]      # the line just drawn
                y_vals = line.get_ydata()
                x_vals = line.get_xdata()

                # Remove temporary line
                line.remove()

                # Interpolate KDE to common x-grid
                y_interp = np.interp(x, x_vals, y_vals)

                # Scale KDE by cluster fraction so it lies below global KDE
                w = cluster_counts.get(i, 1.0 / k)
                y_scaled = y_interp * w

                ax.plot(
                    x,
                    y_scaled,
                    color=colors[i],
                    linewidth=2.0,
                    alpha=0.9,
                    label=f"Cluster {i}",
                )

            ax.set_xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            ax.set_ylabel("Density")
            ax.set_title("Hardness distribution")

            # ============================================================
            # COLOR PIXEL MAP
            # ============================================================
            if grid_data is not None:
                # Flip the image vertically (top <-> bottom)
                grid_data = np.flipud(grid_data)

                axes[0, 1].imshow(
                    grid_data,
                    cmap=cluster_cmap,
                    aspect="equal",
                    interpolation="none",
                    origin="lower",   # <-- keep
                )
                axes[1, 1].set_box_aspect(axes[0, 1].get_data_ratio())

                axes[0, 1].set_xlabel("X (µm)")
                axes[0, 1].set_ylabel("Y (µm)")
                axes[0, 1].set_title("Phase map")
            else:
                axes[0, 1].set_visible(False)

            # ============================================================
            # MODULUS KDE: global + scaled cluster KDEs (vertical)
            # ============================================================
            ax = axes[1, 1]
            feature = "MODULUS_GPa"
            vals = data[feature].dropna()

            sns.kdeplot(
                y=vals,
                ax=ax,
                fill=True,
                alpha=0.25,
                color="gray",
                linewidth=2.0,
                label="Global KDE",
            )

            # Grid
            x = np.linspace(vals.min(), vals.max(), 1200)

            for i in range(k):
                subset = data.loc[data["Cluster"] == i, feature].dropna()
                if subset.shape[0] < 3:
                    continue

                # Temporary KDE
                tmp_ax = sns.kdeplot(y=subset, bw_method="scott", ax=ax)
                line = ax.get_lines()[-1]
                x_vals = line.get_xdata()    # density values
                y_vals = line.get_ydata()    # modulus values

                # Remove temporary line
                line.remove()

                # Interpolate onto modulus axis grid
                y_interp = np.interp(x, y_vals, x_vals)

                # Scale
                w = cluster_counts.get(i, 1.0 / k)
                y_scaled = y_interp * w

                ax.plot(
                    y_scaled,
                    x,
                    color=colors[i],
                    linewidth=2.0,
                    alpha=0.9,
                )

            ax.set_xlabel("Density")
            ax.set_ylabel(self._mechanical_feature_label("MODULUS_GPa"))
            ax.set_title("Modulus distribution")

            # ============================================================
            # E–H scatter plot
            # ============================================================
            ranked_data = data.assign(
                HardnessRank=data["Cluster"].map(rank_by_cluster)
            )
            sns.scatterplot(
                x="HARDNESS_GPa",
                y="MODULUS_GPa",
                hue="HardnessRank",
                hue_order=rank_labels,
                palette=dict(zip(rank_labels, colors)),
                data=ranked_data,
                ax=axes[1, 0],
                legend=False,
                s=15,
                alpha=0.7,
            )
            axes[1, 0].set_xlabel(self._mechanical_feature_label("HARDNESS_GPa"))
            axes[1, 0].set_ylabel(self._mechanical_feature_label("MODULUS_GPa"))
            axes[1, 0].set_title("Clustered hardness vs modulus")

            for ax in axes.flat:
                ax.tick_params(axis="both", labelsize=10)
                ax.xaxis.label.set_size(14)
                ax.yaxis.label.set_size(14)
                ax.title.set_size(14)

            # ============================================================
            # SAVE FIGURE
            # ============================================================
            fig.subplots_adjust(
                left=0.18,
                right=0.97,
                bottom=0.16,
                top=0.91,
                wspace=0.48,
                hspace=0.48,
            )
            out = result_dir / "final_composite_figure.png"
            plt.savefig(out, dpi=300, bbox_inches="tight")
            plt.close()
            print(f"📊 Saved composite figure → {out}")

        except Exception as e:
            print(f"⚠️ Failed in _plot_composite_figure: {e}")

    def _plot_clustered_pdf(self, data, feature, colors, result_dir):
        """
        Plot global PDF and per-cluster PDFs using same colors as cluster map.
        Saves a single combined figure.
        """
        plt.figure(figsize=(7, 5))

        # --- Global KDE (gray)
        sns.kdeplot(
            data=data[feature],
            fill=True,
            color="gray",
            alpha=0.3,
            label="Global PDF"
        )

        # --- Per-cluster PDFs
        clusters = sorted(data["Cluster"].unique())
        for i, c in enumerate(clusters):
            subset = data.loc[data["Cluster"] == c, feature]
            if subset.dropna().shape[0] < 2:
                continue  # KDE needs >1 point

            sns.kdeplot(
                data=subset,
                color=colors[i],
                linewidth=2.0,
                label=f"Cluster {c}"
            )

        plt.xlabel(self._mechanical_feature_label(feature))
        plt.ylabel("Density")
        plt.title(f"{feature} — Global PDF + Cluster PDFs")
        plt.legend()
        out = result_dir / f"clustered_pdf_{feature}.png"
        plt.tight_layout()
        plt.savefig(out, dpi=300)
        plt.close()
        print(f"📊 Saved clustered PDF for {feature} → {out}")

    def _plot_pca_clusters(self, data: pd.DataFrame, k: int, result_dir: Path) -> None:
        """Plot clusters in PCA space (PC1 vs PC2)."""
        try:
            if not self._last_feature_cols:
                print("⚠️ No feature list for PCA — skipping PCA cluster plot.")
                return

            X = data[self._last_feature_cols].replace([np.inf, -np.inf], np.nan)
            X = X.fillna(X.mean())
            X_scaled = StandardScaler().fit_transform(X)

            pca = PCA(n_components=2, random_state=0)
            pcs = pca.fit_transform(X_scaled)

            pc_df = pd.DataFrame(
                {
                    "PC1": pcs[:, 0],
                    "PC2": pcs[:, 1],
                    "Cluster": data["Cluster"].values,
                }
            )

            colors = self._build_color_map(k_actual)

            plt.figure(figsize=(6, 5))
            for c in range(k):
                mask = pc_df["Cluster"] == c
                plt.scatter(
                    pc_df.loc[mask, "PC1"],
                    pc_df.loc[mask, "PC2"],
                    s=12,
                    color=colors[c],
                    label=f"Cluster {c}",
                )
            plt.xlabel("PC1")
            plt.ylabel("PC2")
            plt.title("PCA — Clusters in Feature Space")
            plt.legend()
            plt.tight_layout()

            out = result_dir / "pca_clusters.png"
            plt.savefig(out, dpi=300)
            plt.close()
            print(f"📊 Saved PCA clusters → {out}")
        except Exception as e:
            print(f"⚠️ Failed in _plot_pca_clusters: {e}")

    def _plot_pca_spatial_map(
        self, data: pd.DataFrame, k: int, result_dir: Path
    ) -> None:
        """Plot spatial cluster map (PCA-consistent colors)."""
        try:
            if not {"X Position_µm", "Y Position_µm"}.issubset(data.columns):
                print("⚠️ Missing spatial coordinates — skipping PCA spatial map.")
                return

            colors = self._build_color_map(k)
            plot_pixel_map(
                data["X Position_µm"],
                data["Y Position_µm"],
                data["Cluster"],
                xlabel="X (µm)",
                ylabel="Y (µm)",
                cluster_colors=colors,
                title="Spatial Cluster Map (PCA colors)",
                xDim=self.xdim,
                yDim=self.ydim,
                save_path=result_dir / "spatial_clusters_pca.png",
            )
            print(
                f"📊 Saved PCA spatial cluster map → {result_dir / 'spatial_clusters_pca.png'}"
            )
        except Exception as e:
            print(f"⚠️ Failed in _plot_pca_spatial_map: {e}")

    # ========================================================
    # EXPORT HELPERS (CSV + PNG + MI)
    # ========================================================
    def _export_results(
        self, data: pd.DataFrame, phase_stats: pd.DataFrame, result_dir: Path
    ) -> None:
        """Export clustered data and phase statistics to CSV files."""
        
        # ---- Export CSV with clusters and phases ----
        try:
            csv_out = result_dir / "data_with_clusters_and_phases.csv"
            data.to_csv(csv_out, index=False)
            print(f"💾 Saved clustered data → {csv_out}")
        except Exception as e:
            print(f"⚠️ Failed to export clustered CSV: {e}")

        # ---- Export PNG phase map ----
        try:
            png_out = result_dir / "phase_map.png"
            if phase_stats is not None and not phase_stats.empty:
                plot_pixel_map(
                    data["X Position_µm"],
                    data["Y Position_µm"],
                    data["Phase"],             # <-- correct field
                    "Phase Map",
                    "X (µm)",
                    "Y (µm)",
                    self.xdim,
                    self.ydim,
                    cluster_colors=None,
                    save_path=png_out
                )
                print(f"💾 Saved phase map → {png_out}")
            else:
                print("⚠️ Phase stats empty — skipping phase map.")
        except Exception as e:
            print(f"⚠️ Failed to plot phase map: {e}")

        # ---- Export phase statistics CSV ----
        try:
            if phase_stats is not None and not phase_stats.empty:
                phase_csv = result_dir / "phase_statistics.csv"
                phase_stats.to_csv(phase_csv)
                print(f"💾 Saved phase stats → {phase_csv}")
        except Exception as e:
            print(f"⚠️ Failed to export phase stats CSV: {e}")

    def export(self) -> None:
        """Backward-compatible no-op method."""
        return

    def export_to_mi(
        self,
        mi: MIClient,
        table_name: str,
        record_name_prefix: str = "Clustering",
    ) -> Any:
        """Export clustering results to Granta MI using MIClient."""
        import pandas as pd  # local import (already available globally)

        if self.data_clustered is None:
            raise RuntimeError("No clustered data available. Run run_pipeline() first.")

        table = mi.get_table(table_name)

        json_path = self.outdir / "cluster_statistics_phases.json"
        if not json_path.exists():
            raise RuntimeError(f"JSON summary file not found: {json_path}")

        with open(json_path, "r") as f:
            json_data = json.load(f)

        meta = json_data.get("Clustering Metadata", {})
        method = meta.get("Method", "UnknownMethod")

        # Build phases TABL attribute
        phases_list = json_data.get("Phases", [])
        if isinstance(phases_list, list) and len(phases_list) > 0:
            phases_df = pd.DataFrame(phases_list)[
                [
                    "Phase",
                    "Cluster",
                    "Volume (%)",
                    "Hardness_Mean",
                    "Hardness_Std",
                    "Modulus_Mean",
                    "Modulus_Std",
                ]
            ]
        else:
            phases_df = None

        # Clean dataset filename → safe base name
        def make_safe_name(name: str) -> str:
            safe = "".join(c if c.isalnum() or c in "-_ " else "_" for c in name)
            return safe.strip() if safe.strip() else "Dataset"

        try:
            if hasattr(self, "csv_paths") and self.csv_paths:
                dataset_file = self.csv_paths[0]
            else:
                dataset_file = ""
        except Exception:
            dataset_file = ""

        raw_name = Path(dataset_file).stem
        safe_folder = make_safe_name(raw_name)

        base_name = f"{safe_folder}_{record_name_prefix}_{method}"
        record, exists = mi.get_or_create_record_flat(mi.db, table, base_name)

        # Clear attributes if record already exists
        if exists:
            attributes_to_clear = [
                "File used for clustering analysis",
                "Clustering Method",
                "Cluster Number Mode",
                "Feature Mode",
                "Feature Normalization",
                "Feature Columns Used",
                "PCA Enabled",
                "Cluster Count",
                "Silhouette",
                "Calinski-Harabasz",
                "Davies-Bouldin",
                "Correlation Matrix",
                "E vs H and Phase maps",
                "Link to results",
                "Phases",
            ]
            record = mi.clear_record(record, base_name, attributes_to_clear)

        corr_file = self.outdir / "correlation_matrix.png"
        composite_file = self.outdir / "final_composite_figure.png"
        results_link = str(self.outdir)

        def safe_float(x):
            try:
                return float(x)
            except Exception:
                return None

        def safe_text(x):
            return "unknown" if x is None or str(x).strip() == "" else str(x)

        inputs = {
            "File used for clustering analysis": safe_text(Path(dataset_file).name),
            "Clustering Method": safe_text(meta.get("Method")),
            "Cluster Number Mode": safe_text(meta.get("Cluster Number Mode")),
            "Feature Mode": safe_text(meta.get("Feature Mode")),
            "Feature Normalization": safe_text(json_data.get("Feature Normalization")),
            "Feature Columns Used": ", ".join(meta.get("Feature Columns Used", [])),
            "PCA Enabled": safe_text(meta.get("PCA Enabled")),
            "Cluster Count": safe_float(meta.get("Cluster Count")),
            "Silhouette": safe_float(meta.get("Silhouette")),
            "Calinski-Harabasz": safe_float(meta.get("Calinski-Harabasz")),
            "Davies-Bouldin": safe_float(meta.get("Davies-Bouldin")),
            "Correlation Matrix": str(corr_file) if corr_file.exists() else None,
            "E vs H and Phase maps": (
                str(composite_file) if composite_file.exists() else None
            ),
            "Link to results": results_link,
            "Phases": phases_df,
        }

        inputs_df = pd.DataFrame(
            {"Inputs values": list(inputs.values())},
            index=list(inputs.keys()),
        )

        results = mi.write_attributes(record, inputs_df)
        updated_record = mi.update_record(record, results)
        return updated_record

    def _export_raw_clustered_json(self, data: pd.DataFrame, result_dir: Path) -> None:
        """
        Export per-point raw (UNSCALED) values after clustering/phase assignment,
        plus scaler mean/std (and optional PCA metadata).
        """
        try:
            # What features were used for clustering (raw units)
            feature_cols = self._scaler_feature_cols or self._last_feature_cols or []
            feature_cols = [c for c in feature_cols if c in data.columns]

            # Minimal, useful per-point columns
            base_cols = []
            for c in ["X Position_µm", "Y Position_µm", "Markers", "Index"]:
                if c in data.columns:
                    base_cols.append(c)

            export_cols = base_cols + feature_cols
            for c in ["Cluster", "Phase"]:
                if c in data.columns and c not in export_cols:
                    export_cols.append(c)
            # add raw mechanical columns if present
            for c in ["HARDNESS_GPa_RAW", "MODULUS_GPa_RAW"]:
                if c in data.columns and c not in export_cols:
                    export_cols.append(c)

            # Convert to JSON records (careful with NaN)
            df_out = data[export_cols].copy()
            df_out = df_out.replace({np.nan: None})

            payload = {
                "Raw Data (Unscaled)": df_out.to_dict(orient="records"),
                "Scaling (StandardScaler)": {
                    "Feature Columns Used": feature_cols,
                    "Mean": self._scaler_mean or {},
                    "Std": self._scaler_std or {},
                },
            }

            # Optional PCA metadata
            if self._pca_model is not None:
                payload["PCA"] = {
                    "n_components": int(self._pca_model.n_components_),
                    "explained_variance": self._pca_explained_var,
                    "explained_variance_ratio": self._pca_explained_var_ratio,
                    "components": self._pca_components,
                }

            out_json = result_dir / "raw_clustered_data_unscaled.json"
            out_jsonl = result_dir / "raw_clustered_data_unscaled.jsonl"

            if len(df_out) > 200_000:
                # stream as JSONL
                with out_jsonl.open("w") as f:
                    for rec in df_out.to_dict(orient="records"):
                        f.write(json.dumps(rec, default=str, allow_nan=False) + "\n")
                print(f"💾 Saved raw unscaled clustered JSONL → {out_jsonl}")
                return

            with out_json.open("w") as f:
                json.dump(payload, f, indent=2, default=str, allow_nan=False)
            print(f"💾 Saved raw unscaled clustered JSON → {out_json}")

        except Exception as e:
            print(f"⚠️ Failed raw clustered JSON export: {e}")

    def _relabel_clusters_consecutive(self, data: pd.DataFrame) -> pd.DataFrame:
        """Order clusters by mean hardness, then relabel them 0..k-1."""
        if "Cluster" not in data.columns:
            return data

        unique_labels = sorted(pd.unique(data["Cluster"]))
        hardness_col = next(
            (
                col
                for col in ("HARDNESS_GPa_RAW", "HARDNESS_GPa")
                if col in data.columns
            ),
            None,
        )

        if hardness_col is not None:
            hardness = pd.to_numeric(data[hardness_col], errors="coerce")
            mean_hardness = hardness.groupby(data["Cluster"]).mean()
            ordered_labels = mean_hardness.sort_values(
                kind="stable", na_position="last"
            ).index.tolist()
        else:
            ordered_labels = unique_labels

        mapping = {old: new for new, old in enumerate(ordered_labels)}
        data["Cluster"] = data["Cluster"].map(mapping).astype(int)
        return data

    # ========================================================
    # GRID SEARCH: METHODS × FEATURE MODES
    # ========================================================
    def run_all_combinations(
        self,
        methods_list: List[str],
        feature_modes_list: List[str],
    ) -> pd.DataFrame:
        """
        Run clustering over all combinations of methods × feature modes.
        Ensure each run is fully independent (no state leaking between iterations).
        """

        results: List[Dict[str, Any]] = []

        # Always reload from original CSV once for reference
        original_clean_csv = self.csv_paths[-1] if self.csv_paths else None

        for m in methods_list:
            for fm in feature_modes_list:
                print(f"➡ Running combination: {m} × {fm}")

                # ============================================================
                # FULL RESET OF PIPELINE STATE  (*** CRITICAL FIX ***)
                # ============================================================
                self.data_cleaned = None
                self.data_clustered = None
                self._last_feature_cols = None
                self.csv_paths = []            # avoid path accumulation
                if hasattr(self, "pca_model"):  # force recompute PCA
                    self._pca_model = None

                # Always reload original cleaned CSV for each combination
                if original_clean_csv:
                    self.csv_paths = [original_clean_csv]

                # ============================================================
                # SET COMBINATION PARAMETERS
                # ============================================================
                self.methods = [m]
                self.feature_mode = fm
                self.custom_features = []       # prevent custom-leak between runs
                self.compute_kamm = any(
                    keyword in fm
                    for keyword in ["KAMM", "All KAMM orders"]
                )
                # ============================================================
                # RUN PIPELINE
                # ============================================================
                try:
                    self.run_pipeline()
                except Exception as e:
                    print(f"⚠ Combination failed: {m}, {fm}: {e}")
                    continue

                # ============================================================
                # LOAD OUTPUT METADATA
                # ============================================================
                json_path = self.outdir / "cluster_statistics_phases.json"
                try:
                    with open(json_path, "r") as f:
                        data = json.load(f)
                except Exception as e:
                    print(f"⚠ Failed to load stats JSON for {m}, {fm}: {e}")
                    continue

                meta = data.get("Clustering Metadata", {})

                # ============================================================
                # COMPUTE MAX FEATURE-FEATURE CORRELATION
                # using only features active *for that combination*
                # ============================================================
                maxcorr = np.nan
                corr_pair = None

                try:
                    feature_cols = self._last_feature_cols or []
                    feature_cols = [f for f in feature_cols if f in self.data_cleaned.columns]

                    if len(feature_cols) > 1:
                        corr = self.data_cleaned[feature_cols].corr(numeric_only=True)
                        cm = np.abs(corr.to_numpy())
                        np.fill_diagonal(cm, np.nan)

                        maxcorr = np.nanmax(cm)
                        pos = np.where(cm == maxcorr)

                        if len(pos[0]):  # found valid pair
                            i, j = pos[0][0], pos[1][0]
                            corr_pair = f"{corr.columns[i]} – {corr.columns[j]}"

                except Exception as e:
                    print(f"⚠ Failed correlation extraction: {e}")

                # ============================================================
                # STORE RESULT ENTRY
                # ============================================================
                results.append(
                    {
                        "method": m,
                        "feature_mode": fm,
                        "cluster_count": meta.get("Cluster Count", np.nan),
                        "silhouette": meta.get("Silhouette", np.nan),
                        "calinski": meta.get("Calinski-Harabasz", np.nan),
                        "davies": meta.get("Davies-Bouldin", np.nan),
                        "max_feature_correlation": maxcorr,
                        "max_corr_feature_pair": corr_pair,
                        "path": str(self.outdir),
                    }
                )

        # ============================================================
        # BUILD RESULTS TABLE
        # ============================================================
        df = pd.DataFrame(results)

        if df.empty:
            return df

        # ============================================================
        # BEST FEATURE MODE PER METHOD (by silhouette)
        # ============================================================
        best = (
            df.loc[df.groupby("method")["silhouette"].idxmax()][
                ["method", "feature_mode"]
            ]
            .rename(columns={"feature_mode": "best_feature_for_method"})
        )

        df = df.merge(best, on="method", how="left")

        # Final sorting (best first)
        df = df.sort_values(by="silhouette", ascending=False)

        return df

if __name__ == "__main__":
    # Script is primarily intended to be used as a library from Streamlit.
    pass

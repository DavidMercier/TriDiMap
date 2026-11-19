# ============================================================
# IMPORTS AND GLOBALS
# ============================================================
import os
import io
import time
import zipfile
import tempfile
from pathlib import Path

import pandas as pd
import numpy as np
import plotly.express as px
import streamlit as st
from streamlit_plotly_events import plotly_events

from clustering_app.clustering_pipeline import clustering_pipeline
from clustering_app.MI_client import MIClient

# initialize Plotly selection events in session state
st.session_state.setdefault("plotly_selected", None)

APP_DIR = Path(__file__).resolve().parent              # .../clustering_app
PROJECT_ROOT = APP_DIR.parent                          # project root (same level as doc/)
ICON_DIR = APP_DIR.parent                              # project root (kept for compatibility with your assets pathing)
config_path = APP_DIR / "mi_config.json"

# Documentation (Markdown) location: ../doc/clustering_process.md
DOC_MD_PATH = PROJECT_ROOT / "doc" / "clustering_process.md"

# ============================================================
# STREAMLIT CONFIGURATION
# ============================================================
st.set_page_config(
    page_title="ClusterLab: an ICME Multiphase Material Clustering",
    page_icon="assets/clustering.ico",
    layout="wide",
)

# ============================================================
# CUSTOM CSS
# ============================================================
st.markdown(
    """
    <style>
    h1, h2, h3, h4 {
        color: #002b5c;
        font-family: "Segoe UI";
    }
    .stButton>button {
        background: linear-gradient(90deg, #005b96, #0074b8);
        color: white;
        border-radius: 6px;
        border: none;
        padding: 0.5rem 1.25rem;
        font-weight: 600;
    }
    .stButton>button:hover {
        background: linear-gradient(90deg, #004373, #005b96);
        color: white;
    }
    </style>
    """,
    unsafe_allow_html=True,
)

# ============================================================
# HEADER
# ============================================================
left, right = st.columns([0.15, 0.85])
with left:
    st.image(ICON_DIR / "assets" / "clustering.ico", width=140)
with right:
    st.markdown("## ICME Multiphase Material Clustering Platform")
    st.markdown(
        "A workflow for multiscale-material unsupervised phase clustering "
        "including Kernel Average Mechanical Mismatch (KAMM)."
    )
st.markdown("---")

# ============================================================
# SIDEBAR — PIPELINE SETTINGS
# ============================================================
st.sidebar.header("⚙️ Pipeline Settings")

# store uploaded file in session
if "base_file" not in st.session_state:
    st.session_state.base_file = None

uploaded = st.sidebar.file_uploader(
    "Upload dataset (CSV, XLS, XLSX)",
    type=["csv", "xls", "xlsx"],
)
if uploaded:
    st.session_state.base_file = uploaded
    st.sidebar.success(f"Loaded: {uploaded.name}")

# ============================================================
# FEATURE SPACE SELECTION (MULTI-SELECT)
# ============================================================
feature_modes_selected = st.sidebar.multiselect(
    "Feature spaces for clustering",
    [
        "E vs H",
        "E vs H vs KAMM (recommended)",
        "Mechanical features (H, E, H/E, H³/E²)",
        "All features (H, E, H/E, H³/E², KAMM, KAEM, KAPM, KAMM_RATIO, KAMM_NORMPROD)",
        "Custom selection",
    ],
    default=[
        "All features (H, E, H/E, H³/E², KAMM, KAEM, KAPM, KAMM_RATIO, KAMM_NORMPROD)",
    ],
)

# For single-method runs, we need only ONE feature mode → pick the first chosen
feature_mode_single = feature_modes_selected[0] if len(feature_modes_selected) > 0 else None

# Custom feature list (optional)
custom_features = []
if "Custom selection" in feature_modes_selected:
    custom_features = st.sidebar.multiselect(
        "Select custom features",
        [
            "HARDNESS_GPa",
            "MODULUS_GPa",
            "H/E_ratio",
            "H^3/E^2_ratio",
            "KAMM",
            "KAEM",
            "KAPM",
            "KAMM_RATIO",
            "KAMM_NORMPROD",
        ],
        default=["HARDNESS_GPa", "MODULUS_GPa"],
    )

# Determine if KAMM order needed
show_kamm_order = any(
    keyword in fm
    for fm in feature_modes_selected
    for keyword in ["KAMM", "KAEM", "KAPM", "KAMM_RATIO", "KAMM_NORMPROD"]
) or any(
    f in ["KAMM", "KAEM", "KAPM", "KAMM_RATIO", "KAMM_NORMPROD"]
    for f in custom_features
)

if show_kamm_order:
    sel = st.sidebar.selectbox(
        "KAMM Metric Order",
        ["1st order", "2nd order", "1st + 2nd order"]
    )

    if sel == "1st order":
        kamm_order = [1]
    elif sel == "2nd order":
        kamm_order = [2]
    else:
        kamm_order = [1, 2]   # compute both
else:
    kamm_order = 0

# normalization and PCA options
enable_norm = st.sidebar.checkbox("Apply feature normalization", value=True)
use_pca = st.sidebar.checkbox("Apply PCA before clustering", value=False)

# clustering method selection
methods_list = [
    "KMeans",
    "GMM",
    "DBSCAN",
    "AgglomerativeClustering",
    "OPTICS",
    "Run all combinations (recommend best)",
]

method = st.sidebar.selectbox(
    "Clustering method",
    methods_list,
)

# Automatically deactivate OPTICS inside combinations mode
if method == "Run all combinations (recommend best)":
    st.sidebar.warning("OPTICS is disabled in 'all combinations' mode.")

# note on density-based methods
if method in ["DBSCAN", "OPTICS", "Run all combinations (recommend best)"]:
    st.sidebar.info("ℹ️ The number of clusters does **not apply** to DBSCAN or OPTICS.")

# toggle for automatic cluster detection
auto_k = st.sidebar.checkbox("Automatic cluster detection", value=False)

# disable manual K for DBSCAN/OPTICS
disable_manual_k = method in ["DBSCAN", "OPTICS"]

manual_k = st.sidebar.number_input(
    "Clusters (manual)",
    min_value=1,
    max_value=20,
    value=3,
    disabled=(auto_k or disable_manual_k),
)

# ============================================================
# UTILITY FUNCTIONS
# ============================================================
def list_pngs(folder: Path):
    """Return a sorted list of PNG files in a folder."""
    p = Path(folder)
    return sorted(p.glob("*.png")) if p.exists() else []


def resolve_path(uploaded_file):
    """Save uploaded file to a temporary directory and return its path."""
    if uploaded_file is None:
        return None
    temp = tempfile.mkdtemp()
    dest = Path(temp) / uploaded_file.name
    with open(dest, "wb") as f:
        f.write(uploaded_file.getbuffer())
    return dest


def save_filtered_to_temp_csv(df: pd.DataFrame) -> str:
    """Save dataframe to a temporary CSV and return its path."""
    fd, temp_path = tempfile.mkdtemp(suffix=".csv", prefix="filtered_dataset_"), None
    # mkstemp returns (fd, path)
    if isinstance(fd, tuple):
        fd, temp_path = fd
    else:
        # compatibility, though mkstemp always returns tuple
        fd, temp_path = fd, tempfile.mkstemp(suffix=".csv", prefix="filtered_dataset_")[1]
    os.close(fd)
    df.to_csv(temp_path, index=False)
    return temp_path


# ============================================================
# TAB LAYOUT
# ============================================================
tab_home, tab_preview, tab_run, tab_results, tab_export, tab_help = st.tabs(
    ["🏠 Home", "🔍 Preview Data", "🚀 Run Pipeline", "📊 Results", "📦 Export", "❓ Help / Docs"]
)

# ============================================================
# HOME TAB
# ============================================================
with tab_home:
    st.markdown("### Overview")
    st.markdown(
        """
        * Load indentation datasets (CSV, XLS, XLSX) with hardness (H) and modulus (E) data vs. spatial coordinates.
        * Visualize spatial maps and raw statistics.
        * Compute and add Kernel Average Mechanical Mismatch (KAMM) features.
        * Perform clustering (KMeans, GMM, DBSCAN, Agglomerative, OPTICS) in various feature spaces.
        * Evaluate clustering quality (Silhouette, Calinski–Harabasz, Davies–Bouldin).
        * Select the best model or run all combinations.
        * Generate PCA and composite maps.
        * Export full data and figures.
        * Export results directly to a .zip file or to a Granta MI Micro-Materials Database.
        * Export .stl or .cdb RVE geometries for FEA based on phase maps, for Ansys or other solvers.
        """
    )

    if st.session_state.base_file:
        st.info(f"Dataset: **{st.session_state.base_file.name}**")
    else:
        st.warning("Upload a dataset in the sidebar.")

    # initialize MI connection once when entering Home tab
    if "mi_client" not in st.session_state:
        try:
            client = MIClient.from_json(config_path)
            st.session_state.mi_client = client
            st.success("Connected to Granta MI using config file")
        except Exception as e:
            st.session_state.mi_client = None
            st.error(f"❌ MI connection failed: {e}")

# ============================================================
# PREVIEW TAB
# ============================================================
with tab_preview:
    st.markdown("### 🔍 Raw Data Preview")

    if st.session_state.base_file is None:
        st.warning("Upload a dataset first.")
    else:
        # generate preview (load data and preview figures)
        if st.button("📊 Generate Preview"):
            dataset_path = resolve_path(st.session_state.base_file)

            pipeline = clustering_pipeline(
                base_dir=dataset_path,
                methods=[method],
                feature_mode=feature_mode_single,
                custom_features=custom_features,
                enable_pca=use_pca,
                enable_manual_norm=enable_norm,
                kamm_order=kamm_order,
            )

            with st.spinner("Loading and preprocessing dataset..."):
                pipeline.load()

                # use the latest cleaned csv from the pipeline
                clean_csv = pipeline.csv_paths[-1]
                df = pd.read_csv(clean_csv)

                # --- FIX: Auto-detect HARDNESS / MODULUS columns for preview ---
                def detect_col(df, possible_names):
                    for name in possible_names:
                        if name in df.columns:
                            return name
                    # case-insensitive fallback
                    low = {c.lower(): c for c in df.columns}
                    for name in possible_names:
                        if name.lower() in low:
                            return low[name.lower()]
                    return None

                hardness_col = detect_col(df, [
                    "HARDNESS_GPa", "HARDNESS", "Hardness", "Hardness (GPa)",
                    "HARDNESS_(GPa)", "HARDNESS_GPa_(GPa)", "H"
                ])

                modulus_col = detect_col(df, [
                    "MODULUS_GPa", "MODULUS", "Modulus", "Modulus (GPa)",
                    "MODULUS_(GPa)", "MODULUS_GPa_(GPa)", "E"
                ])

                if hardness_col is None or modulus_col is None:
                    st.error("❌ Could not detect Hardness / Modulus columns. Try running pipeline first.")
                    st.stop()

                df.rename(columns={hardness_col: "HARDNESS_GPa", modulus_col: "MODULUS_GPa"}, inplace=True)

                # enforce numeric types for H and E
                df["HARDNESS_GPa"] = pd.to_numeric(df["HARDNESS_GPa"], errors="coerce")
                df["MODULUS_GPa"] = pd.to_numeric(df["MODULUS_GPa"], errors="coerce")

                # store dataframe for reuse
                st.session_state.preview_df = df

                # regenerate all preview plots
                preview_dir = pipeline.preview()
                st.session_state.preview_dir = str(preview_dir)

            st.success("Preview generated!")

    # show dataset preview and a simple scatter
    if "preview_df" in st.session_state:
        df = st.session_state.preview_df

        st.markdown("### 📄 Dataset Preview (first 20 rows)")
        st.dataframe(df.head(20))

        st.markdown("### 📉 Hardness–Modulus Scatter Plot")
        fig = px.scatter(
            df,
            x="HARDNESS_GPa",
            y="MODULUS_GPa",
            title="Hardness vs. Modulus (static)",
            height=600,
        )
        fig.update_traces(marker=dict(color="black", size=6, opacity=0.8))
        st.plotly_chart(fig, use_container_width=True)

    # show auto-generated preview figures (maps, PDFs, CDFs, fits)
    if "preview_dir" in st.session_state:
        st.markdown("### 🖼 Auto-Generated Preview Figures")

        images = list_pngs(Path(st.session_state.preview_dir))
        if not images:
            st.info("No preview images found.")
        else:
            for img in images:
                st.image(str(img), caption=img.name, use_container_width=True)
                st.markdown("---")

# ============================================================
# RUN PIPELINE TAB
# ============================================================
with tab_run:
    st.markdown("### 🚀 Run Clustering Pipeline")

    if st.session_state.base_file is None:
        st.warning("Upload a dataset first.")
    else:
        if st.button("Run Pipeline Now"):

            # resolve dataset path (use filtered CSV if available)
            if "custom_csv_path" in st.session_state and st.session_state.custom_csv_path:
                dataset_path = Path(st.session_state.custom_csv_path)
                st.info("Using custom filtered dataset (E–H selection).")
            else:
                dataset_path = resolve_path(st.session_state.base_file)

            # ---------------------------------------
            # MODE 1: run all combinations
            # ---------------------------------------
            if method == "Run all combinations (recommend best)":

                # Disable OPTICS
                all_methods = ["KMeans", "GMM", "DBSCAN", "AgglomerativeClustering"]

                pipeline = clustering_pipeline(
                    base_dir=dataset_path,
                    enable_pca=use_pca,
                    enable_manual_norm=enable_norm,
                    auto_cluster_num=auto_k,
                    manual_clusters_num=manual_k,
                    kamm_order=kamm_order,
                )

                pipeline.load()

                with st.spinner("Running all methods × selected feature modes..."):
                    ranking = pipeline.run_all_combinations(all_methods, feature_modes_selected)

                st.session_state.all_results_df = ranking

                if ranking.empty:
                    st.error("No valid clustering results were produced.")
                    st.stop()

                best_row = ranking.iloc[0]
                st.session_state.best_method = best_row["method"]
                st.session_state.best_feature_mode = best_row["feature_mode"]
                st.session_state.result_dir = best_row["path"]
                best_path = Path(best_row["path"])
                best_path.mkdir(parents=True, exist_ok=True)

                ranking_csv_path = best_path / "model_ranking_best_first.csv"
                ranking.to_csv(ranking_csv_path, index=False)

                ranking_json_path = best_path / "model_ranking_best_first.json"
                ranking.to_json(ranking_json_path, orient="records", indent=2)

                st.success(f"Saved ranking to: {ranking_csv_path.name} and {ranking_json_path.name}")

                st.markdown("### 🏆 Model Ranking (best first)")
                st.dataframe(ranking)

                st.success(
                    f"Best model: **{best_row['method']} × {best_row['feature_mode']}**"
                )

                st.info(
                    """
                    ### ℹ️ How to interpret clustering scores
                    **Silhouette score (range: -1 to +1)**
                    - **+1.0** → perfectly separated clusters  
                    - **0.5** → good structure  
                    - **0.0** → overlapping clusters  
                    - **negative** → likely wrong clustering

                    **Calinski–Harabasz (no fixed range)**  
                    - higher = better cluster separation and compactness

                    **Davies–Bouldin (range ≥ 0)**  
                    - lower = better  
                    - DB ≈ 0.3 = very good  
                    - DB > 1 = weak clusters
                    """
                )

                best_path = best_row["path"]
                st.session_state.result_dir = best_path

            # ---------------------------------------
            # MODE 2: single-method execution
            # ---------------------------------------
            else:
                pipeline = clustering_pipeline(
                    base_dir=dataset_path,
                    methods=[method],
                    feature_mode=feature_mode_single,
                    custom_features=custom_features,
                    enable_pca=use_pca,
                    enable_manual_norm=enable_norm,
                    auto_cluster_num=auto_k,
                    manual_clusters_num=manual_k,
                    kamm_order=kamm_order,
                )

                start = time.time()

                with st.spinner("Running pipeline..."):
                    pipeline.load()
                    pipeline.run_pipeline()
                    pipeline.export()

                st.session_state.result_dir = str(pipeline.outdir)
                st.session_state.best_method = method
                st.session_state.best_feature_mode = feature_mode_single

                st.success(f"Pipeline completed in {time.time() - start:.1f} seconds")

                final = Path(pipeline.outdir) / "final_composite_figure.png"
                if final.exists():
                    st.image(
                        str(final),
                        caption="Final Composite Figure",
                        use_container_width=True,
                    )

# ============================================================
# RESULTS TAB
# ============================================================
with tab_results:
    st.markdown("### 📊 Clustering Results")

    if "result_dir" not in st.session_state:
        st.warning("Run the pipeline first.")
    else:
        # show selected model summary
        if "best_method" in st.session_state:
            st.markdown(
                f"### 🔎 Selected Model\n"
                f"**Method:** {st.session_state.best_method}  \n"
                f"**Feature Mode:** {st.session_state.best_feature_mode}"
            )
            st.markdown("---")

        rdir = Path(st.session_state.result_dir)
        images = list_pngs(rdir)

        order = [
            "correlation_matrix.png",
            "pca_clusters.png",
            "spatial_clusters_pca.png",
            "final_composite_figure.png",
            "cluster_scatter_EH.png",
            "spatial_clusters.png",
        ]

        for name in order:
            f = rdir / name
            if f.exists():
                st.markdown(f"#### {name.replace('_', ' ').replace('.png', '')}")
                st.image(str(f), width=600)
                st.markdown("---")

        csv_path = rdir / "data_with_clusters_and_phases.csv"
        json_path = rdir / "cluster_statistics_phases.json"

        st.markdown("### 💾 Download Results")

        if csv_path.exists():
            st.download_button(
                "Download CSV",
                csv_path.read_bytes(),
                file_name=csv_path.name,
            )

        if json_path.exists():
            st.download_button(
                "Download JSON",
                json_path.read_bytes(),
                file_name=json_path.name,
            )

# ============================================================
# EXPORT TAB
# ============================================================
with tab_export:
    # ensure MI client exists when entering Export tab
    if "mi_client" not in st.session_state:
        try:
            client = MIClient.from_json(config_path)
            st.session_state.mi_client = client
            st.success("Connected to Granta MI using config file")
        except Exception as e:
            st.session_state.mi_client = None
            st.error(f"❌ MI connection failed: {e}")

    # ---------------------------------------------------
    # First: ensure results exist
    # ---------------------------------------------------
    if "result_dir" not in st.session_state:
        st.warning("No results yet.")
    else:
        # ✅ define rdir BEFORE using it
        rdir = Path(st.session_state.result_dir)

        # ---------------------------------------------------
        # ZIP DOWNLOAD
        # ---------------------------------------------------
        st.markdown("### 📦 Export All Results")

        if st.button("Download ZIP Archive"):
            buffer = io.BytesIO()
            with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as z:
                for f in rdir.rglob("*"):
                    z.write(f, arcname=f.relative_to(rdir))
            buffer.seek(0)
            st.download_button(
                "💾 Download Results ZIP",
                buffer.getvalue(),
                "clustering_results.zip",
                "application/zip",
                key="zip_download",
            )

        # ---------------------------------------------------
        # EXPORT TO MI
        # ---------------------------------------------------
        st.markdown("### 🚀 Export Directly to Granta MI")

        if st.button("Export results directly to Granta MI"):
            try:
                mi = st.session_state.mi_client
                if mi is None:
                    raise RuntimeError("Not connected to MI")

                # choose dataset path
                if "custom_csv_path" in st.session_state and st.session_state.custom_csv_path:
                    dataset_path = Path(st.session_state.custom_csv_path)
                    st.info("Using custom filtered dataset (E–H selection) for MI export.")
                else:
                    dataset_path = resolve_path(st.session_state.base_file)

                pipeline = clustering_pipeline(
                    base_dir=dataset_path,
                    methods=[method],
                    feature_mode=feature_mode_single,
                    custom_features=custom_features,
                    enable_pca=use_pca,
                    enable_manual_norm=enable_norm,
                    auto_cluster_num=auto_k,
                    manual_clusters_num=manual_k,
                    kamm_order=kamm_order,
                )

                pipeline.load()
                pipeline.run_pipeline()

                default_table = mi.default_table or "Material Properties from Clustering Pipeline"

                rec = pipeline.export_to_mi(
                    mi=mi,
                    table_name=default_table,
                    record_name_prefix="Clustering_Run",
                )

                st.success(f"Exported to Granta MI: {rec.viewer_url}")

            except Exception as e:
                import traceback
                st.error(f"❌ MI Export failed:\n\n{e}\n\n{traceback.format_exc()}")

        # ============================================================
        #   EXPORT TO MECHANICAL (STL / CDB via VTK→CDB)
        # ============================================================
        from collections import defaultdict

        st.markdown("### 🧱 Export RVE Geometry (STL / CDB)")

        from rve_exporter import (
            normalize_phase,
            detect_grid_spacing,
            export_stl,
        )

        from rve_vtk_export import (
            generate_rectangular_vtk_file,
            vtk2cdb,
            rectgrid_to_unstructured,  # 👈 new helper
        )
        import vtk

        thickness = st.number_input(
            "Extrusion thickness (Z direction, same units as X/Y)",
            min_value=0.1, max_value=1000.0, value=1.0
        )

        export_mode = st.radio(
            "Choose Export Format",
            ["STL", "CDB (ANSYS)", "Both (STL + CDB)"],
            horizontal=True
        )

        # -------------------------------------------------
        # SCALE FACTOR SELECTION (visible BEFORE generation)
        # -------------------------------------------------
        st.markdown("#### 📏 Mechanical Export Unit")

        target_unit = st.selectbox(
            "Select target unit for CDB export",
            ["micrometers (µm)", "millimeters (mm)", "meters (m)"],
            index=1,  # default = mm
            key="cdb_scale_unit"
        )

        # MUST be defined before using "scale"
        if target_unit == "micrometers (µm)":
            scale = 1.0
        elif target_unit == "millimeters (mm)":
            scale = 1e-3
        else:
            scale = 1e-6

        st.info(f"Current CDB scale factor = **{scale}** (applied to all coordinates)")

        if st.button("Generate RVE Geometry"):
            try:
                df = pd.read_csv(rdir / "data_with_clusters_and_phases.csv")

                if not {"X Position_µm", "Y Position_µm", "Phase"}.issubset(df.columns):
                    st.error("Phase map requires X Position_µm, Y Position_µm and Phase fields.")
                    st.stop()

                # -------------------------------------------------
                # 1) Compute grid spacing
                # -------------------------------------------------
                xs = df["X Position_µm"].tolist()
                ys = df["Y Position_µm"].tolist()
                dx = detect_grid_spacing(xs)
                dy = detect_grid_spacing(ys)
                dz = thickness

                # -------------------------------------------------
                # 2) Phase → voxel list (for STL)
                # -------------------------------------------------
                phase_voxels = defaultdict(list)
                for _, row in df.iterrows():
                    ph = normalize_phase(row["Phase"])
                    phase_voxels[ph].append((row["X Position_µm"], row["Y Position_µm"]))

                export_dirs = []

                # -------------------------------------------------
                # 3) STL EXPORT
                # -------------------------------------------------
                if export_mode in ["STL", "Both (STL + CDB)"]:
                    stl_dir = rdir / "stl"
                    export_stl(phase_voxels, stl_dir, dx, dy, dz)
                    export_dirs.append(stl_dir)

                # -------------------------------------------------
                # 4) CDB EXPORT (via VTK + vtk2cdb, phases → bodies)
                # -------------------------------------------------
                if export_mode in ["CDB (ANSYS)", "Both (STL + CDB)"]:
                    vtk_dir = rdir / "vtk_tmp"
                    vtk_dir.mkdir(exist_ok=True)

                    # Rectilinear grid coordinates (micrometers)
                    xVec = sorted(set(xs))
                    yVec = sorted(set(ys))
                    zVec = [0.0, dz]   # dz in micrometers

                    # Sanity check: we need at least 2 points in X and Y to make elements
                    if len(xVec) < 2 or len(yVec) < 2:
                        st.error(
                            f"RVE grid has too few points to create hex elements: "
                            f"len(xVec)={len(xVec)}, len(yVec)={len(yVec)}"
                        )
                        st.stop()

                    # --- Write VTK rectilinear grid (still in µm) ---
                    vtk_file = "rve_rectilinear.vtk"
                    generate_rectangular_vtk_file(
                        pathname=str(vtk_dir),
                        filename=vtk_file,
                        xVec=xVec,
                        yVec=yVec,
                        zVec=zVec
                    )

                    # --- Read VTK back ---
                    reader = vtk.vtkRectilinearGridReader()
                    reader.SetFileName(str(vtk_dir / vtk_file))
                    reader.Update()
                    rect_grid = reader.GetOutput()

                    # --- Convert to SimpleGridForCDB (points + cells) ---
                    grid_for_cdb = rectgrid_to_unstructured(rect_grid)

                    # --- Build elem_phase array: one phase per element ---
                    nx, ny, nz = len(xVec), len(yVec), len(zVec)
                    n_elem = (nx - 1) * (ny - 1) * (nz - 1)

                    if n_elem == 0:
                        st.error(
                            f"No elements would be generated (n_elem=0). "
                            f"Check that X/Y contain a 2D grid (unique X={len(xVec)}, unique Y={len(yVec)}, unique Z={len(zVec)})."
                        )
                        st.stop()

                    # map (x,y) -> phase (normalized int)
                    phase_map = {}
                    for _, row in df.iterrows():
                        ph = normalize_phase(row["Phase"])
                        ph_int = int(ph)
                        phase_map[(row["X Position_µm"], row["Y Position_µm"])] = ph_int

                    elem_phase = []
                    # element ordering matches rectgrid_to_unstructured: k, j, i
                    for k in range(nz - 1):  # currently just 0
                        for j, y0 in enumerate(yVec[:-1]):
                            for i, x0 in enumerate(xVec[:-1]):
                                ph_int = phase_map.get((x0, y0), 0)
                                elem_phase.append(ph_int)

                    if len(elem_phase) != n_elem:
                        st.error(
                            f"elem_phase size mismatch: expected {n_elem}, got {len(elem_phase)}. "
                            "Check that the (X,Y) grid corresponds to the indentation map."
                        )
                        st.stop()

                    # --- Write scaled CDB with phase-based components ---
                    cdb_dir = rdir / "cdb"
                    cdb_dir.mkdir(exist_ok=True)
                    cdb_name = cdb_dir / "rve_geom"

                    vtk2cdb(grid_for_cdb, str(cdb_name), scale=scale, elem_phase=elem_phase)

                    export_dirs.append(cdb_dir)

                # -------------------------------------------------
                # 5) ZIP OUTPUT
                # -------------------------------------------------
                zip_buffer = io.BytesIO()
                with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as z:
                    for folder in export_dirs:
                        for f in folder.rglob("*"):
                            z.write(f, arcname=f.relative_to(rdir))

                zip_buffer.seek(0)

                fname = {
                    "STL": "rve_stl.zip",
                    "CDB (ANSYS)": "rve_cdb.zip",
                    "Both (STL + CDB)": "rve_stl_cdb.zip",
                }[export_mode]

                st.download_button(
                    "⬇️ Download Geometry ZIP",
                    data=zip_buffer,
                    file_name=fname,
                    mime="application/zip"
                )

                st.success(f"{export_mode} export completed.")

            except Exception as e:
                st.error(f"❌ Export failed:\n{e}")

# ============================================================
# HELP / DOCS TAB
# ============================================================
with tab_help:
    st.markdown("### ❓ Help / Documentation")
    st.markdown(
        """
        This tab renders the documentation Markdown file located at:

        `../doc/clustering_process.md`
        """
    )

    if DOC_MD_PATH.exists():
        try:
            md_text = DOC_MD_PATH.read_text(encoding="utf-8")
            st.markdown(md_text)
        except Exception as e:
            st.error(f"Could not read documentation file: {e}")
    else:
        st.warning(
            "Documentation file not found.\n\n"
            f"Expected at: **{DOC_MD_PATH}**\n\n"
            "Create the file or check your folder structure."
        )

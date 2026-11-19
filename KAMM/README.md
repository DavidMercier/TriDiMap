# ICME-OoCTO

This repository brings together materials informatics tools, research code, and
project examples. Its main application, **ClusterLab**, is an end-to-end
multiphase materials clustering platform combining:

* A full **data cleaning and preprocessing pipeline**
* **Unsupervised clustering** (KMeans, GMM, DBSCAN, Agglomerative, OPTICS)
* **Mechanical feature extraction** (H/E, H³/E², KAMM family)
* **PCA analysis**, spatial maps, composite plots, PDFs, CDFs
* A complete **Streamlit-based UI** for interactive analysis
* **Export to Granta MI** (automatic record creation, TABL export, file attachments)

The repository also contains the KAMM research manuscript and a collection of
NanoMECommons project notebooks. Those collections have separate purposes and
are indexed below.

## Repository Overview

| Area | Contents |
| --- | --- |
| [`clustering_app/`](clustering_app/) | ClusterLab Streamlit interface, clustering pipeline, and Granta MI integration |
| [`ArticleClusteringKAMM/`](ArticleClusteringKAMM/) | KAMM manuscript source and standalone supplementary implementation |
| [`nanoMECommons/`](nanoMECommons/) | Historical EU project examples, notebooks, sample data, and exports; see its [guide](nanoMECommons/README.md) |
| [`datasets/`](datasets/) | Reference and synthetic validation datasets |
| [`doc/`](doc/) | Clustering workflow documentation |

## KAMM Article

**Enhancing Phase Clustering in Nanomechanical Property Maps of Multiphase
Materials Using Kernel-Averaged Mechanical Mismatch** introduces and evaluates
KAMM, a neighborhood-informed descriptor for nanomechanical property maps. The
study uses controlled synthetic microstructures and an experimental dataset to
assess when adding neighborhood information helps phase clustering.

The [manuscript source](ArticleClusteringKAMM/KAMM_clustering_paper_Materialia/cleaned_manuscript.tex)
is a working draft: its journal field is still a placeholder, and no publication
or DOI is claimed here. The accompanying [standalone code](ArticleClusteringKAMM/supplementary_clustering.py)
provides a small implementation of the descriptors and a KMeans example; it is
distinct from the full ClusterLab application and benchmark workflow.

## Standalone Article Supplement

[supplementary_clustering.py](ArticleClusteringKAMM/supplementary_clustering.py) is a self-contained
collection of key functions, requiring only NumPy, pandas and scikit-learn:

* `prepare_data(data)`: remove invalid observations and average duplicate positions.
* `compute_kam(data, order=1)`: calculate all five descriptors from prepared data.
* `compute_kamm`, `compute_kaem`, `compute_kapm`, `compute_kamm_ratio`, and
  `compute_kamm_normprod`: add just the named descriptor to prepared data.
* `cluster_with_kamm`: standardize selected features and fit reproducible KMeans
  clustering; defaults to hardness, modulus and KAMM.

```python
from ArticleClusteringKAMM.supplementary_clustering import cluster_with_kamm

clustered, scaler, model = cluster_with_kamm(
    measurements, n_clusters=3, order=1,
    feature_columns=("H", "E", "KAMM", "KAEM", "KAPM")
)
```

```bash
python -m pip install numpy pandas scikit-learn
```

The functions accept a DataFrame with `X`, `Y`, `H` and `E` columns; hardness
and modulus must be in GPa. The file contains functions only: no data-file
loading, exports, or executable example. Import the functions and pass the
measurements directly. Selected nonfinite descriptor values are mean-imputed,
with zero fallback for entirely missing features, before standardization.

KAMM averages absolute differences in the product E*H, retaining the app's
zero self-difference in the neighbourhood mean. KAEM and KAPM average absolute
modulus and hardness differences. KAMM_RATIO averages the absolute ratio of
modulus to regularized hardness differences, not differences of E/H ratios.
KAMM_NORMPROD averages signed products of standardized E and H differences.
Each named function contains its own explicit formula and documents its units
and regularization constants. Only the grid-neighbour lookup is shared;
`compute_kam` simply calls all five functions.
Any positive integer `order=r` selects the Manhattan grid shell
`abs(delta_row) + abs(delta_column) = r`, with up to `4*r` neighbours plus
the centre; inner shells and missing grid cells are excluded. Orders 1 and 2
retain the original definitions. Orders above 2 are an extension, not an
additional validated result from the article. For example, pass `order=3` to
any descriptor function or to `cluster_with_kamm`.
There is no GUI, MI, API,
command-line configuration, PCA, model ranking, or metadata-export machinery.
Cluster numbers do not establish physical phase identities. Report the chosen
cluster count, neighbourhood order, random seed and dependency versions with
the article; the example settings are not article-specific. This is a minimal
method illustration, not the synthetic generator or full benchmark workflow.

---

## 🚀 Features

### 🔹 Data Ingestion & Cleaning

* Automatic detection and conversion of **CSV/XLS/XLSX/XML/BIFF** formats
* Robust handling of *MTS/NanoSuite* multi-row headers
* Auto-renaming of inconsistent column names
* Duplicate (X,Y) position resolution
* Derived mechanical feature computation
* Automatic KAMM / KAEM / KAPM computation

### 🔹 Clustering Pipeline

Supported feature modes:

* **E vs H** (recommended)
* **E vs H vs KAMM**
* **Mechanical descriptors** (H/E, H³/E²)
* **Full feature set** (H, E, ratios, KAM family)
* **Custom feature selection**

Supported clustering methods:

* **KMeans**
* **Gaussian Mixture Model (GMM)**
* **DBSCAN / OPTICS** (density-based)
* **Agglomerative Clustering**
* **Run all combinations** mode (auto-ranking using Silhouette score)

Cluster count:

* **Manual selection**
* **Automatic detection** (knee method)

### 🔹 Visualization

The pipeline automatically generates:

* Hardness/Modulus maps
* Feature ratio maps (H/E, H³/E²)
* E–H scatter
* PDFs + GMM decomposition
* Weibull CDFs
* Spatial cluster maps
* PCA scatter + PCA spatial map
* Correlation matrix
* Composite 4‑panel figure

### 🔹 Streamlit UI

A complete interface that provides:

* Dataset preview
* Parameter configuration
* Pipeline execution
* Best‑model recommendation
* Figure visualization
* Export (ZIP / JSON / CSV)

### 🔹 Granta MI Export

* Automatic connection using `.json` config file
* Auto-creation of folders and records
* Upload of:

  * PNG figures
  * Cluster statistics
  * Feature metadata
  * Phase table (TABL)
* Fully typed attribute mapping (TEXT, REAL, FILE, TABL, HYPERLINK)

---

## 📦 Installation

Clone and install:

```bash
git clone <repo-url>
cd ICME-OoCTO
pip install -r requirements.txt
```

or using Poetry:

```bash
poetry install
```

---

## 🧭 Usage

### 1. Run the Streamlit app

```bash
streamlit run clustering_app/app_clustering_gui.py
```

This launches the full interactive interface.

### 2. Use the pipeline programmatically

```python
from clustering_app.clustering_pipeline import clustering_pipeline

pipeline = clustering_pipeline(base_dir="data/sample.csv", methods=["KMeans"])
pipeline.load()
pipeline.run_pipeline()
```

Outputs will be available in:

```
clustering_app/results/clustering/<timestamped-folder>
```

---

## ⚙️ Configuration

### Granta MI

Create `mi_config.json`:

```json
{
  "server": "http://your-mi-server",
  "database": "MI_DB_KEY",
  "username": "user",
  "password": "pwd",
  "default_table": "Material Properties from Clustering Pipeline",
  "default_folder": "ClusterLab"
}
```

The app reads this automatically.

---

## 📁 ClusterLab Structure

```
clustering_app/
├── app_clustering_gui.py      # Streamlit UI
├── clustering_pipeline.py     # Full clustering engine
├── MI_client.py               # MI interface
├── mapping.py                 # Plot helpers
├── processing.py              # Utility functions
├── rve_exporter.py             # RVE export helpers
└── mi_config.json              # Local Granta MI configuration
```

---

## 🖼 Outputs

Each pipeline run generates:

* `data_with_clusters_and_phases.csv`
* `phase_statistics.csv`
* `cluster_statistics_phases.json`
* All PNG figures in the run folder
* Composite figure: `final_composite_figure.png`

---

## 🤝 Contributing

* Use feature branches
* Respect existing directory structure
* Add docstrings for any new modules

---

## 📄 License


---

## 📬 Contact

For issues, feature requests, or MI integration support, open an issue or contact the maintainer.

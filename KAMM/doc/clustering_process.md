# ClusterLab — Clustering Documentation

This page explains the clustering workflow implemented in **ClusterLab: ICME Multiphase Material Clustering Platform** and how to interpret the results.

---

## 1) What the app does (end-to-end)

1. **Load** an indentation map dataset (CSV/XLS/XLSX) containing hardness/modulus and spatial coordinates.  
2. **Preprocess** (clean, optional normalization).  
3. **Build feature space(s)** (e.g., *E vs H*, *E vs H + KAMM*, mechanical ratios, or custom selection).  
4. *(Optional)* **PCA** for dimensionality reduction before clustering.  
5. **Cluster** points using the selected algorithm(s).  
6. **Score** the clustering quality with standard unsupervised metrics.  
7. **Visualize** clusters in feature space and spatial maps.  
8. **Export** results (CSV/JSON/figures, ZIP, MI export, optional geometry export).

---

## 2) Required input columns

Typical required columns (names can vary; the pipeline attempts to detect common variants):

- **Hardness**: `HARDNESS_GPa` (or similar)
- **Modulus**: `MODULUS_GPa` (or similar)
- **Spatial coordinates**: often `X Position_µm`, `Y Position_µm` (for spatial maps & RVE export)

If coordinates are missing, clustering still works, but **spatial maps / RVE export** require `X` and `Y`.

---

## 3) Feature spaces used for clustering

ClusterLab can run clustering in different feature spaces (selected from the sidebar):

### A) E vs H
- 2D clustering in `(MODULUS_GPa, HARDNESS_GPa)`.

### B) E vs H vs KAMM (recommended)
- 3D clustering using `(E, H, KAMM)` where **KAMM** captures local mechanical mismatch (helpful for subtle phase boundaries).

### C) Mechanical features (derived)
- Typical ratios used in indentation analysis:
  - `H/E_ratio`
  - `H^3/E^2_ratio`

### D) All features
- Includes `(H, E, ratios, KAMM family)` such as `KAEM`, `KAPM`, `KAMM_RATIO`, `KAMM_NORMPROD` (when enabled).

### E) Custom selection
- You choose the exact feature columns to cluster on.

> **Tip:** If you activate features like `KAMM/KAEM/KAPM`, the app will ask for the **KAMM metric order** (1st, 2nd, or both) to compute the appropriate neighborhood relationships.

---

## 4) Preprocessing & normalization

Clustering performance depends strongly on feature scaling.

### Feature normalization (recommended)
When **Apply feature normalization** is enabled, the pipeline scales numeric features so that:
- One feature does not dominate due to having larger numeric range.
- Distance-based clustering (KMeans, Agglomerative, OPTICS) becomes more stable.

### Missing values
- Rows with missing essential clustering features are typically removed or imputed depending on pipeline settings.
- If your dataset contains many missing values, consider cleaning it upstream for best results.

---

## 5) PCA (optional)

If **Apply PCA before clustering** is enabled:
- Features are projected into a smaller set of principal components.
- PCA can help when you use *All features* and dimensions are highly correlated.

### How to decide
Use PCA when:
- You have many correlated features (ratios + KAMM family).
- You see unstable clusters due to noise or redundancy.

Avoid PCA when:
- You want direct interpretability in the original feature axes for publication figures.

---

## 6) Clustering methods (what they do)

ClusterLab supports multiple clustering algorithms. Each makes different assumptions.

### 6.1 KMeans
**Idea:** Find `k` cluster centers minimizing within-cluster variance (inertia).  
**Strengths:** Fast, stable, great for compact/spherical clusters.  
**Weaknesses:** Requires `k`; struggles with non-spherical shapes and unequal densities.

Key outputs:
- Cluster labels
- Inertia (used for elbow analysis)

### 6.2 Gaussian Mixture Model (GMM)
**Idea:** Fit `k` Gaussian distributions; assigns points by probability.  
**Strengths:** Handles elliptical clusters, provides soft probabilities.  
**Weaknesses:** Requires `k`; can overfit if `k` too large.

Useful selection criteria:
- **BIC/AIC** (if computed in your pipeline): lower is better.

### 6.3 Agglomerative Clustering (Hierarchical)
**Idea:** Build a hierarchy of merges based on a linkage criterion.  
**Strengths:** Works well for structured data, does not assume spherical clusters.  
**Weaknesses:** Requires `k` (cut level) and linkage choice; can be slower on large datasets.

### 6.4 DBSCAN (density-based)
**Idea:** Clusters are dense regions; points in sparse areas are labeled **noise**.  
**Strengths:** No need to choose `k`; finds arbitrary shapes; detects outliers.  
**Weaknesses:** Sensitive to `eps` and `min_samples`; struggles with varying density.

Outputs:
- Clusters + noise points (`-1` label typically)

### 6.5 OPTICS (density-based, multi-scale)
**Idea:** Similar to DBSCAN but explores density structure across scales.  
**Strengths:** More robust than DBSCAN when density varies.  
**Weaknesses:** Parameter tuning still matters; interpretation can be less straightforward.

> Note: In “Run all combinations” mode, OPTICS may be disabled for stability/performance.

---

## 7) Choosing the number of clusters (k)

For methods that require `k` (KMeans, GMM, Agglomerative), ClusterLab offers:

### Manual `k`
You choose the number of clusters directly.

### Automatic cluster detection
When enabled, the pipeline tries multiple `k` values and ranks models using scoring metrics.

Typical approach:
- Sweep `k` over a range (e.g., 2→N)
- Compute quality metrics per `k`
- Select the best `k` by a rule (best silhouette, best composite score, etc.)

> Density-based methods (DBSCAN/OPTICS) **do not use `k`**.

---

## 8) Clustering quality metrics (scores)

ClusterLab displays standard unsupervised scores. Use them to compare methods/feature spaces.

### 8.1 Silhouette Score (range: -1 to +1)
Measures how well points match their own cluster vs other clusters.
- **~ +1.0**: excellent separation
- **~ 0.5**: good structure
- **~ 0.0**: overlapping clusters
- **< 0.0**: likely wrong clustering

**Use it for:** quick overall comparison across models.

### 8.2 Calinski–Harabasz Index (no fixed upper bound)
Ratio of between-cluster dispersion to within-cluster dispersion.
- **Higher is better** (more separated + more compact clusters)

**Use it for:** comparing different `k` values.

### 8.3 Davies–Bouldin Index (range ≥ 0)
Measures average similarity between each cluster and its most similar one.
- **Lower is better**
- DB ~ 0.2–0.5 is often very strong separation (depends on data)

**Use it for:** detecting overly overlapping clusters.

### 8.4 Inertia (KMeans only)
Sum of squared distances to nearest centroid.
- Always decreases when `k` increases.
- Used with the **elbow method** (look for a “knee”).

**Use it for:** sanity-checking KMeans behavior with increasing `k`.

---

## 9) How to interpret results in the app

### Feature-space plots
- Look for compact, well-separated groups.
- If clusters overlap strongly, try:
  - enabling normalization
  - adding KAMM features
  - trying GMM or density-based methods

### Spatial cluster maps
- Clusters should form spatially coherent regions for real phases.
- “Salt-and-pepper” patterns often indicate:
  - too many clusters
  - noisy features / insufficient smoothing
  - missing normalization

### Phase labeling
If the pipeline maps clusters → phases:
- Treat labels as **data-driven groups**, not automatically physical phases.
- Validate with microstructure knowledge (SEM/EBSD/EDS) where possible.

---

## 10) Practical recommendations (quick guide)

- Start with **E vs H vs KAMM** + **normalization** + **KMeans** or **GMM**.
- If you suspect irregular phase shapes or strong outliers:
  - try **DBSCAN/OPTICS**
- If results depend heavily on random initialization:
  - reduce dimensionality (PCA) or simplify feature space
- If you get too many tiny clusters:
  - lower `k` or use hierarchical/GMM with stronger model selection

---

## 11) Troubleshooting

### The docs tab is empty
- Confirm file path: `project_root/doc/clustering_process.md`
- If the app previously stopped early, ensure you’re not calling `st.stop()` globally in another tab.

### Clusters look unstable
- Enable normalization
- Reduce features or enable PCA
- Use “Run all combinations” to compare methods and feature spaces

### DBSCAN returns mostly noise (-1)
- Increase `eps`
- Decrease `min_samples`
- Ensure normalization is enabled

### Too many clusters with KMeans/GMM
- Reduce `k`
- Use automatic detection and compare scores
- Consider using GMM with BIC/AIC if available

---

## 12) Glossary

- **H (Hardness)**: Indentation hardness (GPa)
- **E (Modulus)**: Elastic modulus (GPa)
- **KAMM**: Kernel Average Mechanical Mismatch (captures local mismatch neighborhoods)
- **PCA**: Principal Component Analysis (dimensionality reduction)
- **k**: Number of clusters (for k-required methods)
- **Noise**: Unclustered points (DBSCAN/OPTICS)

---

*Last updated:* 2026-02-26

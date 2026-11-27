KAMM-assisted machine-learning clustering
=========================================

TriDiMap includes an opt-in workflow based on the supplied KAMM research
supplement: mechanical maps -> neighbourhood descriptors -> standardized
features -> clustering -> phase maps. It does not require the separate
ClusterLab/Streamlit application or a Granta connection.

Reference: D. Mercier and Y. El Gharoussi, *Enhancing phase clustering in
nanomechanical property maps of multiphase materials using Kernel-Averaged
Mechanical Mismatch*, Materials Science and Engineering: A **980**, 151351.
`DOI: 10.1016/j.msea.2026.151351 <https://doi.org/10.1016/j.msea.2026.151351>`_.

MATLAB GUI
----------

For a descriptor map without fitting any clusters, select **KAMM map**
directly in the main **Plot** list, alongside E and H. Choose the descriptor
and shell order together in the upper map-options panel (the same panel as
2D/3D and Remove NaN for E/H maps). This also works
on constant maps and requires neither a phase count nor a Statistics Toolbox.
It preserves the independent ML clustering cache. Descriptor statistics are
shown below the plot selector; unlike E/H thresholds, these readouts do not
filter the measured inputs. Cropping uses the existing raster crop settings.
Figure **SAVE** is supported; E/H spreadsheet export and legacy point picking
are disabled in this standalone view. Numerical maps remain in ``gui.kamm.maps``.
Standalone KAMM uses the same map-processing and rendering pipeline as E/H:
**Remove NaN pixels**, interpolation, smoothing/error maps, 2D pixels, 3D
surfaces (with contours), waterfall, contour, mesh and bars are available.
The descriptor and shell-order selectors share the upper map-options panel.
The lower panel provides colormaps/grayscale, flip, manual color limits,
intervals, normalization, translation and markers.

Descriptors are always calculated from the measured E/H pairs first.
Remove NaN fills missing **descriptor pixels**, not missing measurements,
using the existing neighbouring-pixel averaging approach. Zero, signed and
large descriptor values are retained; E/H validity cutoffs are not applied.
Display processing never modifies ``gui.kamm.maps``, the measurements or
ML clustering features. Uncheck Remove NaN to retain holes. Interpolation
and smoothing follow the usual Remove NaN prerequisite. Statistics report
the unprocessed descriptor; the NaN ratio reports its missing-pixel fraction.
3D Slice/depth mapping and E/H PDF-derived color levels are not applicable.
For standalone maps Log uses natural-log pixel colors in 2D, and logarithmic
height/color axes in 3D; nonpositive values are hidden with a warning.
KAMM 3D plot-box proportions are normalized to the displayed axis ranges,
so large squared-property units do not collapse the surface into a needle.
**Z axis ratio** controls the horizontal-span/height proportion without
changing descriptor values or axis ticks.

For ML-assisted phase clustering:

1. Load a regular indentation map with hardness and modulus in **GPa**.
2. Select **E vs H**, then **ML-assisted clustering**.
   **E-H data: raw measurements** is the default. Select
   **E-H data: processed maps** to apply the retained map cleaning,
   interpolation and smoothing settings to both E and H before clustering.
   This does not modify the measured arrays. Processed counts/fractions
   describe map pixels rather than independent indents; see :doc:`E_H`.
3. Enter the **Phase number** and choose the lower-panel settings:

   * **Features: H,E**: the mechanical-property baseline;
   * **Features: H,E,KAMM**: add spatial mechanical mismatch (default);
   * **Features: H/E, H^3/E^2**: mechanical ratios;
   * **Features: all (9)**: H, E, both ratios and all five KAMM descriptors.

4. Choose **K-means (base MATLAB)**, **GMM (Statistics Toolbox)**,
   **ISOMAP + K-means (base MATLAB)** or **SOM + K-means (base MATLAB)** and
   **KAMM order: 1** or **2**.
5. Switch between **E-H clusters**, **Phase map**, **KAMM map**,
   **Joint phase PDFs (3D)** and **E-H vs descriptor (3D)**. With SOM,
   **SOM clusters** and **SOM U-matrix** are also available. The descriptor
   selector controls the Z-axis in the 3D scatter as well as the image in
   KAMM map. Choose KAMM, KAEM, KAPM, KAMM_RATIO or KAMM_NORMPROD. The 3D
   scatter uses hardness (X), modulus (Y) and the selected descriptor (Z),
   with assigned phases shown in separate colors. It requires a regular raster map.
6. Use **Export ML CSV** for positions, H, E, phase IDs and descriptors.
   In **E-H clusters** or **ISOMAP embedding**, use the upper-panel envelope
   selector for convex hulls or fitted ellipses in the phase colors.
   Changing envelopes reuses the cached fit; the phase legend remains visible.

K-means uses bounded, deterministic multi-start Lloyd iterations and needs
no Statistics Toolbox. SOM also uses base MATLAB. The new ML GMM uses
regularized ``fitgmdist`` and requires Statistics and Machine Learning Toolbox;
an unavailable toolbox produces an explicit message, not a different algorithm. The legacy
**Gaussian Mixture Model** option is unchanged.

Features use population-standard-deviation z-score scaling; constant
features have scale one. Invalid/nonpositive measurements retain NaN
descriptors. They and nonfinite selected feature vectors are excluded from
clustering, not mean-imputed. All excluded positions remain in maps/exports
as phase **0** (unassigned).
Raw-mode clustering performs no interpolation or smoothing. Opt-in
processed-mode clustering uses the processed E/H maps and recomputes KAMM
on that refined raster; filled/interpolated positions may therefore be
assigned phases. Labels are ordered by increasing mean selected hardness,
not physical phase identity.

Fits are cached by input maps, feature selection, method, order, phase
count, input source and, for ISOMAP, neighbour count. Changing a view,
envelope, displayed descriptor, grid, ticks, grayscale or
other display controls does not refit. Changing measurements, crop,
thresholds or analysis settings invalidates the cache. Measurements and
legacy GMM labels are not overwritten. The cached result and model are
available in ``gui.ml`` through ``guidata``.

**SAVE**, **Colormap > Grayscale (all plots)**, grid and minor ticks apply to
the new views.
Log uses H/E axes for scatter/densities and log10 descriptor colors for
KAMM maps (nonpositive values are hidden with a warning). In the 3D scatter,
Log sets all three axes to logarithmic scale; points with nonpositive H, E,
or descriptor values are hidden with a warning. Min/Max annotates H extrema
on the scatters, displayed descriptor extrema on a KAMM map, or displayed
density extrema on the joint PDFs. Log and Min/Max are disabled for
categorical phase maps.

SOM-assisted phase clustering
-----------------------------

Choose **SOM + K-means (base MATLAB)** and a phase count in **E vs H >
ML-assisted clustering**. The **SOM clusters** view shows occupied map nodes
colored by their assigned cluster; empty nodes are transparent. The **SOM
U-matrix** shows the mean distance to each node's adjacent codebook vectors
in standardized feature space, where larger values can suggest boundaries.
The usual E-H clusters and spatial phase-map views show the same assignments.
CSV export adds SOM column and row for each valid measurement; excluded
measurements retain phase 0 and have missing SOM coordinates.

The deterministic batch SOM uses a square grid of up to 10 by 10 nodes,
initialized from ordered samples along the first principal direction. It
trains for 80 iterations with a shrinking Gaussian neighbourhood. Each
measurement is assigned to its closest node in standardized feature space.
K-means then clusters the distinct occupied node prototypes, with equal
weight per distinct prototype rather than per measurement, and each
measurement inherits its node's cluster. The phase count must be between
2 and 100 and no greater than the number of distinct occupied prototypes;
otherwise fitting is rejected. The result is cached with the other ML
settings. Coordinates are used to map assignments back to the sample, not
as SOM features; KAMM contributes local spatial information if selected.

The SOM grid is a feature-space representation, not the sample's spatial map.
Its dimensions, initialization and feature selection affect the result;
compare with other methods and independently characterized microstructure.
Neither SOM nor K-means alone establishes physical phase identity.
The GUI does not currently provide component maps, known-label overlays or
stiffness as a SOM input feature. Run ``test_som`` from the MATLAB tests
folder to check clustering, views, caching and export.

ISOMAP-assisted phase clustering
--------------------------------

In **E vs H > ML-assisted clustering**, select
**ISOMAP + K-means (base MATLAB)** in the method selector. Choose
**ISOMAP neighbours: 5**, **10** (default), **20** or **50** in the
lower E-H options panel. Keep the usual feature selection, phase count
and KAMM shell order. Select **ISOMAP embedding** in the view selector
to inspect the two-dimensional embedding colored by assigned phase.
E-H plots, phase maps, descriptor plots and joint PDFs remain available.
Log is disabled for the embedding, whose coordinates can be negative.

The procedure is:

1. Exclude invalid/nonpositive E-H pairs and nonfinite selected features.
2. Standardize the selected features using the existing z-score scaling.
3. Build a Euclidean k-nearest-neighbour graph in standardized feature space,
   symmetrized by retaining an edge if either point selects the other.
4. Compute shortest-path (geodesic) distances and use classical metric
   multidimensional scaling to obtain two embedding coordinates.
5. Apply the existing K-means algorithm to the embedding, then order phase
   labels by increasing mean measured hardness.

This implements the ISOMAP dimensionality-reduction approach of
Tenenbaum, de Silva and Langford (2000),
`DOI: 10.1126/science.290.5500.2319 <https://doi.org/10.1126/science.290.5500.2319>`_.
ISOMAP itself is not a phase classifier. This opt-in workflow is **not**
a reproduction of the full
spatially enriched hierarchical identification and heterogeneous-indent
rejection procedure described by Bernachy-Barbe (2019),
`DOI: 10.1617/s11527-019-1397-y <https://doi.org/10.1617/s11527-019-1397-y>`_.
XY coordinates are not embedded; KAMM adds neighbourhood information only
when selected on a regular raster.

Neighbour count must be smaller than the number of valid measurements.
A disconnected graph is rejected explicitly: increase neighbours or review
the features and data. ISOMAP adds no artificial inter-component edges,
additional interpolation or automatic removal of potentially heterogeneous
measurements after selecting the raw or processed input maps.
Large neighbour counts can erase the manifold's local geometry; compare
several counts and the direct H/E baseline. The number of phases remains
user-specified, and statistical clusters still require independent
microstructural validation.

Both implementations limit dense ISOMAP to **2000 valid measurements**.
The geodesic and embedding matrices require quadratic memory, and MATLAB's
shortest-path/eigenvalue calculations have cubic worst-case cost. Use an
explicit smaller map or crop for larger datasets; no hidden subsampling
changes the phase fractions.

The MATLAB cached result stores standardized features in
``gui.ml.result.features``, the valid-row embedding in
``gui.ml.result.embedding`` and geodesic/eigenvalue metadata in
``gui.ml.result.isomapModel``. **Export ML CSV** appends ``ISOMAP1`` and
``ISOMAP2`` after the existing columns, with NaN at excluded positions.
Existing K-means/GMM exports retain their column layout.

Python uses the same opt-in method with scikit-learn ISOMAP::

    from tridimap_ml import cluster_map

    result = cluster_map(
        modulus, hardness, feature_set="kamm", method="isomap",
        n_clusters=3, n_neighbors=10,
    )
    phase_map = result.labels
    embedding = result.embedding

As with the notebook, load same-shaped E/H rasters in GPa and import from
the repository's ``python`` directory. ``result.features`` remains the
standardized pre-embedding matrix; ``result.model`` is the K-means model
fitted on ``result.embedding``. ``result.embedding_model`` exposes the
fitted ISOMAP model and its reconstruction diagnostics. Embedding rows
correspond to ``result.valid.ravel()`` in row-major order. Invalid map
positions retain phase 0. The default methods do not compute an embedding.

Run ``test_isomap`` from the MATLAB tests folder with MATLAB available.
The existing Python test command below also covers ISOMAP geodesics,
deterministic clustering, holes, duplicates and disconnected graphs.
MATLAB and Python embeddings/partitions can differ with neighbour-distance
ties, eigenvector orientation and their different K-means initializers.

Neighbourhood definition and formulas
-------------------------------------

Let ``D_i`` contain the centre ``i`` and valid pixels on the Manhattan shell
``abs(delta_row) + abs(delta_column) = order``. Order 1 has up to four
neighbours plus the centre. Order 2 has up to eight plus the centre;
it does **not** include the first shell. Boundaries and missing measurements
reduce the denominator. An isolated valid centre has zero mismatch.

The implemented descriptors use the following definitions:

* **KAMM** = mean over ``D_i`` of ``abs(E_i*H_i - E_j*H_j)`` (GPa squared).
* **KAEM** = mean ``abs(E_i - E_j)`` (GPa).
* **KAPM** = mean ``abs(H_i - H_j)`` (GPa).
* **KAMM_RATIO** = mean ``abs((E_i-E_j)/(H_i-H_j+1e-6))`` (dimensionless,
  with regularization in GPa). This is not a difference of E/H ratios.
* **KAMM_NORMPROD** = mean ``((E_i-E_j)/sigma_E)*((H_i-H_j)/sigma_H)``
  (signed, dimensionless). Global population standard deviations use
  positive finite E-H pairs, with a ``1e-12`` GPa floor.

The zero self-difference participates in each average, matching the supplied
supplement. Nonfinite ratio values can still occur near ``delta_H=-1e-6``;
affected selected feature vectors are excluded explicitly rather than
silently replaced. This differs from the supplement's mean-imputation
policy and preserves missing measurements instead of fabricating features.

Grid indices, not Euclidean physical distances, define the shells. Anisotropic
spacing is not distance-weighted. MATLAB uses the already spatially ordered
map matrices; labels are not flipped again for serpentine acquisition.
Random **Irregular XY** coordinates cannot be treated as raster neighbours:
only H/E or mechanical-ratio clustering and spatial point maps are supported
there. Their CSV exports omit raster descriptors. KAMM feature/map requests
show an explicit raster-grid requirement.

License-free Python notebook
----------------------------

The independent
`python/kamm_clustering.ipynb <https://github.com/DavidMercier/TriDiMap/blob/master/python/kamm_clustering.ipynb>`_
compares E-H K-means, E-H-KAMM K-means and E-H-KAMM GMM on reproducible
synthetic maps with a diffuse interface and a missing patch.

From the repository root::

    python -m pip install -r python/requirements.txt
    python -m jupyterlab python/kamm_clustering.ipynb

Python 3.10+ is recommended. NumPy, scikit-learn and Matplotlib implement
the numerical workflow; no MATLAB installation/license is needed.
``python/tridimap_ml.py`` is also usable without Jupyter. The notebook
explains loading two same-shaped numeric CSV rasters in GPa and exporting
every position without dropping holes. Python raster rows are Y, columns X.
The MATLAB renderer transposes its native X-by-Y maps for display.

Run the focused Python checks with::

    python -m unittest discover -s python -p "test_*.py"

Run ``test_kamm`` from the MATLAB tests folder with the toolbox on the path.
Descriptor definitions are shared across languages, but scikit-learn and
MATLAB initializers need not produce identical clustering partitions.

Interpretation
--------------

KAMM is a descriptor, not a new clustering algorithm or a guarantee of
improved phase identification. Strong mismatch can indicate interfaces,
noise or outliers. Compare against the H/E baseline and independent
microstructural evidence, vary order/phase count, and report preprocessing,
feature scaling, model and dependency versions. The notebook's ground-truth
scores apply only to its synthetic illustration; it is not the complete
research benchmark. DBSCAN/OPTICS, automatic model ranking, PCA and Granta
integration from the larger KAMM application are not part of this GUI feature.

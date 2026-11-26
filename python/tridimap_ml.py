"""Raster-map KAMM descriptors and standardized phase clustering, in GPa."""

from __future__ import annotations

from dataclasses import dataclass
import warnings

import numpy as np
from numpy.typing import ArrayLike, NDArray
from scipy.sparse.csgraph import connected_components
from sklearn.cluster import KMeans
from sklearn.manifold import Isomap
from sklearn.mixture import GaussianMixture
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import StandardScaler

DESCRIPTORS = ("KAMM", "KAEM", "KAPM", "KAMM_RATIO", "KAMM_NORMPROD")
FEATURE_SETS = {
    "eh": ("H", "E"),
    "kamm": ("H", "E", "KAMM"),
    "mechanical": ("H/E", "H^3/E^2"),
    "all": ("H", "E", "H/E", "H^3/E^2", *DESCRIPTORS),
}


def _maps(modulus: ArrayLike, hardness: ArrayLike) -> tuple[NDArray[np.float64], NDArray[np.float64]]:
    e = np.asarray(modulus, dtype=float)
    h = np.asarray(hardness, dtype=float)
    if e.ndim != 2 or e.size == 0 or e.shape != h.shape:
        raise ValueError("E and H must be nonempty 2D arrays of the same shape, in GPa.")
    return e, h


def kamm_maps(
    modulus: ArrayLike, hardness: ArrayLike, order: int = 1
) -> dict[str, NDArray[np.float64]]:
    """Five descriptors on the Manhattan shell r, plus the zero self-difference.

    Shell 1 has four possible neighbours, shell 2 eight (not the inner shell).
    Missing/nonpositive pairs remain NaN and are not neighbours. The denominator
    counts valid shell neighbours plus the centre, matching the supplied KAMM
    supplement. Ratio uses delta_E / (delta_H + 1e-6 GPa); normprod is signed
    and uses population standard deviations with a 1e-12 GPa floor.
    """
    if isinstance(order, (bool, np.bool_)) or not isinstance(order, (int, np.integer)) or order not in (1, 2):
        raise ValueError("order must be 1 or 2.")
    e, h = _maps(modulus, hardness)
    valid = np.isfinite(e) & np.isfinite(h) & (e > 0) & (h > 0)
    if not valid.all():
        warnings.warn(
            f"Leaving {np.count_nonzero(~valid)} invalid/nonpositive E-H positions unassigned.",
            stacklevel=2,
        )
    if not valid.any():
        raise ValueError("At least one positive finite E-H pair is required.")
    with np.errstate(over="ignore"):
        product = e * h
    if not np.isfinite(product[valid]).all():
        raise ValueError("E*H overflows; check input values and GPa units.")
    scale_e = max(float(np.std(e[valid], ddof=0)), 1e-12)
    scale_h = max(float(np.std(h[valid], ddof=0)), 1e-12)
    totals = np.zeros((*e.shape, len(DESCRIPTORS)), dtype=float)
    count = valid.astype(float)
    for di in range(-order, order + 1):
        for dj in range(-order, order + 1):
            if abs(di) + abs(dj) != order:
                continue
            r0, r1 = max(0, -di), min(e.shape[0], e.shape[0] - di)
            c0, c1 = max(0, -dj), min(e.shape[1], e.shape[1] - dj)
            if r0 >= r1 or c0 >= c1:
                continue
            current = np.s_[r0:r1, c0:c1]
            other = np.s_[r0 + di:r1 + di, c0 + dj:c1 + dj]
            pair = valid[current] & valid[other]
            with np.errstate(divide="ignore", invalid="ignore"):
                de = e[current] - e[other]
                dh = h[current] - h[other]
                differences = np.stack(
                    (np.abs(product[current] - product[other]), np.abs(de), np.abs(dh),
                     np.abs(de / (dh + 1e-6)), (de / scale_e) * (dh / scale_h)),
                    axis=-1,
                )
            totals[current] += np.where(pair[..., None], differences, 0)
            count[current] += pair
    with np.errstate(divide="ignore", invalid="ignore"):
        averages = totals / count[..., None]
    return {name: np.where(valid, averages[..., i], np.nan) for i, name in enumerate(DESCRIPTORS)}


@dataclass
class ClusteringResult:
    labels: NDArray[np.int64]
    descriptors: dict[str, NDArray[np.float64]]
    feature_names: tuple[str, ...]
    features: NDArray[np.float64]
    valid: NDArray[np.bool_]
    scaler: StandardScaler
    model: KMeans | GaussianMixture
    embedding: NDArray[np.float64] | None = None
    embedding_model: Isomap | None = None


def cluster_map(
    modulus: ArrayLike,
    hardness: ArrayLike,
    *,
    n_clusters: int = 3,
    feature_set: str = "kamm",
    method: str = "kmeans",
    order: int = 1,
    random_state: int = 0,
    n_neighbors: int = 10,
) -> ClusteringResult:
    """Fit z-score features; return map-shaped, hardness-ordered labels 1..K.

    Zero denotes an invalid/unassigned position, never a material phase.
    Nonfinite selected feature vectors are excluded, not mean-imputed.
    method="isomap" fits K-means on a two-dimensional ISOMAP embedding.
    n_neighbors applies only to ISOMAP, which requires a connected graph.
    Clusterings are statistical candidates, not physical phase identities.
    """
    if feature_set not in FEATURE_SETS or method not in ("kmeans", "gmm", "isomap"):
        raise ValueError("Unknown feature_set or method.")
    if isinstance(n_clusters, (bool, np.bool_)) or not isinstance(n_clusters, (int, np.integer)) or n_clusters < 2:
        raise ValueError("n_clusters must be an integer >= 2.")
    e, h = _maps(modulus, hardness)
    descriptors = kamm_maps(e, h, order)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
        available = {"H": h, "E": e, "H/E": h / e, "H^3/E^2": h**3 / e**2, **descriptors}
    names = FEATURE_SETS[feature_set]
    matrix = np.column_stack([available[name].ravel() for name in names])
    valid = np.isfinite(e) & np.isfinite(h) & (e > 0) & (h > 0)
    valid &= np.all(np.isfinite(matrix), axis=1).reshape(e.shape)
    if not valid.all():
        warnings.warn(
            f"Excluding {np.count_nonzero(~valid)} invalid measurements or selected feature vectors.",
            stacklevel=2,
        )
    if np.count_nonzero(valid) < n_clusters:
        raise ValueError("Fewer valid feature vectors than requested clusters.")
    scaler = StandardScaler()
    features = scaler.fit_transform(matrix[valid.ravel()])
    if len(np.unique(features, axis=0)) < n_clusters:
        raise ValueError("Fewer distinct feature vectors than requested clusters.")
    embedding = None
    embedding_model = None
    clustering_features = features
    if method == "isomap":
        if (
            isinstance(n_neighbors, (bool, np.bool_))
            or not isinstance(n_neighbors, (int, np.integer))
            or not 1 <= n_neighbors < len(features)
        ):
            raise ValueError("ISOMAP n_neighbors must be an integer >= 1 and smaller than the valid sample count.")
        if len(features) > 2000:
            raise ValueError("Dense ISOMAP is limited to 2000 valid samples; analyze a smaller map or crop.")
        graph = NearestNeighbors(n_neighbors=n_neighbors).fit(features).kneighbors_graph(mode="distance")
        if connected_components(graph, directed=False, return_labels=False) != 1:
            raise ValueError("ISOMAP neighbour graph is disconnected; increase n_neighbors or revise the selected features.")
        embedding_model = Isomap(n_neighbors=n_neighbors, n_components=2, eigen_solver="dense")
        embedding = embedding_model.fit_transform(features)
        clustering_features = embedding
        if len(np.unique(embedding, axis=0)) < n_clusters:
            raise ValueError("Fewer distinct ISOMAP coordinates than requested clusters.")
    model: KMeans | GaussianMixture
    if method in ("kmeans", "isomap"):
        model = KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)
    else:
        model = GaussianMixture(
            n_components=n_clusters, random_state=random_state, n_init=3,
            reg_covar=1e-6, max_iter=300,
        )
    predicted = model.fit_predict(clustering_features)
    if len(np.unique(predicted)) != n_clusters:
        raise ValueError("The model produced an empty hard-assignment phase; reduce n_clusters.")
    phase_order = sorted(
        range(n_clusters),
        key=lambda label: (float(np.mean(h[valid][predicted == label])),
                           float(np.mean(e[valid][predicted == label]))),
    )
    remap = np.empty(n_clusters, dtype=np.int64)
    remap[phase_order] = np.arange(1, n_clusters + 1)
    labels = np.zeros(e.shape, dtype=np.int64)
    labels[valid] = remap[predicted]
    return ClusteringResult(
        labels, descriptors, names, features, valid, scaler, model, embedding, embedding_model
    )

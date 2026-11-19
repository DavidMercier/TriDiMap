"""Supplementary methods: KAM descriptors and KMeans clustering.

Dependencies: numpy, pandas, scikit-learn.
Input: pandas DataFrame with X, Y coordinates and H, E in GPa.
Neighbourhood means include the centre; missing grid cells are excluded.
Order r uses the grid shell abs(delta_row) + abs(delta_column) = r.
This file illustrates the numerical method, not the full article benchmark.

Usage: result, scaler, model = cluster_with_kamm(data, n_clusters=3,
           feature_columns=("H", "E", "KAMM"))
"""

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler


def prepare_data(data):
    """Drop invalid/nonpositive measurements and average duplicate positions."""
    cleaned = data[["X", "Y", "H", "E"]].apply(pd.to_numeric, errors="coerce")
    valid = np.isfinite(cleaned).all(axis=1) & (cleaned["H"] > 0) & (cleaned["E"] > 0)
    cleaned = cleaned.loc[valid].copy()
    if cleaned.duplicated(["X", "Y"]).any():
        cleaned = cleaned.groupby(["X", "Y"], as_index=False)[["H", "E"]].mean()
    if len(cleaned) < 2:
        raise ValueError("At least two valid indentation positions are required.")
    return cleaned.reset_index(drop=True)


def _grid_neighbours(data, order):
    """Yield centre and neighbour values from prepared data, including self.

    Any positive integer order r selects abs(delta_row)+abs(delta_column)=r:
    4*r possible neighbours, plus self; inner shells are excluded.
    Orders 1 and 2 retain the four- and eight-neighbour definitions.
    """
    if isinstance(order, (bool, np.bool_)) or not isinstance(order, (int, np.integer)) or order < 1:
        raise ValueError("order must be a positive integer")
    modulus_grid = data.pivot(index="Y", columns="X", values="E")
    hardness_grid = data.pivot(index="Y", columns="X", values="H")
    modulus = modulus_grid.to_numpy()
    hardness = hardness_grid.to_numpy()
    offsets = [(0, 0)]
    for row_offset in range(-order, order + 1):
        column_offset = order - abs(row_offset)
        offsets.append((row_offset, column_offset))
        if column_offset != 0:
            offsets.append((row_offset, -column_offset))
    rows = modulus_grid.index.get_indexer(data["Y"])
    columns = modulus_grid.columns.get_indexer(data["X"])
    for row, column in zip(rows, columns):
        neighbour_modulus = []
        neighbour_hardness = []
        for row_offset, column_offset in offsets:
            other_row = row + row_offset
            other_column = column + column_offset
            if 0 <= other_row < modulus.shape[0] and 0 <= other_column < modulus.shape[1]:
                if np.isfinite(modulus[other_row, other_column]) and np.isfinite(hardness[other_row, other_column]):
                    neighbour_modulus.append(modulus[other_row, other_column])
                    neighbour_hardness.append(hardness[other_row, other_column])
        yield (modulus[row, column], hardness[row, column],
               np.asarray(neighbour_modulus), np.asarray(neighbour_hardness))


def compute_kamm(data, order=1):
    """Kernel average mechanical mismatch: mean(|E_i*H_i - E_j*H_j|), GPa^2."""
    if not np.isfinite(data["E"] * data["H"]).all():
        raise ValueError("E*H must be finite; check the input values and units.")
    values = []
    for modulus, hardness, neighbour_modulus, neighbour_hardness in _grid_neighbours(data, order):
        mismatch = np.abs(modulus * hardness - neighbour_modulus * neighbour_hardness)
        values.append(np.mean(mismatch))
    return data.assign(KAMM=values)


def compute_kaem(data, order=1):
    """Kernel average modulus mismatch: mean(|E_i - E_j|), in GPa."""
    values = []
    for modulus, hardness, neighbour_modulus, neighbour_hardness in _grid_neighbours(data, order):
        mismatch = np.abs(modulus - neighbour_modulus)
        values.append(np.mean(mismatch))
    return data.assign(KAEM=values)


def compute_kapm(data, order=1):
    """Kernel average hardness mismatch: mean(|H_i - H_j|), in GPa."""
    values = []
    for modulus, hardness, neighbour_modulus, neighbour_hardness in _grid_neighbours(data, order):
        mismatch = np.abs(hardness - neighbour_hardness)
        values.append(np.mean(mismatch))
    return data.assign(KAPM=values)


def compute_kamm_ratio(data, order=1):
    """Mean(|(E_i-E_j)/(H_i-H_j+1e-6 GPa)|), dimensionless."""
    values = []
    for modulus, hardness, neighbour_modulus, neighbour_hardness in _grid_neighbours(data, order):
        delta_modulus = modulus - neighbour_modulus
        delta_hardness = hardness - neighbour_hardness
        with np.errstate(divide="ignore", invalid="ignore"):
            mismatch = np.abs(delta_modulus / (delta_hardness + 1e-6))
        values.append(np.mean(mismatch))
    return data.assign(KAMM_RATIO=values)


def compute_kamm_normprod(data, order=1):
    """Mean(delta_E*delta_H/(std(E)*std(H))), signed, dimensionless; ddof=0."""
    modulus_std = max(np.std(data["E"], ddof=0), 1e-12)
    hardness_std = max(np.std(data["H"], ddof=0), 1e-12)
    values = []
    for modulus, hardness, neighbour_modulus, neighbour_hardness in _grid_neighbours(data, order):
        delta_modulus = modulus - neighbour_modulus
        delta_hardness = hardness - neighbour_hardness
        mismatch = delta_modulus * delta_hardness / (modulus_std * hardness_std)
        values.append(np.mean(mismatch))
    return data.assign(KAMM_NORMPROD=values)


def compute_kam(data, order=1):
    """Add all five KAM descriptors by calling their explicit functions."""
    result = compute_kamm(data, order)
    result = compute_kaem(result, order)
    result = compute_kapm(result, order)
    result = compute_kamm_ratio(result, order)
    return compute_kamm_normprod(result, order)


def cluster_with_kamm(data, n_clusters=3, order=1, random_state=0,
                      feature_columns=("H", "E", "KAMM")):
    """Standardize selected features and return labelled data, scaler, KMeans.

    Nonfinite features are mean-imputed (zero if entirely missing).
    Cluster IDs are arbitrary labels, not physical phase identities.
    """
    result = compute_kam(prepare_data(data), order=order)
    if not 1 <= n_clusters <= len(result):
        raise ValueError("n_clusters must be between 1 and the number of valid positions.")
    selected = list(feature_columns)
    available = {"H", "E", "KAMM", "KAEM", "KAPM", "KAMM_RATIO", "KAMM_NORMPROD"}
    if not selected or len(set(selected)) != len(selected) or not set(selected).issubset(available):
        raise ValueError("feature_columns must contain unique H, E or KAM descriptor names.")
    matrix = result[selected].replace([np.inf, -np.inf], np.nan)
    matrix = matrix.fillna(matrix.mean()).fillna(0)
    scaler = StandardScaler()
    features = scaler.fit_transform(matrix)
    model = KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)
    result["Cluster"] = model.fit_predict(features)
    return result, scaler, model

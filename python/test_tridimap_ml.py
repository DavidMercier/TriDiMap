import unittest
import warnings

import numpy as np

from tridimap_ml import cluster_map, kamm_maps


class KammTests(unittest.TestCase):
    def test_reference_shells_and_five_descriptors(self):
        e = np.array([[10., 20.], [30., 40.]])
        first = kamm_maps(e, e / 10)
        np.testing.assert_allclose(first["KAMM"], np.array([[110, 150], [150, 190]]) / 3)
        np.testing.assert_allclose(first["KAEM"], 10)
        np.testing.assert_allclose(first["KAPM"], 1)
        np.testing.assert_allclose(first["KAMM_NORMPROD"], 4 / 3)
        self.assertAlmostEqual(first["KAMM_RATIO"][0, 0], 6.666671666670833)
        second = kamm_maps(e, e / 10, order=2)
        np.testing.assert_allclose(second["KAMM"], [[75, 25], [25, 75]])
        np.testing.assert_allclose(second["KAEM"], [[15, 5], [5, 15]])

    def test_holes_are_not_zero_measurements_or_neighbours(self):
        with self.assertWarns(UserWarning):
            maps = kamm_maps([[10, np.nan], [30, 40]], [[1, np.nan], [3, 4]])
        self.assertTrue(np.isnan(maps["KAMM"][0, 1]))
        self.assertEqual(maps["KAMM"][0, 0], 40)
        for value in kamm_maps(np.full((3, 3), 10), np.ones((3, 3)), order=2).values():
            np.testing.assert_array_equal(value, 0)
        with self.assertRaises(ValueError):
            kamm_maps([[1]], [[1]], order=3)

    def test_models_standardize_preserve_positions_and_order_phases(self):
        h = np.tile([1., 1., 1., 5., 5., 5.], (4, 1))
        e = 20 * h + np.arange(4)[:, None]
        for method in ("kmeans", "gmm"):
            result = cluster_map(e, h, n_clusters=2, method=method)
            again = cluster_map(e, h, n_clusters=2, method=method)
            np.testing.assert_array_equal(result.labels, again.labels)
            np.testing.assert_allclose(result.features.mean(axis=0), 0, atol=1e-12)
            self.assertLess(h[result.labels == 1].mean(), h[result.labels == 2].mean())
            self.assertEqual(result.labels.shape, h.shape)
        h[1, 2] = np.nan
        with warnings.catch_warnings(record=True) as caught:
            result = cluster_map(e, h, n_clusters=2, feature_set="all", order=2)
        self.assertTrue(caught)
        self.assertEqual(result.labels[1, 2], 0)
        self.assertTrue(np.isnan(result.descriptors["KAMM"][1, 2]))
        with self.assertRaises(ValueError):
            cluster_map(np.ones((3, 3)), np.ones((3, 3)), n_clusters=2)


if __name__ == "__main__":
    unittest.main()

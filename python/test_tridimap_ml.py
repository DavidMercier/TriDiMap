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

    def test_isomap_uses_geodesics_and_clusters_embedding_with_holes(self):
        angle = np.linspace(0, np.pi, 80).reshape(10, 8)
        e = 50 + 10 * np.cos(angle)
        h = 3 + np.sin(angle)
        h[2, 3] = np.nan
        with self.assertWarns(UserWarning):
            result = cluster_map(e, h, n_clusters=3, feature_set="eh", method="isomap", n_neighbors=4)
        self.assertEqual(result.labels[2, 3], 0)
        self.assertEqual(result.embedding.shape, (79, 2))
        self.assertEqual(result.labels.shape, h.shape)
        self.assertTrue(np.isfinite(result.embedding).all())
        np.testing.assert_allclose(result.features.mean(axis=0), 0, atol=1e-12)
        direct = np.linalg.norm(result.features[0] - result.features[-1])
        self.assertGreater(result.embedding_model.dist_matrix_[0, -1], 1.3 * direct)
        predicted = result.model.predict(result.embedding)
        phase_order = sorted(
            range(3), key=lambda phase: (h[result.valid][predicted == phase].mean(),
                                        e[result.valid][predicted == phase].mean())
        )
        remap = np.empty(3, dtype=int)
        remap[phase_order] = np.arange(1, 4)
        np.testing.assert_array_equal(result.labels[result.valid], remap[predicted])
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            again = cluster_map(e, h, n_clusters=3, feature_set="eh", method="isomap", n_neighbors=4)
        np.testing.assert_array_equal(result.labels, again.labels)
        np.testing.assert_allclose(result.embedding, again.embedding)

    def test_isomap_rejects_disconnected_graph_and_invalid_neighbour_counts(self):
        e = np.array([[10., 10.1, 10.2, 100., 100.1, 100.2]])
        h = e / 10
        with self.assertRaisesRegex(ValueError, "disconnected"):
            cluster_map(e, h, n_clusters=2, feature_set="eh", method="isomap", n_neighbors=1)
        for neighbours in (0, -1, 6, 1.5, True):
            with self.subTest(neighbours=neighbours), self.assertRaisesRegex(ValueError, "n_neighbors"):
                cluster_map(e, h, n_clusters=2, feature_set="eh", method="isomap", n_neighbors=neighbours)
        connected = cluster_map(e, h, n_clusters=2, feature_set="eh", method="isomap", n_neighbors=3)
        self.assertEqual(connected.embedding.shape, (6, 2))
        baseline = cluster_map(e, h, n_clusters=2, feature_set="eh", n_neighbors=0)
        self.assertIsNone(baseline.embedding)
        self.assertIsNone(baseline.embedding_model)

    def test_isomap_handles_duplicate_samples_and_limits_dense_work(self):
        e = np.array([[10., 10., 20., 20., 30., 30.]])
        result = cluster_map(e, e / 10, n_clusters=3, feature_set="eh", method="isomap", n_neighbors=3)
        self.assertEqual(len(np.unique(result.labels)), 3)
        np.testing.assert_array_equal(result.labels[:, ::2], result.labels[:, 1::2])
        large = np.arange(1., 2026.).reshape(45, 45)
        with self.assertRaisesRegex(ValueError, "2000"):
            cluster_map(large, large / 10, n_clusters=2, feature_set="eh", method="isomap")


if __name__ == "__main__":
    unittest.main()

function TriDiMap_drawClusterEnvelope(points, envelopeType, color, lineWidth)
if envelopeType == 2
    boundary = TriDiMap_clusterHull(points);
    plot(boundary(:, 1), boundary(:, 2), '-', 'Color', color, ...
        'LineWidth', lineWidth, 'Tag', 'TriDiMapClusterEnvelope');
elseif envelopeType == 3
    finite = all(isfinite(points), 2);
    if any(~finite)
        warning('TriDiMap:NonfiniteClusterPoints', ...
            'Ignoring %d nonfinite points when fitting the cluster ellipse.', sum(~finite));
    end
    points = points(finite, :);
    distinct = unique(points, 'rows');
    centered = bsxfun(@minus, distinct, mean(distinct, 1));
    design = [centered(:, 1).^2, centered(:, 1).*centered(:, 2), ...
        centered(:, 2).^2, centered];
    if size(distinct, 1) < 5 || rank(design) < 5
        warning('TriDiMap:ClusterEllipseUnavailable', ...
            'An ellipse requires at least five distinct, nondegenerate points; this phase has no ellipse.');
        return
    end
    ellipse = fit_ellipse(points(:, 1), points(:, 2), gca, 1, color);
    if isempty(ellipse) || ~isempty(ellipse.status)
        warning('TriDiMap:ClusterEllipseUnavailable', ...
            'The fitted conic is not a valid ellipse; this phase has no ellipse.');
    end
end
end

function boundary = TriDiMap_clusterHull(points)
if ~isnumeric(points) || ~isreal(points) || ~ismatrix(points) || size(points, 2) ~= 2
    error('TriDiMap:InvalidClusterPoints', 'Cluster points must be a real numeric N-by-2 array.');
end
finiteRows = all(isfinite(points), 2);
if any(~finiteRows)
    warning('TriDiMap:NonfiniteClusterPoints', ...
        'Ignoring %d nonfinite points when drawing the cluster envelope.', sum(~finiteRows));
end
points = unique(points(finiteRows, :), 'rows');
if size(points, 1) <= 2
    boundary = points;
elseif rank(bsxfun(@minus, points, points(1, :))) < 2
    boundary = points([1, end], :);
else
    indices = convhull(points(:, 1), points(:, 2));
    boundary = points(indices, :);
end
end

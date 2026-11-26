function [embedding, model] = TriDiMap_isomap(features, neighbours)
% Connected k-neighbour geodesics followed by classical metric MDS.
validateattributes(features, {'numeric'}, {'real', 'finite', 'nonempty', '2d'});
features = double(features);
N = size(features, 1);
if ~isnumeric(neighbours) || ~isreal(neighbours) || ~isscalar(neighbours) || ...
        ~isfinite(neighbours) || neighbours < 1 || ...
        neighbours ~= fix(neighbours) || neighbours >= N
    error('TriDiMap:IsomapInput', ...
        'ISOMAP neighbours must be an integer >= 1 and smaller than the valid sample count.');
end
if N > 2000
    error('TriDiMap:IsomapInput', ...
        'Dense ISOMAP is limited to 2000 valid samples; analyze a smaller map or crop.');
end
distances = zeros(N);
for ii = 1:N
    distances(ii, :) = sqrt(sum(bsxfun(@minus, features, features(ii, :)).^2, 2))';
end
distances(1:N+1:end) = Inf;
[~, nearest] = sort(distances, 2);
geodesic = Inf(N);
for ii = 1:N
    selected = nearest(ii, 1:neighbours);
    geodesic(ii, selected) = distances(ii, selected);
end
geodesic = min(geodesic, geodesic');
geodesic(1:N+1:end) = 0;
reached = false(N, 1);
reached(1) = true;
frontier = 1;
while ~isempty(frontier)
    adjacent = any(isfinite(geodesic(frontier, :)), 1)';
    frontier = find(adjacent & ~reached);
    reached(frontier) = true;
end
if ~all(reached)
    error('TriDiMap:IsomapDisconnected', ...
        'ISOMAP neighbour graph is disconnected; increase neighbours or revise the selected features.');
end
for ii = 1:N
    geodesic = min(geodesic, bsxfun(@plus, geodesic(:, ii), geodesic(ii, :)));
end
squared = geodesic.^2;
kernel = -0.5 * bsxfun(@plus, ...
    bsxfun(@minus, bsxfun(@minus, squared, mean(squared, 1)), mean(squared, 2)), ...
    mean(squared(:)));
kernel = (kernel + kernel')/2;
[vectors, diagonal] = eig(kernel);
[eigenvalues, indices] = sort(diag(diagonal), 'descend');
tolerance = N * eps(max(abs(eigenvalues)));
positive = find(eigenvalues > tolerance);
if isempty(positive)
    error('TriDiMap:IsomapInput', 'ISOMAP has no positive embedding eigenvalues; revise the selected features.');
end
dimensions = min(2, numel(positive));
embedding = zeros(N, 2);
for ii = 1:dimensions
    vector = vectors(:, indices(ii));
    [~, pivot] = max(abs(vector));
    if vector(pivot) < 0
        vector = -vector;
    end
    embedding(:, ii) = vector * sqrt(eigenvalues(ii));
end
model = struct('neighbours', neighbours, 'dimensions', dimensions, ...
    'eigenvalues', eigenvalues, 'geodesicDistances', geodesic);
end

function model = TriDiMap_som(features, K)
validateattributes(features, {'numeric'}, {'real', 'finite', 'nonempty', '2d'});
features = double(features);
N = size(features, 1);
if ~isscalar(K) || ~isfinite(K) || K < 2 || K ~= fix(K) || K > 100 || K > N
    error('TriDiMap:SOMInput', 'SOM requires 2 to 100 phases and at least as many valid samples.');
end
side = max(ceil(sqrt(K)), min(10, ceil(sqrt(5*sqrt(N)))));
[column, row] = meshgrid(1:side, 1:side);
positions = [column(:), row(:)];
nodeCount = size(positions, 1);

[~, ~, directions] = svd(bsxfun(@minus, features, mean(features, 1)), 'econ');
projection = features * directions(:, 1);
[~, sorted] = sort(projection);
initial = round(linspace(1, N, nodeCount));
weights = features(sorted(initial), :);
gridDistance = zeros(nodeCount);
for ii = 1:nodeCount
    gridDistance(ii, :) = sum(bsxfun(@minus, positions, positions(ii, :)).^2, 2)';
end

for iteration = 1:80
    bmu = bestMatchingUnits(features, weights);
    counts = accumarray(bmu, 1, [nodeCount, 1]);
    totals = zeros(nodeCount, size(features, 2));
    for jj = 1:size(features, 2)
        totals(:, jj) = accumarray(bmu, features(:, jj), [nodeCount, 1]);
    end
    radius = (side/2) * (0.5/(side/2))^((iteration-1)/79);
    neighbourhood = exp(-gridDistance/(2*radius^2));
    weights = bsxfun(@rdivide, neighbourhood * totals, neighbourhood * counts);
end
bmu = bestMatchingUnits(features, weights);
counts = accumarray(bmu, 1, [nodeCount, 1]);
u = zeros(nodeCount, 1);
for ii = 1:nodeCount
    adjacent = gridDistance(ii, :) == 1;
    differences = bsxfun(@minus, weights(adjacent, :), weights(ii, :));
    u(ii) = mean(sqrt(sum(differences.^2, 2)));
end
model = struct('weights', weights, 'bmu', bmu, 'positions', positions, ...
    'counts', reshape(counts, side, side), 'uMatrix', reshape(u, side, side));
end

function bmu = bestMatchingUnits(features, weights)
N = size(features, 1);
best = Inf(N, 1);
bmu = zeros(N, 1);
for ii = 1:size(weights, 1)
    distance = sum(bsxfun(@minus, features, weights(ii, :)).^2, 2);
    selected = distance < best;
    best(selected) = distance(selected);
    bmu(selected) = ii;
end
end

function result = TriDiMap_mlCluster(E, H, featureMode, method, order, K, gridAvailable, neighbours)
if nargin < 7
    gridAvailable = true;
end
if nargin < 8
    neighbours = 10;
end
if ~isscalar(featureMode) || ~ismember(featureMode, 1:4) || ...
        ~isscalar(method) || ~ismember(method, 1:3) || ...
        ~isscalar(K) || ~isfinite(K) || K < 2 || K ~= fix(K)
    error('TriDiMap:MLInput', 'Choose a feature mode, method and integer phase count >= 2.');
end
if ~gridAvailable && ismember(featureMode, [2, 4])
    error('TriDiMap:KAMMRequiresGrid', ...
        'Neighbourhood feature modes require a raster map; use H,E or mechanical ratios for irregular XY.');
end
validateattributes(E, {'numeric'}, {'real', 'nonempty', '2d'});
validateattributes(H, {'numeric'}, {'real', 'size', size(E)});
E = double(E);
H = double(H);
maps = struct;
if gridAvailable
    maps = TriDiMap_kamm(E, H, order);
end
matrix = [H(:), E(:)];
names = {'H', 'E'};
if featureMode == 2
    matrix = [matrix, maps.KAMM(:)];
    names{3} = 'KAMM';
elseif featureMode >= 3
    ratios = [H(:)./E(:), H(:).^3./E(:).^2];
    if featureMode == 3
        matrix = ratios;
        names = {'H/E', 'H^3/E^2'};
    else
        matrix = [matrix, ratios];
        names = [names, {'H/E', 'H^3/E^2'}];
        descriptors = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
        for ii = 1:numel(descriptors)
            map = maps.(descriptors{ii});
            matrix(:, end+1) = map(:);
        end
        names = [names, descriptors];
    end
end
valid = isfinite(E(:)) & isfinite(H(:)) & E(:) > 0 & H(:) > 0 & all(isfinite(matrix), 2);
if any(~valid)
    warning('TriDiMap:MLExcludedPairs', ...
        'Excluding %d invalid/nonpositive measurements or nonfinite selected feature vectors.', sum(~valid));
end
matrix = matrix(valid, :);
if size(matrix, 1) < K
    error('TriDiMap:MLInput', 'There are fewer valid feature vectors than requested phases.');
end
center = mean(matrix, 1);
scale = std(matrix, 1, 1);
scale(scale == 0) = 1;
features = bsxfun(@rdivide, bsxfun(@minus, matrix, center), scale);
if size(unique(features, 'rows'), 1) < K
    error('TriDiMap:MLInput', 'There are fewer distinct feature vectors than requested phases.');
end
embedding = [];
isomapModel = [];
clusteringFeatures = features;
if method == 3
    [embedding, isomapModel] = TriDiMap_isomap(features, neighbours);
    clusteringFeatures = embedding;
    if size(unique(embedding, 'rows'), 1) < K
        error('TriDiMap:MLInput', 'There are fewer distinct ISOMAP coordinates than requested phases.');
    end
end
if method == 1 || method == 3
    [labels, model] = lloyd(clusteringFeatures, K);
else
    if exist('fitgmdist', 'file') ~= 2 || ~license('test', 'Statistics_Toolbox')
        error('TriDiMap:MLToolbox', ...
            'ML GMM requires Statistics and Machine Learning Toolbox. Choose base-MATLAB K-means or the Python notebook.');
    end
    previousRng = rng;
    cleanup = onCleanup(@() rng(previousRng));
    rng(0, 'twister');
    model = fitgmdist(features, K, 'RegularizationValue', 1e-6, ...
        'Replicates', 3, 'Options', statset('MaxIter', 300));
    labels = cluster(model, features);
    if ~model.Converged
        warning('TriDiMap:MLNotConverged', 'GMM reached its iteration limit; inspect the result.');
    end
end
means = zeros(K, 2);
rawH = H(valid);
rawE = E(valid);
for ii = 1:K
    if ~any(labels == ii)
        error('TriDiMap:MLInput', 'The model produced an empty hard-assignment phase; reduce the phase count.');
    end
    means(ii, :) = [mean(rawH(labels == ii)), mean(rawE(labels == ii))];
end
[~, orderLabels] = sortrows(means, [1, 2]);
remap = zeros(K, 1);
remap(orderLabels) = 1:K;
assigned = zeros(size(H));
assigned(valid) = remap(labels);
result = struct('labels', assigned, 'maps', maps, 'featureNames', {names}, ...
    'center', center, 'scale', scale, 'features', features, 'valid', reshape(valid, size(H)), ...
    'phaseMeans', means(orderLabels, :), 'model', model, ...
    'embedding', embedding, 'isomapModel', isomapModel);
end

function [bestLabels, bestCenters] = lloyd(features, K)
N = size(features, 1);
bestCost = Inf;
for first = unique(round(linspace(1, N, min(5, N))))
    centers = features(first, :);
    closest = Inf(N, 1);
    for ii = 2:K
        closest = min(closest, sum(bsxfun(@minus, features, centers(end, :)).^2, 2));
        [~, next] = max(closest);
        centers(ii, :) = features(next, :);
    end
    labels = zeros(N, 1);
    for iteration = 1:300
        distances = zeros(N, K);
        for ii = 1:K
            distances(:, ii) = sum(bsxfun(@minus, features, centers(ii, :)).^2, 2);
        end
        [nearest, updated] = min(distances, [], 2);
        for ii = 1:K
            if ~any(updated == ii)
                [~, next] = max(nearest);
                updated(next) = ii;
                nearest(next) = -Inf;
            end
        end
        if isequal(labels, updated)
            break
        end
        labels = updated;
        for ii = 1:K
            centers(ii, :) = mean(features(labels == ii, :), 1);
        end
    end
    cost = sum(sum((features - centers(labels, :)).^2));
    if cost < bestCost
        bestCost = cost;
        bestLabels = labels;
        bestCenters = centers;
        bestIteration = iteration;
    end
end
if bestIteration == 300
    warning('TriDiMap:MLNotConverged', 'K-means reached its iteration limit; inspect the result.');
end
end

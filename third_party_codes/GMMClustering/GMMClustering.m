function [labels, model, data] = GMMClustering(K, x, varargin)
if nargin == 0
    K = 2;
    x = getData;
elseif nargin == 1
    x = getData;
end

if ~isnumeric(K) || ~isscalar(K) || ~isfinite(K) || K < 2 || K ~= fix(K)
    error('TriDiMap:GMMInput', 'The number of phases must be an integer greater than or equal to 2.');
end
if ~isnumeric(x) || ~isreal(x) || ndims(x) ~= 2 || isempty(x) || ...
        any(~isfinite(x(:))) || size(x, 1) < K || size(x, 2) ~= 2
    error('TriDiMap:GMMInput', 'GMM input must contain at least K finite two-dimensional observations.');
end

data = double(x);
if size(unique(data, 'rows'), 1) < K
    error('TriDiMap:GMMInput', 'GMM input must contain at least K distinct observations.');
end

center = mean(data, 1);
scale = std(data, 1, 1);
scale(scale == 0) = 1;
features = bsxfun(@rdivide, bsxfun(@minus, data, center), scale);

previousState = rng;
restoreRng = onCleanup(@() rng(previousState));
rng(0, 'twister');

bestLogLikelihood = -Inf;
bestLabels = [];
for start = 1:5
    initialLabels = initializeKMeans(features, K);
    [candidateLabels, means, covariances, weights, logLikelihood] = ...
        fitMixture(features, initialLabels, K);
    if logLikelihood > bestLogLikelihood
        bestLogLikelihood = logLikelihood;
        bestLabels = candidateLabels;
        bestMeans = means;
        bestCovariances = covariances;
        bestWeights = weights;
    end
end

if isempty(bestLabels)
    error('TriDiMap:GMMFit', 'Unable to fit a finite Gaussian mixture to the data.');
end

means = bsxfun(@plus, bsxfun(@times, bestMeans, scale), center);
[~, order] = sortrows(means, [1, 2]);
phaseMap = zeros(K, 1);
phaseMap(order) = 1:K;
labels = phaseMap(bestLabels);

model.means = means(order, :);
model.covariances = cell(K, 1);
for ii = 1:K
    covariance = bestCovariances{order(ii)};
    model.covariances{ii} = covariance .* (scale(:) * scale(:)');
end
model.weights = bestWeights(order);
model.logLikelihood = bestLogLikelihood - size(data, 1) * sum(log(scale));

clear restoreRng;
end

function labels = initializeKMeans(features, K)
N = size(features, 1);
bestCost = Inf;
labels = zeros(N, 1);

for start = 1:5
    centers = features(randperm(N, K), :);
    previousLabels = zeros(N, 1);
    for iteration = 1:100
        distances = pointDistances(features, centers);
        [nearestDistance, updatedLabels] = min(distances, [], 2);

        emptyClusters = setdiff((1:K)', unique(updatedLabels));
        for ii = 1:numel(emptyClusters)
            [~, farthest] = max(nearestDistance);
            updatedLabels(farthest) = emptyClusters(ii);
            nearestDistance(farthest) = -Inf;
        end

        updatedCenters = zeros(K, size(features, 2));
        for ii = 1:K
            updatedCenters(ii, :) = mean(features(updatedLabels == ii, :), 1);
        end
        if isequal(updatedLabels, previousLabels)
            centers = updatedCenters;
            break
        end
        previousLabels = updatedLabels;
        centers = updatedCenters;
    end

    distances = pointDistances(features, centers);
    linearIndices = sub2ind(size(distances), (1:N)', updatedLabels);
    cost = sum(distances(linearIndices));
    if cost < bestCost
        bestCost = cost;
        labels = updatedLabels;
    end
end
end

function distances = pointDistances(features, centers)
N = size(features, 1);
K = size(centers, 1);
distances = zeros(N, K);
for ii = 1:K
    distances(:, ii) = sum(bsxfun(@minus, features, centers(ii, :)).^2, 2);
end
end

function [labels, means, covariances, weights, logLikelihood] = fitMixture(features, labels, K)
N = size(features, 1);
D = size(features, 2);
regularization = 1e-6;
means = zeros(K, D);
covariances = cell(K, 1);
counts = zeros(K, 1);
for ii = 1:K
    selected = features(labels == ii, :);
    counts(ii) = size(selected, 1);
    means(ii, :) = mean(selected, 1);
    residuals = bsxfun(@minus, selected, means(ii, :));
    covariances{ii} = (residuals' * residuals) / counts(ii) + regularization * eye(D);
end
weights = counts / N;

previousLogLikelihood = -Inf;
logLikelihood = -Inf;
for iteration = 1:300
    logProbabilities = zeros(N, K);
    for ii = 1:K
        logProbabilities(:, ii) = log(weights(ii)) + ...
            logGaussianPDF(features, means(ii, :), covariances{ii});
    end

    rowMaximum = max(logProbabilities, [], 2);
    shifted = bsxfun(@minus, logProbabilities, rowMaximum);
    probability = exp(shifted);
    rowSum = sum(probability, 2);
    if any(~isfinite(rowMaximum)) || any(rowSum == 0) || any(~isfinite(rowSum))
        logLikelihood = -Inf;
        return
    end
    logLikelihood = sum(rowMaximum + log(rowSum));
    responsibilities = bsxfun(@rdivide, probability, rowSum);

    if iteration > 1 && abs(logLikelihood - previousLogLikelihood) <= ...
            1e-8 * (1 + abs(previousLogLikelihood))
        break
    end
    previousLogLikelihood = logLikelihood;

    counts = sum(responsibilities, 1);
    if any(counts <= eps * N)
        logLikelihood = -Inf;
        return
    end
    weights = counts / N;
    means = bsxfun(@rdivide, responsibilities' * features, counts');
    for ii = 1:K
        residuals = bsxfun(@minus, features, means(ii, :));
        covariances{ii} = bsxfun(@times, residuals, responsibilities(:, ii))' * ...
            residuals / counts(ii) + regularization * eye(D);
        covariances{ii} = (covariances{ii} + covariances{ii}') / 2;
    end
end

[~, labels] = max(responsibilities, [], 2);
end

function logDensity = logGaussianPDF(features, meanValue, covariance)
[upper, errorFlag] = chol(covariance);
if errorFlag ~= 0
    logDensity = -Inf(size(features, 1), 1);
    return
end
residuals = bsxfun(@minus, features, meanValue) / upper;
logDensity = -0.5 * (size(features, 2) * log(2*pi) + ...
    2 * sum(log(diag(upper))) + sum(residuals.^2, 2));
end

function data = getData
A1 = mvnrnd([-1, 0.3], [.5, .4; .4, .6], 1000);
A2 = mvnrnd([-3, 0.3], [.5, .4; .4, .6], 1000);
A3 = mvnrnd([-2, 0.5], [.5, -.4; -.4, .6], 1000);
data = [A1; A2; A3];
end

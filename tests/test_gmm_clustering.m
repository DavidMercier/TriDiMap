function test_gmm_clustering
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'third_party_codes', 'GMMClustering'));

offsets = [-0.4, -1; -0.4, 1; 0, -1; 0, 1; 0.4, -1; 0.4, 1];
centers = [2, 20; 5, 40; 8, 60];
data = [bsxfun(@plus, offsets, centers(1, :)); ...
    bsxfun(@plus, offsets, centers(2, :)); ...
    bsxfun(@plus, offsets, centers(3, :))];

[labels, model, returnedData] = GMMClustering(3, data);
[repeatLabels] = GMMClustering(3, data);
assert(isequal(labels, repeatLabels));
assert(isequal(returnedData, data));
assert(isequal(unique(labels), (1:3)'));
phaseMeans = accumarray(labels, data(:, 1), [3, 1], @mean);
assert(all(diff(phaseMeans) > 0));
assert(isequal(size(model.means), [3, 2]));
assert(numel(model.covariances) == 3);
assert(abs(sum(model.weights) - 1) < 1e-12);
assert(isfinite(model.logLikelihood));

twoPhaseData = data(1:12, :);
[twoPhaseLabels, twoPhaseModel] = GMMClustering(2, twoPhaseData);
assert(isequal(unique(twoPhaseLabels), (1:2)'));
twoPhaseMeans = accumarray(twoPhaseLabels, twoPhaseData(:, 1), [2, 1], @mean);
assert(all(diff(twoPhaseMeans) > 0));
assert(abs(sum(twoPhaseModel.weights) - 1) < 1e-12);

fourPhaseCenters = [2, 20; 5, 40; 8, 60; 11, 80];
fourPhaseData = [bsxfun(@plus, offsets, fourPhaseCenters(1, :)); ...
    bsxfun(@plus, offsets, fourPhaseCenters(2, :)); ...
    bsxfun(@plus, offsets, fourPhaseCenters(3, :)); ...
    bsxfun(@plus, offsets, fourPhaseCenters(4, :))];
[fourPhaseLabels, fourPhaseModel] = GMMClustering(4, fourPhaseData);
assert(isequal(unique(fourPhaseLabels), (1:4)'));
assert(isequal(size(fourPhaseModel.means), [4, 2]));
assert(abs(sum(fourPhaseModel.weights) - 1) < 1e-12);
disp('GMM clustering tests passed.');
end

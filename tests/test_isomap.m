function test_isomap
root = fileparts(fileparts(mfilename('fullpath')));
previous = path;
cleanup = onCleanup(@() path(previous));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'gui'));
angle = reshape(linspace(0, pi, 80), 10, 8);
E = 50 + 10*cos(angle);
H = 3 + sin(angle);
H(2, 3) = NaN;
state = rng;
a = TriDiMap_mlCluster(E, H, 1, 3, 1, 3, true, 4);
b = TriDiMap_mlCluster(E, H, 1, 3, 1, 3, true, 4);
assert(isequal(a.labels, b.labels) && isequal(rng, state));
assert(isequal(size(a.embedding), [79, 2]) && all(isfinite(a.embedding(:))));
assert(a.labels(2, 3) == 0 && isequal(size(a.labels), size(H)));
direct = norm(a.features(1, :) - a.features(end, :));
assert(a.isomapModel.geodesicDistances(1, end) > 1.3*direct);
assert(max(abs(mean(a.features, 1))) < 1e-12);
assert(all(diff(a.phaseMeans(:, 1)) >= 0));
centers = a.model;
distances = zeros(size(a.embedding, 1), 3);
for ii = 1:3
    residual = bsxfun(@minus, a.embedding, centers(ii, :));
    distances(:, ii) = sum(residual.^2, 2);
end
[~, predicted] = min(distances, [], 2);
for ii = 1:3
    assigned = a.labels(a.valid);
    assert(numel(unique(assigned(predicted == ii))) == 1);
end
duplicates = [10, 10, 20, 20, 30, 30];
duplicateResult = TriDiMap_mlCluster(duplicates, duplicates/10, 1, 3, 1, 3, false, 3);
assert(numel(unique(duplicateResult.labels)) == 3);
assert(isequal(duplicateResult.labels(1:2:end), duplicateResult.labels(2:2:end)));
separated = [10; 10.1; 10.2; 100; 100.1; 100.2];
expectError(@() TriDiMap_isomap(separated, 1), 'TriDiMap:IsomapDisconnected');
for neighbours = [0, -1, 6, 1.5]
    expectError(@() TriDiMap_isomap(separated, neighbours), 'TriDiMap:IsomapInput');
end
expectError(@() TriDiMap_isomap(ones(2001, 2), 10), 'TriDiMap:IsomapInput');
fig = figure('Visible', 'off');
closeFigure = onCleanup(@() close(fig));
ax = axes('Parent', fig);
gui.data = struct;
gui.handles.pb_mlExport_GUI = uicontrol('Parent', fig, 'Visible', 'off');
gui.config = struct('strUnit_Property', {{'GPa'}}, 'strUnit_Length', {{'um'}}, ...
    'mlFeatures', 1, 'mlMethod', 3, 'mlNeighbours', 4, 'mlOrder', 1, ...
    'mlK', 3, 'mlView', 6, 'mlMetric', 1, 'MinXCrop', 1, 'MinYCrop', 1, ...
    'XStep', 1, 'YStep', 1, 'FontSizeVal', 12, 'logZ', true, ...
    'minorTicks', false, 'MinMax', false, 'grid', false);
gui = TriDiMap_runML(gui, E, H);
assert(strcmp(get(get(ax, 'XLabel'), 'String'), 'ISOMAP coordinate 1'));
assert(strcmp(get(ax, 'XScale'), 'linear'));
gui.ml.result.cacheNote = 'preserve embedding across views';
before = gui.ml.result;
gui.config.mlView = 2;
gui = TriDiMap_runML(gui, E, H);
assert(isequaln(gui.ml.result, before));
file = [tempname, '.csv'];
deleteExport = onCleanup(@() delete(file));
guidata(fig, gui);
TriDiMap_exportML(file);
exported = dlmread(file, ',', 1, 0);
assert(isequaln(exported(:, 3:5), [H(:), E(:), before.labels(:)]));
missingEmbedding = exported(~before.valid(:), end-1:end);
assert(all(isnan(missingEmbedding(:))));
assert(isequaln(exported(before.valid(:), end-1:end), before.embedding));
gui.config.mlNeighbours = 5;
gui = TriDiMap_runML(gui, E, H);
assert(gui.ml.result.isomapModel.neighbours == 5 && ~isfield(gui.ml.result, 'cacheNote'));
gui.config.mlMethod = 1;
gui.config.mlView = 6;
expectError(@() TriDiMap_runML(gui, E, H), 'TriDiMap:IsomapInput');
disp('ISOMAP geodesics, clustering, holes, embedding display, cache and CSV checks passed.');
end

function expectError(callback, identifier)
try
    callback();
    error('TriDiMap:MissingError', 'Expected rejection of invalid ISOMAP input.');
catch exception
    assert(strcmp(exception.identifier, identifier));
end
end

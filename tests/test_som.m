function test_som
root = fileparts(fileparts(mfilename('fullpath')));
previous = path;
cleanup = onCleanup(@() path(previous));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'gui'));

H = [ones(4, 8); 4*ones(4, 8)] + reshape(linspace(0, 0.1, 64), 8, 8);
E = 20*H + 10;
H(1, 1) = NaN;
state = rng;
a = TriDiMap_mlCluster(E, H, 1, 4, 1, 2, true);
b = TriDiMap_mlCluster(E, H, 1, 4, 1, 2, true);
assert(isequaln(a.labels, b.labels) && isequal(rng, state));
assert(a.labels(1, 1) == 0 && all(a.labels(a.valid) > 0));
assert(all(diff(a.phaseMeans(:, 1)) > 0));
assert(all(all(a.labels(2:4, :) == 1)) && all(all(a.labels(5:8, :) == 2)));
assigned = a.labels(a.valid);
assert(isequal(assigned, a.somModel.nodeLabels(a.somModel.bmu)));
assert(sum(a.somModel.counts(:)) == sum(a.valid(:)));
assert(all(isfinite(a.somModel.uMatrix(:))) && all(a.somModel.uMatrix(:) >= 0));
adjacent = sum(abs(bsxfun(@minus, a.somModel.positions, a.somModel.positions(1, :))), 2) == 1;
differences = bsxfun(@minus, a.somModel.weights(adjacent, :), a.somModel.weights(1, :));
assert(abs(a.somModel.uMatrix(1) - mean(sqrt(sum(differences.^2, 2)))) < 1e-12);
kamm = TriDiMap_mlCluster(E, H, 2, 4, 1, 2, true);
assert(strcmp(kamm.featureNames{3}, 'KAMM') && all(kamm.labels(kamm.valid) > 0));
irregular = TriDiMap_mlCluster(E(:), H(:), 1, 4, 1, 2, false);
assert(irregular.labels(1) == 0 && all(irregular.labels(irregular.valid) > 0));
expectError(@() TriDiMap_som((1:101)', 101), 'TriDiMap:SOMInput');
expectError(@() TriDiMap_mlCluster(E, H, 1, 4, 1, 64, true), 'TriDiMap:MLInput');

fig = figure('Visible', 'off');
closeFigure = onCleanup(@() close(fig));
ax = axes('Parent', fig);
handles.MainWindow = fig;
handles.bg_property_GUI_3 = uipanel('Parent', fig);
handles.bg2_property_GUI_3 = uipanel('Parent', fig);
handles.pm_sectPlot_GUI = uicontrol('Parent', fig, 'Style', 'popupmenu');
handles = TriDiMap_addMLControls(handles);
methods = get(handles.pm_mlMethod_GUI, 'String');
views = get(handles.pm_mlView_GUI, 'String');
assert(strcmp(methods{4}, 'SOM + K-means (base MATLAB)'));
assert(strcmp(views{7}, 'SOM clusters') && strcmp(views{8}, 'SOM U-matrix'));
gui.data = struct;
gui.handles.pb_mlExport_GUI = uicontrol('Parent', fig, 'Visible', 'off');
gui.config = struct('strUnit_Property', {{'GPa'}}, 'strUnit_Length', {{'um'}}, ...
    'mlFeatures', 1, 'mlMethod', 4, 'mlOrder', 1, 'mlK', 2, ...
    'mlView', 7, 'mlMetric', 1, 'MinXCrop', 1, 'MinYCrop', 1, ...
    'XStep', 1, 'YStep', 1, 'FontSizeVal', 12, 'logZ', false, ...
    'minorTicks', false, 'MinMax', false, 'grid', false);
gui = TriDiMap_runML(gui, E, H);
assert(strcmp(get(get(ax, 'Title'), 'String'), 'SOM clusters (occupied nodes)'));
gui.ml.result.cacheNote = 'preserve across views';
before = gui.ml.result;
gui.config.mlView = 8;
gui = TriDiMap_runML(gui, E, H);
assert(strcmp(get(get(ax, 'Title'), 'String'), 'SOM U-matrix'));
assert(isequaln(gui.ml.result, before));
gui.config.mlView = 1;
gui = TriDiMap_runML(gui, E, H);
xLimits = get(ax, 'XLim');
yLimits = get(ax, 'YLim');
assert(xLimits(1) <= min(H(a.valid)) && xLimits(2) >= max(H(a.valid)));
assert(yLimits(1) <= min(E(a.valid)) && yLimits(2) >= max(E(a.valid)));
gui.config.mlView = 2;
gui = TriDiMap_runML(gui, E, H);
assert(isequaln(gui.ml.result, before));

file = [tempname, '.csv'];
deleteExport = onCleanup(@() delete(file));
guidata(fig, gui);
TriDiMap_exportML(file);
exported = dlmread(file, ',', 1, 0);
assert(all(all(isnan(exported(~before.valid(:), end-1:end)))));
assert(isequal(exported(before.valid(:), end-1:end), ...
    before.somModel.positions(before.somModel.bmu, :)));
gui.config.mlMethod = 1;
gui.config.mlView = 7;
expectError(@() TriDiMap_runML(gui, E, H), 'TriDiMap:SOMInput');
disp('SOM clustering, map views, cache and CSV checks passed.');
end

function expectError(callback, identifier)
try
    callback();
    error('TriDiMap:MissingError', 'Expected rejection of invalid SOM input.');
catch exception
    assert(strcmp(exception.identifier, identifier));
end
end

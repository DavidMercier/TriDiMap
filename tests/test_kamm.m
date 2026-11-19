function test_kamm
root = fileparts(fileparts(mfilename('fullpath')));
previous = path;
cleanup = onCleanup(@() path(previous));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'util'));
addpath(fullfile(root, 'matlab_code', 'loading_data'));
descriptor = [0, NaN, 2000; -2, 4, 6000];
[filled, ratio] = TriDiMap_cleaningData(descriptor, true);
assert(isequaln(descriptor, [0, NaN, 2000; -2, 4, 6000]));
assert(filled(1, 2) == mean([0, -2, 4, 2000, 6000]));
assert(isequal(filled([1, 2, 4, 5, 6]), descriptor([1, 2, 4, 5, 6])));
assert(ratio == 16.67);
[filled, ~] = TriDiMap_cleaningData([NaN, 0, -2, 2000], true);
assert(isequal(filled, [0, 0, -2, 2000]));
E = [10, 20; 30, 40];
H = E/10;
first = TriDiMap_kamm(E, H, 1);
assert(max(abs(first.KAMM(:) - [110; 150; 150; 190]/3)) < 1e-12);
assert(all(first.KAEM(:) == 10) && all(first.KAPM(:) == 1));
assert(max(abs(first.KAMM_NORMPROD(:) - 4/3)) < 1e-12);
assert(abs(first.KAMM_RATIO(1, 1) - 6.666671666670833) < 1e-12);
second = TriDiMap_kamm(E, H, 2);
assert(isequal(second.KAMM, [75, 25; 25, 75]));
assert(isequal(second.KAEM, [15, 5; 5, 15]));
missing = TriDiMap_kamm([10, NaN; 30, 40], [1, NaN; 3, 4], 1);
assert(isnan(missing.KAMM(1, 2)));
assert(missing.KAMM(1, 1) == 40 && missing.neighbourCount(1, 1) == 2);
constant = TriDiMap_kamm(10*ones(3), ones(3), 2);
assert(all(constant.KAMM(:) == 0) && all(constant.KAMM_NORMPROD(:) == 0));
H = [ones(4, 3), 5*ones(4, 3)];
E = 20*H + repmat((1:4)', 1, 6);
state = rng;
a = TriDiMap_mlCluster(E, H, 2, 1, 1, 2);
b = TriDiMap_mlCluster(E, H, 2, 1, 1, 2);
assert(isequal(a.labels, b.labels) && isequal(rng, state));
assert(isequal(size(a.labels), size(H)) && all(a.labels(:) > 0));
assert(a.phaseMeans(1, 1) < a.phaseMeans(2, 1));
assert(max(abs(mean(a.features, 1))) < 1e-12);
H(2, 3) = NaN;
missing = TriDiMap_mlCluster(E, H, 4, 1, 2, 2);
assert(missing.labels(2, 3) == 0 && isnan(missing.maps.KAMM(2, 3)));
try
    TriDiMap_mlCluster(ones(3), ones(3), 2, 1, 1, 2);
    error('TriDiMap:MissingError', 'Expected rejection of indistinguishable features.');
catch exception
    assert(strcmp(exception.identifier, 'TriDiMap:MLInput'));
end
addpath(fullfile(root, 'matlab_code', 'gui'));
fig = figure('Visible', 'off');
closeFigure = onCleanup(@() close(fig));
ax = axes('Parent', fig);
gui.data = struct;
gui.handles.pb_mlExport_GUI = uicontrol('Parent', fig, 'Visible', 'off');
gui.config = struct('strUnit_Property', {{'GPa'}}, 'strUnit_Length', {{'um'}}, ...
    'mlFeatures', 2, 'mlMethod', 1, 'mlOrder', 1, 'mlK', 2, 'mlView', 1, 'mlMetric', 1, ...
    'MinXCrop', 3, 'MinYCrop', 4, 'XStep', 2, 'YStep', 3, ...
    'FontSizeVal', 12, 'logZ', false, 'minorTicks', false, 'MinMax', false, 'grid', false);
H = H + repmat(0.02*(1:6), 4, 1);
gui = TriDiMap_runML(gui, E, H);
gui.ml.result.cacheNote = 'preserve across views';
before = gui.ml.result;
gui.config.mlView = 2;
gui = TriDiMap_runML(gui, E, H);
image = findall(ax, 'Tag', 'TriDiMapMLMap');
expected = double(before.labels');
expected(expected == 0) = NaN;
assert(isequaln(get(image, 'CData'), expected));
xExtent = get(image, 'XData');
yExtent = get(image, 'YData');
assert(isequal([xExtent(1), xExtent(end)], [4, 10]) && ...
    isequal([yExtent(1), yExtent(end)], [9, 24]));
gui.config.mlView = 3;
gui.config.mlMetric = 2;
gui = TriDiMap_runML(gui, E, H);
assert(isequaln(get(findall(ax, 'Tag', 'TriDiMapMLMap'), 'CData'), before.maps.KAEM'));
gui.config.mlView = 4;
gui = TriDiMap_runML(gui, E, H);
assert(numel(findall(ax, 'Tag', 'TriDiMapPhaseDensity')) == 2);
assert(isequaln(gui.ml.result, before));
guidata(fig, gui);
file = [tempname, '.csv'];
deleteExport = onCleanup(@() delete(file));
TriDiMap_exportML(file);
exported = dlmread(file, ',', 1, 0);
assert(isequaln(exported(:, 1:2), gui.ml.coordinates));
assert(isequaln(exported(:, 3:5), [H(:), E(:), before.labels(:)]));
standalone = gui;
standalone.config = rmfield(standalone.config, {'mlFeatures', 'mlMethod', 'mlK', 'mlView'});
standalone.config.mlMetric = 1;
standalone.config.colorMap = 'hot';
standalone.config.flipColor = false;
standalone = TriDiMap_runML(standalone, 10*ones(3), ones(3), true);
assert(all(standalone.kamm.maps.KAMM(:) == 0));
assert(isequaln(standalone.ml, gui.ml));
assert(isequal(get(ax, 'Colormap'), hot(size(get(ax, 'Colormap'), 1))));
palette = get(ax, 'Colormap');
standalone.kamm.cacheNote = 'descriptor selection must not recalculate';
standalone.config.mlMetric = 2;
standalone.config.flipColor = true;
standalone = TriDiMap_runML(standalone, 10*ones(3), ones(3), true);
assert(isfield(standalone.kamm, 'cacheNote'));
assert(isequal(get(ax, 'Colormap'), flipud(palette)));
descriptorImage = get(findall(ax, 'Tag', 'TriDiMapMLMap'), 'CData');
assert(all(descriptorImage(:) == 0));
gui.data.coordinates = gui.ml.coordinates;
gui.config.mlFeatures = 1;
gui.config.mlView = 2;
gui = TriDiMap_runML(gui, E(:), H(:));
points = findall(ax, 'Tag', 'TriDiMapMLMap');
x = get(points, 'XData');
y = get(points, 'YData');
assert(isequal(x(:), gui.data.coordinates(:, 1)) && isequal(y(:), gui.data.coordinates(:, 2)));
assert(isempty(fieldnames(gui.ml.result.maps)) && gui.ml.result.labels(10) == 0);
try
    TriDiMap_mlCluster(E(:), H(:), 2, 1, 1, 2, false);
    error('TriDiMap:MissingError', 'Expected rejection of raster descriptors on irregular XY.');
catch exception
    assert(strcmp(exception.identifier, 'TriDiMap:KAMMRequiresGrid'));
end
disp('KAMM reference formulas, shells, holes, standardization and deterministic clustering passed.');
end

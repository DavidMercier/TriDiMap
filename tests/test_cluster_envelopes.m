function test_cluster_envelopes
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'third_party_codes'));

points = [0, 0; 2, 0; 2, 1; 0, 1; 1, 0.5; 2, 0];
boundary = TriDiMap_clusterHull(points);
assert(isequal(boundary(1, :), boundary(end, :)));
assert(abs(polyarea(boundary(:, 1), boundary(:, 2)) - 2) < 1e-12);
assert(all(inpolygon(points(:, 1), points(:, 2), boundary(:, 1), boundary(:, 2))));
assert(isequal(TriDiMap_clusterHull([2, 3; 0, 1; 1, 2]), [0, 1; 2, 3]));
assert(isequal(TriDiMap_clusterHull([1, 2; 1, 4; 1, 3]), [1, 2; 1, 4]));
assert(isequal(TriDiMap_clusterHull([1, 2; 1, 2]), [1, 2]));
assert(isequal(TriDiMap_clusterHull([2, 3; 1, 2]), [1, 2; 2, 3]));
assert(isempty(TriDiMap_clusterHull(zeros(0, 2))));
lastwarn('');
assert(isequal(TriDiMap_clusterHull([1, 2; NaN, 3; 4, Inf]), [1, 2]));
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'TriDiMap:NonfiniteClusterPoints'));

fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes('Parent', fig);
gui.config = struct('plotClusters', 3, 'plotSectMap', 0, 'flag_ClusterGauss', 1, ...
    'K_GMM', 3, 'FontSizeVal', 12, 'strUnit_Property', {{'GPa'}});
gui.handles.pm_clusterEnvelope_GUI = uicontrol('Parent', fig, 'Style', 'popupmenu', ...
    'String', {'None', 'Hull', 'Ellipse'}, 'Value', 2);
theta = (0:7)' * pi / 4;
cluster = [cos(theta), 2*sin(theta)];
gui.data.dataH_SectorVec = [bsxfun(@plus, cluster, [2, 20]); ...
    bsxfun(@plus, cluster, [5, 40]); bsxfun(@plus, cluster, [8, 60])];
gui.data.dataH_SectorLabVec = kron((1:3)', ones(8, 1));
gui.data.dataH = [1, 9];
gui.data.dataE = [20, 60];
config.FrenchLeg = 0;
LWval = 1.5;
originalLabels = gui.data.dataH_SectorLabVec;
originalPoints = gui.data.dataH_SectorVec;
TriDiMap_runEHmap;
outlines = findall(ax, 'Tag', 'TriDiMapClusterEnvelope');
assert(numel(outlines) == 3);
colors = [0, 0, 1; 1, 0, 0; 0, 1, 0];
for ii = 1:3
    outline = outlines(arrayfun(@(h) isequal(get(h, 'Color'), colors(ii, :)), outlines));
    assert(isscalar(outline));
    clusterPoints = originalPoints(originalLabels == ii, :);
    assert(all(inpolygon(clusterPoints(:, 1), clusterPoints(:, 2), ...
        get(outline, 'XData'), get(outline, 'YData'))));
end
phaseLegend = findall(fig, 'Type', 'legend');
legendLabels = get(phaseLegend, 'String');
assert(isequal(legendLabels(:), {'H = 2 GPa / E = 20 GPa'; ...
    'H = 5 GPa / E = 40 GPa'; 'H = 8 GPa / E = 60 GPa'}));
set(gui.handles.pm_clusterEnvelope_GUI, 'Value', 3);
TriDiMap_runEHmap;
assert(isempty(findall(ax, 'Tag', 'TriDiMapClusterEnvelope')));
assert(numel(findall(ax, 'Type', 'line')) == 6);
set(gui.handles.pm_clusterEnvelope_GUI, 'Value', 1);
TriDiMap_runEHmap;
assert(numel(findall(ax, 'Type', 'line')) == 3);
assert(isempty(findall(fig, 'Type', 'legend')));
assert(isequal(gui.data.dataH_SectorLabVec, originalLabels));
assert(isequal(gui.data.dataH_SectorVec, originalPoints));
disp('Cluster envelope tests passed.');
end

function test_grayscale_plots
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'gui'));
addpath(fullfile(root, 'matlab_code', 'util'));
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes('Parent', fig);
labels = [1, 2; 3, 4];
imageHandle = imagesc(ax, labels);
hold(ax, 'on');
colors = [0, 0, 0; 1, 0, 0; 0, 1, 0; 0, 0, 1];
colormap(fig, colors);
curves = gobjects(4, 1);
for ii = 1:4
    curves(ii) = plot(ax, [1, 2], [ii, ii], 'Color', colors(ii, :), ...
        'Marker', 'o', 'MarkerFaceColor', colors(ii, :));
end
bars = bar(ax, [1, 2], [0.3, 0.5], 'FaceColor', [1, 0, 0], ...
    'EdgeColor', [0, 0, 1]);
annotation = text(ax, 1, 1, 'Phase 2', 'Color', [1, 0, 0]);
limits = get(ax, 'CLim');
gui.config = struct;
gui.handles.AxisPlot_GUI = ax;
gui.data.labels = labels;
gui.resultsPDF.H = struct('means', [2, 5], 'fractions', [0.4, 0.6]);
guidata(fig, gui);
menu = uimenu(fig, 'Label', 'Grayscale plots', 'Checked', 'off');
TriDiMap_toggleGrayscale(menu, []);
grayPalette = get(ax, 'Colormap');
assert(isequal(grayPalette(:, 1), grayPalette(:, 2), grayPalette(:, 3)));
assert(numel(unique(grayPalette(:, 1))) == 4);
for ii = 1:4
    color = get(curves(ii), 'Color');
    assert(isequal(color, grayPalette(ii, :)));
    assert(isequal(get(curves(ii), 'MarkerFaceColor'), color));
end
assert(isequal(get(bars, 'FaceColor'), grayPalette(2, :)));
assert(isequal(get(bars, 'EdgeColor'), grayPalette(4, :)));
assert(isequal(get(annotation, 'Color'), grayPalette(2, :)));
assert(isequal(get(imageHandle, 'CData'), labels));
assert(isequal(get(ax, 'CLim'), limits));
after = guidata(fig);
assert(isequal(after.data, gui.data));
assert(isequal(after.resultsPDF, gui.resultsPDF));
assert(after.config.grayscalePlots);
TriDiMap_applyGrayscale(ax, true);
assert(isequal(get(fig, 'Colormap'), grayPalette));
TriDiMap_toggleGrayscale(menu, []);
assert(strcmp(get(menu, 'Checked'), 'off'));
assert(isequal(get(fig, 'Colormap'), colors));
assert(isequal(get(ax, 'Colormap'), colors));
for ii = 1:4
    assert(isequal(get(curves(ii), 'Color'), colors(ii, :)));
    assert(isequal(get(curves(ii), 'MarkerFaceColor'), colors(ii, :)));
end
assert(isequal(get(bars, 'FaceColor'), [1, 0, 0]));
assert(isequal(get(bars, 'EdgeColor'), [0, 0, 1]));
assert(isequal(get(annotation, 'Color'), [1, 0, 0]));
privateColors = [0, 1, 1; 1, 0, 1; 1, 1, 0];
colormap(ax, privateColors);
TriDiMap_applyGrayscale(ax, true);
privateGray = get(ax, 'Colormap');
assert(isequal(privateGray(:, 1), privateGray(:, 2), privateGray(:, 3)));
TriDiMap_applyGrayscale(ax, true);
assert(isequal(get(ax, 'Colormap'), privateGray));
TriDiMap_applyGrayscale(ax, false);
assert(isequal(get(ax, 'Colormap'), privateColors));
assert(isequal(get(fig, 'Colormap'), colors));
choices = listColormap;
popup = uicontrol('Parent', fig, 'Style', 'popupmenu', 'String', choices, ...
    'Value', find(strcmp(choices, 'Grayscale (all plots)')));
state = rng;
TriDiMap_toggleGrayscale(popup, []);
after = guidata(fig);
assert(after.config.grayscalePlots);
palette = get(ax, 'Colormap');
assert(isequal(palette(:, 1), palette(:, 2), palette(:, 3)));
set(popup, 'Value', 1);
TriDiMap_toggleGrayscale(popup, []);
after = guidata(fig);
assert(~after.config.grayscalePlots && strcmp(after.config.colorMap, 'jet'));
assert(isequal(after.data, gui.data) && isequal(after.resultsPDF, gui.resultsPDF));
assert(isequal(get(ax, 'Colormap'), privateColors) && isequal(rng, state));
disp('Grayscale rendering and restoration tests passed.');
end

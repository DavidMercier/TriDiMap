function test_phase_density
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
cloud = [-1, -2; 1, -2; -1, 2; 1, 2];
points = [bsxfun(@plus, cloud, [2, 10]); bsxfun(@plus, cloud, [8, 30])];
labels = [ones(4, 1); 2*ones(4, 1)];
phases = TriDiMap_phaseDensity(points, labels);
mass = 0;
for ii = 1:2
    phase = phases(ii);
    assert(abs(phase.weight - 0.5) < 1e-12);
    assert(norm(phase.covariance - diag([1, 4]), 'fro') < 1e-12);
    assert(abs(phase.pdf(61, 61) - 1/(8*pi)) < 1e-12);
    integral = trapz(phase.E(:, 1), trapz(phase.H(1, :), phase.pdf, 2));
    assert(abs(integral - 0.5) < 1e-4);
    mass = mass + integral;
end
assert(abs(mass - 1) < 2e-4);
correlated = [-1, -1; -1, 1; 1, -1; 1, 1] * [1, 2; 0, 3];
phase = TriDiMap_phaseDensity(correlated, ones(4, 1));
assert(norm(phase.covariance - [1, 2; 2, 13], 'fro') < 1e-12);
assert(abs(phase.pdf(61, 61) - 1/(6*pi)) < 1e-12);
lastwarn('');
filtered = TriDiMap_phaseDensity([points; NaN, 4], [labels; 1]);
[~, identifier] = lastwarn;
assert(strcmp(identifier, 'TriDiMap:NonfinitePhaseDensityPoints'));
assert(isequal(filtered, phases));
lastwarn('');
partial = TriDiMap_phaseDensity([cloud; 4, 4; 5, 5; 6, 6], [ones(4, 1); 2*ones(3, 1)]);
[~, identifier] = lastwarn;
assert(strcmp(identifier, 'TriDiMap:DegeneratePhaseDensity'));
assert(numel(partial) == 1 && abs(partial.weight - 4/7) < 1e-12);
assertFailure(@() TriDiMap_phaseDensity([1, 2; 2, 4], [1; 1]), 'TriDiMap:NoPhaseDensity');

fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes('Parent', fig);
gui.config = struct('FontSizeVal', 12, 'strUnit_Property', {{'GPa'}}, ...
    'logZ', false, 'grid', false, 'minorTicks', false, 'MinMax', false);
gui.data = struct('modulusIsReduced', true);
TriDiMap_plotPhaseDensity(points, labels, [0, 0, 1; 1, 0, 0], gui);
surfaces = findall(ax, 'Tag', 'TriDiMapPhaseDensity');
assert(numel(surfaces) == 2);
for ii = 1:2
    surface = surfaces(arrayfun(@(item) get(item, 'UserData') == ii, surfaces));
    assert(isequal(get(surface, 'ZData'), phases(ii).pdf));
end
assert(isequal(get(ax, 'View'), [45, 30]));
assert(strcmp(get(get(ax, 'YLabel'), 'String'), 'Reduced indentation modulus (GPa)'));
phaseLegend = findall(fig, 'Type', 'legend');
assert(numel(get(phaseLegend, 'String')) == 2);
TriDiMap_applyGrayscale(ax, true);
for ii = 1:2
    color = get(surfaces(ii), 'FaceColor');
    assert(color(1) == color(2) && color(2) == color(3));
end
gui.config.logZ = true;
gui.config.grid = true;
gui.config.minorTicks = true;
gui.config.MinMax = true;
plotted = TriDiMap_plotPhaseDensity(points, labels, [0, 0, 1; 1, 0, 0], gui);
assert(isequal(plotted, phases));
assert(strcmp(get(ax, 'XScale'), 'log') && strcmp(get(ax, 'YScale'), 'log'));
assert(strcmp(get(ax, 'ZScale'), 'linear'));
assert(all(strcmp(get(ax, {'XGrid', 'YGrid', 'ZGrid', ...
    'XMinorTick', 'YMinorTick', 'ZMinorTick'}), 'on')));
surfaces = findall(ax, 'Tag', 'TriDiMapPhaseDensity');
extrema = findall(ax, 'Tag', 'TriDiMapDensityExtrema');
assert(numel(extrema) == 2);
assert(numel(findall(ax, 'Tag', 'TriDiMapDensityMinimum')) == 2);
for ii = 1:2
    surface = surfaces(arrayfun(@(item) get(item, 'UserData') == ii, surfaces));
    h = get(surface, 'XData');
    e = get(surface, 'YData');
    z = get(surface, 'ZData');
    finite = isfinite(z);
    assert(all(h(finite) > 0 & e(finite) > 0));
    assert(isequal(z(finite), phases(ii).pdf(finite)));
    marker = extrema(arrayfun(@(item) get(item, 'UserData') == ii, extrema));
    assert(isequal(get(marker, 'ZData'), [min(z(finite)), max(z(finite))]));
end
lastwarn('');
mixed = TriDiMap_plotPhaseDensity([points; cloud - 20], [labels; 3*ones(4, 1)], ...
    [0, 0, 1; 1, 0, 0; 0, 1, 0], gui);
[~, identifier] = lastwarn;
assert(strcmp(identifier, 'TriDiMap:NonpositivePhaseDensity'));
assert(numel(findall(ax, 'Tag', 'TriDiMapPhaseDensity')) == 2);
assert(all(abs([mixed.weight] - 1/3) < 1e-12));
assertFailure(@() TriDiMap_plotPhaseDensity(cloud - 20, ones(4, 1), [0, 0, 0], gui), ...
    'TriDiMap:NoPhaseDensity');
gui.config.logZ = false;
gui.config.grid = false;
gui.config.minorTicks = false;
gui.config.MinMax = false;
TriDiMap_plotPhaseDensity(points, labels, [0, 0, 1; 1, 0, 0], gui);
assert(strcmp(get(ax, 'XScale'), 'linear') && strcmp(get(ax, 'YScale'), 'linear'));
assert(all(strcmp(get(ax, {'XGrid', 'YGrid', 'ZGrid', ...
    'XMinorTick', 'YMinorTick', 'ZMinorTick'}), 'off')));
assert(isempty(findall(ax, 'Tag', 'TriDiMapDensityExtrema')));
assert(isempty(findall(ax, 'Tag', 'TriDiMapDensityMinimum')));
disp('Joint phase density normalization, covariance, filtering and rendering tests passed.');
end

function assertFailure(action, identifier)
try
    action();
catch exception
    assert(strcmp(exception.identifier, identifier), exception.message);
    return
end
error('TriDiMap:MissingError', 'Expected error %s.', identifier);
end

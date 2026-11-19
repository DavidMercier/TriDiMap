function phases = TriDiMap_plotPhaseDensity(points, labels, colors, gui)
phases = TriDiMap_phaseDensity(points, labels);
visible = true(size(phases));
if gui.config.logZ
    visible = arrayfun(@(phase) any(phase.H(:) > 0 & phase.E(:) > 0), phases);
    if ~any(visible)
        error('TriDiMap:NoPhaseDensity', ...
            'No phase density has positive H and E coordinates for logarithmic axes.');
    end
    if any(~visible)
        warning('TriDiMap:NonpositivePhaseDensity', ...
            '%d phase densities have no positive H-E mesh and cannot be displayed on logarithmic axes.', sum(~visible));
    end
end
indices = find(visible);
cla;
legend off;
colorbar off;
hold on;
surfaces = gobjects(numel(indices), 1);
descriptions = cell(numel(indices), 1);
highest = 0;
theta = linspace(0, 2*pi, 81);
for ii = 1:numel(indices)
    phase = phases(indices(ii));
    color = colors(phase.id, :);
    h = phase.H;
    e = phase.E;
    density = phase.pdf;
    if gui.config.logZ
        hidden = h <= 0 | e <= 0;
        h(hidden) = NaN;
        e(hidden) = NaN;
        density(hidden) = NaN;
    end
    surfaces(ii) = surf(h, e, density, ...
        'FaceColor', color, 'FaceAlpha', 0.65, 'EdgeColor', 'none', ...
        'Tag', 'TriDiMapPhaseDensity', 'UserData', phase.id);
    factor = chol(phase.covariance, 'lower');
    for radius = 1:3
        ring = bsxfun(@plus, phase.mean', radius*factor*[cos(theta); sin(theta)]);
        if gui.config.logZ
            ring(:, any(ring <= 0, 1)) = NaN;
        end
        plot3(ring(1, :), ring(2, :), zeros(size(theta)), ...
            'Color', color, 'LineWidth', 0.6, 'Tag', 'TriDiMapDensityContour');
    end
    displayed = find(isfinite(density));
    [peak, maximum] = max(density(displayed));
    maximum = displayed(maximum);
    highest = max(highest, peak);
    peakLabel = sprintf('Phase %d', phase.id);
    if gui.config.MinMax
        [minimum, location] = min(density(displayed));
        location = displayed(location);
        peakLabel = sprintf('Phase %d\nMax = %.3g', phase.id, peak);
        plot3(h([location, maximum]), e([location, maximum]), [minimum, peak], ...
            'o', 'Color', color, 'MarkerFaceColor', 'w', ...
            'Tag', 'TriDiMapDensityExtrema', 'UserData', phase.id);
        text(h(location), e(location), minimum, sprintf('Min = %.3g', minimum), ...
            'FontSize', gui.config.FontSizeVal, 'Interpreter', 'none', ...
            'Tag', 'TriDiMapDensityMinimum');
    end
    text(h(maximum), e(maximum), 1.03*peak, peakLabel, ...
        'HorizontalAlignment', 'center', 'FontSize', gui.config.FontSizeVal, ...
        'Tag', 'TriDiMapDensityLabel');
    descriptions{ii} = sprintf('Phase %d (n=%d, %.1f%%)', phase.id, phase.count, 100*phase.weight);
end
unit = char(gui.config.strUnit_Property);
hardness = 'Hardness';
modulus = 'Elastic modulus';
probability = 'Joint probability density';
heading = 'Joint E-H probability density by phase';
reduced = isfield(gui.data, 'originalProperties') || isfield(gui.data, 'modulusIsReduced');
if reduced
    modulus = 'Reduced indentation modulus';
end
if isfield(gui.config, 'FrenchLeg') && gui.config.FrenchLeg
    hardness = 'Durete';
    modulus = 'Module elastique';
    if reduced
        modulus = 'Module d''indentation reduit';
    end
    probability = 'Densite de probabilite conjointe';
    heading = 'Densite conjointe E-H ponderee par phase';
end
xlabel([hardness, ' (', unit, ')'], 'Interpreter', 'tex');
ylabel([modulus, ' (', unit, ')'], 'Interpreter', 'tex');
zlabel([probability, ' (', unit, '^{-2})'], 'Interpreter', 'tex');
title(heading, 'Interpreter', 'none');
legend(surfaces, descriptions, 'Location', 'northeastoutside', 'Interpreter', 'none');
scale = 'linear';
if gui.config.logZ
    scale = 'log';
end
states = {'off', 'on'};
gridState = states{1 + logical(gui.config.grid)};
tickState = states{1 + logical(gui.config.minorTicks)};
set(gca, 'FontSize', gui.config.FontSizeVal, ...
    'XScale', scale, 'YScale', scale, 'ZScale', 'linear', ...
    'XGrid', gridState, 'YGrid', gridState, 'ZGrid', gridState, ...
    'XMinorTick', tickState, 'YMinorTick', tickState, 'ZMinorTick', tickState);
axis tight;
zlim([0, 1.12*highest]);
view(45, 30);
pbaspect([1, 1, 0.7]);
box on;
hold off;
end

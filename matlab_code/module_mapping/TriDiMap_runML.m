function gui = TriDiMap_runML(gui, E, H, descriptorOnly)
if nargin < 4
    descriptorOnly = false;
end
c = gui.config;
if ~strcmp(char(c.strUnit_Property), 'GPa')
    error('TriDiMap:MLInput', 'ML descriptors expect modulus and hardness in GPa; check data and property units.');
end
raster = ~isfield(gui.data, 'coordinates');
if ~raster && (descriptorOnly || ismember(c.mlFeatures, [2, 4]) || c.mlView == 3)
    error('TriDiMap:KAMMRequiresGrid', ...
        'KAMM requires a raster map. Random XY positions are not grid neighbours. Choose H,E or mechanical ratios.');
end
if descriptorOnly
    c.mlView = 3;
    gui = TriDiMap_cacheKamm(gui, E, H);
    result = struct('maps', gui.kamm.maps);
else
    key = struct('E', E, 'H', H, 'features', c.mlFeatures, 'method', c.mlMethod, ...
        'order', c.mlOrder, 'K', c.mlK, 'raster', raster);
    if ~isfield(gui, 'ml') || ~isequaln(gui.ml.key, key)
        result = TriDiMap_mlCluster(E, H, c.mlFeatures, c.mlMethod, c.mlOrder, c.mlK, raster);
        gui.ml = struct('key', key, 'result', result);
    end
    result = gui.ml.result;
end
if raster
    [x, y] = ndgrid((c.MinXCrop-1+(0:size(H, 1)-1))*c.XStep, ...
        (c.MinYCrop-1+(0:size(H, 2)-1))*c.YStep);
    coordinates = [x(:), y(:)];
else
    coordinates = gui.data.coordinates;
end
if descriptorOnly
    gui.kamm.coordinates = coordinates;
else
    gui.ml.coordinates = coordinates;
end
if c.mlView ~= 3
    colors = lines(c.mlK);
end
if c.mlView == 4
    TriDiMap_plotPhaseDensity([H(:), E(:)], result.labels(:), colors, gui);
elseif c.mlView == 1
    cla;
    colorbar off;
    hold on;
    handles = gobjects(c.mlK, 1);
    descriptions = cell(c.mlK, 1);
    for ii = 1:c.mlK
        selected = result.labels == ii;
        handles(ii) = plot(H(selected), E(selected), '.', 'Color', colors(ii, :));
        descriptions{ii} = sprintf('Phase %d (n=%d)', ii, sum(selected(:)));
    end
    legend(handles, descriptions, 'Location', 'northeastoutside');
    scale = 'linear';
    if c.logZ
        scale = 'log';
    end
    set(gca, 'XScale', scale, 'YScale', scale);
    xlabel('Hardness (GPa)');
    ylabel('Elastic / indentation modulus (GPa)');
    title('ML-assisted phase clustering');
    if c.MinMax
        selected = find(result.valid);
        [~, low] = min(H(selected));
        [~, high] = max(H(selected));
        for index = selected([low, high])'
            text(H(index), E(index), sprintf('H=%.3g, E=%.3g', H(index), E(index)), ...
                'Tag', 'TriDiMapMLExtremum');
        end
    end
    hold off;
else
    if c.mlView == 2
        values = double(result.labels);
        values(values == 0) = NaN;
        heading = 'ML phase map';
        colorLabel = 'Phase';
        palette = colors;
    else
        metrics = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
        metric = metrics{c.mlMetric};
        values = result.maps.(metric);
        heading = [metric, ' map (order ', num2str(c.mlOrder), ')'];
        units = {'GPa^2', 'GPa', 'GPa', 'dimensionless', 'dimensionless'};
        colorLabel = [metric, ' (', units{c.mlMetric}, ')'];
        palette = parula(256);
        if c.logZ
            if any(values(isfinite(values)) <= 0)
                warning('TriDiMap:MLLogNonpositive', 'Nonpositive descriptor values are hidden in log-color display.');
            end
            values(values <= 0) = NaN;
            values = log10(values);
            colorLabel = ['log10 ', colorLabel];
            if ~any(isfinite(values(:)))
                error('TriDiMap:MLInput', 'This descriptor has no positive values for log colors; uncheck Log.');
            end
        end
        if ~any(isfinite(values(:)))
            error('TriDiMap:MLInput', 'This descriptor has no finite values to display.');
        end
    end
    cla;
    legend off;
    if raster
        image = imagesc(unique(coordinates(:, 1)), unique(coordinates(:, 2)), values');
        set(image, 'AlphaData', isfinite(values'), 'Tag', 'TriDiMapMLMap');
        set(gca, 'YDir', 'normal');
    else
        scatter(coordinates(:, 1), coordinates(:, 2), 55, values(:), ...
            'filled', 'Tag', 'TriDiMapMLMap');
    end
    colormap(gca, palette);
    if descriptorOnly
        axisMap(c.colorMap, '', c.FontSizeVal, [], [], c.flipColor, char(c.strUnit_Length));
    end
    bar = colorbar;
    ylabel(bar, colorLabel, 'Interpreter', 'none');
    if c.mlView == 2
        caxis([0.5, c.mlK+0.5]);
        set(bar, 'Ticks', 1:c.mlK);
    elseif c.MinMax
        valid = find(isfinite(values));
        [~, low] = min(values(valid));
        [~, high] = max(values(valid));
        for index = valid([low, high])'
            text(coordinates(index, 1), coordinates(index, 2), ...
                sprintf('%.3g', values(index)), 'Tag', 'TriDiMapMLExtremum');
        end
    end
    axis equal tight;
    title(heading, 'Interpreter', 'none');
    xlabel(['X (', char(c.strUnit_Length), ')'], 'Interpreter', 'none');
    ylabel(['Y (', char(c.strUnit_Length), ')'], 'Interpreter', 'none');
end
if c.mlView ~= 4
    states = {'off', 'on'};
    set(gca, 'FontSize', c.FontSizeVal, 'XMinorTick', states{1+logical(c.minorTicks)}, ...
        'YMinorTick', states{1+logical(c.minorTicks)});
end
if ~descriptorOnly
    set(gui.handles.pb_mlExport_GUI, 'Enable', 'on');
end
end

function gui = TriDiMap_runML(gui, E, H, descriptorOnly)
if nargin < 4
    descriptorOnly = false;
end
c = gui.config;
if ~strcmp(char(c.strUnit_Property), 'GPa')
    error('TriDiMap:MLInput', 'ML descriptors expect modulus and hardness in GPa; check data and property units.');
end
raster = ~isfield(gui.data, 'coordinates');
if ~raster && (descriptorOnly || ismember(c.mlFeatures, [2, 4]) || ismember(c.mlView, [3, 5]))
    error('TriDiMap:KAMMRequiresGrid', ...
        'KAMM requires a raster map. Random XY positions are not grid neighbours. Use H,E-only features and a non-KAMM view.');
end
if descriptorOnly
    c.mlView = 3;
    gui = TriDiMap_cacheKamm(gui, E, H);
    result = struct('maps', gui.kamm.maps);
else
    key = struct('E', E, 'H', H, 'features', c.mlFeatures, 'method', c.mlMethod, ...
        'order', c.mlOrder, 'K', c.mlK, 'raster', raster);
    preparedEH = isfield(gui, 'eh') && isequaln(gui.eh.E, E) && isequaln(gui.eh.H, H);
    if preparedEH
        key.inputSource = gui.eh.source;
    end
    neighbours = 10;
    if c.mlMethod == 3
        if isfield(c, 'mlNeighbours')
            neighbours = c.mlNeighbours;
        end
        key.neighbours = neighbours;
    end
    if ~isfield(gui, 'ml') || ~isequaln(gui.ml.key, key)
        result = TriDiMap_mlCluster(E, H, c.mlFeatures, c.mlMethod, c.mlOrder, c.mlK, raster, neighbours);
        gui.ml = struct('key', key, 'result', result);
    end
    result = gui.ml.result;
    if c.mlView == 6 && isempty(result.embedding)
        error('TriDiMap:IsomapInput', 'Choose ISOMAP + K-means to display the ISOMAP embedding.');
    end
end
if ~descriptorOnly && preparedEH
    coordinates = gui.eh.coordinates;
elseif raster
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
elseif c.mlView == 1 || c.mlView == 6
    plotX = H;
    plotY = E;
    if c.mlView == 6
        plotX = NaN(size(H));
        plotY = NaN(size(E));
        plotX(result.valid) = result.embedding(:, 1);
        plotY(result.valid) = result.embedding(:, 2);
    end
    cla;
    colorbar off;
    hold on;
    handles = gobjects(c.mlK, 1);
    descriptions = cell(c.mlK, 1);
    envelopeType = 1;
    if isfield(c, 'mlEnvelope')
        envelopeType = c.mlEnvelope;
    end
    for ii = 1:c.mlK
        selected = result.labels == ii;
        handles(ii) = plot(plotX(selected), plotY(selected), '.', 'Color', colors(ii, :));
        phaseX = plotX(selected);
        phaseY = plotY(selected);
        TriDiMap_drawClusterEnvelope([phaseX(:), phaseY(:)], ...
            envelopeType, colors(ii, :), 1.5);
        descriptions{ii} = sprintf('Phase %d (n=%d)', ii, sum(selected(:)));
    end
    legend(handles, descriptions, 'Location', 'northeastoutside');
    scale = 'linear';
    if c.logZ && c.mlView == 1
        scale = 'log';
    end
    set(gca, 'XScale', scale, 'YScale', scale);
    if c.mlView == 6
        xlabel('ISOMAP coordinate 1');
        ylabel('ISOMAP coordinate 2');
        title('ISOMAP embedding with K-means phases');
    else
        xlabel('Hardness (GPa)');
        ylabel('Elastic / indentation modulus (GPa)');
        title('ML-assisted phase clustering');
    end
    if c.MinMax
        selected = find(result.valid);
        [~, low] = min(H(selected));
        [~, high] = max(H(selected));
        for index = selected([low, high])'
            text(plotX(index), plotY(index), sprintf('H=%.3g, E=%.3g', H(index), E(index)), ...
                'Tag', 'TriDiMapMLExtremum');
        end
    end
    hold off;
elseif c.mlView == 5
    labels = result.labels(:);
    hardness = H(:);
    modulus = E(:);
    metrics = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
    units = {'GPa^2', 'GPa', 'GPa', 'dimensionless', 'dimensionless'};
    metric = metrics{c.mlMetric};
    descriptorMap = result.maps.(metric);
    descriptor = descriptorMap(:);
    unit = units{c.mlMetric};
    selected = labels > 0 & isfinite(hardness) & isfinite(modulus) & isfinite(descriptor);
    if c.logZ
        nonpositive = selected & (hardness <= 0 | modulus <= 0 | descriptor <= 0);
        if any(nonpositive)
            warning('TriDiMap:MLLogNonpositive', ...
                '%s points with nonpositive values are hidden on logarithmic axes.', metric);
        end
        selected = selected & hardness > 0 & modulus > 0 & descriptor > 0;
    end
    if ~any(selected)
        error('TriDiMap:MLInput', ...
            'There are no assigned finite H-E-%s points to display.', metric);
    end
    oldLegends = findall(ancestor(gca, 'figure'), 'Tag', 'legend');
    if ~isempty(oldLegends)
        delete(oldLegends);
    end
    colorbar off;
    cla;
    hold on;
    handles = cell(c.mlK, 1);
    descriptions = cell(c.mlK, 1);
    for ii = 1:c.mlK
        phase = selected & labels == ii;
        handles{ii} = scatter3(hardness(phase), modulus(phase), descriptor(phase), ...
            24, colors(ii, :), 'filled', 'Tag', 'TriDiMapML3DCluster');
        descriptions{ii} = sprintf('Phase %d (n=%d)', ii, sum(phase));
    end
    legend([handles{:}], descriptions, 'Location', 'northeastoutside');
    scale = 'linear';
    if c.logZ
        scale = 'log';
    end
    set(gca, 'XScale', scale, 'YScale', scale, 'ZScale', scale);
    xlabel('Hardness (GPa)');
    ylabel('Elastic / indentation modulus (GPa)');
    zlabel([metric, ' (', unit, ')'], 'Interpreter', 'none');
    title(['ML-assisted H-E-', metric, ' (3D)'], 'Interpreter', 'none');
    view(3);
    if c.MinMax
        points = find(selected);
        [~, low] = min(hardness(points));
        [~, high] = max(hardness(points));
        for index = points([low, high])'
            text(hardness(index), modulus(index), descriptor(index), ...
                sprintf('H=%.3g, E=%.3g, %s=%.3g', ...
                hardness(index), modulus(index), metric, descriptor(index)), ...
                'Tag', 'TriDiMapMLExtremum');
        end
    end
    if c.grid
        grid on;
    else
        grid off;
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
    if c.mlView == 5
        set(gca, 'ZMinorTick', states{1+logical(c.minorTicks)});
    end
end
if ~descriptorOnly
    set(gui.handles.pb_mlExport_GUI, 'Enable', 'on');
end
end

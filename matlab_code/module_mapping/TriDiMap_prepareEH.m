function [gui, E, H, flagCrop] = TriDiMap_prepareEH(gui, E, H)
c = gui.config;
source = 1;
if isfield(c, 'ehSource')
    source = c.ehSource;
end
if ~isscalar(source) || ~ismember(source, [1, 2])
    error('TriDiMap:EHInput', 'Choose raw measurements or processed maps for E-H analysis.');
end
raster = ~isfield(gui.data, 'coordinates');
if source == 2 && ~raster
    error('TriDiMap:EHInput', 'Processed E-H maps require a regular raster; use raw measurements for irregular XY.');
end
processing = struct('noNan', false, 'interpolate', false, 'smooth', false);
if source == 2
    processing.noNan = logical(c.noNan);
    processing.interpolate = logical(c.noNan && c.interpBool);
    processing.smooth = logical(c.noNan && c.smoothBool);
    if processing.noNan
        if any(size(E) < 2) || any(size(H) < 2)
            error('TriDiMap:EHInput', 'Processed E-H maps need at least two pixels on each axis; choose raw measurements.');
        end
        E = TriDiMap_cleaningData(E);
        H = TriDiMap_cleaningData(H);
    end
end
[E, flagCrop] = TriDiMap_cropping(E);
[H, flagCropH] = TriDiMap_cropping(H);
if ~raster
    coordinates = gui.data.coordinates;
else
    if ~flagCrop || ~flagCropH
        error('TriDiMap:EHInput', 'Correct the E-H crop bounds before plotting.');
    end
    measuredSize = size(H);
    if processing.noNan && (processing.interpolate || processing.smooth)
        [~, ~, E] = TriDiMap_interpolation_smoothing( ...
            E, processing.interpolate, c.interpFact, processing.smooth, c.smoothFact);
        [~, ~, H] = TriDiMap_interpolation_smoothing( ...
            H, processing.interpolate, c.interpFact, processing.smooth, c.smoothFact);
    end
    xOffset = (round(abs(c.MinXCrop))-1)*c.XStep;
    yOffset = (round(abs(c.MinYCrop))-1)*c.YStep;
    [x, y] = ndgrid(linspace(xOffset, xOffset+(measuredSize(1)-1)*c.XStep, size(H, 1)), ...
        linspace(yOffset, yOffset+(measuredSize(2)-1)*c.YStep, size(H, 2)));
    coordinates = [x(:), y(:)];
    gui.data.xData = x(:, 1);
    gui.data.yData = y(1, :);
    gui.data.xData_interp = x';
    gui.data.yData_interp = y';
    gui.data.data2plot = H;
end
names = {'raw', 'processed'};
prepared = struct('E', E, 'H', H, 'source', names{source}, ...
    'processing', processing, 'coordinates', coordinates);
changed = ~isfield(gui, 'eh') || ~isequaln(gui.eh, prepared);
if changed
    gui.config.flag_ClusterGauss = 0;
    if source == 2 && (processing.noNan || processing.interpolate || processing.smooth)
        warning('TriDiMap:EHProcessedData', ...
            ['E-H analysis uses processed map pixels, including filled/interpolated values where enabled. ', ...
            'Cluster fractions and counts describe these pixels, not independent measured indents.']);
    end
end
gui.eh = prepared;
end

function TriDiMap_applyGrayscale(ax, enabled)
figureHandle = ancestor(ax, 'figure');
paletteKey = 'TriDiMapColorColormap';
colorsKey = 'TriDiMapPlotColors';
weights = [0.299; 0.587; 0.114];
axesPalette = get(ax, 'Colormap');
figurePalette = get(figureHandle, 'Colormap');
if enabled
    if ~isappdata(figureHandle, paletteKey)
        setappdata(figureHandle, paletteKey, get(figureHandle, 'Colormap'));
    end
    palette = getappdata(figureHandle, paletteKey);
    set(figureHandle, 'Colormap', repmat(palette * weights, 1, 3));
elseif isappdata(figureHandle, paletteKey)
    set(figureHandle, 'Colormap', getappdata(figureHandle, paletteKey));
    rmappdata(figureHandle, paletteKey);
end

properties = {'Color', 'FaceColor', 'EdgeColor', 'MarkerFaceColor', 'MarkerEdgeColor'};
objects = findall(ax);
for ii = 1:numel(objects)
    object = objects(ii);
    if ~enabled
        if isappdata(object, colorsKey)
            set(object, getappdata(object, colorsKey));
            rmappdata(object, colorsKey);
        end
        continue
    end
    if isappdata(object, colorsKey)
        colors = getappdata(object, colorsKey);
    else
        colors = struct;
        for jj = 1:numel(properties)
            property = properties{jj};
            if isprop(object, property)
                value = get(object, property);
                if isnumeric(value) && isequal(size(value), [1, 3])
                    colors.(property) = value;
                end
            end
        end
        % Preserve an independent axes palette when changing the figure palette.
        if object == ax && (~isequal(axesPalette, figurePalette) || ...
                ~isequal(get(ax, 'Colormap'), get(figureHandle, 'Colormap')))
            colors.Colormap = axesPalette;
        end
        setappdata(object, colorsKey, colors);
    end
    names = fieldnames(colors);
    for jj = 1:numel(names)
        value = colors.(names{jj});
        set(object, names{jj}, repmat(value * weights, 1, 3));
    end
end
end

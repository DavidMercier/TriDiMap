function TriDiMap_toggleGrayscale(source, ~)
figureHandle = ancestor(source, 'figure');
gui = guidata(figureHandle);
isMenu = strcmp(get(source, 'Type'), 'uimenu');
if isMenu
    enabled = ~strcmp(get(source, 'Checked'), 'on');
else
    choices = get(source, 'String');
    selected = choices{get(source, 'Value')};
    enabled = strcmp(selected, 'Grayscale (all plots)');
    if ~enabled
        gui.config.colorMap = selected;
    end
end
gui.config.grayscalePlots = enabled;
guidata(figureHandle, gui);
if isMenu
    if enabled
        set(source, 'Checked', 'on');
    else
        set(source, 'Checked', 'off');
    end
end
TriDiMap_applyGrayscale(gui.handles.AxisPlot_GUI, enabled);
if ~isMenu && ~enabled && isfield(gui.config, 'property') && ...
        (gui.config.property < 3 || gui.config.property == 10)
    figure(figureHandle);
    TriDiMap_runPlot;
end
end

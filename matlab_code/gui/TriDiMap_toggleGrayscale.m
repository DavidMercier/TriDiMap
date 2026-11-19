function TriDiMap_toggleGrayscale(source, ~)
figureHandle = ancestor(source, 'figure');
gui = guidata(figureHandle);
enabled = ~strcmp(get(source, 'Checked'), 'on');
gui.config.grayscalePlots = enabled;
guidata(figureHandle, gui);
if enabled
    set(source, 'Checked', 'on');
else
    set(source, 'Checked', 'off');
end
TriDiMap_applyGrayscale(gui.handles.AxisPlot_GUI, enabled);
end

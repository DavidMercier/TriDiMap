%% Copyright 2014 MERCIER David
function TriDiMap_getParam
%% Function to get parameters from the GUI
gui = guidata(gcf);
if ~gui.config.saveFlag
    TriDiMap_updateUnit;
end
gui = guidata(gcf);

gui.config.dataType = get(gui.handles.pm_set_file, 'Value');
gui.config.N_XStep_default = str2num(get(gui.handles.value_numXindents_GUI, 'String'));
gui.config.N_YStep_default = str2num(get(gui.handles.value_numYindents_GUI, 'String'));
gui.config.XStep_default = str2num(get(gui.handles.value_deltaXindents_GUI, 'String'));
gui.config.YStep_default = str2num(get(gui.handles.value_deltaYindents_GUI, 'String'));
gui.config.angleRotation_default = str2num(get(gui.handles.value_angleRot_GUI, 'String'));

gui.config.property = get(gui.handles.property_GUI, 'Value');

gui.config.rawData = get(gui.handles.cb_pixData_GUI, 'Value');
if gui.config.rawData
    gui.config.contourPlot = 0;
    set(gui.handles.cb_contourPlotMap_GUI, 'Visible', 'off');
    display('Contour plot not active, when pixelized data is plotted !');
else
    set(gui.handles.cb_smoothMap_GUI, 'Visible', 'on');
    set(gui.handles.slider_smoothMap_GUI, 'Visible', 'on');
    set(gui.handles.cb_contourPlotMap_GUI, 'Visible', 'on');
end

gui.config.noNan = get(gui.handles.cb_pixNaN_GUI, 'Value');
if ~gui.config.noNan
    gui.config.interpBool = 0;
    set(gui.handles.cb_interpMap_GUI, 'Visible', 'off');
    set(gui.handles.slider_interpMap_GUI, 'Visible', 'off');
    gui.config.smoothBool = 0;
    set(gui.handles.cb_smoothMap_GUI, 'Visible', 'off');
    set(gui.handles.slider_smoothMap_GUI, 'Visible', 'off');
    gui.config.binarizedGrid = 0;
    display('Interpolation and smoothing not active, because NaN values not removed/corrected !');
else
    set(gui.handles.cb_interpMap_GUI, 'Visible', 'on');
    set(gui.handles.slider_interpMap_GUI, 'Visible', 'on');
    set(gui.handles.cb_smoothMap_GUI, 'Visible', 'on');
    set(gui.handles.slider_smoothMap_GUI, 'Visible', 'on');
    set(gui.handles.cb_smoothMap_GUI, 'Visible', 'on');
    set(gui.handles.slider_smoothMap_GUI, 'Visible', 'on');
end

gui.config.interpBool = get(gui.handles.cb_interpMap_GUI, 'Value');
gui.config.interpFact = get(gui.handles.slider_interpMap_GUI, 'Value');
gui.config.smoothBool = get(gui.handles.cb_smoothMap_GUI, 'Value');
gui.config.smoothFact = get(gui.handles.slider_smoothMap_GUI, 'Value');
if gui.config.smoothBool
    set(gui.handles.cb_errorMap_GUI, 'Visible', 'on');
else
    set(gui.handles.cb_errorMap_GUI, 'Visible', 'off');
end

gui.config.normalizationStep = get(gui.handles.cb_normMap_GUI, 'Value');
gui.config.normalizationStepVal = get(gui.handles.pm_normMap_GUI, 'Value');
if gui.config.normalizationStep
    set(gui.handles.pm_normMap_GUI, 'Visible', 'on');
    set(gui.handles.cb_autoColorbar_GUI, 'Value', 1);
else
    set(gui.handles.pm_normMap_GUI, 'Visible', 'off');
end
gui.config.translationStep = get(gui.handles.cb_transMap_GUI, 'Value');
gui.config.translationStepVal = get(gui.handles.value_transMap_GUI, 'Value');
if gui.config.translationStep
    set(gui.handles.value_transMap_GUI, 'Visible', 'on');
    set(gui.handles.unit_transMap_GUI, 'Visible', 'on');
else
    set(gui.handles.value_transMap_GUI, 'Visible', 'off');
    set(gui.handles.unit_transMap_GUI, 'Visible', 'off');
end

gui.config.contourPlot = get(gui.handles.cb_contourPlotMap_GUI, 'Value');
gui.config.flipColor = get(gui.handles.cb_flipColormap_GUI, 'Value');
gui.config.scaleAxis = get(gui.handles.cb_autoColorbar_GUI, 'Value');
gui.config.cmin = str2num(get(gui.handles.value_colorMin_GUI, 'String'));
gui.config.cmax = str2num(get(gui.handles.value_colorMax_GUI, 'String'));
gui.config.intervalScaleBar = str2num(get(gui.handles.value_colorNum_GUI, 'String'));
gui.config.logZ = get(gui.handles.cb_log_plot_GUI, 'Value');
gui.config.grid = get(gui.handles.cb_grid_plot_GUI, 'Value');
gui.config.Markers = get(gui.handles.cb_markers_GUI, 'Value');
gui.config.MinMax = get(gui.handles.cb_MinMax_plot_GUI, 'Value');
gui.config.minorTicks = get(gui.handles.cb_tickColorBar_GUI, 'Value');
gui.config.colorMap = char(get_value_popupmenu(gui.handles.colormap_GUI, listColormap));

%% To Do

% Raw data or post-processed data
gui.config.fracCalc = 0; % Boolean to plot raw dataset in black and white and to calculate phase fraction
gui.config.binarizedGrid = 0; % Variable to binarize values of the grid
% 0 = no binarization / 1 = smoothed binarization / 2 = binarization

% Setting for phase fraction
gui.config.Legend = {'Ni', 'SiC'}; % {'Softest phase', 'Hardest phase'}
gui.config.LegendMatch = {'Match', 'No match'};

if gui.config.plotImage
    gui.config.rawData = 1;
    gui.config.fracCalc = 1;
    gui.config.intervalScaleBar_H = 2;
    gui.config.intervalScaleBar_YM = 2;
end
if gui.config.N_XStep_default ~= gui.config.N_YStep_default
    gui.config.Markers = 0;
    set(gui.handles.cb_markers_GUI, 'Visible', 'off');
    display('Markers can''t be plotted, because grid is not square !');
else
    set(gui.handles.cb_markers_GUI, 'Visible', 'on');
end

guidata(gcf, gui);

end
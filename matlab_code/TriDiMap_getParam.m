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
gui.config.XStep = str2num(get(gui.handles.value_deltaXindents_GUI, 'String'));
gui.config.YStep = str2num(get(gui.handles.value_deltaYindents_GUI, 'String'));

gui.config.property = get(gui.handles.property_GUI, 'Value');

gui.config.MinXCrop = str2num(get(gui.handles.value_MinXCrop_GUI, 'String'));
gui.config.MaxXCrop = str2num(get(gui.handles.value_MaxXCrop_GUI, 'String'));
gui.config.MinYCrop = str2num(get(gui.handles.value_MinYCrop_GUI, 'String'));
gui.config.MaxYCrop = str2num(get(gui.handles.value_MaxYCrop_GUI, 'String'));

if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    gui.config.rawData = get(gui.handles.cb_pixData_GUI, 'Value');
    if gui.config.rawData
        gui.config.contourPlot = 0;
        set(gui.handles.cb_contourPlotMap_GUI, 'Visible', 'off');
        display('Contour plot not active, when pixelized data is plotted !');
    else
        set(gui.handles.cb_contourPlotMap_GUI, 'Visible', 'on');
    end
    
    gui.config.noNan = get(gui.handles.cb_pixNaN_GUI, 'Value');
    if ~gui.config.noNan
        set(gui.handles.cb_interpMap_GUI, 'Value', 0);
        set(gui.handles.cb_interpMap_GUI, 'Visible', 'off');
        set(gui.handles.pm_interpMap_GUI, 'Visible', 'off');
        set(gui.handles.cb_smoothMap_GUI, 'Value', 0);
        set(gui.handles.cb_smoothMap_GUI, 'Visible', 'off');
        set(gui.handles.pm_smoothMap_GUI, 'Visible', 'off');
        gui.config.binarizedGrid = 0;
        display('Interpolation and smoothing not active, because NaN values not removed/corrected !');
    else
        set(gui.handles.cb_interpMap_GUI, 'Visible', 'on');
        set(gui.handles.pm_interpMap_GUI, 'Visible', 'on');
        set(gui.handles.cb_smoothMap_GUI, 'Visible', 'on');
        set(gui.handles.pm_smoothMap_GUI, 'Visible', 'on');
        set(gui.handles.cb_errorMap_GUI, 'Visible', 'on');
    end
    
    gui.config.interpBool = get(gui.handles.cb_interpMap_GUI, 'Value');
    if gui.config.interpBool == 0
        gui.config.interpFactVal = 1;
    end
    gui.config.interpFactStr = get_value_popupmenu(gui.handles.pm_interpMap_GUI, listInterp);
    gui.config.interpFact = get(gui.handles.pm_interpMap_GUI, 'Value');
    if gui.config.interpBool == 1
        if gui.config.interpFact == 1
            gui.config.interpFactVal = 2;
        elseif gui.config.interpFact == 2
            gui.config.interpFactVal = 4;
        elseif gui.config.interpFact == 3
            gui.config.interpFactVal = 8;
        elseif gui.config.interpFact == 4
            gui.config.interpFactVal = 16;
        end
        set(gui.handles.pm_interpMap_GUI, 'Visible', 'on');
    else
        set(gui.handles.pm_interpMap_GUI, 'Visible', 'off');
    end
    
    gui.config.smoothBool = get(gui.handles.cb_smoothMap_GUI, 'Value');
    gui.config.smoothFactStr = get_value_popupmenu(gui.handles.pm_smoothMap_GUI, listSmooth);
    gui.config.smoothFact = get(gui.handles.pm_smoothMap_GUI, 'Value');
    if gui.config.smoothBool
        set(gui.handles.cb_errorMap_GUI, 'Visible', 'on');
        set(gui.handles.pm_smoothMap_GUI, 'Visible', 'on');
    else
        set(gui.handles.cb_errorMap_GUI, 'Visible', 'off');
        set(gui.handles.cb_errorMap_GUI, 'Value', 0);
        set(gui.handles.pm_smoothMap_GUI, 'Visible', 'off');
    end
    
    gui.config.normalizationStep = get(gui.handles.cb_normMap_GUI, 'Value');
    gui.config.normalizationStepVal = get(gui.handles.pm_normMap_GUI, 'Value');
    if gui.config.normalizationStep
        set(gui.handles.cb_autoColorbar_GUI, 'Value', 1);
        set(gui.handles.cb_transMap_GUI, 'Visible', 'off');
        set(gui.handles.value_transMap_GUI, 'Visible', 'off');
    else
        set(gui.handles.cb_transMap_GUI, 'Visible', 'on');
        set(gui.handles.value_transMap_GUI, 'Visible', 'on');
    end
    gui.config.translationStep = get(gui.handles.cb_transMap_GUI, 'Value');
    gui.config.translationStepVal = str2num(get(gui.handles.value_transMap_GUI, 'String'));
    if gui.config.translationStep
        set(gui.handles.value_transMap_GUI, 'Visible', 'on');
        set(gui.handles.unit_transMap_GUI, 'Visible', 'on');
        set(gui.handles.cb_normMap_GUI, 'Visible', 'off');
        set(gui.handles.pm_normMap_GUI, 'Visible', 'off');
    else
        set(gui.handles.value_transMap_GUI, 'Visible', 'off');
        set(gui.handles.unit_transMap_GUI, 'Visible', 'off');
        set(gui.handles.cb_normMap_GUI, 'Visible', 'on');
        set(gui.handles.pm_normMap_GUI, 'Visible', 'on');
    end
    if gui.config.normalizationStep
        set(gui.handles.pm_normMap_GUI, 'Visible', 'on');
    else
        set(gui.handles.pm_normMap_GUI, 'Visible', 'off');
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
else
    gui.config.rawData = 1;
    gui.config.noNan = 1;
    gui.config.criterionBinMap = 7;
    gui.config.legendBinMap = 0;
    gui.config.legendStr = {'Ni', 'SiC'}; % {'Softest phase', 'Hardest phase'}
    gui.config.legendMatch = {'Match', 'No match'};
end

guidata(gcf, gui);

end